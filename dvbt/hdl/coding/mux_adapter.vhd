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
			sink_bit 	: in  STD_LOGIC;	
			sink_val	: in  STD_LOGIC;
--			sink_rdy	: out STD_LOGIC;
			source_bit	: out STD_LOGIC;	
			source_val	: out STD_LOGIC;
			source_sop	: out STD_LOGIC;
			source_eop	: out STD_LOGIC
	);
end mux_adapter;


architecture Behavioral of mux_adapter is

	constant PRBS_INIT_SEQUENCE	: std_logic_vector(14 downto 0) 	:= B"0000_0001_0101_001";
	constant PRBS_PERIOD		: std_logic_vector(10 downto 0) 	:= "10111011111";	-- 1503+1 bytes
	constant TS_LENGTH			: std_logic_vector(10 downto 0) 	:= "10111011111";	-- 1503

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

	signal sink_val_reg			: std_logic;
	signal sink_bit_reg			: std_logic;
	
	-- PRBS Generator
	signal prbs_sequence 		: std_logic_vector(15 downto 0);
	signal init					: std_logic;
	signal enable				: std_logic;
	signal prbs_out				: std_logic;
	
	-- packet counters, byte/bit counter (in a packet)
	signal rst_bit_cntr 		: std_logic;
	signal bit_cntr				: std_logic_vector(10 downto 0);	-- TS_LENGHT
	signal rst_packet_cntr_n 	: std_logic;
	signal packet_cntr 	 		: std_logic_vector(2 downto 0);		-- 0:7
--	signal reset_byte_cntr		: std_logic;
--	signal byte_cntr			: std_logic_vector(10 downto 0);	-- PRBS_PERIOD

	-- prbs fsm
	type fsm_states_prbs is (sinc_inicial, prbs_funcionando, sinc_normal);
	signal wait_gen_prbs : fsm_states_prbs;
	
begin
	
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				sink_bit_reg <= '0';
			elsif ce = '1' then
				sink_bit_reg <= sink_bit;
			end if;
		end if;
	end process;

	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				sink_val_reg <= '0';
				source_val	 <= '0';
			elsif ce = '1' then
				sink_val_reg <= sink_val;
				source_val   <= sink_val_reg;
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
			elsif ce = '1' and sink_val = '1' then
				case wait_gen_prbs is
														
					when sinc_inicial 	=>		if bit_cntr = "00000000111" then 
													wait_gen_prbs <= prbs_funcionando;
												else
													wait_gen_prbs <= sinc_inicial;
												end if;
														
					when sinc_normal		=> 	if bit_cntr = "00000000111" then
													wait_gen_prbs <= prbs_funcionando;
												else
													wait_gen_prbs <= sinc_normal;
												end if;	
														
					when prbs_funcionando =>	if rst_bit_cntr = '1' then
													if packet_cntr = "111" then 
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
				bit_cntr <= (others => '1');
			elsif ce = '1' and sink_val = '1' then
				if rst_bit_cntr = '1'  then
					bit_cntr <= (others => '0');
				else
					bit_cntr <= bit_cntr + 1;
				end if;
			end if;
		end if;
	end process;		
		
	rst_bit_cntr <= '1' when bit_cntr = TS_LENGTH else '0';
	
	-- packet counter
	process(clk) 
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				packet_cntr <= (others => '0');
			elsif ce = '1' and sink_val = '1' then
				if rst_bit_cntr = '1' then
					packet_cntr <= packet_cntr + 1;
				end if;
			end if;
		end if;
	end process;
		
	rst_packet_cntr_n <= '0' when packet_cntr = "111" else '1';

	--------------------------------------------------------------
	-- PRBS Generator: 1 + x^14 + x^15
	--------------------------------------------------------------

	init	<= '1' when wait_gen_prbs = sinc_inicial		else '0';
	enable	<= '1' when wait_gen_prbs = prbs_funcionando 	else '0';

	gen_registros_prbs: for i in 0 to 14 generate
		Inst_registro_prbs: registro_prbs PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce			=> sink_val,
			init 		=> init,
			init_val	=> PRBS_INIT_SEQUENCE(i),
			entrada 	=> prbs_sequence(i),
			salida 		=> prbs_sequence(i+1)
		);
	end generate;
	
	prbs_sequence(0) 	<= prbs_sequence(14) xor prbs_sequence(15);	
	prbs_out			<= prbs_sequence(0)  and enable;

	--------------------------------------------------------------
	-- Ouput
	--------------------------------------------------------------
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				source_bit <= '0';
			elsif ce = '1' and sink_val_reg = '1' then
				case wait_gen_prbs is
					when sinc_inicial 	=> source_bit <= not sink_bit_reg;
					when others 		=> source_bit <= sink_bit_reg xor prbs_out;
				end case;
			end if;
		end if;
	end process;
	
	source_eop <= '1' when bit_cntr = TS_LENGTH else '0';
	source_sop <= '1' when bit_cntr = 0 else '0';

