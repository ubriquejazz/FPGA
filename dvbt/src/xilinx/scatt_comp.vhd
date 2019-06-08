library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity scatt_comp is
	PORT(
			clk			: IN  std_logic;
			reset_n		: IN  std_logic;
			ce			: IN  std_logic;
			A			: IN  std_logic_vector(12 downto 0);
			B			: IN  std_logic_vector(12 downto 0);
			C			: OUT std_logic
		);
end scatt_comp;

architecture Behavioral of scatt_comp is

	signal aux : std_logic_vector(12 downto 0);

begin

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				C <= '0';
			elsif ce = '1' then
				if (A = B) then
					C <= '1';
				else
					C <= '0';
				end if;	
			end if;
		end if;
	end process;
							  
	-- xor(A, not(A)) = (others => '1')
	--	C <= '1' when aux = B"1111111111111" else '0';

end Behavioral;