-------------------------------------------------------------------------------------
-- Puncturing with serial output
--
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity puncturing is
	 Generic	(	
		FEC 			: natural := 34;
		Orate			: integer := 4);
    Port ( 
		clk 			: IN std_logic;
		reset_n 		: IN std_logic;
		ce 				: IN std_logic;
		x				: IN std_logic;
		y				: IN std_logic;
		new_data		: IN std_logic;
		--
		salida 			: OUT std_logic;
		data_rdy 		: OUT std_logic
	);
end puncturing;

architecture Behavioral of puncturing is

	-- inputs
	signal x_reg 			: std_logic;
	signal y_reg 			: std_logic;
	signal new_data_reg 	: std_logic;

	-- output fsm
	type fsm_states is (salida0, salida1, salida2, salida3, salida4, salida5, salida6, salida7);
	signal wait_gen : fsm_states;
	
	-- data ready counter
	signal cont_data_rdy		: std_logic_vector (2 downto 0);
	signal rst_cont_data_rdy	: std_logic;
	signal data_rdy_int			: std_logic;
	signal data_rdy_int_reg		: std_logic;

	-- puncturing
	signal pattern_x	: std_logic_vector(6 downto 0);
	signal pattern_y 	: std_logic_vector(6 downto 0);
	
	-- FEC = 12:
--	constant PATTERN_X 	: std_logic_vector(6 downto 0) := "0000001";
--	constant PATTERN_Y 	: std_logic_vector(6 downto 0) := "0000001";
	
	-- FEC = 23:
--	constant PATTERN_X 	: std_logic_vector(6 downto 0) := "0000001";
--	constant PATTERN_Y 	: std_logic_vector(6 downto 0) := "0000011";
	
	-- FEC = 34:
--	constant PATTERN_X 	: std_logic_vector(6 downto 0) := "0000101";
--	constant PATTERN_Y 	: std_logic_vector(6 downto 0) := "0000011";
	
	-- FEC = 56:
--	constant PATTERN_X 	: std_logic_vector(6 downto 0) := "0010101";
--	constant PATTERN_Y 	: std_logic_vector(6 downto 0) := "0001011";
	
	-- FEC = 78:
--	constant PATTERN_X 	: std_logic_vector(6 downto 0) := "1010001";
--	constant PATTERN_Y 	: std_logic_vector(6 downto 0) := "0101111";

begin

	pattern_x <= 	"0000001" when FEC = 12 else 	
						"0000001" when FEC = 23 else 		
						"0000101" when FEC = 34 else 
						"0010101" when FEC = 56 else 
						"1010001" when FEC = 78 else 
						(others => '0'); 	
	
	pattern_y <= 	"0000001" when FEC = 12 else 	
						"0000011" when FEC = 23 else 		
						"0000011" when FEC = 34 else 
						"0001011" when FEC = 56 else 
						"0101111" when FEC = 78 else 
						(others => '0'); 		

	-------------------------------------------------------------------------
	-- To register input signals
	-------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				x_reg <= '0';
			elsif ce = '1' and new_data = '1' then
				x_reg <= x;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				y_reg <= '0';
			elsif ce = '1' and new_data = '1' then
				y_reg <= y;
			end if;
		end if;
	end process;

	-------------------------------------------------------------------------
	-- FSM
	-------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen <= salida0;
			elsif ce = '1' then
				case wait_gen is
				
					when salida0	=>	if new_data = '1' then
												wait_gen <= salida1;
											else
												wait_gen <= salida0;
											end if;
					when salida1	=>	if Orate = 2 then
												wait_gen <= salida0;
											elsif new_data = '1' then
												wait_gen <= salida2;
											end if;
					when salida2	=>	if Orate = 3 then
												wait_gen <= salida0;
											elsif new_data = '1' then
												wait_gen <= salida3;
											end if;
					when salida3	=>	if Orate = 4 then
												wait_gen <= salida0;
											elsif new_data = '1' then
												wait_gen <= salida4;
											end if;
					when salida4	=>	if Orate = 5 then
												wait_gen <= salida0;
											elsif new_data = '1' then
												wait_gen <= salida5;
											end if;
					when salida5	=>	if Orate = 6 then
												wait_gen <= salida0;
											elsif new_data = '1' then
												wait_gen <= salida6;
											end if;
					when salida6	=>	if Orate = 7 then
												wait_gen <= salida0;
											elsif new_data = '1' then
												wait_gen <= salida7;
											end if;
					when salida7	=>	wait_gen <= salida0;
					
				end case;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------
	-- Output
	-------------------------------------------------------------------------
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				salida <= '0';
			elsif ce = '1' then
				case wait_gen is
					when salida0	=>	salida <= x;
					when salida1	=>	salida <= y_reg;
					when salida2	=>	salida <= (x_reg and pattern_x(1)) or (y_reg and pattern_y(1));
					when salida3	=>	salida <= (x_reg and pattern_x(2)) or (y_reg and pattern_y(2));
					when salida4	=>	salida <= (x_reg and pattern_x(3)) or (y_reg and pattern_y(3));
					when salida5	=>	salida <= (x_reg and pattern_x(4)) or (y_reg and pattern_y(4));
					when salida6	=>	salida <= (x_reg and pattern_x(5)) or (y_reg and pattern_y(5));
					when salida7	=>	salida <= (x_reg and pattern_x(6)) or (y_reg and pattern_y(6));
				end case;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------
	-- Data Ready
	-------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or data_rdy_int = '1' then
				cont_data_rdy <= conv_std_logic_vector(1, 3);
			elsif ce = '1' and new_data = '1' then
				cont_data_rdy <= cont_data_rdy + 1;
			end if;
		end if;
	end process;	

	data_rdy_int <= '1' when cont_data_rdy = conv_std_logic_vector(Orate, 4) else '0';

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				data_rdy_int_reg <= '0';
			elsif ce = '1' then
				data_rdy_int_reg <= data_rdy_int;
			end if;
		end if;
	end process;
	
	data_rdy <= new_data_reg or data_rdy_int_reg;
			
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_reg <= '0';
			elsif ce = '1' then
				new_data_reg <= new_data;
			end if;
		end if;
	end process;	
	
end Behavioral;