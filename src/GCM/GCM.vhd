LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY GCM IS
	PORT (
		clk, SOF, aad_val, enc_val : IN STD_LOGIC;
		num_bits : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		is_dec, EOF : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		iv : IN STD_LOGIC_VECTOR(95 DOWNTO 0);
		input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val, out_tag : OUT STD_LOGIC;
		output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE GCM_arc OF GCM IS

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
			clk, in_val, aad, frame_start, frame_end : IN STD_LOGIC;
			state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_aad, out_frame_start, out_frame_end : OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT bitParallel IS
		PORT (
			clk : IN STD_LOGIC;
			in_val : IN STD_LOGIC;
			A : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			B : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_product : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	COMPONENT bitREG IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			out_val : OUT STD_LOGIC);
	END COMPONENT;

	SIGNAL val_enc, mult_val, val_count, mult_run, after_sof, vfin_enc, start_of_frame, end_of_frame, is_aad, after_after_eof, run_valid, in_valid, after_eof, in_aad : STD_LOGIC := '0';
	SIGNAL fin_enc, H, X, mult_product, full_counter, mult_input, aes_input, fin_hash, fin_length : STD_LOGIC_VECTOR(127 DOWNTO 0);

	SIGNAL vals, sof_delay, aad_delay, eof_delay : STD_LOGIC_VECTOR(70 DOWNTO 0);
	SIGNAL regs : STD_LOGIC_VECTOR(9087 DOWNTO 0);
	SIGNAL counter : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL aad_length, ptext_length : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');

BEGIN
	encrypter : PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (SOF = '1') THEN
				aes_input <= (OTHERS => '0');
				val_enc <= '1';
				after_sof <= '1';
				counter <= x"00000001";
			ELSIF (after_sof = '1') THEN
				val_enc <= '1';
				after_sof <= '0';
				counter <= counter + '1';
				aes_input <= full_counter;
			ELSIF (vals(1) = '1' AND aad_delay(1) = '0') THEN
				counter <= counter + '1';
				aes_input <= full_counter;
				val_enc <= '1';
			ELSE
				val_enc <= '0';
			END IF;
		END IF;
		full_counter <= iv & counter;
	END PROCESS;

	director : PROCESS (start_of_frame, mult_run, is_aad, sof_delay(69), sof_delay(70), end_of_frame, fin_enc, X, mult_input, mult_product, after_eof, after_after_eof)
	BEGIN
		IF (sof_delay(69) = '1') THEN
			H <= fin_enc;
		ELSIF (sof_delay(70) = '1') THEN
			fin_hash <= fin_enc;
		ELSIF (run_valid = '1') THEN
			IF (start_of_frame = '1') THEN
				IF (is_aad = '1') THEN
					mult_input <= X;
					mult_run <= '1';
				ELSE
					output <= fin_enc XOR X;
					out_val <= '1';
					mult_input <= fin_enc XOR X;
					mult_run <= '1';
				END IF;
			ELSE
				IF (is_aad = '1') THEN
					IF (mult_val = '1') THEN
						mult_input <= X XOR mult_product;
						mult_run <= '1';
					END IF;
				ELSE
					IF (mult_val = '1') THEN
						output <= fin_enc XOR X;
						out_val <= '1';
						mult_input <= fin_enc XOR X XOR mult_product;
						mult_run <= '1';
					END IF;
				END IF;
			END IF;
		ELSIF (after_eof = '1') THEN
			mult_input <= fin_length XOR mult_product;
			mult_run <= '1';
			out_val <= '0';
		ELSIF (after_after_eof = '1') THEN
			mult_run <= '0';
			output <= fin_hash XOR mult_product;
			out_tag <= '1';
		ELSE
			mult_run <= '0';
			out_val <= '0';
			out_tag <= '0';
		END IF;
	END PROCESS;

	ender : PROCESS (clk, end_of_frame, after_eof, after_after_eof)
	BEGIN
		IF (rising_edge(clk)) THEN
			IF (end_of_frame = '1') THEN
				after_eof <= '1';
			ELSIF (after_eof = '1') THEN
				after_after_eof <= '1';
				after_eof <= '0';
			ELSIF (after_after_eof = '1') THEN
				after_after_eof <= '0';
			END IF;
		END IF;
	END PROCESS;

	organizer : PROCESS (aad_val, enc_val)
	BEGIN
		IF (aad_val = '1') THEN
			in_aad <= '1';
		ELSIF (enc_val = '1') THEN
			in_aad <= '0';
		END IF;
	END PROCESS;

	runner : PROCESS (clk, SOF, EOF, in_valid)
	BEGIN

		IF (SOF = '1') THEN
			in_valid <= '1';
		END IF;
		IF (EOF = '1') THEN
			IF (RISING_EDGE(clk)) THEN
				in_valid <= '0';
			END IF;
		END IF;
	END PROCESS;

	lengths : PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (in_valid = '1') THEN
				IF (in_aad = '1') THEN
					IF (num_bits = x"00") THEN
						aad_length <= aad_length + x"80";
					ELSE
						aad_length <= aad_length + num_bits;
					END IF;
				ELSE
					IF (num_bits = x"00") THEN
						ptext_length <= ptext_length + x"80";
					ELSE
						ptext_length <= ptext_length + num_bits;
					END IF;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	fin_length <= aad_length & ptext_length;

	U : AES PORT MAP(clk, key, val_enc, aes_input, vfin_enc, fin_enc);
	UU : bitParallel PORT MAP(clk, mult_run, H, mult_input, mult_val, mult_product);

	delayREG0 : REG PORT MAP(clk, in_valid, in_aad, SOF, EOF, input, vals(0), regs(127 DOWNTO 0), aad_delay(0), sof_delay(0), eof_delay(0));

	delayREG1 : REG PORT MAP(clk, vals(0), aad_delay(0), sof_delay(0), eof_delay(0), regs(127 DOWNTO 0), vals(1), regs(255 DOWNTO 128), aad_delay(1), sof_delay(1), eof_delay(1));
	delayREG2 : REG PORT MAP(clk, vals(1), aad_delay(1), sof_delay(1), eof_delay(1), regs(255 DOWNTO 128), vals(2), regs(383 DOWNTO 256), aad_delay(2), sof_delay(2), eof_delay(2));
	delayREG3 : REG PORT MAP(clk, vals(2), aad_delay(2), sof_delay(2), eof_delay(2), regs(383 DOWNTO 256), vals(3), regs(511 DOWNTO 384), aad_delay(3), sof_delay(3), eof_delay(3));
	delayREG4 : REG PORT MAP(clk, vals(3), aad_delay(3), sof_delay(3), eof_delay(3), regs(511 DOWNTO 384), vals(4), regs(639 DOWNTO 512), aad_delay(4), sof_delay(4), eof_delay(4));
	delayREG5 : REG PORT MAP(clk, vals(4), aad_delay(4), sof_delay(4), eof_delay(4), regs(639 DOWNTO 512), vals(5), regs(767 DOWNTO 640), aad_delay(5), sof_delay(5), eof_delay(5));
	delayREG6 : REG PORT MAP(clk, vals(5), aad_delay(5), sof_delay(5), eof_delay(5), regs(767 DOWNTO 640), vals(6), regs(895 DOWNTO 768), aad_delay(6), sof_delay(6), eof_delay(6));
	delayREG7 : REG PORT MAP(clk, vals(6), aad_delay(6), sof_delay(6), eof_delay(6), regs(895 DOWNTO 768), vals(7), regs(1023 DOWNTO 896), aad_delay(7), sof_delay(7), eof_delay(7));
	delayREG8 : REG PORT MAP(clk, vals(7), aad_delay(7), sof_delay(7), eof_delay(7), regs(1023 DOWNTO 896), vals(8), regs(1151 DOWNTO 1024), aad_delay(8), sof_delay(8), eof_delay(8));
	delayREG9 : REG PORT MAP(clk, vals(8), aad_delay(8), sof_delay(8), eof_delay(8), regs(1151 DOWNTO 1024), vals(9), regs(1279 DOWNTO 1152), aad_delay(9), sof_delay(9), eof_delay(9));
	delayREG10 : REG PORT MAP(clk, vals(9), aad_delay(9), sof_delay(9), eof_delay(9), regs(1279 DOWNTO 1152), vals(10), regs(1407 DOWNTO 1280), aad_delay(10), sof_delay(10), eof_delay(10));
	delayREG11 : REG PORT MAP(clk, vals(10), aad_delay(10), sof_delay(10), eof_delay(10), regs(1407 DOWNTO 1280), vals(11), regs(1535 DOWNTO 1408), aad_delay(11), sof_delay(11), eof_delay(11));
	delayREG12 : REG PORT MAP(clk, vals(11), aad_delay(11), sof_delay(11), eof_delay(11), regs(1535 DOWNTO 1408), vals(12), regs(1663 DOWNTO 1536), aad_delay(12), sof_delay(12), eof_delay(12));
	delayREG13 : REG PORT MAP(clk, vals(12), aad_delay(12), sof_delay(12), eof_delay(12), regs(1663 DOWNTO 1536), vals(13), regs(1791 DOWNTO 1664), aad_delay(13), sof_delay(13), eof_delay(13));
	delayREG14 : REG PORT MAP(clk, vals(13), aad_delay(13), sof_delay(13), eof_delay(13), regs(1791 DOWNTO 1664), vals(14), regs(1919 DOWNTO 1792), aad_delay(14), sof_delay(14), eof_delay(14));
	delayREG15 : REG PORT MAP(clk, vals(14), aad_delay(14), sof_delay(14), eof_delay(14), regs(1919 DOWNTO 1792), vals(15), regs(2047 DOWNTO 1920), aad_delay(15), sof_delay(15), eof_delay(15));
	delayREG16 : REG PORT MAP(clk, vals(15), aad_delay(15), sof_delay(15), eof_delay(15), regs(2047 DOWNTO 1920), vals(16), regs(2175 DOWNTO 2048), aad_delay(16), sof_delay(16), eof_delay(16));
	delayREG17 : REG PORT MAP(clk, vals(16), aad_delay(16), sof_delay(16), eof_delay(16), regs(2175 DOWNTO 2048), vals(17), regs(2303 DOWNTO 2176), aad_delay(17), sof_delay(17), eof_delay(17));
	delayREG18 : REG PORT MAP(clk, vals(17), aad_delay(17), sof_delay(17), eof_delay(17), regs(2303 DOWNTO 2176), vals(18), regs(2431 DOWNTO 2304), aad_delay(18), sof_delay(18), eof_delay(18));
	delayREG19 : REG PORT MAP(clk, vals(18), aad_delay(18), sof_delay(18), eof_delay(18), regs(2431 DOWNTO 2304), vals(19), regs(2559 DOWNTO 2432), aad_delay(19), sof_delay(19), eof_delay(19));
	delayREG20 : REG PORT MAP(clk, vals(19), aad_delay(19), sof_delay(19), eof_delay(19), regs(2559 DOWNTO 2432), vals(20), regs(2687 DOWNTO 2560), aad_delay(20), sof_delay(20), eof_delay(20));
	delayREG21 : REG PORT MAP(clk, vals(20), aad_delay(20), sof_delay(20), eof_delay(20), regs(2687 DOWNTO 2560), vals(21), regs(2815 DOWNTO 2688), aad_delay(21), sof_delay(21), eof_delay(21));
	delayREG22 : REG PORT MAP(clk, vals(21), aad_delay(21), sof_delay(21), eof_delay(21), regs(2815 DOWNTO 2688), vals(22), regs(2943 DOWNTO 2816), aad_delay(22), sof_delay(22), eof_delay(22));
	delayREG23 : REG PORT MAP(clk, vals(22), aad_delay(22), sof_delay(22), eof_delay(22), regs(2943 DOWNTO 2816), vals(23), regs(3071 DOWNTO 2944), aad_delay(23), sof_delay(23), eof_delay(23));
	delayREG24 : REG PORT MAP(clk, vals(23), aad_delay(23), sof_delay(23), eof_delay(23), regs(3071 DOWNTO 2944), vals(24), regs(3199 DOWNTO 3072), aad_delay(24), sof_delay(24), eof_delay(24));
	delayREG25 : REG PORT MAP(clk, vals(24), aad_delay(24), sof_delay(24), eof_delay(24), regs(3199 DOWNTO 3072), vals(25), regs(3327 DOWNTO 3200), aad_delay(25), sof_delay(25), eof_delay(25));
	delayREG26 : REG PORT MAP(clk, vals(25), aad_delay(25), sof_delay(25), eof_delay(25), regs(3327 DOWNTO 3200), vals(26), regs(3455 DOWNTO 3328), aad_delay(26), sof_delay(26), eof_delay(26));
	delayREG27 : REG PORT MAP(clk, vals(26), aad_delay(26), sof_delay(26), eof_delay(26), regs(3455 DOWNTO 3328), vals(27), regs(3583 DOWNTO 3456), aad_delay(27), sof_delay(27), eof_delay(27));
	delayREG28 : REG PORT MAP(clk, vals(27), aad_delay(27), sof_delay(27), eof_delay(27), regs(3583 DOWNTO 3456), vals(28), regs(3711 DOWNTO 3584), aad_delay(28), sof_delay(28), eof_delay(28));
	delayREG29 : REG PORT MAP(clk, vals(28), aad_delay(28), sof_delay(28), eof_delay(28), regs(3711 DOWNTO 3584), vals(29), regs(3839 DOWNTO 3712), aad_delay(29), sof_delay(29), eof_delay(29));
	delayREG30 : REG PORT MAP(clk, vals(29), aad_delay(29), sof_delay(29), eof_delay(29), regs(3839 DOWNTO 3712), vals(30), regs(3967 DOWNTO 3840), aad_delay(30), sof_delay(30), eof_delay(30));
	delayREG31 : REG PORT MAP(clk, vals(30), aad_delay(30), sof_delay(30), eof_delay(30), regs(3967 DOWNTO 3840), vals(31), regs(4095 DOWNTO 3968), aad_delay(31), sof_delay(31), eof_delay(31));
	delayREG32 : REG PORT MAP(clk, vals(31), aad_delay(31), sof_delay(31), eof_delay(31), regs(4095 DOWNTO 3968), vals(32), regs(4223 DOWNTO 4096), aad_delay(32), sof_delay(32), eof_delay(32));
	delayREG33 : REG PORT MAP(clk, vals(32), aad_delay(32), sof_delay(32), eof_delay(32), regs(4223 DOWNTO 4096), vals(33), regs(4351 DOWNTO 4224), aad_delay(33), sof_delay(33), eof_delay(33));
	delayREG34 : REG PORT MAP(clk, vals(33), aad_delay(33), sof_delay(33), eof_delay(33), regs(4351 DOWNTO 4224), vals(34), regs(4479 DOWNTO 4352), aad_delay(34), sof_delay(34), eof_delay(34));
	delayREG35 : REG PORT MAP(clk, vals(34), aad_delay(34), sof_delay(34), eof_delay(34), regs(4479 DOWNTO 4352), vals(35), regs(4607 DOWNTO 4480), aad_delay(35), sof_delay(35), eof_delay(35));
	delayREG36 : REG PORT MAP(clk, vals(35), aad_delay(35), sof_delay(35), eof_delay(35), regs(4607 DOWNTO 4480), vals(36), regs(4735 DOWNTO 4608), aad_delay(36), sof_delay(36), eof_delay(36));
	delayREG37 : REG PORT MAP(clk, vals(36), aad_delay(36), sof_delay(36), eof_delay(36), regs(4735 DOWNTO 4608), vals(37), regs(4863 DOWNTO 4736), aad_delay(37), sof_delay(37), eof_delay(37));
	delayREG38 : REG PORT MAP(clk, vals(37), aad_delay(37), sof_delay(37), eof_delay(37), regs(4863 DOWNTO 4736), vals(38), regs(4991 DOWNTO 4864), aad_delay(38), sof_delay(38), eof_delay(38));
	delayREG39 : REG PORT MAP(clk, vals(38), aad_delay(38), sof_delay(38), eof_delay(38), regs(4991 DOWNTO 4864), vals(39), regs(5119 DOWNTO 4992), aad_delay(39), sof_delay(39), eof_delay(39));
	delayREG40 : REG PORT MAP(clk, vals(39), aad_delay(39), sof_delay(39), eof_delay(39), regs(5119 DOWNTO 4992), vals(40), regs(5247 DOWNTO 5120), aad_delay(40), sof_delay(40), eof_delay(40));
	delayREG41 : REG PORT MAP(clk, vals(40), aad_delay(40), sof_delay(40), eof_delay(40), regs(5247 DOWNTO 5120), vals(41), regs(5375 DOWNTO 5248), aad_delay(41), sof_delay(41), eof_delay(41));
	delayREG42 : REG PORT MAP(clk, vals(41), aad_delay(41), sof_delay(41), eof_delay(41), regs(5375 DOWNTO 5248), vals(42), regs(5503 DOWNTO 5376), aad_delay(42), sof_delay(42), eof_delay(42));
	delayREG43 : REG PORT MAP(clk, vals(42), aad_delay(42), sof_delay(42), eof_delay(42), regs(5503 DOWNTO 5376), vals(43), regs(5631 DOWNTO 5504), aad_delay(43), sof_delay(43), eof_delay(43));
	delayREG44 : REG PORT MAP(clk, vals(43), aad_delay(43), sof_delay(43), eof_delay(43), regs(5631 DOWNTO 5504), vals(44), regs(5759 DOWNTO 5632), aad_delay(44), sof_delay(44), eof_delay(44));
	delayREG45 : REG PORT MAP(clk, vals(44), aad_delay(44), sof_delay(44), eof_delay(44), regs(5759 DOWNTO 5632), vals(45), regs(5887 DOWNTO 5760), aad_delay(45), sof_delay(45), eof_delay(45));
	delayREG46 : REG PORT MAP(clk, vals(45), aad_delay(45), sof_delay(45), eof_delay(45), regs(5887 DOWNTO 5760), vals(46), regs(6015 DOWNTO 5888), aad_delay(46), sof_delay(46), eof_delay(46));
	delayREG47 : REG PORT MAP(clk, vals(46), aad_delay(46), sof_delay(46), eof_delay(46), regs(6015 DOWNTO 5888), vals(47), regs(6143 DOWNTO 6016), aad_delay(47), sof_delay(47), eof_delay(47));
	delayREG48 : REG PORT MAP(clk, vals(47), aad_delay(47), sof_delay(47), eof_delay(47), regs(6143 DOWNTO 6016), vals(48), regs(6271 DOWNTO 6144), aad_delay(48), sof_delay(48), eof_delay(48));
	delayREG49 : REG PORT MAP(clk, vals(48), aad_delay(48), sof_delay(48), eof_delay(48), regs(6271 DOWNTO 6144), vals(49), regs(6399 DOWNTO 6272), aad_delay(49), sof_delay(49), eof_delay(49));
	delayREG50 : REG PORT MAP(clk, vals(49), aad_delay(49), sof_delay(49), eof_delay(49), regs(6399 DOWNTO 6272), vals(50), regs(6527 DOWNTO 6400), aad_delay(50), sof_delay(50), eof_delay(50));
	delayREG51 : REG PORT MAP(clk, vals(50), aad_delay(50), sof_delay(50), eof_delay(50), regs(6527 DOWNTO 6400), vals(51), regs(6655 DOWNTO 6528), aad_delay(51), sof_delay(51), eof_delay(51));
	delayREG52 : REG PORT MAP(clk, vals(51), aad_delay(51), sof_delay(51), eof_delay(51), regs(6655 DOWNTO 6528), vals(52), regs(6783 DOWNTO 6656), aad_delay(52), sof_delay(52), eof_delay(52));
	delayREG53 : REG PORT MAP(clk, vals(52), aad_delay(52), sof_delay(52), eof_delay(52), regs(6783 DOWNTO 6656), vals(53), regs(6911 DOWNTO 6784), aad_delay(53), sof_delay(53), eof_delay(53));
	delayREG54 : REG PORT MAP(clk, vals(53), aad_delay(53), sof_delay(53), eof_delay(53), regs(6911 DOWNTO 6784), vals(54), regs(7039 DOWNTO 6912), aad_delay(54), sof_delay(54), eof_delay(54));
	delayREG55 : REG PORT MAP(clk, vals(54), aad_delay(54), sof_delay(54), eof_delay(54), regs(7039 DOWNTO 6912), vals(55), regs(7167 DOWNTO 7040), aad_delay(55), sof_delay(55), eof_delay(55));
	delayREG56 : REG PORT MAP(clk, vals(55), aad_delay(55), sof_delay(55), eof_delay(55), regs(7167 DOWNTO 7040), vals(56), regs(7295 DOWNTO 7168), aad_delay(56), sof_delay(56), eof_delay(56));
	delayREG57 : REG PORT MAP(clk, vals(56), aad_delay(56), sof_delay(56), eof_delay(56), regs(7295 DOWNTO 7168), vals(57), regs(7423 DOWNTO 7296), aad_delay(57), sof_delay(57), eof_delay(57));
	delayREG58 : REG PORT MAP(clk, vals(57), aad_delay(57), sof_delay(57), eof_delay(57), regs(7423 DOWNTO 7296), vals(58), regs(7551 DOWNTO 7424), aad_delay(58), sof_delay(58), eof_delay(58));
	delayREG59 : REG PORT MAP(clk, vals(58), aad_delay(58), sof_delay(58), eof_delay(58), regs(7551 DOWNTO 7424), vals(59), regs(7679 DOWNTO 7552), aad_delay(59), sof_delay(59), eof_delay(59));
	delayREG60 : REG PORT MAP(clk, vals(59), aad_delay(59), sof_delay(59), eof_delay(59), regs(7679 DOWNTO 7552), vals(60), regs(7807 DOWNTO 7680), aad_delay(60), sof_delay(60), eof_delay(60));
	delayREG61 : REG PORT MAP(clk, vals(60), aad_delay(60), sof_delay(60), eof_delay(60), regs(7807 DOWNTO 7680), vals(61), regs(7935 DOWNTO 7808), aad_delay(61), sof_delay(61), eof_delay(61));
	delayREG62 : REG PORT MAP(clk, vals(61), aad_delay(61), sof_delay(61), eof_delay(61), regs(7935 DOWNTO 7808), vals(62), regs(8063 DOWNTO 7936), aad_delay(62), sof_delay(62), eof_delay(62));
	delayREG63 : REG PORT MAP(clk, vals(62), aad_delay(62), sof_delay(62), eof_delay(62), regs(8063 DOWNTO 7936), vals(63), regs(8191 DOWNTO 8064), aad_delay(63), sof_delay(63), eof_delay(63));
	delayREG64 : REG PORT MAP(clk, vals(63), aad_delay(63), sof_delay(63), eof_delay(63), regs(8191 DOWNTO 8064), vals(64), regs(8319 DOWNTO 8192), aad_delay(64), sof_delay(64), eof_delay(64));
	delayREG65 : REG PORT MAP(clk, vals(64), aad_delay(64), sof_delay(64), eof_delay(64), regs(8319 DOWNTO 8192), vals(65), regs(8447 DOWNTO 8320), aad_delay(65), sof_delay(65), eof_delay(65));
	delayREG66 : REG PORT MAP(clk, vals(65), aad_delay(65), sof_delay(65), eof_delay(65), regs(8447 DOWNTO 8320), vals(66), regs(8575 DOWNTO 8448), aad_delay(66), sof_delay(66), eof_delay(66));
	delayREG67 : REG PORT MAP(clk, vals(66), aad_delay(66), sof_delay(66), eof_delay(66), regs(8575 DOWNTO 8448), vals(67), regs(8703 DOWNTO 8576), aad_delay(67), sof_delay(67), eof_delay(67));
	delayREG68 : REG PORT MAP(clk, vals(67), aad_delay(67), sof_delay(67), eof_delay(67), regs(8703 DOWNTO 8576), vals(68), regs(8831 DOWNTO 8704), aad_delay(68), sof_delay(68), eof_delay(68));
	delayREG69 : REG PORT MAP(clk, vals(68), aad_delay(68), sof_delay(68), eof_delay(68), regs(8831 DOWNTO 8704), vals(69), regs(8959 DOWNTO 8832), aad_delay(69), sof_delay(69), eof_delay(69));
	delayREG70 : REG PORT MAP(clk, vals(69), aad_delay(69), sof_delay(69), eof_delay(69), regs(8959 DOWNTO 8832), vals(70), regs(9087 DOWNTO 8960), aad_delay(70), sof_delay(70), eof_delay(70));
	delayREG71 : REG PORT MAP(clk, vals(70), aad_delay(70), sof_delay(70), eof_delay(70), regs(9087 DOWNTO 8960), run_valid, X, is_aad, start_of_frame, end_of_frame);

END;