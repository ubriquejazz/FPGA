---------------------------------------------------------------------------
-- Writing Counters (Symbol Interleaver memories)
--
-- This module is grouping 6 bits words into symbols of 6048/1512 words
-- 	indice_i = 0 : 6047/1511
-- 	6 bits words counter at the symbol_interleaver input
--
-- si_wr_fin --> end of the count indicated by the OFDM parameter, 
-- 	it doesnt take into account the GI parameter.
--
-- si_wr_par: even symbol
-- 	the si_wr_fin is delayed one cycle from si_wr_par. This si_wr_par signal 
--	should be delayed externally to contadores_escritura module
--	(see the generation of the signals simbolo_par & simbolo_impar)
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;
	
entity contadores_escritura is
	port (
		clk					: IN  std_logic;
		reset_n 			: IN  std_logic;
		ce					: IN  std_logic;
	--	si_wr_data 		 	: IN  std_logic_vector(5 downto 0);
		si_wr_nd			: IN  std_logic;  
		--
		indice_i			: OUT std_logic_vector(12 downto 0);
		si_wr_par			: OUT std_logic;
		si_wr_fin			: OUT std_logic
	);
end contadores_escritura;


architecture Behavioral of contadores_escritura is

	signal indx_symbol_1512		: std_logic_vector(10 downto 0);
	signal indx_symbol_6048		: std_logic_vector(12 downto 0);
	signal fin_simbolo_1512		: std_logic;
	signal fin_simbolo_6048		: std_logic;
	signal si_wr_fin_int		: std_logic;

	signal simbolo_impar_1512	: std_logic;
	signal simbolo_impar_6048	: std_logic;
	signal simbolo_par_1512		: std_logic;
	signal simbolo_par_6048		: std_logic;
	signal si_wr_par_int		: std_logic;

begin
	
	----------------------------------------------------------------------------
	-- 2k Mode
	----------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				indx_symbol_1512 <= (others => '1');
			elsif fin_simbolo_1512 = '1' then
				indx_symbol_1512 <= (others => '0');
			elsif ce = '1' and si_wr_nd = '1' then
				indx_symbol_1512 <= indx_symbol_1512 + 1;
			end if;
		end if;
	end process;	

	fin_simbolo_1512 <= '1' when indx_symbol_1512 = conv_std_logic_vector(1512, 11) else '0';

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				simbolo_impar_1512 <= '1';
				-- simbolo_par <= '0';
			elsif fin_simbolo_1512 = '1' then
				simbolo_impar_1512 <= not simbolo_impar_1512;
			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------------
	-- 8k Mode
	----------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then 
				indx_symbol_6048 <= (others => '1');
			elsif fin_simbolo_6048 = '1' then
				indx_symbol_6048 <= (others => '0');
			elsif ce = '1' and si_wr_nd = '1' then
				indx_symbol_6048 <= indx_symbol_6048 + 1;
			end if;
		end if;
	end process;	

	fin_simbolo_6048 <= '1' when indx_symbol_6048 = conv_std_logic_vector(6048, 13) else '0';

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				simbolo_impar_6048 <= '1';
				-- simbolo_par <= '0';
			elsif fin_simbolo_6048 = '1' then
				simbolo_impar_6048 <= not simbolo_impar_6048;
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- Outputs
	----------------------------------------------------------------------------

	indice_i <= ( "00" & indx_symbol_1512 ) when OFDM = 2 else indx_symbol_6048;

	simbolo_par_1512	<= not simbolo_impar_1512;
	simbolo_par_6048	<= not simbolo_impar_6048;
	si_wr_par_int		<= simbolo_par_1512 when OFDM = 2 else simbolo_par_6048;
	si_wr_par	 	<= si_wr_par_int;

	si_wr_fin_int		<= fin_simbolo_1512 when OFDM = 2 else fin_simbolo_6048;
	si_wr_fin		<= si_wr_fin_int;
	
end Behavioral;
