LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY SubBytesWord IS
	PORT (
		clk, in_val : IN STD_LOGIC;
		data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));

END ENTITY;

ARCHITECTURE SubBytesWord_arc OF SubBytesWord IS

	COMPONENT SubBytesROM
		PORT (
			clock, in_val : IN STD_LOGIC;
			address : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT;

	SIGNAL data_temp : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL vals : STD_LOGIC_VECTOR(3 DOWNTO 0) := x"0";

BEGIN

	U1 : SubBytesROM PORT MAP(clk, in_val, data_in(31 DOWNTO 24), vals(0), data_temp(31 DOWNTO 24));
	U2 : SubBytesROM PORT MAP(clk, in_val, data_in(23 DOWNTO 16), vals(1), data_temp(23 DOWNTO 16));
	U3 : SubBytesROM PORT MAP(clk, in_val, data_in(15 DOWNTO 8), vals(2), data_temp(15 DOWNTO 8));
	U4 : SubBytesROM PORT MAP(clk, in_val, data_in(7 DOWNTO 0), vals(3), data_temp(7 DOWNTO 0));

	incrementer : PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (vals = x"f") THEN
				out_data <= data_temp;
				out_val <= '1';
			ELSE
				out_val <= '0';
			END IF;
		END IF;
	END PROCESS;

END ARCHITECTURE;