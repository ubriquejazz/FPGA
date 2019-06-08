--------------------------------------------------------------------------------
--   File Name : mypackage.vhd
--------------------------------------------------------------------------------
--  Copyright (C) 2010 Juan Gago
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License version 2 as
--  published by the Free Software Foundation.
--
--------------------------------------------------------------------------------
--  DESCRIPTION: Definition of constants for the project.
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;

package mypackage is

	-----------------------------------------------------------------------------
	-- Simulation Flag
	-- It's controlled automaticaly by XST with the pragma statement
	--  "false" --> synthesis
	--  "true"  --> simulation
	-----------------------------------------------------------------------------
	constant SIMULATION : boolean := false
	-- synthesis translate_off
	or true
	-- synthesis translate_on
	;

	-- Constants (do not modify)
	constant F_CLOCK	: integer := 64000;	-- Main clock frequency (KHz) 
	constant F_CARRIER	: integer := 14000;	-- Carrier frequency (KHz)
	constant F_SYMBOL	: integer := 9143;	-- Symbol frequency  (KHz) 
	
	-- Constants (modifiable)
	constant HIERARCHY	: integer := 0;		-- HIERARCHY used (0 = NO, 1 = [?=1])
	constant HPFEC		: integer := 34;	-- FEC used for HP stream (12, 23, 34, 56, 78)
	constant LPFEC		: integer := 34;	-- FEC used for LP stream (12, 23, 34, 56, 78)
	constant QAM		: integer := 6;		-- QAM used (2=4QAM, 4=16QAM, 6=64QAM)
	constant OFDM		: integer := 2;		-- Mode OFDM used (2, 8)
	constant GI			: integer := 0;		-- Guard interval used (4, 8, 16, 32, 0)

	-- Superframe Length. Table 16 ETSI EN-300744
	constant NUM_BYTES_TS	: integer := 188;	-- TS packet length 		(bytes)
	constant SYMBOLS_FR	: integer := 68;		-- Frame length				(symbols)
	constant FRAMES_SF	: integer := 4;			-- Superframe length		(frames)
	constant SYMBOLS_SF	: integer := 272;		-- 68 x 4					(symbols) 
	constant PACKETS_SF	: integer := 1134;		-- f (HPFEC, QAM, OFDM)		(packets)
		
	-- MPEG-TS input data stream. f (QAM, OFDM, GI)	
	constant SYMBOL		: integer := 14336;			-- 2048 x (1 + GI) x F_CLOCK / F_SYMBOL	
	constant SUPERFRAME	: integer := 3899392;		-- SYMBOLS_SF x SYMBOL	 		(cycles)
	constant BYTES_SF	: integer := 213192;		-- PACKETS_SF x NUM_BYTES_TS	(bytes)
	constant WORDS_SYMBOL	: integer := 1512; 		-- 1 word = QAM bits			(words)

	-- BYTES_SF/SUPERFRAME 	= RATE_NUM/RATE_CONT
	constant RATE_NUM	: integer := 26649;			-- 141.75 packets	(bytes)
	constant RATE_CONT	: integer := 487424;		-- 			(cycles)

	-- Reference Power (AGC):  fi(1,18,17);
	constant POT_REF : std_logic_vector(17 downto 0) := 
	--	conv_std_logic_vector(65536, 18);	--> cag( 3,  1, 1) = 0.5000 W
		conv_std_logic_vector(6554,  18);  	--> cag(13,  1, 1) = 0.0500 W
	--	conv_std_logic_vector(16384, 18); 	--> cag( 3, .5, 1) = 0.1250 W
	--	conv_std_logic_vector(1638,  18);  	--> cag(13, .5, 1) = 0.0125 W

	-- DAC Parameters
	constant DAC_LSB	: std_logic_vector(17 downto 0) := B"0000000_0000001_0000";
	constant DAC_MAX	: std_logic_vector(17 downto 0) := B"0111111_1111111_0000"; -- (+ 2^17 - 1)
	constant DAC_MIN	: std_logic_vector(17 downto 0) := B"1000000_0000001_1111"; -- (- 2^17 )

	-- Debug
	constant INTERPOLATION_FACTOR_18	: std_logic_vector(17 downto 0) := conv_std_logic_vector(49,18);	
	constant INTERPOLATION_FACTOR_16	: std_logic_vector(15 downto 0) := conv_std_logic_vector(49,16);	

-----------------------------------------------------------------------------------------------------------------
-- TESTBENCH (up_sampling.m)
-----------------------------------------------------------------------------------------------------------------

	constant CLOCK_PERIOD 		: time := 15.625 ns;		-- 64 MHz
	constant CLOCK_PERIOD_56  	: time := 17.85714286 ns;	-- 56 MHz
	constant CLOCK_PERIOD_112 	: time := 8.928571429 ns;	-- 112 MHz

	-- No. samples in 2K MODE 
	--	constant NUM_MUESTRAS_F0	: integer := 2560; 		-- GI = 4  
	--	constant NUM_MUESTRAS_F0	: integer := 2304; 		-- GI = 8  
	--	constant NUM_MUESTRAS_F0	: integer := 2176; 		-- GI = 16 
	--	constant NUM_MUESTRAS_F0	: integer := 2112; 		-- GI = 32 
		constant NUM_MUESTRAS_F0	: integer := 2048;		-- GI = 0
	--	constant NUM_MUESTRAS_56	: integer := 15680; 	-- GI = 4  
	--	constant NUM_MUESTRAS_56	: integer := 14112; 	-- GI = 8  
	--	constant NUM_MUESTRAS_56	: integer := 13328; 	-- GI = 16 
	--	constant NUM_MUESTRAS_56	: integer := 12936; 	-- GI = 32 
		constant NUM_MUESTRAS_56	: integer := 12544;		-- GI = 0
	
	-- No. samples in 8K MODE 
	--	constant NUM_MUESTRAS_F0	: integer := 10240;		-- GI = 4  
	--	constant NUM_MUESTRAS_F0	: integer := 9216;		-- GI = 8 
	--	constant NUM_MUESTRAS_F0	: integer := 8704;		-- GI = 16
	--	constant NUM_MUESTRAS_F0	: integer := 8448;		-- GI = 32 
	--	constant NUM_MUESTRAS_F0	: integer := 8192;		-- GI = 0
	--	constant NUM_MUESTRAS_56	: integer := 62720;		-- GI = 4
	--	constant NUM_MUESTRAS_56	: integer := 56448;		-- GI = 8 
	--	constant NUM_MUESTRAS_56	: integer := 53312;		-- GI = 16
	--	constant NUM_MUESTRAS_56	: integer := 51744;		-- GI = 32 
	--	constant NUM_MUESTRAS_56	: integer := 50176;		-- GI = 0

end mypackage;

package body mypackage is

end mypackage;
