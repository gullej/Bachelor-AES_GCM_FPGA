LIBRARY ieee;
--LIBRARY STD;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY TB_Counter IS
END ENTITY;

ARCHITECTURE TB_Counter_arc OF TB_Counter IS

	COMPONENT CounterMode IS
	PORT (
		clk, in_valid : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		iv : IN STD_LOGIC_VECTOR(95 DOWNTO 0);
		input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	SIGNAL clk, fin_val_TB : STD_LOGIC;
	SIGNAL in_val_TB : STD_LOGIC;
	SIGNAL input_TB, output_TB : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL key_TB : STD_LOGIC_VECTOR(127 DOWNTO 0) := x"4c80cdefbb5d10da906ac73c3613a634";
	SIGNAL counter_TB : STD_LOGIC_VECTOR(95 DOWNTO 0) := x"2e443b684956ed7e3b244cfe";
	
BEGIN
	stimulus : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR 5 ns;
		clk <= '1';
		WAIT FOR 5 ns;
	END PROCESS;

	DUT : CounterMode PORT MAP(clk, in_val_TB, key_TB, counter_TB, input_TB, fin_val_TB, output_TB);

	reader : PROCESS(clk)

	FILE plains  : TEXT OPEN READ_MODE  IS "../CounterMode/testbench/test_case_1.txt";
	--FILE ciphers : TEXT OPEN WRITE_MODE IS "testbench/test_ciphers.txt";
	VARIABLE v_ILINE : LINE;
	--VARIABLE v_OLINE : LINE;
	VARIABLE v_in_data  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	--VARIABLE v_out_data : STD_LOGIC_VECTOR(127 DOWNTO 0);
	
	BEGIN
		IF( RISING_EDGE(clk)) THEN
			IF (NOT ENDFILE(plains)) THEN
					READLINE(plains, v_ILINE);
					HREAD(v_ILINE, v_in_data);
	
					in_val_TB <= '1';
			ELSE

					in_val_TB <= '0';
			END IF;

			input_TB <= v_in_data;
			--v_out_data <= fin_data_TB;

		END IF;

		

		
	END PROCESS;

END ARCHITECTURE;