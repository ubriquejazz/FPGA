---------------------------------------------------------------------------------
-- QAM Mapper
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity mapper_64qam is
	port (
		clk			: IN 	std_logic;
		reset_n 	: IN  	std_logic;
		ce 			: IN  	std_logic;
		addr		: IN 	std_logic_VECTOR(5 downto 0);
		xn_re		: OUT 	std_logic_VECTOR(15 downto 0);
		xn_im		: OUT 	std_logic_VECTOR(15 downto 0)
		);
end mapper_64qam;


architecture Behavioral of mapper_64qam is

	COMPONENT qam64_re
	PORT(
		addra	: IN std_logic_VECTOR(5 downto 0);
		clka	: IN std_logic;
		douta	: OUT std_logic_VECTOR(15 downto 0);
		ena		: IN std_logic
		);
	END COMPONENT;

	COMPONENT qam64_im
	PORT(
		addra	: IN std_logic_VECTOR(5 downto 0);
		clka	: IN std_logic;
		douta	: OUT std_logic_VECTOR(15 downto 0);
		ena		: IN std_logic
		);
	END COMPONENT;
	
	COMPONENT qam16_re
	PORT(
		addr	: IN std_logic_VECTOR(5 downto 0);
		clk		: IN std_logic;
		dout	: OUT std_logic_VECTOR(15 downto 0);
		en		: IN std_logic
		);
	END COMPONENT;

	COMPONENT qam16_im
	PORT(
		addr	: IN std_logic_VECTOR(5 downto 0);
		clk		: IN std_logic;
		dout	: OUT std_logic_VECTOR(15 downto 0);
		en		: IN std_logic
		);
	END COMPONENT;
	
	COMPONENT qpsk_re
	PORT(
		addr	: IN std_logic_VECTOR(5 downto 0);
		clk		: IN std_logic;
		dout	: OUT std_logic_VECTOR(15 downto 0);
		en		: IN std_logic
		);
	END COMPONENT;

	COMPONENT qpsk_im
	PORT(
		addr	: IN std_logic_VECTOR(5 downto 0);
		clk		: IN std_logic;
		dout	: OUT std_logic_VECTOR(15 downto 0);
		en		: IN std_logic
		);
	END COMPONENT;
		
	-- normalized symbols and 16 bits coded symbols
	SIGNAL xn_qam64_re 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qam64_im 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qam16_re 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qam16_im 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qpsk_re 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qpsk_im 	: std_logic_VECTOR(15 downto 0);
	
begin

	U1 : qam64_re
	port map ( 
		clka  	=> clk, 
		ena		=> ce,
		addra 	=> addr, 
		douta 	=>	xn_qam64_re );

	U2 : qam64_im
	port map ( 
		clka  	=> clk, 
		ena		=> ce,
		addra 	=> addr, 
		douta 	=>	xn_qam64_im );

--	U3 : qam16_re
--	port map ( 
--		clk  	=> clk, 
--		en		=> ce,
--		addr 	=> addr, 
--		dout 	=>	xn_qam16_re );

--	U4 : qam16_im
--	port map ( 
--		clk  	=> clk, 
--		en		=> ce,
--		addr 	=> addr, 
--		dout 	=>	xn_qam16_im );

--	U5 : qpsk_re
--	port map ( 
--		clk  	=> clk, 
--		en		=> ce,
--		addr 	=> addr, 
--		dout 	=>	xn_qpsk_re );

--	U6 : qpsk_im
--	port map ( 
--		clk  	=> clk, 
--		en		=> ce,
--		addr 	=> addr, 
--		dout	=>	xn_qpsk_im );

	-- Output Multiplexor
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				xn_re <= (others => '0');
				xn_im	<= (others => '0');
			elsif ce = '1' then
				xn_im <= xn_qam64_im;
				xn_re <= xn_qam64_re;			
--				case QAM is
--					when 2		=>	xn_im <= xn_qpsk_im;
--										xn_re <= xn_qpsk_re;
--										
--					when 4		=>	xn_im <= xn_qam16_im;
--										xn_re <= xn_qam16_re;
--										
--					when 6		=>	xn_im <= xn_qam64_im;
--										xn_re <= xn_qam64_re;
--										
--					when others => xn_im <= (others => '1');
--										xn_re <= (others => '1');
--				end case;
			end if;
		end if;
	end process;

end Behavioral;