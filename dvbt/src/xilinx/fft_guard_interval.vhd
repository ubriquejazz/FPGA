-----------------------------------------------------------------------------------
-- fft_guard_interval
--
--		pipelined_8k
--		fifo_16k
--
-----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity fft_guard_interval is
	port (
		clk			: in std_logic;
		reset_n		: in std_logic;
		ce			: in std_logic;
		start		: in std_logic;
		cp_len_we	: in std_logic;
		xn_re		: in std_logic_vector ( 15 downto 0 );
		xn_im		: in std_logic_vector ( 15 downto 0 );
		xn_index 	: out std_logic_vector( 12 downto 0 ); 
		rfs			: out std_logic;
		rfd			: out std_logic;
		rd_en_s0	: in std_logic;
		empty_s0 	: out std_logic;
		xk_re 		: out std_logic_vector ( 15 downto 0 ); 
		xk_im 		: out std_logic_vector ( 15 downto 0 ); 
		ovflo		: out std_logic 
		);
end fft_guard_interval;


architecture Behavioral of fft_guard_interval is

	-- conservative scaling schedule to prevent overflows
	constant SCLAE_SCH_2K : std_logic_vector(13 downto 0) := B"0001_10_10_10_10_11";-- S = 2^(1 + 4*2 + 3) = 4096
	constant SCALE_SCH_8K : std_logic_vector(13 downto 0) := B"01_10_10_10_10_10_11";-- S = 2^(1 + 5*2 + 3) = 16384

	constant SCALE_2K : std_logic_vector(17 downto 0) := conv_std_logic_vector(4096,18); 
	constant SCALE_8K : std_logic_vector(17 downto 0) := conv_std_logic_vector(16384,18);

	constant SCALE_2K_BIN : std_logic_vector( 3 downto 0) := conv_std_logic_vector(12,4); 	-- log2(4096)
	constant SCALE_8K_BIN : std_logic_vector( 3 downto 0) := conv_std_logic_vector(14,4); 	-- log2(16384)

	-- inputs
	signal sclr_int			: std_logic;
	signal inicio			: std_logic;
	signal ce_reg			: std_logic;
	signal start_int		: std_logic;
	signal xn_re_int		: std_logic_VECTOR(15 downto 0);
	signal xn_im_int		: std_logic_VECTOR(15 downto 0);

	-- FFT=1 IFFT=0
	signal fwd_inv_int 	 	: std_logic := '0';								
	signal fwd_inv_we_int 	: std_logic;
	
	-- No. points
	signal nfft_int			: std_logic_vector(4 downto 0) := "01011"; 		
	signal nfft_we_int		: std_logic;
	
	--	scale_sch
	signal scale_sch_int	: std_logic_vector(13 downto 0) := SCLAE_SCH_2K;
	signal scale_sch_we_int	: std_logic;
	
	-- cp_len
	signal cp_len_8k		: std_logic_vector(12 downto 0) := "0001000000000";
	signal cp_len_2k		: std_logic_vector(12 downto 0) := "0001000000000";
	signal cp_len_int		: std_logic_vector(12 downto 0) := "0001000000000";
	signal cp_len_we_int 	: std_logic;

	-- others
	signal rfs_int 			: std_logic;
	signal rfd_int 			: std_logic;
	signal busy_int 		: std_logic;
	signal cpv_int 			: std_logic;
	signal dv_int 			: std_logic;
	signal edone_int 		: std_logic;
	signal done_int 		: std_logic;
	signal ovflo_int 		: std_logic;
	
	-- output
	signal xk_re_int 		: std_logic_VECTOR(15 downto 0);
	signal xk_im_int 		: std_logic_VECTOR(15 downto 0);
	signal xn_index_int 	: std_logic_VECTOR(12 downto 0);
	signal xk_index_int 	: std_logic_VECTOR(12 downto 0);
	
	component pipelined_8k
	port (
		ce				: IN std_logic;
		sclr			: IN std_logic;
		clk				: IN std_logic;
		start			: IN std_logic;
		nfft			: IN std_logic_VECTOR(4 downto 0);
		nfft_we			: IN std_logic;
		fwd_inv			: IN std_logic;
		fwd_inv_we		: IN std_logic;
		scale_sch		: IN std_logic_VECTOR(13 downto 0);
		scale_sch_we	: IN std_logic;
		cp_len 			: IN std_logic_VECTOR(12 downto 0); 
		cp_len_we 		: IN std_logic; 
		--
		xn_re 		: in  STD_LOGIC_VECTOR ( 15 downto 0 ); 
		xn_im 		: in  STD_LOGIC_VECTOR ( 15 downto 0 ); 
		xk_re 		: out STD_LOGIC_VECTOR ( 15 downto 0 ); 
		xk_im 		: out STD_LOGIC_VECTOR ( 15 downto 0 ); 
		xn_index 	: out STD_LOGIC_VECTOR ( 12 downto 0 ); 
		xk_index 	: out STD_LOGIC_VECTOR ( 12 downto 0 ); 
		--
		rfs			: OUT std_logic;
		rfd			: OUT std_logic;
		busy		: OUT std_logic;
		cpv 		: OUT STD_LOGIC; 
		dv			: OUT std_logic;
		edone		: OUT std_logic;
		done 		: OUT std_logic;
		ovflo		: OUT std_logic
		);
	end component;
	
	-- fifo stage 0
	signal wr_en_s0			: std_logic;
	signal threshod_s0		: std_logic_vector(13 downto 0);

	-- fifo I
	signal I_bb_16			: std_logic_vector(15 downto 0);
	signal I_full_s0		: std_logic;
	signal I_prog_full_s0		: std_logic;
	signal I_empty_s0		: std_logic;
	
	-- fifo Q
	signal Q_bb_16			: std_logic_vector(15 downto 0);
	signal Q_full_s0		: std_logic;
	signal Q_prog_full_s0		: std_logic;
	signal Q_empty_s0		: std_logic;

	component fifo_16k
	port (
		clk				: IN std_logic;
		wr_en			: IN std_logic;
		din				: IN std_logic_VECTOR(15 downto 0);
		rd_en			: IN std_logic;
		dout			: OUT std_logic_VECTOR(15 downto 0);
		empty			: OUT std_logic;
		full			: OUT std_logic;
		prog_full		: OUT std_logic;
		prog_full_thresh	: IN std_logic_VECTOR(13 downto 0)
	);
	end component;

