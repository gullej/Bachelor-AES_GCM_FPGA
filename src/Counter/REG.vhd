LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY REG IS
	PORT (
		clk, in_val : IN STD_LOGIC;
		state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY REG;

ARCHITECTURE REG_arc OF REG IS


BEGIN
	clock : PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
			IF (in_val = '1') THEN
				out_state <= state;
				out_val <= '1';
			ELSE
				out_val <= '0';
			END IF;
		END IF;
	END PROCESS;

END;