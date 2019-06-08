-------------------------------------------------------------------------------------
-- Frame Adapter
--
-- This module synchronizes the output of the blocks:
-- 	. QAM_mapper 
-- 	. TPS_generator
-- 	. Pilot_generator
-- so that they come at the right moment regarding to data acquisition of the block
--	. FFT_Guard_Interval
--
-- At the output of the Frame Adapter there is a multiplexor to select the carrier that
-- corresponds to the index generated by the reading counter of the Symbol_Interleaver.
--
-------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity frame_adapter is
	PORT(
		clk 			: IN  std_logic;
		reset_n			: IN  std_logic;
		ce				: IN  std_logic;		
		-- contadores_lectura
		init			: IN  std_logic;	
		index	 		: IN  std_logic_vector(12 downto 0);
		index_flags		: IN  std_logic_vector(3 downto 0);
		frame_indx		: OUT std_logic_VECTOR(6 downto 0);
		-- data carrier gen
		qam_re			: IN  std_logic_vector(15 downto 0);
		qam_im			: IN  std_logic_vector(15 downto 0);
		-- fft_guard_interval
		xn_re			: OUT std_logic_vector(15 downto 0);
		xn_im			: OUT std_logic_vector(15 downto 0)
		);
end frame_adapter;


architecture Behavioral of frame_adapter is

	SIGNAL fin_frame	: std_logic;
	SIGNAL frame0		: std_logic_vector(6 downto 0);	
	SIGNAL frame1		: std_logic_vector(6 downto 0);
	SIGNAL frame2		: std_logic_vector(6 downto 0);
	SIGNAL frame3		: std_logic_vector(6 downto 0);

	SIGNAL index1: std_logic_vector(12 downto 0);
	SIGNAL index2: std_logic_vector(12 downto 0);
	SIGNAL index3: std_logic_vector(12 downto 0);
	
	SIGNAL flags1: std_logic_vector(3 downto 0);
	SIGNAL flags2: std_logic_vector(3 downto 0);
	SIGNAL flags3: std_logic_vector(3 downto 0);
	SIGNAL flags4: std_logic_vector(3 downto 0);

	SIGNAL init1 : std_logic;
	SIGNAL init2 : std_logic;
	SIGNAL init3 : std_logic;
	
	----------------------------------------------------------------------------------	
	-- PRBS Generator: 1 + x^2 + x^11
	----------------------------------------------------------------------------------	

	SIGNAL new_data		: std_logic;
	SIGNAL init_prbs	: std_logic;
	SIGNAL salida_prbs	: std_logic;	
	SIGNAL prbs_sequence 	: std_logic_vector(11 downto 0);

	-- BPSK boosted values in 1.0.15 Fixed Point --> +/- 1 
	constant POSITIVE_BSPK : std_logic_vector(15 downto 0) := X"7FFF";	
	constant NEGATIVE_BSPK : std_logic_vector(15 downto 0) := X"8000"; 
	constant PRBS_INIT_SEQUENCE : std_logic_vector(10 downto 0) := B"1111_1111_111";

	COMPONENT registro_prbs
	PORT(
		clk 			: IN std_logic;
		reset_n 		: IN std_logic;
		ce 				: IN std_logic;
		init 			: IN std_logic;
		init_val 		: IN std_logic;
		entrada 		: IN std_logic;          
		salida 			: OUT std_logic
		);
	END COMPONENT;
	
	----------------------------------------------------------------------------------	
	-- tps and pilots carriers
	----------------------------------------------------------------------------------	
	SIGNAL continua		: std_logic;
	SIGNAL dispersa		: std_logic;
	SIGNAL tps_rdy		: std_logic;
	SIGNAL zero_rdy		: std_logic;
	SIGNAL pilot_rdy	: std_logic;
	SIGNAL tps_re		: std_logic_vector(15 downto 0);
	SIGNAL pilot_re		: std_logic_vector(15 downto 0);
	SIGNAL zero			: std_logic_vector(15 downto 0);

	COMPONENT tps_gen
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		frame_indx	: IN std_logic_vector(6 downto 0);          
		tps_re	 	: OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;
	
	COMPONENT scatt_detector
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		carrier_indx	: IN  std_logic_vector(12 downto 0);	-- k
		frame_indx	: IN  std_logic_vector(6  downto 0);	-- l
		dispersa	: OUT std_logic
		);
	END COMPONENT;
	

