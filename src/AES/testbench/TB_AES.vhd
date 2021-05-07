LIBRARY ieee;
--LIBRARY STD;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY TB_AES IS
END ENTITY;

ARCHITECTURE TB_AES_arc OF TB_AES IS

	COMPONENT AES IS
		PORT (
			clk : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			in_val : IN STD_LOGIC;
			in_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			fin_val : OUT STD_LOGIC;
			fin_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));

	END COMPONENT;

	SIGNAL clk, fin_val_TB : STD_LOGIC;
	SIGNAL in_val_TB : STD_LOGIC;
	SIGNAL in_data_TB, fin_data_TB : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL key_TB : STD_LOGIC_VECTOR(127 DOWNTO 0) := x"00000000000000000000000000000000";
	
BEGIN
	stimulus : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR 5 ns;
		clk <= '1';
		WAIT FOR 5 ns;
	END PROCESS;

	DUT : AES PORT MAP(clk, key_TB, in_val_TB, in_data_TB, fin_val_TB, fin_data_TB);
	
	reader : PROCESS(clk)
	FILE plains  : TEXT OPEN READ_MODE  IS "../AES/testbench/test_plains.txt";
	FILE ciphers : TEXT OPEN WRITE_MODE IS "../AES/testbench/test_ciphers.txt";
	VARIABLE v_ILINE : LINE;
	VARIABLE v_OLINE : LINE;
	VARIABLE v_in_data  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	VARIABLE v_out_data : STD_LOGIC_VECTOR(127 DOWNTO 0);
	
	BEGIN
		IF( RISING_EDGE(clk)) THEN
			IF (NOT ENDFILE(plains)) THEN
					READLINE(plains, v_ILINE);
					HREAD(v_ILINE, v_in_data);
	
					in_val_TB <= '1';
			ELSE

					in_val_TB <= '0';
			END IF;

			in_data_TB <= v_in_data;
			--v_out_data <= fin_data_TB;

		END IF;

		

		
	END PROCESS;

END ARCHITECTURE;