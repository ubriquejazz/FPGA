----------------------------------------------------------------------------------
-- OUTER ENCODER (rs_encoder v3.1)
--
-- The start signal is active at the sync byte (i.e. start of every 188 bytes packets)
-- At the last byte the rs_encoder generates 204 - 188 = 16 bytes instead of only one.
-- This difference at the output rate is solved with a 32 bytes buffer at the input. 
-- The rdy_for_data signal is used to extract the information from this buffer.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity outer_coder is
    Port ( clk 			: in  STD_LOGIC;
           reset_n 		: in  STD_LOGIC;
           ce 			: in  STD_LOGIC;
		   sink_rdy		: out STD_LOGIC;
           sink_byte	: in  STD_LOGIC_VECTOR (7 downto 0);
           sink_val	 	: in  STD_LOGIC;
           sink_sop	 	: in  STD_LOGIC;
           sink_eop	 	: in  STD_LOGIC;
           source_rdy 	: in  STD_LOGIC;		   
           source_byte 	: out STD_LOGIC_VECTOR (7 downto 0);
           source_val	: out STD_LOGIC;
           source_sop	: out STD_LOGIC;
           source_eop	: out STD_LOGIC
	);
end outer_coder;

architecture Behavioral of outer_coder is

 	COMPONENT rs_encoder
	PORT (
		clk			: IN  STD_LOGIC;
		reset		: IN  STD_LOGIC;
		rsin		: IN  STD_LOGIC_VECTOR (8 DOWNTO 1);
		sink_val	: IN  STD_LOGIC;
		sink_sop	: IN  STD_LOGIC;
		sink_eop	: IN  STD_LOGIC;
		sink_ena	: OUT STD_LOGIC;
		source_ena	: IN  STD_LOGIC;
		rsout		: OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
		source_val	: OUT STD_LOGIC;
		source_sop	: OUT STD_LOGIC;
		source_eop	: OUT STD_LOGIC
	);		
	END COMPONENT;
	
	signal aclr : std_logic;

begin

	aclr <= not reset_n;
	
	Inst_outer_coder: rs_encoder
	PORT MAP (
		clk  		=>  clk,
		reset  		=>  aclr,
		rsin  		=>  sink_byte,
		sink_ena  	=>  sink_rdy, -- output
		sink_val  	=>  sink_val,
		sink_sop  	=>  sink_sop,
		sink_eop  	=>  sink_eop, 
		source_ena  => source_rdy, -- input
		rsout  		=> source_byte,
		source_val  => source_val,
		source_sop  => source_sop,
		source_eop  => source_eop
	);
	
end Behavioral;

-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;

library WORK;
use WORK.mypackage.all;

ENTITY outer_coder_tb_vhd IS
END outer_coder_tb_vhd;

ARCHITECTURE behavior OF outer_coder_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT outer_coder
	PORT(
		clk 		: in std_logic;
	   reset_n 		: in  STD_LOGIC;
	   ce 			: in  STD_LOGIC;
	   sink_rdy		: out STD_LOGIC;
	   sink_byte	: in  STD_LOGIC_VECTOR (7 downto 0);
	   sink_val	 	: in  STD_LOGIC;
	   sink_sop	 	: in  STD_LOGIC;
	   sink_eop	 	: in  STD_LOGIC;
	   source_rdy 	: in  STD_LOGIC;		   
	   source_byte 	: out STD_LOGIC_VECTOR (7 downto 0);
	   source_val	: out STD_LOGIC;
	   source_sop	: out STD_LOGIC;
	   source_eop	: out STD_LOGIC
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL sink_val 	:  std_logic := '0';
	SIGNAL sink_sop 	:  std_logic := '0';
	SIGNAL sink_eop 	:  std_logic := '0';
	SIGNAL sink_byte	:  std_logic_vector(7 downto 0) := (others=>'0');

	--Outputs
	SIGNAL sink_rdy 	:  std_logic;
	SIGNAL source_byte 	:  std_logic_vector(7 downto 0);
	SIGNAL source_val 	:  std_logic;
	SIGNAL source_sop 	:  std_logic;
	SIGNAL source_eop 	:  std_logic;

	--Testbench
	file OUT_FILE	: TEXT;
	file IN_FILE	: TEXT;
	signal file_end	: std_logic;	
	shared variable cycles_cntr	: integer	:= 0;	

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: outer_coder PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_rdy 	=> sink_rdy,
		sink_byte 	=> sink_byte,
		sink_val 	=> sink_val,
		sink_sop 	=> sink_sop,
		sink_eop 	=> sink_eop,
		source_rdy  => '1',
		source_byte => source_byte,
		source_val 	=> source_val,
		source_sop 	=> source_sop,		
		source_eop 	=> source_eop
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
	rdFile: process(clk)
		variable dato	 : line;
		variable valor	 : integer;
		variable rd_cntr : integer;	
	begin
		if clk'event and clk = '0' then	-- clk = '1'
			if reset_n = '0' then
				cycles_cntr	:= 0;
				rd_cntr := 0;
				file_open(IN_FILE, "../01_salida_mux_adapter.dat", read_mode);
				sink_byte <= (others => '0');
				sink_val <= '0';
				sink_sop <= '0'; 
				sink_eop <= '0';				
				file_end <= '0';
			elsif ce = '1' and sink_rdy = '1' then
			
				if cycles_cntr = 8 then
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
						file_end <= '1';
						valor := 0;
					end if;					
					sink_byte  <= conv_std_logic_vector(valor, 8);
					sink_val <= '1';
					cycles_cntr := 0;
				else
					sink_val <= '0';
					cycles_cntr := cycles_cntr + 1;
				end if;				
			end if;
		end if;
	end process;
	
	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	wrFile: process(clk)
		variable dato : line;
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				file_open(OUT_FILE, "../101_rs_coder.dat", write_mode);
			elsif ce = '1' then 
				if source_val = '1'then -- and file_end = '0' then
					write(dato, conv_integer(source_byte));
					writeline(OUT_FILE, dato);
				end if;
			end if;
		end if;
	end process;
		
	tb : PROCESS
	BEGIN

		reset_n <= '0';
		ce <= '0';
		-- Wait 100 ns for global reset to finish
		wait for 110 ns;
		reset_n <= '1';
		ce <= '1';		
		wait until file_end = '1';
		wait for 15*CLOCK_PERIOD;
		file_close (IN_FILE);
		file_close (OUT_FILE);

		wait; -- will wait forever
	END PROCESS;

END;

-- synthesis translate_on