end Behavioral;


-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;

library WORK;
use WORK.mypackage.all;

ENTITY mux_adapter_tb_vhd IS
END mux_adapter_tb_vhd;

ARCHITECTURE behavior OF mux_adapter_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT mux_adapter
	PORT(
		clk 		: in  STD_LOGIC;
		reset_n		: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;
		sink_bit	: in  STD_LOGIC;	
		sink_val	: in  STD_LOGIC;
--		sink_rdy 	: out STD_LOGIC;	
		source_bit 	: out STD_LOGIC;	
		source_val	: out STD_LOGIC;
		source_sop	: out STD_LOGIC;
		source_eop	: out STD_LOGIC
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 				:  std_logic := '0';
	SIGNAL reset_n 			:  std_logic := '0';
	SIGNAL ce 				:  std_logic := '0';	
	SIGNAL sink_bit			:  std_logic := '0';
	SIGNAL sink_val 		:  std_logic := '0';
	
	--Outputs	
	signal sink_rdy			:  std_logic;
	SIGNAL source_bit		:  std_logic;
	SIGNAL source_val 		:  std_logic;
	SIGNAL source_sop 		:  std_logic;
	SIGNAL source_eop 		:  std_logic;
	
	-- mux adapter
	signal mux1_source_bit	: std_logic;
	signal mux1_source_val 	: std_logic;	
	signal mux1_source_sop	: std_logic;
	signal mux1_source_eop	: std_logic;
	signal mux2_sink_bit	: std_logic;
	signal mux2_sink_val	: std_logic;
	
	--Testbench

	file IN_FILE		 : TEXT;
	
BEGIN

	uut1: mux_adapter PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_bit 	=> sink_bit,
		sink_val 	=> sink_val,
		source_bit	=> mux1_source_bit,
		source_val 	=> mux1_source_val,
		source_sop 	=> mux1_source_sop,
		source_eop	=> mux1_source_eop
	);
	
	mux2_sink_bit <= mux1_source_bit;
	mux2_sink_val <= mux1_source_val;


	uut2: mux_adapter PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_bit 	=> mux2_sink_bit,
		sink_val	=> mux2_sink_val,
		source_bit	=> source_bit,
		source_val 	=> source_val,
		source_sop 	=> source_sop,
		source_eop	=> source_eop
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
		variable cuenta_bits	: integer;
		variable dato			: line;
		variable valor			: integer;
		variable cuenta_ciclos	: integer;
		variable byte_entrada	: std_logic_vector(8 downto 0);
	begin
		if clk'event and clk = '0' then
			if reset_n = '0' then
				sink_bit <= '0';
				sink_val <= '0';
				cuenta_ciclos	:= 0;
				cuenta_bits 	:= 7;
			elsif ce = '1' and sink_rdy = '1' then
				-- Mandamos un bit cada 4 ciclos de reloj:
				if cuenta_ciclos = 3 then
					if cuenta_bits = 7 then
						if (not endfile(IN_FILE)) then
							readline(IN_FILE, dato);
							read (dato, valor);	
						else
							file_close (IN_FILE);
							file_open(IN_FILE, "00_entrada_8ts.dat", read_mode);
							readline(IN_FILE, dato);
							read (dato, valor);	
						end if;
						byte_entrada := conv_std_logic_vector(valor, 9);
					end if;
					sink_bit <= byte_entrada(cuenta_bits);
					sink_val <= '1';
					
					if cuenta_bits = 0 then
						cuenta_bits := 7;
					else
						cuenta_bits := cuenta_bits - 1;
					end if;
					cuenta_ciclos := 0;
				else
					sink_val <= '0';
					cuenta_ciclos := cuenta_ciclos + 1;
				end if;
			end if;
		end if;
	end process;
	
	tb : PROCESS
	BEGIN
		file_open(IN_FILE, "../00_entrada_8ts.dat", read_mode);
		sink_rdy <= '0';
		reset_n <= '0';
		ce <= '0';
		-- Wait 100 ns for global reset to finish
		wait for 110 ns;
		reset_n <= '1';
		ce <= '1';
		wait for 595 ns;
		sink_rdy <= '1';		
