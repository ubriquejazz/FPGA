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

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity inner_coder is
	 Generic	(	
		FEC 			: natural := 34;
		Irate			: integer := 3;
		Orate			: integer := 4);
    Port ( 
		clk 		: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		sink_byte 	: IN  std_logic_vector(7 downto 0);          
		sink_val 	: IN  std_logic;
		sink_rdy 	: OUT std_logic;
		source_bit	: OUT std_logic;
		source_val 	: OUT std_logic);
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

	COMPONENT puncturing
	GENERIC(
		FEC 		: natural := 34;
		Orate		: integer := 4);
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		sink_x 		: IN std_logic;
		sink_y 		: IN std_logic;
		sink_val	: IN std_logic;
		source_bit	: OUT std_logic;
		source_val 	: OUT std_logic
		);
	END COMPONENT;	
	
	component dcfifo
	generic (
		add_ram_output_register	:	string := "OFF";
		add_usedw_msb_bit		:	string := "OFF";
		clocks_are_synchronized	:	string := "FALSE";
		delay_rdusedw			:	natural := 1;
		delay_wrusedw			:	natural := 1;
		intended_device_family	:	string := "unused";
		lpm_numwords			:	natural;
		lpm_showahead			:	string := "OFF";
		lpm_width				:	natural;
		lpm_widthu				:	natural := 1;
		overflow_checking		:	string := "ON";
		rdsync_delaypipe		:	natural := 0;
		read_aclr_synch			:	string := "OFF";
		underflow_checking		:	string := "ON";
		use_eab					:	string := "ON";
		write_aclr_synch		:	string := "OFF";
		wrsync_delaypipe		:	natural := 0;
		lpm_hint				:	string := "UNUSED";
		lpm_type				:	string := "dcfifo"
	);
	port(
		aclr	:	in std_logic := '0';
		data	:	in std_logic_vector(lpm_width-1 downto 0);
		q		:	out std_logic_vector(lpm_width-1 downto 0);
		rdclk	:	in std_logic;
		rdempty	:	out std_logic;
		rdfull	:	out std_logic;
		rdreq	:	in std_logic;
		rdusedw	:	out std_logic_vector(lpm_widthu-1 downto 0);
		wrclk	:	in std_logic;
		wrempty	:	out std_logic;
		wrfull	:	out std_logic;
		wrreq	:	in std_logic;
		wrusedw	:	out std_logic_vector(lpm_widthu-1 downto 0)
	);
	end component;
	
--	signal rdempty_fifo2	: std_logic;
--	signal fifo2_in			: std_logic_vector (1 downto 0);
--	signal fifo2_out		: std_logic_vector (1 downto 0);
	
	signal reg_conv 		: std_logic_vector(6 downto 0);
	signal x_output 		: std_logic;
	signal y_output 		: std_logic;	
	signal punct_sink_val 	: std_logic;	
	signal punct_source_val	: std_logic;	
	signal punct_source_bit	: std_logic;
	
	signal aclr 			: std_logic;
	signal rdreq			: std_logic;
	signal rdempty			: std_logic;
	signal wrfull			: std_logic;
	signal fifo_out			: std_logic_vector (7 downto 0);
	signal std_bit_cntr		: std_logic_vector (2 downto 0);
	signal sent_bit_cntr	: std_logic_vector (2 downto 0);
	signal rst_std_bit_cntr	: std_logic;
	signal rst_sent_bit_cntr : std_logic;
	signal ce_cntr			: std_logic;
	signal serial_bit		: std_logic;

	type fsm_states 	is (reposo, lee_byte, envio_bits, espero_ciclo, reposo_con_reset, lee_byte_con_reset);
	signal wait_gen 	: fsm_states;

