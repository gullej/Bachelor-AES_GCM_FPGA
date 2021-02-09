LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ShiftRows IS

	PORT (
		clk, in_val : IN STD_LOGIC;
		input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE ShiftRows_arch OF ShiftRows IS
	SIGNAL output : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL val1 : STD_LOGIC := '0';
BEGIN

	--Shifting 1st row
	output(127 DOWNTO 120) <= input(127 DOWNTO 120);
	output(95 DOWNTO 88) <= input(95 DOWNTO 88);
	output(63 DOWNTO 56) <= input(63 DOWNTO 56);
	output(31 DOWNTO 24) <= input(31 DOWNTO 24);

	--Shifting 2nd row
	output(119 DOWNTO 112) <= input(87 DOWNTO 80);
	output(87 DOWNTO 80) <= input(55 DOWNTO 48);
	output(55 DOWNTO 48) <= input(23 DOWNTO 16);
	output(23 DOWNTO 16) <= input(119 DOWNTO 112);

	--Shifting 3rd row
	output(111 DOWNTO 104) <= input(47 DOWNTO 40);
	output(79 DOWNTO 72) <= input(15 DOWNTO 8);
	output(47 DOWNTO 40) <= input(111 DOWNTO 104);
	output(15 DOWNTO 8) <= input(79 DOWNTO 72);
	--Shifting 4th row
	output(103 DOWNTO 96) <= input(7 DOWNTO 0);
	output(71 DOWNTO 64) <= input(103 DOWNTO 96);
	output(39 DOWNTO 32) <= input(71 DOWNTO 64);
	output(7 DOWNTO 0) <= input(39 DOWNTO 32);

	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF (in_val = '1') THEN
				val1 <= '1';
			END IF;
			IF (val1 = '1') THEN
				out_state <= output;
				out_val <= '1';
				val1 <= '0';
			ELSE
				out_val <= '0';
			END IF;
		END IF;

	END PROCESS;
END ARCHITECTURE;