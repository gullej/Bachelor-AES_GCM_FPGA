
LIBRARY ieee;
--LIBRARY STD;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY TB_multH IS
END ENTITY;

ARCHITECTURE TB_multH_arc OF TB_multH IS

COMPONENT multH IS
	PORT (
		clk : IN STD_LOGIC;
		in_val : IN STD_LOGIC;
		X : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		Y : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_product : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END COMPONENT;

	SIGNAL clk, in_val_TB, out_val_TB : STD_LOGIC;
	SIGNAL X_TB, Y_TB, out_product_TB : STD_LOGIC_VECTOR(127 DOWNTO 0);
	
	
BEGIN
	stimulus : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR 5 ns;
		clk <= '1';
		WAIT FOR 5 ns;
	END PROCESS;

	DUT : multH PORT MAP(clk, in_val_TB, X_TB, Y_TB, out_val_TB, out_product_TB);

	reader : PROCESS (clk)

	FILE multipliers : TEXT OPEN READ_MODE  IS "testbench/test_multipliers.txt";
	VARIABLE v_ILINE : LINE;
	VARIABLE v_OLINE : LINE;
	VARIABLE v_in_data1  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	VARIABLE v_in_data2  : STD_LOGIC_VECTOR(127 DOWNTO 0);
	VARIABLE v_out_data : STD_LOGIC_VECTOR(127 DOWNTO 0);
	VARIABLE v_SPACE    : character;

	BEGIN

		IF( RISING_EDGE(clk)) THEN
			IF (NOT ENDFILE(multipliers)) THEN
					READLINE(multipliers, v_ILINE);
					HREAD(v_ILINE, v_in_data1);
					READ(v_ILINE, v_SPACE);
					HREAD(v_ILINE, v_in_data2);
					in_val_TB <= '1';
			ELSE

					in_val_TB <= '0';
			END IF;

			X_TB <= v_in_data1;
			Y_TB <= v_in_data2;
		END IF;
	END PROCESS;


END ARCHITECTURE;