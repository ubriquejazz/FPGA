-----------------------------------------------------------------------------------------
-- TRANSPORT MULTIPLEX ADAPTATION AND RANDOMIZATION FOR ENERGY DISPERSAL:
--
-- The transmission starts at the MSB of the first sync-word byte: not(0x47) = 0xB8.
-- The PRBS initialization sequence is loaded at the start of every 8 TS-packets.
-- The first PRBS bit at the output of the PRBS generator is aplied to the MSB 
-- of the byte following to the inverted sync byte (0xB8). So the period of the
-- sequence PRBS is: PRBS_PERIOD = (8 x 188 bytes) - 1 = 1503 bytes. 
-- During the sync bytes of the subsequent 7 TS-packets, the PRBS generation continues
-- but its output is disabled leaving these bits unrandomized (their value are still 0x47).
-- The randomization process is active also when the modulator input bit-stream is non-existent.
-------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity mux_adapter is
	Port ( 
			clk			: in  STD_LOGIC;
			reset_n	 	: in  STD_LOGIC;
			ce 			: in  STD_LOGIC;
			entrada 	: in  STD_LOGIC;	
			new_data	: in  STD_LOGIC;
			salida 		: out STD_LOGIC;	
			data_rdy	: out STD_LOGIC
	);
end mux_adapter;


architecture Behavioral of mux_adapter is

	constant PRBS_INIT_SEQUENCE	: std_logic_vector(14 downto 0) 	:= B"0000_0001_0101_001";
	constant PRBS_PERIOD		: std_logic_vector(10 downto 0) 	:= "10111011111";	-- 1503+1 bytes
	constant TS_LENGTH			: std_logic_vector(10 downto 0) 	:= "10111011111";	-- 1503

	-- input/output
	signal new_data_serie		: std_logic;
	signal new_data_serie_reg	: std_logic;
	signal entrada_serie		: std_logic;
	signal entrada_serie_reg	: std_logic;
	signal data_rdy_serie		: std_logic;
	signal salida_serie			: std_logic;

	-- PRBS Generator
	signal prbs_sequence 		: std_logic_vector(15 downto 0);
	signal init					: std_logic;
	signal salida_and			: std_logic;
	signal salida_prbs			: std_logic;
	signal enable				: std_logic;

	COMPONENT registro_prbs
	PORT(
		clk 					: IN  std_logic;
		reset_n 				: IN  std_logic;
		ce					 	: IN  std_logic;
		init			 		: IN  std_logic;
		init_val				: IN  std_logic;
		entrada				 	: IN  std_logic;          
		salida 					: OUT std_logic
		);
	END COMPONENT;

	-- packet counters, byte/bit counter (in a packet)
	signal rst_count_bit_total 	: std_logic;
	signal count_bit			: std_logic_vector(10 downto 0);	-- TS_LENGHT
	signal rst_count_packets_n 	: std_logic;
	signal count_packets 	 	: std_logic_vector(2 downto 0);		-- 0:7
--	signal reset_count_byte		: std_logic;
--	signal count_byte			: std_logic_vector(10 downto 0);	-- PRBS_PERIOD

	-- prbs fsm
	type fsm_states_prbs is (sinc_inicial, prbs_funcionando, sinc_normal);
	signal wait_gen_prbs : fsm_states_prbs;
	
