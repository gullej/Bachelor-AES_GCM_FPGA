LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AESRound IS
	PORT (
		clk, in_val : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		in_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE AESRound_arc OF AESRound IS

	COMPONENT SubBytes IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	COMPONENT ShiftRows IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	COMPONENT MixColumns IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT MixColumns;

	COMPONENT AddKey IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT AddKey;

	SIGNAL state1, state2, state3, state4 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL val1, val2, val3, val4 : STD_LOGIC := '0';
BEGIN

	U1 : SubBytes   PORT MAP(clk, in_val, in_data, val1, state1);
	U2 : ShiftRows  PORT MAP(clk, val1, state1, val2, state2);
	U3 : MixColumns PORT MAP(clk, val2, state2, val3, state3);
	U4 : AddKey     PORT MAP(clk, val3, key, state3,  val4, state4);

	PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (val4 = '1') THEN
				out_val <= '1';
				out_state <= state4;
			ELSE
				out_val <= '0';
			END IF;
		END IF;
	END PROCESS;
END ARCHITECTURE;