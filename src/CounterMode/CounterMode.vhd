LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY CounterMode IS
	PORT (
		clk, in_valid : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		iv : IN STD_LOGIC_VECTOR(95 DOWNTO 0);
		input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY CounterMode;

ARCHITECTURE CounterMode_arc OF CounterMode IS

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
			clk, in_val, aad, frame_start, frame_end, isDec : IN STD_LOGIC;
			num_bits : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_bits : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			out_aad, out_frame_start, out_frame_end, out_isDec : OUT STD_LOGIC);
	END COMPONENT;


	SIGNAL val_enc, val_count : STD_LOGIC := '0';
	SIGNAL fin_enc, full_counter : STD_LOGIC_VECTOR(127 DOWNTO 0);

	SIGNAL vals : STD_LOGIC_VECTOR(69 DOWNTO 0);
	SIGNAL regs : STD_LOGIC_VECTOR(8831 DOWNTO 0);
	SIGNAL counter : STD_LOGIC_VECTOR(31 downto 0) := x"00000002";

BEGIN
	incrementer: PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (in_valid = '1') THEN
				counter <= counter + '1';
			END IF;
		END IF;
	END PROCESS;

	full_counter <= iv & counter;

	U : AES PORT MAP(clk, key, in_valid, full_counter, val_enc, fin_enc);

	-- 69 delay regs?
	U0  : REG PORT MAP(clk => clk, in_val => in_valid, aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => input, 	              out_val => vals(0),  out_state => regs(127 DOWNTO 0)    , out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U1  : REG PORT MAP(clk => clk, in_val => vals(0),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(127 DOWNTO 0),     out_val => vals(1),  out_state => regs(255 DOWNTO 128)  , out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U2  : REG PORT MAP(clk => clk, in_val => vals(1),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(255 DOWNTO 128),   out_val => vals(2),  out_state => regs(383 DOWNTO 256)  , out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U3  : REG PORT MAP(clk => clk, in_val => vals(2),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(383 DOWNTO 256),   out_val => vals(3),  out_state => regs(511 DOWNTO 384)  , out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U4  : REG PORT MAP(clk => clk, in_val => vals(3),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(511 DOWNTO 384),   out_val => vals(4),  out_state => regs(639 DOWNTO 512)  , out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U5  : REG PORT MAP(clk => clk, in_val => vals(4),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(639 DOWNTO 512),   out_val => vals(5),  out_state => regs(767 DOWNTO 640)  , out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U6  : REG PORT MAP(clk => clk, in_val => vals(5),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(767 DOWNTO 640),   out_val => vals(6),  out_state => regs(895 DOWNTO 768)  , out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U7  : REG PORT MAP(clk => clk, in_val => vals(6),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(895 DOWNTO 768),   out_val => vals(7),  out_state => regs(1023 DOWNTO 896) , out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U8  : REG PORT MAP(clk => clk, in_val => vals(7),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(1023 DOWNTO 896),  out_val => vals(8),  out_state => regs(1151 DOWNTO 1024), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U9  : REG PORT MAP(clk => clk, in_val => vals(8),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(1151 DOWNTO 1024), out_val => vals(9),  out_state => regs(1279 DOWNTO 1152), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U10 : REG PORT MAP(clk => clk, in_val => vals(9),  aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(1279 DOWNTO 1152), out_val => vals(10), out_state => regs(1407 DOWNTO 1280), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U11 : REG PORT MAP(clk => clk, in_val => vals(10), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(1407 DOWNTO 1280), out_val => vals(11), out_state => regs(1535 DOWNTO 1408), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U12 : REG PORT MAP(clk => clk, in_val => vals(11), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(1535 DOWNTO 1408), out_val => vals(12), out_state => regs(1663 DOWNTO 1536), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U13 : REG PORT MAP(clk => clk, in_val => vals(12), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(1663 DOWNTO 1536), out_val => vals(13), out_state => regs(1791 DOWNTO 1664), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U14 : REG PORT MAP(clk => clk, in_val => vals(13), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(1791 DOWNTO 1664), out_val => vals(14), out_state => regs(1919 DOWNTO 1792), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U15 : REG PORT MAP(clk => clk, in_val => vals(14), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(1919 DOWNTO 1792), out_val => vals(15), out_state => regs(2047 DOWNTO 1920), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U16 : REG PORT MAP(clk => clk, in_val => vals(15), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(2047 DOWNTO 1920), out_val => vals(16), out_state => regs(2175 DOWNTO 2048), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U17 : REG PORT MAP(clk => clk, in_val => vals(16), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(2175 DOWNTO 2048), out_val => vals(17), out_state => regs(2303 DOWNTO 2176), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U18 : REG PORT MAP(clk => clk, in_val => vals(17), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(2303 DOWNTO 2176), out_val => vals(18), out_state => regs(2431 DOWNTO 2304), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U19 : REG PORT MAP(clk => clk, in_val => vals(18), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(2431 DOWNTO 2304), out_val => vals(19), out_state => regs(2559 DOWNTO 2432), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U20 : REG PORT MAP(clk => clk, in_val => vals(19), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(2559 DOWNTO 2432), out_val => vals(20), out_state => regs(2687 DOWNTO 2560), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U21 : REG PORT MAP(clk => clk, in_val => vals(20), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(2687 DOWNTO 2560), out_val => vals(21), out_state => regs(2815 DOWNTO 2688), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U22 : REG PORT MAP(clk => clk, in_val => vals(21), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(2815 DOWNTO 2688), out_val => vals(22), out_state => regs(2943 DOWNTO 2816), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U23 : REG PORT MAP(clk => clk, in_val => vals(22), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(2943 DOWNTO 2816), out_val => vals(23), out_state => regs(3071 DOWNTO 2944), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U24 : REG PORT MAP(clk => clk, in_val => vals(23), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(3071 DOWNTO 2944), out_val => vals(24), out_state => regs(3199 DOWNTO 3072), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U25 : REG PORT MAP(clk => clk, in_val => vals(24), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(3199 DOWNTO 3072), out_val => vals(25), out_state => regs(3327 DOWNTO 3200), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U26 : REG PORT MAP(clk => clk, in_val => vals(25), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(3327 DOWNTO 3200), out_val => vals(26), out_state => regs(3455 DOWNTO 3328), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U27 : REG PORT MAP(clk => clk, in_val => vals(26), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(3455 DOWNTO 3328), out_val => vals(27), out_state => regs(3583 DOWNTO 3456), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U28 : REG PORT MAP(clk => clk, in_val => vals(27), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(3583 DOWNTO 3456), out_val => vals(28), out_state => regs(3711 DOWNTO 3584), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U29 : REG PORT MAP(clk => clk, in_val => vals(28), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(3711 DOWNTO 3584), out_val => vals(29), out_state => regs(3839 DOWNTO 3712), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U30 : REG PORT MAP(clk => clk, in_val => vals(29), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(3839 DOWNTO 3712), out_val => vals(30), out_state => regs(3967 DOWNTO 3840), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U31 : REG PORT MAP(clk => clk, in_val => vals(30), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(3967 DOWNTO 3840), out_val => vals(31), out_state => regs(4095 DOWNTO 3968), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U32 : REG PORT MAP(clk => clk, in_val => vals(31), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(4095 DOWNTO 3968), out_val => vals(32), out_state => regs(4223 DOWNTO 4096), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U33 : REG PORT MAP(clk => clk, in_val => vals(32), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(4223 DOWNTO 4096), out_val => vals(33), out_state => regs(4351 DOWNTO 4224), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U34 : REG PORT MAP(clk => clk, in_val => vals(33), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(4351 DOWNTO 4224), out_val => vals(34), out_state => regs(4479 DOWNTO 4352), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U35 : REG PORT MAP(clk => clk, in_val => vals(34), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(4479 DOWNTO 4352), out_val => vals(35), out_state => regs(4607 DOWNTO 4480), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U36 : REG PORT MAP(clk => clk, in_val => vals(35), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(4607 DOWNTO 4480), out_val => vals(36), out_state => regs(4735 DOWNTO 4608), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U37 : REG PORT MAP(clk => clk, in_val => vals(36), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(4735 DOWNTO 4608), out_val => vals(37), out_state => regs(4863 DOWNTO 4736), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U38 : REG PORT MAP(clk => clk, in_val => vals(37), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(4863 DOWNTO 4736), out_val => vals(38), out_state => regs(4991 DOWNTO 4864), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U39 : REG PORT MAP(clk => clk, in_val => vals(38), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(4991 DOWNTO 4864), out_val => vals(39), out_state => regs(5119 DOWNTO 4992), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U40 : REG PORT MAP(clk => clk, in_val => vals(39), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(5119 DOWNTO 4992), out_val => vals(40), out_state => regs(5247 DOWNTO 5120), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U41 : REG PORT MAP(clk => clk, in_val => vals(40), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(5247 DOWNTO 5120), out_val => vals(41), out_state => regs(5375 DOWNTO 5248), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U42 : REG PORT MAP(clk => clk, in_val => vals(41), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(5375 DOWNTO 5248), out_val => vals(42), out_state => regs(5503 DOWNTO 5376), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U43 : REG PORT MAP(clk => clk, in_val => vals(42), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(5503 DOWNTO 5376), out_val => vals(43), out_state => regs(5631 DOWNTO 5504), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U44 : REG PORT MAP(clk => clk, in_val => vals(43), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(5631 DOWNTO 5504), out_val => vals(44), out_state => regs(5759 DOWNTO 5632), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U45 : REG PORT MAP(clk => clk, in_val => vals(44), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(5759 DOWNTO 5632), out_val => vals(45), out_state => regs(5887 DOWNTO 5760), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U46 : REG PORT MAP(clk => clk, in_val => vals(45), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(5887 DOWNTO 5760), out_val => vals(46), out_state => regs(6015 DOWNTO 5888), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U47 : REG PORT MAP(clk => clk, in_val => vals(46), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(6015 DOWNTO 5888), out_val => vals(47), out_state => regs(6143 DOWNTO 6016), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U48 : REG PORT MAP(clk => clk, in_val => vals(47), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(6143 DOWNTO 6016), out_val => vals(48), out_state => regs(6271 DOWNTO 6144), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U49 : REG PORT MAP(clk => clk, in_val => vals(48), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(6271 DOWNTO 6144), out_val => vals(49), out_state => regs(6399 DOWNTO 6272), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U50 : REG PORT MAP(clk => clk, in_val => vals(49), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(6399 DOWNTO 6272), out_val => vals(50), out_state => regs(6527 DOWNTO 6400), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U51 : REG PORT MAP(clk => clk, in_val => vals(50), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(6527 DOWNTO 6400), out_val => vals(51), out_state => regs(6655 DOWNTO 6528), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U52 : REG PORT MAP(clk => clk, in_val => vals(51), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(6655 DOWNTO 6528), out_val => vals(52), out_state => regs(6783 DOWNTO 6656), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U53 : REG PORT MAP(clk => clk, in_val => vals(52), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(6783 DOWNTO 6656), out_val => vals(53), out_state => regs(6911 DOWNTO 6784), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U54 : REG PORT MAP(clk => clk, in_val => vals(53), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(6911 DOWNTO 6784), out_val => vals(54), out_state => regs(7039 DOWNTO 6912), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U55 : REG PORT MAP(clk => clk, in_val => vals(54), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(7039 DOWNTO 6912), out_val => vals(55), out_state => regs(7167 DOWNTO 7040), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U56 : REG PORT MAP(clk => clk, in_val => vals(55), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(7167 DOWNTO 7040), out_val => vals(56), out_state => regs(7295 DOWNTO 7168), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U57 : REG PORT MAP(clk => clk, in_val => vals(56), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(7295 DOWNTO 7168), out_val => vals(57), out_state => regs(7423 DOWNTO 7296), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U58 : REG PORT MAP(clk => clk, in_val => vals(57), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(7423 DOWNTO 7296), out_val => vals(58), out_state => regs(7551 DOWNTO 7424), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U59 : REG PORT MAP(clk => clk, in_val => vals(58), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(7551 DOWNTO 7424), out_val => vals(59), out_state => regs(7679 DOWNTO 7552), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U60 : REG PORT MAP(clk => clk, in_val => vals(59), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(7679 DOWNTO 7552), out_val => vals(60), out_state => regs(7807 DOWNTO 7680), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U61 : REG PORT MAP(clk => clk, in_val => vals(60), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(7807 DOWNTO 7680), out_val => vals(61), out_state => regs(7935 DOWNTO 7808), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U62 : REG PORT MAP(clk => clk, in_val => vals(61), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(7935 DOWNTO 7808), out_val => vals(62), out_state => regs(8063 DOWNTO 7936), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U63 : REG PORT MAP(clk => clk, in_val => vals(62), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(8063 DOWNTO 7936), out_val => vals(63), out_state => regs(8191 DOWNTO 8064), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U64 : REG PORT MAP(clk => clk, in_val => vals(63), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(8191 DOWNTO 8064), out_val => vals(64), out_state => regs(8319 DOWNTO 8192), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U65 : REG PORT MAP(clk => clk, in_val => vals(64), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(8319 DOWNTO 8192), out_val => vals(65), out_state => regs(8447 DOWNTO 8320), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U66 : REG PORT MAP(clk => clk, in_val => vals(65), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(8447 DOWNTO 8320), out_val => vals(66), out_state => regs(8575 DOWNTO 8448), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U67 : REG PORT MAP(clk => clk, in_val => vals(66), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(8575 DOWNTO 8448), out_val => vals(67), out_state => regs(8703 DOWNTO 8576), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);
	U68 : REG PORT MAP(clk => clk, in_val => vals(67), aad => '0', frame_start => '0', frame_end => '0', isDec => '0', num_bits => "00000000", state => regs(8703 DOWNTO 8576), out_val => vals(68), out_state => regs(8831 DOWNTO 8704), out_bits => open, out_aad => open, out_frame_start => open, out_frame_end => open, out_isDec => open);        

	PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
			IF (val_enc = '1') THEN
				output <= fin_enc XOR regs(8831 DOWNTO 8704);
				out_val <= '1';
			ELSE
				out_val <= '0';
			END IF;
		END IF;
	END PROCESS;

END;