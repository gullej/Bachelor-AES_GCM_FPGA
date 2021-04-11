
LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY GHASH IS
	PORT (
		clk : IN STD_LOGIC;
		in_val : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		auth_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_product : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE GHASH_arc OF GHASH IS

	COMPONENT multH IS
		PORT (
			clk : IN STD_LOGIC;
			in_val : IN STD_LOGIC;
			X : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			Y : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_product : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	COMPONENT AES IS
		PORT (
			clk : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			in_val : IN STD_LOGIC;
			in_data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			fin_val : OUT STD_LOGIC;
			fin_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	SIGNAL auth_temp : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL H : STD_LOGIC_VECTOR(127 DOWNTO 0)  := (others => '0');
	SIGNAL aes_val : STD_LOGIC;
	SIGNAL aes_state : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL mult_val : STD_LOGIC;
	SIGNAL mult_product : STD_LOGIC_VECTOR(127 downto 0);

BEGIN

	U1 : AES   PORT MAP(clk, key, in_val, H, aes_val, aes_state);
	U2 : multH PORT MAP(clk, aes_val, aes_state, auth_temp, mult_val, mult_product);

	multiplier : PROCESS (clk)

	BEGIN
		IF (RISING_EDGE(clk)) THEN
			IF (aes_val = '1') THEN
				auth_temp <= aes_state;

			END IF;

			IF (mult_val = '1') THEN
				out_product <= mult_product;
				out_val <= '1';
			END IF;
		ELSE
			out_val <= '0';
		END IF;

	END PROCESS;

END ARCHITECTURE;