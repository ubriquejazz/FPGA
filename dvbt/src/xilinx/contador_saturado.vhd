----------------------------------------------------------------------------
-- Limited Counter (Reading the Symbol Interleaver memories)
--
-- The ce input makes that the counter k = 0 : 1511 when counter j = 0 : 2047
-- The k counter is reseted when the ready_int signal is over
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;
	
entity contador_saturado is
	port (
		clk				: IN 	std_logic;
		reset_n 		: IN  std_logic;
		cont_rst_n		: IN  std_logic;
		ce				: IN  std_logic;
		symbol_index	: OUT std_logic_VECTOR(12 downto 0)
	);
end contador_saturado;


architecture Behavioral of contador_saturado is

	signal cont_2k		: std_logic_vector(10 downto 0);
	signal resta_2k		: std_logic_vector(12 downto 0);
	signal cont_sat_2k 	: std_logic_vector(10 downto 0);
	
	signal cont_8k			: std_logic_vector(12 downto 0);
	signal resta_8k		: std_logic_vector(14 downto 0);
	signal cont_sat_8k 	: std_logic_vector(12 downto 0);

begin

	-- 2k/8k counters: 1 cycle
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or cont_rst_n = '0' then
				cont_2k 	<= (others => '0');
			elsif ce = '1' then
				cont_2k	<= cont_2k + 1;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or cont_rst_n = '0' then
				cont_8k 	<= (others => '0');
			elsif ce = '1' then
				cont_8k	<= cont_8k + 1;
			end if;
		end if;
	end process;

	resta_2k <= conv_std_logic_vector(1511, 13) - cont_2k;
	resta_8k <= conv_std_logic_vector(6047, 15) - cont_8k;
	
	--------------------------
	-- 2k saturator: 0 cycle
	-- 8k saturator: 1 cycle
	--------------------------

	cont_sat_2k <= cont_2k when resta_2k(12) = '0' else (others => '0');
	--	process(clk)
	--	begin
	--		if clk'event and clk = '1' then
	--			if reset_n = '0' then
	--				cont_sat_2k <= (others => '0');
	--			elsif resta_2k(12) = '1' then
	--				cont_sat_2k <= (others => '0');				
	--			else
	--				cont_sat_2k <= cont_2k;
	--			end if;
	--		end if;
	--	end process;

	--	cont_sat_8k <= cont_8k when resta_8k(14) = '0' else (others => '0');
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				cont_sat_8k <= (others => '0');
			elsif resta_8k(14) = '1' then
				cont_sat_8k <= (others => '0');				
			else
				cont_sat_8k <= cont_8k;
			end if;
		end if;
	end process;

	symbol_index <= "00" & cont_sat_2k when OFDM = 2 else cont_sat_8k;
	
end Behavioral;	