begin

	sclr_int <= not reset_n;
	
	-------------------------------------------------------------------------------------------------------
	-- XFFT instance
	-------------------------------------------------------------------------------------------------------

	cp_len_8k <=	"0100000000000" when GI = 4 else 		-- 2048
						"0010000000000" when GI = 8 else  	-- 1024
						"0001000000000" when GI = 16 else 	-- 512
						"0000100000000" when GI = 32 else 	-- 256
						(others => '0'); 							 	
	cp_len_2k <=	"0100000000000" when GI = 4 else 		-- 512
						"0010000000000" when GI = 8 else	-- 256
						"0001000000000" when GI = 16 else	-- 128
						"0000100000000" when GI = 32 else	-- 64
						(others => '0'); 					-- 0
	
	cp_len_int		<= cp_len_2k 	when OFDM = 2 else cp_len_8k;
	scale_sch_int	<= SCLAE_SCH_2K	when OFDM = 2 else SCALE_SCH_8K;
	nfft_int		<= "01011"   	when OFDM = 2 else "01101";

	Inst_pipelined_8k : pipelined_8k
	port map (
		clk 			=> clk,
		ce				=> ce,
		sclr 			=> sclr_int,
		--
		start 			=> start_int,
		nfft 			=> nfft_int,
		nfft_we			=> nfft_we_int,
		fwd_inv 		=> fwd_inv_int,
		fwd_inv_we 		=> fwd_inv_we_int,
		scale_sch 	 	=> scale_sch_int,
		scale_sch_we 	=> scale_sch_we_int,
		cp_len 			=> cp_len_int,
		cp_len_we 		=> cp_len_we,			-- cp_len_we_int,
		--
		xn_re 			=> xn_re,				-- xn_re_int,
		xn_im 			=> xn_im,				-- xn_im_int,
		xn_index 		=> xn_index,			-- xn_index_int,
		--
		xk_re 			=> xk_re_int,
		xk_im 			=> xk_im_int,
		xk_index 		=> xk_index_int,
		--
		rfs				=> rfs_int,
		rfd 			=> rfd,				-- rfd_int,
		busy 			=> busy_int,
		dv 				=> dv_int,
		cpv 			=> cpv_int,
		edone 			=> edone_int,
		done 			=> done_int,
		ovflo 			=> ovflo_int 
	);

	-------------------------------------------------------------------------------------------------------
	-- XFFT Core Control
	-------------------------------------------------------------------------------------------------------

	process (clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				inicio <= '0';
				ce_reg <= '0';
			elsif ce = '1' then		
				inicio <= '1';
				ce_reg <= inicio;
			end if;
		end if;
	end process;

	control : process (clk)
	begin
		if (clk = '1' and clk'event) then
			if reset_n = '0' then
				nfft_we_int 	  <= '0';
				fwd_inv_we_int   <= '0';
				scale_sch_we_int <= '0';
				
				-- other signals
				start_int <= '0';
			
			elsif ce_reg = '1' then		
				nfft_we_int 	  	<= '0';
				fwd_inv_we_int   	<= '0';
				scale_sch_we_int 	<= '0';
			
				-- other signals (repeted)
				start_int <= start;
			--	rfd 	 <= rfd_int;
				rfs	 	 <= rfs_int;
				ovflo 	 <= ovflo_int;

			elsif inicio = '1' then		
				nfft_we_int 	  	<= '1';
				fwd_inv_we_int   	<= '1';
				scale_sch_we_int 	<= '1';

				-- other signals (repeted)
				start_int <= start;
			--	rfd		 <= rfd_int;
				rfs  	 <= rfs_int;
				ovflo 	 <= ovflo_int;

			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- Stage #0 Fifos
	----------------------------------------------------------------------------
	
	wr_en_s0 <= dv_int;
	
	threshod_s0 <= conv_std_logic_vector (10239,14);
--		conv_std_logic_vector (10239,14) when GI = 4  and OFDM = 8 else 		
--		conv_std_logic_vector (9215,14) when GI = 8  and OFDM = 8 else 		
--		conv_std_logic_vector (8703,14)	when GI = 16 and OFDM = 8 else
--		conv_std_logic_vector (8447,14)	when GI = 32 and OFDM = 8 else
--		conv_std_logic_vector (8191,14)	when GI = 0  and OFDM = 8 else
--		conv_std_logic_vector (2559,14) when GI = 4  and OFDM = 2 else
--		conv_std_logic_vector (2303,14) when GI = 8  and OFDM = 2 else
--		conv_std_logic_vector (2175,14) when GI = 16 and OFDM = 2 else
--		conv_std_logic_vector (2111,14) when GI = 32 and OFDM = 2 else
--		conv_std_logic_vector (2047,14) when GI = 0  and OFDM = 2 else
--		(others => '1'); 	
		
	Inst_fifo_stage0_I: fifo_16k 
	PORT MAP(
		clk				=> clk,
		wr_en			=> wr_en_s0,
		din				=> xk_re_int,
		rd_en			=> rd_en_s0,
		dout			=> I_bb_16,
		empty			=> I_empty_s0,
		full			=> I_full_s0,
		prog_full		=> I_prog_full_s0,
		prog_full_thresh	=> threshod_s0
	);

	Inst_fifo_stage0_Q: fifo_16k 
	PORT MAP(
		clk				=> clk,
		wr_en			=> wr_en_s0,
		din				=> xk_im_int,
		rd_en			=> rd_en_s0,
		dout			=> Q_bb_16,
		empty			=> Q_empty_s0,
		full			=> Q_full_s0,
		prog_full		=> Q_prog_full_s0,
		prog_full_thresh	=> threshod_s0
	);

	xk_re	<= I_bb_16 when I_empty_s0 = '0' else (others => '0');
	xk_im	<= Q_bb_16 when Q_empty_s0 = '0' else (others => '0');

	empty_s0 <= I_empty_s0 and Q_empty_s0;


end Behavioral;
