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
		sink_wrd		: in  STD_LOGIC_VECTOR(5 downto 0);
		sink_val 		: in  STD_LOGIC;		
		source_wrd 		: out STD_LOGIC_VECTOR(5 downto 0);
		source_val 		: out STD_LOGIC
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
	
	signal bit_int_source_wrd	: std_logic_vector(5 downto 0);
	signal bit_int_source_val 	: std_logic;	
	signal startup_cntr			: std_logic_vector(7 downto 0);
	signal bit_int_start		: std_logic;
	signal mod_126_cntr			: std_logic_vector(7 downto 0);
	signal mod_126_cntr_rst	: std_logic;

begin

	---------------------------------------------------------------------------------
	-- A bit-interleaver per branch.
	---------------------------------------------------------------------------------
	
	-- Inputs:
	rama0a(0) <= sink_wrd(0);
	rama1a(0) <= sink_wrd(1);
	rama1b(0) <= sink_wrd(1);
	rama2b(0) <= sink_wrd(2);
	rama3a(0) <= sink_wrd(3);
	rama3b(0) <= sink_wrd(3);
	rama4a(0) <= sink_wrd(4);
	rama4b(0) <= sink_wrd(4);
	rama5a(0) <= sink_wrd(5);
	rama5b(0) <= sink_wrd(5);
	
	-- Branch 0:
	gen_rama0: for i in 0 to Nmax generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama0a(i),
			salida 		=> rama0a(i+1)
		);
	end generate;
	
	-- Branch 1:	
	gen_rama1A: for i in 0 to Nmax-Nrama1 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama1a(i),
			salida 		=> rama1a(i+1)
		);
	end generate;
	
	gen_rama1B: for i in 0 to MODULO+Nmax-Nrama1 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama1b(i),
			salida 		=> rama1b(i+1)
		);
	end generate;
	
	-- Branch 2. The A branch is direct, only the B one is coded:
	gen_rama2B: for i in 0 to MODULO+Nmax-Nrama2 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama2b(i),
			salida 		=> rama2b(i+1)
		);
	end generate;
	
	-- Branch 3:
	gen_rama3A: for i in 0 to Nmax-Nrama3 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama3a(i),
			salida 		=> rama3a(i+1)
		);
	end generate;
	
	gen_rama3B: for i in 0 to MODULO+Nmax-Nrama3 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama3b(i),
			salida 		=> rama3b(i+1)
		);
	end generate;
	
	-- Branch 4:	
	gen_rama4A: for i in 0 to Nmax-Nrama4 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama4a(i),
			salida 		=> rama4a(i+1)
		);
	end generate;
	
	gen_rama4B: for i in 0 to MODULO+Nmax-Nrama4 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama4b(i),
			salida 		=> rama4b(i+1)
		);
	end generate;
	
	-- Branch 5:	
	gen_rama5A: for i in 0 to Nmax-Nrama5 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
			entrada 	=> rama5a(i),
			salida 		=> rama5a(i+1)
		);
	end generate;
	
	gen_rama5B: for i in 0 to MODULO+Nmax-Nrama5 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> sink_val,
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
				bit_int_start <= '0';
			elsif sink_val = '1' and startup_cntr = conv_std_logic_vector(Nmax-1, 8) then
				bit_int_start	<= '1';
			end if;
		end if;
	end process;
	
	-- Latency of the bit interleaver:
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				startup_cntr <= (others => '0');
			elsif sink_val = '1' and bit_int_start = '0' then
				startup_cntr <= startup_cntr + 1;
			end if;
		end if;
	end process;

	-- Module 126 Counter --> w
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or mod_126_cntr_rst = '1' then
				mod_126_cntr 	<= (others => '0');
			elsif bit_int_source_val = '1' then
				mod_126_cntr	<= mod_126_cntr + 1;
			end if;
		end if;
	end process;
	
	mod_126_cntr_rst <= '1' when mod_126_cntr = conv_std_logic_vector(MODULO, 8) else '0';
	
	---------------------------------------------------------------------------------
	-- Bit interleaver outputs
	---------------------------------------------------------------------------------

	bit_int_source_wrd(0) <= rama0a(Nmax+1);
	bit_int_source_wrd(1) <= rama1a(Nmax-Nrama1+1) 	when mod_126_cntr < MODULO-Nrama1 else rama1b(MODULO+Nmax-Nrama1+1);
	bit_int_source_wrd(2) <= sink_wrd(2) 		when mod_126_cntr < MODULO-Nrama2 else rama2b(MODULO+Nmax-Nrama2+1);
	bit_int_source_wrd(3) <= rama3a(Nmax-Nrama3+1) 	when mod_126_cntr < MODULO-Nrama3 else rama3b(MODULO+Nmax-Nrama3+1);
	bit_int_source_wrd(4) <= rama4a(Nmax-Nrama4+1) 	when mod_126_cntr < MODULO-Nrama4 else rama4b(MODULO+Nmax-Nrama4+1);
	bit_int_source_wrd(5) <= rama5a(Nmax-Nrama5+1) 	when mod_126_cntr < MODULO-Nrama5 else rama5b(MODULO+Nmax-Nrama5+1);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				bit_int_source_val <= '0';
			elsif sink_val = '1' and bit_int_start	= '1' then
				bit_int_source_val <= '1';
			else
				bit_int_source_val <= '0';
			end if;
		end if;
	end process;
	
	source_wrd <= bit_int_source_wrd;
	source_val <= bit_int_source_val;	
	
