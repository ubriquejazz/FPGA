----------------------------------------------------------------------------
-- Reading Counters (Symbol Interleaver memories)
--
-- 	start = 1 cycle pulse
--
-- 	ready = start + 3 during 8192 cycles
--		indice_j = 0 : 8191
--		indice_k = 0 : 6047
--
-- 	ready = start + 3 during 2048 cycles
--		indice_j = 0 : 2047
--		indice_k = 0 : 1511
--
-- 	1 bit ROM of 2048 / 8192 positions:
--			* tabla_pilotos		_2k		_8k
--			* tabla_tps			_2k		_8k
--			* tabla_cero		_2k		_8k
--
----------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;
	
entity contadores_lectura is
	port (
		clk				: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce				: IN  std_logic;
		start			: IN  std_logic;							
		ready			: OUT std_logic;
		--
		indice_k 		: OUT std_logic_VECTOR(12 downto 0);		
		indice_j 		: OUT std_logic_VECTOR(12 downto 0);
		j_piloto		: OUT std_logic;		
		j_tps			: OUT std_logic;		
		j_cero			: OUT std_logic							
	);
end contadores_lectura;


architecture Behavioral of contadores_lectura is

	-- pilots, zeroes, tps for 2k mode
	COMPONENT tabla_pilotos_2k
	PORT(
			clka		: IN std_logic;
			addra		: IN std_logic_VECTOR(10 downto 0);
			ena			: IN std_logic;
			ssra		: IN std_logic;
			douta		: OUT std_logic_VECTOR(0 downto 0)
		);
	END COMPONENT;
	
	COMPONENT tabla_ceros_2k
	PORT(
			clka		: IN std_logic;
			addra		: IN std_logic_VECTOR(10 downto 0);
			ena			: IN std_logic;
			ssra		: IN std_logic;
			douta		: OUT std_logic_VECTOR(0 downto 0)
		);
	END COMPONENT;

	COMPONENT tabla_tps_2k
	PORT(
			clka		: IN std_logic;
			addra		: IN std_logic_VECTOR(10 downto 0);
			ena			: IN std_logic;
			ssra		: IN std_logic;
			douta		: OUT std_logic_VECTOR(0 downto 0)
		);
	END COMPONENT;
	
	-- pilots, ceros, tps for 8k mode
	COMPONENT tabla_pilotos_8k
	PORT(
			clka		: IN std_logic;
			addra		: IN std_logic_VECTOR(12 downto 0);
			ena			: IN std_logic;
			ssra		: IN std_logic;
			douta		: OUT std_logic_VECTOR(0 downto 0)
		);
	END COMPONENT;
	
	COMPONENT tabla_ceros_8k
	PORT(
			clka		: IN std_logic;
			addra		: IN std_logic_VECTOR(12 downto 0);
			ena			: IN std_logic;
			ssra		: IN std_logic;
			douta		: OUT std_logic_VECTOR(0 downto 0)
		);
	END COMPONENT;

	COMPONENT tabla_tps_8k
	PORT(
			clka		: IN std_logic;
			addra		: IN std_logic_VECTOR(12 downto 0);
			ena			: IN std_logic;
			ssra		: IN std_logic;
			douta		: OUT std_logic_VECTOR(0 downto 0)
		);
	END COMPONENT;

	COMPONENT contador_saturado
	PORT(
			clk 		: IN std_logic;
			reset_n 	: IN std_logic;
			cont_rst_n	: IN std_logic;
			ce 			: IN std_logic;          
			symbol_index 	: OUT std_logic_vector(12 downto 0)
		);
	END COMPONENT;

	signal indice			: std_logic_vector(13 downto 0);
	signal fin_cuenta		: std_logic;
	
	type fsm_states is (reposo, cuenta);
	signal wait_gen : fsm_states;

	signal index_2k		: std_logic_vector(10 downto 0);
	signal index_2k_reg	: std_logic_vector(10 downto 0);
	signal index_8k		: std_logic_vector(12 downto 0);
	signal index_8k_reg	: std_logic_vector(12 downto 0);

	signal piloto			: std_logic;
	signal out_piloto_2k	: std_logic_vector(0 downto 0);
	signal out_piloto_8k	: std_logic_vector(0 downto 0);
	signal cero			: std_logic;
	signal out_cero_2k	: std_logic_vector(0 downto 0);
	signal out_cero_8k	: std_logic_vector(0 downto 0);
	signal tps			: std_logic;
	signal out_tps_2k	: std_logic_vector(0 downto 0);
	signal out_tps_8k	: std_logic_vector(0 downto 0);

	signal ready_aux	: std_logic;
	signal ready_int	: std_logic;
	
	-- contador_saturado
	signal ce_cont_sat	: std_logic;
	signal cont_rst_n	: std_logic;

	signal sclr		: std_logic;
	
