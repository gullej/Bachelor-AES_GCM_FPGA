LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY loopMult IS
	PORT (
		clk : IN STD_LOGIC;
		in_val : IN STD_LOGIC;
		X : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		Y : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_product : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE loopMult_arc OF loopMult IS

	SIGNAL R : STD_LOGIC_VECTOR(127 DOWNTO 0) := ("11100001" & x"000000000000000000000000000000");
	SIGNAL A,B : STD_LOGIC_VECTOR(127 DOWNTO 0);
	
BEGIN

	PROCESS (clk)
	BEGIN
	IF (RISING_EDGE(clk)) THEN
		A <= X;
		B <= Y;
	END IF;
	END PROCESS;

	multiplier : PROCESS (clk)
		VARIABLE Z_v : STD_LOGIC_VECTOR(127 DOWNTO 0);
		VARIABLE V_v : STD_LOGIC_VECTOR(127 DOWNTO 0);
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (in_val = '1') THEN
				V_v := B;
				Z_v := (others => '0');

				looper : FOR i IN 0 TO 127 LOOP
					IF (A(127-i) = '0') THEN
						Z_v := Z_v;
					ELSE
						Z_v := Z_v xor V_v;
					END IF;

					IF (V_v(0) = '0') THEN
						V_v :=  '0' & V_v(127 downto 1);
					ELSE
						V_v :=  ('0' & V_v(127 downto 1)) xor R;
					END IF;
				END LOOP looper;
				
				out_product <= Z_v;
				out_val <= '1';
				ELSE
					out_val <= '0';
			END IF;

	
		END IF;

	END PROCESS;

END ARCHITECTURE;