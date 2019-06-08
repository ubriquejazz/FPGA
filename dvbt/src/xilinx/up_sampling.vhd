library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity up_sampling is
	port ( 	ce				: IN std_logic;
				reset_n		: IN std_logic;
				--
				clk0		: IN std_logic;
				clk1		: IN std_logic;
				clk2		: IN std_logic;
				--
				DinI_s0		: IN  std_logic_VECTOR(15 downto 0);
				DinQ_s0		: IN  std_logic_VECTOR(15 downto 0);
				rd_en_s0	: OUT std_logic;
				empty_s0	: IN  std_logic;
				DoutI_s4	: OUT std_logic_VECTOR(17 downto 0);
				DoutQ_s4	: OUT std_logic_VECTOR(17 downto 0)					
	);
end up_sampling;

architecture Behavioral of up_sampling is

	---------------------------------------------------
	-- Interpolator
	---------------------------------------------------	
	signal I_us_18		: std_logic_VECTOR(17 downto 0);
	signal Q_us_18		: std_logic_VECTOR(17 downto 0);
--	signal rd_en_s4	: std_logic;
--	signal empty_s4	: std_logic;

	COMPONENT interpolador
	PORT(
		ce 			: IN std_logic;
		reset_n 	: IN std_logic;
		clk0 		: IN std_logic;
		clk1 		: IN std_logic;
		clk2 		: IN std_logic;
		rd_en_s0 	: OUT std_logic;
		empty_s0 	: IN  std_logic;
		data_in 	: IN  std_logic_vector(15 downto 0);
		data_out 	: OUT std_logic_vector(17 downto 0)
		);
	END COMPONENT;
	
	--------------------------------------------------
	-- Amplifier x49
	--------------------------------------------------
	signal I_us_ampl_18	: std_logic_VECTOR(17 downto 0);
	signal Q_us_ampl_18	: std_logic_VECTOR(17 downto 0);
	signal Q_aux_36		: std_logic_vector(35 downto 0);

	COMPONENT amplificador_18
	PORT(
		clk 			: IN std_logic;
		ce 			: IN std_logic;
		reset_n 		: IN std_logic;
		I_din_18 	: IN std_logic_vector(17 downto 0);
		Q_din_18 	: IN std_logic_vector(17 downto 0);          
		I_dout_18 	: OUT std_logic_vector(17 downto 0);
		Q_dout_18 	: OUT std_logic_vector(17 downto 0)
		);
	END COMPONENT;

begin

	-----------------------------------------------------
	-- I/Q interpolator
	-----------------------------------------------------
  
	Inst_interp_I: interpolador PORT MAP(
		ce 			=> ce,
		reset_n 	=> reset_n,
		clk0 		=> clk0,
		clk1 		=> clk1,
		clk2 		=> clk2,
		--
		rd_en_s0 	=> rd_en_s0,
		empty_s0 	=> empty_s0,
		data_in 	=> DinI_s0,
		data_out 	=> DoutI_s4
	);
	
	Inst_interp_Q: interpolador PORT MAP(
		ce 			=> ce,
		reset_n 	=> reset_n,
		clk0 		=> clk0,
		clk1 		=> clk1,
		clk2 		=> clk2,
	--	rd_en_s0 	=> rd_en_s0,
		empty_s0 	=> empty_s0,
		data_in 	=> DinQ_s0,
		data_out 	=> DoutQ_s4
	);

	-----------------------------------------------------
	-- Amplifier
	-----------------------------------------------------

	--	Inst_amplificador_18: amplificador_18 PORT MAP(
	--		ce 			=> ce,
	--		reset_n 	=> reset_n,
	--		clk0 		=> clk0_dcm,
	--		I_din_18 	=> DoutI_s4,
	--		Q_din_18 	=> DoutQ_s4,
	--		I_dout_18 	=> I_us_ampl_18,
	--		Q_dout_18 	=> Q_us_ampl_18
	--	);
	

end Behavioral;