-------------------------------------------------------------------------------------------
-- OUTER INTERLEAVER
--
-- Convolutional byte-wise interleaving with depth I = 12.
-- Simulacion temporal en el proyecto "01_Forney_Interleaver"
-- Todas las ramas se han implementado en una unica memoria de 2048 bytes:
--
-------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity outer_interleaver is
    Port ( clk		 		: in  STD_LOGIC;
           reset_n 			: in  STD_LOGIC;
           ce 				: in  STD_LOGIC;
           new_data 		: in  STD_LOGIC;
           entrada 			: in  STD_LOGIC_VECTOR (7 downto 0);
           salida 			: out STD_LOGIC_VECTOR (7 downto 0);
           data_rdy 		: out STD_LOGIC);
end outer_interleaver;


architecture Behavioral of outer_interleaver is

	constant M 	: integer := 17;
	constant N 	: integer := 204;

	component outer_memo
		port
		(	addra	: IN  std_logic_VECTOR(10 downto 0);
			addrb	: IN  std_logic_VECTOR(10 downto 0);
			wea		: IN  std_logic_VECTOR(0 downto 0);
			clka	: IN  std_logic;
			clkb	: IN  std_logic;
			dina	: IN  std_logic_VECTOR(7 downto 0);
			doutb	: OUT std_logic_VECTOR(7 downto 0)
		);
	end component;
	
	type fsm_states 	is (rama0, rama1, rama2, rama3, rama4, rama5, rama6, rama7, rama8, rama9, rama10, rama11);
	signal wait_gen : fsm_states;
	
	signal ce_rama_0			: std_logic;
	signal ce_rama_1			: std_logic;
	signal ce_rama_2			: std_logic;
	signal ce_rama_3			: std_logic;
	signal ce_rama_4			: std_logic;
	signal ce_rama_5			: std_logic;
	signal ce_rama_6			: std_logic;
	signal ce_rama_7			: std_logic;
	signal ce_rama_8			: std_logic;
	signal ce_rama_9			: std_logic;
	signal ce_rama_10			: std_logic;
	signal ce_rama_11			: std_logic;
	
	signal dir_escritura_r1		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r2		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r3		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r4		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r5		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r6		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r7		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r8		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r9		: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r10	: std_logic_VECTOR(10 downto 0);
	signal dir_escritura_r11	: std_logic_VECTOR(10 downto 0);
	
	signal dir_lectura_r1	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r2	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r3	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r4	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r5	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r6	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r7	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r8	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r9	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r10	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura_r11	: std_logic_VECTOR(10 downto 0);
	
	signal reset_dir_escritura_r1_n		: std_logic;
	signal reset_dir_escritura_r2_n		: std_logic;
	signal reset_dir_escritura_r3_n		: std_logic;
	signal reset_dir_escritura_r4_n		: std_logic;
	signal reset_dir_escritura_r5_n		: std_logic;
	signal reset_dir_escritura_r6_n		: std_logic;
	signal reset_dir_escritura_r7_n		: std_logic;
	signal reset_dir_escritura_r8_n		: std_logic;
	signal reset_dir_escritura_r9_n		: std_logic;
	signal reset_dir_escritura_r10_n	: std_logic;
	signal reset_dir_escritura_r11_n	: std_logic;	
	signal reset_dir_lectura_r1_n		: std_logic;
	signal reset_dir_lectura_r2_n		: std_logic;
	signal reset_dir_lectura_r3_n		: std_logic;
	signal reset_dir_lectura_r4_n		: std_logic;
	signal reset_dir_lectura_r5_n		: std_logic;
	signal reset_dir_lectura_r6_n		: std_logic;
	signal reset_dir_lectura_r7_n		: std_logic;
	signal reset_dir_lectura_r8_n		: std_logic;
	signal reset_dir_lectura_r9_n		: std_logic;
	signal reset_dir_lectura_r10_n		: std_logic;
	signal reset_dir_lectura_r11_n		: std_logic;
	
	signal dir_escritura	: std_logic_VECTOR(10 downto 0);
	signal dir_lectura	: std_logic_VECTOR(10 downto 0);
	signal din				: std_logic_VECTOR(7 downto 0);
	signal dout				: std_logic_VECTOR(7 downto 0);
	signal wea				: std_logic_VECTOR(0 downto 0);
	
	signal entrada_reg	: std_logic_vector(7 downto 0);
	signal new_data_reg	: std_logic;
	signal ce_rama_0_reg	: std_logic;

