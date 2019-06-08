library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity up_converter is
	port(		
		clk 				: IN  std_logic;
		reset_n 			: IN  std_logic;
		ce 					: IN  std_logic;
		DinI				: IN  std_logic_VECTOR(17 downto 0);
		DinQ				: IN  std_logic_VECTOR(17 downto 0);
		dac1				: OUT std_logic_VECTOR(17 downto 0);				
		dac2 				: OUT std_logic_VECTOR(17 downto 0)
	 	);
end up_converter;

architecture Behavioral of up_converter is
	
	COMPONENT mezclador
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		phase 		: IN std_logic_vector(1 downto 0);
		data_in 	: IN std_logic_vector(17 downto 0);          
		data_out 	: OUT std_logic_vector(17 downto 0)
		);
	END COMPONENT;

	signal fase_coseno 		: std_logic_vector(1 downto 0);
	signal fase_seno 		: std_logic_vector(1 downto 0);
	signal fase_menos_seno 	: std_logic_vector(1 downto 0);
	
	SIGNAL I_coseno 		: std_logic_VECTOR(17 downto 0);		
	SIGNAL I_seno			: std_logic_VECTOR(17 downto 0);		
	SIGNAL Q_coseno 		: std_logic_VECTOR(17 downto 0);		
	SIGNAL Q_menos_seno  	: std_logic_VECTOR(17 downto 0);		

begin

	------------------
	--  I component --
	------------------

	fase_coseno <= "00";
	
	Inst_I_coseno: mezclador PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		phase 	=> fase_coseno,
		data_in 	=> DinI,
		data_out => I_coseno
	);

	fase_seno <= "01";
	
	Inst_I_seno: mezclador PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		phase 	=> fase_seno,
		data_in 	=> DinI,
		data_out => I_seno
	);

	------------------
	-- Q component --
	------------------
	
	fase_coseno <= "00";
	
	Inst_Q_coseno: mezclador PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		phase 		=> fase_coseno,
		data_in 	=> DinQ,
		data_out 	=> Q_coseno
	);

	fase_menos_seno <= "11";
	
	Inst_Q_menos_seno: mezclador PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		phase 		=> fase_menos_seno,
		data_in 	=> DinQ,
		data_out 	=> Q_menos_seno
	);
	
	------------------
	-- DAC Outpus   --
	------------------
	
	dac1 <= I_coseno; -- Q_menos_seno + ;
	dac2 <= Q_coseno; -- I_seno + 

end Behavioral;