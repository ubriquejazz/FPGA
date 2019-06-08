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

	constant CLOCK_PERIOD : time := 15.625 ns;	-- 64 MHz
	-- Constants (do not modify)
	constant F_CLOCK	: integer := 64000;		-- Main clock frequency (KHz) 
	constant F_SYMBOL	: integer := 9143;		-- Symbol frequency  (KHz) 	
	-- Constants (modifiable)	
	constant HIERARCHY	: integer := 0;			-- HIERARCHY used (0 = NO, 1 = [?=1])
	constant HPFEC		: integer := 34;		-- FEC used for HP stream (12, 23, 34, 56, 78)
	constant LPFEC		: integer := 34;		-- FEC used for LP stream (12, 23, 34, 56, 78)
	constant QAM		: integer := 6;			-- QAM used (2=4QAM, 4=16QAM, 6=64QAM)
	constant OFDM		: integer := 2;			-- Mode OFDM used (2, 8)
	constant GI			: integer := 0;			-- Guard interval used (4, 8, 16, 32, 0)
	-- Superframe Length. Table 16 ETSI EN-300744
	constant NUM_BYTES_TS	: integer := 188;	-- TS packet length 			(bytes)
	constant SYMBOLS_FR	: integer := 68;		-- Frame length					(symbols)
	constant FRAMES_SF	: integer := 4;			-- Superframe length			(frames)
	constant SYMBOLS_SF	: integer := 272;		-- 68 x 4						(symbols) 
	constant PACKETS_SF	: integer := 1134;		-- f (HPFEC, QAM, OFDM)			(packets)	
	-- MPEG-TS input data stream. f (QAM, OFDM, GI)	
	constant SYMBOL		: integer := 14336;		-- 2048 x (1 + GI) x F_CLOCK / F_SYMBOL	
	constant SUPERFRAME	: integer := 3899392;	-- SYMBOLS_SF x SYMBOL	 		(cycles)
	constant BYTES_SF	: integer := 213192;	-- PACKETS_SF x NUM_BYTES_TS	(bytes)
	constant WORDS_SYMBOL	: integer := 1512; 	-- 1 word = QAM bits			(words)
	-- BYTES_SF/SUPERFRAME 	= RATE_NUM/RATE_CONT
	constant RATE_NUM	: integer := 26649;		-- 141.75 packets	(bytes)
	constant RATE_CONT	: integer := 487424;	-- 			(cycles)

end mypackage;

package body mypackage is
end mypackage;