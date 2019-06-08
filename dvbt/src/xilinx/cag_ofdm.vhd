-------------------------------------------------------------------
-- Automatic Control Gain (CAG) for OFDM signals
--
--		Pp = (1 V)^2 / 1 Ohm = 1 W
--		Pp = 30 dBm
--		
--		RPM = Pp - Pm = 13 dB
--		Pm = 17 dBm	
--		Pm = 0.05W (1 Ohm)
-------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity cag_ofdm is
    Port ( clk     				: in  STD_LOGIC;
           reset_n 				: in  STD_LOGIC;
           ce      				: in  STD_LOGIC;
           din     				: in  STD_LOGIC_VECTOR (17 downto 0);
           cont_overflows_DAC	: out STD_LOGIC_VECTOR (13 downto 0);
           ganancia_cag			: out STD_LOGIC_VECTOR (17 downto 0);
           dout    				: out STD_LOGIC_VECTOR (17 downto 0);
           ganancia_inestable	: out STD_LOGIC);
end cag_ofdm;

architecture Behavioral of cag_ofdm is
	
	constant GANANCIA_INICIAL_CAG 	: std_logic_vector(17 downto 0) := "000001000000000000";
	constant K1 			: std_logic_vector(17 downto 0) := conv_std_logic_vector(65602, 18); -- K1 = 1,001
	constant K2 		 	: std_logic_vector(17 downto 0) := conv_std_logic_vector(65470, 18); -- K2 = 0,999

	-- Power Average
	constant PROMEDIO		: std_logic_vector(10 downto 0) := "11111111111";		--> 2048 - 1
	constant PROMEDIO_BIN	: std_logic_vector(4 downto 0)	:= conv_std_logic_vector(11,5);	--> 11 = log2(2048)
--	constant PROMEDIO		: std_logic_vector(10 downto 0) := "00000000111";		--> 8 - 1
--	constant PROMEDIO_BIN	: std_logic_vector(4 downto 0)	:= conv_std_logic_vector(3,5);	--> 3 = log2(8)

	-- Gain Update 
	constant DIEZMADO 			: std_logic_vector(23 downto 0) := conv_std_logic_vector(3804, 24);	-- (15192, 24);	
	constant DIEZMADO_RESET		: std_logic_vector(23 downto 0) := conv_std_logic_vector(3808, 24);	-- (15196, 24); 
--	constant LIMITE_POSITIVO	: std_logic_vector(9 downto 0)  := conv_std_logic_vector	(64, 10);
--	constant LIMITE_NEGATIVO	: std_logic_vector(9 downto 0)  := conv_std_logic_vector	(-64, 10);
	constant LIMITE_POSITIVO	: std_logic_vector(9 downto 0)  := conv_std_logic_vector	(16, 10);
	constant LIMITE_NEGATIVO	: std_logic_vector(9 downto 0)  := conv_std_logic_vector	(-16, 10);
--	constant LIMITE_POSITIVO	: std_logic_vector(9 downto 0)  := conv_std_logic_vector	(2, 10);
--	constant LIMITE_NEGATIVO	: std_logic_vector(9 downto 0)  := conv_std_logic_vector	(-2, 10);

	COMPONENT acumulador
	PORT(
		clk     : IN  std_logic;
		reset_n : IN  std_logic;
		ce      : IN  std_logic;
		A       : IN  std_logic_vector(17 downto 0);
		B       : IN  std_logic_vector(17 downto 0);    
		PCOUT   : OUT std_logic_vector(47 downto 0)
		);
	END COMPONENT;
	
	COMPONENT filtro_LP_cag_pot_media
	PORT(
		clk 		: IN 	std_logic;
		reset_n 	: IN 	std_logic;
		ce 			: IN 	std_logic;
		entrada 	: IN 	std_logic_vector(17 downto 0);          
		salida 		: OUT std_logic_vector(17 downto 0)
		);
	END COMPONENT;

	COMPONENT mult_suma
	PORT(
		clk     : IN  std_logic;
		reset_n : IN  std_logic;
		ce      : IN  std_logic;
		A       : IN  std_logic_vector(17 downto 0);
		B       : IN  std_logic_vector(17 downto 0);
		PCIN    : IN  std_logic_vector(47 downto 0);          
		PCOUT   : OUT std_logic_vector(47 downto 0)
		);
	END COMPONENT;

	COMPONENT mult_add
	PORT(
		clk     : IN  std_logic;
		reset_n : IN  std_logic;
		ce      : IN  std_logic;
		A       : IN  std_logic_vector(17 downto 0);
		B       : IN  std_logic_vector(17 downto 0);
		PCIN    : IN  std_logic_vector(47 downto 0);          
		PCOUT   : OUT std_logic_vector(47 downto 0)
		);
	END COMPONENT;

	signal pulsos_reg				: std_logic_vector(2 downto 0);
	signal cuenta_pot_media			: std_logic_vector(10 downto 0);
	signal reset_promediador		: std_logic;
	signal salida_promediador		: std_logic_vector(47 downto 0);		
	signal potencia_media			: std_logic_vector(47 downto 0);		
	signal potencia_media_18		: std_logic_vector(17 downto 0);	
	signal potencia_filtrada		: std_logic_vector(17 downto 0);	
	signal potencia_filtrada_reg	: std_logic_vector(17 downto 0);	
	signal dout_aux_18				: std_logic_vector(17 downto 0);	
	signal potencia_inst			: std_logic_vector(35 downto 0);	
	signal potencia_media_red		: std_logic_vector(35 downto 0);	
	signal cuenta_exitos       		: std_logic_vector(9 downto 0);
	signal reset_cuenta_exitos		: std_logic;
	signal constante	  			: std_logic_vector(17 downto 0);	
	signal ce_multiplicador			: std_logic;
	signal ce_multiplicador_reg		: std_logic;
	signal ganancia	  				: std_logic_vector(17 downto 0);
	signal ganancia_36_pre			: std_logic_vector(47 downto 0);	
	signal ganancia_36				: std_logic_vector(35 downto 0);	
	signal ganancia_36_red			: std_logic_vector(35 downto 0);	
	signal oe_contador				: std_logic;
	signal contador					: std_logic_vector(23 downto 0);	
	signal reset_contador			: std_logic;	
	signal dout_aux         	   	: std_logic_vector(35 downto 0); 
	signal cont_overflows 			: std_logic_vector(13 downto 0);
	signal contador_estabilidad		: std_logic_vector(7 downto 0);
	signal reset_contador_estabilidad_n	: std_logic;
	signal cuenta_2seg				: std_logic_vector(28 downto 0);

