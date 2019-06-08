----------------------------------------------------------------------------------------
-- TPS Generator
--
-- Every TPS carriers of the same symbol brings the same information bit,
-- so each frame has 68 bits; these are:
--
--      1 bit 	initialization
--      16 bits synchronization
--      37 bits info 
--      14 bits CRC
--
-- This all information is stored in a ROM
----------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity tps_gen is
	port (
		clk			: IN 	std_logic;
		reset_n	 	: IN  std_logic;
		ce				: IN  std_logic;
		frame_indx	: IN  std_logic_VECTOR(6 downto 0);
		tps_re		: OUT std_logic_VECTOR(15 downto 0)
	);
end tps_gen;


architecture Behavioral of tps_gen is
	
	-- BPSK values in 1.0.15 Fixed Point --> +/- 0.75 
	constant POSITIVE_BSPK : std_logic_vector(15 downto 0) := X"6000";	
	constant NEGATIVE_BSPK : std_logic_vector(15 downto 0) := X"A000"; 

	COMPONENT tabla_info_tps
	PORT(
			clka		: IN std_logic;
			addra		: IN std_logic_vector(6 downto 0);
			ena		: IN std_logic;
			ssra		: IN std_logic;
			douta		: OUT std_logic_vector(0 downto 0)
		);
	END COMPONENT;
	
	signal info_memo : std_logic_vector(0 downto 0);
	signal sclr	: std_logic;
	signal info : std_logic;

begin

	sclr <= not reset_n;
	
	Inst_tabla_info_tps : tabla_info_tps
	port map (
			clka 	=> clk,
			ssra 	=> sclr,
			ena 	=> ce,
			addra => frame_indx,
			douta => info_memo
	);

	info <= info_memo(0);
	tps_re <= POSITIVE_BSPK when info = '1' else NEGATIVE_BSPK;	
	
end Behavioral;