library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity scatt_adder is
	PORT(
			clk			: IN  std_logic;
			reset_n		: IN  std_logic;
			ce			: IN  std_logic;
			A			: IN  std_logic_vector(12 downto 0);
			B			: IN  std_logic_vector(12 downto 0);
			C			: OUT std_logic_vector(12 downto 0)
		);
end scatt_adder;

architecture Behavioral of scatt_adder is

begin

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				C <= (others => '0');
			elsif ce = '1' then
				C <= A + B;
			end if;
		end if;
	end process;

end Behavioral;

