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

entity coding is
	Generic	(	
		FEC 		: natural := 34;
		Irate		: integer := 3;
		Orate		: integer := 4);
    Port (	
		clk			: in  STD_LOGIC;
		reset_n 	: in  STD_LOGIC;
		ce 			: in  STD_LOGIC;
		new_data	: in  STD_LOGIC;
		entrada 	: in  STD_LOGIC_VECTOR(7 downto 0);
		overflow 	: out STD_LOGIC;
		data_out 	: out STD_LOGIC; --_VECTOR(7 downto 0);
		data_rdy 	: out STD_LOGIC
	 );
end coding;


architecture Behavioral of coding is

	COMPONENT byte_serializer
	PORT(
			clk 			: IN std_logic;
			reset_n 		: IN std_logic;
			ce 				: IN std_logic;
			entrada 		: IN std_logic_vector(7 downto 0);
			new_byte 		: IN std_logic;          
			buffer_ovf 		: OUT std_logic;
			salida 			: OUT std_logic;
			data_rdy 		: OUT std_logic
		);
	END COMPONENT;

	COMPONENT bit_parallelizer
	PORT(
			clk 			: IN std_logic;
			reset_n 		: IN std_logic;
			ce 				: IN std_logic;
			entrada 		: IN std_logic;
			new_data 		: IN std_logic;  
			--
			salida 			: OUT std_logic_vector(7 downto 0);
			byte_rdy 		: OUT std_logic
		);
	END COMPONENT;

	COMPONENT mux_adapter
	PORT(
		clk 		: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		entrada 	: IN  std_logic;	--_vector(7 downto 0);      
		new_data 	: IN  std_logic;
		salida 		: OUT std_logic;	--_vector(7 downto 0);
		data_rdy 	: OUT std_logic
		);
	END COMPONENT;

	COMPONENT outer_coder
	PORT(
		clk 		: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		data_in 	: IN  std_logic_vector(7 downto 0);
		new_data 	: IN  std_logic;          
		data_out 	: OUT std_logic_vector(7 downto 0);
		data_rdy 	: OUT std_logic
		);
	END COMPONENT;

	COMPONENT outer_interleaver
	PORT(
		clk 		: IN  std_logic;
		reset_n 	: IN  std_logic;
		ce 			: IN  std_logic;
		entrada 	: IN  std_logic_vector(7 downto 0);          
		new_data 	: IN  std_logic;
		salida 		: OUT std_logic_vector(7 downto 0);
		data_rdy 	: OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT inner_coder
	GENERIC(
		FEC 		: natural := 34;
		Irate		: integer := 3;
		Orate		: integer := 4);
	PORT(
		clk 		: IN std_logic;
		reset_n 	: IN std_logic;
		ce 			: IN std_logic;
		entrada 	: IN std_logic_vector(7 downto 0);          
		new_byte 	: IN std_logic;
		buffer_ovf 	: OUT std_logic;
		-- 
		salida 		: OUT std_logic;
		data_rdy 	: OUT std_logic
		);
	END COMPONENT;
	
	--byte serializer
	signal byte2bit_in				: std_logic_vector(7 downto 0);
	signal byte2bit_nd				: std_logic;
	signal byte2bit_out				: std_logic;
	signal byte2bit_rdy				: std_logic;	
	-- bit parallelizer
	signal bit2byte_in				: std_logic;
	signal bit2byte_nd				: std_logic;
	signal bit2byte_out				: std_logic_vector(7 downto 0);
	signal bit2byte_rdy				: std_logic;
	-- mux adapter
	signal entrada_mux_adapter 		: std_logic;
	signal new_data_mux_adapter 	: std_logic;
	signal salida_mux_adapter		: std_logic;
	signal data_rdy_mux_adapter 	: std_logic;
	-- outer coder
	signal entrada_outer_coder	: std_logic_vector(7 downto 0);
	signal new_data_outer_coder	: std_logic;
	signal salida_outer_coder	: std_logic_vector(7 downto 0);
	signal data_rdy_outer_coder	: std_logic;
	-- outer inter
	signal entrada_outer_inter	: std_logic_vector(7 downto 0);
	signal new_data_outer_inter	: std_logic;
	signal salida_outer_inter	: std_logic_vector(7 downto 0);
	signal data_rdy_outer_inter	: std_logic;
	-- inner coder
	signal entrada_inner_coder		: std_logic_vector(7 downto 0);
	signal new_data_inner_coder		: std_logic;
	signal salida_inner_coder		: std_logic;
	signal data_rdy_inner_coder		: std_logic;
	signal buffer_ovf_inner_coder	: std_logic;

begin

	----------------------------------------------------------------------------
	-- To register intermediate signals to avoid timing issues
	----------------------------------------------------------------------------

	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				entrada_mux_adapter <= '0';
			elsif ce = '1' then
				entrada_mux_adapter <= byte2bit_out;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_mux_adapter <= '0';
			elsif ce = '1' then
				new_data_mux_adapter <= byte2bit_rdy;
			end if;
		end if;
	end process;
	
	-- 8 bit to 1 bit serializer
	Inst_byte_serializer: byte_serializer PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		entrada 	=> entrada,
		new_byte 	=> new_data,
		buffer_ovf 	=> overflow,
		salida 		=> byte2bit_out,
		data_rdy 	=> byte2bit_rdy
	);

	----------------------------------------------------------------------------
	-- 1. Transport multiplex adaptation and randomization for energy dispersal:
	----------------------------------------------------------------------------
	Inst_mux_adapter: mux_adapter PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		entrada 	=> entrada_mux_adapter,
		new_data 	=> new_data_mux_adapter,
		salida 		=> salida_mux_adapter,
		data_rdy 	=> data_rdy_mux_adapter
	);

