---------------------------------------------------------------------------------
-- QAM Mapper
---------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

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
	
	-- normalized symbols and 16 bits coded symbols
	SIGNAL xn_qam64_re 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qam64_im 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qam16_re 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qam16_im 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qpsk_re 	: std_logic_VECTOR(15 downto 0);
	SIGNAL xn_qpsk_im 	: std_logic_VECTOR(15 downto 0);
	
begin

	U1 : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "./mif/qam64_re.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 64,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		widthad_a => 6,
		width_a => 16,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => addr,
		clock0 => clk,
		clocken0 => ce,
		q_a => xn_qam64_re
	);

	U2 : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "./mif/qam64_im.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 64,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		widthad_a => 6,
		width_a => 16,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => addr,
		clock0 => clk,
		clocken0 => ce,
		q_a => xn_qam64_im
	);
	
--	U1 : qam64_re
--	port map ( 
--		clka  	=> clk, 
--		ena		=> ce,
--		addra 	=> addr, 
--		douta 	=>	xn_qam64_re );

--	U2 : qam64_im
--	port map ( 
--		clka  	=> clk, 
--		ena		=> ce,
--		addra 	=> addr, 
--		douta 	=>	xn_qam64_im );
	
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

-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library WORK;
use WORK.mypackage.all;

ENTITY mapper_64qam_tb_vhd IS
END mapper_64qam_tb_vhd;

ARCHITECTURE behavior OF mapper_64qam_tb_vhd IS 

	COMPONENT mapper_64qam
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		addr 		: IN std_logic_vector(5 downto 0);          
		xn_re 		: OUT std_logic_vector(15 downto 0);
		xn_im 		: OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;
	
	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL addr		 	:  std_logic_vector(5 downto 0);
	--Outputs
	SIGNAL qam_re 		:  std_logic_vector(15 downto 0);
	SIGNAL qam_im 		:  std_logic_vector(15 downto 0);
	
BEGIN
	
	uut: mapper_64qam 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		addr 		=> addr,
		xn_re 		=> qam_re,
		xn_im 		=> qam_im
	);
		
	-- Clock
	process
	begin
		clk   <= '1';
		wait for CLOCK_PERIOD/2;
		clk   <= '0';
		wait for CLOCK_PERIOD/2;
	end process;
	
	process (clk)
		variable   cnt : integer;
	begin
		if (rising_edge(clk)) then
			if reset_n = '0' then
				-- Reset the counter to 0
				cnt := 0;
			elsif ce = '1' then
				-- Increment the counter if counting is enabled			   
				cnt := cnt + 1;
			end if;
		end if;

		-- Output the current count
		addr <= conv_std_logic_vector (cnt,6);
	end process;
	
	tb : PROCESS
	BEGIN

		reset_n <= '0';
		ce	<= '0';
		wait for CLOCK_PERIOD;        	   --wait for GSR
		reset_n <= '1';
		ce <= '1';
		wait for CLOCK_PERIOD;

		-- Place stimulus here

		wait; -- will wait forever
	END PROCESS;
		
END;

-- synthesis translate_on