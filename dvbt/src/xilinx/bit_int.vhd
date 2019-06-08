-------------------------------------------------------------------------------------
-- BIT INTERLEAVER
--
-- Each interleaver is implemented through an 126 registers array 
-- except the interleaver e=0 which is 105 register long. 
--
-- The input-output bit relation for each interleaver is as follows:
--    ae,w = be,He(w)                   e = 0 : 5     w, He(w) = 0 : 125
-- The value of w is implemented by a ciclic module 126 counter
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity bit_int is
	PORT( 
		clk	 			: in  STD_LOGIC;
		reset_n 		: in  STD_LOGIC;
		ce 				: in  STD_LOGIC;		
		-- high priority
		data_in 		: in  STD_LOGIC;
		new_data 		: in  STD_LOGIC;
		-- low priority
	-- data_in_lp 		: in  STD_LOGIC;
	-- new_data_lp 		: in  STD_LOGIC;
		
		-- output
		data_out 		: out STD_LOGIC_VECTOR (5 downto 0);
		data_ready 		: out STD_LOGIC
	);	
end bit_int;

architecture Behavioral of bit_int is

	constant MODULO 	: integer := 126;
	constant Nmax 		: integer := 105;
	constant Nrama1 	: integer := 63;
	constant Nrama2 	: integer := 105;
	constant Nrama3 	: integer := 42;
	constant Nrama4 	: integer := 21;
	constant Nrama5 	: integer := 84;
	
	COMPONENT reg_simple
	PORT(
		clk 		: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		entrada 	: IN  std_logic; 
		salida 		: OUT std_logic
		);
	END COMPONENT;
	
	type fsm_mux is (rama0, rama1, rama2, rama3, rama4, rama5);
	signal wait_gen_mux : fsm_mux;
	
	signal inicio 				: std_logic;
	signal new_data_reg 		: std_logic;
	signal data_in_reg 			: std_logic;
	signal salida_demux			: std_logic_vector(5 downto 0);
	signal salida_demux_rdy 	: std_logic;	
	signal cont_mod_126			: std_logic_vector(7 downto 0);
	signal reset_cont_mod_126	: std_logic;
	signal rama0a				: std_logic_vector(Nmax+1 downto 0);
	signal rama1a				: std_logic_vector(Nmax-Nrama1+1 downto 0);
	signal rama1b				: std_logic_vector(MODULO+Nmax-Nrama1+1 downto 0);
	signal rama2b				: std_logic_vector(MODULO+Nmax-Nrama2+1 downto 0);
	signal rama3a				: std_logic_vector(Nmax-Nrama3+1 downto 0);
	signal rama3b				: std_logic_vector(MODULO+Nmax-Nrama3+1 downto 0);
	signal rama4a				: std_logic_vector(Nmax-Nrama4+1 downto 0);
	signal rama4b				: std_logic_vector(MODULO+Nmax-Nrama4+1 downto 0);
	signal rama5a				: std_logic_vector(Nmax-Nrama5+1 downto 0);
	signal rama5b				: std_logic_vector(MODULO+Nmax-Nrama5+1 downto 0);
	signal salida_bit_int		: std_logic_vector(5 downto 0);
	signal salida_bit_int_rdy 	: std_logic;
	signal fin_de_simbolo		: std_logic;
	signal cont_inicio			: std_logic_vector(7 downto 0);
	signal inicio_bit_int		: std_logic;
	signal ce_signal_rdy_QPSK 	: std_logic;
	signal ce_signal_rdy_16QAM	: std_logic;
	signal ce_signal_rdy_64QAM	: std_logic;
	signal ce_signal_rdy 		: std_logic;

