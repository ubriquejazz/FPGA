----------------------------------------------------------------------------
-- 	start = 1 cycle pulse
--
-- 	indx_val = start + 3 during 8192 cycles
--		indx_ofdm = 0 : 8191
--		indx_1512 = 0 : 6047
--
-- 	indx_val = start + 3 during 2048 cycles
--		indx_ofdm = 0 : 2047
--		indx_1512 = 0 : 1511
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

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
	
entity contadores_lectura is
	port (
		clk				: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce				: IN  std_logic;
		start			: IN  std_logic;							
--		rfs				: OUT std_logic;	
		indx_val		: OUT std_logic;
		indx_sop		: OUT std_logic;
		indx_eop		: OUT std_logic;
		indx_1512 		: OUT std_logic_VECTOR(12 downto 0);		
		indx_ofdm 		: OUT std_logic_VECTOR(12 downto 0);
		indx_flags		: OUT std_logic_VECTOR(2 downto 0)					
	);
end contadores_lectura;


architecture Behavioral of contadores_lectura is

	COMPONENT contador_saturado
	PORT(
			clk 		: IN std_logic;
			reset_n 	: IN std_logic;
			ce 			: IN std_logic;          
			cntr_rst_n	: IN std_logic;
			cntr_value : OUT std_logic_vector(12 downto 0)
		);
	END COMPONENT;

	signal piloto			: std_logic;
	signal out_piloto_2k	: std_logic_vector(0 downto 0);
	signal out_piloto_8k	: std_logic_vector(0 downto 0);
	signal tps				: std_logic;
	signal out_tps_2k		: std_logic_vector(0 downto 0);
	signal out_tps_8k		: std_logic_vector(0 downto 0);
	signal cero				: std_logic;
	signal out_cero_2k		: std_logic_vector(0 downto 0);
	signal out_cero_8k		: std_logic_vector(0 downto 0);
	signal ce_cont_sat		: std_logic;
		
	signal cntr				: std_logic_vector(13 downto 0);
	signal fin_cntr			: std_logic;
	signal index_2k			: std_logic_vector(10 downto 0);
	signal index_2k_reg		: std_logic_vector(10 downto 0);
	signal index_8k			: std_logic_vector(12 downto 0);
	signal index_8k_reg		: std_logic_vector(12 downto 0);

	type fsm_states is (reposo, cuenta);
	signal wait_gen 		: fsm_states;
	signal indx_val_i		: std_logic;
	signal indx_val_d		: std_logic;
	signal indx_val_r		: std_logic;

begin

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
					when cuenta =>	if fin_cntr = '1' then
										wait_gen <= reposo;
									else
										wait_gen <= cuenta;
									end if;
				end case;
			end if;
		end if;
	end process;

	indx_val_i <= '1' when wait_gen = cuenta else '0';	
	indx_val <= indx_val_r;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				indx_val_d <= '0';
				indx_val_r <= '0';
			elsif ce = '1' then
				indx_val_d <= indx_val_i;
				indx_val_r <= indx_val_d;
			end if;
		end if;
	end process;	
		
	-------------------------------------------------------------------------
	-- General Counter
	-------------------------------------------------------------------------
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or wait_gen = reposo then	--  or start = '1'
				cntr <= (others => '0');
			elsif ce = '1' then
				if fin_cntr = '1' then
					cntr <= (others => '0');
				else
					cntr <= cntr + 1;
				end if;
			end if;
		end if;
	end process;	

	fin_cntr <= '1' when	( OFDM = 2 and cntr  = conv_std_logic_vector(2047, 14) ) or
							( OFDM = 8 and cntr  = conv_std_logic_vector(8191, 14) ) else '0';
	
	----------------------------------------------------------------------------
	-- Reading Counter: indx_ofdm, flags_j
	----------------------------------------------------------------------------
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then 
				index_2k <= (others => '0');
				index_8k <= (others => '0');
			elsif ce = '1' then
				index_8k	<= cntr(12 downto 0);
				if OFDM = 2 then
					index_2k <= cntr(10 downto 0);
					index_8k <= (others => '0');
				else
					index_2k <= (others => '0');
					index_8k <= cntr(12 downto 0);
				end if;
			end if;
		end if;
	end process;
	
	indx_ofdm <= "00" & index_2k_reg when OFDM = 2 else index_8k_reg;
	indx_sop <= indx_val_r when (index_2k_reg = conv_std_logic_vector(0, 11)) else '0';
	indx_eop <= indx_val_r when (index_2k_reg = conv_std_logic_vector(2047, 11)) else '0';

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
	
	piloto <= '0'; -- out_piloto_2k(0) when OFDM = 2 else out_piloto_8k(0);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				indx_flags(2) <= '0';
			elsif ce = '1' then
				indx_flags(2) <= piloto and indx_val_r;
			end if;
		end if;
	end process;	

	----------------------------------------------------------------------------
	-- TPS Carriers Table
	----------------------------------------------------------------------------
	
	tps <= '0'; -- out_tps_2k(0) when OFDM = 2 else out_tps_8k(0);
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				indx_flags(1) <= '0';
			elsif ce = '1' then
				indx_flags(1) <= tps and indx_val_r;
			end if;
		end if;
	end process;	

	----------------------------------------------------------------------------
	-- Zeroes Table
	----------------------------------------------------------------------------

	U1 : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "./mif/tabla_ceros_2k.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 2048,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		widthad_a => 11,
		width_a => 1,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => index_2k,
		clock0 => clk,
		clocken0 => ce,
		q_a => out_cero_2k
	);
	
	cero <= out_cero_2k(0) when OFDM = 2 else out_cero_8k(0);

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				indx_flags(0) <= '0';
			elsif ce = '1' then
				indx_flags(0) <= cero and indx_val_r;
			end if;
		end if;
	end process;	

	----------------------------------------------------------------------------
	-- Reading Counter: indx_1512
	----------------------------------------------------------------------------
	
	ce_cont_sat <= not (piloto or cero) and indx_val_r;	
	
	Inst_contador_saturado: contador_saturado 
	PORT MAP(
		clk	 		 => clk,
		reset_n 	 => reset_n,
		ce 			 => ce_cont_sat,
		cntr_rst_n 	 => indx_val_d,			--indx_val_r,					
		cntr_value	 => indx_1512
	);
	