--	salida_mux_adapter 	<= entrada_mux_adapter;
--	data_rdy_mux_adapter 	<= new_data_mux_adapter;
	
	----------------------------------------------------------------------------
	-- To register intermediate signals to avoid timing issues
	----------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				bit2byte_in <= '0';
			elsif ce = '1' then
				bit2byte_in <= salida_mux_adapter;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				bit2byte_nd <= '0';
			elsif ce = '1' then
				bit2byte_nd <= data_rdy_mux_adapter;
			end if;
		end if;
	end process;

	-- 8 bits to 1 byte parallelizer
	Inst_bit_parallelizer: bit_parallelizer PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		entrada 	=> bit2byte_in,
		new_data 	=> bit2byte_nd,
		salida 		=> entrada_outer_coder,
		byte_rdy 	=> new_data_outer_coder
	);
	
	----------------------------------------------------------------------------
	-- 2. Outer coder (Reed-solomon):
	----------------------------------------------------------------------------
	Inst_outer_coder: outer_coder PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 		=> ce,
		data_in 	=> entrada_outer_coder,
		new_data 	=> new_data_outer_coder,
		data_out 	=> salida_outer_coder,
		data_rdy 	=> data_rdy_outer_coder
	);
	
	----------------------------------------------------------------------------
	-- To register intermediate signals to avoid timing issues
	----------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				entrada_outer_inter <= (others => '0');
			elsif ce = '1' then
				entrada_outer_inter <= salida_outer_coder;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_outer_inter <= '0';
			elsif ce = '1' then
				new_data_outer_inter <= data_rdy_outer_coder;
			end if;
		end if;
	end process;

	----------------------------------------------------------------------------
	-- 3. Outer Interleaver (byte-wise interleaving):
	----------------------------------------------------------------------------
	Inst_outer_interleaver: outer_interleaver PORT MAP(
		clk 		=> clk,
		reset_n 	=> reset_n,
		ce 			=> ce,
		new_data 	=> new_data_outer_inter,
		entrada 	=> entrada_outer_inter,
		salida 		=> salida_outer_inter,
		data_rdy 	=> data_rdy_outer_inter
	);

	----------------------------------------------------------------------------
	-- To register intermediate signals to avoid timing issues
	----------------------------------------------------------------------------
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				entrada_inner_coder <= (others => '0');
			elsif ce = '1' then
				entrada_inner_coder <= salida_outer_inter;
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if clk'event and clk = '1' then
			if reset_n = '0' then
				new_data_inner_coder <= '0';
			elsif ce = '1' then
				new_data_inner_coder <= data_rdy_outer_inter;
			end if;
		end if;
	end process;
	
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
		new_byte 	=> new_data_inner_coder,
		entrada 	=> entrada_inner_coder,
		buffer_ovf 	=> buffer_ovf_inner_coder,
		salida 		=> salida_inner_coder,
		data_rdy 	=> data_rdy_inner_coder
	);
	
	data_out <= salida_inner_coder;
	data_rdy <= data_rdy_inner_coder;


end Behavioral;

