LIBRARY ieee;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.all;
USE ieee.std_logic_arith.ALL;
USE std.textio.ALL;

library WORK;
use WORK.mypackage.all;

ENTITY dvbt_core_tb_vhd IS
END dvbt_core_tb_vhd;

ARCHITECTURE behavior OF dvbt_core_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT dvbt_core
	PORT(
		ce 			: IN std_logic;
		reset_n 	: IN std_logic;
		clk 		: IN std_logic;
--		pps_mod		: IN  std_logic;
		spi_data 	: IN std_logic_vector(7 downto 0);
		spi_dvalid 	: IN std_logic;          
		spi_rdy 	: OUT std_logic;
		spi_sop		: IN  std_logic;
		spi_eop		: IN  std_logic;
--		status 		: OUT std_logic_vector(3 downto 0);
		xn_rdy		: IN  std_logic;
		xn_val		: OUT std_logic;
		xn_sop		: OUT std_logic;
		xn_eop		: OUT std_logic;
		xn_index	: OUT std_logic_vector(12 downto 0);
		xn_re		: OUT std_logic_vector(15 downto 0);
		xn_im	 	: OUT std_logic_vector(15 downto 0)	
		);
	END COMPONENT;

	COMPONENT filter_64M 
	PORT (
		clk				: IN STD_LOGIC;
		reset_n			: IN STD_LOGIC;
		ast_sink_data	: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		ast_sink_valid	: IN STD_LOGIC;
		ast_source_ready: IN STD_LOGIC;
		ast_sink_error	: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
		ast_source_data	: OUT STD_LOGIC_VECTOR (32 DOWNTO 0);
		ast_sink_ready	: OUT STD_LOGIC;
		ast_source_valid: OUT STD_LOGIC;
		ast_source_error: OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
	);
	END COMPONENT;	
	
	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL spi_dvalid 	:  std_logic := '0';
	SIGNAL spi_sop		:  std_logic := '0';
	SIGNAL spi_eop	 	:  std_logic := '0';
	SIGNAL spi_data 	:  std_logic_vector(7 downto 0) := (others=>'0');
	SIGNAL xn_rdy	 	:  std_logic := '0';
	--Outputs
	SIGNAL spi_rdy 		:  std_logic;	
	SIGNAL xn_sop		:  std_logic;
	SIGNAL xn_eop		:  std_logic;
	SIGNAL xn_val 		:  std_logic;
	SIGNAL xn_index		:  std_logic_vector(12 downto 0);
	SIGNAL xn_re 		:  std_logic_vector(15 downto 0);
	SIGNAL xn_im 		:  std_logic_vector(15 downto 0);

	--Testbench	
	SIGNAL xk_sop		:  std_logic;
	SIGNAL xk_eop		:  std_logic;
	SIGNAL xk_val 		:  std_logic;
	SIGNAL xk_re 		:  std_logic_vector(32 downto 0);
