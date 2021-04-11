
LIBRARY ieee;
--LIBRARY STD;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY TB_ghash IS
END ENTITY;

ARCHITECTURE TB_GHASH_arc OF TB_GHASH IS

	COMPONENT GHASH IS
		PORT (
			clk : IN STD_LOGIC;
			in_val : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			auth_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_product : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	SIGNAL clk, in_val_TB, out_val_TB : STD_LOGIC;
	SIGNAL key_TB : STD_LOGIC_VECTOR(127 DOWNTO 0) := (others => '0');
	SIGNAL auth_TB, out_product_TB : STD_LOGIC_VECTOR(127 DOWNTO 0);
	
BEGIN
	stimulus : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR 5 ns;
		clk <= '1';
		WAIT FOR 5 ns;
	END PROCESS;

	DUT : GHASH PORT MAP(clk, in_val_TB, key_TB, auth_TB, out_val_TB, out_product_TB);

	reader : PROCESS (clk)

	FILE plains : TEXT OPEN READ_MODE  IS "testbench/test_hashes.txt";
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

			auth_TB <= v_in_data;
		END IF;
	END PROCESS;


END ARCHITECTURE;