begin

	-- registramos de nuevo la entrada para poder sincronizar la salida
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				entrada_reg <= (others => '0');
			elsif ce = '1' then
				entrada_reg	<= entrada;
			end if;
		end if;
	end process;
	
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

	-- la salida es estable 2 ciclos despues de tener los datos a la entrada
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				data_rdy <= '0';
			elsif ce = '1' then
				data_rdy	<= new_data_reg;
			end if;
		end if;
	end process;
	
	---------------------------------------------------------------------------------
	-- INSTANCIAMOS LA MEMORIA:
	---------------------------------------------------------------------------------
	Inst_outer_memo : outer_memo
		port map
		(
			addra	=> dir_escritura,
			addrb	=> dir_lectura,
			clka	=> clk,
			clkb	=> clk,
			dina	=> entrada,
			doutb	=> dout,
			wea	=> wea
		);
	
	wea(0) <= '0' when wait_gen = rama0 or new_data = '0' else '1';

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				salida <= (others => '0');
			elsif ce = '1' and new_data_reg = '1' then
				case ce_rama_0_reg is
					when '1'		=>	salida <= entrada_reg;
					when others	=> salida <= dout;
				end case;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------------------
	-- MÁQUINA DE ESTADOS:
	---------------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen <= rama0;
			elsif ce = '1' and new_data = '1' then
				case wait_gen is
					when rama0	=>	wait_gen <= rama1;
					when rama1	=>	wait_gen <= rama2;
					when rama2	=>	wait_gen <= rama3;
					when rama3	=>	wait_gen <= rama4;
					when rama4	=>	wait_gen <= rama5;
					when rama5	=>	wait_gen <= rama6;
					when rama6	=>	wait_gen <= rama7;
					when rama7	=>	wait_gen <= rama8;
					when rama8	=>	wait_gen <= rama9;
					when rama9	=>	wait_gen <= rama10;
					when rama10	=>	wait_gen <= rama11;
					when rama11	=>	wait_gen <= rama0;
				end case;
			end if;
		end if;
	end process;
	
	ce_rama_0 	<= '1' when wait_gen = rama0 else '0';
	ce_rama_1 	<= '1' when wait_gen = rama1 else '0';
	ce_rama_2 	<= '1' when wait_gen = rama2 else '0';
	ce_rama_3 	<= '1' when wait_gen = rama3 else '0';
	ce_rama_4 	<= '1' when wait_gen = rama4 else '0';
	ce_rama_5 	<= '1' when wait_gen = rama5 else '0';
	ce_rama_6 	<= '1' when wait_gen = rama6 else '0';
	ce_rama_7 	<= '1' when wait_gen = rama7 else '0';
	ce_rama_8 	<= '1' when wait_gen = rama8 else '0';
	ce_rama_9 	<= '1' when wait_gen = rama9 else '0';
	ce_rama_10 	<= '1' when wait_gen = rama10 else '0';
	ce_rama_11 	<= '1' when wait_gen = rama11 else '0';
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				ce_rama_0_reg <= '0';
			elsif ce = '1' then
				ce_rama_0_reg <= ce_rama_0;
			end if;
		end if;
	end process;
	
	with wait_gen select
		dir_escritura <= 	dir_escritura_r1 when rama1,
								dir_escritura_r2 when rama2,
								dir_escritura_r3 when rama3,
								dir_escritura_r4 when rama4,
								dir_escritura_r5 when rama5,
								dir_escritura_r6 when rama6,
								dir_escritura_r7 when rama7,
								dir_escritura_r8 when rama8,
								dir_escritura_r9 when rama9,
								dir_escritura_r10 when rama10,
								dir_escritura_r11 when rama11,
								dir_escritura_r1 when others;
	
	with wait_gen select
		dir_lectura <= 	dir_lectura_r1 when rama1,
								dir_lectura_r2 when rama2,
								dir_lectura_r3 when rama3,
								dir_lectura_r4 when rama4,
								dir_lectura_r5 when rama5,
								dir_lectura_r6 when rama6,
								dir_lectura_r7 when rama7,
								dir_lectura_r8 when rama8,
								dir_lectura_r9 when rama9,
								dir_lectura_r10 when rama10,
								dir_lectura_r11 when rama11,
								dir_lectura_r11 when others;	
	
	---------------------------------------------------------------------------------
	-- MANEJO DE LAS DIRECCIONES DE LECTURA Y ESCRITURA:
	---------------------------------------------------------------------------------

	-- Direcciones para la rama 1:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r1 	<= conv_std_logic_vector(0, 11);
				dir_lectura_r1 	<= conv_std_logic_vector(M, 11);
			elsif reset_dir_escritura_r1_n = '0' then
				dir_escritura_r1 	<= conv_std_logic_vector(0, 11);
			elsif reset_dir_lectura_r1_n = '0' then
				dir_lectura_r1 	<= conv_std_logic_vector(0, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_1 = '1' then
				dir_escritura_r1 	<= dir_escritura_r1 + 1;
				dir_lectura_r1 	<= dir_lectura_r1 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r1_n 	<= '0' when dir_escritura_r1 	= conv_std_logic_vector(2*M, 11) else '1';
	reset_dir_lectura_r1_n 		<= '0' when dir_lectura_r1 	= conv_std_logic_vector(2*M, 11) else '1';
	
	-- Direcciones para la rama 2:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r2 	<= conv_std_logic_vector(2*M, 11);
				dir_lectura_r2 	<= conv_std_logic_vector((2*M)+M, 11);
			elsif reset_dir_escritura_r2_n = '0' then
				dir_escritura_r2 	<= conv_std_logic_vector(2*M, 11);
			elsif reset_dir_lectura_r2_n = '0' then
				dir_lectura_r2 	<= conv_std_logic_vector(2*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_2 = '1' then
				dir_escritura_r2 	<= dir_escritura_r2 + 1;
				dir_lectura_r2 	<= dir_lectura_r2 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r2_n 	<= '0' when dir_escritura_r2 	= conv_std_logic_vector(5*M, 11) else '1';
	reset_dir_lectura_r2_n 		<= '0' when dir_lectura_r2 	= conv_std_logic_vector(5*M, 11) else '1';
	
	-- Direcciones para la rama 3:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r3 	<= conv_std_logic_vector(5*M, 11);
				dir_lectura_r3 	<= conv_std_logic_vector((5*M)+M, 11);
			elsif reset_dir_escritura_r3_n = '0' then
				dir_escritura_r3 	<= conv_std_logic_vector(5*M, 11);
			elsif reset_dir_lectura_r3_n = '0' then
				dir_lectura_r3 	<= conv_std_logic_vector(5*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_3 = '1' then
				dir_escritura_r3 	<= dir_escritura_r3 + 1;
				dir_lectura_r3 	<= dir_lectura_r3 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r3_n 	<= '0' when dir_escritura_r3 	= conv_std_logic_vector(9*M, 11) else '1';
	reset_dir_lectura_r3_n 		<= '0' when dir_lectura_r3 	= conv_std_logic_vector(9*M, 11) else '1';
	
	-- Direcciones para la rama 4:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r4 	<= conv_std_logic_vector(9*M, 11);
				dir_lectura_r4 	<= conv_std_logic_vector((9*M)+M, 11);
			elsif reset_dir_escritura_r4_n = '0' then
				dir_escritura_r4 	<= conv_std_logic_vector(9*M, 11);
			elsif reset_dir_lectura_r4_n = '0' then
				dir_lectura_r4 	<= conv_std_logic_vector(9*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_4 = '1' then
				dir_escritura_r4 	<= dir_escritura_r4 + 1;
				dir_lectura_r4 	<= dir_lectura_r4 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r4_n 	<= '0' when dir_escritura_r4 	= conv_std_logic_vector(14*M, 11) else '1';
	reset_dir_lectura_r4_n 		<= '0' when dir_lectura_r4 	= conv_std_logic_vector(14*M, 11) else '1';
	
	-- Direcciones para la rama 5:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r5 	<= conv_std_logic_vector(14*M, 11);
				dir_lectura_r5 	<= conv_std_logic_vector((14*M)+M, 11);
			elsif reset_dir_escritura_r5_n = '0' then
				dir_escritura_r5 	<= conv_std_logic_vector(14*M, 11);
			elsif reset_dir_lectura_r5_n = '0' then
				dir_lectura_r5 	<= conv_std_logic_vector(14*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_5 = '1' then
				dir_escritura_r5 	<= dir_escritura_r5 + 1;
				dir_lectura_r5 	<= dir_lectura_r5 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r5_n 	<= '0' when dir_escritura_r5 	= conv_std_logic_vector(20*M, 11) else '1';
	reset_dir_lectura_r5_n 		<= '0' when dir_lectura_r5 	= conv_std_logic_vector(20*M, 11) else '1';
	
	-- Direcciones para la rama 6:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r6 	<= conv_std_logic_vector(20*M, 11);
				dir_lectura_r6 	<= conv_std_logic_vector((20*M)+M, 11);
			elsif reset_dir_escritura_r6_n = '0' then
				dir_escritura_r6 	<= conv_std_logic_vector(20*M, 11);
			elsif reset_dir_lectura_r6_n = '0' then
				dir_lectura_r6 	<= conv_std_logic_vector(20*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_6 = '1' then
				dir_escritura_r6 	<= dir_escritura_r6 + 1;
				dir_lectura_r6 	<= dir_lectura_r6 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r6_n 	<= '0' when dir_escritura_r6 	= conv_std_logic_vector(27*M, 11) else '1';
	reset_dir_lectura_r6_n 		<= '0' when dir_lectura_r6 	= conv_std_logic_vector(27*M, 11) else '1';
	
	-- Direcciones para la rama 7:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r7 	<= conv_std_logic_vector(27*M, 11);
				dir_lectura_r7 	<= conv_std_logic_vector((27*M)+M, 11);
			elsif reset_dir_escritura_r7_n = '0' then
				dir_escritura_r7 	<= conv_std_logic_vector(27*M, 11);
			elsif reset_dir_lectura_r7_n = '0' then
				dir_lectura_r7 	<= conv_std_logic_vector(27*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_7 = '1' then
				dir_escritura_r7 	<= dir_escritura_r7 + 1;
				dir_lectura_r7 	<= dir_lectura_r7 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r7_n 	<= '0' when dir_escritura_r7 	= conv_std_logic_vector(35*M, 11) else '1';
	reset_dir_lectura_r7_n 		<= '0' when dir_lectura_r7 	= conv_std_logic_vector(35*M, 11) else '1';
	
	-- Direcciones para la rama 8:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r8 	<= conv_std_logic_vector(35*M, 11);
				dir_lectura_r8 	<= conv_std_logic_vector((35*M)+M, 11);
			elsif reset_dir_escritura_r8_n = '0' then
				dir_escritura_r8 	<= conv_std_logic_vector(35*M, 11);
			elsif reset_dir_lectura_r8_n = '0' then
				dir_lectura_r8 	<= conv_std_logic_vector(35*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_8 = '1' then
				dir_escritura_r8 	<= dir_escritura_r8 + 1;
				dir_lectura_r8 	<= dir_lectura_r8 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r8_n 	<= '0' when dir_escritura_r8 	= conv_std_logic_vector(44*M, 11) else '1';
	reset_dir_lectura_r8_n 		<= '0' when dir_lectura_r8 	= conv_std_logic_vector(44*M, 11) else '1';
	
	-- Direcciones para la rama 9:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r9 	<= conv_std_logic_vector(44*M, 11);
				dir_lectura_r9 	<= conv_std_logic_vector((44*M)+M, 11);
			elsif reset_dir_escritura_r9_n = '0' then
				dir_escritura_r9 	<= conv_std_logic_vector(44*M, 11);
			elsif reset_dir_lectura_r9_n = '0' then
				dir_lectura_r9 	<= conv_std_logic_vector(44*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_9 = '1' then
				dir_escritura_r9 	<= dir_escritura_r9 + 1;
				dir_lectura_r9 	<= dir_lectura_r9 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r9_n 	<= '0' when dir_escritura_r9 	= conv_std_logic_vector(54*M, 11) else '1';
	reset_dir_lectura_r9_n 		<= '0' when dir_lectura_r9 	= conv_std_logic_vector(54*M, 11) else '1';
	
	-- Direcciones para la rama 10:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r10	<= conv_std_logic_vector(54*M, 11);
				dir_lectura_r10 	<= conv_std_logic_vector((54*M)+M, 11);
			elsif reset_dir_escritura_r10_n = '0' then
				dir_escritura_r10 <= conv_std_logic_vector(54*M, 11);
			elsif reset_dir_lectura_r10_n = '0' then
				dir_lectura_r10 	<= conv_std_logic_vector(54*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_10 = '1' then
				dir_escritura_r10	<= dir_escritura_r10 + 1;
				dir_lectura_r10 	<= dir_lectura_r10 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r10_n 	<= '0' when dir_escritura_r10	= conv_std_logic_vector(65*M, 11) else '1';
	reset_dir_lectura_r10_n 	<= '0' when dir_lectura_r10 	= conv_std_logic_vector(65*M, 11) else '1';
	
	-- Direcciones para la rama 11:
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then
				dir_escritura_r11	<= conv_std_logic_vector(65*M, 11);
				dir_lectura_r11 	<= conv_std_logic_vector((65*M)+M, 11);
			elsif reset_dir_escritura_r11_n = '0' then
				dir_escritura_r11 <= conv_std_logic_vector(65*M, 11);
			elsif reset_dir_lectura_r11_n = '0' then
				dir_lectura_r11 	<= conv_std_logic_vector(65*M, 11);
			elsif ce = '1' and new_data = '1' and ce_rama_11 = '1' then
				dir_escritura_r11	<= dir_escritura_r11 + 1;
				dir_lectura_r11 	<= dir_lectura_r11 + 1;
			end if;
		end if;
	end process;
	
	reset_dir_escritura_r11_n 	<= '0' when dir_escritura_r11	= conv_std_logic_vector(77*M, 11) else '1';
	reset_dir_lectura_r11_n 	<= '0' when dir_lectura_r11 	= conv_std_logic_vector(77*M, 11) else '1';
	
end Behavioral;

-- synthesis translate off

ENTITY outer_interleaver_tb_vhd IS
END outer_interleaver_tb_vhd;

ARCHITECTURE behavior OF outer_interleaver_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT outer_interleaver
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		new_data 	: IN std_logic;
		entrada 	: IN std_logic_vector(7 downto 0);          
		salida 		: OUT std_logic_vector(7 downto 0);
		data_rdy 	: OUT std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL new_data 	:  std_logic := '0';
	SIGNAL entrada 		:  std_logic_vector(7 downto 0) := (others=>'0');

	--Outputs
	SIGNAL salida		:  std_logic_vector(7 downto 0);
	SIGNAL data_rdy 	:  std_logic;

	--Testbench
	file	datos_salida	: TEXT;
	file	datos_entrada	: TEXT;
	signal file_end			: std_logic;
	signal inicio 			: std_logic;

	shared variable contador : integer 	:= 0;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: outer_interleaver PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		new_data => new_data,
		entrada 	=> entrada,
		salida 	=> salida,
		data_rdy => data_rdy
	);

	process
	begin
		clk   <= '1';
		wait for CLOCK_PERIOD/2;
		clk   <= '0';
		wait for CLOCK_PERIOD/2;
	end process;
	
	-- Proceso para introducción de datos por la entrada:	
	-- Utilizamos flanco descendente para que esta introducción hecha en el testbench no penalice un ciclo.
	process(clk)
		variable dato				: line;
		variable valor				: integer;
		variable cuenta_ciclos	: integer;
	begin
		if clk'event and clk = '0' then
			if reset_n = '0' then
				file_open(datos_entrada, "101_rs_coder.dat", read_mode);
				entrada	<= (others => '0');
				new_data <= '0';
				contador := 0;
				cuenta_ciclos	:= 0;
				file_end <= '0';
				
			elsif ce = '1' and inicio = '1' then
			
				-- Mandamos un byte cada 8 ciclos de reloj:
				if cuenta_ciclos = 7 then
					if (not endfile(datos_entrada)) then
						readline(datos_entrada, dato);
						read (dato, valor);	
					else
						file_end <= '1';
						--file_close (datos_entrada);
						--file_open(datos_entrada, "101_rs_coder.dat", read_mode);
						--readline(datos_entrada, dato);
						--read (dato, valor);	
						valor := 0;
					end if;		
					
					entrada  <= conv_std_logic_vector(valor, 8);
					new_data <= '1';
					contador := contador + 1;
					cuenta_ciclos := 0;
				else
					new_data <= '0';
					cuenta_ciclos := cuenta_ciclos + 1;
				end if;				
			end if;
		end if;
	end process;
	
	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	process(clk)
		variable dato : line;
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				file_open(datos_salida, "102_outer_int.dat", write_mode);
			elsif ce = '1' then
				if data_rdy = '1'then -- and file_end = '0' then
					write(dato, conv_integer(salida));
					writeline(datos_salida, dato);
				end if;
			end if;
		end if;
	end process;
		
	tb : PROCESS
	BEGIN
		inicio <= '0';
		reset_n <= '0';
		ce <= '0';

		-- Wait 100 ns for global reset to finish
		wait for 110 ns;
		reset_n <= '1';
		ce <= '1';

		wait for 595 ns;
		inicio <= '1';
		
		wait until file_end = '1';
		file_close (datos_entrada);
		file_close (datos_salida);

		wait; -- will wait forever
	END PROCESS;

END;

-- synthesis translate on
