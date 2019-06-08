---------------------------------------------------------------------------------
-- modulator:
--
--		data_carriers_gen
--		frame_adapter
--		fft_guard_interval
--
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity modulator is
	PORT(
		clk 				: IN std_logic;
		reset_n	 		: IN std_logic;
		ce 				: IN std_logic;
		
		-- entrada al inner_interleaver 		
		new_data_hp		: IN  std_logic;
		entrada_hp 		: IN  std_logic;

	-- new_data_lp		: IN  std_logic;
	-- entrada_lp		: IN  std_logic;

		-- salidas del symbol_interleaver
		si_wr_fin 		: OUT std_logic;
		fa_frame_indx	: OUT std_logic_VECTOR(6 downto 0);

		-- time domain de la fft
		xn_rdy			: OUT std_logic;
		xn_re				: OUT std_logic_VECTOR(15 downto 0);
		xn_im				: OUT std_logic_VECTOR(15 downto 0);
		
		-- freq domain y fifo_16k interface
		rd_en_s0			: IN 	std_logic;
		empty_s0			: OUT	std_logic;
		xk_ovflo			: OUT	std_logic;
		xk_re_s0			: OUT std_logic_VECTOR(15 downto 0);
		xk_im_s0			: OUT std_logic_VECTOR(15 downto 0)
	);
end modulator;


