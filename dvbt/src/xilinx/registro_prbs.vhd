library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity registro_prbs is
    Port ( 		clk 		: in  STD_LOGIC;
				reset_n 	: in  STD_LOGIC;
				ce			: in  STD_LOGIC;
				init 		: in  STD_LOGIC;
				init_val	: in  STD_LOGIC;
				entrada 	: in  STD_LOGIC;
				salida 		: out STD_LOGIC
			);
end registro_prbs;

architecture Behavioral of registro_prbs is

begin
	process (clk) 
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				salida <= '0';
			elsif init = '1' then
				salida <= init_val;
			elsif ce = '1' then
				salida <= entrada;
			end if;
		end if;
	end process; 

end Behavioral;