begin

	entrada_serie 	<= entrada;
	new_data_serie <= new_data;
	
	-------------------------------------------------------------------------
	-- To register intermediate signals 
	-------------------------------------------------------------------------

	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				entrada_serie_reg <= '0';
			elsif ce = '1' then
				entrada_serie_reg <= entrada_serie;
			end if;
		end if;
	end process;

	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				new_data_serie_reg <= '0';
				data_rdy_serie <= '0';
			elsif ce = '1' then
				new_data_serie_reg <= new_data_serie;
				data_rdy_serie  <= new_data_serie_reg;
			end if;
		end if;
	end process;

	-------------------------------------------------------------------------
	-- FSM for the PRBS Generator
	-------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen_prbs <= sinc_inicial;				
			elsif ce = '1' and new_data_serie = '1' then
				case wait_gen_prbs is
														
					when sinc_inicial 	=>		if count_bit = "00000000111" then 
													wait_gen_prbs <= prbs_funcionando;
												else
													wait_gen_prbs <= sinc_inicial;
												end if;
														
					when sinc_normal		=> 	if count_bit = "00000000111" then
													wait_gen_prbs <= prbs_funcionando;
												else
													wait_gen_prbs <= sinc_normal;
												end if;	
														
					when prbs_funcionando =>	if rst_count_bit_total = '1' then
													if count_packets = "111" then 
														wait_gen_prbs <= sinc_inicial;
													else
														wait_gen_prbs <= sinc_normal;
													end if;
												else
													wait_gen_prbs <= prbs_funcionando;
												end if;										
				end case;
			end if;
		end if;
	end process;

	-- bit counter in a packet (188 x 8 bits):
	process(clk) 
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				count_bit <= (others => '1');
			elsif ce = '1' and new_data_serie = '1' then
				if rst_count_bit_total = '1'  then
					count_bit <= (others => '0');
				else
					count_bit <= count_bit + 1;
				end if;
			end if;
		end if;
	end process;		
		
	rst_count_bit_total <= '1' when count_bit = TS_LENGTH else '0';
	
	-- packet counter
	process(clk) 
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				count_packets <= (others => '0');
			elsif ce = '1' and new_data_serie = '1' then
				if rst_count_bit_total = '1' then
					count_packets <= count_packets + 1;
				end if;
			end if;
		end if;
	end process;
		
	rst_count_packets_n <= '0' when count_packets = "111" else '1';

	--------------------------------------------------------------
	-- PRBS Generator: 1 + x^14 + x^15
	--------------------------------------------------------------

	init	<= '1' when wait_gen_prbs = sinc_inicial		else '0';
	enable	<= '1' when wait_gen_prbs = prbs_funcionando 	else '0';

	gen_registros_prbs: for i in 0 to 14 generate
		Inst_registro_prbs: registro_prbs PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce			=> new_data_serie,
			init 		=> init,
			init_val	=> PRBS_INIT_SEQUENCE(i),
			entrada 	=> prbs_sequence(i),
			salida 		=> prbs_sequence(i+1)
		);
	end generate;
	
	prbs_sequence(0) 	<= prbs_sequence(14) xor prbs_sequence(15);	
	salida_and			<= prbs_sequence(0)  and enable;

	--------------------------------------------------------------
	-- Ouput
	--------------------------------------------------------------
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				salida_serie <= '0';
			elsif ce = '1' and new_data_serie_reg = '1' then
				case wait_gen_prbs is
					when sinc_inicial 	=> salida_serie <= not entrada_serie_reg;
					when others 		=> salida_serie <= entrada_serie_reg xor salida_and;
				end case;
			end if;
		end if;
	end process;
	
	salida <= salida_serie;
	data_rdy <= data_rdy_serie;

end Behavioral;

-- synthesis translate_off

ENTITY mux_adapter_tb_vhd IS
END mux_adapter_tb_vhd;