begin

	-------------------------------------------------------------------------------------------------------
	-- Pulse every PROMEDIO cycles. This pulse is registered to enable many circuits inside the AGC
	-------------------------------------------------------------------------------------------------------
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				cuenta_pot_media 	<= (others => '0');
			elsif ce = '1' then
				cuenta_pot_media 	<= cuenta_pot_media + 1;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				pulsos_reg(0) 	<= '0';
			elsif ce = '1' then
				if cuenta_pot_media = PROMEDIO then
					pulsos_reg(0) 	<= '1';
				else
					pulsos_reg(0) 	<= '0';
				end if;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				pulsos_reg(1) 	<= '0';
			elsif ce = '1' then
				pulsos_reg(1) 	<= pulsos_reg(0);
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				pulsos_reg(2) 	<= '0';
			elsif ce = '1' then
				pulsos_reg(2) 	<= pulsos_reg(1);
			end if;
		end if;
	end process;	
	
	-------------------------------------------------------------------------------------------------------
	-- Multiplier and accumaltor through a DSP48 block. LPF @ 56e6/PROMEDIO:
	-------------------------------------------------------------------------------------------------------
	reset_promediador <= reset_n and (not pulsos_reg(1));

--	Inst_acumulador: acumulador PORT MAP(
--		clk     => clk,
--		reset_n => reset_promediador,
--		ce      => ce,
--		A       => dout_aux_18,
--		B       => dout_aux_18,
--		PCOUT   => salida_promediador
--	);	
	
	Inst_mult_add: mult_add PORT MAP(
		clk     => clk,
		reset_n => reset_promediador,
		ce      => ce,
		A       => dout_aux_18,
		B       => dout_aux_18,
		PCIN    => salida_promediador,
		PCOUT   => salida_promediador
	);
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				potencia_media 	<= (others => '0');
			elsif ce = '1' and pulsos_reg(0) = '1' then
				potencia_media 	<= shr(salida_promediador, PROMEDIO_BIN);
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				potencia_media_red 	<= (others => '0');
			elsif ce = '1' and pulsos_reg(1) = '1' then
				potencia_media_red	<= potencia_media(35 downto 0) + "000000000000000000001111111111111111" + not potencia_media(35);
			end if;
		end if;
	end process;
	
	potencia_media_18 <= potencia_media_red(34 downto 17);

	Inst_filtro_LP_cag_pot_media: filtro_LP_cag_pot_media PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> pulsos_reg(2),
		entrada 	=> potencia_media_18,
		salida 	=> potencia_filtrada
	);
	
	-------------------------------------------------------------------------------------------------------
	-- More things: multiplier + counter
	-------------------------------------------------------------------------------------------------------	-------------------------------------------------------------------------------------------------------
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' or reset_cuenta_exitos = '1' then
				cuenta_exitos	<= (others => '0');
			elsif ce = '1' and oe_contador = '1' then
				if potencia_filtrada < POT_REF then
					cuenta_exitos <= cuenta_exitos + 1;
				elsif potencia_filtrada > POT_REF then
					cuenta_exitos <= cuenta_exitos - 1;
				end if;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				ce_multiplicador <= '0';
				reset_cuenta_exitos <= '0';
			elsif ce = '1' then
				if cuenta_exitos = LIMITE_POSITIVO then
					ce_multiplicador <= '1';
					constante <= K1;
					reset_cuenta_exitos <= '1';
				elsif cuenta_exitos = LIMITE_NEGATIVO then
					ce_multiplicador <= '1';
					constante <= K2;
					reset_cuenta_exitos <= '1';
				else 
					ce_multiplicador <= '0';
					reset_cuenta_exitos <= '0';
				end if;
			end if;
		end if;
	end process;

	process (clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then   
				ganancia_36 <= "000000010000000000000000000000000000";
			elsif ce_multiplicador = '1' then
				ganancia_36 <= ganancia * constante;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				ganancia_36_red	<= "000000010000000000000000000000000000";
			elsif ce = '1' then
				ganancia_36_red	<= ganancia_36 + "000000000000000000000111111111111111" + not ganancia_36(35);
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				ganancia	<= GANANCIA_INICIAL_CAG;
			elsif ce = '1' then
				ganancia	<= ganancia_36_red(33 downto 16);
			end if;
		end if;
	end process;
	
	----------------------------------------------------------------------
	-- Decimation counter: oe_contador
	----------------------------------------------------------------------
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' or reset_contador = '1' then
				contador 	<= (others => '0');
			elsif ce = '1' then
				contador 	<= contador + 1;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				oe_contador <= '0';
			elsif ce = '1' then
				if contador = DIEZMADO then
					oe_contador <= '1';
				else
					oe_contador <= '0';
				end if;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				reset_contador <= '0';
			elsif ce = '1' then
				if contador = DIEZMADO_RESET then
					reset_contador <= '1';
				else
					reset_contador <= '0';
				end if;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------------------------------------
	-- Output computation: output_sample = gain * input_sample
	-------------------------------------------------------------------------------------------------------
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				dout_aux 	<= (others => '0');
			elsif ce = '1' then
				dout_aux 	<= ganancia * din;
			end if;
		end if;
	end process;
				
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				dout_aux_18 <= (others => '0');
				cont_overflows <= (others => '0');
			elsif ce = '1' then
				if (dout_aux(29) = '0' and dout_aux(30) = '1') then
					cont_overflows <= cont_overflows + 1;
					dout_aux_18 	<= "100000000000000000";
				elsif (dout_aux(29) = '1' and dout_aux(30) = '0') then
					cont_overflows	<= cont_overflows + 1;
					dout_aux_18 	<= "011111111111111111";
				else
					dout_aux_18 <= dout_aux (29 downto 12);
				end if;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------------------------------------
	-- Outputs
	-------------------------------------------------------------------------------------------------------
	ganancia_cag 			<= ganancia;
	cont_overflows_DAC	<= cont_overflows;
	dout 						<= dout_aux_18;
	
	-------------------------------------------------------------------------------------------------------
	-- Stability Control
	-------------------------------------------------------------------------------------------------------
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' or reset_contador_estabilidad_n = '0' then
				cuenta_2seg <= (others => '0');
			elsif ce = '1' then
				cuenta_2seg <= cuenta_2seg + 1;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				reset_contador_estabilidad_n <= '1';
			elsif ce = '1' then
				if cuenta_2seg = conv_std_logic_vector(112000000, 29) then
					reset_contador_estabilidad_n <= '0';
				else
					reset_contador_estabilidad_n <= '1';
				end if;
			end if;
		end if;
	end process;
		
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' or reset_contador_estabilidad_n = '0' then
				contador_estabilidad <= (others => '0');
			elsif ce_multiplicador = '1' then
				if cuenta_exitos = LIMITE_POSITIVO then
					contador_estabilidad <= contador_estabilidad + 1;
				elsif cuenta_exitos = LIMITE_NEGATIVO then
					contador_estabilidad <= contador_estabilidad - 1;
				end if;
			end if;
		end if;
	end process;
		
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				ce_multiplicador_reg <= '0';
			elsif ce = '1' then
				ce_multiplicador_reg <= ce_multiplicador;
			end if;
		end if;
	end process;
		
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				ganancia_inestable <= '0';
			elsif ce_multiplicador_reg = '1' then
				if contador_estabilidad = conv_std_logic_vector	(100, 8) or contador_estabilidad = conv_std_logic_vector	(-100, 8) then
					ganancia_inestable <= '1';
				else 
					ganancia_inestable <= '0';
				end if;
			end if;
		end if;
	end process;
	

end Behavioral;

