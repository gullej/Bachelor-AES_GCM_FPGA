LIBRARY ieee;
--LIBRARY STD;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY TB_GCM IS
END ENTITY;

ARCHITECTURE TB_GCM_arc OF TB_GCM IS

	COMPONENT GCM IS
	PORT (
		clk, SOF, aad_val, enc_val : IN STD_LOGIC;
		num_bits : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		is_dec, EOF : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		iv : IN STD_LOGIC_VECTOR(95 DOWNTO 0);
		input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val, out_tag : OUT STD_LOGIC;
		output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	SIGNAL clk, fin_val_TB, aad_val_TB, SOF_TB, enc_val_TB, is_dec_TB, out_tag_TB, EOF_TB : STD_LOGIC;
	SIGNAL num_bytes_TB : STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL input_TB, output_TB : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL key_TB : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL iv_TB : STD_LOGIC_VECTOR(95 DOWNTO 0);
	
BEGIN
	stimulus : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR 5 ns;
		clk <= '1';
		WAIT FOR 5 ns;
	END PROCESS;

	DUT : GCM PORT MAP(clk, SOF_TB, aad_val_TB, enc_val_TB, num_bytes_TB, is_dec_TB, EOF_TB, key_TB, iv_TB, input_TB, fin_val_TB, out_tag_TB, output_TB);

	reader : PROCESS(clk)

	FILE plains  : TEXT OPEN READ_MODE  IS "../GCM/testbench/test_case_3.txt";
	VARIABLE v_ILINE : LINE;
	VARIABLE v_in_data  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	VARIABLE v_in_key : STD_LOGIC_VECTOR(127 DOWNTO 0);
	VARIABLE v_in_iv : STD_LOGIC_VECTOR(95 DOWNTO 0);
	VARIABLE v_aad_val, v_SoF, v_enc_val, v_is_dec, v_EOF  : STD_LOGIC;
	VARIABLE v_num_bytes : STD_LOGIC_VECTOR(7 downto 0);
	VARIABLE v_SPACE : character;
	--1, v_SPACE2, v_SPACE3, v_SPACE4 
	--VARIABLE  : STD_LOGIC;
	VARIABLE counter : STD_LOGIC_VECTOR(1 downto 0) := "01";
	
	BEGIN
		IF( RISING_EDGE(clk)) THEN
			IF (counter = "01") THEN
				READLINE(plains, v_ILINE);
				HREAD(v_ILINE, v_in_key);
				counter := counter + '1';
			ELSIF (counter = "10") THEN
				READLINE(plains, v_ILINE);
				HREAD(v_ILINE, v_in_iv);
				counter := counter + '1';
			ELSIF (NOT ENDFILE(plains)) THEN
					READLINE(plains, v_ILINE);
					HREAD(v_ILINE, v_in_data);
						READ(v_ILINE, v_SPACE);
					READ(v_ILINE, v_SOF);
						READ(v_ILINE, v_SPACE);
					READ(V_ILINE, v_aad_val);
						READ(v_ILINE, v_SPACE);
					READ(V_ILINE, v_enc_val);
						READ(v_ILINE, v_SPACE);
					HREAD(v_ILINE, v_num_bytes);
						READ(v_ILINE, v_SPACE);
					READ(V_ILINE, v_is_dec);
						READ(v_ILINE, v_SPACE);
					READ(V_ILINE, v_EOF);
			ELSE
				v_in_data := x"00000000000000000000000000000000";
				v_SOF := '0';
				v_aad_val := '0';
				v_enc_val := '0';
				v_num_bytes := x"00";
				v_is_dec := '0';
				v_EOF := '0';

			END IF;
			key_TB <= v_in_key;
			iv_TB <= v_in_iv;
			input_TB <= v_in_data;
			SOF_TB <= v_SOF;
			aad_val_TB <= v_aad_val;
			enc_val_TB <= v_enc_val;
			num_bytes_TB <= v_num_bytes;
			is_dec_TB <= v_is_dec;
			EOF_TB <= v_EOF;

		END IF;
	END PROCESS;
END ARCHITECTURE;