ARCHITECTURE behavior OF mux_adapter_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT mux_adapter
	PORT(
		clk 		: in  STD_LOGIC;
		reset_n		: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;
		entrada		: in  STD_LOGIC;	
		new_data	: in  STD_LOGIC;
		salida	 	: out STD_LOGIC;	
		data_rdy 	: out STD_LOGIC
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL entrada 		:  std_logic := '0';
	SIGNAL new_data 	:  std_logic := '0';
	SIGNAL entrada_int 	:  std_logic := '0';
	SIGNAL new_data_int :  std_logic := '0';

	--Outputs
	SIGNAL salida 		:  std_logic;
	SIGNAL data_rdy 	:  std_logic;
	SIGNAL salida_int	:  std_logic;
	SIGNAL data_rdy_int	:  std_logic;

	--Testbench
	file	datos_salida	: TEXT;
	file	datos_entrada	: TEXT;
	signal file_end			: std_logic;
	signal inicio 			: std_logic;

	shared variable contador_lec : integer 	:= 0;
	shared variable contador_esc : integer 	:= 0;
	
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: mux_adapter PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		entrada 	=> entrada,
		new_data 	=> new_data,
		salida 		=> salida_int,
		data_rdy 	=> data_rdy_int
	);

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				entrada_int <= '0';
			elsif ce = '1' then
				entrada_int <= salida_int;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_int <= '0';
			elsif ce = '1' then
				new_data_int <= data_rdy_int;
			end if;
		end if;
	end process;	

	uut2: mux_adapter PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		entrada 	=> entrada_int,
		new_data	=> new_data_int,
		salida 		=> salida,
		data_rdy 	=> data_rdy
	);	

	process
	begin
		clk   <= '1';
		wait for CLOCK_PERIOD/2;
		clk   <= '0';
		wait for CLOCK_PERIOD/2;
	end process;

	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	process(clk)
		variable dato : line;
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				contador_esc := 0;
			elsif ce = '1' then
				if data_rdy = '1'then 
					write(dato, conv_integer(salida));
					writeline(datos_salida, dato);
					contador_esc := contador_esc + 1;
				end if;
			end if;
		end if;
	end process;

	-- Proceso para introducción de datos por la entrada:	
	-- Utilizamos flanco descendente para que esta introducción hecha en el testbench no penalice un ciclo.
	process(clk)
		variable cuenta_bits		: integer;
		variable dato				: line;
		variable valor				: integer;
		variable cuenta_ciclos	: integer;
		variable byte_entrada	: std_logic_vector(8 downto 0);
	begin
		if clk'event and clk = '0' then
			if reset_n = '0' then
				entrada 			<= '0';
				contador_lec	:= 0;
				cuenta_ciclos	:= 0;
				cuenta_bits 	:= 7;
			elsif ce = '1' and inicio = '1' then
				-- Mandamos un bit cada 4 ciclos de reloj:
				if cuenta_ciclos = 3 then
					if cuenta_bits = 7 then
						if (not endfile(datos_entrada)) then
							readline(datos_entrada, dato);
							read (dato, valor);	
						else
							file_close (datos_entrada);
--							file_open(datos_entrada, "01_salida_mux_adapter.dat", read_mode);
							file_open(datos_entrada, "00_entrada_8ts.dat", read_mode);
							readline(datos_entrada, dato);
							read (dato, valor);	
						end if;
						byte_entrada := conv_std_logic_vector(valor, 9);
					end if;
					entrada 	<= byte_entrada(cuenta_bits);
					new_data <= '1';
					contador_lec := contador_lec + 1;
					
					if cuenta_bits = 0 then
						cuenta_bits := 7;
					else
						cuenta_bits := cuenta_bits - 1;
					end if;
					cuenta_ciclos := 0;
				else
					new_data <= '0';
					cuenta_ciclos := cuenta_ciclos + 1;
				end if;
			end if;
		end if;
	end process;
	
	tb : PROCESS
	BEGIN

				file_open(datos_entrada, "../00_entrada_8ts.dat", read_mode);
--				file_open(datos_entrada, "../01_salida_mux_adapter.dat", read_mode);
				file_open(datos_salida, "../01_salida_mux_adapter.dat", write_mode);
--				file_open(datos_salida, "../02_salida_mux_adapter.dat", write_mode);
	
		inicio <= '0';
		reset_n <= '0';
		ce <= '0';

		-- Wait 100 ns for global reset to finish
		wait for 110 ns;
		reset_n <= '1';
		ce <= '1';

		wait for 595 ns;
		inicio <= '1';
		
--		wait until file_end = '1';
		wait for 499 us;
		file_close (datos_entrada);
		file_close (datos_salida);
		wait; -- will wait forever
	END PROCESS;

END;


ENTITY mux_adapter_byte_tb_vhd IS
END mux_adapter_byte_tb_vhd;

ARCHITECTURE behavior OF mux_adapter_byte_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT mux_adapter
	PORT(
		clk 		: in  STD_LOGIC;
		reset_n		: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;
		entrada		: in  STD_LOGIC;	
		new_data	: in  STD_LOGIC;
		salida	 	: out STD_LOGIC;
		data_rdy 	: out STD_LOGIC
	);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