end Behavioral;

-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;

library WORK;
use WORK.mypackage.all;

ENTITY bit_int_tb_vhd IS
END bit_int_tb_vhd;

ARCHITECTURE behavior OF bit_int_tb_vhd IS 

	COMPONENT resampler 
	PORT( 
		clk	 		: in  STD_LOGIC;
		reset_n 	: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;		
		sink_bit 	: in  STD_LOGIC;
		sink_val 	: in  STD_LOGIC;
		source_rdy  : in  STD_LOGIC;
		source_wrd	: out STD_LOGIC_VECTOR (5 downto 0);
		source_val 	: out STD_LOGIC
	);
	END COMPONENT;
	
	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT bit_int
	PORT(
		clk 			: IN std_logic;
		reset_n 		: IN std_logic;
		ce 				: IN std_logic;
		sink_wrd		: IN std_logic_vector(5 downto 0);
		sink_val 		: IN std_logic;          
		source_wrd 		: OUT std_logic_vector(5 downto 0);
		source_val 		: OUT std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL data_in 		:  std_logic := '0';
	SIGNAL new_data 	:  std_logic := '0';	
	--Outputs
	SIGNAL source_wrd 	:  std_logic_vector(5 downto 0);
	SIGNAL source_val 	:  std_logic;
	--Testbench
	SIGNAL tmp_sink_wrd :  std_logic_vector(5 downto 0);
	SIGNAL tmp_sink_val :  std_logic;	

	signal sink_rdy 	: std_logic;
	file datos_salida	: TEXT;
	file datos_entrada	: TEXT;
	
BEGIN

	Inst_resampler: resampler
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_bit	=> data_in,
		sink_val	=> new_data,
		source_rdy	=> '1',
		source_wrd	=> tmp_sink_wrd,
		source_val	=> tmp_sink_val
	);
		
	-- Instantiate the Unit Under Test (UUT)
	uut: bit_int PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_val	=> tmp_sink_val,
		sink_wrd 	=> tmp_sink_wrd,
		source_wrd  => source_wrd,
		source_val 	=> source_val
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
		variable dato : line;
		variable valor : integer;
		variable bit_cntr : integer;
	begin
		if clk'event and clk = '0' then	-- clk = '1'
			if reset_n = '0' then
				data_in <= '0';
				new_data <= '0';				
				bit_cntr := 0;
			elsif ce = '1' and sink_rdy = '1' then
			
				-- Para entrada de bits a ráfagas:
				if bit_cntr = 0 then
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
				
				bit_cntr := bit_cntr + 1;
				if bit_cntr = 3 then
					bit_cntr := 0;
				end if;
				
			end if;
		end if;
	end process;
	
	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	wrFile: process(clk)
		variable wr_cntr : integer;
		variable dato : line;
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wr_cntr := 0;
			elsif ce = '1' then
				if source_val = '1' then
					write(dato, conv_integer(source_wrd));
					writeline(datos_salida, dato);
					wr_cntr := wr_cntr + 1;
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
		sink_rdy <= '0';
		wait for 105 ns;
		reset_n <= '1';
		ce <= '1';
		wait for 700 ns;
		sink_rdy <= '1';
		wait for 2999 us;
		file_close (datos_salida);
		file_close (datos_entrada);
		wait; -- will wait forever

	END PROCESS;

END;

-- synthesis translate_on