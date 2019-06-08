--------------------------------------------------------------------------------
--     This file is owned and controlled by Xilinx and must be used           --
--     solely for design, simulation, implementation and creation of          --
--     design files limited to Xilinx devices or technologies. Use            --
--     with non-Xilinx devices or technologies is expressly prohibited        --
--     and immediately terminates your license.                               --
--                                                                            --
--     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"          --
--     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR                --
--     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION        --
--     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION            --
--     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS              --
--     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,                --
--     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE       --
--     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY               --
--     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE                --
--     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR         --
--     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF        --
--     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS        --
--     FOR A PARTICULAR PURPOSE.                                              --
--                                                                            --
--     Xilinx products are not intended for use in life support               --
--     appliances, devices, or systems. Use in such applications are          --
--     expressly prohibited.                                                  --
--                                                                            --
--     (c) Copyright 1995-2007 Xilinx, Inc.                                   --
--     All rights reserved.                                                   --
--------------------------------------------------------------------------------
-- You must compile the wrapper file rs_encoder.vhd when simulating
-- the core, rs_encoder. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

-- The synthesis directives "translate_off/translate_on" specified
-- below are supported by Xilinx, Mentor Graphics and Synplicity
-- synthesis tools. Ensure they are correct for your synthesis tool(s).

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- synthesis translate_off
Library XilinxCoreLib;
-- synthesis translate_on
ENTITY rs_encoder IS
	port (
	data_in: IN std_logic_VECTOR(7 downto 0);
	start: IN std_logic;
	bypass: IN std_logic;
	nd: IN std_logic;
	data_out: OUT std_logic_VECTOR(7 downto 0);
	info: OUT std_logic;
	rdy: OUT std_logic;
	rfd: OUT std_logic;
	ce: IN std_logic;
	reset: IN std_logic;
	clk: IN std_logic);
END rs_encoder;

ARCHITECTURE rs_encoder_a OF rs_encoder IS
-- synthesis translate_off
component wrapped_rs_encoder
	port (
	data_in: IN std_logic_VECTOR(7 downto 0);
	start: IN std_logic;
	bypass: IN std_logic;
	nd: IN std_logic;
	data_out: OUT std_logic_VECTOR(7 downto 0);
	info: OUT std_logic;
	rdy: OUT std_logic;
	rfd: OUT std_logic;
	ce: IN std_logic;
	reset: IN std_logic;
	clk: IN std_logic);
end component;

-- Configuration specification 
	for all : wrapped_rs_encoder use entity XilinxCoreLib.rs_encoder_v6_1(behavioral)
		generic map(
			c_has_r_in => 0,
			c_userpm => 0,
			c_spec => 0,
			c_num_channels => 1,
			c_has_rffd => 0,
			c_gen_poly_type => 0,
			c_polynomial => 285,
			c_has_rdy => 1,
			c_has_nd => 1,
			c_has_n_in => 0,
			c_has_rfd => 1,
			c_has_ce => 1,
			c_gen_start => 0,
			c_n => 204,
			c_memstyle => 2,
			c_symbol_width => 8,
			c_optimization => 2,
			c_k => 188,
			c_h => 1,
			c_mem_init_prefix => "rs_encoder");
-- synthesis translate_on
BEGIN
-- synthesis translate_off
U0 : wrapped_rs_encoder
		port map (
			data_in => data_in,
			start => start,
			bypass => bypass,
			nd => nd,
			data_out => data_out,
			info => info,
			rdy => rdy,
			rfd => rfd,
			ce => ce,
			reset => reset,
			clk => clk);
-- synthesis translate_on

END rs_encoder_a;

