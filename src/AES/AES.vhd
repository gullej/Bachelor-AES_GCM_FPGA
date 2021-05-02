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
		fin_val : OUT STD_LOGIC;
		fin_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE AES_arc OF AES IS

	COMPONENT KeyExpansion IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_key : OUT STD_LOGIC_VECTOR(1407 DOWNTO 0));
	END COMPONENT;

	COMPONENT AddKey IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
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
	SIGNAL state6, state7, state8, state9 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL state10, state11, state12, state13 : STD_LOGIC_VECTOR(127 DOWNTO 0);

	SIGNAL roundkeys : STD_LOGIC_VECTOR(1407 DOWNTO 0);
	SIGNAL vals : STD_LOGIC_VECTOR(12 downto 0) := "0000000000000";

BEGIN

	U1 : KeyExpansion PORT MAP(clk, in_val, key, roundkeys);

	U2  : AddKey    PORT MAP(clk, in_val,  roundkeys(1407 DOWNTO 1280), in_data, vals(0), state1);  -- round 0
	U3  : AESRound  PORT MAP(clk, vals(0), roundkeys(1279 DOWNTO 1152), state1,  vals(1), state2);  -- round 1
	U4  : AESRound  PORT MAP(clk, vals(1), roundkeys(1151 DOWNTO 1024), state2,  vals(2), state3);  -- round 2
	U5  : AESRound  PORT MAP(clk, vals(2), roundkeys(1023 DOWNTO 896),  state3,  vals(3), state4);  -- round 3
	U6  : AESRound  PORT MAP(clk, vals(3), roundkeys(895 DOWNTO 768),   state4,  vals(4), state5);  -- round 4
	U7  : AESRound  PORT MAP(clk, vals(4), roundkeys(767 DOWNTO 640),   state5,  vals(5), state6);  -- round 5
	U8  : AESRound  PORT MAP(clk, vals(5), roundkeys(639 DOWNTO 512),   state6,  vals(6), state7);  -- round 6
	U9  : AESRound  PORT MAP(clk, vals(6), roundkeys(511 DOWNTO 384),   state7,  vals(7), state8);  -- round 7
	U10 : AESRound  PORT MAP(clk, vals(7), roundkeys(383 DOWNTO 256),   state8,  vals(8), state9);  -- round 8
	U11 : AESRound  PORT MAP(clk, vals(8), roundkeys(255 DOWNTO 128),   state9,  vals(9), state10); -- round 9
	
	U12 : SubBytes  PORT MAP(clk, vals(9),  state10, vals(10), state11); -- round 10
	U13 : ShiftRows PORT MAP(clk, vals(10), state11, vals(11), state12); -- round 10
	U14 : AddKey    PORT MAP(clk, vals(11), roundkeys(127 DOWNTO 0), state12, vals(12), state13); -- round 10

	PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (vals(12) = '1') THEN
				fin_val <= '1';
				fin_state <= state13;
			ELSE
				fin_val <= '0';
			END IF;

			--END IF;
		END IF;

	END PROCESS;

END ARCHITECTURE;