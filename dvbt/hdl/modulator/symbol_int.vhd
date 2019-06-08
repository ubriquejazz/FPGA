---------------------------------------------------------------------------------
-- SYMBOL INTERLEAVER
--
-- Permutation functions were tabuled into two ROMs:
--
--		ROM 6048 x 13 bits			ROM 1512 x 13 bits
--		----------------------		----------------------
--    * tabla_8k_pares.coe			* tabla_2k_pares.coe
--    * tabla_8k_impares.coe		* tabla_2k_impares.coe
--
-- These ROMs show the order when we're writing (or reading) to store the input
-- (or to get the output) depending on the case of the transmission.
--
-- During the symbols interleaving, odd symbols and even symbols are distingued.
-- Two RAM are used to stored them:
--    * one for even symbols and
--    * other for odd symbols
--
-- The address to write these RAMs is the output of a counter (writing counter)
-- The address to read these RAMs is the output of other counter but this is
-- more complex generation (reading counter).
---------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
	
entity symbol_int is
	port (
		clk			: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce			: IN  std_logic;		
		sink_wrd 	: IN  std_logic_vector(5  downto 0);
		sink_val	: IN  std_logic;  
		start_pulses: OUT std_logic_vector(4  downto 0);		
		indx_ofdm	: OUT std_logic_vector(12 downto 0);
		indx_flags	: OUT std_logic_vector(2  downto 0);	
		source_val	: OUT std_logic;
		source_sop	: OUT std_logic;
		source_eop	: OUT std_logic;
		source_wrd	: OUT std_logic_vector(5  downto 0)
	);
end symbol_int;


