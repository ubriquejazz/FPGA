--------------------------------------------------------------------------------
--   File Name : up_package.vhd
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

package up_package is

--	constant CLOCK_PERIOD 		: time := 15.625 ns;		-- 64 MHz
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

end up_package;

package body up_package is
end up_package;