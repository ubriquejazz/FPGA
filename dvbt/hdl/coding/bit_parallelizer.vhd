-------------------------------------------------------------------------
-- Bit Parallelizer
--
-- Vamos agrupando en bytes los bits que nos llegan por la entrada
--
-------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity bit_parallelizer is
    Port ( clk			: in  STD_LOGIC;
			reset_n 	: in  STD_LOGIC;
			ce 			: in  STD_LOGIC;
			sink_bit 	: in  STD_LOGIC;
			sink_val	: in  STD_LOGIC;
--			sink_sop	: in  STD_LOGIC;
--			sink_eop	: in  STD_LOGIC;
			source_byte	: out STD_LOGIC_VECTOR(7 downto 0);
			source_val	: out STD_LOGIC);
end bit_parallelizer;


architecture Behavioral of bit_parallelizer is

	signal bit_cntr 		: std_logic_vector(2 downto 0);
	signal byte_aux			: std_logic_vector(7 downto 0);	
	signal byte_aux_val		: std_logic;
	signal last_bit			: std_logic;
	signal ce_sink_val		: std_logic;

begin

	ce_sink_val <= ce and sink_val;

	-- cyclic counter, last_bit pulse each time a byte is available
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				bit_cntr <= "111";
			elsif ce_sink_val = '1' then
				bit_cntr <= bit_cntr - 1;
			end if;
		end if;
	end process;
	
	last_bit <= '1' when bit_cntr = "000" else '0';

	-- storing bits into byte_aux
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				byte_aux <= (others => '0');
			elsif ce_sink_val = '1' then
				byte_aux(conv_integer(bit_cntr)) <= sink_bit;
			end if;
		end if;
	end process;
	
	-- output	
	source_byte <= byte_aux;
	byte_aux_val <= last_bit and sink_val;

	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				source_val <= '0';
			elsif ce = '1' then
				source_val <= byte_aux_val;
			end if;
		end if;
	end process;	
	
end Behavioral;


-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;

library WORK;
use WORK.mypackage.all;

ENTITY bit_parallelizer_tb_vhd IS
END bit_parallelizer_tb_vhd;

ARCHITECTURE behavior OF bit_parallelizer_tb_vhd IS 

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
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';	
	SIGNAL sink_val		:  std_logic := '0';
	SIGNAL sink_byte	:  std_logic_vector(7 downto 0) := (others=>'0');	
	SIGNAL sink_sop		:  std_logic := '0';
	SIGNAL sink_eop		:  std_logic := '0';
	
	--Intermediate
	signal aux_bit 		: std_logic;
	signal aux_val		: std_logic;
	signal aux_sop		: std_logic;
	signal aux_eop		: std_logic;

	--Outputs
	SIGNAL sink_rdy	 	: std_logic;
	SIGNAL source_byte	: std_logic_vector(7 downto 0);	
	SIGNAL source_val 	: std_logic;
	
	--Testbench
	shared variable cycles_cntr	: integer	:= 0;	
	
BEGIN
		
	-- 8 bits to 1 bit serializer
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

	-- 1 bit to 8 bits parallelizer
	uut: bit_parallelizer PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_bit 	=> aux_bit,
		sink_val 	=> aux_val,
		source_byte	=> source_byte,
		source_val 	=> source_val
	);		
	
	process
	begin
		clk <= '1';
		wait for CLOCK_PERIOD/2;
		clk <= '0';
		wait for CLOCK_PERIOD/2;
	end process;		
		
	-- Proceso para introducción de datos por la entrada a 27.99 Mbps
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
	
	process(clk)
		variable rd_cntr : integer;	
	begin
		if clk'event and clk = '0' then	-- clk = '1'
			if reset_n = '0' then
				rd_cntr := 0;				
				sink_byte <= (others => '0');
				sink_val <= '0'; 
				sink_sop <= '0'; 
				sink_eop <= '0';
			elsif ce = '1' then
					rd_cntr := rd_cntr + 1;
					if rd_cntr = 1 then
						sink_sop <= '1';
						sink_eop <= '0';
					elsif rd_cntr = 188 then
						rd_cntr := 0;
						sink_sop <= '0';
						sink_eop <= '1';
					else
						sink_eop <= '0';
						sink_sop <= '0';
					end if;				
			
				if cycles_cntr = 1 then
					sink_byte <= sink_byte + 1;
					sink_val <= '1';
				else
					sink_val <= '0';
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
		
		wait; -- will wait forever
	END PROCESS;

END;
-- synthesis translate_on