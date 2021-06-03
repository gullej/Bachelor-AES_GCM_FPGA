LIBRARY ieee;
--LIBRARY STD;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY TB_ESP IS
END ENTITY;

ARCHITECTURE TB_ESP_arc OF TB_ESP IS

	COMPONENT ESP IS
	PORT (
		clk, sof, eof : IN STD_LOGIC;
		num_bits : IN STD_LOGIC_VECTOR(7 downto 0);
		is_dec : IN STD_LOGIC;
		input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val: OUT STD_LOGIC;
		output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;


	signal clk, sof_TB, eof_TB, out_val_TB, is_dec_TB : STD_LOGIC;
	SIGNAL num_bits_TB : STD_LOGIC_VECTOR(7 downto 0);
	signal input_TB, output_TB : STD_LOGIC_VECTOR(127 downto 0);
	
BEGIN
	stimulus : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR 5 ns;
		clk <= '1';
		WAIT FOR 5 ns;
	END PROCESS;


	DUT : ESP PORT MAP(clk, sof_TB, eof_TB, num_bits_TB, is_dec_TB, input_TB, out_val_TB, output_TB);

	reader : PROCESS(clk)

	FILE tester  : TEXT OPEN READ_MODE  IS "../ESP/testbench/test_case_2.txt";
	VARIABLE v_ILINE : LINE;
	VARIABLE v_in_data  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	VARIABLE v_in_sof, v_in_eof, v_in_isDec  : STD_LOGIC;
	VARIABLE v_numBits : STD_LOGIC_VECTOR(7 downto 0);
	VARIABLE v_SPACE : character;
	
	BEGIN
		IF( RISING_EDGE(clk)) THEN
			IF (NOT ENDFILE(tester)) THEN
					READLINE(tester, v_ILINE);
					HREAD(v_ILINE, v_in_data);
						READ(v_ILINE, v_SPACE);
					READ(v_ILINE, v_in_sof);
					READ(v_ILINE, v_SPACE);
					READ(v_ILINE, v_in_eof);
					HREAD(v_ILINE, v_numBits);
						READ(v_ILINE, v_SPACE);
					READ(V_ILINE, v_in_isDec);
			ELSE
				v_in_data := x"00000000000000000000000000000000" ;
				v_in_sof := '0';
				v_in_eof := '0';
				v_in_isDec := '0';
				v_numBits := x"00";

			END IF;
			
			sof_TB <= v_in_sof;
			eof_TB <= v_in_eof;
			num_bits_TB <= v_numBits;
			is_dec_TB <= v_in_isDec;
			input_TB <= v_in_data;
			
			
		END IF;
	END PROCESS;
END ARCHITECTURE;