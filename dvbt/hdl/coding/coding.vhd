----------------------------------------------------------------
-- channel coding
--
--	mux_adapter
-- 	outer_coder
-- 	outer_interleaver
-- 	inner_coder(FEC : natural := 34);
--
----------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity coding is
	Generic	(	
		FEC 		: natural := 34;
		Irate		: integer := 3;
		Orate		: integer := 4);
    Port (	
		clk			: in  STD_LOGIC;
		reset_n 	: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;
		sink_rdy 	: out STD_LOGIC;
		sink_byte 	: in  STD_LOGIC_VECTOR(7 downto 0);
		sink_val	: in  STD_LOGIC;
		sink_sop	: in  STD_LOGIC;
		sink_eop	: in  STD_LOGIC;
--		source_rdy	: in  STD_LOGIC;
		source_bit 	: out STD_LOGIC; 
		source_val	: out STD_LOGIC;
		source_sop	: out STD_LOGIC;
		source_eop 	: out STD_LOGIC
	 );
end coding;


architecture Behavioral of coding is

	COMPONENT byte_serializer
	PORT(	clk 		: IN std_logic;
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
	END COMPONENT;

	COMPONENT bit_parallelizer
	PORT(	clk 		: in  STD_LOGIC;	
			reset_n 	: in  STD_LOGIC;
			ce 			: in  STD_LOGIC;
			sink_bit 	: in  STD_LOGIC;
			sink_val	: in  STD_LOGIC;
			source_byte	: out STD_LOGIC_VECTOR(7 downto 0);
			source_val	: out STD_LOGIC
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
	
 	COMPONENT rs_encoder
	PORT (
		clk			: IN  STD_LOGIC;
		reset		: IN  STD_LOGIC;
		rsin		: IN  STD_LOGIC_VECTOR (8 DOWNTO 1);
		sink_val	: IN  STD_LOGIC;
		sink_sop	: IN  STD_LOGIC;
		sink_eop	: IN  STD_LOGIC;
		sink_ena	: OUT STD_LOGIC;
		source_ena	: IN  STD_LOGIC;
		rsout		: OUT STD_LOGIC_VECTOR (8 DOWNTO 1);
		source_val	: OUT STD_LOGIC;
		source_sop	: OUT STD_LOGIC;
		source_eop	: OUT STD_LOGIC
	);		
	END COMPONENT;

	COMPONENT mux_adapter
	PORT(	
		clk			: in  STD_LOGIC;
		reset_n	 	: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;
		sink_bit 	: in  STD_LOGIC;	--_vector(7 downto 0); 	
		sink_val	: in  STD_LOGIC;
--		sink_rdy	: out STD_LOGIC;
--		source_rdy	: in  STD_LOGIC;
		source_bit	: out STD_LOGIC;	--_vector(7 downto 0); 	
		source_val	: out STD_LOGIC;
		source_sop	: out STD_LOGIC;
		source_eop	: out STD_LOGIC
		);
	END COMPONENT;

	COMPONENT outer_interleaver
	PORT(
		clk 		: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		sink_rdy 	: OUT std_logic;
		sink_byte 	: IN  std_logic_vector(7 downto 0);          
		sink_val 	: IN  std_logic;
		source_byte	: OUT std_logic_vector(7 downto 0);
		source_rdy 	: IN  std_logic;
		source_val 	: OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT inner_coder
	GENERIC(
		FEC 		: natural := 34;
		Irate		: integer := 3;
		Orate		: integer := 4);
	PORT(
		clk 		: in std_logic;
		reset_n 	: in std_logic;
		ce 			: in std_logic;
		sink_byte 	: in std_logic_vector(7 downto 0);          
		sink_val 	: in std_logic;
		sink_rdy 	: out std_logic; 
--		sink_sop	: in  std_logic; 
--		sink_eop	: in  std_logic;		
		source_bit	: out std_logic;
		source_val	: out std_logic
--		source_sop	: out std_logic;
--		source_eop	: out std_logic				
		);
	END COMPONENT;

	-- mux adapter
	signal mux_adapter_sink_bit		: std_logic;
	signal mux_adapter_sink_val 	: std_logic;
	signal mux_adapter_source_bit	: std_logic;
	signal mux_adapter_source_val	: std_logic;	
	signal mux_adapter_source_sop	: std_logic;
	signal mux_adapter_source_eop	: std_logic;
	-- fifo 
	signal aclr 					: std_logic;
	signal wrreq					: std_logic;
	signal fifo_in					: std_logic_vector(7 downto 0);
	signal rdempty					: std_logic;
	-- outer coder
	signal outer_coder_sink_byte	: std_logic_vector(7 downto 0);
	signal outer_coder_sink_rdy		: std_logic;
	signal outer_coder_sink_val		: std_logic;
	signal outer_coder_sink_sop		: std_logic;
	signal outer_coder_sink_eop		: std_logic;	
	signal outer_coder_source_byte	: std_logic_vector(7 downto 0);
	signal outer_coder_source_rdy	: std_logic;
	signal outer_coder_source_val	: std_logic;
	signal outer_coder_source_sop	: std_logic;
	signal outer_coder_source_eop	: std_logic;
	-- outer inter	
	signal outer_inter_sink_byte	: std_logic_vector(7 downto 0);
	signal outer_inter_sink_rdy		: std_logic;
	signal outer_inter_sink_val		: std_logic;
	signal outer_inter_source_byte	: std_logic_vector(7 downto 0);
	signal outer_inter_source_rdy	: std_logic;
	signal outer_inter_source_val	: std_logic;
	-- inner coder
	signal inner_coder_sink_byte	: std_logic_vector(7 downto 0);
	signal inner_coder_sink_val		: std_logic;
	signal inner_coder_sink_rdy		: std_logic;

begin

	aclr <= not reset_n;

	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then  
				outer_coder_sink_sop <= '0';
				outer_coder_sink_eop <= '0';
			elsif ce = '1' then	
				outer_coder_sink_sop <= sink_sop;
				outer_coder_sink_eop <= sink_eop;
			end if;
		end if;
	end process;	
	
	----------------------------------------------------------------------------
	-- 1. Transport multiplex adaptation and randomization for energy dispersal:
	----------------------------------------------------------------------------

	-- 8 bits to 1 bit serializer
	Inst_byte_serializer: byte_serializer PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_byte 	=> sink_byte,		--	entrada,
		sink_val 	=> sink_val,		--	new_data,
		sink_rdy 	=> sink_rdy,		--	overflow,
		source_sop	=> open,
		source_eop	=> open,
		source_bit	=> mux_adapter_sink_bit,
		source_val 	=> mux_adapter_sink_val
	);

	Inst_mux_adapter: mux_adapter PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_bit 	=> mux_adapter_sink_bit,
		sink_val 	=> mux_adapter_sink_val,
		source_bit	=> mux_adapter_source_bit,
		source_val 	=> mux_adapter_source_val,
		source_sop	=> mux_adapter_source_sop,
		source_eop	=> mux_adapter_source_eop
	);

	-- 1 bit to 8 bits parallelizer
	Inst_bit_parallelizer: bit_parallelizer PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_bit 	=> mux_adapter_source_bit,
		sink_val 	=> mux_adapter_source_val,		
		source_byte	=> fifo_in,
		source_val 	=> wrreq
	);
	
	dcfifo_component : dcfifo
	generic map
        (
        add_ram_output_register => "OFF",
        intended_device_family => "Cyclone III",
        lpm_numwords => 32,
        lpm_type => "dcfifo",
        lpm_width => 8,
        lpm_widthu => 5,
        overflow_checking => "ON",
        underflow_checking => "ON",
        use_eab => "ON"
        )
	port map
        (
        rdclk => clk,
        wrclk => clk,
        aclr => aclr,
        data => fifo_in,
        wrreq => wrreq,
        rdreq => outer_coder_sink_rdy,
        rdempty => rdempty,
        wrfull => open,
        q => outer_coder_sink_byte 
        );

	outer_coder_sink_val <= not (rdempty);
	
	----------------------------------------------------------------------------
	-- 2. Outer coder (Reed-solomon):
	----------------------------------------------------------------------------
	Inst_outer_coder: rs_encoder
	PORT MAP (
		clk  		=>  clk,
		reset  		=>  aclr,
		rsin  		=>  outer_coder_sink_byte,
		sink_ena  	=>  outer_coder_sink_rdy, -- output
		sink_val  	=>  outer_coder_sink_val,
		sink_sop  	=>  outer_coder_sink_sop,
		sink_eop  	=>  outer_coder_sink_eop,
		source_ena  =>  outer_coder_source_rdy, -- input
		rsout  		=>  outer_coder_source_byte,
		source_val  =>  outer_coder_source_val,
		source_sop  =>  outer_coder_source_sop,
		source_eop  =>  outer_coder_source_eop
	);
	
	outer_inter_sink_byte <= outer_coder_source_byte;
	outer_inter_sink_val <= outer_coder_source_val;
	outer_coder_source_rdy <= outer_inter_sink_rdy;
	
	source_sop <= outer_coder_source_sop;
	source_eop <= outer_coder_source_eop;

	----------------------------------------------------------------------------
	-- 3. Outer Interleaver (byte-wise interleaving):
	----------------------------------------------------------------------------
	Inst_outer_interleaver: outer_interleaver PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_byte 	=> outer_inter_sink_byte,
		sink_val 	=> outer_inter_sink_val,
		sink_rdy	=> outer_inter_sink_rdy, -- output		
		source_rdy  => outer_inter_source_rdy,	-- input
		source_byte	=> outer_inter_source_byte,
		source_val 	=> outer_inter_source_val
	);
	
	inner_coder_sink_byte  <= outer_inter_source_byte;
	inner_coder_sink_val <= outer_inter_source_val;
	outer_inter_source_rdy <= inner_coder_sink_rdy;
	
	----------------------------------------------------------------------------
	-- 4. Inner Coder
	----------------------------------------------------------------------------
	Inst_inner_coder: inner_coder 
	GENERIC MAP(
		FEC			=> FEC,
		Irate		=> Irate,
		Orate		=> Orate)	
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_byte 	=> inner_coder_sink_byte,
		sink_val 	=> inner_coder_sink_val,
		sink_rdy 	=> inner_coder_sink_rdy, -- output
		source_bit	=> source_bit,
		source_val 	=> source_val
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

