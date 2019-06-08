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
	port ( 			ce		: IN  std_logic;
				reset_n		: IN  std_logic;
				clk		: IN  std_logic;
				--
--				pps_mod		: IN  std_logic;
--				spi_clk 	: IN  std_logic;
				spi_data 	: IN  std_logic_vector(7 downto 0);
				spi_dvalid	: IN  std_logic;
				spi_rdy 	: OUT std_logic;
--				status 		: OUT std_logic_vector(3 downto 0);
				si_wr_fin 	: OUT std_logic;
				xn_rdy		: OUT std_logic;
				xn_re		: OUT std_logic_VECTOR(15 downto 0);
				xn_im		: OUT std_logic_VECTOR(15 downto 0);
				xk_rdy		: OUT std_logic;
				xk_re	 	: OUT std_logic_VECTOR(15 downto 0);
				xk_im	 	: OUT std_logic_VECTOR(15 downto 0)					
	);
end dvbt_core;

architecture Behavioral of dvbt_core is

	--------------------------------------------------
	-- coding_hp
	--------------------------------------------------
	signal entrada_mux_adapter 	: std_logic_vector(7 downto 0);
	signal mux_adapter_ovflow	: std_logic;
	signal new_data_mux_adapter 	: std_logic;
	signal salida_inner_coder 	: std_logic;
	signal data_rdy_inner_coder 	: std_logic;
	
	COMPONENT coding
	 Generic	(	
		FEC 			: natural := 34;
		Irate			: integer := 3;
		Orate			: integer := 4);
	PORT(
		clk				: IN  std_logic;
		reset_n 		: IN  std_logic;
		ce 				: IN  std_logic;
		entrada 		: IN  std_logic_vector(7 downto 0);
		new_data		: IN  std_logic;
		overflow		: out std_logic;
		data_out 		: out std_logic;	--_vector(7 downto 0);
		data_rdy 		: out std_logic
		);
	END COMPONENT;
	
	--------------------------------------------------
	-- modulator
	--------------------------------------------------
	signal entrada_hp	: std_logic;
	signal new_data_hp	: std_logic;
	signal fa_frame_indx	: std_logic_VECTOR(6 downto 0);
	signal xn_re_int	: std_logic_VECTOR(15 downto 0);
	signal xn_im_int	: std_logic_VECTOR(15 downto 0);
	signal I_bb_16		: std_logic_VECTOR(15 downto 0);
	signal Q_bb_16		: std_logic_VECTOR(15 downto 0);
	signal I_bb_ampl_16	: std_logic_VECTOR(15 downto 0);
	signal Q_bb_ampl_16	: std_logic_VECTOR(15 downto 0);
	signal rd_en_s0		: std_logic;
	signal empty_s0		: std_logic;

	COMPONENT modulator
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		new_data_hp : IN std_logic;
		entrada_hp 	: IN std_logic;
		rd_en_s0 	: IN std_logic;          
		si_wr_fin 	: OUT std_logic;
		fa_frame_indx  	: OUT std_logic_vector(6 downto 0);
		xn_rdy 		: OUT std_logic;
		xn_re 		: OUT std_logic_vector(15 downto 0);
		xn_im 		: OUT std_logic_vector(15 downto 0);
		empty_s0 	: OUT std_logic;
		xk_ovflo 	: OUT std_logic;
		xk_re_s0 	: OUT std_logic_vector(15 downto 0);
		xk_im_s0 	: OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;	

	-- 9143 KHz and 16 MHz readers
	signal en1_7_s1	: std_logic;	
	signal en1_7_s3	: std_logic;
	
	component contador7x 
   	port (  
		clk 		: in  STD_LOGIC;
		ce 		: in  STD_LOGIC;
           	reset_n		: in  STD_LOGIC;
           	oe_7		: out STD_LOGIC);
	end component;

begin

	----------------------------------------------------------------------------
	-- To register input signals: 8 bits @ 6/8 * F_SYMBOL
	----------------------------------------------------------------------------
	
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				entrada_mux_adapter <= (others => '0');
			elsif ce = '1' then
				entrada_mux_adapter <= spi_data;
			end if;
		end if;
	end process;
		
	process (clk)
	begin
		if clk'event and clk = '1' then  
			if reset_n = '0' then   
				new_data_mux_adapter <= '0';
			elsif ce = '1' then
				new_data_mux_adapter <= spi_dvalid;
			end if;
		end if;
	end process;

	Inst_coding_hp: coding 
	GENERIC MAP(
		FEC				=> 34,
		Irate			=> 3,
		Orate			=> 4)	
	PORT MAP(
		clk				=> clk,
		reset_n 		=> reset_n,
		ce 				=> ce,
		new_data		=> new_data_mux_adapter,
		entrada 		=> entrada_mux_adapter,
		overflow 		=> mux_adapter_ovflow,
		data_out 		=> salida_inner_coder,
		data_rdy 		=> data_rdy_inner_coder
	);
		
	--	Inst_coding_lp: coding 
	
	spi_rdy <= not (mux_adapter_ovflow);
	
	----------------------------------------------------------------------------
	-- To register intermediate signals: 1 bit @ 6 * F_SYMBOL
	----------------------------------------------------------------------------	
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				entrada_hp <= '0';
			elsif ce = '1' then
				entrada_hp <= salida_inner_coder;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_hp <= '0';
			elsif ce = '1' then
				new_data_hp <= data_rdy_inner_coder;
			end if;
		end if;
	end process;	
	
	-----------------------------------------------------
	-- modulator @ 64 MHz
	-----------------------------------------------------

	Inst_modulator: modulator 
	PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		entrada_hp 	=> entrada_hp,
		new_data_hp	=> new_data_hp,
		--
		si_wr_fin 	=> si_wr_fin,
		fa_frame_indx	=> fa_frame_indx,
		xn_re 		=> xn_re_int,
		xn_im 		=> xn_im_int,
		xn_rdy		=> xn_rdy,
		--
		rd_en_s0 	=> rd_en_s0,
		empty_s0 	=> empty_s0,
		xk_re_s0 	=> I_bb_16,
		xk_im_s0 	=> Q_bb_16
	);
	
	xn_re <= xn_re_int;
	xn_im <= xn_im_int;

	----------------------------------------------------------------------------
	-- reading interface of the fifo (stage 0)
	----------------------------------------------------------------------------
	
	Inst_9143KHz_reader: contador7x 
	port map (
		clk 	=> clk,				-- 64 MHz
		reset_n	=> reset_n,
		ce 		=> ce,
		oe_7	=> en1_7_s1			-- 9.143 MHz 
		);
	
	rd_en_s0 <= en1_7_s1 and not(empty_s0);
	xk_rdy 	<= not(empty_s0);
		
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				xk_re <= (others => '0');
			elsif ce = '1' then
				xk_re <=  I_bb_16;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk = '1' and clk'event then
			if reset_n = '0' then
				xk_im <= (others => '0');
			elsif ce = '1' then
				xk_im <= Q_bb_16;
			end if;
		end if;
	end process;
	
end Behavioral;	
