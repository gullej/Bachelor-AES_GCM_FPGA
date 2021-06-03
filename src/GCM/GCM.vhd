LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY GCM IS
	PORT (
		clk, SOF, aad_val, enc_val : IN STD_LOGIC;
		num_bits : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		isDec, EOF : IN STD_LOGIC;
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
			clk, in_val, aad, frame_start, frame_end, isDec : IN STD_LOGIC;
			num_bits : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_bits : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			out_aad, out_frame_start, out_frame_end, out_isDec : OUT STD_LOGIC);
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

	SIGNAL val_enc, mult_val, val_count, mult_run, after_sof, vfin_enc, start_of_frame, end_of_frame, is_aad, after_after_eof, run_valid, in_valid, after_eof, in_aad, val_dec, is_dec : STD_LOGIC := '0';
	SIGNAL fin_enc, H, X, mult_product, full_counter, mult_input, aes_input, fin_hash, fin_length : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL num_bits_delay : STD_LOGIC_VECTOR(575 DOWNTO 0);
	SIGNAL vals, sof_delay, aad_delay, eof_delay, dec_delay : STD_LOGIC_VECTOR(70 DOWNTO 0);
	SIGNAL regs : STD_LOGIC_VECTOR(9087 DOWNTO 0);
	SIGNAL counter : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL aad_length, ptext_length : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');
	SIGNAL check_val : STD_LOGIC;
	SIGNAL bits_delayed : STD_LOGIC_VECTOR(7 DOWNTO 0);

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

	director : PROCESS (start_of_frame, mult_run, is_aad, sof_delay(69), sof_delay(70), end_of_frame, fin_enc, X, mult_input, mult_product, after_eof, after_after_eof, bits_delayed)
		VARIABLE temp_vector : STD_LOGIC_VECTOR(127 DOWNTO 0);
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
			ELSIF (end_of_frame = '1') THEN
				IF (is_aad = '1') THEN
					mult_input <= X XOR mult_product;
					mult_run <= '1';
				ELSE
					IF (bits_delayed = x"00") THEN
						output <= fin_enc XOR X;
						out_val <= '1';
						mult_input <= fin_enc XOR X XOR mult_product;
						mult_run <= '1';
						check_val <= '0';
					ELSE
						check_val <= '1';
						FOR i IN 0 TO 127 LOOP
							IF (i < (127 - to_integer(unsigned(bits_delayed)))) THEN
								temp_vector(i) := '0';
							ELSE
								temp_vector(i) := fin_enc(i) XOR X(i);
							END IF;
						END LOOP;
						output <= temp_vector;
						out_val <= '1';
						mult_input <= temp_vector XOR mult_product;
						mult_run <= '1';
					END IF;
				END IF;
			ELSE
				IF (is_aad = '1') THEN
					mult_input <= X XOR mult_product;
					mult_run <= '1';
				ELSE
					output <= fin_enc XOR X;
					out_val <= '1';
					mult_input <= fin_enc XOR X XOR mult_product;
					mult_run <= '1';
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
			after_eof <= end_of_frame;
			after_after_eof <= after_eof;
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
		--IF (RISING_EDGE(clk)) THEN -- this should not be here for it to work
			IF (SOF = '1') THEN
				IF (isDec = '1') THEN
					val_dec <= '1';
				END IF;
				in_valid <= '1';
			END IF;
			IF (EOF = '1') THEN
				IF (RISING_EDGE(clk)) THEN		
				in_valid <= '0';
				val_dec <= '0';
			END IF;
		END IF;
	END PROCESS;

	lengths : PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (run_valid = '1') THEN
				IF (is_aad = '1') THEN
					IF (bits_delayed = x"00") THEN
						aad_length <= aad_length + x"80";
					ELSE
						aad_length <= aad_length + bits_delayed;
					END IF;
				ELSE
					IF (bits_delayed = x"00") THEN
						ptext_length <= ptext_length + x"80";
					ELSE
						ptext_length <= ptext_length + bits_delayed;
					END IF;
				END IF;
			END IF;
			IF (after_after_eof = '1') THEN
				aad_length <= x"0000000000000000";
				ptext_length <= x"0000000000000000";
			END IF;
		END IF;
	END PROCESS;

	fin_length <= aad_length & ptext_length;

	U : AES PORT MAP(clk, key, val_enc, aes_input, vfin_enc, fin_enc);
	UU : bitParallel PORT MAP(clk, mult_run, H, mult_input, mult_val, mult_product);

	delayREG0 : REG PORT MAP(clk, in_valid, in_aad, SOF, EOF, val_dec, num_bits, input, vals(0), regs(127 DOWNTO 0), num_bits_delay(7 DOWNTO 0), aad_delay(0), sof_delay(0), eof_delay(0), dec_delay(0));
	delayREG1 : REG PORT MAP(clk, vals(0), aad_delay(0), sof_delay(0), eof_delay(0), dec_delay(0), num_bits_delay(7 DOWNTO 0), regs(127 DOWNTO 0), vals(1), regs(255 DOWNTO 128), num_bits_delay(15 DOWNTO 8), aad_delay(1), sof_delay(1), eof_delay(1), dec_delay(1));
	delayREG2 : REG PORT MAP(clk, vals(1), aad_delay(1), sof_delay(1), eof_delay(1), dec_delay(1), num_bits_delay(15 DOWNTO 8), regs(255 DOWNTO 128), vals(2), regs(383 DOWNTO 256), num_bits_delay(23 DOWNTO 16), aad_delay(2), sof_delay(2), eof_delay(2), dec_delay(2));
	delayREG3 : REG PORT MAP(clk, vals(2), aad_delay(2), sof_delay(2), eof_delay(2), dec_delay(2), num_bits_delay(23 DOWNTO 16), regs(383 DOWNTO 256), vals(3), regs(511 DOWNTO 384), num_bits_delay(31 DOWNTO 24), aad_delay(3), sof_delay(3), eof_delay(3), dec_delay(3));
	delayREG4 : REG PORT MAP(clk, vals(3), aad_delay(3), sof_delay(3), eof_delay(3), dec_delay(3), num_bits_delay(31 DOWNTO 24), regs(511 DOWNTO 384), vals(4), regs(639 DOWNTO 512), num_bits_delay(39 DOWNTO 32), aad_delay(4), sof_delay(4), eof_delay(4), dec_delay(4));
	delayREG5 : REG PORT MAP(clk, vals(4), aad_delay(4), sof_delay(4), eof_delay(4), dec_delay(4), num_bits_delay(39 DOWNTO 32), regs(639 DOWNTO 512), vals(5), regs(767 DOWNTO 640), num_bits_delay(47 DOWNTO 40), aad_delay(5), sof_delay(5), eof_delay(5), dec_delay(5));
	delayREG6 : REG PORT MAP(clk, vals(5), aad_delay(5), sof_delay(5), eof_delay(5), dec_delay(5), num_bits_delay(47 DOWNTO 40), regs(767 DOWNTO 640), vals(6), regs(895 DOWNTO 768), num_bits_delay(55 DOWNTO 48), aad_delay(6), sof_delay(6), eof_delay(6), dec_delay(6));
	delayREG7 : REG PORT MAP(clk, vals(6), aad_delay(6), sof_delay(6), eof_delay(6), dec_delay(6), num_bits_delay(55 DOWNTO 48), regs(895 DOWNTO 768), vals(7), regs(1023 DOWNTO 896), num_bits_delay(63 DOWNTO 56), aad_delay(7), sof_delay(7), eof_delay(7), dec_delay(7));
	delayREG8 : REG PORT MAP(clk, vals(7), aad_delay(7), sof_delay(7), eof_delay(7), dec_delay(7), num_bits_delay(63 DOWNTO 56), regs(1023 DOWNTO 896), vals(8), regs(1151 DOWNTO 1024), num_bits_delay(71 DOWNTO 64), aad_delay(8), sof_delay(8), eof_delay(8), dec_delay(8));
	delayREG9 : REG PORT MAP(clk, vals(8), aad_delay(8), sof_delay(8), eof_delay(8), dec_delay(8), num_bits_delay(71 DOWNTO 64), regs(1151 DOWNTO 1024), vals(9), regs(1279 DOWNTO 1152), num_bits_delay(79 DOWNTO 72), aad_delay(9), sof_delay(9), eof_delay(9), dec_delay(9));
	delayREG10 : REG PORT MAP(clk, vals(9), aad_delay(9), sof_delay(9), eof_delay(9), dec_delay(9), num_bits_delay(79 DOWNTO 72), regs(1279 DOWNTO 1152), vals(10), regs(1407 DOWNTO 1280), num_bits_delay(87 DOWNTO 80), aad_delay(10), sof_delay(10), eof_delay(10), dec_delay(10));
	delayREG11 : REG PORT MAP(clk, vals(10), aad_delay(10), sof_delay(10), eof_delay(10), dec_delay(10), num_bits_delay(87 DOWNTO 80), regs(1407 DOWNTO 1280), vals(11), regs(1535 DOWNTO 1408), num_bits_delay(95 DOWNTO 88), aad_delay(11), sof_delay(11), eof_delay(11), dec_delay(11));
	delayREG12 : REG PORT MAP(clk, vals(11), aad_delay(11), sof_delay(11), eof_delay(11), dec_delay(11), num_bits_delay(95 DOWNTO 88), regs(1535 DOWNTO 1408), vals(12), regs(1663 DOWNTO 1536), num_bits_delay(103 DOWNTO 96), aad_delay(12), sof_delay(12), eof_delay(12), dec_delay(12));
	delayREG13 : REG PORT MAP(clk, vals(12), aad_delay(12), sof_delay(12), eof_delay(12), dec_delay(12), num_bits_delay(103 DOWNTO 96), regs(1663 DOWNTO 1536), vals(13), regs(1791 DOWNTO 1664), num_bits_delay(111 DOWNTO 104), aad_delay(13), sof_delay(13), eof_delay(13), dec_delay(13));
	delayREG14 : REG PORT MAP(clk, vals(13), aad_delay(13), sof_delay(13), eof_delay(13), dec_delay(13), num_bits_delay(111 DOWNTO 104), regs(1791 DOWNTO 1664), vals(14), regs(1919 DOWNTO 1792), num_bits_delay(119 DOWNTO 112), aad_delay(14), sof_delay(14), eof_delay(14), dec_delay(14));
	delayREG15 : REG PORT MAP(clk, vals(14), aad_delay(14), sof_delay(14), eof_delay(14), dec_delay(14), num_bits_delay(119 DOWNTO 112), regs(1919 DOWNTO 1792), vals(15), regs(2047 DOWNTO 1920), num_bits_delay(127 DOWNTO 120), aad_delay(15), sof_delay(15), eof_delay(15), dec_delay(15));
	delayREG16 : REG PORT MAP(clk, vals(15), aad_delay(15), sof_delay(15), eof_delay(15), dec_delay(15), num_bits_delay(127 DOWNTO 120), regs(2047 DOWNTO 1920), vals(16), regs(2175 DOWNTO 2048), num_bits_delay(135 DOWNTO 128), aad_delay(16), sof_delay(16), eof_delay(16), dec_delay(16));
	delayREG17 : REG PORT MAP(clk, vals(16), aad_delay(16), sof_delay(16), eof_delay(16), dec_delay(16), num_bits_delay(135 DOWNTO 128), regs(2175 DOWNTO 2048), vals(17), regs(2303 DOWNTO 2176), num_bits_delay(143 DOWNTO 136), aad_delay(17), sof_delay(17), eof_delay(17), dec_delay(17));
	delayREG18 : REG PORT MAP(clk, vals(17), aad_delay(17), sof_delay(17), eof_delay(17), dec_delay(17), num_bits_delay(143 DOWNTO 136), regs(2303 DOWNTO 2176), vals(18), regs(2431 DOWNTO 2304), num_bits_delay(151 DOWNTO 144), aad_delay(18), sof_delay(18), eof_delay(18), dec_delay(18));
	delayREG19 : REG PORT MAP(clk, vals(18), aad_delay(18), sof_delay(18), eof_delay(18), dec_delay(18), num_bits_delay(151 DOWNTO 144), regs(2431 DOWNTO 2304), vals(19), regs(2559 DOWNTO 2432), num_bits_delay(159 DOWNTO 152), aad_delay(19), sof_delay(19), eof_delay(19), dec_delay(19));
	delayREG20 : REG PORT MAP(clk, vals(19), aad_delay(19), sof_delay(19), eof_delay(19), dec_delay(19), num_bits_delay(159 DOWNTO 152), regs(2559 DOWNTO 2432), vals(20), regs(2687 DOWNTO 2560), num_bits_delay(167 DOWNTO 160), aad_delay(20), sof_delay(20), eof_delay(20), dec_delay(20));
	delayREG21 : REG PORT MAP(clk, vals(20), aad_delay(20), sof_delay(20), eof_delay(20), dec_delay(20), num_bits_delay(167 DOWNTO 160), regs(2687 DOWNTO 2560), vals(21), regs(2815 DOWNTO 2688), num_bits_delay(175 DOWNTO 168), aad_delay(21), sof_delay(21), eof_delay(21), dec_delay(21));
	delayREG22 : REG PORT MAP(clk, vals(21), aad_delay(21), sof_delay(21), eof_delay(21), dec_delay(21), num_bits_delay(175 DOWNTO 168), regs(2815 DOWNTO 2688), vals(22), regs(2943 DOWNTO 2816), num_bits_delay(183 DOWNTO 176), aad_delay(22), sof_delay(22), eof_delay(22), dec_delay(22));
	delayREG23 : REG PORT MAP(clk, vals(22), aad_delay(22), sof_delay(22), eof_delay(22), dec_delay(22), num_bits_delay(183 DOWNTO 176), regs(2943 DOWNTO 2816), vals(23), regs(3071 DOWNTO 2944), num_bits_delay(191 DOWNTO 184), aad_delay(23), sof_delay(23), eof_delay(23), dec_delay(23));
	delayREG24 : REG PORT MAP(clk, vals(23), aad_delay(23), sof_delay(23), eof_delay(23), dec_delay(23), num_bits_delay(191 DOWNTO 184), regs(3071 DOWNTO 2944), vals(24), regs(3199 DOWNTO 3072), num_bits_delay(199 DOWNTO 192), aad_delay(24), sof_delay(24), eof_delay(24), dec_delay(24));
	delayREG25 : REG PORT MAP(clk, vals(24), aad_delay(24), sof_delay(24), eof_delay(24), dec_delay(24), num_bits_delay(199 DOWNTO 192), regs(3199 DOWNTO 3072), vals(25), regs(3327 DOWNTO 3200), num_bits_delay(207 DOWNTO 200), aad_delay(25), sof_delay(25), eof_delay(25), dec_delay(25));
	delayREG26 : REG PORT MAP(clk, vals(25), aad_delay(25), sof_delay(25), eof_delay(25), dec_delay(25), num_bits_delay(207 DOWNTO 200), regs(3327 DOWNTO 3200), vals(26), regs(3455 DOWNTO 3328), num_bits_delay(215 DOWNTO 208), aad_delay(26), sof_delay(26), eof_delay(26), dec_delay(26));
	delayREG27 : REG PORT MAP(clk, vals(26), aad_delay(26), sof_delay(26), eof_delay(26), dec_delay(26), num_bits_delay(215 DOWNTO 208), regs(3455 DOWNTO 3328), vals(27), regs(3583 DOWNTO 3456), num_bits_delay(223 DOWNTO 216), aad_delay(27), sof_delay(27), eof_delay(27), dec_delay(27));
	delayREG28 : REG PORT MAP(clk, vals(27), aad_delay(27), sof_delay(27), eof_delay(27), dec_delay(27), num_bits_delay(223 DOWNTO 216), regs(3583 DOWNTO 3456), vals(28), regs(3711 DOWNTO 3584), num_bits_delay(231 DOWNTO 224), aad_delay(28), sof_delay(28), eof_delay(28), dec_delay(28));
	delayREG29 : REG PORT MAP(clk, vals(28), aad_delay(28), sof_delay(28), eof_delay(28), dec_delay(28), num_bits_delay(231 DOWNTO 224), regs(3711 DOWNTO 3584), vals(29), regs(3839 DOWNTO 3712), num_bits_delay(239 DOWNTO 232), aad_delay(29), sof_delay(29), eof_delay(29), dec_delay(29));
	delayREG30 : REG PORT MAP(clk, vals(29), aad_delay(29), sof_delay(29), eof_delay(29), dec_delay(29), num_bits_delay(239 DOWNTO 232), regs(3839 DOWNTO 3712), vals(30), regs(3967 DOWNTO 3840), num_bits_delay(247 DOWNTO 240), aad_delay(30), sof_delay(30), eof_delay(30), dec_delay(30));
	delayREG31 : REG PORT MAP(clk, vals(30), aad_delay(30), sof_delay(30), eof_delay(30), dec_delay(30), num_bits_delay(247 DOWNTO 240), regs(3967 DOWNTO 3840), vals(31), regs(4095 DOWNTO 3968), num_bits_delay(255 DOWNTO 248), aad_delay(31), sof_delay(31), eof_delay(31), dec_delay(31));
	delayREG32 : REG PORT MAP(clk, vals(31), aad_delay(31), sof_delay(31), eof_delay(31), dec_delay(31), num_bits_delay(255 DOWNTO 248), regs(4095 DOWNTO 3968), vals(32), regs(4223 DOWNTO 4096), num_bits_delay(263 DOWNTO 256), aad_delay(32), sof_delay(32), eof_delay(32), dec_delay(32));
	delayREG33 : REG PORT MAP(clk, vals(32), aad_delay(32), sof_delay(32), eof_delay(32), dec_delay(32), num_bits_delay(263 DOWNTO 256), regs(4223 DOWNTO 4096), vals(33), regs(4351 DOWNTO 4224), num_bits_delay(271 DOWNTO 264), aad_delay(33), sof_delay(33), eof_delay(33), dec_delay(33));
	delayREG34 : REG PORT MAP(clk, vals(33), aad_delay(33), sof_delay(33), eof_delay(33), dec_delay(33), num_bits_delay(271 DOWNTO 264), regs(4351 DOWNTO 4224), vals(34), regs(4479 DOWNTO 4352), num_bits_delay(279 DOWNTO 272), aad_delay(34), sof_delay(34), eof_delay(34), dec_delay(34));
	delayREG35 : REG PORT MAP(clk, vals(34), aad_delay(34), sof_delay(34), eof_delay(34), dec_delay(34), num_bits_delay(279 DOWNTO 272), regs(4479 DOWNTO 4352), vals(35), regs(4607 DOWNTO 4480), num_bits_delay(287 DOWNTO 280), aad_delay(35), sof_delay(35), eof_delay(35), dec_delay(35));
	delayREG36 : REG PORT MAP(clk, vals(35), aad_delay(35), sof_delay(35), eof_delay(35), dec_delay(35), num_bits_delay(287 DOWNTO 280), regs(4607 DOWNTO 4480), vals(36), regs(4735 DOWNTO 4608), num_bits_delay(295 DOWNTO 288), aad_delay(36), sof_delay(36), eof_delay(36), dec_delay(36));
	delayREG37 : REG PORT MAP(clk, vals(36), aad_delay(36), sof_delay(36), eof_delay(36), dec_delay(36), num_bits_delay(295 DOWNTO 288), regs(4735 DOWNTO 4608), vals(37), regs(4863 DOWNTO 4736), num_bits_delay(303 DOWNTO 296), aad_delay(37), sof_delay(37), eof_delay(37), dec_delay(37));
	delayREG38 : REG PORT MAP(clk, vals(37), aad_delay(37), sof_delay(37), eof_delay(37), dec_delay(37), num_bits_delay(303 DOWNTO 296), regs(4863 DOWNTO 4736), vals(38), regs(4991 DOWNTO 4864), num_bits_delay(311 DOWNTO 304), aad_delay(38), sof_delay(38), eof_delay(38), dec_delay(38));
	delayREG39 : REG PORT MAP(clk, vals(38), aad_delay(38), sof_delay(38), eof_delay(38), dec_delay(38), num_bits_delay(311 DOWNTO 304), regs(4991 DOWNTO 4864), vals(39), regs(5119 DOWNTO 4992), num_bits_delay(319 DOWNTO 312), aad_delay(39), sof_delay(39), eof_delay(39), dec_delay(39));
	delayREG40 : REG PORT MAP(clk, vals(39), aad_delay(39), sof_delay(39), eof_delay(39), dec_delay(39), num_bits_delay(319 DOWNTO 312), regs(5119 DOWNTO 4992), vals(40), regs(5247 DOWNTO 5120), num_bits_delay(327 DOWNTO 320), aad_delay(40), sof_delay(40), eof_delay(40), dec_delay(40));
	delayREG41 : REG PORT MAP(clk, vals(40), aad_delay(40), sof_delay(40), eof_delay(40), dec_delay(40), num_bits_delay(327 DOWNTO 320), regs(5247 DOWNTO 5120), vals(41), regs(5375 DOWNTO 5248), num_bits_delay(335 DOWNTO 328), aad_delay(41), sof_delay(41), eof_delay(41), dec_delay(41));
	delayREG42 : REG PORT MAP(clk, vals(41), aad_delay(41), sof_delay(41), eof_delay(41), dec_delay(41), num_bits_delay(335 DOWNTO 328), regs(5375 DOWNTO 5248), vals(42), regs(5503 DOWNTO 5376), num_bits_delay(343 DOWNTO 336), aad_delay(42), sof_delay(42), eof_delay(42), dec_delay(42));
	delayREG43 : REG PORT MAP(clk, vals(42), aad_delay(42), sof_delay(42), eof_delay(42), dec_delay(42), num_bits_delay(343 DOWNTO 336), regs(5503 DOWNTO 5376), vals(43), regs(5631 DOWNTO 5504), num_bits_delay(351 DOWNTO 344), aad_delay(43), sof_delay(43), eof_delay(43), dec_delay(43));
	delayREG44 : REG PORT MAP(clk, vals(43), aad_delay(43), sof_delay(43), eof_delay(43), dec_delay(43), num_bits_delay(351 DOWNTO 344), regs(5631 DOWNTO 5504), vals(44), regs(5759 DOWNTO 5632), num_bits_delay(359 DOWNTO 352), aad_delay(44), sof_delay(44), eof_delay(44), dec_delay(44));
	delayREG45 : REG PORT MAP(clk, vals(44), aad_delay(44), sof_delay(44), eof_delay(44), dec_delay(44), num_bits_delay(359 DOWNTO 352), regs(5759 DOWNTO 5632), vals(45), regs(5887 DOWNTO 5760), num_bits_delay(367 DOWNTO 360), aad_delay(45), sof_delay(45), eof_delay(45), dec_delay(45));
	delayREG46 : REG PORT MAP(clk, vals(45), aad_delay(45), sof_delay(45), eof_delay(45), dec_delay(45), num_bits_delay(367 DOWNTO 360), regs(5887 DOWNTO 5760), vals(46), regs(6015 DOWNTO 5888), num_bits_delay(375 DOWNTO 368), aad_delay(46), sof_delay(46), eof_delay(46), dec_delay(46));
	delayREG47 : REG PORT MAP(clk, vals(46), aad_delay(46), sof_delay(46), eof_delay(46), dec_delay(46), num_bits_delay(375 DOWNTO 368), regs(6015 DOWNTO 5888), vals(47), regs(6143 DOWNTO 6016), num_bits_delay(383 DOWNTO 376), aad_delay(47), sof_delay(47), eof_delay(47), dec_delay(47));
	delayREG48 : REG PORT MAP(clk, vals(47), aad_delay(47), sof_delay(47), eof_delay(47), dec_delay(47), num_bits_delay(383 DOWNTO 376), regs(6143 DOWNTO 6016), vals(48), regs(6271 DOWNTO 6144), num_bits_delay(391 DOWNTO 384), aad_delay(48), sof_delay(48), eof_delay(48), dec_delay(48));
	delayREG49 : REG PORT MAP(clk, vals(48), aad_delay(48), sof_delay(48), eof_delay(48), dec_delay(48), num_bits_delay(391 DOWNTO 384), regs(6271 DOWNTO 6144), vals(49), regs(6399 DOWNTO 6272), num_bits_delay(399 DOWNTO 392), aad_delay(49), sof_delay(49), eof_delay(49), dec_delay(49));
	delayREG50 : REG PORT MAP(clk, vals(49), aad_delay(49), sof_delay(49), eof_delay(49), dec_delay(49), num_bits_delay(399 DOWNTO 392), regs(6399 DOWNTO 6272), vals(50), regs(6527 DOWNTO 6400), num_bits_delay(407 DOWNTO 400), aad_delay(50), sof_delay(50), eof_delay(50), dec_delay(50));
	delayREG51 : REG PORT MAP(clk, vals(50), aad_delay(50), sof_delay(50), eof_delay(50), dec_delay(50), num_bits_delay(407 DOWNTO 400), regs(6527 DOWNTO 6400), vals(51), regs(6655 DOWNTO 6528), num_bits_delay(415 DOWNTO 408), aad_delay(51), sof_delay(51), eof_delay(51), dec_delay(51));
	delayREG52 : REG PORT MAP(clk, vals(51), aad_delay(51), sof_delay(51), eof_delay(51), dec_delay(51), num_bits_delay(415 DOWNTO 408), regs(6655 DOWNTO 6528), vals(52), regs(6783 DOWNTO 6656), num_bits_delay(423 DOWNTO 416), aad_delay(52), sof_delay(52), eof_delay(52), dec_delay(52));
	delayREG53 : REG PORT MAP(clk, vals(52), aad_delay(52), sof_delay(52), eof_delay(52), dec_delay(52), num_bits_delay(423 DOWNTO 416), regs(6783 DOWNTO 6656), vals(53), regs(6911 DOWNTO 6784), num_bits_delay(431 DOWNTO 424), aad_delay(53), sof_delay(53), eof_delay(53), dec_delay(53));
	delayREG54 : REG PORT MAP(clk, vals(53), aad_delay(53), sof_delay(53), eof_delay(53), dec_delay(53), num_bits_delay(431 DOWNTO 424), regs(6911 DOWNTO 6784), vals(54), regs(7039 DOWNTO 6912), num_bits_delay(439 DOWNTO 432), aad_delay(54), sof_delay(54), eof_delay(54), dec_delay(54));
	delayREG55 : REG PORT MAP(clk, vals(54), aad_delay(54), sof_delay(54), eof_delay(54), dec_delay(54), num_bits_delay(439 DOWNTO 432), regs(7039 DOWNTO 6912), vals(55), regs(7167 DOWNTO 7040), num_bits_delay(447 DOWNTO 440), aad_delay(55), sof_delay(55), eof_delay(55), dec_delay(55));
	delayREG56 : REG PORT MAP(clk, vals(55), aad_delay(55), sof_delay(55), eof_delay(55), dec_delay(55), num_bits_delay(447 DOWNTO 440), regs(7167 DOWNTO 7040), vals(56), regs(7295 DOWNTO 7168), num_bits_delay(455 DOWNTO 448), aad_delay(56), sof_delay(56), eof_delay(56), dec_delay(56));
	delayREG57 : REG PORT MAP(clk, vals(56), aad_delay(56), sof_delay(56), eof_delay(56), dec_delay(56), num_bits_delay(455 DOWNTO 448), regs(7295 DOWNTO 7168), vals(57), regs(7423 DOWNTO 7296), num_bits_delay(463 DOWNTO 456), aad_delay(57), sof_delay(57), eof_delay(57), dec_delay(57));
	delayREG58 : REG PORT MAP(clk, vals(57), aad_delay(57), sof_delay(57), eof_delay(57), dec_delay(57), num_bits_delay(463 DOWNTO 456), regs(7423 DOWNTO 7296), vals(58), regs(7551 DOWNTO 7424), num_bits_delay(471 DOWNTO 464), aad_delay(58), sof_delay(58), eof_delay(58), dec_delay(58));
	delayREG59 : REG PORT MAP(clk, vals(58), aad_delay(58), sof_delay(58), eof_delay(58), dec_delay(58), num_bits_delay(471 DOWNTO 464), regs(7551 DOWNTO 7424), vals(59), regs(7679 DOWNTO 7552), num_bits_delay(479 DOWNTO 472), aad_delay(59), sof_delay(59), eof_delay(59), dec_delay(59));
	delayREG60 : REG PORT MAP(clk, vals(59), aad_delay(59), sof_delay(59), eof_delay(59), dec_delay(59), num_bits_delay(479 DOWNTO 472), regs(7679 DOWNTO 7552), vals(60), regs(7807 DOWNTO 7680), num_bits_delay(487 DOWNTO 480), aad_delay(60), sof_delay(60), eof_delay(60), dec_delay(60));
	delayREG61 : REG PORT MAP(clk, vals(60), aad_delay(60), sof_delay(60), eof_delay(60), dec_delay(60), num_bits_delay(487 DOWNTO 480), regs(7807 DOWNTO 7680), vals(61), regs(7935 DOWNTO 7808), num_bits_delay(495 DOWNTO 488), aad_delay(61), sof_delay(61), eof_delay(61), dec_delay(61));
	delayREG62 : REG PORT MAP(clk, vals(61), aad_delay(61), sof_delay(61), eof_delay(61), dec_delay(61), num_bits_delay(495 DOWNTO 488), regs(7935 DOWNTO 7808), vals(62), regs(8063 DOWNTO 7936), num_bits_delay(503 DOWNTO 496), aad_delay(62), sof_delay(62), eof_delay(62), dec_delay(62));
	delayREG63 : REG PORT MAP(clk, vals(62), aad_delay(62), sof_delay(62), eof_delay(62), dec_delay(62), num_bits_delay(503 DOWNTO 496), regs(8063 DOWNTO 7936), vals(63), regs(8191 DOWNTO 8064), num_bits_delay(511 DOWNTO 504), aad_delay(63), sof_delay(63), eof_delay(63), dec_delay(63));
	delayREG64 : REG PORT MAP(clk, vals(63), aad_delay(63), sof_delay(63), eof_delay(63), dec_delay(63), num_bits_delay(511 DOWNTO 504), regs(8191 DOWNTO 8064), vals(64), regs(8319 DOWNTO 8192), num_bits_delay(519 DOWNTO 512), aad_delay(64), sof_delay(64), eof_delay(64), dec_delay(64));
	delayREG65 : REG PORT MAP(clk, vals(64), aad_delay(64), sof_delay(64), eof_delay(64), dec_delay(64), num_bits_delay(519 DOWNTO 512), regs(8319 DOWNTO 8192), vals(65), regs(8447 DOWNTO 8320), num_bits_delay(527 DOWNTO 520), aad_delay(65), sof_delay(65), eof_delay(65), dec_delay(65));
	delayREG66 : REG PORT MAP(clk, vals(65), aad_delay(65), sof_delay(65), eof_delay(65), dec_delay(65), num_bits_delay(527 DOWNTO 520), regs(8447 DOWNTO 8320), vals(66), regs(8575 DOWNTO 8448), num_bits_delay(535 DOWNTO 528), aad_delay(66), sof_delay(66), eof_delay(66), dec_delay(66));
	delayREG67 : REG PORT MAP(clk, vals(66), aad_delay(66), sof_delay(66), eof_delay(66), dec_delay(66), num_bits_delay(535 DOWNTO 528), regs(8575 DOWNTO 8448), vals(67), regs(8703 DOWNTO 8576), num_bits_delay(543 DOWNTO 536), aad_delay(67), sof_delay(67), eof_delay(67), dec_delay(67));
	delayREG68 : REG PORT MAP(clk, vals(67), aad_delay(67), sof_delay(67), eof_delay(67), dec_delay(67), num_bits_delay(543 DOWNTO 536), regs(8703 DOWNTO 8576), vals(68), regs(8831 DOWNTO 8704), num_bits_delay(551 DOWNTO 544), aad_delay(68), sof_delay(68), eof_delay(68), dec_delay(68));
	delayREG69 : REG PORT MAP(clk, vals(68), aad_delay(68), sof_delay(68), eof_delay(68), dec_delay(68), num_bits_delay(551 DOWNTO 544), regs(8831 DOWNTO 8704), vals(69), regs(8959 DOWNTO 8832), num_bits_delay(559 DOWNTO 552), aad_delay(69), sof_delay(69), eof_delay(69), dec_delay(69));
	delayREG70 : REG PORT MAP(clk, vals(69), aad_delay(69), sof_delay(69), eof_delay(69), dec_delay(69), num_bits_delay(559 DOWNTO 552), regs(8959 DOWNTO 8832), vals(70), regs(9087 DOWNTO 8960), num_bits_delay(567 DOWNTO 560), aad_delay(70), sof_delay(70), eof_delay(70), dec_delay(70));

	delayREG71 : REG PORT MAP(clk, vals(70), aad_delay(70), sof_delay(70), eof_delay(70), dec_delay(70), num_bits_delay(567 DOWNTO 560), regs(9087 DOWNTO 8960), run_valid, X, bits_delayed, is_aad, start_of_frame, end_of_frame, is_Dec);
END;