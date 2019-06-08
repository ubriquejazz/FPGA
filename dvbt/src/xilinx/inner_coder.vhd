-------------------------------------------------------------------------------------
-- INNER CODER (Parameter Implementation)
--
-- In the case of loading the input at a rate greater than a byte per 8 cycles,
-- data would be loss. To avoid this, a 2048 bytes buffer is at input to load the 
-- input data. So I read this buffer a byte per every 8 cycles.
--
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity inner_coder is
	 Generic	(	
		FEC 			: natural := 34;
		Irate			: integer := 3;
		Orate			: integer := 4);
    Port ( 
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		--
		entrada 	: IN std_logic_vector(7 downto 0);          
		new_byte 	: IN std_logic;
		buffer_ovf 	: OUT std_logic;
		--
		salida		: OUT std_logic;
		data_rdy 	: OUT std_logic);
end inner_coder;


architecture Behavioral of inner_coder is

	COMPONENT reg_simple	
	PORT(
		clk 		: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		entrada 	: IN  std_logic;          
		salida 		: OUT std_logic
		);
	END COMPONENT;

	COMPONENT buffer_inicial
	PORT(
		clk			: IN  std_logic;
		din			: IN  std_logic_VECTOR(7 downto 0);
		rd_en		: IN  std_logic;
		srst		: IN  std_logic;
		wr_en		: IN  std_logic;
		dout		: OUT std_logic_VECTOR(7 downto 0);
		empty		: OUT std_logic;
		full		: OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT puncturing
	GENERIC(
		FEC 			: natural := 34;
		Orate			: integer := 4);
	PORT(
		clk 			: IN std_logic;
		reset_n 		: IN std_logic;
		ce 				: IN std_logic;
		x 				: IN std_logic;
		y 				: IN std_logic;
		new_data 		: IN std_logic;
		salida 			: OUT std_logic;
		data_rdy 		: OUT std_logic
		);
	END COMPONENT;	
	
	-- input buffer 
	signal reset_fifo 	: std_logic;
	signal read_buffer	: std_logic;
	signal salida_fifo	: std_logic_vector (7 downto 0);
	signal buffer_vacio	: std_logic;
	
	-- input fsm 
	type fsm_states 	is (reposo, lee_byte, envio_bits, espero_ciclo, reposo_con_reset, lee_byte_con_reset);
	signal wait_gen 	: fsm_states;

	-- fsm counters
	signal cont_bits_byte			: std_logic_vector (2 downto 0);
	signal cont_bits_enviados		: std_logic_vector (2 downto 0);
	signal rst_cont_bits_byte		: std_logic;
	signal rst_cont_bits_enviados	: std_logic;
	signal ce_contadores			: std_logic;
	signal bit_de_entrada			: std_logic;

	-- convolutional coder registers
	signal reg_conv 		: std_logic_vector(6 downto 0);
	signal x_output 		: std_logic;
	signal y_output 		: std_logic;	
	signal new_data 		: std_logic;	

begin

	-------------------------------------------------------------------------
	-- Input Buffer
	-------------------------------------------------------------------------
	reset_fifo <= not reset_n;
	
	Inst_buffer_inicial: buffer_inicial PORT MAP(
		clk			=> clk,
		din			=> entrada,
		rd_en		=> read_buffer,
		srst		=> reset_fifo,
		wr_en		=> new_byte,
		dout		=> salida_fifo,
		empty		=> buffer_vacio,
		full		=> buffer_ovf
	);

	read_buffer 	<= '1' when wait_gen = lee_byte or 
								wait_gen = lee_byte_con_reset else '0';
										
	bit_de_entrada <= salida_fifo(conv_integer(cont_bits_byte));

	-------------------------------------------------------------------------
	-- FSM to get data from the input buffer
	-------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen <= reposo;
			elsif ce = '1' then
				case wait_gen is
					
					-- RESET si cont_bits_enviados = conv_std_logic_vector(Irate-1, 3)
					when reposo_con_reset	=>	if buffer_vacio = '0' then 
													wait_gen <= lee_byte;
												else
													wait_gen <= reposo_con_reset;
												end if;														
					when lee_byte_con_reset	=>	wait_gen <= envio_bits;					

					-- Funcionamiento normal
					when reposo			=>	if buffer_vacio = '0' then 
												wait_gen <= lee_byte;
											else
												wait_gen <= reposo;
											end if;					
					when lee_byte		=>	wait_gen <= envio_bits;
					when espero_ciclo	=>	wait_gen <= envio_bits;					
					when envio_bits	=>	

					-- ENVIO en funcion de buffer_vacio, cont_bits_byte, cont_bits_enviados 
					if cont_bits_enviados = conv_std_logic_vector(Irate-1, 3) and cont_bits_byte /= 0 then
						wait_gen <= espero_ciclo;
						
					elsif cont_bits_enviados = conv_std_logic_vector(Irate-1, 3) and cont_bits_byte = 0 then
						if buffer_vacio = '1' then
							wait_gen <= reposo_con_reset;
						else
							wait_gen <= lee_byte_con_reset;
						end if;
						
					elsif cont_bits_byte = 0 and buffer_vacio = '1' then
						wait_gen <= reposo;
						
					elsif cont_bits_byte = 0 and buffer_vacio = '0' then
						wait_gen <= lee_byte;
						
					else
						wait_gen <= envio_bits;
					end if;					

				end case;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------
	-- cont_bits_byte, cont_bits_enviados counters
	-------------------------------------------------------------------------

	ce_contadores	<= '1' when wait_gen = envio_bits else '0';
	
	-- MSB First Counter
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or rst_cont_bits_byte = '1' then
				cont_bits_byte <= (others => '1');
			elsif ce = '1' and ce_contadores = '1' then
				cont_bits_byte <= cont_bits_byte - 1;
			end if;
		end if;
	end process;

	rst_cont_bits_byte <= '0' when wait_gen = envio_bits or 
											 wait_gen = espero_ciclo else '1';

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or rst_cont_bits_enviados = '1' then
				cont_bits_enviados <= (others => '0');
			elsif ce = '1' and ce_contadores = '1' then
				cont_bits_enviados <= cont_bits_enviados + 1;
			end if;
		end if;
	end process;

	rst_cont_bits_enviados 	<= '1' when wait_gen = espero_ciclo or
													wait_gen = reposo_con_reset or
													wait_gen = lee_byte_con_reset else '0';

	-------------------------------------------------------------------------
	-- Register of the convolutional coder
	-------------------------------------------------------------------------

	reg_conv(6) <= bit_de_entrada;

	gen_reg_simple: for i in 6 downto 1 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 		=> new_data,
			entrada 	=> reg_conv(i),
			salida 	=> reg_conv(i-1)
		);
	end generate;

	x_output <= ((reg_conv(6) xor reg_conv(5)) xor (reg_conv(4) xor reg_conv(3))) xor reg_conv(0);
	y_output <= ((reg_conv(6) xor reg_conv(4)) xor (reg_conv(3) xor reg_conv(1))) xor reg_conv(0);

	-------------------------------------------------------------------------
	-- Puncturing
	-------------------------------------------------------------------------
	
	new_data <= '1' when wait_gen = envio_bits else '0';
						
	Inst_puncturing: puncturing 
	GENERIC MAP(
		FEC				=> FEC,
		Orate			=> Orate)
	PORT MAP(
		clk 			=> clk,
		reset_n 		=> reset_n,
		ce 				=> ce,
		x 				=> x_output,
		y 				=> y_output,
		new_data 		=> new_data,
		salida 			=> salida,
		data_rdy 		=> data_rdy
	);
	
