-------------------------------------------------------------------------------------
-- Data Carrier Generator
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity data_carriers_gen is
	PORT(
		clk 			: IN 	std_logic;
		reset_n 		: IN 	std_logic;
		ce 				: IN 	std_logic;
		
		-- entradas al bit_interleaver
    	new_data		: IN std_logic;
		entrada 		: IN std_logic;
		
		-- salidas del qam_mapper
		qam_rdy			: OUT std_logic;
		qam_re 			: OUT std_logic_vector(15 downto 0);
		qam_im 			: OUT std_logic_vector(15 downto 0);
		
		-- contadores_lectura
		start_pulses	: OUT std_logic_vector(4  downto 0);
		index			: OUT std_logic_vector(12 downto 0);
		index_flags		: OUT std_logic_vector(3  downto 0)
		);
end data_carriers_gen;


architecture Behavioral of data_carriers_gen is

	SIGNAL start6: std_logic;
	SIGNAL start7: std_logic;
	SIGNAL start8: std_logic;

	-- bit interleaver 
	SIGNAL salida_bi	 : std_logic_vector(5 downto 0);          
	SIGNAL data_rdy_bi 	 : std_logic;

	COMPONENT bit_int
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		data_in 	: IN std_logic;
		new_data 	: IN std_logic;          
		data_out 	: OUT std_logic_vector(5 downto 0);
		data_ready 	: OUT std_logic
		);
	END COMPONENT;
	
	-- symbol interleaver 
	SIGNAL entrada_si	 : std_logic_vector(5 downto 0);   	
	SIGNAL new_data_si 	 : std_logic;
	SIGNAL salida_si	 : std_logic_vector(5 downto 0);  
	SIGNAL data_rdy_si 	 : std_logic;

	COMPONENT symbol_int
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		entrada 	: IN std_logic_vector(5 downto 0);
		new_data 	: IN std_logic;          
		data_rdy 	: OUT std_logic;
		salida 		: OUT std_logic_vector(5 downto 0);
		--
		start_pulses: OUT std_logic_vector(4  downto 0);
		index 		: OUT std_logic_vector(12 downto 0);
		indx_flags 	: OUT std_logic_vector(3 downto 0)
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
	
	COMPONENT wordrate_gen
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		fin_cuenta 	: OUT std_logic;
		oe 		: OUT std_logic
		);
	END COMPONENT;
	
begin

	-- Counter to simulate Bit Interleaver @ INNER_IL_NUM / INNER_IL_CONT * 64 MHz
	--	Inst_bit_int_CONT: wordrate_gen PORT MAP(
	--		clk 		=> clk,
	--		reset_n 	=> reset_n,
	--		ce 			=> ce,
	--		oe 			=> data_rdy_bi
	--	);

	----------------------------------------------------------------------------
	-- Bit Interleaver
	----------------------------------------------------------------------------	
	Inst_bit_int: bit_int 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		data_in 	=> entrada,
		new_data 	=> new_data,
		data_out 	=> salida_bi,
		data_ready 	=> data_rdy_bi
	);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				entrada_si 	<= (others => '0');
			elsif ce = '1' then			
				entrada_si 	<= salida_bi;	
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_si <= '0';
			elsif ce = '1' then
				new_data_si <= data_rdy_bi;
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Symbol_Interleaver = 1(ROM) + 1(RAM) = 2 cycles
	----------------------------------------------------------------------------
			--		frame_indx = start0 + 1 + 3 cycles

	Inst_symbol_int: symbol_int 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		entrada 	=> entrada_si,
		new_data 	=> new_data_si,
		data_rdy 	=> data_rdy_si,
		salida		=> salida_si,

		-- contadores_escritura
		start_pulses	=> start_pulses,

		-- contadores_lectura
		index 		=> index,
		indx_flags 	=> index_flags
	);
		
	----------------------------------------------------------------------------
	-- QAM_Mapper = 1(ROM) + 1(Mux) = 2 cycles	
	----------------------------------------------------------------------------
			--		qam_rdy = start0 + 1 + 3 + 2 + 2

	start6  <= data_rdy_si;

	Inst_mapper: mapper_64qam 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		addr 		=> salida_si,
		xn_re 		=> qam_re,
		xn_im 		=> qam_im
	);

	qam_rdy <= start8;		

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				start7 	<= '0';
				start8	<= '0';
			elsif ce = '1' then
				start7 	<= start6;
				start8	<= start7;
			end if;
		end if;
	end process;
			
end Behavioral;
