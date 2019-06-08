-------------------------------------------------------------------------------------
-- Data Carrier Generator
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity data_carriers_gen is
	PORT(
		clk 			: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce 				: IN  std_logic;
		sink_wrd 		: IN  std_logic_vector(5 downto 0);
    	sink_val		: IN  std_logic;
--		start_pulses	: OUT std_logic_vector(4  downto 0);
		indx_ofdm		: OUT std_logic_vector(12 downto 0);
		indx_flags		: OUT std_logic_vector(2  downto 0);
		qam_val			: OUT std_logic;
		qam_sop			: OUT std_logic;
		qam_eop			: OUT std_logic;
		qam_re 			: OUT std_logic_vector(15 downto 0);
		qam_im 			: OUT std_logic_vector(15 downto 0)		
		);
end data_carriers_gen;


architecture Behavioral of data_carriers_gen is

	COMPONENT bit_int
	PORT(
		clk 		: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		sink_wrd 	: IN  std_logic_vector(5 downto 0);
		sink_val 	: IN  std_logic;          
		source_wrd 	: OUT std_logic_vector(5 downto 0);
		source_val 	: OUT std_logic
		);
	END COMPONENT;	
	
	COMPONENT contadores_escritura
	PORT(
		clk			: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce			: IN  std_logic;
		si_wr_nd	: IN  std_logic;   
		indice_i	: OUT std_logic_vector(12 downto 0);
		si_wr_par	: OUT std_logic;
		si_wr_fin	: OUT std_logic
		);
	END COMPONENT;	
	
	COMPONENT symbol_int
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		sink_wrd 	: IN std_logic_vector(5 downto 0);
		sink_val 	: IN std_logic;
		start_pulses: OUT std_logic_vector(4 downto 0);
		source_sop 	: OUT std_logic;
		source_eop 	: OUT std_logic;
		source_val 	: OUT std_logic;
		source_wrd 	: OUT std_logic_vector(5 downto 0);
		indx_ofdm 	: OUT std_logic_vector(12 downto 0);
		indx_flags 	: OUT std_logic_vector(2 downto 0)
		);
	END COMPONENT;

	COMPONENT mapper_64qam
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		addr 		: IN std_logic_vector(5 downto 0);          
		xn_re 		: OUT std_logic_vector(15 downto 0);
		xn_im 		: OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;
	
	-- symbol interleaver 
	SIGNAL symbol_sink_wrd 	: std_logic_vector(5 downto 0);  
	SIGNAL symbol_sink_val	: std_logic;
	SIGNAL symbol_source_wrd: std_logic_vector(5 downto 0);  
	SIGNAL symbol_source_sop: std_logic;
	SIGNAL symbol_source_eop: std_logic;
	SIGNAL symbol_source_val: std_logic;
	SIGNAL symbol_indx_ofdm	: std_logic_vector(12 downto 0);
	SIGNAL symbol_indx_flags: std_logic_vector(2  downto 0);
	SIGNAL sync_stream		: std_logic_vector(2  downto 0);
	
	-- Writing Counters
	signal si_wr_par_int	: std_logic;
	signal simbolo_par		: std_logic;
	signal simbolo_impar	: std_logic;
	signal start0			: std_logic;
	SIGNAL start6			: std_logic;
	SIGNAL flags7: std_logic_vector(18 downto 0); -- 6 + 13 = 19 bits
	SIGNAL flags8: std_logic_vector(18 downto 0); 
	SIGNAL flags9: std_logic_vector(18 downto 0); 
	SIGNAL flagsA: std_logic_vector(18 downto 0); 
	SIGNAL flagsB: std_logic_vector(18 downto 0); 
	SIGNAL flagsC: std_logic_vector(18 downto 0); 
	
begin
	
	Inst_bit_int: bit_int 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_wrd 	=> sink_wrd,
		sink_val 	=> sink_val,
		source_wrd 	=> symbol_sink_wrd,
		source_val 	=> symbol_sink_val
	);		

	Inst_contadores_escritura: contadores_escritura PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,	
		si_wr_nd	=> symbol_sink_val,
		indice_i	=> open,
		si_wr_par	=> si_wr_par_int,
		si_wr_fin	=> start0
	);

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				simbolo_par <= '0';	
				simbolo_impar <= '1';
			elsif ce = '1' then
				simbolo_par <= si_wr_par_int;	
				simbolo_impar <= not si_wr_par_int;
			end if;
		end if;
	end process;	
		
	----------------------------------------------------------------------------
	-- Symbol_Interleaver = 1(ROM) + 1(RAM) = 2 cycles
	----------------------------------------------------------------------------
			--	indx_flags(3) = start0 + 1 + 3 cycles

	Inst_symbol_int: symbol_int 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_wrd 	=> symbol_sink_wrd,
		sink_val 	=> symbol_sink_val,
		start_pulses => open,
		indx_flags 	=> symbol_indx_flags,
		indx_ofdm	=> symbol_indx_ofdm,	
		source_sop	=> symbol_source_sop,
		source_eop	=> symbol_source_eop,
		source_val 	=> symbol_source_val,
		source_wrd	=> symbol_source_wrd
	);
	
	sync_stream <= symbol_source_val & symbol_source_sop & symbol_source_eop;
	
	----------------------------------------------------------------------------
	-- QAM_Mapper = 1(ROM) + 1(Mux) = 2 cycles	
	----------------------------------------------------------------------------
			--		qam_val = start0 + 1 + 3 + 2 + 2

	start6  <= symbol_source_val;

	Inst_mapper: mapper_64qam 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		addr 		=> symbol_source_wrd,
		xn_re 		=> qam_re,
		xn_im 		=> qam_im
	);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
--				start7 	<= '0';
--				start8	<= '0';
				flags7  <= (others => '0');
				flags8  <= (others => '0');				
				flags9  <= (others => '0');				
				flagsA  <= (others => '0');				
				flagsB  <= (others => '0');				
				flagsC  <= (others => '0');				
			elsif ce = '1' then
--				start7 	<= start6;
--				start8	<= start7;				
				flags7  <= sync_stream & symbol_indx_flags & symbol_indx_ofdm;
				flags8  <= flags7;
				flags9  <= flags8;
				flagsA  <= flags9;
				flagsB  <= flagsA;
				flagsC  <= flagsB;
			end if;
		end if;
	end process;
	
	qam_val <= flagsC(18); 	
	qam_sop <= flagsC(17); 
	qam_eop <= flagsC(16); 

	indx_ofdm	<= flagsC(12 downto 0);		
	indx_flags	<= flagsC(15 downto 13);	
	
end Behavioral;