--	SIGNAL new_data 	:  std_logic := '0';
--	SIGNAL entrada 		:  std_logic := '0';
	
	--Outputs
--	SIGNAL salida		:  std_logic;
--	SIGNAL data_rdy 	:  std_logic;

	--Testbench
	file	datos_salida	: TEXT;
	file	datos_entrada	: TEXT;
	signal file_end		: std_logic;
	signal inicio 			: std_logic;

	shared variable 	cuenta_ciclos	: integer	:= 0;
	shared variable 	cuenta_tandas	: integer	:= 0;
	shared variable 	valor_inicial	: integer	:= 0;
	shared variable 	contador_lec 	: integer 	:= 0;
	shared variable 	contador_esc 	: integer 	:= 0;

	COMPONENT byte_serializer
	PORT(
			clk 				: IN std_logic;
			reset_n 			: IN std_logic;
			ce 					: IN std_logic;
			entrada 			: IN std_logic_vector(7 downto 0);
			new_byte 			: IN std_logic;          
			buffer_ovf 			: OUT std_logic;
			salida 				: OUT std_logic;
			data_rdy 			: OUT std_logic
		);
	END COMPONENT;

	COMPONENT bit_parallelizer
	PORT(
			clk 				: IN std_logic;
			reset_n 			: IN std_logic;
			ce 					: IN std_logic;
			entrada 			: IN std_logic;
			new_data 			: IN std_logic;  
			salida 				: OUT std_logic_vector(7 downto 0);
			byte_rdy 			: OUT std_logic
		);
	END COMPONENT;

	--byte serializer
	signal byte2bit_in				: std_logic_vector(7 downto 0) := (others=>'0');
	signal byte2bit_nd				: std_logic := '0';
	signal byte2bit_out				: std_logic := '0';
	signal byte2bit_rdy				: std_logic := '0';
	-- bit parallelizer
	signal bit2byte_in				: std_logic := '0';
	signal bit2byte_nd				: std_logic := '0';
	signal bit2byte_out				: std_logic_vector(7 downto 0) := (others=>'0');
	signal bit2byte_rdy				: std_logic := '0';
	-- mux adapter
	signal entrada_mux_adapter 		: std_logic := '0';
	signal new_data_mux_adapter 	: std_logic := '0';
	signal salida_mux_adapter 		: std_logic := '0';
	signal data_rdy_mux_adapter 	: std_logic := '0';	
	SIGNAL new_data_outer_coder 	: std_logic := '0';
	SIGNAL entrada_outer_coder 		: std_logic_vector(7 downto 0) := (others=>'0');

BEGIN

	----------------------------------------------------------------------------
	-- Registramos las señales de interconexión para evitar problemas de timing:
	----------------------------------------------------------------------------
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				entrada_mux_adapter <= '0';
			elsif ce = '1' then
				entrada_mux_adapter <= byte2bit_out;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_mux_adapter <= '0';
			elsif ce = '1' then
				new_data_mux_adapter <= byte2bit_rdy;
			end if;
		end if;
	end process;
	
	-- 8 bit to 1 bit serializer
	Inst_byte_serializer: byte_serializer PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		entrada 	=> byte2bit_in,
		new_byte => byte2bit_nd,
--		buffer_ovf => overflow,
		salida 	=> byte2bit_out,
		data_rdy => byte2bit_rdy
	);
	
	----------------------------------------------------------------------------
	-- Instantiate the Unit Under Test (UUT)
	----------------------------------------------------------------------------
	uut: mux_adapter PORT MAP(
		clk 			=> clk,
		reset_n 		=> reset_n,
		ce 			=> ce,
		entrada 		=> entrada_mux_adapter,
		new_data 	=> new_data_mux_adapter,
		salida 		=> salida_mux_adapter,
		data_rdy 	=> data_rdy_mux_adapter
	);

