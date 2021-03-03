LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY AddKey IS
	PORT (
		clk, in_val : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY AddKey;

ARCHITECTURE rtl OF AddKey IS
	SIGNAL addition : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL val1 : STD_LOGIC := '0';

BEGIN
	addition(127 DOWNTO 0) <= state(127 DOWNTO 0) XOR key(127 DOWNTO 0);

	clock : PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
			IF (in_val = '1') THEN
				out_state <= addition;
				out_val <= '1';
			ELSE
				out_val <= '0';
			END IF;
		END IF;
	END PROCESS;

END;