end Behavioral;

-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;

library WORK;
use WORK.mypackage.all;

ENTITY comtadores_lectura_tb_vhd IS
END comtadores_lectura_tb_vhd;

ARCHITECTURE behavior OF comtadores_lectura_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT contadores_lectura
	PORT(
		clk				: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce				: IN  std_logic;
		start			: IN  std_logic;							
--		rfs				: OUT std_logic;	
		indx_val		: OUT std_logic;
		indx_sop		: OUT std_logic;
		indx_eop		: OUT std_logic;
		indx_1512 		: OUT std_logic_VECTOR(12 downto 0);		
		indx_ofdm 		: OUT std_logic_VECTOR(12 downto 0);
		indx_flags		: OUT std_logic_VECTOR(2 downto 0)					
	);	
	END COMPONENT;

	--Inputs
	SIGNAL clk 		:  std_logic := '0';
	SIGNAL reset_n  :  std_logic := '0';
	SIGNAL ce 		:  std_logic := '0';

	--Outputs
	SIGNAL indx_val 	: std_logic;
	SIGNAL indx_sop 	: std_logic;
	SIGNAL indx_eop 	: std_logic;
	SIGNAL indx_1512 	: std_logic_vector(12 downto 0);
	SIGNAL indx_ofdm 	: std_logic_vector(12 downto 0);
	SIGNAL indx_flags	: std_logic_vector(2 downto 0);

	-- Contadores de Lectura
	SIGNAL start0		: std_logic;
	SIGNAL start1		: std_logic;
	SIGNAL start2		: std_logic;
	SIGNAL start3		: std_logic;


BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: contadores_lectura PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		start 		=> start0,
		indx_val	=> indx_val,		-- cnt_ready = start0 + 3
		indx_sop 	=> indx_sop,
		indx_eop 	=> indx_eop,
		indx_1512 	=> indx_1512,
		indx_ofdm 	=> indx_ofdm,
		indx_flags	=> indx_flags
	);	

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				start1 <= '0';
				start2 <= '0';
				start3 <= '0';
			elsif ce = '1' then
				start1 <= start0;
				start2 <= start1;
				start3 <= start2;
			end if;
		end if;
	end process;

	process
	begin
		clk   <= '1';
		wait for CLOCK_PERIOD/2;
		clk   <= '0';
		wait for CLOCK_PERIOD/2;
	end process;
	
	tb : PROCESS
	BEGIN

		start0 	<= '0';
		reset_n <= '0';
		ce	<= '0';
		wait for CLOCK_PERIOD;        	   --wait for GSR
		reset_n <= '1';
		ce <= '1';
		wait for CLOCK_PERIOD;
		start0 <= '1';
		wait for CLOCK_PERIOD;
		start0 <= '0';
		wait; -- will wait forever
	END PROCESS;

END;


-- synthesis translate_on


--	Inst_pilotos_8k: tabla_pilotos_8k 
--	PORT MAP(
--		clka 	=> clk,
--		addra	=> index_8k,
--		douta	=> out_piloto_8k
--	);	
--	Inst_pilotos_2k: tabla_pilotos_2k 
--	PORT MAP(
--		clka 	=> clk,
--		addra	=> index_2k,
--		douta	=> out_piloto_2k
--	);	
--
--	Inst_tps_8k: tabla_tps_8k 
--	PORT MAP(
--		clka 	=> clk,
--		addra	=> index_8k,
--		douta	=> out_tps_8k
--	);	
--	Inst_tps_2k: tabla_tps_2k 
--	PORT MAP(
--		clka 	=> clk,
--		addra	=> index_2k,
--		douta	=> out_tps_2k
--	);	
--
--	Inst_ceros_8k: tabla_ceros_8k 
--	PORT MAP(
--		clka 	=> clk,
--		addra	=> index_8k,
--		douta	=> out_cero_8k
--	);