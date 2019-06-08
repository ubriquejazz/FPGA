library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity mult_add is
    Port ( clk     : in  STD_LOGIC;
           reset_n : in  STD_LOGIC;
           ce      : in  STD_LOGIC;
           A       : in  STD_LOGIC_VECTOR (17 downto 0);
           B       : in  STD_LOGIC_VECTOR (17 downto 0);
           PCIN    : in  STD_LOGIC_VECTOR (47 downto 0);
           PCOUT   : out STD_LOGIC_VECTOR (47 downto 0));
end mult_add;

architecture Behavioral of mult_add is

begin

	process (clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then   
				PCOUT <= (others=>'0');
			elsif ce = '1' then
				PCOUT <= PCIN + (A*B);
			end if;
		end if;
	end process;

end Behavioral;

