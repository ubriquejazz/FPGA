library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity reg_simple is
    Port 	( clk     : in  STD_LOGIC;
			  reset_n : in  STD_LOGIC;
			  ce      : in  STD_LOGIC;
			  entrada : in  STD_LOGIC;
			  salida  : out STD_LOGIC);
end reg_simple;

architecture Behavioral of reg_simple is

begin

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				salida <= '0';
			elsif ce = '1' then
				salida <= entrada;
			end if;
		end if;
	end process;
	
end Behavioral;