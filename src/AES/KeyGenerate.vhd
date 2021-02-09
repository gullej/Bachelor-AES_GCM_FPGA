LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY KeyGenerate IS
	PORT (
		clk, in_val : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		rcon : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_key : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));

END ENTITY;

ARCHITECTURE KeyGenerate_arc OF KeyGenerate IS

	COMPONENT SubBytesWord IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));

	END COMPONENT;

	SIGNAL first_word, temp_word : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL word1, word2, word3, word4 : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL val1 : STD_LOGIC := '0';

BEGIN

	U1 : SubBytesWord PORT MAP(clk, in_val, first_word, val1, temp_word);

	first_word(31 DOWNTO 8) <= key(23 DOWNTO 0);
	first_word(7 DOWNTO 0) <= key(31 DOWNTO 24);

	word1 <= key(127 DOWNTO 96) XOR temp_word XOR rcon;
	word2 <= key(95 DOWNTO 64) XOR word1;
	word3 <= key(63 DOWNTO 32) XOR word2;
	word4 <= key(31 DOWNTO 0) XOR word3;

	PROCESS (clk)
	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (val1 = '1') THEN
				out_key(127 DOWNTO 96) <= word1;
				out_key(95 DOWNTO 64) <= word2;
				out_key(63 DOWNTO 32) <= word3;
				out_key(31 DOWNTO 0) <= word4;
				out_val <= '1';
			ELSE
				out_val <= '0';
			END IF;
		END IF;

	END PROCESS;
END ARCHITECTURE;