begin

	sclr <= not reset_n;

	-------------------------------------------------------------------------
	-- FSM
	-------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen <= reposo;
			elsif ce = '1' then
				case wait_gen is
					when reposo	=>	if start = '1' then 
										wait_gen <= cuenta;
									else
										wait_gen <= reposo;
									end if;
					when cuenta =>	if fin_cuenta = '1' then
										wait_gen <= reposo;
									else
										wait_gen <= cuenta;
									end if;
				end case;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				ready_aux <= '0';
			elsif ce = '1' then
				case wait_gen is
					when reposo		=>	ready_aux <= '0';
					when cuenta		=>	ready_aux <= '1';
				end case;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				ready_int <= '0';
			elsif ce = '1' then
				ready_int <= ready_aux;
			end if;
		end if;
	end process;
	
	ready <= ready_int;
		
	-------------------------------------------------------------------------
	-- General Counter
	-------------------------------------------------------------------------
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or wait_gen = reposo then	--  or start = '1'
				indice <= (others => '0');
			elsif ce = '1' then
				if fin_cuenta = '1' then
					indice <= (others => '0');
				else
					indice <= indice + 1;
				end if;
			end if;
		end if;
	end process;	

	fin_cuenta <= '1' when	( OFDM = 2 and indice  = conv_std_logic_vector(2047, 14) ) or
							( OFDM = 8 and indice  = conv_std_logic_vector(8191, 14) ) else '0';

	----------------------------------------------------------------------------
	-- Reading Counter: indice_j, flags_j
	----------------------------------------------------------------------------
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				index_2k <= (others => '0');
				index_8k <= (others => '0');
			elsif ce = '1' then
				index_8k	<= indice(12 downto 0);
				if OFDM = 2 then
					index_2k	<= indice(10 downto 0);
					index_8k <= (others => '0');
				else
					index_2k <= (others => '0');
					index_8k	<= indice(12 downto 0);
				end if;
			end if;
		end if;
	end process;
	
	indice_j	<= "00" & index_2k_reg when OFDM = 2 else index_8k_reg;

	-- model the delay of tabla_pilotos_2k || tabla_ceros_2k
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				index_2k_reg <= (others => '0');
			elsif ce = '1' then
				index_2k_reg <= index_2k;
			end if;
		end if;
	end process;	
	
	-- model the delay of tabla_pilotos_8k || tabla_ceros_8k
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				index_8k_reg <= (others => '0');
			elsif ce = '1' then
				index_8k_reg <= index_8k;
			end if;
		end if;
	end process;	

	----------------------------------------------------------------------------
	-- Conitunous Pilotos Table
	----------------------------------------------------------------------------
	Inst_pilotos_8k: tabla_pilotos_8k 
	PORT MAP(
		clka 	=> clk,
		ena 	=> ce,
		ssra 	=> sclr,
		addra	=> index_8k,
		douta	=> out_piloto_8k
	);

	Inst_pilotos_2k: tabla_pilotos_2k 
	PORT MAP(
		clka 	=> clk,
		ena 	=> ce,
		ssra 	=> sclr,
		addra	=> index_2k,
		douta	=> out_piloto_2k
	);	
	
	piloto <= out_piloto_2k(0) when OFDM = 2 else out_piloto_8k(0);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				j_piloto	<= '0';
			elsif ce = '1' then
				j_piloto <= piloto and ready_int;
			end if;
		end if;
	end process;	

	----------------------------------------------------------------------------
	-- TPS Carriers Table
	----------------------------------------------------------------------------
	Inst_tps_8k: tabla_tps_8k 
	PORT MAP(
		clka 	=> clk,
		ena 	=> ce,
		ssra 	=> sclr,
		addra	=> index_8k,
		douta	=> out_tps_8k
	);
	
	Inst_tps_2k: tabla_tps_2k 
	PORT MAP(
		clka 	=> clk,
		ena 	=> ce,
		ssra 	=> sclr,
		addra	=> index_2k,
		douta	=> out_tps_2k
	);	
	
	tps <= out_tps_2k(0) when OFDM = 2 else out_tps_8k(0);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				j_tps	<= '0';
			elsif ce = '1' then
				j_tps <= tps and ready_int;
			end if;
		end if;
	end process;	

	----------------------------------------------------------------------------
	-- Zeroes Table
	----------------------------------------------------------------------------
	Inst_ceros_8k: tabla_ceros_8k 
	PORT MAP(
		clka 	=> clk,
		ena 	=> ce,
		ssra 	=> sclr,
		addra	=> index_8k,
		douta	=> out_cero_8k
	);
	
	Inst_ceros_2k: tabla_ceros_2k 
	PORT MAP(
		clka 	=> clk,
		ena 	=> ce,
		ssra 	=> sclr,
		addra	=> index_2k,
		douta	=> out_cero_2k
	);	
	
	cero <= out_cero_2k(0) when OFDM = 2 else out_cero_8k(0);

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				j_cero <= '0';
			elsif ce = '1' then
				j_cero <= cero and ready_int;
			end if;
		end if;
	end process;	

	----------------------------------------------------------------------------
	-- Reading Counter: indice_k
	----------------------------------------------------------------------------
	ce_cont_sat <= not (piloto or cero) and ready_int;	
	
	Inst_contador_saturado: contador_saturado 
	PORT MAP(
		clk	 		 => clk,
		reset_n 		 => reset_n,
		ce 			 => ce_cont_sat,
		cont_rst_n 	 => ready_aux,			--ready_int,					
		symbol_index => indice_k
	);

end Behavioral;