--		wait until file_end = '1';
		wait for 499 us;
		file_close (IN_FILE);
		wait; -- will wait forever
	END PROCESS;

END;
-- synthesis translate_on

-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;

library WORK;
use WORK.mypackage.all;

ENTITY mux_adapter_byte_tb_vhd IS
END mux_adapter_byte_tb_vhd;

ARCHITECTURE behavior OF mux_adapter_byte_tb_vhd IS 

	COMPONENT byte_serializer
	PORT(	clk 		: IN std_logic;
			reset_n 	: IN std_logic;
			ce 			: IN std_logic;
			sink_byte 	: IN std_logic_vector(7 downto 0);          
			sink_val 	: IN std_logic;
			sink_rdy 	: OUT std_logic;
			source_bit	: OUT std_logic;
			source_sop	: OUT std_logic;
			source_eop	: OUT std_logic;			
			source_val 	: OUT std_logic
		);
	END COMPONENT;

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT mux_adapter
	PORT(
		clk 			: in  STD_LOGIC;
		reset_n			: in  STD_LOGIC;
		ce 				: in  STD_LOGIC;
		sink_bit		: in  STD_LOGIC;	
		sink_val		: in  STD_LOGIC;
		source_bit 		: out STD_LOGIC;
		source_val		: out STD_LOGIC;
		source_sop		: out STD_LOGIC;
		source_eop		: out STD_LOGIC
		);
	END COMPONENT;	

	COMPONENT bit_parallelizer
	PORT(	clk 		: in  STD_LOGIC;	
			reset_n 	: in  STD_LOGIC;
			ce 			: in  STD_LOGIC;
			sink_bit 	: in  STD_LOGIC;
			sink_val	: in  STD_LOGIC;
			source_byte	: out STD_LOGIC_VECTOR(7 downto 0);
			source_val	: out STD_LOGIC
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 						:  std_logic := '0';
	SIGNAL reset_n 					:  std_logic := '0';
	SIGNAL ce 						:  std_logic := '0';	
	SIGNAL sink_val					:  std_logic := '0';
	SIGNAL sink_sop					:  std_logic := '0';
	SIGNAL sink_eop					:  std_logic := '0';
	SIGNAL sink_byte				:  std_logic_vector(7 downto 0) := (others=>'0');	
	
	--Intermediate			
	signal aux_bit 					: std_logic;
	signal aux_val					: std_logic;
	signal aux_sop					: std_logic;
	signal aux_eop					: std_logic;
	-- mux adapter
	signal mux_adapter_sink_bit		: std_logic;
	signal mux_adapter_sink_val		: std_logic;
	signal mux_adapter_source_bit	: std_logic;
	signal mux_adapter_source_val 	: std_logic;	
	SIGNAL mux_adapter_source_sop	: std_logic;
	SIGNAL mux_adapter_source_eop	: std_logic;

	--Outputs
	SIGNAL sink_rdy	 				: std_logic;
	SIGNAL source_byte				: std_logic_vector(7 downto 0);	
	SIGNAL source_val 				: std_logic;	
	
	--Testbench
	file	OUT_FILE	: TEXT;
	file	IN_FILE	: TEXT;	
	
	shared variable cycles_cntr	: integer	:= 0;	

BEGIN
	
	-- 8 bit to 1 bit serializer
	Inst_byte_serializer: byte_serializer PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_byte 	=> sink_byte,		
		sink_val 	=> sink_val,		
		sink_rdy 	=> sink_rdy,
		source_bit	=> aux_bit, -- source_bit,
		source_sop	=> aux_sop,	-- source_sop,
		source_eop	=> aux_eop,	-- source_eop,
		source_val 	=> aux_val 	-- source_val
		);

	mux_adapter_sink_bit <= aux_bit;
	mux_adapter_sink_val <= aux_val;
	
	-- Instantiate the Unit Under Test (UUT)
	uut: mux_adapter PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_bit 	=> mux_adapter_sink_bit,
		sink_val 	=> mux_adapter_sink_val,
		source_bit	=> mux_adapter_source_bit,
		source_val 	=> mux_adapter_source_val,
		source_sop	=> mux_adapter_source_sop,
		source_eop	=> mux_adapter_source_eop
	);

	-- 8 bits to 1 byte parallelizer
	Inst_bit_parallelizer: bit_parallelizer PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_bit 	=> mux_adapter_source_bit,
		sink_val 	=> mux_adapter_source_val,
		source_byte	=> source_byte,
		source_val 	=> source_val
	);

	process
	begin
		clk   <= '1';
		wait for CLOCK_PERIOD/2;
		clk   <= '0';
		wait for CLOCK_PERIOD/2;
	end process;

	-- Procesos para introducción de datos por la entrada:	
	-- Utilizamos flanco descendente para que esta introducción hecha en el testbench no penalice un ciclo.
	rdCntr: process(clk)
		variable cuenta_tandas	: integer := 0;
		variable valor_inicial	: integer := 0;
	begin
		if clk'event and clk = '0' then -- clk = '1'
			if reset_n = '0' then
				cycles_cntr := 0;
				cuenta_tandas := 0;				
			elsif ce = '1' and sink_rdy = '1' then 
				if cycles_cntr = 0 then
					if cuenta_tandas = 6	then				
						cuenta_tandas := 0;
						valor_inicial := 20 - 1;
					else
						cuenta_tandas := cuenta_tandas + 1;
						valor_inicial := 18 - 1;
					end if;
					cycles_cntr := valor_inicial;
				else
					cycles_cntr := cycles_cntr - 1;
				end if;

			end if;
		end if;
	end process;
	
	rdFile: process(clk)
		variable dato	 : line;
		variable valor	 : integer;
		variable rd_cntr : integer;	
	begin
		if clk'event and clk = '0' then -- clk = '1'
			if reset_n = '0' then
				rd_cntr := 0;				
				sink_byte <= (others => '0');
				sink_val <= '0'; 
				sink_sop <= '0'; 
				sink_eop <= '0';
			elsif ce = '1' and sink_rdy = '1' then 
				
				if cycles_cntr = 1 then				  
					rd_cntr := rd_cntr + 1;
					if rd_cntr = 1 then
						sink_sop <= '1';
						sink_eop <= '0';
					elsif rd_cntr = NUM_BYTES_TS then
						rd_cntr := 0;
						sink_sop <= '0';
						sink_eop <= '1';
					else
						sink_eop <= '0';
						sink_sop <= '0';
					end if;				  
				  
					if (not endfile(IN_FILE)) then
						readline(IN_FILE, dato);
						read (dato, valor);	
					else
						file_close (IN_FILE);
						file_open(IN_FILE, "../00_entrada_8ts.dat", read_mode);
						readline(IN_FILE, dato);
						read (dato, valor);	
					end if;
--					byte_entrada := conv_std_logic_vector(valor, 9);
					sink_byte <= conv_std_logic_vector(valor, 8);
					sink_val <= '1';
				else
					sink_val <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	wrFile: process(clk)
		variable dato : line;
		variable wr_cntr : integer;
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wr_cntr := 0;
			elsif ce = '1' then 
				if source_val = '1'then 
					write(dato, conv_integer(source_byte));
					writeline(OUT_FILE, dato);
					wr_cntr := wr_cntr + 1;
				end if;
			end if;
		end if;
	end process;	
		
	tb : PROCESS
	BEGIN
		file_open(IN_FILE, "../00_entrada_8ts.dat", read_mode);
		file_open(OUT_FILE, "../01_salida_mux_adapter.dat", write_mode);
		reset_n <= '0';
		ce <= '0';
		-- Wait 100 ns for global reset to finish
		wait for 110 ns;
		reset_n <= '1';
		ce <= '1';		
		wait for 595 ns;
--		wait until file_end = '1';		
		wait for 499 us;
		file_close (IN_FILE);
		file_close (OUT_FILE);
		wait; -- will wait forever
	END PROCESS;

END;

-- synthesis translate_on