--	salida_mux_adapter 	<= entrada_mux_adapter;
--	data_rdy_mux_adapter <= new_data_mux_adapter;

	----------------------------------------------------------------------------
	-- Registramos las señales de interconexión para evitar problemas de timing:
	----------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				bit2byte_in <= '0';
			elsif ce = '1' then
				bit2byte_in <= salida_mux_adapter;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				bit2byte_nd <= '0';
			elsif ce = '1' then
				bit2byte_nd <= data_rdy_mux_adapter;
			end if;
		end if;
	end process;

	-- 8 bits to 1 byte parallelizer
	Inst_bit_parallelizer: bit_parallelizer PORT MAP(
		clk 			=> clk,
		reset_n 		=> reset_n,
		ce 			=> ce,
		entrada 		=> bit2byte_in,
		new_data 	=> bit2byte_nd,
		salida 		=> entrada_outer_coder,
		byte_rdy 	=> new_data_outer_coder
	);
		
	---------------------------------------------------------------------------------------------
	-- Test Bench
	---------------------------------------------------------------------------------------------

	process
	begin
		clk   <= '1';
		wait for CLOCK_PERIOD/2;
		clk   <= '0';
		wait for CLOCK_PERIOD/2;
	end process;

	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	process(clk)
		variable dato : line;
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				contador_esc := 0;
			elsif ce = '1' then
				if new_data_outer_coder = '1'then 
					write(dato, conv_integer(entrada_outer_coder));
					writeline(datos_salida, dato);
					contador_esc := contador_esc + 1;
				end if;
			end if;
		end if;
	end process;
	
	-- Proceso para introducción de datos por la entrada a 27.99 Mbps
	-- Utilizamos flanco descendente para que esta introducción hecha en el testbench no penalice un ciclo.
	process(clk)
		variable dato				: line;
		variable valor				: integer;
		variable byte_entrada	: std_logic_vector(8 downto 0);
	begin
		if clk'event and clk = '0' then
			if reset_n = '0' then
				cuenta_ciclos := 0;
				cuenta_tandas := 0;
				contador_esc  := 0;

				byte2bit_in	<= (others => '0');
				byte2bit_nd <= '0';
			elsif ce = '1' and inicio = '1' then

				if cuenta_ciclos = 1 then
					if (not endfile(datos_entrada)) then
						readline(datos_entrada, dato);
						read (dato, valor);	
					else
						file_close (datos_entrada);
--						file_open(datos_entrada, "../01_salida_mux_adapter.dat", read_mode);
						file_open(datos_entrada, "../00_entrada_8ts.dat", read_mode);
						readline(datos_entrada, dato);
						read (dato, valor);	
					end if;
				-- byte_entrada := conv_std_logic_vector(valor, 9);
				-- entrada <= byte_entrada(7 downto 0);
					byte2bit_in  <= conv_std_logic_vector(valor, 8);					
					byte2bit_nd <= '1';
					contador_esc := contador_esc + 1;
				else
					byte2bit_nd <= '0';
				end if;

				if cuenta_ciclos = 0 then
					if cuenta_tandas = 6	then				
						cuenta_tandas := 0;
						valor_inicial := 20 - 1;
					else
						cuenta_tandas := cuenta_tandas + 1;
						valor_inicial := 18 - 1;
					end if;
					--
					cuenta_ciclos := valor_inicial;
				else
					cuenta_ciclos := cuenta_ciclos - 1;
				end if;

			end if;
		end if;
	end process;	
		
	tb : PROCESS
	BEGIN

				file_open(datos_entrada, "../00_entrada_8ts.dat", read_mode);
--				file_open(datos_entrada, "../01_salida_mux_adapter.dat", read_mode);
				file_open(datos_salida, "../01_salida_mux_adapter.dat", write_mode);
--				file_open(datos_salida, "../02_salida_mux_adapter.dat", write_mode);
	
		inicio <= '0';
		reset_n <= '0';
		ce <= '0';

		-- Wait 100 ns for global reset to finish
		wait for 110 ns;
		reset_n <= '1';
		ce <= '1';

		wait for 595 ns;
		inicio <= '1';
		
--		wait until file_end = '1';
		wait for 499 us;
		file_close (datos_entrada);
		file_close (datos_salida);

		wait; -- will wait forever
	END PROCESS;

END;
-- synthesis translate_on
