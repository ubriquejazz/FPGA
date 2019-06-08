library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity contador7x is
   Port ( 
		clk 			: in  STD_LOGIC;
		reset_n			: in  STD_LOGIC;
		ce 				: in  STD_LOGIC;
		oe_7			: out STD_LOGIC
	);
end contador7x;

architecture Behavioral of contador7x is

	signal count_7   : unsigned (2 downto 0);
	signal oe_int_7  : std_logic;

begin

	-- divisor x7
	process (clk) 
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' or oe_int_7 = '1' then 
				count_7 <= (others => '0');
			elsif ce = '1' then
				count_7 <= count_7 + 1;
			end if;
		end if;
	end process; 
	
	oe_int_7 <= '1' when count_7 = 6 else '0';
	oe_7 <= oe_int_7;
		
end Behavioral;
