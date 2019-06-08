----------------------------------------------------------------------------------
-- OUTER ENCODER (rs_encoder v3.1)
--
-- The start signal is active at the sync byte (i.e. start of every 188 bytes packets)
-- At the last byte the rs_encoder generates 204 - 188 = 16 bytes instead of only one.
-- This difference at the output rate is solved with a 32 bytes buffer at the input. 
-- The rdy_for_data signal is used to extract the information from this buffer.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity outer_coder is
    Port ( clk 		: in  STD_LOGIC;
           reset_n 	: in  STD_LOGIC;
           ce 		: in  STD_LOGIC;
           data_in 	: in  STD_LOGIC_VECTOR (7 downto 0);
           new_data : in  STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (7 downto 0);
           data_rdy : out STD_LOGIC);
end outer_coder;

architecture Behavioral of outer_coder is

	component rs_encoder
		port
		(
			data_in		: IN  std_logic_VECTOR(7 downto 0);
			start		: IN  std_logic;
			bypass		: IN  std_logic;
			nd			: IN  std_logic;
			data_out	: OUT std_logic_VECTOR(7 downto 0);
			info		: OUT std_logic;
			rdy			: OUT std_logic;
			rfd			: OUT std_logic;
			ce			: IN  std_logic;
			reset		: IN  std_logic;
			clk			: IN  std_logic
		);
	end component;

	component buffer_interno
		port
		(
			clk			: IN  std_logic;
			din			: IN  std_logic_VECTOR(7 downto 0);
			rd_en		: IN  std_logic;
			srst		: IN  std_logic;
			wr_en		: IN  std_logic;
			dout		: OUT std_logic_VECTOR(7 downto 0);
			empty		: OUT std_logic;
			full		: OUT std_logic
		);
	end component;

	-- bit parallelizer
	signal byte_aux			: std_logic_vector(7 downto 0);
	signal byte_rdy			: std_logic;

	-- fifo
	signal reset_fifo		: std_logic;
	signal buffer_vacio		: std_logic;
	signal buffer_lleno		: std_logic;
	signal read_buffer		: std_logic;

	-- counter
	signal cuenta_bytes		: std_logic_vector(7 downto 0);
	signal rst_cuenta_bytes	: std_logic;
	signal primer_byte		: std_logic;
	signal rdy_for_data		: std_logic;

	-- rs encoder
	signal rs_encoder_in	: std_logic_vector(7 downto 0);
	signal rs_encoder_nd	: std_logic;
	signal rs_encoder_start	: std_logic;
	signal rs_encoder_reset	: std_logic;

begin

	byte_aux <= data_in;
	byte_rdy <= new_data;
	
	-------------------------------------------------------------------------
	-- Input FIFO:
	-------------------------------------------------------------------------
	reset_fifo <= not reset_n;
	
	Inst_buffer_interno: buffer_interno PORT MAP(
		clk			=> clk,
		din			=> byte_aux,
		rd_en		=> read_buffer,
		srst		=> reset_fifo,
		wr_en		=> byte_rdy,
		dout		=> rs_encoder_in,
		empty		=> buffer_vacio,
		full		=> buffer_lleno
	);
	
	read_buffer <= (not buffer_vacio) and rdy_for_data;

	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				rs_encoder_nd <= '0';
			elsif ce = '1' then
				rs_encoder_nd <= read_buffer;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------
	-- 188 bytes per block
	-------------------------------------------------------------------------
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' or rst_cuenta_bytes = '1' then   
				cuenta_bytes <= (others => '0');
			elsif ce = '1' and read_buffer = '1' then
				cuenta_bytes <= cuenta_bytes + 1;
			end if;
		end if;
	end process;
	
	rst_cuenta_bytes <= '1' when cuenta_bytes = conv_std_logic_vector(NUM_BYTES_TS, 8) else '0';
	
	primer_byte <= '1' when cuenta_bytes = "00000000" else '0';
	
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				rs_encoder_start <= '0';
			elsif ce = '1' then
				rs_encoder_start <= primer_byte and read_buffer;
			end if;
		end if;
	end process;
			
	-------------------------------------------------------------------------
	-- Reed Solomon Encoder (v3.0)
	-------------------------------------------------------------------------
	rs_encoder_reset <= not reset_n;
	
	Inst_rs_encoder: rs_encoder PORT MAP(
		data_in		=> rs_encoder_in,
		start		=> rs_encoder_start,
		bypass		=> '0',
		nd			=> rs_encoder_nd,
		data_out	=> data_out,
		info		=> open,
		rdy			=> data_rdy,
		rfd			=> rdy_for_data,
		ce			=> ce,
		reset		=> rs_encoder_reset,
		clk			=> clk
	);

end Behavioral;

-- synthesis translate_off

ENTITY outer_coder_tb_vhd IS
END outer_coder_tb_vhd;

ARCHITECTURE behavior OF outer_coder_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT outer_coder
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		data_in 	: IN std_logic_vector(7 downto 0);
		new_data 	: IN std_logic;          
		data_out 	: OUT std_logic_vector(7 downto 0);
		data_rdy 	: OUT std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL new_data 	:  std_logic := '0';
	SIGNAL data_in 		:  std_logic_vector(7 downto 0) := (others=>'0');

	--Outputs
	SIGNAL data_out 	:  std_logic_vector(7 downto 0);
	SIGNAL data_rdy 	:  std_logic;

	--Testbench
	file	datos_salida	: TEXT;
	file	datos_entrada	: TEXT;
	signal file_end			: std_logic;
	signal inicio 			: std_logic;

	shared variable contador : integer 	:= 0;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: outer_coder PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		data_in 	=> data_in,
		new_data 	=> new_data,
		data_out 	=> data_out,
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
		variable dato				: line;
		variable valor				: integer;
		variable cuenta_ciclos	: integer;
	begin
		if clk'event and clk = '0' then
			if reset_n = '0' then
				file_open(datos_entrada, "../01_salida_mux_adapter.dat", read_mode);
				data_in	<= (others => '0');
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
						--file_open(datos_entrada, "../01_salida_mux_adapter.dat", read_mode);
						--readline(datos_entrada, dato);
						--read (dato, valor);	
						valor := 0;
					end if;		
					
					data_in  <= conv_std_logic_vector(valor, 8);
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
				file_open(datos_salida, "101_rs_coder.dat", write_mode);
			elsif ce = '1' then
				if data_rdy = '1'then -- and file_end = '0' then
					write(dato, conv_integer(data_out));
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
		wait for 15*CLOCK_PERIOD;

		file_close (datos_entrada);
		file_close (datos_salida);

		wait; -- will wait forever
	END PROCESS;

END;

-- synthesis translate_on