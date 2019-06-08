---------------------------------------------------------------------------
--   File Name : dvbt_core.vhd
---------------------------------------------------------------------------
--  Copyright (C) 2010 Juan Gago
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License version 2 as
--  published by the Free Software Foundation.
--
---------------------------------------------------------------------------
-- DESCRIPTION:
--					 _ _ _ _ _ _ _ 
--		hpfec	->	|	    	   |	-> I	
--					|qam, ofdm, gi | 
-- 		lpfec	-> 	|_ _ _ _ _ _ _ |	-> Q	
--
---------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library WORK;
use WORK.mypackage.all;

entity dvbt_core is
	port ( 	ce			: IN  std_logic;
			reset_n		: IN  std_logic;
			clk			: IN  std_logic;
--			pps_mod		: IN  std_logic;
			spi_data 	: IN  std_logic_vector(7 downto 0);
			spi_dvalid	: IN  std_logic;
			spi_rdy 	: OUT std_logic;
			spi_sop		: IN  std_logic;
			spi_eop		: IN  std_logic;
--			status 		: OUT std_logic_vector(3 downto 0);
			xn_rdy		: IN  std_logic;
			xn_val		: OUT std_logic;
			xn_sop		: OUT std_logic;
			xn_eop		: OUT std_logic;
			xn_index	: OUT std_logic_vector(12 downto 0);
			xn_re		: OUT std_logic_vector(15 downto 0);
			xn_im	 	: OUT std_logic_vector(15 downto 0)					
	);
end dvbt_core;

architecture Behavioral of dvbt_core is
	
	COMPONENT coding
	 Generic	(	
		FEC 		: natural := 34;
		Irate		: integer := 3;
		Orate		: integer := 4);
	PORT(
		clk			: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		sink_rdy 	: out STD_LOGIC;
		sink_byte 	: in  STD_LOGIC_VECTOR(7 downto 0);
		sink_val	: in  STD_LOGIC;
		sink_sop	: in  STD_LOGIC;
		sink_eop	: in  STD_LOGIC;
		source_bit 	: out STD_LOGIC; 
		source_val	: out STD_LOGIC;
		source_sop	: out STD_LOGIC;
		source_eop 	: out STD_LOGIC
		);
	END COMPONENT;

	COMPONENT resampler 
	PORT( 
		clk	 		: in  STD_LOGIC;
		reset_n 	: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;		
		sink_bit 	: in  STD_LOGIC;
		sink_val 	: in  STD_LOGIC;
--		sink_rdy	: out STD_LOGIC;
		source_rdy 	: in  STD_LOGIC;
		source_wrd	: out STD_LOGIC_VECTOR (5 downto 0);
		source_val 	: out STD_LOGIC
	);
	END COMPONENT;
		
	COMPONENT data_carriers_gen
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		sink_wrd	: IN std_logic_vector(5 downto 0);
		sink_val	: IN std_logic;
--		lp_sink_wrd	: IN std_logic_vector(5 downto 0);		
--		lp_sink_val : IN std_logic;
		indx_ofdm	: OUT std_logic_vector(12 downto 0);
		indx_flags	: OUT std_logic_vector(2  downto 0);		
		qam_val 	: OUT std_logic;
		qam_sop		: OUT std_logic;
		qam_eop		: OUT std_logic;		
		qam_re 		: OUT std_logic_vector(15 downto 0);
		qam_im 		: OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;	

--	signal lp_inner_coder_source_bit : std_logic;
--	signal lp_inner_coder_source_val : std_logic;
--	signal lp_inner_coder_source_rdy : std_logic; 
	signal hp_inner_coder_source_bit : std_logic;
	signal hp_inner_coder_source_val : std_logic; 
	signal hp_inner_coder_source_sop : std_logic; 
	signal hp_inner_coder_source_eop : std_logic; 	
	-- resample from 1 bit @ 6 * F_SYMBOL to 6 bits @ 1 * F_SYMBOL
	signal bit_int_sink_wrd : std_logic_vector(5  downto 0);
	signal bit_int_sink_val : std_logic;	
	-- data carrier generator	
	SIGNAL flags			: std_logic_vector(2  downto 0);
	SIGNAL qam_re			: std_logic_vector(15 downto 0);
	SIGNAL qam_im			: std_logic_vector(15 downto 0);
	SIGNAL qam_val 			: std_logic;
	SIGNAL zero				: std_logic_vector(15 downto 0);	
	SIGNAL zero_val 		: std_logic;
	
begin

--	Inst_coding_lp: coding 
	Inst_coding_hp: coding 
	GENERIC MAP(
		FEC			=> HPFEC,
		Irate		=> HPFEC MOD 10,
		Orate		=> HPFEC REM 10)	
	PORT MAP(
		clk			=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		sink_rdy	=> spi_rdy,
		sink_byte	=> spi_data,
		sink_val 	=> spi_dvalid,
		sink_sop	=> spi_sop,
		sink_eop	=> spi_eop,
		source_bit 	=> hp_inner_coder_source_bit,
		source_val 	=> hp_inner_coder_source_val,
		source_sop	=> hp_inner_coder_source_sop,
		source_eop	=> hp_inner_coder_source_eop
	);
		
--	generate
--	if (HIERARCHY = 0) and (QAM = 6) then

		Inst_resampler: resampler
--		GENERIC MAP(
--			HIER	=> HIERARCHY,
--			QAM		=> QAM)	
		PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> ce,
			sink_bit	=> hp_inner_coder_source_bit,
			sink_val	=> hp_inner_coder_source_val,
			source_rdy	=> xn_rdy, -- source ready
			source_wrd	=> bit_int_sink_wrd,
			source_val	=> bit_int_sink_val
		);		
		
		Inst_data_carriers_gen: data_carriers_gen 
--		GENERIC MAP(
--			OFDM	=> OFDM,
--			QAM		=> QAM)	
		PORT MAP(
			clk 		=> clk,
			reset_n 	=> reset_n,
			ce 			=> xn_rdy,	-- chip enable
			sink_wrd 	=> bit_int_sink_wrd,
			sink_val 	=> bit_int_sink_val,			
			indx_ofdm	=> xn_index,			
			indx_flags  => flags,	
			qam_val		=> qam_val,
			qam_sop		=> xn_sop,
			qam_eop		=> xn_eop,
			qam_re 		=> qam_re,	-- xn_re
			qam_im 		=> qam_im	-- xn_im			
		);

		zero <= conv_std_logic_vector(0, 16);
		zero_val <= qam_val and flags(0);
		xn_re <= zero when zero_val = '1' else qam_re;						
		xn_im <= zero when zero_val = '1' else qam_im;	
		xn_val <= qam_val;		

--	end if;
--	end generate;
		
end Behavioral;	