begin
	---------------------------------------------------------------------------------
	-- To register input signals and to generate an internal start signal
	---------------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_reg <= '0';
			elsif ce = '1' then
				new_data_reg <= new_data;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				data_in_reg <= '0';
			elsif ce = '1' then
				data_in_reg <= data_in;
			end if;
		end if;
	end process;
	
	---------------------------------------------------------------------------------
	-- Input demultiplexor (Finite State Machine).
	---------------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen_mux <= rama0;
			elsif ce = '1' and new_data_reg = '1' then
				case wait_gen_mux is
				
					when rama0	=>	wait_gen_mux <= rama2;

					when rama1	=>	wait_gen_mux <= rama3;

					when rama2	=>	wait_gen_mux <= rama4;
					
					when rama3	=>	wait_gen_mux <= rama5;
					
					when rama4	=>	wait_gen_mux <= rama1;
					
					when rama5	=>	wait_gen_mux <= rama0;
					
					when others => wait_gen_mux <= rama0;
					
				end case;
			end if;
		end if;
	end process;
	
	---------------------------------------------------------------------------------
	-- FSM Outpus
	---------------------------------------------------------------------------------
	
	ce_signal_rdy <= '1' when wait_gen_mux = rama5 else '0';	
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				salida_demux_rdy <= '0';
			elsif ce = '1' and ce_signal_rdy = '1' and new_data_reg = '1' then
				salida_demux_rdy <= '1';
			else
				salida_demux_rdy <= '0';
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				salida_demux <= (others => '0');
			elsif ce = '1' and new_data_reg = '1' then
				case wait_gen_mux is
					when rama0	=>	salida_demux(0) <= data_in_reg;
					when rama1	=>	salida_demux(1) <= data_in_reg;
					when rama2	=>	salida_demux(2) <= data_in_reg;
					when rama3	=>	salida_demux(3) <= data_in_reg;
					when rama4	=>	salida_demux(4) <= data_in_reg;
					when rama5	=>	salida_demux(5) <= data_in_reg;
				end case;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------------------
	-- A bit-interleaver per branch.
	---------------------------------------------------------------------------------
	
	-- Inputs:
	rama0a(0) <= salida_demux(0);
	rama1a(0) <= salida_demux(1);
	rama1b(0) <= salida_demux(1);
	rama2b(0) <= salida_demux(2);
	rama3a(0) <= salida_demux(3);
	rama3b(0) <= salida_demux(3);
	rama4a(0) <= salida_demux(4);
	rama4b(0) <= salida_demux(4);
	rama5a(0) <= salida_demux(5);
	rama5b(0) <= salida_demux(5);
	
	-- Branch 0:
	gen_rama0: for i in 0 to Nmax generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama0a(i),
			salida 		=> rama0a(i+1)
		);
	end generate;
	
	-- Branch 1:	
	gen_rama1A: for i in 0 to Nmax-Nrama1 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama1a(i),
			salida 		=> rama1a(i+1)
		);
	end generate;
	
	gen_rama1B: for i in 0 to MODULO+Nmax-Nrama1 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama1b(i),
			salida 		=> rama1b(i+1)
		);
	end generate;
	
	-- Branch 2. The A branch is direct, only the B one is coded:
	gen_rama2B: for i in 0 to MODULO+Nmax-Nrama2 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama2b(i),
			salida 		=> rama2b(i+1)
		);
	end generate;
	
	-- Branch 3:
	gen_rama3A: for i in 0 to Nmax-Nrama3 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama3a(i),
			salida 		=> rama3a(i+1)
		);
	end generate;
	
	gen_rama3B: for i in 0 to MODULO+Nmax-Nrama3 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama3b(i),
			salida 		=> rama3b(i+1)
		);
	end generate;
	
	-- Branch 4:	
	gen_rama4A: for i in 0 to Nmax-Nrama4 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama4a(i),
			salida 		=> rama4a(i+1)
		);
	end generate;
	
	gen_rama4B: for i in 0 to MODULO+Nmax-Nrama4 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama4b(i),
			salida 		=> rama4b(i+1)
		);
	end generate;
	
	-- Branch 5:	
	gen_rama5A: for i in 0 to Nmax-Nrama5 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama5a(i),
			salida 		=> rama5a(i+1)
		);
	end generate;
	
	gen_rama5B: for i in 0 to MODULO+Nmax-Nrama5 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> salida_demux_rdy,
			entrada 	=> rama5b(i),
			salida 		=> rama5b(i+1)
		);
	end generate;

	---------------------------------------------------------------------------------
	-- Counters
	---------------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				inicio_bit_int <= '0';
			elsif salida_demux_rdy = '1' and cont_inicio = conv_std_logic_vector(Nmax-1, 8) then
				inicio_bit_int	<= '1';
			end if;
		end if;
	end process;
	
	-- Latency of the bit interleaver:
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				cont_inicio <= (others => '0');
			elsif salida_demux_rdy = '1' and inicio_bit_int = '0' then
				cont_inicio	<= cont_inicio + 1;
			end if;
		end if;
	end process;

	-- Module 126 Counter --> w
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or reset_cont_mod_126 = '1' then
				cont_mod_126 	<= (others => '0');
			elsif salida_bit_int_rdy = '1' then
				cont_mod_126	<= cont_mod_126 + 1;
			end if;
		end if;
	end process;
	
	reset_cont_mod_126 <= '1' when cont_mod_126 = conv_std_logic_vector(MODULO, 8) else '0';
	
	---------------------------------------------------------------------------------
	-- Bit interleaver outputs
	---------------------------------------------------------------------------------

	salida_bit_int(0) <= rama0a(Nmax+1);
	salida_bit_int(1) <= rama1a(Nmax-Nrama1+1) 	when cont_mod_126 < MODULO-Nrama1 else rama1b(MODULO+Nmax-Nrama1+1);
	salida_bit_int(2) <= salida_demux(2) 		when cont_mod_126 < MODULO-Nrama2 else rama2b(MODULO+Nmax-Nrama2+1);
	salida_bit_int(3) <= rama3a(Nmax-Nrama3+1) 	when cont_mod_126 < MODULO-Nrama3 else rama3b(MODULO+Nmax-Nrama3+1);
	salida_bit_int(4) <= rama4a(Nmax-Nrama4+1) 	when cont_mod_126 < MODULO-Nrama4 else rama4b(MODULO+Nmax-Nrama4+1);
	salida_bit_int(5) <= rama5a(Nmax-Nrama5+1) 	when cont_mod_126 < MODULO-Nrama5 else rama5b(MODULO+Nmax-Nrama5+1);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				salida_bit_int_rdy <= '0';
			elsif salida_demux_rdy = '1' and inicio_bit_int	= '1' then
				salida_bit_int_rdy <= '1';
			else
				salida_bit_int_rdy <= '0';
			end if;
		end if;
	end process;
	
	data_out <= salida_bit_int;
	data_ready <= salida_bit_int_rdy;	
	
