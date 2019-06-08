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
	
entity symbol_int is
	port (
		clk			: IN 	std_logic;
		reset_n 	: IN  std_logic;
		ce			: IN  std_logic;
		
		-- interfaz de entrada/salida
		entrada 	: IN  std_logic_vector(5  downto 0);
		new_data	: IN  std_logic;  
		data_rdy	: OUT std_logic;  
		salida		: OUT std_logic_vector(5  downto 0);

		-- contadores_escritura
		start_pulses: OUT std_logic_vector(4  downto 0);
		
		-- contadores_lectura
		index		: OUT std_logic_vector(12 downto 0);
		indx_flags	: OUT std_logic_vector(3  downto 0)
	);
end symbol_int;


architecture Behavioral of symbol_int is

	COMPONENT contadores_escritura
	PORT(
		clk					: IN 	std_logic;
		reset_n 			: IN  std_logic;
		ce					: IN  std_logic;
	--	si_wr_data 		 	: IN  std_logic_vector(5 downto 0);
		si_wr_nd			: IN  std_logic;   
		indice_i			: OUT std_logic_vector(12 downto 0);
		si_wr_par		 	: OUT std_logic;
		si_wr_fin	 		: OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT contadores_lectura
	PORT(
		clk 			: IN std_logic;
		reset_n 		: IN std_logic;
		ce 				: IN std_logic;
		start 			: IN std_logic; 
		ready			: OUT std_logic; 
		indice_k	 	: OUT std_logic_vector(12 downto 0);
		indice_j		: OUT std_logic_vector(12 downto 0);
		j_piloto		: OUT std_logic;							
		j_tps			: OUT std_logic;							
		j_cero			: OUT std_logic							
		);
	END COMPONENT;

	COMPONENT tabla_2k_impares
	PORT(
			addra	: IN  std_logic_VECTOR(10 downto 0);
			clka	: IN  std_logic;
			douta	: OUT std_logic_VECTOR(12 downto 0);
			ena		: IN  std_logic
		);
	END COMPONENT;

	COMPONENT tabla_2k_pares
	PORT(
			addra	: IN  std_logic_VECTOR(10 downto 0);
			clka	: IN  std_logic;
			douta	: OUT std_logic_VECTOR(12 downto 0);
			ena		: IN  std_logic
		);
	END COMPONENT;

	COMPONENT tabla_8k_impares
	PORT(
			addra	: IN  std_logic_VECTOR(12 downto 0);
			clka	: IN  std_logic;
			douta	: OUT std_logic_VECTOR(12 downto 0);
			ena		: IN  std_logic
		);
	END COMPONENT;

	COMPONENT tabla_8k_pares
	PORT(
			addra	: IN  std_logic_VECTOR(12 downto 0);
			clka	: IN  std_logic;
			douta	: OUT std_logic_VECTOR(12 downto 0);
			ena		: IN  std_logic
		);
	END COMPONENT;

	COMPONENT symbol_memo
	PORT(
			addra	: IN  std_logic_VECTOR(12 downto 0);
			clka	: IN  std_logic;
			dina	: IN  std_logic_VECTOR(5 downto 0);
			wea		: IN  std_logic_VECTOR(0 downto 0);
			douta	: OUT std_logic_VECTOR(5 downto 0);
			ena		: IN  std_logic;
			ssra	: IN 	std_logic
		);
	END COMPONENT;
		
	-- Writing Counters
	signal indice_i			: std_logic_vector(12 downto 0);
	signal start0			: std_logic;
	signal si_wr_par_int	: std_logic;
	signal simbolo_par		: std_logic;
	signal simbolo_impar	: std_logic;
	
	-- delayer start0 para ready del salida_si
	signal start1: std_logic;
	signal start2: std_logic;
	signal start3: std_logic;
	signal start4: std_logic;
	signal start5: std_logic;
	signal start6: std_logic;

	-- Reading Counters
	SIGNAL cnt_start				: std_logic;
	SIGNAL ready_int				: std_logic;
	SIGNAL pilot_int				: std_logic;
	SIGNAL tps_int					: std_logic;
	SIGNAL zero_int					: std_logic;
	SIGNAL indice_j_int 			: std_logic_vector(12 downto 0);
	SIGNAL indice_k_int				: std_logic_vector(12 downto 0);

	-- Rest of the read interface
	signal inicio_lecturas		: std_logic;
	signal ce_lectura 			: std_logic;
	signal tabla_addr_2k			: std_logic_vector(10 downto 0);
	signal tabla_addr_8k			: std_logic_vector(12 downto 0);
		
	-- H(q) Permutation Tables
	signal ce_tabla_impares		: std_logic;
	signal ce_tabla_pares		: std_logic;
	signal dir_impares			: std_logic_vector(12 downto 0);
	signal dir_impares_2k		: std_logic_vector(12 downto 0);
	signal dir_impares_8k		: std_logic_vector(12 downto 0);
	signal dir_pares				: std_logic_vector(12 downto 0);
	signal dir_pares_2k			: std_logic_vector(12 downto 0);
	signal dir_pares_8k			: std_logic_vector(12 downto 0);

	-- Symbol Memories
	signal ce_memo_impares		: std_logic;
	signal ce_memo_pares			: std_logic;
	signal addr_memo_impares	: std_logic_vector(12 downto 0);
	signal addr_memo_pares		: std_logic_vector(12 downto 0);
	signal salida_impares		: std_logic_vector(5 downto 0);
	signal salida_pares			: std_logic_vector(5 downto 0);
	signal wea_par					: std_logic_vector(0 downto 0);
	signal wea_impar				: std_logic_vector(0 downto 0);

	signal sclr_int	: std_logic;
	
begin

	sclr_int <= not reset_n;

	----------------------------------------------------------------------------
	-- Writing Interface (indice_i)
	----------------------------------------------------------------------------

	Inst_contadores_escritura: contadores_escritura PORT MAP(
		clk 				=> clk,
		reset_n 			=> reset_n,
		ce 					=> ce,	
	--	si_wr_data 		 	=> entrada,
		si_wr_nd 			=> new_data,
		indice_i			=> indice_i,
		si_wr_par 			=> si_wr_par_int,
		si_wr_fin 			=> start0
	);

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				simbolo_par 	<= '0';	
				simbolo_impar 	<= '1';
			elsif ce = '1' then
				simbolo_par 	<= si_wr_par_int;	
				simbolo_impar 	<= not si_wr_par_int;
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
				start5 <= '0';
				start6 <= '0';
			elsif ce = '1' then
				start5 <= start4;
				start6 <= start5;
			end if;
		end if;
	end process;	

	salida 	<= salida_impares when simbolo_par = '1' else salida_pares;
	data_rdy	<= start6;
	
	----------------------------------------------------------------------------
	-- Reading Interface (indice_j, indice_k)
	----------------------------------------------------------------------------
	
	Inst_contadores_lectura: contadores_lectura PORT MAP(
		clk 				=> clk,
		reset_n 			=> reset_n,
		ce 					=> ce,	
		start				=>	cnt_start,		-- cnt_start = start0 + 1
		ready				=>	ready_int,		-- cnt_ready = cnt_start + 3 = start0 + 4	
		indice_k 			=> indice_k_int,
		indice_j 			=> indice_j_int,
		j_piloto 			=> pilot_int,
		j_tps				=> tps_int,
		j_cero 				=> zero_int
	);
	
	index		<= indice_j_int;		
	indx_flags	<= ready_int & pilot_int & tps_int & zero_int;
	ce_lectura  <= not(tps_int or pilot_int or zero_int);
		
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

	ce_tabla_pares 		<= inicio_lecturas and ce_lectura and ready_int and simbolo_impar;
	ce_tabla_impares 	<= inicio_lecturas and ce_lectura and ready_int and simbolo_par;

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				ce_memo_impares <= '0';
				ce_memo_pares	 <= '0';
			elsif ce = '1' then
				ce_memo_impares <= new_data or (ready_int and simbolo_par);
				ce_memo_pares	 <= new_data or (ready_int and simbolo_impar);
			end if;
		end if;
	end process;	
	
	tabla_addr_2k 	<= indice_k_int(10 downto 0) when OFDM = 2 else (others => '0');
	tabla_addr_8k 	<= indice_k_int(12 downto 0) when OFDM = 8 else (others => '0');

	--------------------------------------------------------------------
	-- Odd Symbols Memory. Deinterleaver y(elements) = u
	--------------------------------------------------------------------

	Inst_tabla_2k_impares: tabla_2k_impares PORT MAP(
		clka		=> clk,
		addra		=> tabla_addr_2k,
		douta		=> dir_impares_2k,
		ena			=> ce_tabla_impares
	);

	Inst_tabla_8k_impares: tabla_8k_impares PORT MAP(
		clka		=> clk,
		addra		=> tabla_addr_8k,
		douta		=> dir_impares_8k,
		ena			=> ce_tabla_impares
	);

	Inst_symbol_memo_impares: symbol_memo PORT MAP(
		clka		=> clk,
		ssra		=> sclr_int,
		addra		=> addr_memo_impares,
		dina		=> entrada,
		douta		=> salida_impares,
		wea			=> wea_impar,
		ena			=> ce_memo_impares	 
	);
	
	wea_impar(0) <= simbolo_impar;
	dir_impares 		<= dir_impares_2k when OFDM = 2 else dir_impares_8k;
	addr_memo_impares	<= indice_i when simbolo_impar = '1' else dir_impares;
		
	------------------------------------------------------------------------
	-- Even Symbols Memory. Standard interleaver y = u(Elements)
	------------------------------------------------------------------------

	Inst_tabla_2k_pares: tabla_2k_pares PORT MAP(
		clka		=> clk,
		addra		=> tabla_addr_2k,
		douta		=> dir_pares_2k,
		ena			=> ce_tabla_pares
	);

	Inst_tabla_8k_pares: tabla_8k_pares PORT MAP(
		clka		=> clk,
		addra		=> tabla_addr_8k,
		douta		=> dir_pares_8k,
		ena			=> ce_tabla_pares
	);
	
	Inst_symbol_memo_pares: symbol_memo PORT MAP(
		clka		=> clk,
		ssra		=> sclr_int,
		addra		=> addr_memo_pares,
		dina		=> entrada,
		douta		=> salida_pares,
		wea			=> wea_par,
		ena			=> ce_memo_pares
	);
	
	wea_par(0) <= simbolo_par;
	dir_pares 		<= dir_pares_2k when OFDM = 2 else dir_pares_8k;
	addr_memo_pares <= indice_i when simbolo_par = '1' else dir_pares;
				
end Behavioral;