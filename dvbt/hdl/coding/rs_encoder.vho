--IP Functional Simulation Model
--VERSION_BEGIN 12.0SP2 cbx_mgl 2012:08:02:15:20:46:SJ cbx_simgen 2012:08:02:15:18:54:SJ  VERSION_END


-- Copyright (C) 1991-2012 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- You may only use these simulation model output files for simulation
-- purposes and expressly not for synthesis or any other purposes (in which
-- event Altera disclaims all warranties of any kind).


--synopsys translate_off

 LIBRARY sgate;
 USE sgate.sgate_pack.all;

--synthesis_resources = lut 256 mux21 207 oper_add 3 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  rs_encoder IS 
	 PORT 
	 ( 
		 clk	:	IN  STD_LOGIC;
		 reset	:	IN  STD_LOGIC;
		 rsin	:	IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
		 rsout	:	OUT  STD_LOGIC_VECTOR (7 DOWNTO 0);
		 sink_ena	:	OUT  STD_LOGIC;
		 sink_eop	:	IN  STD_LOGIC;
		 sink_sop	:	IN  STD_LOGIC;
		 sink_val	:	IN  STD_LOGIC;
		 source_ena	:	IN  STD_LOGIC;
		 source_eop	:	OUT  STD_LOGIC;
		 source_sop	:	OUT  STD_LOGIC;
		 source_val	:	OUT  STD_LOGIC
	 ); 
 END rs_encoder;

 ARCHITECTURE RTL OF rs_encoder IS

	 ATTRIBUTE synthesis_clearbox : natural;
	 ATTRIBUTE synthesis_clearbox OF RTL : ARCHITECTURE IS 1;
	 SIGNAL	 ni010O7	:	STD_LOGIC := '0';
	 SIGNAL	 ni010O8	:	STD_LOGIC := '0';
	 SIGNAL	 ni011O10	:	STD_LOGIC := '0';
	 SIGNAL	 ni011O9	:	STD_LOGIC := '0';
	 SIGNAL	 ni01ll5	:	STD_LOGIC := '0';
	 SIGNAL	 ni01ll6	:	STD_LOGIC := '0';
	 SIGNAL	 ni01Oi3	:	STD_LOGIC := '0';
	 SIGNAL	 ni01Oi4	:	STD_LOGIC := '0';
	 SIGNAL	 ni01OO1	:	STD_LOGIC := '0';
	 SIGNAL	 ni01OO2	:	STD_LOGIC := '0';
	 SIGNAL	 ni100i45	:	STD_LOGIC := '0';
	 SIGNAL	 ni100i46	:	STD_LOGIC := '0';
	 SIGNAL	 ni100l43	:	STD_LOGIC := '0';
	 SIGNAL	 ni100l44	:	STD_LOGIC := '0';
	 SIGNAL	 ni10Oi41	:	STD_LOGIC := '0';
	 SIGNAL	 ni10Oi42	:	STD_LOGIC := '0';
	 SIGNAL	 ni1i0O35	:	STD_LOGIC := '0';
	 SIGNAL	 ni1i0O36	:	STD_LOGIC := '0';
	 SIGNAL	 ni1i1i39	:	STD_LOGIC := '0';
	 SIGNAL	 ni1i1i40	:	STD_LOGIC := '0';
	 SIGNAL  wire_ni1i1i40_w_lg_w_lg_q120w121w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_ni1i1i40_w_lg_q120w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL	 ni1i1O37	:	STD_LOGIC := '0';
	 SIGNAL	 ni1i1O38	:	STD_LOGIC := '0';
	 SIGNAL	 ni1iil33	:	STD_LOGIC := '0';
	 SIGNAL	 ni1iil34	:	STD_LOGIC := '0';
	 SIGNAL	 ni1iOi31	:	STD_LOGIC := '0';
	 SIGNAL	 ni1iOi32	:	STD_LOGIC := '0';
	 SIGNAL	 ni1iOO29	:	STD_LOGIC := '0';
	 SIGNAL	 ni1iOO30	:	STD_LOGIC := '0';
	 SIGNAL	 ni1l0l25	:	STD_LOGIC := '0';
	 SIGNAL	 ni1l0l26	:	STD_LOGIC := '0';
	 SIGNAL	 ni1l1l27	:	STD_LOGIC := '0';
	 SIGNAL	 ni1l1l28	:	STD_LOGIC := '0';
	 SIGNAL	 ni1lil23	:	STD_LOGIC := '0';
	 SIGNAL	 ni1lil24	:	STD_LOGIC := '0';
	 SIGNAL	 ni1lOi21	:	STD_LOGIC := '0';
	 SIGNAL	 ni1lOi22	:	STD_LOGIC := '0';
	 SIGNAL	 ni1O0i19	:	STD_LOGIC := '0';
	 SIGNAL	 ni1O0i20	:	STD_LOGIC := '0';
	 SIGNAL	 ni1O0O17	:	STD_LOGIC := '0';
	 SIGNAL	 ni1O0O18	:	STD_LOGIC := '0';
	 SIGNAL  wire_ni1O0O18_w_lg_w_lg_q58w59w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_ni1O0O18_w_lg_q58w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL	 ni1OiO15	:	STD_LOGIC := '0';
	 SIGNAL	 ni1OiO16	:	STD_LOGIC := '0';
	 SIGNAL	 ni1OlO13	:	STD_LOGIC := '0';
	 SIGNAL	 ni1OlO14	:	STD_LOGIC := '0';
	 SIGNAL	 ni1OOO11	:	STD_LOGIC := '0';
	 SIGNAL	 ni1OOO12	:	STD_LOGIC := '0';
	 SIGNAL	n000i	:	STD_LOGIC := '0';
	 SIGNAL	n000l	:	STD_LOGIC := '0';
	 SIGNAL	n000O	:	STD_LOGIC := '0';
	 SIGNAL	n001i	:	STD_LOGIC := '0';
	 SIGNAL	n001l	:	STD_LOGIC := '0';
	 SIGNAL	n001O	:	STD_LOGIC := '0';
	 SIGNAL	n00ii	:	STD_LOGIC := '0';
	 SIGNAL	n00il	:	STD_LOGIC := '0';
	 SIGNAL	n00iO	:	STD_LOGIC := '0';
	 SIGNAL	n00li	:	STD_LOGIC := '0';
	 SIGNAL	n00ll	:	STD_LOGIC := '0';
	 SIGNAL	n00lO	:	STD_LOGIC := '0';
	 SIGNAL	n00Oi	:	STD_LOGIC := '0';
	 SIGNAL	n00Ol	:	STD_LOGIC := '0';
	 SIGNAL	n00OO	:	STD_LOGIC := '0';
	 SIGNAL	n01ii	:	STD_LOGIC := '0';
	 SIGNAL	n01il	:	STD_LOGIC := '0';
	 SIGNAL	n01iO	:	STD_LOGIC := '0';
	 SIGNAL	n01li	:	STD_LOGIC := '0';
	 SIGNAL	n01ll	:	STD_LOGIC := '0';
	 SIGNAL	n01lO	:	STD_LOGIC := '0';
	 SIGNAL	n01Oi	:	STD_LOGIC := '0';
	 SIGNAL	n01Ol	:	STD_LOGIC := '0';
	 SIGNAL	n01OO	:	STD_LOGIC := '0';
	 SIGNAL	n0i0i	:	STD_LOGIC := '0';
	 SIGNAL	n0i0l	:	STD_LOGIC := '0';
	 SIGNAL	n0i0O	:	STD_LOGIC := '0';
	 SIGNAL	n0i1i	:	STD_LOGIC := '0';
	 SIGNAL	n0i1l	:	STD_LOGIC := '0';
	 SIGNAL	n0i1O	:	STD_LOGIC := '0';
	 SIGNAL	n0iii	:	STD_LOGIC := '0';
	 SIGNAL	n0iil	:	STD_LOGIC := '0';
	 SIGNAL	n0iiO	:	STD_LOGIC := '0';
	 SIGNAL	n0ili	:	STD_LOGIC := '0';
	 SIGNAL	n0ill	:	STD_LOGIC := '0';
	 SIGNAL	n0ilO	:	STD_LOGIC := '0';
	 SIGNAL	n0iOi	:	STD_LOGIC := '0';
	 SIGNAL	n0iOl	:	STD_LOGIC := '0';
	 SIGNAL	n0iOO	:	STD_LOGIC := '0';
	 SIGNAL	n0l0i	:	STD_LOGIC := '0';
	 SIGNAL	n0l0l	:	STD_LOGIC := '0';
	 SIGNAL	n0l0O	:	STD_LOGIC := '0';
	 SIGNAL	n0l1i	:	STD_LOGIC := '0';
	 SIGNAL	n0l1l	:	STD_LOGIC := '0';
	 SIGNAL	n0l1O	:	STD_LOGIC := '0';
	 SIGNAL	n0lii	:	STD_LOGIC := '0';
	 SIGNAL	n0lil	:	STD_LOGIC := '0';
	 SIGNAL	n0liO	:	STD_LOGIC := '0';
	 SIGNAL	n0lli	:	STD_LOGIC := '0';
	 SIGNAL	n0lll	:	STD_LOGIC := '0';
	 SIGNAL	n0llO	:	STD_LOGIC := '0';
	 SIGNAL	n0lOi	:	STD_LOGIC := '0';
	 SIGNAL	n0lOl	:	STD_LOGIC := '0';
	 SIGNAL	n0lOO	:	STD_LOGIC := '0';
	 SIGNAL	n0O0i	:	STD_LOGIC := '0';
	 SIGNAL	n0O0l	:	STD_LOGIC := '0';
	 SIGNAL	n0O0O	:	STD_LOGIC := '0';
	 SIGNAL	n0O1i	:	STD_LOGIC := '0';
	 SIGNAL	n0O1l	:	STD_LOGIC := '0';
	 SIGNAL	n0O1O	:	STD_LOGIC := '0';
	 SIGNAL	n0Oii	:	STD_LOGIC := '0';
	 SIGNAL	n0Oil	:	STD_LOGIC := '0';
	 SIGNAL	n0OiO	:	STD_LOGIC := '0';
	 SIGNAL	n0Oli	:	STD_LOGIC := '0';
	 SIGNAL	n0Oll	:	STD_LOGIC := '0';
	 SIGNAL	n0OlO	:	STD_LOGIC := '0';
	 SIGNAL	n0OOi	:	STD_LOGIC := '0';
	 SIGNAL	n0OOO	:	STD_LOGIC := '0';
	 SIGNAL	wire_n0OOl_CLRN	:	STD_LOGIC;
	 SIGNAL  wire_n0OOl_w_lg_n01iO103w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n0OOl_w_lg_n01lO104w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n0OOl_w_lg_n0OlO67w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n0OOl_w_lg_n0OOi71w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n0OOl_w_lg_w_lg_w_lg_n001O118w122w123w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n0OOl_w_lg_w_lg_n001O118w122w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n0OOl_w_lg_n001O118w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL	n100i	:	STD_LOGIC := '0';
	 SIGNAL	n100l	:	STD_LOGIC := '0';
	 SIGNAL	n100O	:	STD_LOGIC := '0';
	 SIGNAL	n101i	:	STD_LOGIC := '0';
	 SIGNAL	n101l	:	STD_LOGIC := '0';
	 SIGNAL	n101O	:	STD_LOGIC := '0';
	 SIGNAL	n10ii	:	STD_LOGIC := '0';
	 SIGNAL	n10il	:	STD_LOGIC := '0';
	 SIGNAL	n10li	:	STD_LOGIC := '0';
	 SIGNAL	n11Oi	:	STD_LOGIC := '0';
	 SIGNAL	n11Ol	:	STD_LOGIC := '0';
	 SIGNAL	n11OO	:	STD_LOGIC := '0';
	 SIGNAL	nlOO1l	:	STD_LOGIC := '0';
	 SIGNAL  wire_n10iO_w_lg_n100i538w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n100l536w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n100O534w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n101i543w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n101l541w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n101O539w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n10ii532w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n10il530w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n10li529w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n11Oi111w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n11Ol29w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_n11OO545w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_n10iO_w_lg_nlOO1l88w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL	n10lO	:	STD_LOGIC := '0';
	 SIGNAL	wire_n10ll_PRN	:	STD_LOGIC;
	 SIGNAL	n1iOO	:	STD_LOGIC := '0';
	 SIGNAL	nll00i	:	STD_LOGIC := '0';
	 SIGNAL	nll00l	:	STD_LOGIC := '0';
	 SIGNAL	nll00O	:	STD_LOGIC := '0';
	 SIGNAL	nll01i	:	STD_LOGIC := '0';
	 SIGNAL	nll01l	:	STD_LOGIC := '0';
	 SIGNAL	nll01O	:	STD_LOGIC := '0';
	 SIGNAL	nll0ii	:	STD_LOGIC := '0';
	 SIGNAL	nll0il	:	STD_LOGIC := '0';
	 SIGNAL	nll0iO	:	STD_LOGIC := '0';
	 SIGNAL	nll0li	:	STD_LOGIC := '0';
	 SIGNAL	nll0ll	:	STD_LOGIC := '0';
	 SIGNAL	nll0lO	:	STD_LOGIC := '0';
	 SIGNAL	nll0Oi	:	STD_LOGIC := '0';
	 SIGNAL	nll0Ol	:	STD_LOGIC := '0';
	 SIGNAL	nll0OO	:	STD_LOGIC := '0';
	 SIGNAL	nll1li	:	STD_LOGIC := '0';
	 SIGNAL	nll1ll	:	STD_LOGIC := '0';
	 SIGNAL	nll1lO	:	STD_LOGIC := '0';
	 SIGNAL	nll1Oi	:	STD_LOGIC := '0';
	 SIGNAL	nll1Ol	:	STD_LOGIC := '0';
	 SIGNAL	nll1OO	:	STD_LOGIC := '0';
	 SIGNAL	nlli0i	:	STD_LOGIC := '0';
	 SIGNAL	nlli0l	:	STD_LOGIC := '0';
	 SIGNAL	nlli0O	:	STD_LOGIC := '0';
	 SIGNAL	nlli1i	:	STD_LOGIC := '0';
	 SIGNAL	nlli1l	:	STD_LOGIC := '0';
	 SIGNAL	nlli1O	:	STD_LOGIC := '0';
	 SIGNAL	nlliii	:	STD_LOGIC := '0';
	 SIGNAL	nlliil	:	STD_LOGIC := '0';
	 SIGNAL	nlliiO	:	STD_LOGIC := '0';
	 SIGNAL	nllili	:	STD_LOGIC := '0';
	 SIGNAL	nllill	:	STD_LOGIC := '0';
	 SIGNAL	nllilO	:	STD_LOGIC := '0';
	 SIGNAL	nlliOi	:	STD_LOGIC := '0';
	 SIGNAL	nlliOl	:	STD_LOGIC := '0';
	 SIGNAL	nlliOO	:	STD_LOGIC := '0';
	 SIGNAL	nlll0i	:	STD_LOGIC := '0';
	 SIGNAL	nlll0l	:	STD_LOGIC := '0';
	 SIGNAL	nlll0O	:	STD_LOGIC := '0';
	 SIGNAL	nlll1i	:	STD_LOGIC := '0';
	 SIGNAL	nlll1l	:	STD_LOGIC := '0';
	 SIGNAL	nlll1O	:	STD_LOGIC := '0';
	 SIGNAL	nlllii	:	STD_LOGIC := '0';
	 SIGNAL	nlllil	:	STD_LOGIC := '0';
	 SIGNAL	nllliO	:	STD_LOGIC := '0';
	 SIGNAL	nlllli	:	STD_LOGIC := '0';
	 SIGNAL	nlllll	:	STD_LOGIC := '0';
	 SIGNAL	nllllO	:	STD_LOGIC := '0';
	 SIGNAL	nlllOi	:	STD_LOGIC := '0';
	 SIGNAL	nlllOl	:	STD_LOGIC := '0';
	 SIGNAL	nlllOO	:	STD_LOGIC := '0';
	 SIGNAL	nllO0i	:	STD_LOGIC := '0';
	 SIGNAL	nllO0l	:	STD_LOGIC := '0';
	 SIGNAL	nllO0O	:	STD_LOGIC := '0';
	 SIGNAL	nllO1i	:	STD_LOGIC := '0';
	 SIGNAL	nllO1l	:	STD_LOGIC := '0';
	 SIGNAL	nllO1O	:	STD_LOGIC := '0';
	 SIGNAL	nllOii	:	STD_LOGIC := '0';
	 SIGNAL	nllOil	:	STD_LOGIC := '0';
	 SIGNAL	nllOiO	:	STD_LOGIC := '0';
	 SIGNAL	nllOli	:	STD_LOGIC := '0';
	 SIGNAL	nllOll	:	STD_LOGIC := '0';
	 SIGNAL	nllOlO	:	STD_LOGIC := '0';
	 SIGNAL	nllOOi	:	STD_LOGIC := '0';
	 SIGNAL	nllOOl	:	STD_LOGIC := '0';
	 SIGNAL	nllOOO	:	STD_LOGIC := '0';
	 SIGNAL	nlO00i	:	STD_LOGIC := '0';
	 SIGNAL	nlO00l	:	STD_LOGIC := '0';
	 SIGNAL	nlO00O	:	STD_LOGIC := '0';
	 SIGNAL	nlO01i	:	STD_LOGIC := '0';
	 SIGNAL	nlO01l	:	STD_LOGIC := '0';
	 SIGNAL	nlO01O	:	STD_LOGIC := '0';
	 SIGNAL	nlO0ii	:	STD_LOGIC := '0';
	 SIGNAL	nlO0il	:	STD_LOGIC := '0';
	 SIGNAL	nlO0iO	:	STD_LOGIC := '0';
	 SIGNAL	nlO0li	:	STD_LOGIC := '0';
	 SIGNAL	nlO0ll	:	STD_LOGIC := '0';
	 SIGNAL	nlO0lO	:	STD_LOGIC := '0';
	 SIGNAL	nlO0Oi	:	STD_LOGIC := '0';
	 SIGNAL	nlO0Ol	:	STD_LOGIC := '0';
	 SIGNAL	nlO0OO	:	STD_LOGIC := '0';
	 SIGNAL	nlO10i	:	STD_LOGIC := '0';
	 SIGNAL	nlO10l	:	STD_LOGIC := '0';
	 SIGNAL	nlO10O	:	STD_LOGIC := '0';
	 SIGNAL	nlO11i	:	STD_LOGIC := '0';
	 SIGNAL	nlO11l	:	STD_LOGIC := '0';
	 SIGNAL	nlO11O	:	STD_LOGIC := '0';
	 SIGNAL	nlO1ii	:	STD_LOGIC := '0';
	 SIGNAL	nlO1il	:	STD_LOGIC := '0';
	 SIGNAL	nlO1iO	:	STD_LOGIC := '0';
	 SIGNAL	nlO1li	:	STD_LOGIC := '0';
	 SIGNAL	nlO1ll	:	STD_LOGIC := '0';
	 SIGNAL	nlO1lO	:	STD_LOGIC := '0';
	 SIGNAL	nlO1Oi	:	STD_LOGIC := '0';
	 SIGNAL	nlO1Ol	:	STD_LOGIC := '0';
	 SIGNAL	nlO1OO	:	STD_LOGIC := '0';
	 SIGNAL	nlOi0i	:	STD_LOGIC := '0';
	 SIGNAL	nlOi0l	:	STD_LOGIC := '0';
	 SIGNAL	nlOi0O	:	STD_LOGIC := '0';
	 SIGNAL	nlOi1i	:	STD_LOGIC := '0';
	 SIGNAL	nlOi1l	:	STD_LOGIC := '0';
	 SIGNAL	nlOi1O	:	STD_LOGIC := '0';
	 SIGNAL	nlOiii	:	STD_LOGIC := '0';
	 SIGNAL	nlOiil	:	STD_LOGIC := '0';
	 SIGNAL	nlOiiO	:	STD_LOGIC := '0';
	 SIGNAL	nlOili	:	STD_LOGIC := '0';
	 SIGNAL	nlOill	:	STD_LOGIC := '0';
	 SIGNAL	nlOilO	:	STD_LOGIC := '0';
	 SIGNAL	nlOiOi	:	STD_LOGIC := '0';
	 SIGNAL	nlOiOl	:	STD_LOGIC := '0';
	 SIGNAL	nlOiOO	:	STD_LOGIC := '0';
	 SIGNAL	nlOl0i	:	STD_LOGIC := '0';
	 SIGNAL	nlOl0l	:	STD_LOGIC := '0';
	 SIGNAL	nlOl0O	:	STD_LOGIC := '0';
	 SIGNAL	nlOl1i	:	STD_LOGIC := '0';
	 SIGNAL	nlOl1l	:	STD_LOGIC := '0';
	 SIGNAL	nlOl1O	:	STD_LOGIC := '0';
	 SIGNAL	nlOlii	:	STD_LOGIC := '0';
	 SIGNAL	nlOlil	:	STD_LOGIC := '0';
	 SIGNAL	nlOliO	:	STD_LOGIC := '0';
	 SIGNAL	nlOlli	:	STD_LOGIC := '0';
	 SIGNAL	nlOlll	:	STD_LOGIC := '0';
	 SIGNAL	nlOllO	:	STD_LOGIC := '0';
	 SIGNAL	nlOlOi	:	STD_LOGIC := '0';
	 SIGNAL	nlOlOl	:	STD_LOGIC := '0';
	 SIGNAL	nlOlOO	:	STD_LOGIC := '0';
	 SIGNAL	nlOO1i	:	STD_LOGIC := '0';
	 SIGNAL	wire_n1iOl_CLRN	:	STD_LOGIC;
	 SIGNAL	wire_n00i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n00l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n00O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n010i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n011O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n01i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n01l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n01O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0ii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0il_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0iO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0li_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0ll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0lO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0Oi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0Ol_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n0OO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n10i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n10l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n10O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n10Oi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n10Ol_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n10OO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n11i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n11l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n11O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1i0i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1i0l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1i0O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1i1i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1i1l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1i1O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1ii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1iii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1iil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1iiO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1il_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1ili_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1ill_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1ilO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1iO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1l0i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1l0l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1l0O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1li_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1lii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1lil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1liO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1ll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1lli_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1lll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1llO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1lO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1lOi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1O1i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1O1l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1Oi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1OiO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1Ol_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1Oli_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1Oll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_n1OO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni00i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni00l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni00O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni01i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni01l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni01O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0ii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0iO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0li_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0ll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0lO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0Oi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0Ol_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni0OO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni10i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni10l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni10O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni11i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni11l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni11O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1ii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1il_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1iO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1li_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1ll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1lO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1Oi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1Ol_dataout	:	STD_LOGIC;
	 SIGNAL	wire_ni1OO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nii0i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nii0l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nii0O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nii1i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nii1l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nii1O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niiii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niiil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niiiO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niili_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niill_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niilO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niiO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niiOi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niiOl_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niiOO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nil1i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nil1l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nili_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nilil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niliO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nill_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nilli_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nilll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nillO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nilOi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nilOl_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nilOO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niO0l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niO0O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niO1i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOiO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOli_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOlO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOOi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOOl_dataout	:	STD_LOGIC;
	 SIGNAL	wire_niOOO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl00i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl00l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl00O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl01i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl01l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl01O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0ii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0il_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0iO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0li_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0ll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0lO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0Oi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0Ol_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl0OO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl10i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl10l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl10O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl11i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl11l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl11O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl1ii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl1il_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl1iO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl1li_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl1ll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl1Oi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl1Ol_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nl1OO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nli0i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nli0l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nli0O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nli1i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nli1l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nli1O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nliii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nliil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nliiO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlili_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlill_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlilO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nliOi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nliOl_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nliOO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nll0i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nll0l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nll0O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nll1O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nllii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nllil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlliO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nllli_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nllll_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlllO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nllOi_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nllOl_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nllOO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlO0i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlO0l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlO0O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlO1i_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlO1l_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlO1O_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlOii_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlOil_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlOiO_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlOOl_dataout	:	STD_LOGIC;
	 SIGNAL	wire_nlOOO_dataout	:	STD_LOGIC;
	 SIGNAL  wire_n1iOi_a	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_n1iOi_b	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_gnd	:	STD_LOGIC;
	 SIGNAL  wire_n1iOi_o	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_n1l1i_a	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_n1l1i_b	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_n1l1i_o	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_n1lOl_a	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_n1lOl_b	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_n1lOl_o	:	STD_LOGIC_VECTOR (5 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_sink_val61w62w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_sink_val34w35w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_source_ena43w70w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_source_ena43w99w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_ni01il30w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_sink_eop105w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_sink_val61w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_source_ena52w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_source_ena89w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_reset97w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_sink_val34w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_source_ena43w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_source_ena43w56w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  wire_w_lg_w_lg_w_lg_source_ena43w56w60w	:	STD_LOGIC_VECTOR (0 DOWNTO 0);
	 SIGNAL  ni010l :	STD_LOGIC;
	 SIGNAL  ni011l :	STD_LOGIC;
	 SIGNAL  ni01il :	STD_LOGIC;
	 SIGNAL  ni01iO :	STD_LOGIC;
	 SIGNAL  ni01li :	STD_LOGIC;
	 SIGNAL  ni100O :	STD_LOGIC;
	 SIGNAL  ni101i :	STD_LOGIC;
	 SIGNAL  ni101l :	STD_LOGIC;
	 SIGNAL  ni101O :	STD_LOGIC;
	 SIGNAL  ni10ii :	STD_LOGIC;
	 SIGNAL  ni10il :	STD_LOGIC;
	 SIGNAL  ni10iO :	STD_LOGIC;
	 SIGNAL  ni10li :	STD_LOGIC;
	 SIGNAL  ni10ll :	STD_LOGIC;
	 SIGNAL  ni10lO :	STD_LOGIC;
	 SIGNAL  ni10OO :	STD_LOGIC;
	 SIGNAL  ni11OO :	STD_LOGIC;
	 SIGNAL  ni1i0l :	STD_LOGIC;
	 SIGNAL  ni1ili :	STD_LOGIC;
	 SIGNAL  ni1ill :	STD_LOGIC;
	 SIGNAL  ni1ilO :	STD_LOGIC;
	 SIGNAL  ni1iOl :	STD_LOGIC;
	 SIGNAL  ni1l0i :	STD_LOGIC;
	 SIGNAL  ni1lii :	STD_LOGIC;
	 SIGNAL  ni1lli :	STD_LOGIC;
	 SIGNAL  ni1lll :	STD_LOGIC;
	 SIGNAL  ni1llO :	STD_LOGIC;
	 SIGNAL  ni1lOO :	STD_LOGIC;
	 SIGNAL  ni1O1i :	STD_LOGIC;
	 SIGNAL  ni1O1l :	STD_LOGIC;
	 SIGNAL  ni1O1O :	STD_LOGIC;
	 SIGNAL  ni1Oil :	STD_LOGIC;
	 SIGNAL  ni1Oll :	STD_LOGIC;
	 SIGNAL  ni1OOl :	STD_LOGIC;
 BEGIN

	wire_gnd <= '0';
	wire_w_lg_w_lg_sink_val61w62w(0) <= wire_w_lg_sink_val61w(0) AND n01il;
	wire_w_lg_w_lg_sink_val34w35w(0) <= wire_w_lg_sink_val34w(0) AND source_ena;
	wire_w_lg_w_lg_source_ena43w70w(0) <= wire_w_lg_source_ena43w(0) AND n0OOi;
	wire_w_lg_w_lg_source_ena43w99w(0) <= wire_w_lg_source_ena43w(0) AND ni1ili;
	wire_w_lg_ni01il30w(0) <= ni01il AND wire_n10iO_w_lg_n11Ol29w(0);
	wire_w_lg_sink_eop105w(0) <= sink_eop AND wire_n0OOl_w_lg_n01lO104w(0);
	wire_w_lg_sink_val61w(0) <= sink_val AND wire_w_lg_w_lg_w_lg_source_ena43w56w60w(0);
	wire_w_lg_source_ena52w(0) <= source_ena AND wire_n10iO_w_lg_n11Ol29w(0);
	wire_w_lg_source_ena89w(0) <= source_ena AND wire_n10iO_w_lg_nlOO1l88w(0);
	wire_w_lg_reset97w(0) <= NOT reset;
	wire_w_lg_sink_val34w(0) <= NOT sink_val;
	wire_w_lg_source_ena43w(0) <= NOT source_ena;
	wire_w_lg_w_lg_source_ena43w56w(0) <= wire_w_lg_source_ena43w(0) OR ni1Oil;
	wire_w_lg_w_lg_w_lg_source_ena43w56w60w(0) <= wire_w_lg_w_lg_source_ena43w56w(0) OR wire_ni1O0O18_w_lg_w_lg_q58w59w(0);
	ni010l <= ((ni01il AND n11Ol) AND (ni010O8 XOR ni010O7));
	ni011l <= (wire_w_lg_ni01il30w(0) AND (ni011O10 XOR ni011O9));
	ni01il <= (sink_val AND source_ena);
	ni01iO <= (((n0OOi AND nlOO1l) AND (ni01ll6 XOR ni01ll5)) OR ni01li);
	ni01li <= (wire_w_lg_source_ena89w(0) AND (ni1l1l28 XOR ni1l1l27));
	ni100O <= ((n0lll AND nlOO1l) XOR (nlOO1l AND nll1lO));
	ni101i <= ((n0lOl AND nlOO1l) XOR (nlOO1l AND nll1OO));
	ni101l <= ((n0lli AND nlOO1l) XOR (nlOO1l AND nll1ll));
	ni101O <= ((n0liO AND nlOO1l) XOR (nlOO1l AND nll1li));
	ni10ii <= ((n0lil AND nlOO1l) XOR (n1iOO AND nlOO1l));
	ni10il <= ((n0llO AND nlOO1l) XOR (nlOO1l AND nll1Oi));
	ni10iO <= ((n0lOi AND nlOO1l) XOR (nlOO1l AND nll1Ol));
	ni10li <= (source_ena AND n01Ol);
	ni10ll <= (wire_w_lg_source_ena43w(0) AND n01Ol);
	ni10lO <= (sink_val AND sink_eop);
	ni10OO <= ((((wire_n10iO_w_lg_n100i538w(0) AND wire_n10iO_w_lg_n101O539w(0)) AND wire_n10iO_w_lg_n101l541w(0)) AND wire_n10iO_w_lg_n101i543w(0)) AND wire_n10iO_w_lg_n11OO545w(0));
	ni11OO <= ((n0lOO AND nlOO1l) XOR (nlOO1l AND nll01i));
	ni1i0l <= ((((wire_n10iO_w_lg_n10li529w(0) AND wire_n10iO_w_lg_n10il530w(0)) AND wire_n10iO_w_lg_n10ii532w(0)) AND wire_n10iO_w_lg_n100O534w(0)) AND wire_n10iO_w_lg_n100l536w(0));
	ni1ili <= (sink_val AND ((wire_n0OOl_w_lg_n01iO103w(0) AND wire_w_lg_sink_eop105w(0)) AND (ni1i0O36 XOR ni1i0O35)));
	ni1ill <= (source_ena AND wire_n10iO_w_lg_n11Oi111w(0));
	ni1ilO <= '1';
	ni1iOl <= (wire_w_lg_w_lg_source_ena43w70w(0) AND (ni1iOO30 XOR ni1iOO29));
	ni1l0i <= ((ni1lll AND nlOO1l) AND (ni1l0l26 XOR ni1l0l25));
	ni1lii <= (ni1lli AND nlOO1l);
	ni1lli <= ((source_ena AND n0OOi) AND (ni1lil24 XOR ni1lil23));
	ni1lll <= (source_ena AND wire_n0OOl_w_lg_n0OOi71w(0));
	ni1llO <= ((wire_w_lg_w_lg_source_ena43w70w(0) OR (wire_w_lg_source_ena43w(0) AND wire_n0OOl_w_lg_n0OOi71w(0))) OR (NOT (ni1lOi22 XOR ni1lOi21)));
	ni1lOO <= (wire_w_lg_source_ena43w(0) AND n0OlO);
	ni1O1i <= (source_ena AND wire_n0OOl_w_lg_n0OlO67w(0));
	ni1O1l <= (source_ena AND n0OlO);
	ni1O1O <= (wire_w_lg_w_lg_sink_val61w62w(0) AND (ni1O0i20 XOR ni1O0i19));
	ni1Oil <= (wire_w_lg_source_ena52w(0) AND (ni1OiO16 XOR ni1OiO15));
	ni1Oll <= ((ni1OOl AND n11Ol) AND (ni1OlO14 XOR ni1OlO13));
	ni1OOl <= (wire_w_lg_w_lg_sink_val34w35w(0) AND (ni1OOO12 XOR ni1OOO11));
	rsout <= ( n0Oil & n0Oii & n0O0O & n0O0l & n0O0i & n0O1O & n0O1l & n0O1i);
	sink_ena <= ((source_ena AND n11Ol) AND (ni01OO2 XOR ni01OO1));
	source_eop <= n10lO;
	source_sop <= n000l;
	source_val <= ((n0OOO OR n01ii) OR (NOT (ni01Oi4 XOR ni01Oi3)));
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni010O7 <= ni010O8;
		END IF;
		if (now = 0 ns) then
			ni010O7 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni010O8 <= ni010O7;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni011O10 <= ni011O9;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni011O9 <= ni011O10;
		END IF;
		if (now = 0 ns) then
			ni011O9 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni01ll5 <= ni01ll6;
		END IF;
		if (now = 0 ns) then
			ni01ll5 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni01ll6 <= ni01ll5;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni01Oi3 <= ni01Oi4;
		END IF;
		if (now = 0 ns) then
			ni01Oi3 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni01Oi4 <= ni01Oi3;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni01OO1 <= ni01OO2;
		END IF;
		if (now = 0 ns) then
			ni01OO1 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni01OO2 <= ni01OO1;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni100i45 <= ni100i46;
		END IF;
		if (now = 0 ns) then
			ni100i45 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni100i46 <= ni100i45;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni100l43 <= ni100l44;
		END IF;
		if (now = 0 ns) then
			ni100l43 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni100l44 <= ni100l43;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni10Oi41 <= ni10Oi42;
		END IF;
		if (now = 0 ns) then
			ni10Oi41 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni10Oi42 <= ni10Oi41;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1i0O35 <= ni1i0O36;
		END IF;
		if (now = 0 ns) then
			ni1i0O35 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1i0O36 <= ni1i0O35;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1i1i39 <= ni1i1i40;
		END IF;
		if (now = 0 ns) then
			ni1i1i39 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1i1i40 <= ni1i1i39;
		END IF;
	END PROCESS;
	wire_ni1i1i40_w_lg_w_lg_q120w121w(0) <= NOT wire_ni1i1i40_w_lg_q120w(0);
	wire_ni1i1i40_w_lg_q120w(0) <= ni1i1i40 XOR ni1i1i39;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1i1O37 <= ni1i1O38;
		END IF;
		if (now = 0 ns) then
			ni1i1O37 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1i1O38 <= ni1i1O37;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1iil33 <= ni1iil34;
		END IF;
		if (now = 0 ns) then
			ni1iil33 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1iil34 <= ni1iil33;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1iOi31 <= ni1iOi32;
		END IF;
		if (now = 0 ns) then
			ni1iOi31 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1iOi32 <= ni1iOi31;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1iOO29 <= ni1iOO30;
		END IF;
		if (now = 0 ns) then
			ni1iOO29 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1iOO30 <= ni1iOO29;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1l0l25 <= ni1l0l26;
		END IF;
		if (now = 0 ns) then
			ni1l0l25 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1l0l26 <= ni1l0l25;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1l1l27 <= ni1l1l28;
		END IF;
		if (now = 0 ns) then
			ni1l1l27 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1l1l28 <= ni1l1l27;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1lil23 <= ni1lil24;
		END IF;
		if (now = 0 ns) then
			ni1lil23 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1lil24 <= ni1lil23;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1lOi21 <= ni1lOi22;
		END IF;
		if (now = 0 ns) then
			ni1lOi21 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1lOi22 <= ni1lOi21;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1O0i19 <= ni1O0i20;
		END IF;
		if (now = 0 ns) then
			ni1O0i19 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1O0i20 <= ni1O0i19;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1O0O17 <= ni1O0O18;
		END IF;
		if (now = 0 ns) then
			ni1O0O17 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1O0O18 <= ni1O0O17;
		END IF;
	END PROCESS;
	wire_ni1O0O18_w_lg_w_lg_q58w59w(0) <= NOT wire_ni1O0O18_w_lg_q58w(0);
	wire_ni1O0O18_w_lg_q58w(0) <= ni1O0O18 XOR ni1O0O17;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1OiO15 <= ni1OiO16;
		END IF;
		if (now = 0 ns) then
			ni1OiO15 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1OiO16 <= ni1OiO15;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1OlO13 <= ni1OlO14;
		END IF;
		if (now = 0 ns) then
			ni1OlO13 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1OlO14 <= ni1OlO13;
		END IF;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1OOO11 <= ni1OOO12;
		END IF;
		if (now = 0 ns) then
			ni1OOO11 <= '1' after 1 ps;
		end if;
	END PROCESS;
	PROCESS (clk)
	BEGIN
		IF (clk = '1' AND clk'event) THEN ni1OOO12 <= ni1OOO11;
		END IF;
	END PROCESS;
	PROCESS (clk, wire_n0OOl_CLRN)
	BEGIN
		IF (wire_n0OOl_CLRN = '0') THEN
				n000i <= '0';
				n000l <= '0';
				n000O <= '0';
				n001i <= '0';
				n001l <= '0';
				n001O <= '0';
				n00ii <= '0';
				n00il <= '0';
				n00iO <= '0';
				n00li <= '0';
				n00ll <= '0';
				n00lO <= '0';
				n00Oi <= '0';
				n00Ol <= '0';
				n00OO <= '0';
				n01ii <= '0';
				n01il <= '0';
				n01iO <= '0';
				n01li <= '0';
				n01ll <= '0';
				n01lO <= '0';
				n01Oi <= '0';
				n01Ol <= '0';
				n01OO <= '0';
				n0i0i <= '0';
				n0i0l <= '0';
				n0i0O <= '0';
				n0i1i <= '0';
				n0i1l <= '0';
				n0i1O <= '0';
				n0iii <= '0';
				n0iil <= '0';
				n0iiO <= '0';
				n0ili <= '0';
				n0ill <= '0';
				n0ilO <= '0';
				n0iOi <= '0';
				n0iOl <= '0';
				n0iOO <= '0';
				n0l0i <= '0';
				n0l0l <= '0';
				n0l0O <= '0';
				n0l1i <= '0';
				n0l1l <= '0';
				n0l1O <= '0';
				n0lii <= '0';
				n0lil <= '0';
				n0liO <= '0';
				n0lli <= '0';
				n0lll <= '0';
				n0llO <= '0';
				n0lOi <= '0';
				n0lOl <= '0';
				n0lOO <= '0';
				n0O0i <= '0';
				n0O0l <= '0';
				n0O0O <= '0';
				n0O1i <= '0';
				n0O1l <= '0';
				n0O1O <= '0';
				n0Oii <= '0';
				n0Oil <= '0';
				n0OiO <= '0';
				n0Oli <= '0';
				n0Oll <= '0';
				n0OlO <= '0';
				n0OOi <= '0';
				n0OOO <= '0';
		ELSIF (clk = '1' AND clk'event) THEN
				n000i <= wire_nl01i_dataout;
				n000l <= wire_nilll_dataout;
				n000O <= wire_nllii_dataout;
				n001i <= wire_niOii_dataout;
				n001l <= wire_ni11O_dataout;
				n001O <= wire_n11l_dataout;
				n00ii <= wire_nllil_dataout;
				n00il <= wire_nlliO_dataout;
				n00iO <= wire_nllli_dataout;
				n00li <= wire_nllll_dataout;
				n00ll <= wire_nlllO_dataout;
				n00lO <= wire_nllOi_dataout;
				n00Oi <= wire_nllOl_dataout;
				n00Ol <= wire_niOiO_dataout;
				n00OO <= wire_niOli_dataout;
				n01ii <= ni01li;
				n01il <= source_ena;
				n01iO <= wire_nll1O_dataout;
				n01li <= wire_niO0l_dataout;
				n01ll <= wire_ni11i_dataout;
				n01lO <= wire_nlOOl_dataout;
				n01Oi <= wire_nl1Oi_dataout;
				n01Ol <= wire_nilil_dataout;
				n01OO <= wire_nll0l_dataout;
				n0i0i <= wire_niOOl_dataout;
				n0i0l <= wire_niOOO_dataout;
				n0i0O <= wire_nl11i_dataout;
				n0i1i <= wire_niOll_dataout;
				n0i1l <= wire_niOlO_dataout;
				n0i1O <= wire_niOOi_dataout;
				n0iii <= wire_ni10l_dataout;
				n0iil <= wire_ni10O_dataout;
				n0iiO <= wire_ni1ii_dataout;
				n0ili <= wire_ni1il_dataout;
				n0ill <= wire_ni1iO_dataout;
				n0ilO <= wire_ni1li_dataout;
				n0iOi <= wire_ni1ll_dataout;
				n0iOl <= wire_ni1lO_dataout;
				n0iOO <= wire_n10O_dataout;
				n0l0i <= wire_n1li_dataout;
				n0l0l <= wire_n1ll_dataout;
				n0l0O <= wire_n1lO_dataout;
				n0l1i <= wire_n1ii_dataout;
				n0l1l <= wire_n1il_dataout;
				n0l1O <= wire_n1iO_dataout;
				n0lii <= wire_n1Oi_dataout;
				n0lil <= wire_nl00i_dataout;
				n0liO <= wire_nl00l_dataout;
				n0lli <= wire_nl00O_dataout;
				n0lll <= wire_nl0ii_dataout;
				n0llO <= wire_nl0il_dataout;
				n0lOi <= wire_nl0iO_dataout;
				n0lOl <= wire_nl0li_dataout;
				n0lOO <= wire_nl0ll_dataout;
				n0O0i <= wire_ni0lO_dataout;
				n0O0l <= wire_ni0Oi_dataout;
				n0O0O <= wire_ni0Ol_dataout;
				n0O1i <= wire_ni0iO_dataout;
				n0O1l <= wire_ni0li_dataout;
				n0O1O <= wire_ni0ll_dataout;
				n0Oii <= wire_ni0OO_dataout;
				n0Oil <= wire_nii1i_dataout;
				n0OiO <= wire_nlOil_dataout;
				n0Oli <= wire_nl1li_dataout;
				n0Oll <= wire_ni00O_dataout;
				n0OlO <= wire_niil_dataout;
				n0OOi <= wire_nliOi_dataout;
				n0OOO <= wire_nilOl_dataout;
		END IF;
		if (now = 0 ns) then
			n000i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n000l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n000O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n001i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n001l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n001O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00ii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00il <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00iO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00li <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00ll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00lO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00Oi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00Ol <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n00OO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01ii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01il <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01iO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01li <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01ll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01lO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01Oi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01Ol <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n01OO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0i0i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0i0l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0i0O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0i1i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0i1l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0i1O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0iii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0iil <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0iiO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0ili <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0ill <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0ilO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0iOi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0iOl <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0iOO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0l0i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0l0l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0l0O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0l1i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0l1l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0l1O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0lii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0lil <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0liO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0lli <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0lll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0llO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0lOi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0lOl <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0lOO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0O0i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0O0l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0O0O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0O1i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0O1l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0O1O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0Oii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0Oil <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0OiO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0Oli <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0Oll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0OlO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0OOi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n0OOO <= '1' after 1 ps;
		end if;
	END PROCESS;
	wire_n0OOl_CLRN <= ((ni1iOi32 XOR ni1iOi31) AND wire_w_lg_reset97w(0));
	wire_n0OOl_w_lg_n01iO103w(0) <= NOT n01iO;
	wire_n0OOl_w_lg_n01lO104w(0) <= NOT n01lO;
	wire_n0OOl_w_lg_n0OlO67w(0) <= NOT n0OlO;
	wire_n0OOl_w_lg_n0OOi71w(0) <= NOT n0OOi;
	wire_n0OOl_w_lg_w_lg_w_lg_n001O118w122w123w(0) <= wire_n0OOl_w_lg_w_lg_n001O118w122w(0) OR ni10OO;
	wire_n0OOl_w_lg_w_lg_n001O118w122w(0) <= wire_n0OOl_w_lg_n001O118w(0) OR wire_ni1i1i40_w_lg_w_lg_q120w121w(0);
	wire_n0OOl_w_lg_n001O118w(0) <= n001O OR n001i;
	PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN
				n100i <= '1';
				n100l <= '1';
				n100O <= '1';
				n101i <= '1';
				n101l <= '1';
				n101O <= '1';
				n10ii <= '1';
				n10il <= '1';
				n10li <= '1';
				n11Oi <= '1';
				n11Ol <= '1';
				n11OO <= '1';
				nlOO1l <= '1';
		ELSIF (clk = '1' AND clk'event) THEN
				n100i <= wire_n1i1l_dataout;
				n100l <= wire_n1l0i_dataout;
				n100O <= wire_n1l0l_dataout;
				n101i <= wire_n10Ol_dataout;
				n101l <= wire_n10OO_dataout;
				n101O <= wire_n1i1i_dataout;
				n10ii <= wire_n1l0O_dataout;
				n10il <= wire_n1lii_dataout;
				n10li <= wire_n1lil_dataout;
				n11Oi <= wire_n011O_dataout;
				n11Ol <= wire_n1OiO_dataout;
				n11OO <= wire_n10Oi_dataout;
				nlOO1l <= wire_n1O1i_dataout;
		END IF;
		if (now = 0 ns) then
			n100i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n100l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n100O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n101i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n101l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n101O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n10ii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n10il <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n10li <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n11Oi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n11Ol <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			n11OO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOO1l <= '1' after 1 ps;
		end if;
	END PROCESS;
	wire_n10iO_w_lg_n100i538w(0) <= NOT n100i;
	wire_n10iO_w_lg_n100l536w(0) <= NOT n100l;
	wire_n10iO_w_lg_n100O534w(0) <= NOT n100O;
	wire_n10iO_w_lg_n101i543w(0) <= NOT n101i;
	wire_n10iO_w_lg_n101l541w(0) <= NOT n101l;
	wire_n10iO_w_lg_n101O539w(0) <= NOT n101O;
	wire_n10iO_w_lg_n10ii532w(0) <= NOT n10ii;
	wire_n10iO_w_lg_n10il530w(0) <= NOT n10il;
	wire_n10iO_w_lg_n10li529w(0) <= NOT n10li;
	wire_n10iO_w_lg_n11Oi111w(0) <= NOT n11Oi;
	wire_n10iO_w_lg_n11Ol29w(0) <= NOT n11Ol;
	wire_n10iO_w_lg_n11OO545w(0) <= NOT n11OO;
	wire_n10iO_w_lg_nlOO1l88w(0) <= NOT nlOO1l;
	PROCESS (clk, wire_n10ll_PRN, reset)
	BEGIN
		IF (wire_n10ll_PRN = '0') THEN
				n10lO <= '1';
		ELSIF (reset = '1') THEN
				n10lO <= '0';
		ELSIF (clk = '1' AND clk'event) THEN
			IF (source_ena = '1') THEN
				n10lO <= (wire_n10iO_w_lg_nlOO1l88w(0) AND ni10OO);
			END IF;
		END IF;
		if (now = 0 ns) then
			n10lO <= '1' after 1 ps;
		end if;
	END PROCESS;
	wire_n10ll_PRN <= (ni100i46 XOR ni100i45);
	PROCESS (clk, wire_n1iOl_CLRN)
	BEGIN
		IF (wire_n1iOl_CLRN = '0') THEN
				n1iOO <= '0';
				nll00i <= '0';
				nll00l <= '0';
				nll00O <= '0';
				nll01i <= '0';
				nll01l <= '0';
				nll01O <= '0';
				nll0ii <= '0';
				nll0il <= '0';
				nll0iO <= '0';
				nll0li <= '0';
				nll0ll <= '0';
				nll0lO <= '0';
				nll0Oi <= '0';
				nll0Ol <= '0';
				nll0OO <= '0';
				nll1li <= '0';
				nll1ll <= '0';
				nll1lO <= '0';
				nll1Oi <= '0';
				nll1Ol <= '0';
				nll1OO <= '0';
				nlli0i <= '0';
				nlli0l <= '0';
				nlli0O <= '0';
				nlli1i <= '0';
				nlli1l <= '0';
				nlli1O <= '0';
				nlliii <= '0';
				nlliil <= '0';
				nlliiO <= '0';
				nllili <= '0';
				nllill <= '0';
				nllilO <= '0';
				nlliOi <= '0';
				nlliOl <= '0';
				nlliOO <= '0';
				nlll0i <= '0';
				nlll0l <= '0';
				nlll0O <= '0';
				nlll1i <= '0';
				nlll1l <= '0';
				nlll1O <= '0';
				nlllii <= '0';
				nlllil <= '0';
				nllliO <= '0';
				nlllli <= '0';
				nlllll <= '0';
				nllllO <= '0';
				nlllOi <= '0';
				nlllOl <= '0';
				nlllOO <= '0';
				nllO0i <= '0';
				nllO0l <= '0';
				nllO0O <= '0';
				nllO1i <= '0';
				nllO1l <= '0';
				nllO1O <= '0';
				nllOii <= '0';
				nllOil <= '0';
				nllOiO <= '0';
				nllOli <= '0';
				nllOll <= '0';
				nllOlO <= '0';
				nllOOi <= '0';
				nllOOl <= '0';
				nllOOO <= '0';
				nlO00i <= '0';
				nlO00l <= '0';
				nlO00O <= '0';
				nlO01i <= '0';
				nlO01l <= '0';
				nlO01O <= '0';
				nlO0ii <= '0';
				nlO0il <= '0';
				nlO0iO <= '0';
				nlO0li <= '0';
				nlO0ll <= '0';
				nlO0lO <= '0';
				nlO0Oi <= '0';
				nlO0Ol <= '0';
				nlO0OO <= '0';
				nlO10i <= '0';
				nlO10l <= '0';
				nlO10O <= '0';
				nlO11i <= '0';
				nlO11l <= '0';
				nlO11O <= '0';
				nlO1ii <= '0';
				nlO1il <= '0';
				nlO1iO <= '0';
				nlO1li <= '0';
				nlO1ll <= '0';
				nlO1lO <= '0';
				nlO1Oi <= '0';
				nlO1Ol <= '0';
				nlO1OO <= '0';
				nlOi0i <= '0';
				nlOi0l <= '0';
				nlOi0O <= '0';
				nlOi1i <= '0';
				nlOi1l <= '0';
				nlOi1O <= '0';
				nlOiii <= '0';
				nlOiil <= '0';
				nlOiiO <= '0';
				nlOili <= '0';
				nlOill <= '0';
				nlOilO <= '0';
				nlOiOi <= '0';
				nlOiOl <= '0';
				nlOiOO <= '0';
				nlOl0i <= '0';
				nlOl0l <= '0';
				nlOl0O <= '0';
				nlOl1i <= '0';
				nlOl1l <= '0';
				nlOl1O <= '0';
				nlOlii <= '0';
				nlOlil <= '0';
				nlOliO <= '0';
				nlOlli <= '0';
				nlOlll <= '0';
				nlOllO <= '0';
				nlOlOi <= '0';
				nlOlOl <= '0';
				nlOlOO <= '0';
				nlOO1i <= '0';
		ELSIF (clk = '1' AND clk'event) THEN
			IF (ni01iO = '1') THEN
				n1iOO <= (nll01l XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni100O))));
				nll00i <= (nll0lO XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10ii XOR ni101l)))));
				nll00l <= (nll0Oi XOR (ni11OO XOR (ni10iO XOR (ni100O XOR (ni10ii XOR ni101O)))));
				nll00O <= (nll0Ol XOR (ni10iO XOR (ni10il XOR (ni101O XOR ni101l))));
				nll01i <= (nll0iO XOR (ni11OO XOR (ni10il XOR (ni101l XOR ni100O))));
				nll01l <= (nll0li XOR (ni101i XOR (ni10ii XOR ni10iO)));
				nll01O <= (nll0ll XOR (ni11OO XOR (ni101O XOR ni101i)));
				nll0ii <= (nll0OO XOR (ni101i XOR (ni10iO XOR (ni101l XOR ni100O))));
				nll0il <= (nlli1i XOR (ni11OO XOR (ni101i XOR (ni100O XOR ni10il))));
				nll0iO <= (nlli1l XOR (ni11OO XOR (ni10il XOR ni10iO)));
				nll0li <= (nlli1O XOR (ni101i XOR (ni10iO XOR (ni101l XOR ni100O))));
				nll0ll <= (nlli0i XOR (ni11OO XOR (ni101i XOR (ni100O XOR ni10il))));
				nll0lO <= (nlli0l XOR (ni11OO XOR (ni101i XOR (ni10il XOR (ni101l XOR ni100O)))));
				nll0Oi <= (nlli0O XOR (ni11OO XOR (ni101i XOR (ni10il XOR (ni10ii XOR ni101l)))));
				nll0Ol <= (nlliii XOR (ni11OO XOR (ni101i XOR (ni101O XOR ni101l))));
				nll0OO <= (nlliil XOR (ni11OO XOR (ni100O XOR (ni10ii XOR ni101l))));
				nll1li <= (nll01O XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni101O)))));
				nll1ll <= (nll00i XOR (ni11OO XOR (ni101i XOR (ni10il XOR (ni100O XOR (ni101O XOR ni101l))))));
				nll1lO <= (nll00l XOR (ni11OO XOR (ni10ii XOR ni101l)));
				nll1Oi <= (nll00O XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni101O))));
				nll1Ol <= (nll0ii XOR (ni101i XOR (ni10iO XOR (ni101l XOR (ni10ii XOR ni101O)))));
				nll1OO <= (nll0il XOR (ni11OO XOR (ni101i XOR (ni100O XOR (ni101O XOR ni101l)))));
				nlli0i <= (nllilO XOR (ni10iO XOR (ni10il XOR (ni101O XOR ni101l))));
				nlli0l <= (nlliOi XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni101l XOR (ni10ii XOR ni101O))))));
				nlli0O <= (nlliOl XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni101l))))));
				nlli1i <= (nlliiO XOR (ni10il XOR (ni100O XOR (ni10ii XOR ni101O))));
				nlli1l <= (nllili XOR (ni10iO XOR (ni10il XOR (ni101O XOR ni101l))));
				nlli1O <= (nllill XOR (ni10il XOR (ni100O XOR (ni10ii XOR ni101O))));
				nlliii <= (nlliOO XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10ii XOR ni10il)))));
				nlliil <= (nlll1i XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10ii XOR ni101O)))));
				nlliiO <= (nlll1l XOR (ni11OO XOR (ni101i XOR (ni101O XOR ni101l))));
				nllili <= (nlll1O XOR (ni11OO XOR (ni100O XOR (ni10ii XOR ni101l))));
				nllill <= (nlll0i XOR (ni101l XOR ni11OO));
				nllilO <= (ni100O XOR nlll0l);
				nlliOi <= (nlll0O XOR (ni11OO XOR (ni10il XOR (ni10ii XOR ni101l))));
				nlliOl <= (nlllii XOR (ni11OO XOR (ni10iO XOR (ni100O XOR (ni101O XOR ni101l)))));
				nlliOO <= (nlllil XOR (ni11OO XOR (ni101i XOR (ni100O XOR ni10il))));
				nlll0i <= (nllllO XOR (ni10iO XOR (ni10il XOR (ni101l XOR (ni10ii XOR ni101O)))));
				nlll0l <= (nlllOi XOR (ni101i XOR (ni10iO XOR (ni100O XOR (ni101O XOR ni101l)))));
				nlll0O <= (nlllOl XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni101O XOR ni100O)))));
				nlll1i <= (nllliO XOR (ni11OO XOR (ni10il XOR ni10iO)));
				nlll1l <= (nlllli XOR (ni101i XOR (ni10ii XOR ni10iO)));
				nlll1O <= (nlllll XOR (ni11OO XOR (ni101O XOR ni101i)));
				nlllii <= (nlllOO XOR (ni11OO XOR (ni101i XOR (ni101O XOR ni10iO))));
				nlllil <= (nllO1i XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni101O))))));
				nllliO <= (nllO1l XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni101O XOR ni101l)))));
				nlllli <= (nllO1O XOR (ni11OO XOR (ni101i XOR (ni100O XOR (ni10ii XOR ni101l)))));
				nlllll <= (nllO0i XOR (ni11OO XOR (ni10il XOR (ni100O XOR (ni10ii XOR ni101O)))));
				nllllO <= (nllO0l XOR (ni11OO XOR (ni101i XOR (ni10il XOR ni10iO))));
				nlllOi <= (nllO0O XOR (ni11OO XOR (ni101i XOR (ni10ii XOR ni10iO))));
				nlllOl <= (nllOii XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni101O))));
				nlllOO <= (nllOil XOR (ni11OO XOR (ni10il XOR (ni101l XOR (ni10ii XOR ni101O)))));
				nllO0i <= (nllOlO XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni100O XOR ni10il)))));
				nllO0l <= (ni10iO XOR nllOOi);
				nllO0O <= (ni101i XOR nllOOl);
				nllO1i <= (nllOiO XOR (ni11OO XOR (ni101i XOR (ni10il XOR (ni100O XOR (ni101l XOR (ni10ii XOR ni101O)))))));
				nllO1l <= (nllOli XOR (ni11OO XOR (ni10iO XOR (ni10il XOR (ni100O XOR (ni101O XOR ni101l))))));
				nllO1O <= (nllOll XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni101l XOR ni100O)))));
				nllOii <= (nllOOO XOR (ni10iO XOR ni11OO));
				nllOil <= (nlO11i XOR (ni101i XOR (ni10ii XOR ni10iO)));
				nllOiO <= (nlO11l XOR (ni11OO XOR (ni101i XOR (ni101O XOR ni10iO))));
				nllOli <= (nlO11O XOR (ni11OO XOR (ni101l XOR ni101i)));
				nllOll <= (nlO10i XOR (ni100O XOR ni11OO));
				nllOlO <= (ni10il XOR nlO10l);
				nllOOi <= (nlO10O XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni100O XOR (ni10ii XOR ni101O))))));
				nllOOl <= (nlO1ii XOR (ni11OO XOR (ni101i XOR (ni10il XOR (ni101l XOR (ni10ii XOR ni101O))))));
				nllOOO <= (nlO1il XOR (ni101l XOR ni101i));
				nlO00i <= (nlO0lO XOR (ni11OO XOR (ni10il XOR (ni10ii XOR ni101l))));
				nlO00l <= (nlO0Oi XOR (ni10iO XOR (ni101O XOR ni100O)));
				nlO00O <= (nlO0Ol XOR (ni101i XOR (ni101l XOR ni10il)));
				nlO01i <= (nlO0iO XOR (ni101l XOR ni100O));
				nlO01l <= (nlO0li XOR (ni11OO XOR (ni10iO XOR (ni10ii XOR ni10il))));
				nlO01O <= (nlO0ll XOR (ni11OO XOR (ni101i XOR (ni101O XOR ni100O))));
				nlO0ii <= (nlO0OO XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni100O XOR (ni101l XOR (ni10ii XOR ni101O)))))));
				nlO0il <= (nlOi1i XOR (ni11OO XOR (ni101i XOR (ni10il XOR (ni100O XOR (ni101O XOR ni101l))))));
				nlO0iO <= (nlOi1l XOR (ni101i XOR (ni10il XOR (ni10ii XOR ni101O))));
				nlO0li <= (nlOi1O XOR (ni100O XOR ni101i));
				nlO0ll <= (nlOi0i XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni100O XOR (ni101O XOR ni101l))))));
				nlO0lO <= (nlOi0l XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni100O XOR (ni10ii XOR ni101l)))))));
				nlO0Oi <= (nlOi0O XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni100O XOR (ni10ii XOR ni101O)))))));
				nlO0Ol <= (nlOiii XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni101l XOR (ni10ii XOR ni101O)))))));
				nlO0OO <= (nlOiil XOR (ni11OO XOR (ni101i XOR (ni101l XOR ni100O))));
				nlO10i <= (nlO1lO XOR (ni11OO XOR (ni10iO XOR (ni10il XOR (ni101O XOR ni100O)))));
				nlO10l <= (nlO1Oi XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni101l)))));
				nlO10O <= (nlO1Ol XOR (ni11OO XOR (ni101i XOR (ni10ii XOR ni101l))));
				nlO11i <= (nlO1iO XOR (ni101i XOR (ni101O XOR ni10iO)));
				nlO11l <= (nlO1li XOR (ni10iO XOR (ni100O XOR (ni101O XOR ni101l))));
				nlO11O <= (nlO1ll XOR (ni101i XOR (ni10il XOR (ni100O XOR (ni10ii XOR ni101l)))));
				nlO1ii <= (nlO1OO XOR (ni11OO XOR (ni101O XOR ni100O)));
				nlO1il <= (nlO01i XOR (ni11OO XOR (ni10il XOR ni101i)));
				nlO1iO <= (nlO01l XOR (ni101i XOR (ni101l XOR ni10iO)));
				nlO1li <= (nlO01O XOR (ni101l XOR ni100O));
				nlO1ll <= (nlO00i XOR (ni100O XOR ni10il));
				nlO1lO <= (nlO00l XOR (ni10iO XOR (ni10ii XOR ni10il)));
				nlO1Oi <= (nlO00O XOR (ni101i XOR (ni101O XOR ni10iO)));
				nlO1Ol <= (nlO0ii XOR (ni11OO XOR (ni10iO XOR (ni10ii XOR ni100O))));
				nlO1OO <= (nlO0il XOR (ni101i XOR (ni101O XOR ni10il)));
				nlOi0i <= (nlOilO XOR (ni11OO XOR (ni10iO XOR (ni101l XOR ni100O))));
				nlOi0l <= (nlOiOi XOR (ni101i XOR (ni10il XOR (ni10ii XOR ni100O))));
				nlOi0O <= (nlOiOl XOR (ni11OO XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni101O)))));
				nlOi1i <= (nlOiiO XOR (ni11OO XOR (ni10il XOR (ni10ii XOR ni100O))));
				nlOi1l <= (nlOili XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni100O XOR (ni101O XOR ni101l)))))));
				nlOi1O <= (nlOill XOR (ni10il XOR ni10iO));
				nlOiii <= (nlOiOO XOR (ni101i XOR (ni10iO XOR (ni101O XOR ni101l))));
				nlOiil <= (nlOl1i XOR (ni100O XOR ni10il));
				nlOiiO <= (nlOl1l XOR (ni10iO XOR (ni10ii XOR ni10il)));
				nlOili <= (nlOl1O XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni101O XOR ni100O)))));
				nlOill <= (nlOl0i XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni101l XOR ni100O)))));
				nlOilO <= (nlOl0l XOR (ni11OO XOR (ni10ii XOR ni101i)));
				nlOiOi <= (nlOl0O XOR (ni11OO XOR (ni10ii XOR ni101O)));
				nlOiOl <= (nlOlii XOR (ni101O XOR ni101l));
				nlOiOO <= (nlOlil XOR (ni101l XOR ni100O));
				nlOl0i <= (nlOllO XOR (ni10il XOR (ni101O XOR ni100O)));
				nlOl0l <= (nlOlOi XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni101l XOR ni100O))))));
				nlOl0O <= (nlOlOl XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni100O))))));
				nlOl1i <= (nlOliO XOR (ni11OO XOR (ni100O XOR ni101i)));
				nlOl1l <= (nlOlli XOR (ni10il XOR ni11OO));
				nlOl1O <= (nlOlll XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni10ii XOR ni100O)))));
				nlOlii <= (nlOlOO XOR (ni11OO XOR (ni101i XOR (ni10iO XOR (ni101O XOR ni10il)))));
				nlOlil <= (nlOO1i XOR (ni11OO XOR (ni101i XOR (ni101l XOR ni10iO))));
				nlOliO <= (ni10iO XOR (ni10il XOR (ni10ii XOR ni100O)));
				nlOlli <= (ni101i XOR (ni10iO XOR (ni10il XOR (ni10ii XOR ni101O))));
				nlOlll <= (ni11OO XOR (ni101i XOR (ni10il XOR (ni100O XOR (ni101O XOR ni101l)))));
				nlOllO <= (ni11OO XOR (ni10ii XOR ni101l));
				nlOlOi <= (ni10iO XOR (ni10il XOR (ni10ii XOR ni101O)));
				nlOlOl <= (ni101i XOR (ni10iO XOR (ni101l XOR (ni10ii XOR ni101O))));
				nlOlOO <= (ni11OO XOR (ni101i XOR (ni100O XOR (ni101O XOR ni101l))));
				nlOO1i <= (ni11OO XOR (ni10il XOR (ni101l XOR ni100O)));
			END IF;
		END IF;
		if (now = 0 ns) then
			n1iOO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll00i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll00l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll00O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll01i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll01l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll01O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0ii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0il <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0iO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0li <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0ll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0lO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0Oi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0Ol <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll0OO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll1li <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll1ll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll1lO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll1Oi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll1Ol <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nll1OO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlli0i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlli0l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlli0O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlli1i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlli1l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlli1O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlliii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlliil <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlliiO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllili <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllill <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllilO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlliOi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlliOl <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlliOO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlll0i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlll0l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlll0O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlll1i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlll1l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlll1O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlllii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlllil <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllliO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlllli <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlllll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllllO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlllOi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlllOl <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlllOO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllO0i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllO0l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllO0O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllO1i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllO1l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllO1O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOil <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOiO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOli <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOlO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOOi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOOl <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nllOOO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO00i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO00l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO00O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO01i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO01l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO01O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0ii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0il <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0iO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0li <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0ll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0lO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0Oi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0Ol <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO0OO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO10i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO10l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO10O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO11i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO11l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO11O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1ii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1il <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1iO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1li <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1ll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1lO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1Oi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1Ol <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlO1OO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOi0i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOi0l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOi0O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOi1i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOi1l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOi1O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOiii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOiil <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOiiO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOili <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOill <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOilO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOiOi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOiOl <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOiOO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOl0i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOl0l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOl0O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOl1i <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOl1l <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOl1O <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOlii <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOlil <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOliO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOlli <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOlll <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOllO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOlOi <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOlOl <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOlOO <= '1' after 1 ps;
		end if;
		if (now = 0 ns) then
			nlOO1i <= '1' after 1 ps;
		end if;
	END PROCESS;
	wire_n1iOl_CLRN <= ((ni100l44 XOR ni100l43) AND wire_w_lg_reset97w(0));
	wire_n00i_dataout <= wire_n0lO_dataout AND NOT(ni011l);
	wire_n00l_dataout <= wire_n0Oi_dataout AND NOT(ni011l);
	wire_n00O_dataout <= wire_n0Ol_dataout AND NOT(ni011l);
	wire_n010i_dataout <= n11Oi OR ni1ill;
	wire_n011O_dataout <= wire_n010i_dataout AND NOT((wire_w_lg_w_lg_source_ena43w99w(0) AND (ni1iil34 XOR ni1iil33)));
	wire_n01i_dataout <= wire_n0iO_dataout AND NOT(ni011l);
	wire_n01l_dataout <= wire_n0li_dataout AND NOT(ni011l);
	wire_n01O_dataout <= wire_n0ll_dataout AND NOT(ni011l);
	wire_n0ii_dataout <= n000O WHEN ni1Oll = '1'  ELSE wire_n0OO_dataout;
	wire_n0il_dataout <= n00ii WHEN ni1Oll = '1'  ELSE wire_ni1i_dataout;
	wire_n0iO_dataout <= n00il WHEN ni1Oll = '1'  ELSE wire_ni1l_dataout;
	wire_n0li_dataout <= n00iO WHEN ni1Oll = '1'  ELSE wire_ni1O_dataout;
	wire_n0ll_dataout <= n00li WHEN ni1Oll = '1'  ELSE wire_ni0i_dataout;
	wire_n0lO_dataout <= n00ll WHEN ni1Oll = '1'  ELSE wire_ni0l_dataout;
	wire_n0Oi_dataout <= n00lO WHEN ni1Oll = '1'  ELSE wire_ni0O_dataout;
	wire_n0Ol_dataout <= n00Oi WHEN ni1Oll = '1'  ELSE wire_niii_dataout;
	wire_n0OO_dataout <= n0iOO AND NOT(wire_w_lg_source_ena43w(0));
	wire_n10i_dataout <= n01OO WHEN ni1Oll = '1'  ELSE wire_n10l_dataout;
	wire_n10l_dataout <= n001O AND NOT(wire_w_lg_source_ena43w(0));
	wire_n10O_dataout <= rsin(0) WHEN ni010l = '1'  ELSE wire_n1Ol_dataout;
	wire_n10Oi_dataout <= wire_n1i1O_dataout OR ni10ll;
	wire_n10Ol_dataout <= wire_n1i0i_dataout OR ni10ll;
	wire_n10OO_dataout <= wire_n1i0l_dataout OR ni10ll;
	wire_n11i_dataout <= n01lO AND source_ena;
	wire_n11l_dataout <= sink_sop WHEN ni010l = '1'  ELSE wire_n11O_dataout;
	wire_n11O_dataout <= wire_n10i_dataout AND NOT(ni011l);
	wire_n1i0i_dataout <= wire_n1l1i_o(2) WHEN ni10li = '1'  ELSE wire_n1iiO_dataout;
	wire_n1i0l_dataout <= wire_n1l1i_o(3) WHEN ni10li = '1'  ELSE wire_n1ili_dataout;
	wire_n1i0O_dataout <= wire_n1l1i_o(4) WHEN ni10li = '1'  ELSE wire_n1ill_dataout;
	wire_n1i1i_dataout <= wire_n1i0O_dataout OR ni10ll;
	wire_n1i1l_dataout <= wire_n1iii_dataout AND NOT(ni10ll);
	wire_n1i1O_dataout <= wire_n1l1i_o(1) WHEN ni10li = '1'  ELSE wire_n1iil_dataout;
	wire_n1ii_dataout <= rsin(1) WHEN ni010l = '1'  ELSE wire_n1OO_dataout;
	wire_n1iii_dataout <= wire_n1l1i_o(5) WHEN ni10li = '1'  ELSE wire_n1ilO_dataout;
	wire_n1iil_dataout <= wire_n1iOi_o(1) WHEN ni01li = '1'  ELSE n11OO;
	wire_n1iiO_dataout <= wire_n1iOi_o(2) WHEN ni01li = '1'  ELSE n101i;
	wire_n1il_dataout <= rsin(2) WHEN ni010l = '1'  ELSE wire_n01i_dataout;
	wire_n1ili_dataout <= wire_n1iOi_o(3) WHEN ni01li = '1'  ELSE n101l;
	wire_n1ill_dataout <= wire_n1iOi_o(4) WHEN ni01li = '1'  ELSE n101O;
	wire_n1ilO_dataout <= wire_n1iOi_o(5) WHEN ni01li = '1'  ELSE n100i;
	wire_n1iO_dataout <= rsin(3) WHEN ni010l = '1'  ELSE wire_n01l_dataout;
	wire_n1l0i_dataout <= wire_n1liO_dataout OR ni10lO;
	wire_n1l0l_dataout <= wire_n1lli_dataout OR ni10lO;
	wire_n1l0O_dataout <= wire_n1lll_dataout OR ni10lO;
	wire_n1li_dataout <= rsin(4) WHEN ni010l = '1'  ELSE wire_n01O_dataout;
	wire_n1lii_dataout <= wire_n1llO_dataout OR ni10lO;
	wire_n1lil_dataout <= wire_n1lOi_dataout AND NOT(ni10lO);
	wire_n1liO_dataout <= wire_n1lOl_o(1) WHEN ni1Oil = '1'  ELSE n100l;
	wire_n1ll_dataout <= rsin(5) WHEN ni010l = '1'  ELSE wire_n00i_dataout;
	wire_n1lli_dataout <= wire_n1lOl_o(2) WHEN ni1Oil = '1'  ELSE n100O;
	wire_n1lll_dataout <= wire_n1lOl_o(3) WHEN ni1Oil = '1'  ELSE n10ii;
	wire_n1llO_dataout <= wire_n1lOl_o(4) WHEN ni1Oil = '1'  ELSE n10il;
	wire_n1lO_dataout <= rsin(6) WHEN ni010l = '1'  ELSE wire_n00l_dataout;
	wire_n1lOi_dataout <= wire_n1lOl_o(5) WHEN ni1Oil = '1'  ELSE n10li;
	wire_n1O1i_dataout <= wire_n1O1l_dataout AND NOT((source_ena AND (n01Oi OR n01ll)));
	wire_n1O1l_dataout <= nlOO1l OR (source_ena AND ((wire_n0OOl_w_lg_w_lg_w_lg_n001O118w122w123w(0) OR (NOT (ni10Oi42 XOR ni10Oi41))) AND wire_n10iO_w_lg_nlOO1l88w(0)));
	wire_n1Oi_dataout <= rsin(7) WHEN ni010l = '1'  ELSE wire_n00O_dataout;
	wire_n1OiO_dataout <= wire_n1Oli_dataout AND NOT((source_ena AND ni1ili));
	wire_n1Ol_dataout <= wire_n0ii_dataout AND NOT(ni011l);
	wire_n1Oli_dataout <= wire_n1Oll_dataout AND NOT(ni1ill);
	wire_n1Oll_dataout <= n11Ol OR ((source_ena AND ni1i0l) AND (ni1i1O38 XOR ni1i1O37));
	wire_n1OO_dataout <= wire_n0il_dataout AND NOT(ni011l);
	wire_ni00i_dataout <= n0iOi AND NOT(ni1lll);
	wire_ni00l_dataout <= n0iOl AND NOT(ni1lll);
	wire_ni00O_dataout <= wire_ni0ii_dataout OR ni1iOl;
	wire_ni01i_dataout <= n0ili AND NOT(ni1lll);
	wire_ni01l_dataout <= n0ill AND NOT(ni1lll);
	wire_ni01O_dataout <= n0ilO AND NOT(ni1lll);
	wire_ni0i_dataout <= n0l0i AND NOT(wire_w_lg_source_ena43w(0));
	wire_ni0ii_dataout <= n0Oll AND NOT(ni1lll);
	wire_ni0iO_dataout <= n0lil WHEN ni1lii = '1'  ELSE wire_nii1l_dataout;
	wire_ni0l_dataout <= n0l0l AND NOT(wire_w_lg_source_ena43w(0));
	wire_ni0li_dataout <= n0liO WHEN ni1lii = '1'  ELSE wire_nii1O_dataout;
	wire_ni0ll_dataout <= n0lli WHEN ni1lii = '1'  ELSE wire_nii0i_dataout;
	wire_ni0lO_dataout <= n0lll WHEN ni1lii = '1'  ELSE wire_nii0l_dataout;
	wire_ni0O_dataout <= n0l0O AND NOT(wire_w_lg_source_ena43w(0));
	wire_ni0Oi_dataout <= n0llO WHEN ni1lii = '1'  ELSE wire_nii0O_dataout;
	wire_ni0Ol_dataout <= n0lOi WHEN ni1lii = '1'  ELSE wire_niiii_dataout;
	wire_ni0OO_dataout <= n0lOl WHEN ni1lii = '1'  ELSE wire_niiil_dataout;
	wire_ni10i_dataout <= n001l AND NOT(ni1lll);
	wire_ni10l_dataout <= n0lil WHEN ni1iOl = '1'  ELSE wire_ni1Oi_dataout;
	wire_ni10O_dataout <= n0liO WHEN ni1iOl = '1'  ELSE wire_ni1Ol_dataout;
	wire_ni11i_dataout <= n01Oi WHEN ni1iOl = '1'  ELSE wire_ni11l_dataout;
	wire_ni11l_dataout <= n01ll AND NOT(ni1lll);
	wire_ni11O_dataout <= n000i WHEN ni1iOl = '1'  ELSE wire_ni10i_dataout;
	wire_ni1i_dataout <= n0l1i AND NOT(wire_w_lg_source_ena43w(0));
	wire_ni1ii_dataout <= n0lli WHEN ni1iOl = '1'  ELSE wire_ni1OO_dataout;
	wire_ni1il_dataout <= n0lll WHEN ni1iOl = '1'  ELSE wire_ni01i_dataout;
	wire_ni1iO_dataout <= n0llO WHEN ni1iOl = '1'  ELSE wire_ni01l_dataout;
	wire_ni1l_dataout <= n0l1l AND NOT(wire_w_lg_source_ena43w(0));
	wire_ni1li_dataout <= n0lOi WHEN ni1iOl = '1'  ELSE wire_ni01O_dataout;
	wire_ni1ll_dataout <= n0lOl WHEN ni1iOl = '1'  ELSE wire_ni00i_dataout;
	wire_ni1lO_dataout <= n0lOO WHEN ni1iOl = '1'  ELSE wire_ni00l_dataout;
	wire_ni1O_dataout <= n0l1O AND NOT(wire_w_lg_source_ena43w(0));
	wire_ni1Oi_dataout <= n0iii AND NOT(ni1lll);
	wire_ni1Ol_dataout <= n0iil AND NOT(ni1lll);
	wire_ni1OO_dataout <= n0iiO AND NOT(ni1lll);
	wire_nii0i_dataout <= n0iiO WHEN ni1l0i = '1'  ELSE wire_niilO_dataout;
	wire_nii0l_dataout <= n0ili WHEN ni1l0i = '1'  ELSE wire_niiOi_dataout;
	wire_nii0O_dataout <= n0ill WHEN ni1l0i = '1'  ELSE wire_niiOl_dataout;
	wire_nii1i_dataout <= n0lOO WHEN ni1lii = '1'  ELSE wire_niiiO_dataout;
	wire_nii1l_dataout <= n0iii WHEN ni1l0i = '1'  ELSE wire_niili_dataout;
	wire_nii1O_dataout <= n0iil WHEN ni1l0i = '1'  ELSE wire_niill_dataout;
	wire_niii_dataout <= n0lii AND NOT(wire_w_lg_source_ena43w(0));
	wire_niiii_dataout <= n0ilO WHEN ni1l0i = '1'  ELSE wire_niiOO_dataout;
	wire_niiil_dataout <= n0iOi WHEN ni1l0i = '1'  ELSE wire_nil1i_dataout;
	wire_niiiO_dataout <= n0iOl WHEN ni1l0i = '1'  ELSE wire_nil1l_dataout;
	wire_niil_dataout <= wire_niiO_dataout OR ni010l;
	wire_niili_dataout <= n1iOO WHEN ni01li = '1'  ELSE n0O1i;
	wire_niill_dataout <= nll1li WHEN ni01li = '1'  ELSE n0O1l;
	wire_niilO_dataout <= nll1ll WHEN ni01li = '1'  ELSE n0O1O;
	wire_niiO_dataout <= wire_nili_dataout AND NOT(ni011l);
	wire_niiOi_dataout <= nll1lO WHEN ni01li = '1'  ELSE n0O0i;
	wire_niiOl_dataout <= nll1Oi WHEN ni01li = '1'  ELSE n0O0l;
	wire_niiOO_dataout <= nll1Ol WHEN ni01li = '1'  ELSE n0O0O;
	wire_nil1i_dataout <= nll1OO WHEN ni01li = '1'  ELSE n0Oii;
	wire_nil1l_dataout <= nll01i WHEN ni01li = '1'  ELSE n0Oil;
	wire_nili_dataout <= n0OiO WHEN ni1Oll = '1'  ELSE wire_nill_dataout;
	wire_nilil_dataout <= n01Oi WHEN ni1lli = '1'  ELSE wire_niliO_dataout;
	wire_niliO_dataout <= n01ll WHEN ni1lll = '1'  ELSE wire_nilli_dataout;
	wire_nill_dataout <= n0OlO AND NOT(wire_w_lg_source_ena43w(0));
	wire_nilli_dataout <= n01Ol AND NOT(ni1llO);
	wire_nilll_dataout <= n000i WHEN ni1lli = '1'  ELSE wire_nillO_dataout;
	wire_nillO_dataout <= n001l WHEN ni1lll = '1'  ELSE wire_nilOi_dataout;
	wire_nilOi_dataout <= n000l AND NOT(ni1llO);
	wire_nilOl_dataout <= wire_nilOO_dataout OR ni1lli;
	wire_nilOO_dataout <= n0Oll WHEN ni1lll = '1'  ELSE wire_niO1i_dataout;
	wire_niO0l_dataout <= n01lO WHEN ni1lOO = '1'  ELSE wire_niO0O_dataout;
	wire_niO0O_dataout <= n01li AND NOT(ni1O1i);
	wire_niO1i_dataout <= n0OOO AND NOT(ni1llO);
	wire_niOii_dataout <= n001O WHEN ni1lOO = '1'  ELSE wire_niOil_dataout;
	wire_niOil_dataout <= n001i AND NOT(ni1O1i);
	wire_niOiO_dataout <= n0iOO WHEN ni1lOO = '1'  ELSE wire_nl11l_dataout;
	wire_niOli_dataout <= n0l1i WHEN ni1lOO = '1'  ELSE wire_nl11O_dataout;
	wire_niOll_dataout <= n0l1l WHEN ni1lOO = '1'  ELSE wire_nl10i_dataout;
	wire_niOlO_dataout <= n0l1O WHEN ni1lOO = '1'  ELSE wire_nl10l_dataout;
	wire_niOOi_dataout <= n0l0i WHEN ni1lOO = '1'  ELSE wire_nl10O_dataout;
	wire_niOOl_dataout <= n0l0l WHEN ni1lOO = '1'  ELSE wire_nl1ii_dataout;
	wire_niOOO_dataout <= n0l0O WHEN ni1lOO = '1'  ELSE wire_nl1il_dataout;
	wire_nl00i_dataout <= n0iOO WHEN ni1O1l = '1'  ELSE wire_nl0lO_dataout;
	wire_nl00l_dataout <= n0l1i WHEN ni1O1l = '1'  ELSE wire_nl0Oi_dataout;
	wire_nl00O_dataout <= n0l1l WHEN ni1O1l = '1'  ELSE wire_nl0Ol_dataout;
	wire_nl01i_dataout <= n001O WHEN ni1O1l = '1'  ELSE wire_nl01l_dataout;
	wire_nl01l_dataout <= n001i WHEN ni1O1i = '1'  ELSE wire_nl01O_dataout;
	wire_nl01O_dataout <= n000i AND NOT(wire_w_lg_source_ena43w(0));
	wire_nl0ii_dataout <= n0l1O WHEN ni1O1l = '1'  ELSE wire_nl0OO_dataout;
	wire_nl0il_dataout <= n0l0i WHEN ni1O1l = '1'  ELSE wire_nli1i_dataout;
	wire_nl0iO_dataout <= n0l0l WHEN ni1O1l = '1'  ELSE wire_nli1l_dataout;
	wire_nl0li_dataout <= n0l0O WHEN ni1O1l = '1'  ELSE wire_nli1O_dataout;
	wire_nl0ll_dataout <= n0lii WHEN ni1O1l = '1'  ELSE wire_nli0i_dataout;
	wire_nl0lO_dataout <= n00Ol WHEN ni1O1i = '1'  ELSE wire_nli0l_dataout;
	wire_nl0Oi_dataout <= n00OO WHEN ni1O1i = '1'  ELSE wire_nli0O_dataout;
	wire_nl0Ol_dataout <= n0i1i WHEN ni1O1i = '1'  ELSE wire_nliii_dataout;
	wire_nl0OO_dataout <= n0i1l WHEN ni1O1i = '1'  ELSE wire_nliil_dataout;
	wire_nl10i_dataout <= n0i1i AND NOT(ni1O1i);
	wire_nl10l_dataout <= n0i1l AND NOT(ni1O1i);
	wire_nl10O_dataout <= n0i1O AND NOT(ni1O1i);
	wire_nl11i_dataout <= n0lii WHEN ni1lOO = '1'  ELSE wire_nl1iO_dataout;
	wire_nl11l_dataout <= n00Ol AND NOT(ni1O1i);
	wire_nl11O_dataout <= n00OO AND NOT(ni1O1i);
	wire_nl1ii_dataout <= n0i0i AND NOT(ni1O1i);
	wire_nl1il_dataout <= n0i0l AND NOT(ni1O1i);
	wire_nl1iO_dataout <= n0i0O AND NOT(ni1O1i);
	wire_nl1li_dataout <= wire_nl1ll_dataout OR ni1lOO;
	wire_nl1ll_dataout <= n0Oli AND NOT(ni1O1i);
	wire_nl1Oi_dataout <= n01lO WHEN ni1O1l = '1'  ELSE wire_nl1Ol_dataout;
	wire_nl1Ol_dataout <= n01li WHEN ni1O1i = '1'  ELSE wire_nl1OO_dataout;
	wire_nl1OO_dataout <= n01Oi AND NOT(wire_w_lg_source_ena43w(0));
	wire_nli0i_dataout <= n0i0O WHEN ni1O1i = '1'  ELSE wire_nlilO_dataout;
	wire_nli0l_dataout <= n0lil AND NOT(wire_w_lg_source_ena43w(0));
	wire_nli0O_dataout <= n0liO AND NOT(wire_w_lg_source_ena43w(0));
	wire_nli1i_dataout <= n0i1O WHEN ni1O1i = '1'  ELSE wire_nliiO_dataout;
	wire_nli1l_dataout <= n0i0i WHEN ni1O1i = '1'  ELSE wire_nlili_dataout;
	wire_nli1O_dataout <= n0i0l WHEN ni1O1i = '1'  ELSE wire_nlill_dataout;
	wire_nliii_dataout <= n0lli AND NOT(wire_w_lg_source_ena43w(0));
	wire_nliil_dataout <= n0lll AND NOT(wire_w_lg_source_ena43w(0));
	wire_nliiO_dataout <= n0llO AND NOT(wire_w_lg_source_ena43w(0));
	wire_nlili_dataout <= n0lOi AND NOT(wire_w_lg_source_ena43w(0));
	wire_nlill_dataout <= n0lOl AND NOT(wire_w_lg_source_ena43w(0));
	wire_nlilO_dataout <= n0lOO AND NOT(wire_w_lg_source_ena43w(0));
	wire_nliOi_dataout <= wire_nliOl_dataout OR ni1O1l;
	wire_nliOl_dataout <= n0Oli WHEN ni1O1i = '1'  ELSE wire_nliOO_dataout;
	wire_nliOO_dataout <= n0OOi AND NOT(wire_w_lg_source_ena43w(0));
	wire_nll0i_dataout <= n01iO AND NOT(ni1Oll);
	wire_nll0l_dataout <= sink_sop WHEN ni1O1O = '1'  ELSE wire_nll0O_dataout;
	wire_nll0O_dataout <= n01OO AND NOT(ni1Oll);
	wire_nll1O_dataout <= sink_eop WHEN ni1O1O = '1'  ELSE wire_nll0i_dataout;
	wire_nllii_dataout <= rsin(0) WHEN ni1O1O = '1'  ELSE wire_nllOO_dataout;
	wire_nllil_dataout <= rsin(1) WHEN ni1O1O = '1'  ELSE wire_nlO1i_dataout;
	wire_nlliO_dataout <= rsin(2) WHEN ni1O1O = '1'  ELSE wire_nlO1l_dataout;
	wire_nllli_dataout <= rsin(3) WHEN ni1O1O = '1'  ELSE wire_nlO1O_dataout;
	wire_nllll_dataout <= rsin(4) WHEN ni1O1O = '1'  ELSE wire_nlO0i_dataout;
	wire_nlllO_dataout <= rsin(5) WHEN ni1O1O = '1'  ELSE wire_nlO0l_dataout;
	wire_nllOi_dataout <= rsin(6) WHEN ni1O1O = '1'  ELSE wire_nlO0O_dataout;
	wire_nllOl_dataout <= rsin(7) WHEN ni1O1O = '1'  ELSE wire_nlOii_dataout;
	wire_nllOO_dataout <= n000O AND NOT(ni1Oll);
	wire_nlO0i_dataout <= n00li AND NOT(ni1Oll);
	wire_nlO0l_dataout <= n00ll AND NOT(ni1Oll);
	wire_nlO0O_dataout <= n00lO AND NOT(ni1Oll);
	wire_nlO1i_dataout <= n00ii AND NOT(ni1Oll);
	wire_nlO1l_dataout <= n00il AND NOT(ni1Oll);
	wire_nlO1O_dataout <= n00iO AND NOT(ni1Oll);
	wire_nlOii_dataout <= n00Oi AND NOT(ni1Oll);
	wire_nlOil_dataout <= wire_nlOiO_dataout OR ni1O1O;
	wire_nlOiO_dataout <= n0OiO AND NOT(ni1Oll);
	wire_nlOOl_dataout <= sink_eop WHEN ni01il = '1'  ELSE wire_nlOOO_dataout;
	wire_nlOOO_dataout <= n01iO WHEN ni1OOl = '1'  ELSE wire_n11i_dataout;
	wire_n1iOi_a <= ( n100i & n101O & n101l & n101i & n11OO & "1");
	wire_n1iOi_b <= ( "1" & "1" & "1" & "1" & "0" & "1");
	n1iOi :  oper_add
	  GENERIC MAP (
		sgate_representation => 0,
		width_a => 6,
		width_b => 6,
		width_o => 6
	  )
	  PORT MAP ( 
		a => wire_n1iOi_a,
		b => wire_n1iOi_b,
		cin => wire_gnd,
		o => wire_n1iOi_o
	  );
	wire_n1l1i_a <= ( "0" & "1" & "1" & "1" & "1" & "1");
	wire_n1l1i_b <= ( "1" & "1" & "1" & "1" & "0" & "1");
	n1l1i :  oper_add
	  GENERIC MAP (
		sgate_representation => 0,
		width_a => 6,
		width_b => 6,
		width_o => 6
	  )
	  PORT MAP ( 
		a => wire_n1l1i_a,
		b => wire_n1l1i_b,
		cin => wire_gnd,
		o => wire_n1l1i_o
	  );
	wire_n1lOl_a <= ( n10li & n10il & n10ii & n100O & n100l & "1");
	wire_n1lOl_b <= ( "1" & "1" & "1" & "1" & "0" & "1");
	n1lOl :  oper_add
	  GENERIC MAP (
		sgate_representation => 0,
		width_a => 6,
		width_b => 6,
		width_o => 6
	  )
	  PORT MAP ( 
		a => wire_n1lOl_a,
		b => wire_n1lOl_b,
		cin => wire_gnd,
		o => wire_n1lOl_o
	  );

 END RTL; --rs_encoder
--synopsys translate_on
--VALID FILE