end Behavioral;

-- synthesis translate off

ENTITY bit_int_tb_vhd IS
END bit_int_tb_vhd;

ARCHITECTURE behavior OF bit_int_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT bit_int
	PORT(
		clk 			: IN std_logic;
		reset_n 		: IN std_logic;
		ce 				: IN std_logic;
		data_in 		: IN std_logic;
		new_data 		: IN std_logic;          
		data_out 		: OUT std_logic_vector(5 downto 0);
		data_ready 		: OUT std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL data_in 		:  std_logic := '0';
	SIGNAL new_data 	:  std_logic := '0';

	--Outputs
	SIGNAL data_out 	:  std_logic_vector(5 downto 0);
	SIGNAL data_ready 	:  std_logic;

	--Testbench
	shared variable 	cuenta_ciclos	: integer	:= 0;
	shared variable 	contador		: integer 	:= 0;
	shared variable 	byte 			: std_logic_vector(8 downto 0);
	
	file	datos_salida	: TEXT;
	file	datos_entrada	: TEXT;
	signal 	inicio 			: std_logic;
	
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: bit_int PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		data_in 	=> data_in,
		new_data 	=> new_data,
		data_out 	=> data_out,
		data_ready 	=> data_ready
	);

	process
	begin
		clk   <= '1';
		wait for CLOCK_PERIOD/2;
		clk   <= '0';
		wait for CLOCK_PERIOD/2;
	end process;	

	-- Proceso para introducción de datos por la entrada:	
	-- Utilizamos flanco descendente para que esta introducción hecha en el testbench no penalice un ciclo.
	process(clk)
		variable cuenta_bits		: integer;
		variable dato				: line;
		variable valor				: integer;
		variable byte_entrada	: std_logic_vector(8 downto 0);
	begin
		if clk'event and clk = '0' then
			if reset_n = '0' then
				data_in <= '0';
				cuenta_bits := 0;
			elsif ce = '1' and inicio = '1' then
			
				-- Para entrada de bits a ráfagas:
				if cuenta_bits = 0 then
					if (not endfile(datos_entrada)) then
						readline(datos_entrada, dato);
						read (dato, valor);	
					else
						file_close (datos_entrada);
						file_open(datos_entrada, "..\04_salida_inner_coder.dat", read_mode);
						readline(datos_entrada, dato);
						read (dato, valor);	
					end if;
					if valor = 1 then
						data_in <= '1';
					else
						data_in <= '0';
					end if;
					new_data <= '1';
				else
					new_data <= '0';
				end if;
				
				cuenta_bits := cuenta_bits + 1;
				if cuenta_bits = 3 then
					cuenta_bits := 0;
				end if;
				
			end if;
		end if;
	end process;
	
	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	process(clk)
		variable cuenta_bits	: integer;
		variable dato			: line;
		variable byte 			: std_logic_vector(8 downto 0);
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				cuenta_bits 	:= 7;
				byte := (others => '0');
			elsif ce = '1' then
				if data_ready = '1' then
					write(dato, conv_integer(data_out));
					writeline(datos_salida, dato);
				end if;
			end if;
		end if;
	end process;	

	tb : PROCESS
	BEGIN

		file_open(datos_entrada, "..\04_salida_inner_coder.dat", read_mode);
		file_open(datos_salida, "..\05_salida_bit_int.dat", write_mode);
		reset_n <= '0';
		ce <= '0';
		inicio <= '0';
		wait for 105 ns;
		reset_n <= '1';
		ce <= '1';
		wait for 700 ns;
		inicio <= '1';

		wait for 20 ns;

		wait for 2999 us;
		file_close (datos_salida);
		file_close (datos_entrada);
		wait; -- will wait forever

	END PROCESS;

END;

-- synthesis translate on