entity top_coding is
    Port (	
		clk			: in  STD_LOGIC;
		reset_n 	: in  STD_LOGIC;
		ce 			: in  STD_LOGIC; 
		spi_dvalid	: in  STD_LOGIC;
		spi_data 	: in  STD_LOGIC_VECTOR(7 downto 0);
		spi_rdy		: out STD_LOGIC;
		spi_sop		: in  STD_LOGIC;
		spi_eop		: in  STD_LOGIC;
		data_out 	: out STD_LOGIC; --_VECTOR(7 downto 0);
		data_val 	: out STD_LOGIC
		);
end top_coding;

architecture Behavioral of top_coding is

	COMPONENT coding
	 Generic	(	
		FEC 		: natural := 34;
		Irate		: integer := 3;
		Orate		: integer := 4);
	PORT(
		clk			: in  STD_LOGIC;
		reset_n 	: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;
		sink_rdy 	: out STD_LOGIC;
		sink_byte 	: in  STD_LOGIC_VECTOR(7 downto 0);
		sink_val	: in  STD_LOGIC;
		sink_sop	: in  STD_LOGIC;
		sink_eop	: in  STD_LOGIC;
		source_bit 	: out STD_LOGIC; --_VECTOR(7 downto 0);
		source_val	: out STD_LOGIC;
		source_sop	: out STD_LOGIC;
		source_eop 	: out STD_LOGIC
		);
	END COMPONENT;