architecture Behavioral of symbol_int is

	COMPONENT contadores_escritura
	PORT(
		clk				: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce				: IN  std_logic;
	--	si_wr_data 	 	: IN  std_logic_vector(5 downto 0);
		si_wr_nd		: IN  std_logic;   
		indice_i		: OUT std_logic_vector(12 downto 0);
		si_wr_par	 	: OUT std_logic;
		si_wr_fin		: OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT contadores_lectura
	PORT(
		clk				: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce				: IN  std_logic;
		start			: IN  std_logic;							
--		rfs				: OUT std_logic;	
		indx_val		: OUT std_logic;
		indx_sop		: OUT std_logic;
		indx_eop		: OUT std_logic;
		indx_1512 		: OUT std_logic_VECTOR(12 downto 0);		
		indx_ofdm 		: OUT std_logic_VECTOR(12 downto 0);
		indx_flags		: OUT std_logic_VECTOR(2 downto 0)					
	);					
	END COMPONENT;
	
	-- Writing Counters
	signal indice_i			: std_logic_vector(12 downto 0);
	signal start0			: std_logic;
	signal si_wr_par_int	: std_logic;
	signal simbolo_par		: std_logic;
	signal simbolo_impar	: std_logic;	
	-- delayer start0 para ready del salida_si
	signal start1			: std_logic;
	signal start2			: std_logic;
	signal start3			: std_logic;
	signal start4			: std_logic;
	-- Reading Counters
	SIGNAL cnt_start		: std_logic;
	SIGNAL indx_val			: std_logic;
	SIGNAL indx_sop			: std_logic;
	SIGNAL indx_eop			: std_logic;
	SIGNAL indice_k			: std_logic_vector(12 downto 0);
	SIGNAL indice_j 		: std_logic_vector(12 downto 0);
	SIGNAL flags		 	: std_logic_vector(2 downto 0);	
	SIGNAL sync_stream		: std_logic_vector(2 downto 0);	
	SIGNAL flags5	 		: std_logic_vector(18 downto 0); -- 6 + 13 = 19 bits
	SIGNAL flags6		 	: std_logic_vector(18 downto 0);	
	-- Rest of the read interface
	signal inicio_lecturas	: std_logic;
	signal ce_lectura 		: std_logic;
	signal tabla_addr_2k	: std_logic_vector(10 downto 0);
	signal tabla_addr_8k	: std_logic_vector(12 downto 0);	
	-- H(q) Permutation Tables
	signal ce_tabla_impares	: std_logic;
	signal ce_tabla_pares	: std_logic;
	signal dir_impares		: std_logic_vector(12 downto 0);
	signal dir_impares_2k	: std_logic_vector(12 downto 0);
	signal dir_impares_8k	: std_logic_vector(12 downto 0);
	signal dir_pares		: std_logic_vector(12 downto 0);
	signal dir_pares_2k		: std_logic_vector(12 downto 0);
	signal dir_pares_8k		: std_logic_vector(12 downto 0);
	-- Symbol Memories
	signal ce_memo_impares	: std_logic;
	signal ce_memo_pares	: std_logic;
	signal addr_memo_impares: std_logic_vector(12 downto 0);
	signal addr_memo_pares	: std_logic_vector(12 downto 0);
	signal salida_impares	: std_logic_vector(5 downto 0);
	signal salida_pares		: std_logic_vector(5 downto 0);
	signal wea_par			: std_logic;
	signal wea_impar		: std_logic;

	signal sclr_int	: std_logic;
	
begin

	sclr_int <= not reset_n;
	
	Inst_contadores_escritura: contadores_escritura PORT MAP(
		clk 			=> clk,
		reset_n 		=> reset_n,
		ce 				=> ce,	
	--	si_wr_data 	 	=> sink_wrd,
		si_wr_nd 		=> sink_val,
		indice_i		=> indice_i,
		si_wr_par 		=> si_wr_par_int,
		si_wr_fin 		=> start0
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
	-- cnt_start = start0 + 1 to FFT synchronization
	----------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				start1 <= '0';	
			elsif ce = '1' then
				start1 <= start0;	
			end if;
		end if;
	end process;

	cnt_start <= start1;

	----------------------------------------------------------------------------
	-- Delay introduced by Contadores_Lectura = 3 cycles
	----------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				start2 <= '0';
				start3 <= '0';
				start4 <= '0';
			elsif ce = '1' then
				start2 <= start1;
				start3 <= start2;
				start4 <= start3;
			end if;
		end if;
	end process;	

	start_pulses <= start4 & start3 & start2 & start1 & start0;
	
	----------------------------------------------------------------------------
	-- Delay introduced by Symbol_Interleaver = 1(ROM) + 1(RAM) = 2 cycles
	----------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
--				start5 <= '0';
--				start6 <= '0';
				flags5 <= (others => '0');
				flags6 <= (others => '0');
			elsif ce = '1' then
--				start5 <= start4;
--				start6 <= start5;				
				flags5 <= sync_stream & flags & indice_j;
				flags6 <= flags5; -- start6;
			end if;
		end if;
	end process;	

	indx_ofdm	<= flags6(12 downto 0);		
	indx_flags	<= flags6(15 downto 13);
	source_val	<= flags6(18); 
	source_sop  <= flags6(17);
	source_eop 	<= flags6(16);
	source_wrd 	<= salida_impares when simbolo_par = '1' else salida_pares;
		
	----------------------------------------------------------------------------
	-- Reading Interface (indice_j, indice_k)
	----------------------------------------------------------------------------
	
	Inst_contadores_lectura: contadores_lectura PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,	
		start		=> cnt_start,		-- cnt_start = start0 + 1
		indx_val	=> indx_val,		-- cnt_ready = cnt_start + 3 = start0 + 4	
		indx_sop	=> indx_sop,
		indx_eop	=> indx_eop,		
		indx_1512 	=> indice_k,
		indx_ofdm	=> indice_j,		-- 13 bits, start4
		indx_flags	=> flags			-- 3 bits,  start4
	);
	
	sync_stream <= indx_val & indx_sop & indx_eop;
	ce_lectura  <= not(flags(2) or flags(1) or flags(0));
		
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				inicio_lecturas <= '0';	
			elsif cnt_start = '1' then
				inicio_lecturas <= '1';	
			end if;
		end if;
	end process;

	ce_tabla_pares <= inicio_lecturas and ce_lectura and indx_val and simbolo_impar;
	ce_tabla_impares <= inicio_lecturas and ce_lectura and indx_val and simbolo_par;

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				ce_memo_impares <= '0';
				ce_memo_pares	 <= '0';
			elsif ce = '1' then
				ce_memo_impares <= sink_val or (indx_val and simbolo_par);
				ce_memo_pares <= sink_val or (indx_val and simbolo_impar);
			end if;
		end if;
	end process;	
	
	tabla_addr_2k 	<= indice_k(10 downto 0) when OFDM = 2 else (others => '0');
	tabla_addr_8k 	<= indice_k(12 downto 0) when OFDM = 8 else (others => '0');

	--------------------------------------------------------------------
	-- Odd Symbols Memory. Deinterleaver y(elements) = u
	--------------------------------------------------------------------
	
	Inst_tabla_2k_impares : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "./mif/tabla_2k_impares.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 2048,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 11,
		width_a => 13,
		width_byteena_a => 1
	)
	PORT MAP (
		aclr0 => sclr_int,
		data_a => (others => '1'),
		wren_a => '0',
		address_a => tabla_addr_2k,
		clock0 => clk,
		clocken0 => ce_tabla_impares,
		q_a => dir_impares_2k
	);			
	
	Inst_symbol_memo_impares : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",	
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "UNUSED",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 8192,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "CLEAR0",
		outdata_reg_a => "CLOCK0",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 13,
		width_a => 6,
		width_byteena_a => 1
	)
	PORT MAP (
		aclr0 => sclr_int,
		address_a => addr_memo_impares,
		clock0 => clk,
		clocken0 => ce_memo_impares,
		data_a => sink_wrd,
		wren_a => wea_impar,
		q_a => salida_impares
	);	
	
	wea_impar		    <= simbolo_impar;
	dir_impares 		<= dir_impares_2k when OFDM = 2 else dir_impares_8k;
	addr_memo_impares	<= indice_i when simbolo_impar = '1' else dir_impares;
		
	------------------------------------------------------------------------
	-- Even Symbols Memory. Standard interleaver y = u(Elements)
	------------------------------------------------------------------------

	Inst_tabla_2k_pares : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "./mif/tabla_2k_pares.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 2048,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 11,
		width_a => 13,
		width_byteena_a => 1
	)
	PORT MAP (
		aclr0 => sclr_int,
		data_a => (others => '1'),
		wren_a => '0',
		address_a => tabla_addr_2k,
		clock0 => clk,
		clocken0 => ce_tabla_pares,
		q_a => dir_pares_2k
	);			

	Inst_symbol_memo_pares : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "UNUSED",		
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 8192,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "CLEAR0",
		outdata_reg_a => "CLOCK0",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 13,
		width_a => 6,
		width_byteena_a => 1
	)
	PORT MAP (
		aclr0 => sclr_int,
		address_a => addr_memo_pares,
		clock0 => clk,
		clocken0 => ce_memo_pares,		
		data_a => sink_wrd,
		wren_a => wea_par,
		q_a => salida_pares
	);
	
	wea_par	<= simbolo_par;
	dir_pares <= dir_pares_2k when OFDM = 2 else dir_pares_8k;
	addr_memo_pares <= indice_i when simbolo_par = '1' else dir_pares;
				
end Behavioral;