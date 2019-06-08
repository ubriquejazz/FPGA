library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top_coding is
    Port (	
		clk			: in  STD_LOGIC;
		reset_n 	: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;
		--
		spi_dvalid	: in  STD_LOGIC;
		spi_data 	: in  STD_LOGIC_VECTOR(7 downto 0);
		spi_rdy		: out STD_LOGIC;
		--
		data_out 	: out STD_LOGIC; --_VECTOR(7 downto 0);
		data_rdy 	: out STD_LOGIC
		);
end top_coding;

architecture Behavioral of top_coding is

	COMPONENT coding
	 Generic	(	
		FEC 			: natural := 34;
		Irate			: integer := 3;
		Orate			: integer := 4);
	PORT(
		clk				: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce 				: IN  std_logic;
		entrada 		: IN  std_logic_vector(7 downto 0);
		new_data		: IN  std_logic;
		overflow		: out std_logic;
		data_out 		: out std_logic;	--_vector(7 downto 0);
		data_rdy 		: out std_logic
		);
	END COMPONENT;

begin

	Inst_coding: coding 
	GENERIC MAP(
		FEC			=> 34,
		Irate		=> 3,
		Orate		=> 4)	
	PORT MAP(
		clk			=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		new_data	=> spi_dvalid,
		entrada 	=> spi_data,
		overflow 	=> spi_rdy,
		data_out 	=> data_out,
		data_rdy	=> data_rdy
	);

end Behavioral;
