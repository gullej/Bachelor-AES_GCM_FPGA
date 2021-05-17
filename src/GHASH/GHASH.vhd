
LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY GHASH IS
	PORT (
		clk : IN STD_LOGIC;
		in_val : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		auth_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_product : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE GHASH_arc OF GHASH IS

	COMPONENT bitParallel IS
		PORT (
			clk : IN STD_LOGIC;
			in_val : IN STD_LOGIC;
			A : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			B : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_product : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	COMPONENT AES IS
		PORT (
			clk : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			in_val : IN STD_LOGIC;
			in_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			fin_val : OUT STD_LOGIC;
			fin_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	COMPONENT REG IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	SIGNAL auth_temp, X : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL H : STD_LOGIC_VECTOR(127 DOWNTO 0)  := (others => '0');
	SIGNAL aes_val : STD_LOGIC;
	SIGNAL aes_state : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL mult_val : STD_LOGIC;
	SIGNAL mult_product : STD_LOGIC_VECTOR(127 downto 0);
	SIGNAL regs : STD_LOGIC_VECTOR(8831 DOWNTO 0);
	SIGNAL vals : STD_LOGIC_VECTOR(68 DOWNTO 0);
	SIGNAL start_of_frame : STD_LOGIC := '1';
	SIGNAL tester : STD_LOGIC;

BEGIN

	UU1 : AES         PORT MAP(clk, key, in_val, H, aes_val, aes_state);
	UU2 : bitParallel PORT MAP(clk, vals(68), aes_state, auth_temp, mult_val, mult_product);

	X <= regs(8831 DOWNTO 8704);

	PROCESS(start_of_frame, auth_temp, X)
	BEGIN
		IF (start_of_frame = '1') THEN
			auth_temp <= X;
			tester <= '1';
		ELSE
			auth_temp <= X xor mult_product;
			tester <= '0';
		END IF;
	END PROCESS;

	U0  : REG PORT MAP(clk, in_val,   auth_data, 	          vals(0),  regs(127 DOWNTO 0));
	U1  : REG PORT MAP(clk, vals(0),  regs(127 DOWNTO 0),     vals(1),  regs(255 DOWNTO 128));
	U2  : REG PORT MAP(clk, vals(1),  regs(255 DOWNTO 128),   vals(2),  regs(383 DOWNTO 256));
	U3  : REG PORT MAP(clk, vals(2),  regs(383 DOWNTO 256),   vals(3),  regs(511 DOWNTO 384));
	U4  : REG PORT MAP(clk, vals(3),  regs(511 DOWNTO 384),   vals(4),  regs(639 DOWNTO 512));
	U5  : REG PORT MAP(clk, vals(4),  regs(639 DOWNTO 512),   vals(5),  regs(767 DOWNTO 640));
	U6  : REG PORT MAP(clk, vals(5),  regs(767 DOWNTO 640),   vals(6),  regs(895 DOWNTO 768));
	U7  : REG PORT MAP(clk, vals(6),  regs(895 DOWNTO 768),   vals(7),  regs(1023 DOWNTO 896));
	U8  : REG PORT MAP(clk, vals(7),  regs(1023 DOWNTO 896),  vals(8),  regs(1151 DOWNTO 1024));
	U9  : REG PORT MAP(clk, vals(8),  regs(1151 DOWNTO 1024), vals(9),  regs(1279 DOWNTO 1152));
	U10 : REG PORT MAP(clk, vals(9),  regs(1279 DOWNTO 1152), vals(10), regs(1407 DOWNTO 1280));
	U11 : REG PORT MAP(clk, vals(10), regs(1407 DOWNTO 1280), vals(11), regs(1535 DOWNTO 1408));
	U12 : REG PORT MAP(clk, vals(11), regs(1535 DOWNTO 1408), vals(12), regs(1663 DOWNTO 1536));
	U13 : REG PORT MAP(clk, vals(12), regs(1663 DOWNTO 1536), vals(13), regs(1791 DOWNTO 1664));
	U14 : REG PORT MAP(clk, vals(13), regs(1791 DOWNTO 1664), vals(14), regs(1919 DOWNTO 1792));
	U15 : REG PORT MAP(clk, vals(14), regs(1919 DOWNTO 1792), vals(15), regs(2047 DOWNTO 1920));
	U16 : REG PORT MAP(clk, vals(15), regs(2047 DOWNTO 1920), vals(16), regs(2175 DOWNTO 2048));
	U17 : REG PORT MAP(clk, vals(16), regs(2175 DOWNTO 2048), vals(17), regs(2303 DOWNTO 2176));
	U18 : REG PORT MAP(clk, vals(17), regs(2303 DOWNTO 2176), vals(18), regs(2431 DOWNTO 2304));
	U19 : REG PORT MAP(clk, vals(18), regs(2431 DOWNTO 2304), vals(19), regs(2559 DOWNTO 2432));
	U20 : REG PORT MAP(clk, vals(19), regs(2559 DOWNTO 2432), vals(20), regs(2687 DOWNTO 2560));
	U21 : REG PORT MAP(clk, vals(20), regs(2687 DOWNTO 2560), vals(21), regs(2815 DOWNTO 2688));
	U22 : REG PORT MAP(clk, vals(21), regs(2815 DOWNTO 2688), vals(22), regs(2943 DOWNTO 2816));
	U23 : REG PORT MAP(clk, vals(22), regs(2943 DOWNTO 2816), vals(23), regs(3071 DOWNTO 2944));
	U24 : REG PORT MAP(clk, vals(23), regs(3071 DOWNTO 2944), vals(24), regs(3199 DOWNTO 3072));
	U25 : REG PORT MAP(clk, vals(24), regs(3199 DOWNTO 3072), vals(25), regs(3327 DOWNTO 3200));
	U26 : REG PORT MAP(clk, vals(25), regs(3327 DOWNTO 3200), vals(26), regs(3455 DOWNTO 3328));
	U27 : REG PORT MAP(clk, vals(26), regs(3455 DOWNTO 3328), vals(27), regs(3583 DOWNTO 3456));
	U28 : REG PORT MAP(clk, vals(27), regs(3583 DOWNTO 3456), vals(28), regs(3711 DOWNTO 3584));
	U29 : REG PORT MAP(clk, vals(28), regs(3711 DOWNTO 3584), vals(29), regs(3839 DOWNTO 3712));
	U30 : REG PORT MAP(clk, vals(29), regs(3839 DOWNTO 3712), vals(30), regs(3967 DOWNTO 3840));
	U31 : REG PORT MAP(clk, vals(30), regs(3967 DOWNTO 3840), vals(31), regs(4095 DOWNTO 3968));
	U32 : REG PORT MAP(clk, vals(31), regs(4095 DOWNTO 3968), vals(32), regs(4223 DOWNTO 4096));
	U33 : REG PORT MAP(clk, vals(32), regs(4223 DOWNTO 4096), vals(33), regs(4351 DOWNTO 4224));
	U34 : REG PORT MAP(clk, vals(33), regs(4351 DOWNTO 4224), vals(34), regs(4479 DOWNTO 4352));
	U35 : REG PORT MAP(clk, vals(34), regs(4479 DOWNTO 4352), vals(35), regs(4607 DOWNTO 4480));
	U36 : REG PORT MAP(clk, vals(35), regs(4607 DOWNTO 4480), vals(36), regs(4735 DOWNTO 4608));
	U37 : REG PORT MAP(clk, vals(36), regs(4735 DOWNTO 4608), vals(37), regs(4863 DOWNTO 4736));
	U38 : REG PORT MAP(clk, vals(37), regs(4863 DOWNTO 4736), vals(38), regs(4991 DOWNTO 4864));
	U39 : REG PORT MAP(clk, vals(38), regs(4991 DOWNTO 4864), vals(39), regs(5119 DOWNTO 4992));
	U40 : REG PORT MAP(clk, vals(39), regs(5119 DOWNTO 4992), vals(40), regs(5247 DOWNTO 5120));
	U41 : REG PORT MAP(clk, vals(40), regs(5247 DOWNTO 5120), vals(41), regs(5375 DOWNTO 5248));
	U42 : REG PORT MAP(clk, vals(41), regs(5375 DOWNTO 5248), vals(42), regs(5503 DOWNTO 5376));
	U43 : REG PORT MAP(clk, vals(42), regs(5503 DOWNTO 5376), vals(43), regs(5631 DOWNTO 5504));
	U44 : REG PORT MAP(clk, vals(43), regs(5631 DOWNTO 5504), vals(44), regs(5759 DOWNTO 5632));
	U45 : REG PORT MAP(clk, vals(44), regs(5759 DOWNTO 5632), vals(45), regs(5887 DOWNTO 5760));
	U46 : REG PORT MAP(clk, vals(45), regs(5887 DOWNTO 5760), vals(46), regs(6015 DOWNTO 5888));
	U47 : REG PORT MAP(clk, vals(46), regs(6015 DOWNTO 5888), vals(47), regs(6143 DOWNTO 6016));
	U48 : REG PORT MAP(clk, vals(47), regs(6143 DOWNTO 6016), vals(48), regs(6271 DOWNTO 6144));
	U49 : REG PORT MAP(clk, vals(48), regs(6271 DOWNTO 6144), vals(49), regs(6399 DOWNTO 6272));
	U50 : REG PORT MAP(clk, vals(49), regs(6399 DOWNTO 6272), vals(50), regs(6527 DOWNTO 6400));
	U51 : REG PORT MAP(clk, vals(50), regs(6527 DOWNTO 6400), vals(51), regs(6655 DOWNTO 6528));
	U52 : REG PORT MAP(clk, vals(51), regs(6655 DOWNTO 6528), vals(52), regs(6783 DOWNTO 6656));
	U53 : REG PORT MAP(clk, vals(52), regs(6783 DOWNTO 6656), vals(53), regs(6911 DOWNTO 6784));
	U54 : REG PORT MAP(clk, vals(53), regs(6911 DOWNTO 6784), vals(54), regs(7039 DOWNTO 6912));
	U55 : REG PORT MAP(clk, vals(54), regs(7039 DOWNTO 6912), vals(55), regs(7167 DOWNTO 7040));
	U56 : REG PORT MAP(clk, vals(55), regs(7167 DOWNTO 7040), vals(56), regs(7295 DOWNTO 7168));
	U57 : REG PORT MAP(clk, vals(56), regs(7295 DOWNTO 7168), vals(57), regs(7423 DOWNTO 7296));
	U58 : REG PORT MAP(clk, vals(57), regs(7423 DOWNTO 7296), vals(58), regs(7551 DOWNTO 7424));
	U59 : REG PORT MAP(clk, vals(58), regs(7551 DOWNTO 7424), vals(59), regs(7679 DOWNTO 7552));
	U60 : REG PORT MAP(clk, vals(59), regs(7679 DOWNTO 7552), vals(60), regs(7807 DOWNTO 7680));
	U61 : REG PORT MAP(clk, vals(60), regs(7807 DOWNTO 7680), vals(61), regs(7935 DOWNTO 7808));
	U62 : REG PORT MAP(clk, vals(61), regs(7935 DOWNTO 7808), vals(62), regs(8063 DOWNTO 7936));
	U63 : REG PORT MAP(clk, vals(62), regs(8063 DOWNTO 7936), vals(63), regs(8191 DOWNTO 8064));
	U64 : REG PORT MAP(clk, vals(63), regs(8191 DOWNTO 8064), vals(64), regs(8319 DOWNTO 8192));
	U65 : REG PORT MAP(clk, vals(64), regs(8319 DOWNTO 8192), vals(65), regs(8447 DOWNTO 8320));
	U66 : REG PORT MAP(clk, vals(65), regs(8447 DOWNTO 8320), vals(66), regs(8575 DOWNTO 8448));
	U67 : REG PORT MAP(clk, vals(66), regs(8575 DOWNTO 8448), vals(67), regs(8703 DOWNTO 8576));
	U68 : REG PORT MAP(clk, vals(67), regs(8703 DOWNTO 8576), vals(68), regs(8831 DOWNTO 8704));        


	multiplier : PROCESS (clk)

	BEGIN
		IF (RISING_EDGE(clk)) THEN
			
		ELSE
			out_val <= '0';
		END IF;

	END PROCESS;

END ARCHITECTURE;