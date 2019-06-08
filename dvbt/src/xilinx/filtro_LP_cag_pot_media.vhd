library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity filtro_LP_cag_pot_media is
    Port ( 
		clk     	: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce    		: IN  std_logic;
		entrada		: in  STD_LOGIC_VECTOR (17 downto 0);
		salida		: out STD_LOGIC_VECTOR (17 downto 0));
end filtro_LP_cag_pot_media;

architecture Behavioral of filtro_LP_cag_pot_media is

	COMPONENT mult_add
	PORT(
		clk     : IN  std_logic;
		reset_n : IN  std_logic;
		ce      : IN  std_logic;
		A       : IN  std_logic_vector(17 downto 0);
		B       : IN  std_logic_vector(17 downto 0);
		PCIN    : IN  std_logic_vector(47 downto 0);          
		PCOUT   : OUT std_logic_vector(47 downto 0)
		);
	END COMPONENT;
	
	COMPONENT reg_18bits
	PORT(
		clk     : IN std_logic;
		reset_n : IN std_logic;
		ce      : IN std_logic;
		entrada : IN 	std_logic_vector(17 downto 0);          
		salida  : OUT 	std_logic_vector(17 downto 0)
		);
	END COMPONENT;
	
	type multi_signal_dsp is array (2 downto 0) of std_logic_vector (17 downto 0);
--	signal alfa:  std_logic_vector (17 downto 0) := "011111001100110100";	
	signal alfa:  std_logic_vector (17 downto 0);									
	signal uno_menos_alfa	: std_logic_vector (17 downto 0);
	signal suma_aux_1	: std_logic_vector (47 downto 0);
	signal suma_aux_2	: std_logic_vector (47 downto 0);
	signal entrada_reg 	: multi_signal_dsp;

begin
	--------------------------------------------------------------------------------------------------------
	-- The alpha value depends on the cutting frequency and the sampling period:
	--				alfa = 2 * pi * fcut / fsampling
	--------------------------------------------------------------------------------------------------------
	alfa <= "011111010000111100";
	uno_menos_alfa <= "011111111111111111" - alfa;
	
	Inst_mult_add_1: mult_add 
	PORT MAP(
		clk     => clk,
		reset_n => reset_n,
		ce      => ce,
		A       => entrada,
		B       => uno_menos_alfa,
		PCIN    => (others => '0'),
		PCOUT   => suma_aux_1
	);

	Inst_mult_add_2: mult_add 
	PORT MAP(
		clk     => clk,
		reset_n => reset_n,
		ce      => ce,
		A       => suma_aux_2(34 downto 17),
		B       => alfa,
		PCIN    => suma_aux_1,
		PCOUT   => suma_aux_2
	);
	
	-- Low Pass Filter
	salida <= suma_aux_2(34 downto 17); 

end Behavioral;

