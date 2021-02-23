LIBRARY ieee;
LIBRARY STD;
USE STD.textio.ALL;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AES_TB IS
END ENTITY;

ARCHITECTURE AES_TB_arc OF AES_TB IS

	COMPONENT AES IS
		PORT (
			clk : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			in_val : IN STD_LOGIC;
			in_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));

	END COMPONENT;

	COMPONENT invAES IS
	PORT (
		clk : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		in_val : IN STD_LOGIC;
		in_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));

	END COMPONENT;

	SIGNAL clk, out_val_TB, in_val_TB : STD_LOGIC;
	SIGNAL first : STD_LOGIC := '1';
	SIGNAL in_data_TB, out_data_TB, key_TB : STD_LOGIC_VECTOR(127 DOWNTO 0);
	

BEGIN
	stimulus : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR 5 ns;
		clk <= '1';
		WAIT FOR 5 ns;
	END PROCESS;

	DUT : AES PORT MAP(clk, key_TB, in_val_TB, in_data_TB, out_val_TB, out_data_TB);
	
	PROCESS BEGIN
		IF (first = '1') THEN
			in_val_TB <= '1';
			key_TB <= x"00000000000000000000000000000000";
			in_data_TB <= x"f34481ec3cc627bacd5dc3fb08f273e6";
			first <= '0';
			wait for 20 ns;
		ELSE
			in_val_TB <= '0';
			wait for 20 ns;
		END IF;
	END PROCESS;

END ARCHITECTURE;