architecture Behavioral of modulator is

	SIGNAL new_data_lp		: std_logic;
	SIGNAL entrada_lp 		: std_logic;

	-------------------------------------------------------------------
	-- data carrier generator
	-------------------------------------------------------------------

	SIGNAL start_pulses		: std_logic_vector(4  downto 0);
	SIGNAL index_int			: std_logic_vector(12 downto 0);
	SIGNAL index_flags_int	: std_logic_vector(3  downto 0);

	COMPONENT data_carriers_gen
	PORT(
		clk 			: IN 	std_logic;
		reset_n 		: IN 	std_logic;
		ce 			: IN 	std_logic;

		-- entradas al bit_interleaver
      new_data		: IN std_logic;
		entrada 		: IN std_logic;

		-- salidas del qam_mapper
		qam_re 		: OUT std_logic_vector(15 downto 0);
		qam_im 		: OUT std_logic_vector(15 downto 0);
		qam_rdy		: OUT std_logic;

		-- contadores_lectura
		start_pulses	: OUT std_logic_vector(4  downto 0);
		index				: OUT std_logic_vector(12 downto 0);
		index_flags		: OUT std_logic_vector(3  downto 0)
		);
	END COMPONENT;

	-------------------------------------------------------------------
	-- frame adapter
	-------------------------------------------------------------------

	SIGNAL qam_re	 	: std_logic_vector(15 downto 0);
	SIGNAL qam_im		: std_logic_vector(15 downto 0);
	SIGNAL qam_rdy		: std_logic;
	SIGNAL frame_indx_int	: std_logic_vector(6  downto 0);  

	COMPONENT frame_adapter
	PORT(
		clk 			: IN 	std_logic;
		reset_n 		: IN 	std_logic;
		ce 			: IN 	std_logic;

		-- contadores_lectura
		init 			: IN std_logic;
		index 		: IN std_logic_vector(12 downto 0);
		index_flags : IN std_logic_vector(3 downto 0);          
		frame_indx	: OUT std_logic_VECTOR(6 downto 0);

		-- data carrier gen output
		qam_re 		: IN std_logic_vector(15 downto 0);
		qam_im 		: IN std_logic_vector(15 downto 0);

		-- fft_guard_interval input
		xn_re 		: OUT std_logic_vector(15 downto 0);
		xn_im 		: OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;

	-------------------------------------------------------------------
	-- fft and guard interval
	-------------------------------------------------------------------

	SIGNAL fft_start_aux	:  std_logic;
	SIGNAL fft_start		:  std_logic;
	SIGNAL xn_re_int		:  std_logic_vector(15 downto 0);
	SIGNAL xn_im_int 		:  std_logic_vector(15 downto 0);
	SIGNAL xn_index_int	:  std_logic_vector(12 downto 0);
	SIGNAL cp_len_we		:  std_logic;
	SIGNAL rfs 	 	 		:  std_logic;
	SIGNAL rfd 	 	 		:  std_logic;
	SIGNAL ovflo	 		:  std_logic;

	component contadores_lectura
	port(
		clk 			: IN 	std_logic;
		reset_n 		: IN 	std_logic;
		ce 			: IN 	std_logic;
		start 		: IN 	std_logic;          
		ready 		: OUT std_logic
		);
	end component;

	COMPONENT fft_guard_interval
	PORT(
		clk 			: IN 	std_logic;
		reset_n 		: IN 	std_logic;
		ce 			: IN 	std_logic;
		start 		: IN  std_logic;
		cp_len_we 	: IN  std_logic;
		xn_re 		: IN  std_logic_vector(15 downto 0);
		xn_im 		: IN  std_logic_vector(15 downto 0);
		xn_index 	: OUT std_logic_vector(12 downto 0);
		rfs 			: OUT std_logic;
		rfd 			: OUT std_logic;
		rd_en_s0 	: IN  std_logic;          
		empty_s0 	: OUT std_logic;
		xk_re 		: OUT std_logic_vector(15 downto 0);
		xk_im 		: OUT std_logic_vector(15 downto 0);
		ovflo 		: OUT std_logic
		);
	END COMPONENT;	
	
begin

	----------------------------------------------------------------------------
	-- Data Carriers Generator
	----------------------------------------------------------------------------
	
	Inst_data_carriers_gen: data_carriers_gen PORT MAP(
		clk 				=> clk,
		reset_n 			=> reset_n,
		ce 				=> ce,
		--
		new_data 		=> new_data_hp,
		entrada 			=> entrada_hp,
		--
		qam_rdy			=> qam_rdy,
		qam_re 			=> qam_re,
		qam_im 			=> qam_im,
		--
		start_pulses	=> start_pulses,
		index 			=> index_int,
		index_flags 	=> index_flags_int
	);
	
	si_wr_fin		<= start_pulses(0);

	----------------------------------------------------------------------------
	-- Frame Adapter
	----------------------------------------------------------------------------
			
			--		init 		 			 = start3
			--
			--		frame_indx_int		 = start4
			--		index, index_flags = start4
			--
			-- 	qam_re(0) 			 = start0 + 8
			--
			-- 	xn_re(0)  			 = start0 + 8

	Inst_frame_adapter: frame_adapter PORT MAP(
		clk 				=> clk,
		reset_n 			=> reset_n,
		ce 				=> ce,
		init				=> start_pulses(3),
		index 			=> index_int,
		index_flags 	=> index_flags_int,
		frame_indx		=> frame_indx_int,
		qam_re			=> qam_re,
		qam_im			=> qam_im,
		xn_re				=> xn_re_int,
		xn_im				=> xn_im_int
	);
	
	xn_re  <= xn_re_int;
	xn_im  <= xn_im_int;
	
	fa_frame_indx	<= frame_indx_int;

	----------------------------------------------------------------------------
	-- FFT and Guard Interval
	----------------------------------------------------------------------------

			--		cnt_start = start0
			--
			-- 	cnt_ready = cnt_start + 3 = start0 + 3
			--
			-- 	fft_start = cnt_ready 
			--					 = start0 + 3
			--
			-- 	xn_re(0)  = fft_start + 5 
			--					 = start0 + 8
	
	Inst_contadores_lectura : contadores_lectura PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,	
		start		=>	start_pulses(0),	
		ready 	=> fft_start_aux
	);

	fft_start <= fft_start_aux and rfs;
	cp_len_we <= rfs;
	
	Inst_fft_guard_interval: fft_guard_interval PORT MAP(
		clk 					=> clk,
		reset_n 				=> reset_n,
		ce 					=> ce,		
		start 				=> fft_start,
		cp_len_we			=> cp_len_we,
		rfs 					=> rfs,
		rfd 					=> rfd,
		xn_re 				=> xn_re_int,
		xn_im 				=> xn_im_int,
		xn_index 			=> xn_index_int,
		rd_en_s0				=> rd_en_s0,
		empty_s0 			=> empty_s0,
		xk_re					=> xk_re_s0,
		xk_im	 				=> xk_im_s0,
		ovflo 				=> ovflo 
	);

	xn_rdy 	<= rfd;
	xk_ovflo	<= ovflo;
	
end Behavioral;