--	SIGNAL xk_im 		:  std_logic_vector(32 downto 0);
	SIGNAL grabar		: std_logic;
	SIGNAL symbol_cntr	: std_logic_vector(2 downto 0);

	file IN_FILE, OUT_FILE	: TEXT;

	shared variable cycles_cntr	: integer	:= 0;
		
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: dvbt_core PORT MAP(
		ce 			=> ce,
		reset_n 	=> reset_n,
		clk 		=> clk,
		spi_data 	=> spi_data,
		spi_dvalid 	=> spi_dvalid,
		spi_rdy 	=> spi_rdy,
		spi_sop		=> spi_sop,
		spi_eop		=> spi_eop,
--		status 		=> open,
		xn_rdy 		=> xn_rdy,
		xn_val		=> xn_val, 
		xn_sop	 	=> xn_sop,
		xn_eop		=> xn_eop,
		xn_index	=> xn_index,
		xn_re 		=> xn_re,
		xn_im 		=> xn_im
	);
	
	filter_64M_ast_inst : filter_64M
	PORT MAP (
		clk  				=>  clk,
		reset_n  			=>  reset_n,
		ast_sink_data  		=>  xn_re,
		ast_sink_valid  	=>  xn_val,
		ast_sink_ready  	=>  xn_rdy,		
		ast_sink_error		=>  (others => '0'),
		ast_source_ready  	=>  '1',
		ast_source_data  	=>  xk_re,
		ast_source_valid  	=>  xk_val,
		ast_source_error 	=>  open
	);
	
	process
	begin
		clk   <= '1';
		wait for CLOCK_PERIOD/2;
		clk   <= '0';
		wait for CLOCK_PERIOD/2;
	end process;
	
	-- Procesos para introducción de datos por la entrada:	
	-- Utilizamos flanco descendente para que esta introducción hecha en el testbench no penalice un ciclo.
	rdCntr: process(clk)
		variable cuenta_tandas	: integer := 0;
		variable valor_inicial	: integer := 0;
	begin
		if clk'event and clk = '0' then -- clk = '1'
			if reset_n = '0' then
				cycles_cntr := 0;
				cuenta_tandas := 0;				
			elsif ce = '1' and spi_rdy = '1' then 
				if cycles_cntr = 0 then
					if cuenta_tandas = 6	then				
						cuenta_tandas := 0;
						valor_inicial := 20 - 1;
					else
						cuenta_tandas := cuenta_tandas + 1;
						valor_inicial := 18 - 1;
					end if;
					cycles_cntr := valor_inicial;
				else
					cycles_cntr := cycles_cntr - 1;
				end if;

			end if;
		end if;
	end process;
	
	rdFile: process(clk)
		variable dato	 : line;
		variable valor	 : integer;
		variable rd_cntr : integer;	
	begin
		if clk'event and clk = '0' then -- clk = '1'
			if reset_n = '0' then
				rd_cntr := 0;				
				spi_data <= (others => '0');
				spi_dvalid <= '0'; 
				spi_sop <= '0'; 
				spi_eop <= '0';
			elsif ce = '1' and spi_rdy = '1' then 
				
				if cycles_cntr = 1 then				  
					rd_cntr := rd_cntr + 1;
					if rd_cntr = 1 then
						spi_sop <= '1';
						spi_eop <= '0';
					elsif rd_cntr = NUM_BYTES_TS then
						rd_cntr := 0;
						spi_sop <= '0';
						spi_eop <= '1';
					else
						spi_eop <= '0';
						spi_sop <= '0';
					end if;				  
				  
					if (not endfile(IN_FILE)) then
						readline(IN_FILE, dato);
						read (dato, valor);	
					else
						file_close (IN_FILE);
						file_open(IN_FILE, "../00_entrada_8ts.dat", read_mode);
						readline(IN_FILE, dato);
						read (dato, valor);	
					end if;
--					byte_entrada := conv_std_logic_vector(valor, 9);
					spi_data <= conv_std_logic_vector(valor, 8);
					spi_dvalid <= '1';
				else
					spi_dvalid <= '0';
				end if;
			end if;
		end if;
	end process;
	
	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	wrFile: process(clk)
		variable dato: line;
		variable espacio_blanco : string (1 to 3);
		variable wr_cntr : integer;		
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				espacio_blanco(1) := ' ';
				espacio_blanco(2) := ' ';
				espacio_blanco(3) := ' ';
				wr_cntr := 0;
			elsif ce = '1' then
--				if xn_val_4 = '1' then
				if xn_index > 0 then 
					write(dato, conv_integer(xn_re));
					write(dato, espacio_blanco);
					write(dato, conv_integer(xn_im));
					writeline(OUT_FILE, dato);
					wr_cntr := wr_cntr + 1;
				end if;
			end if;
		end if;
	end process;	
	
	tb : PROCESS
	BEGIN
		file_open(IN_FILE, "..\00_entrada_8ts.dat", read_mode);
		file_open(OUT_FILE, "..\02_time_64qam.dat", write_mode);
		grabar <= '0';
		reset_n <= '0';
		ce <= '0';
		-- Wait 100 ns for global reset to finish
		wait for 110 ns;
		reset_n <= '1';
		ce <= '1';
		------------------------------------------------------	
		symbol_cntr <= "000";
		wait until xn_sop'event and xn_sop = '1';
		------------------------------------------------------		
		symbol_cntr <= "001";
		grabar <= '1';
--		wait until xn_index = conv_std_logic_vector(NUM_MUESTRAS_F0-1, 13);
		wait until xn_sop'event and xn_sop = '1';
		grabar <= '0';		
		------------------------------------------------------
--		symbol_cntr <= "010";
--		wait until xn_sop'event and xn_sop = '1';
--		
--		for symbol_cntr in 1 to 272 - 1 loop
--			wait until xn_sop'event and xn_sop = '1';
--			
--		end loop;
		file_close (IN_FILE);
		file_close (OUT_FILE);
		ASSERT (FALSE) REPORT
			"Escritura correcta. Simulation successful (not a failure).  No problems detected."
		SEVERITY FAILURE;
		
		wait; -- will wait forever

	END PROCESS;

END;
