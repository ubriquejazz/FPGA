-------------------------------------------------------------------------------------
-- resampler
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity resampler is
	PORT( 
		clk	 			: in  STD_LOGIC;
		reset_n 		: in  STD_LOGIC;
		ce 				: in  STD_LOGIC;
--		sink_rdy		: out STD_LOGIC;
		sink_bit 		: in  STD_LOGIC;
		sink_val 		: in  STD_LOGIC;
		source_rdy 		: in  STD_LOGIC;
		source_wrd		: out STD_LOGIC_VECTOR (5 downto 0);
		source_val 		: out STD_LOGIC
	);	
end resampler;

architecture Behavioral of resampler is

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

	type fsm_mux is (rama0, rama1, rama2, rama3, rama4, rama5);
	signal wait_gen_mux : fsm_mux;

	signal fifo_in	: STD_LOGIC_VECTOR (5 downto 0);
	signal aclr	: STD_LOGIC;
	signal wrreq	: STD_LOGIC;
	signal rdempty	: STD_LOGIC;

begin

	aclr <= not reset_n;
	
	---------------------------------------------------------------------------------
	-- Input demultiplexor (Finite State Machine).
	---------------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wait_gen_mux <= rama0;
			elsif ce = '1' and sink_val = '1' then
				case wait_gen_mux is
				
					when rama0	=>	wait_gen_mux <= rama2;
					when rama1	=>	wait_gen_mux <= rama3;
					when rama2	=>	wait_gen_mux <= rama4;					
					when rama3	=>	wait_gen_mux <= rama5;					
					when rama4	=>	wait_gen_mux <= rama1;					
					when rama5	=>	wait_gen_mux <= rama0;					
					when others => 	wait_gen_mux <= rama0;
					
				end case;
			end if;
		end if;
	end process;

	---------------------------------------------------------------------------------
	-- FSM Outpus
	---------------------------------------------------------------------------------
		
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				wrreq <= '0';
			elsif ce = '1' and sink_val = '1' and wait_gen_mux = rama5 then
				wrreq <= '1';
			else
				wrreq <= '0';
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				fifo_in <= (others => '0');
			elsif ce = '1' and sink_val = '1' then
				case wait_gen_mux is
					when rama0	=>	fifo_in(0) <= sink_bit;
					when rama1	=>	fifo_in(1) <= sink_bit;
					when rama2	=>	fifo_in(2) <= sink_bit;
					when rama3	=>	fifo_in(3) <= sink_bit;
					when rama4	=>	fifo_in(4) <= sink_bit;
					when rama5	=>	fifo_in(5) <= sink_bit;
				end case;
			end if;
		end if;
	end process;
	
	dcfifo_component : dcfifo
	generic map
        (
        add_ram_output_register => "OFF",
        intended_device_family => "Cyclone III",
        lpm_numwords => 32,
        lpm_type => "dcfifo",
        lpm_width => 6,
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
        rdreq => source_rdy,
        rdempty => rdempty,
        wrfull => open,
        q => source_wrd
        );

	source_val <= not rdempty;	

end Behavioral;
