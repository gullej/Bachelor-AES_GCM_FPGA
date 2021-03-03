LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY SubBytes IS
	PORT (
		clk, in_val : IN STD_LOGIC;
		data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));

END ENTITY;

ARCHITECTURE SubBytes_arc OF SubBytes IS

	COMPONENT SubBytesROM
		PORT (
			clock, in_val : IN STD_LOGIC;
			address : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			out_VAL : OUT STD_LOGIC;
			out_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT;

	SIGNAL data_temp : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL vals : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000";

BEGIN

	U1  : SubBytesROM PORT MAP(clk, in_val, data_in(127 DOWNTO 120), vals(0),  data_temp(127 DOWNTO 120));
	U2  : SubBytesROM PORT MAP(clk, in_val, data_in(119 DOWNTO 112), vals(1),  data_temp(119 DOWNTO 112));
	U3  : SubBytesROM PORT MAP(clk, in_val, data_in(111 DOWNTO 104), vals(2),  data_temp(111 DOWNTO 104));
	U4  : SubBytesROM PORT MAP(clk, in_val, data_in(103 DOWNTO 96),  vals(3),  data_temp(103 DOWNTO 96));
	U5  : SubBytesROM PORT MAP(clk, in_val, data_in(95 DOWNTO 88),   vals(4),  data_temp(95 DOWNTO 88));
	U6  : SubBytesROM PORT MAP(clk, in_val, data_in(87 DOWNTO 80),   vals(5),  data_temp(87 DOWNTO 80));
	U7  : SubBytesROM PORT MAP(clk, in_val, data_in(79 DOWNTO 72),   vals(6),  data_temp(79 DOWNTO 72));
	U8  : SubBytesROM PORT MAP(clk, in_val, data_in(71 DOWNTO 64),   vals(7),  data_temp(71 DOWNTO 64));
	U9  : SubBytesROM PORT MAP(clk, in_val, data_in(63 DOWNTO 56),   vals(8),  data_temp(63 DOWNTO 56));
	U10 : SubBytesROM PORT MAP(clk, in_val, data_in(55 DOWNTO 48),   vals(9),  data_temp(55 DOWNTO 48));
	U11 : SubBytesROM PORT MAP(clk, in_val, data_in(47 DOWNTO 40),   vals(10), data_temp(47 DOWNTO 40));
	U12 : SubBytesROM PORT MAP(clk, in_val, data_in(39 DOWNTO 32),   vals(11), data_temp(39 DOWNTO 32));
	U13 : SubBytesROM PORT MAP(clk, in_val, data_in(31 DOWNTO 24),   vals(12), data_temp(31 DOWNTO 24));
	U14 : SubBytesROM PORT MAP(clk, in_val, data_in(23 DOWNTO 16),   vals(13), data_temp(23 DOWNTO 16));
	U15 : SubBytesROM PORT MAP(clk, in_val, data_in(15 DOWNTO 8),    vals(14), data_temp(15 DOWNTO 8));
	U16 : SubBytesROM PORT MAP(clk, in_val, data_in(7 DOWNTO 0),     vals(15), data_temp(7 DOWNTO 0));

	incrementer : PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (vals = x"ffff") THEN
				out_state <= data_temp;
				out_val <= '1';
			ELSE
				out_val <= '0';
			END IF;
		END IF;

	END PROCESS;

END ARCHITECTURE;