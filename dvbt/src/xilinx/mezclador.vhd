library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity mezclador is
	port(		
		clk 			: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce 				: IN  std_logic;
		phase			: IN  std_logic_vector(1 downto 0);
		data_in			: IN  std_logic_VECTOR(17 downto 0);
		data_out 		: OUT std_logic_VECTOR(17 downto 0)					
	 	);
end mezclador;

architecture Behavioral of mezclador is

	type fsm_states is (mas_uno, cero_pn, menos_uno, cero_np);
	signal wait_gen : fsm_states;

begin

	-------------------------------------------------------------------------
	-- FSM
	-------------------------------------------------------------------------
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				case phase is
					when "01"		=> wait_gen <= mas_uno;		-- 90
					when "10"		=> wait_gen <= cero_pn;		-- 180
					when "11"		=> wait_gen <= menos_uno;	-- 270
					when others 	=> wait_gen <= cero_np;		-- 0
				end case;
			elsif ce = '1' then
				case wait_gen is
					when mas_uno 	=>	wait_gen <= cero_pn;
					when cero_pn 	=>	wait_gen <= menos_uno;
					when menos_uno =>	wait_gen <= cero_np;
					when cero_np 	=>	wait_gen <= mas_uno;
				end case;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------
	-- Outpus
	-------------------------------------------------------------------------
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				data_out <= (others => '0');
			elsif ce = '1' then
				case wait_gen is
					when mas_uno 	=> data_out <= data_in;
					when cero_pn 	=>	data_out <= (others => '0');
					when menos_uno 	=>	data_out <= not( data_in ) + '1';
					when cero_np 	=>	data_out <= (others => '0');
				end case;
			end if;
		end if;
	end process;


end Behavioral;

