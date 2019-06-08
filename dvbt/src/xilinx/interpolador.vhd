library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity interpolador is
	port ( 	ce				: IN std_logic;
			reset_n			: IN std_logic;
			--
			clk0			: IN std_logic;
			clk1			: IN std_logic;
			clk2			: IN std_logic;
			--
			rd_en_s0		: OUT std_logic;
			empty_s0		: IN  std_logic;
			data_in			: IN  std_logic_VECTOR(15 downto 0);
			data_out 		: OUT std_logic_VECTOR(17 downto 0)					
	);
end interpolador;

architecture Behavioral of interpolador is

	signal sclr_int	: std_logic;

	-- 9143 KHz and 16 MHz readers
	signal en1_7_s1	: std_logic;	
	signal en1_7_s3	: std_logic;
	
	component contador7x 
   port (  clk 		: in  STD_LOGIC;
           ce 		: in  STD_LOGIC;
           reset_n	: in  STD_LOGIC;
           oe_7		: out STD_LOGIC);
	end component;

	-- 1/4 y 1/2 decimators
	signal diezmo7_28	: std_logic;
	signal diezmo7_14	: std_logic;

	COMPONENT diezmador7_28
	PORT(
		clk 			: IN std_logic;
		reset_n	 	: IN std_logic;
		ce 			: IN std_logic;
		fin_cuenta	: out STD_LOGIC;
		oe		 		: OUT std_logic);
	END COMPONENT;

	COMPONENT diezmador7_14
	PORT(
		clk 			: IN std_logic;
		ce 			: IN std_logic;
		reset_n	 	: IN std_logic;
		fin_cuenta	: out STD_LOGIC;
		oe		 		: OUT std_logic);
	END COMPONENT;

	---------------------------------------------------
	-- fifo stage 2 and 4
	---------------------------------------------------

	signal rd_en_s2	: std_logic;
	signal wr_en_s2	: std_logic;
	signal rd_en_s4	: std_logic;
	signal wr_en_s4	: std_logic;

	-- fifo stage2
	signal empty_s2		: std_logic;
	signal full_s2		: std_logic;
	signal x2			: std_logic_VECTOR(17 downto 0);
	signal y2			: std_logic_VECTOR(17 downto 0);

	-- fifo stage4
	signal empty_s4		: std_logic;
	signal full_s4		: std_logic;
	signal x4			: std_logic_VECTOR(17 downto 0);
	signal y4			: std_logic_VECTOR(17 downto 0);

	component fifo_16
	port (
		rst			: IN std_logic;
		wr_clk		: IN std_logic;
		wr_en		: IN std_logic;
		din			: IN std_logic_VECTOR(17 downto 0);
		rd_clk		: IN std_logic;
		rd_en		: IN std_logic;
		dout		: OUT std_logic_VECTOR(17 downto 0);
		empty		: OUT std_logic;
		full		: OUT std_logic);
	end component;	
	
	--------------------------------------------------
	-- filter stage 1 and 3
	--------------------------------------------------

	-- fir stage1
	signal rfd_s1	: std_logic;
	signal rdy_s1	: std_logic;
	signal nd_s1	: std_logic;
	signal x16_s1	: std_logic_VECTOR(15 downto 0);
	signal y33_s1	: std_logic_VECTOR(32 downto 0); 

	-- fir stage3
	signal rfd_s3	: std_logic;
	signal rdy_s3	: std_logic;
	signal nd_s3	: std_logic;
	signal x16_s3	: std_logic_VECTOR(15 downto 0);
	signal y33_s3	: std_logic_VECTOR(32 downto 0 ); 

	COMPONENT filter_64M
	PORT(
		ce 		: in STD_LOGIC;
		sclr 	: in STD_LOGIC;
		clk 	: in STD_LOGIC;
		nd 		: in STD_LOGIC;
		rfd 	: out STD_LOGIC; 
		rdy 	: out STD_LOGIC; 
		dout 	: out STD_LOGIC_VECTOR ( 32 downto 0 ); 
		din 	: in  STD_LOGIC_VECTOR ( 15 downto 0 ) 
		);
	END COMPONENT;

	COMPONENT filter_112M
	PORT(
		ce 		: in STD_LOGIC;
		sclr 	: in STD_LOGIC;
		clk 	: in STD_LOGIC;
		nd 		: in STD_LOGIC;
		rfd 	: out STD_LOGIC; 
		rdy 	: out STD_LOGIC; 
		dout 	: out STD_LOGIC_VECTOR ( 32 downto 0 ); 
		din 	: in  STD_LOGIC_VECTOR ( 15 downto 0 ) 
		);
	END COMPONENT;