begin

	aclr <= not reset_n;	

	dcfifo_component : dcfifo
	generic map
        (
        add_ram_output_register => "OFF",
        intended_device_family => "Cyclone III",
        lpm_numwords => 2048,
        lpm_type => "dcfifo",
        lpm_width => 8,
        lpm_widthu => 11,
        overflow_checking => "ON",
        underflow_checking => "ON",
        use_eab => "ON"
        )
	port map
        (
        rdclk => clk,
        wrclk => clk,
        aclr => aclr,
        data => sink_byte,
        wrreq => sink_val,
        rdreq => rdreq,
        rdempty => rdempty,
        wrfull => wrfull,
        q => fifo_out
        );

	rdreq <= '1' when wait_gen = lee_byte or wait_gen = lee_byte_con_reset else '0';
	serial_bit <= fifo_out(conv_integer(std_bit_cntr));
	sink_rdy <= not (wrfull);

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
					
					-- RESET si sent_bit_cntr = conv_std_logic_vector(Irate-1, 3)
					when reposo_con_reset	=>	if rdempty = '0' then 
													wait_gen <= lee_byte;
												else
													wait_gen <= reposo_con_reset;
												end if;														
					when lee_byte_con_reset	=>	wait_gen <= envio_bits;					

					-- Funcionamiento normal
					when reposo			=>	if rdempty = '0' then 
												wait_gen <= lee_byte;
											else
												wait_gen <= reposo;
											end if;					
					when lee_byte		=>	wait_gen <= envio_bits;
					when espero_ciclo	=>	wait_gen <= envio_bits;					
					when envio_bits	=>	

					-- ENVIO en funcion de rdempty, std_bit_cntr, sent_bit_cntr 
					if sent_bit_cntr = conv_std_logic_vector(Irate-1, 3) and std_bit_cntr /= 0 then
						wait_gen <= espero_ciclo;
						
					elsif sent_bit_cntr = conv_std_logic_vector(Irate-1, 3) and std_bit_cntr = 0 then
						if rdempty = '1' then
							wait_gen <= reposo_con_reset;
						else
							wait_gen <= lee_byte_con_reset;
						end if;
						
					elsif std_bit_cntr = 0 and rdempty = '1' then
						wait_gen <= reposo;
						
					elsif std_bit_cntr = 0 and rdempty = '0' then
						wait_gen <= lee_byte;
						
					else
						wait_gen <= envio_bits;
					end if;					

				end case;
			end if;
		end if;
	end process;
	
	-------------------------------------------------------------------------
	-- std_bit_cntr, sent_bit_cntr counters
	-------------------------------------------------------------------------

	ce_cntr	<= '1' when wait_gen = envio_bits else '0';
	
	-- MSB First Counter
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or rst_std_bit_cntr = '1' then
				std_bit_cntr <= (others => '1');
			elsif ce = '1' and ce_cntr = '1' then
				std_bit_cntr <= std_bit_cntr - 1;
			end if;
		end if;
	end process;

	rst_std_bit_cntr <= '0' when wait_gen = envio_bits or 
								 wait_gen = espero_ciclo else '1';

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or rst_sent_bit_cntr = '1' then
				sent_bit_cntr <= (others => '0');
			elsif ce = '1' and ce_cntr = '1' then
				sent_bit_cntr <= sent_bit_cntr + 1;
			end if;
		end if;
	end process;

	rst_sent_bit_cntr 	<= '1' when wait_gen = espero_ciclo or
									wait_gen = reposo_con_reset or
									wait_gen = lee_byte_con_reset else '0';

	-------------------------------------------------------------------------
	-- Register of the convolutional coder
	-------------------------------------------------------------------------

	reg_conv(6) <= serial_bit;

	gen_reg_simple: for i in 6 downto 1 generate
		Inst_reg_simple: reg_simple PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> punct_sink_val,
			entrada 	=> reg_conv(i),
			salida 		=> reg_conv(i-1)
		);
	end generate;

	x_output <= ((reg_conv(6) xor reg_conv(5)) xor (reg_conv(4) xor reg_conv(3))) xor reg_conv(0);
	y_output <= ((reg_conv(6) xor reg_conv(4)) xor (reg_conv(3) xor reg_conv(1))) xor reg_conv(0);

	-------------------------------------------------------------------------
	-- Puncturing
	-------------------------------------------------------------------------
	
	punct_sink_val <= '1' when wait_gen = envio_bits else '0';
						
	Inst_puncturing: puncturing 
	GENERIC MAP(
		FEC				=> FEC,
		Orate			=> Orate)
	PORT MAP(
		clk 			=> clk,
		reset_n 		=> reset_n,
		ce 				=> ce,
		sink_x 			=> x_output,
		sink_y 			=> y_output,
		sink_val 		=> punct_sink_val,
		source_bit 		=> punct_source_bit,
		source_val 		=> punct_source_val
	);
		