begin

	Inst_coding: coding 
	GENERIC MAP(
		FEC			=> 34,
		Irate		=> 3,
		Orate		=> 4)	
	PORT MAP(
		clk			=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_rdy 	=> spi_rdy,
		sink_byte 	=> spi_data,
		sink_val	=> spi_dvalid,
		sink_sop	=> spi_sop,
		sink_eop	=> spi_eop,
		source_bit 	=> data_out,
		source_val	=> data_val,
		source_sop	=> open,
		source_eop 	=> open
	);

end Behavioral;

-- synthesis translate_on

-- synthesis translate_off
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use std.textio.all;

library WORK;
use WORK.mypackage.all;

ENTITY coding_tb_vhd IS
END coding_tb_vhd;

ARCHITECTURE behavior OF coding_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT top_coding
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		spi_dvalid	: in  STD_LOGIC;
		spi_data 	: in  STD_LOGIC_VECTOR(7 downto 0);
		spi_rdy		: out STD_LOGIC;
		spi_sop		: in  STD_LOGIC;
		spi_eop		: in  STD_LOGIC;
		data_out 	: out std_logic;	--_vector(7 downto 0);  
		data_val 	: out std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk 		:  std_logic := '0';
	SIGNAL reset_n 	:  std_logic := '0';
	SIGNAL ce 		:  std_logic := '0';
	
	SIGNAL spi_dvalid :  std_logic := '0';
	SIGNAL spi_data :  std_logic_vector(7 downto 0) := (others=>'0');
	SIGNAL spi_sop	:  std_logic := '0';
	SIGNAL spi_eop	:  std_logic := '0';

	--Outputs
	SIGNAL spi_rdy	:  std_logic;
	SIGNAL data_out	:  std_logic;	--_vector(7 downto 0);  
	SIGNAL data_val	:  std_logic;
	
	--Testbench
	file IN_FILE	: TEXT;
	file OUT_FILE	: TEXT;
	shared variable cycles_cntr	: integer	:= 0;		

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: top_coding PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,		--
		spi_dvalid 	=> spi_dvalid,
		spi_data  	=> spi_data,
		spi_rdy	  	=> spi_rdy,	
		spi_sop		=> spi_sop,
		spi_eop		=> spi_eop,
		data_out 	=> data_out,
		data_val 	=> data_val
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
				  
					if (not endfile(OUT_FILE)) then
						readline(OUT_FILE, dato);
						read (dato, valor);	
					else
						file_close (OUT_FILE);
						file_open(OUT_FILE, "../00_entrada_8ts.dat", read_mode);
						readline(OUT_FILE, dato);
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
	
	-- Proceso para guardar los datos de salida en un fichero utilizando una línea para cada bit
	wrFile: process(clk)
		variable espacio_blanco	: string (1 to 2);
		variable dato : line;
		variable wr_cntr : integer;		
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				espacio_blanco(2) := ' ';
				espacio_blanco(1) := ' ';
				wr_cntr := 0;
			elsif ce = '1' then
				if data_val = '1' then
					write(dato, conv_integer(data_out));
					writeline(IN_FILE, dato);
					wr_cntr := wr_cntr + 1;
				end if; 
			end if;
		end if;
	end process;
	
	tb : PROCESS
	BEGIN
		file_open(OUT_FILE, "../00_entrada_8ts.dat", read_mode);
		file_open(IN_FILE, "../04_salida_inner_coder.dat", write_mode);
		reset_n <= '0';
		ce <= '0';
		-- Wait 100 ns for global reset to finish
		wait for 110 ns;
		reset_n <= '1';
		ce <= '1';		
		wait for 595 ns;
--		wait until file_end = '1';
		wait for 499 us;
		file_close (IN_FILE);
		file_close (OUT_FILE);
		wait; -- will wait forever
	END PROCESS;

END;
	
-- synthesis translate_on