begin

	-------------------------------------------------------------------------------------
	-- Symbols counter --> frame_indx ready at 		start0 + 4
	-------------------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or fin_frame = '1' then
				frame0 <= (others => '1');
			elsif ce = '1' and init = '1' then 		-- init = start3
				frame0 <= frame0 + 1;
			end if;
		end if;
	end process;

	frame_indx 	<= frame0; 	
	fin_frame 	<= '1' when frame0 = conv_std_logic_vector(68, 7) else '0';
			
	-----------------------------------------------------------------------------
	-- The PRBS Generator is initialized so that the first output bit occurs at 
	-- the kmin carrier. A new value is generated at each non null carrier.
	--
	--	salida_prbs ready from start0 + 8	
	-----------------------------------------------------------------------------

	new_data <= not(flags3(0)) and flags3(3);	-- not(zero) and (cnt_rdy) at start7
	init_prbs <= init3;							-- start6

	gen_registros_prbs: for i in 0 to 10 generate
		Inst_registro_prbs: registro_prbs PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce		=> new_data,
			init 		=> init_prbs,
			init_val	=> PRBS_INIT_SEQUENCE(i),
			entrada 	=> prbs_sequence(i),
			salida 		=> prbs_sequence(i+1)
		);
	end generate;
	
	prbs_sequence(0) 	<= prbs_sequence(2) xor prbs_sequence(11);	
	salida_prbs		<= prbs_sequence(0);	

	----------------------------------------------------------------------------
	-- Pilot Generator
	--	pilot_re(0) ready from 		start0 + 8
	----------------------------------------------------------------------------

	continua	 <= flags4(1);			-- start0 + 8

	Inst_scatt_detector:	scatt_detector 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		frame_indx	=> frame0,		-- start0 + 4
		carrier_indx	=> index3,		-- start0 + 7
		dispersa	=> dispersa		-- start0 + 8	
	);
	
	pilot_rdy <= (continua or dispersa) and flags4(3);
	pilot_re  <= POSITIVE_BSPK when salida_prbs = '1' else NEGATIVE_BSPK;	

	----------------------------------------------------------------------------
	-- TPS Generator 
	--	tps_re(0) ready from		start0 + 8
	----------------------------------------------------------------------------

	Inst_tps_gen: tps_gen 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		frame_indx	=> frame3,		-- start0 + 7
		tps_re 		=> tps_re
	);	
	
	tps_rdy <= flags4(2) and flags4(3);

	----------------------------------------------------------------------------
	-- Multiplexor at the output of the Frame Adapter
	--	zero(0) ready from  		start0 + 8
	----------------------------------------------------------------------------

	zero 	<= conv_std_logic_vector(0, 16);
	zero_rdy <= flags4(0) and flags4(3);

	xn_re	<= zero when zero_rdy 	= '1' else
--				tps_re 		when tps_rdy 	= '1' else
--				pilot_re	when pilot_rdy 	= '1' else 
				qam_re;
					
	xn_im <= zero when zero_rdy 	= '1' else
--				zero when tps_rdy 	= '1' else
--				zero when pilot_rdy 	= '1' else 
				qam_im;
																
	----------------------------------------------------------------------------
	-- Symbol_Interleaver	= 1(ROM) + 1(RAM) = 2 cycles
	-- QAM_Mapper 			= 1(ROM) + 1(Mux) = 2 cycles	
	----------------------------------------------------------------------------
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				frame1 <= (others => '0');
				frame2 <= (others => '0');
				frame3 <= (others => '0');
			elsif ce = '1' then
				frame1 <= frame0;
				frame2 <= frame1;
				frame3 <= frame2;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				index1 <= (others => '0');
				index2 <= (others => '0');
				index3 <= (others => '0');
			elsif ce = '1' then
				index1 <= index;
				index2 <= index1;
				index3 <= index2;
			end if;
		end if;
	end process;		
		
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				flags1 <= (others => '0');
				flags2 <= (others => '0');
				flags3 <= (others => '0');
				flags4 <= (others => '0');
			elsif ce = '1' then
				flags1 <= index_flags;
				flags2 <= flags1;
				flags3 <= flags2;
				flags4 <= flags3;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				init1 <= '0';
				init2 <= '0';
				init3 <= '0';
			elsif ce = '1' then
				init1 <= init;		-- start4
				init2 <= init1;		-- start5
				init3 <= init2;		-- start6
			end if;
		end if;
	end process;

end Behavioral;
