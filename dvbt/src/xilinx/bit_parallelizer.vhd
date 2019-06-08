-------------------------------------------------------------------------
-- Bit Parallelizer
-- This module group into bytes the bits they are arriving at the input
-------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity bit_parallelizer is
    Port ( clk		: in  STD_LOGIC;
           reset_n 	: in  STD_LOGIC;
           ce 		: in  STD_LOGIC;
           entrada 	: in  STD_LOGIC;
           new_data	: in  STD_LOGIC;
		   salida 	: out STD_LOGIC_VECTOR(7 downto 0);
		   byte_rdy	: out STD_LOGIC);
end bit_parallelizer;


architecture Behavioral of bit_parallelizer is

	signal cuenta_bits 	: std_logic_vector(2 downto 0);
	signal byte_aux		: std_logic_vector(7 downto 0);
	
	signal byte_prerdy	: std_logic;
	signal ce_carga_datos	: std_logic;
	signal ultimo_bit	: std_logic;

begin

	ce_carga_datos <= ce and new_data;

	-- Ciclic counter, it generates a pulse per each new byte
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				cuenta_bits <= "111";
			elsif ce_carga_datos = '1' then
				cuenta_bits <= cuenta_bits - 1;
			end if;
		end if;
	end process;
	
	ultimo_bit <= '1' when cuenta_bits = "000" else '0';

	-- storing bits into byte_aux
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				byte_aux <= (others => '0');
			elsif ce_carga_datos = '1' then
				byte_aux(conv_integer(cuenta_bits)) <= entrada;
			end if;
		end if;
	end process;
	
	-- Outputs	
	salida <= byte_aux;
	byte_prerdy <= ultimo_bit and new_data;

	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				byte_rdy <= '0';
			elsif ce = '1' then
				byte_rdy <= byte_prerdy;
			end if;
		end if;
	end process;	
	
end Behavioral;

