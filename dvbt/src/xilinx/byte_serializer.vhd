------------------------------------------------------------------------
-- Byte Serializer
-- It reads a new byte at the input every 8 cycles, this is the normal
-- case. But there is a 2048 bytes buffer to load a greater input rates.
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity byte_serializer is
    Port ( 
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		--
		entrada 	: IN std_logic_vector(7 downto 0);          
		new_byte 	: IN std_logic;
		buffer_ovf 	: OUT std_logic;
		--
		salida 		: OUT std_logic;
		data_rdy 	: OUT std_logic
		);
end byte_serializer;

architecture Behavioral of byte_serializer is

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

	-- packets counters, byte/bit counters (in a packet)
	signal cont_bits_byte			: std_logic_vector (2 downto 0);
	signal rst_cont_bits_byte		: std_logic;
	signal ce_cont_bits_byte		: std_logic;

	-- initial fifo 
	signal reset_fifo 	: std_logic;
	signal read_buffer	: std_logic;
	signal buffer_vacio	: std_logic;
--	signal buffer_ovf	: std_logic;	
	signal salida_fifo	: std_logic_vector (7 downto 0);
	
	type fsm_states_entrada	is (reposo_entrada, lee_byte, envio_bits, espero_ciclo);
	signal wait_gen_entrada : fsm_states_entrada;

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

	read_buffer <= '1' when wait_gen_entrada = lee_byte else '0';

	salida <= salida_fifo(conv_integer(cont_bits_byte));
	data_rdy <= '1' when wait_gen_entrada = envio_bits else '0';


	-------------------------------------------------------------------------
	-- Input Buffer FSM
	-------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen_entrada <= reposo_entrada;
			elsif ce = '1' then
				case wait_gen_entrada is
				
				when reposo_entrada	=>	if buffer_vacio = '0' then
											wait_gen_entrada <= lee_byte;
										else
											wait_gen_entrada <= reposo_entrada;
										end if;
														
				when lee_byte		=>	wait_gen_entrada <= envio_bits;
					
				when envio_bits	=> 	if cont_bits_byte = 0 and buffer_vacio = '1' then
										wait_gen_entrada <= reposo_entrada;
									elsif cont_bits_byte = 0 and buffer_vacio = '0' then
										wait_gen_entrada <= lee_byte;
									else
										wait_gen_entrada <= espero_ciclo;
									end if;

				when espero_ciclo	=>	wait_gen_entrada <= envio_bits;				

				end case;
			end if;
		end if;
	end process;

	-- MSB first counter
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or rst_cont_bits_byte = '1' then
				cont_bits_byte <= (others => '1');
			elsif ce = '1' and ce_cont_bits_byte = '1' then
				cont_bits_byte <= cont_bits_byte - 1;
			end if;
		end if;
	end process;

	ce_cont_bits_byte  <= '1' when wait_gen_entrada = espero_ciclo else '0';
	rst_cont_bits_byte <= '1' when wait_gen_entrada = lee_byte else '0';
	
end Behavioral;

