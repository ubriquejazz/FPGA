------------------------------------------------------------------------
-- Byte Serializer
--
-- 2048 * 8 bits input FIFO.
-- Bytes are read each 8 clocks
--
------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity byte_serializer is
    Port ( 	clk 		: IN std_logic;
			reset_n 	: IN std_logic;
			ce 			: IN std_logic;
			sink_byte 	: IN std_logic_vector(7 downto 0);          
			sink_val 	: IN std_logic;
			sink_rdy 	: OUT std_logic;
			source_bit	: OUT std_logic;	-- MSB first
			source_sop	: OUT std_logic;
			source_eop	: OUT std_logic;			
			source_val 	: OUT std_logic
		);
end byte_serializer;

architecture Behavioral of byte_serializer is

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

	signal aclr 		: std_logic;
	signal rdreq		: std_logic;
	signal rdempty		: std_logic;
	signal wrfull		: std_logic;	
	signal fifo_out		: std_logic_vector (7 downto 0);
	signal bit_cntr		: std_logic_vector (2 downto 0);
	signal rst_bit_cntr	: std_logic;
	signal ce_bit_cntr	: std_logic;	

	type fsm_states_entrada	is (reposo_entrada, lee_byte, envio_bits, espero_ciclo);
	signal wait_gen_entrada : fsm_states_entrada;

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

	rdreq <= '1' when wait_gen_entrada = lee_byte else '0';
	source_bit <= fifo_out(conv_integer(bit_cntr));
	source_val <= '1' when wait_gen_entrada = envio_bits else '0';
	source_sop <= '1' when (wait_gen_entrada = envio_bits) and (bit_cntr = 7) else '0';
	source_eop <= '1' when (wait_gen_entrada = envio_bits) and (bit_cntr = 0) else '0';
	sink_rdy <= not (wrfull);

	-------------------------------------------------------------------------
	-- FSM
	-------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen_entrada <= reposo_entrada;
			elsif ce = '1' then
				case wait_gen_entrada is
				
					when reposo_entrada	=>	if rdempty = '0' then 
												wait_gen_entrada <= lee_byte;
											else
												wait_gen_entrada <= reposo_entrada;
											end if;
														
					when lee_byte	=>	wait_gen_entrada <= envio_bits;
					
					when envio_bits	=> 	if bit_cntr = 0 and rdempty = '1' then
											wait_gen_entrada <= reposo_entrada;
										elsif bit_cntr = 0 and rdempty = '0' then
											wait_gen_entrada <= lee_byte;
										else
											wait_gen_entrada <= espero_ciclo;
										end if;

					when espero_ciclo	=>	wait_gen_entrada <= envio_bits;					

				end case;
			end if;
		end if;
	end process;

	--  counter
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' or rst_bit_cntr = '1' then
				bit_cntr <= (others => '1');
			elsif ce = '1' and ce_bit_cntr = '1' then
				bit_cntr <= bit_cntr - 1;
			end if;
		end if;
	end process;
	
	ce_bit_cntr  <= '1' when wait_gen_entrada = espero_ciclo else '0';
	rst_bit_cntr <= '1' when wait_gen_entrada = lee_byte else '0';	

end Behavioral;