begin

  sclr_int 	<= not reset_n;

  Inst_9143KHz_reader: contador7x 
   port map (
		clk 			=> clk1,				-- 64 MHz
		reset_n		=> reset_n,
		ce 			=> ce,
		oe_7	 		=> en1_7_s1			-- 9.143 MHz 
		);
	
  rd_en_s0 <= en1_7_s1 and not(empty_s0);

	----------------------------------------------------------------------------
	-- Stage #1 Filtering
	----------------------------------------------------------------------------
   
	x16_s1 <= data_in; 
	nd_s1 <= rfd_s1 and en1_7_s1 and not(empty_s0);

   Inst_filter_stage1: filter_64M
		PORT MAP (
			ce			 => ce,
			sclr 		 => sclr_int,
			clk 		 => clk1, 				-- 64 MHz
			nd			 => nd_s1,
			din 		 => x16_s1,
			dout 		 => y33_s1, 
			rfd 		 => rfd_s1,						
			rdy 		 => rdy_s1				-- 7 * 64 
	);

		data_out	<= sxt(y33_s1(32 downto 16), 18); 
	--	data_rdy	<= rdy_s1;
	--	clk_out 	<= clk1;	
	
end Behavioral;

--	----------------------------------------------------------------------------
--	-- Stage #2 Fifos
--	----------------------------------------------------------------------------
--
--	Inst_diezmo1_4: diezmador7_28 
--		PORT MAP(
--			clk 			=> clk1, 		-- 64 MHz
--			reset_n	 	=> reset_n,
--			ce 			=> rdy_s1,
--			oe		 		=> diezmo7_28		
--	);
--
--	wr_en_s2 <= diezmo7_28 and not(full_s2);
--	x2	<= sxt(y33_s1(32 downto 16), 18);
--
--   Inst_fifo_stage2: fifo_16		-- fifo_stage2
--		PORT MAP (
--			rst		=> sclr_int,
--			wr_clk	=> clk1, 			-- 64 MHz
--			wr_en		=> wr_en_s2,		
--			din		=> x2,
--			rd_clk	=> clk2, 			-- 112 MHz
--			rd_en		=> rd_en_s2,
--			dout		=> y2,
--			empty		=> empty_s2,
--			full		=> full_s2		
--	);
--
--   Inst_16MHz_reader: contador7x 
--		port map (
--		clk 			=> clk2,			-- 112 MHz
--		reset_n		=> reset_n,
--		ce 			=> ce,
--		oe_7	 		=> en1_7_s3		-- 16 MHz
--	);
--
--	-- leemos 1 de cada 7 ciclos de clock2 siempre que no esté vacía
--	rd_en_s2 <= en1_7_s3 and not(empty_s2); 							
--	
--	--	data_out	<= y2;
--	--	data_rdy	<= rd_en_s2;				
--	--	clk_out 	<= clk2;			
--
--	----------------------------------------------------------------------------	
--	-- Stage #3 Filtering
--	----------------------------------------------------------------------------
--
--	x16_s3 <= y2(17 downto 2);
--	nd_s3	<= rd_en_s2 and rfd_s3;		-- 16 MHz
--	
--	Inst_filter_stage3: filter_112M
--		PORT MAP (
--			ce			 => ce,
--			sclr 		 => sclr_int,
--			clk 		 => clk2, 			-- 112 MHz
--			nd			 => nd_s3,
--			din 		 => x16_s3,
--			dout 		 => y33_s3, 
--			rfd 		 => rfd_s3,
--			rdy 		 => rdy_s3		
--	);	
--	
--	--	data_out	<= sxt(y33_s3(32 downto 18), 16);  
--	--	data_rdy	<= rdy_s3;
--	--	clk_out 	<= clk2;	
--
--	----------------------------------------------------------------------------
--	-- Stage #4 Fifos
--	----------------------------------------------------------------------------
--  	
--	Inst_diezmo1_2: diezmador7_14
--		PORT MAP(
--			clk 			=> clk2, 		-- 112 MHz
--			reset_n	 	=> reset_n,
--			ce 			=> rdy_s3,
--			oe		 		=> diezmo7_14		
--	);
--	
--	wr_en_s4 <= diezmo7_14 and not(full_s4);					
--	x4 <= sxt(y33_s3(32 downto 16),18);  
--	
--	stage4: fifo_16
--		PORT MAP (
--			rst		=> sclr_int,
--			wr_clk	=> clk2, 		-- 112 MHz
--			wr_en		=> wr_en_s4,		
--			din		=> x4,
--			rd_clk	=> clk0, 		-- 56 MHz
--			rd_en		=> rd_en_s4,
--			dout		=> y4,
--			empty		=> empty_s4,
--			full		=> full_s4	
--	);
--	
--	-- Read unless is not empty 
--	rd_en_s4 <= not(empty_s4);
--	--	data_rdy	<= not(empty_s4);				
--	data_out	<= y4;		
--	--	clk_out 	<= clk0;			


