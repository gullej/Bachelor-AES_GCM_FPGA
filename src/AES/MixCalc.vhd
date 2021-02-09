LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY MixCalc IS
	PORT (
		clk, in_val : IN STD_LOGIC;
		state : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END ENTITY MixCalc;

ARCHITECTURE rtl OF MixCalc IS

	SIGNAL newState : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL sig0, sig1, sig2, sig3 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL tmp, tmp01, tmp12, tmp23, tmp30 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL double01, double12, double23, double30 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL val1 : STD_LOGIC := '0';

BEGIN

	sig0 <= state(31 DOWNTO 24);
	sig1 <= state(23 DOWNTO 16);
	sig2 <= state(15 DOWNTO 8);
	sig3 <= state(7 DOWNTO 0);

	tmp <= sig0 XOR sig1 XOR sig2 XOR sig3;

	tmp01 <= sig0 XOR sig1;
	tmp12 <= sig1 XOR sig2;
	tmp23 <= sig2 XOR sig3;
	tmp30 <= sig3 XOR sig0;

	double01 <= (tmp01(6 DOWNTO 0) & '0') XOR x"1B" WHEN tmp01(7) = '1' ELSE
		(tmp01(6 DOWNTO 0) & '0');
	double12 <= (tmp12(6 DOWNTO 0) & '0') XOR x"1B" WHEN tmp12(7) = '1' ELSE
		(tmp12(6 DOWNTO 0) & '0');
	double23 <= (tmp23(6 DOWNTO 0) & '0') XOR x"1B" WHEN tmp23(7) = '1' ELSE
		(tmp23(6 DOWNTO 0) & '0');
	double30 <= (tmp30(6 DOWNTO 0) & '0') XOR x"1B" WHEN tmp30(7) = '1' ELSE
		(tmp30(6 DOWNTO 0) & '0');

	newstate(31 DOWNTO 24) <= sig0 XOR tmp XOR double01;
	newstate(23 DOWNTO 16) <= sig1 XOR tmp XOR double12;
	newstate(15 DOWNTO 8) <= sig2 XOR tmp XOR double23;
	newstate(7 DOWNTO 0) <= sig3 XOR tmp XOR double30;

	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF (in_val = '1') THEN
				val1 <= '1';
			END IF;
			IF (in_val = '1') THEN
				out_state <= newState;
				out_val <= '1';
			ELSE
				out_val <= '0';
			END IF;
		END IF;

	END PROCESS;

END;