end Behavioral;

-- synthesis translate off

ENTITY inner_coder_tb_vhd IS
END inner_coder_tb_vhd;

ARCHITECTURE behavior OF inner_coder_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT inner_coder
	 Generic	(	
		FEC 			: natural := 34;
		Irate			: integer := 3;
		Orate			: integer := 4);
	PORT(
		clk 			: IN std_logic;
		reset_n 		: IN std_logic;
		ce 				: IN std_logic;
		entrada 		: IN std_logic_vector(7 downto 0);
		new_byte 		: IN std_logic;          
		buffer_ovf 		: OUT std_logic;
		salida			: OUT std_logic;
		data_rdy 		: OUT std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL new_byte 	:  std_logic := '0';
	SIGNAL entrada 	:  std_logic_vector(7 downto 0) := (others=>'0');

	--Outputs
	SIGNAL buffer_ovf 	:  std_logic;
	SIGNAL salida		:  std_logic;
	SIGNAL data_rdy 	:  std_logic;

	--Testbench
	file	datos_salida	: TEXT;
	file	datos_entrada	: TEXT;
	shared variable cuenta_ciclos	: integer;

	signal file_end		: std_logic;
	signal inicio 		: std_logic;
	signal i 			: integer 	:= 0;
	signal j 			: integer 	:= 0;
	
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: inner_coder 
	GENERIC MAP(
		FEC			=> 34,
		Irate		=> 3,
		Orate		=> 4)	
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		entrada 	=> entrada,
		new_byte 	=> new_byte,
		buffer_ovf 	=> buffer_ovf,
		salida		=> salida,
		data_rdy 	=> data_rdy
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
		variable dato			: line;
		variable valor			: integer;
		variable byte_entrada	: std_logic_vector(8 downto 0);
	begin
		if clk'event and clk = '0' then
			if reset_n = '0' then
				cuenta_ciclos := 0;
				entrada <= (others => '0');
				new_byte <= '0';
			elsif ce = '1' and inicio = '1' then
				if cuenta_ciclos = 8 then
					if (not endfile(datos_entrada)) then
						readline(datos_entrada, dato);
						read (dato, valor);	
					else
						file_close (datos_entrada);
						file_open(datos_entrada, "102_outer_int.dat", read_mode);
						readline(datos_entrada, dato);
						read (dato, valor);	
					end if;
					byte_entrada := conv_std_logic_vector(valor, 9);
					entrada <= byte_entrada(7 downto 0);
					new_byte <= '1';
					cuenta_ciclos := 0;
				else
					new_byte <= '0';
				end if;
				cuenta_ciclos := cuenta_ciclos + 1;
			end if;
		end if;
	end process;
	
	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	process(clk)
		variable cuenta_bits	: integer;
		variable dato			: line;
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				cuenta_bits 	:= 7;
			elsif ce = '1' then
				if data_rdy = '1' then
					write(dato, conv_integer(salida));
					writeline(datos_salida, dato);
				end if;
			end if;
		end if;
	end process;

	tb : PROCESS
	BEGIN
		file_open(datos_entrada, "102_outer_int.dat", read_mode);
		file_open(datos_salida, "103_inner_coder.dat", write_mode);

		reset_n <= '0';
		ce <= '0';		
		inicio <= '0';	

		-- Wait 100 ns for global reset to finish
		wait for 100 ns;
		reset_n <= '1';
		wait for 805 ns;
		inicio <= '1';
		ce <= '1';

		wait for 999 us;
		file_close (datos_salida);
		file_close (datos_entrada);
		
		wait;
	END PROCESS;

END;

-- synthesis translate on