--	fifo2_in <= "0" & punct_source_bit;		
--	dcfifo_component2 : dcfifo
--      lpm_width => 2,
--      data => fifo2_in,
--      wrreq => punct_source_val,
--      rdreq => source_rdy,
--      q => fifo2_out);

	source_bit <= punct_source_bit; -- fifo2_in(0);
	source_val <= punct_source_val; -- not rdempty_fifo2;
	
end Behavioral;

-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;

library WORK;
use WORK.mypackage.all;

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
		sink_byte 		: IN std_logic_vector(7 downto 0);
		sink_val 		: IN std_logic;          
		sink_rdy 		: OUT std_logic;
--		source_rdy		: IN  std_logic;		
		source_bit		: OUT std_logic;
		source_val 		: OUT std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 			:  std_logic := '0';
	SIGNAL reset_n 		:  std_logic := '0';
	SIGNAL ce 			:  std_logic := '0';
	SIGNAL sink_val 	:  std_logic := '0';
	SIGNAL sink_byte 	:  std_logic_vector(7 downto 0) := (others=>'0');

	--Outputs
	SIGNAL sink_rdy 	:  std_logic;
	SIGNAL source_bit	:  std_logic;
	SIGNAL source_val 	:  std_logic;

	--Testbench
	file	OUT_FILE	: TEXT;
	file	IN_FILE	: TEXT;
	shared variable cycle_cntr	: integer;

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
		sink_byte 	=> sink_byte,
		sink_val 	=> sink_val,
		sink_rdy 	=> sink_rdy,
--		source_rdy	=> '1',
		source_bit	=> source_bit,
		source_val 	=> source_val
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
	rdFile: process(clk)
		variable dato	: line;
		variable valor	: integer;
		variable rd_cntr : integer;			
	begin
		if clk'event and clk = '0' then -- clk = '1'
			if reset_n = '0' then
				cycle_cntr := 0;
				sink_byte <= (others => '0');
				sink_val <= '0';
			elsif ce = '1' and sink_rdy = '1' then
				if cycle_cntr = 8 then
					rd_cntr := rd_cntr + 1;
					if (not endfile(IN_FILE)) then
						readline(IN_FILE, dato);
						read (dato, valor);	
					else
						file_close (IN_FILE);
						file_open(IN_FILE, "../102_outer_int.dat", read_mode);
						readline(IN_FILE, dato);
						read (dato, valor);	
					end if;
					sink_byte <= conv_std_logic_vector(valor, 8);
					sink_val <= '1';
					cycle_cntr := 0;
				else
					sink_val <= '0';
				end if;
				cycle_cntr := cycle_cntr + 1;
			end if;
		end if;
	end process;
		
	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada byte:
	wrFile: process(clk)
		variable wr_cntr: integer;
		variable dato: line;
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wr_cntr := 0;
			elsif ce = '1' then
				if source_val = '1' then
					write(dato, conv_integer(source_bit));
					writeline(OUT_FILE, dato);
					wr_cntr := wr_cntr + 1;
				end if;
			end if;
		end if;
	end process;

	tb : PROCESS
	BEGIN
		file_open(IN_FILE, "../102_outer_int.dat", read_mode);
		file_open(OUT_FILE, "../103_inner_coder.dat", write_mode);
		reset_n <= '0';
		ce <= '0';		
		-- Wait 100 ns for global reset to finish
		wait for 100 ns;
		reset_n <= '1';
		wait for 805 ns;
		ce <= '1';
		wait for 999 us;
		file_close (OUT_FILE);
		file_close (IN_FILE);		
		wait;
	END PROCESS;

END;

-- synthesis translate_on
