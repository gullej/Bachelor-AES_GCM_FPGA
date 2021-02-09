LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY AES IS
	PORT (
		clk : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		in_val : IN STD_LOGIC;
		in_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));

END ENTITY;

ARCHITECTURE AES_arc OF AES IS

	COMPONENT KeyExpansion IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_key : OUT STD_LOGIC_VECTOR(1407 DOWNTO 0));
	END COMPONENT;

	COMPONENT AddKey IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT AddKey;

	COMPONENT AESRound IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			in_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

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

	SIGNAL state1, state2, state3, state4, state5 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL state6, state7, state8, state9, state10 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL state11, state12, state13 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL roundkeys : STD_LOGIC_VECTOR(1407 DOWNTO 0);
	SIGNAL val1, val2, val3, val4, val5, val6, val7, val8 : STD_LOGIC := '0';
	SIGNAL val9, val10, val11, val12, val13, val14 : STD_LOGIC := '0';
BEGIN

	U1 : KeyExpansion PORT MAP(clk, in_val, key, val1, roundkeys);
	U2 : AddKey PORT MAP(clk, val1, in_data, roundkeys(1407 DOWNTO 1280), val2, state1); -- round 0
	U3 : AESRound PORT MAP(clk, val2, roundkeys(1279 DOWNTO 1152), state1, val3, state2); --round 1
	U4 : AESRound PORT MAP(clk, val3, roundkeys(1151 DOWNTO 1024), state2, val4, state3); --round 2
	U5 : AESRound PORT MAP(clk, val4, roundkeys(1023 DOWNTO 896), state3, val5, state4); --round 3
	U6 : AESRound PORT MAP(clk, val5, roundkeys(895 DOWNTO 768), state4, val6, state5); --round 4
	U7 : AESRound PORT MAP(clk, val6, roundkeys(767 DOWNTO 640), state5, val7, state6); --round 5
	U8 : AESRound PORT MAP(clk, val7, roundkeys(639 DOWNTO 512), state6, val8, state7); --round 6
	U9 : AESRound PORT MAP(clk, val8, roundkeys(511 DOWNTO 384), state7, val9, state8); --round 7
	U10 : AESRound PORT MAP(clk, val9, roundkeys(383 DOWNTO 256), state8, val10, state9); --round 8
	U11 : AESRound PORT MAP(clk, val10, roundkeys(255 DOWNTO 128), state9, val11, state10); --round 9
	U12 : SubBytes PORT MAP(clk, val11, state10, val12, state11); --round 10
	U13 : ShiftRows PORT MAP(clk, val12, state11, val13, state12); --round 10
	U14 : AddKey PORT MAP(clk, val13, state12, roundkeys(127 DOWNTO 0), val14, state13); --round 10

	PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (val14 = '1') THEN
				out_state <= state13;
				out_val <= '1';
			ELSE
				out_val <= '0';
			END IF;
		END IF;

	END PROCESS;
END ARCHITECTURE;