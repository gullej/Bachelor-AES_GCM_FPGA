LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY KeyExpansion IS
	PORT (
		clk, in_val : IN STD_LOGIC;
		key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		--out_val : OUT STD_LOGIC;
		out_key : OUT STD_LOGIC_VECTOR(1407 DOWNTO 0));

END ENTITY;

ARCHITECTURE KeyExpansion_arc OF KeyExpansion IS

	COMPONENT KeyGenerate IS
		PORT (
			clk, in_val : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			rcon : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			out_val : OUT STD_LOGIC;
			out_key : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));

	END COMPONENT;

	SIGNAL key1, key2, key3, key4 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL key5, key6, key7, key8 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL key9, key10, key11 : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL val1, val2, val3, val4, val5, val6, val7, val8, val9, val10 : STD_LOGIC := '0';

BEGIN

	U1 : KeyGenerate PORT MAP(clk, in_val, key, x"01000000", val1, key1);
	U2 : KeyGenerate PORT MAP(clk, val1, key1, x"02000000", val2, key2);
	U3 : KeyGenerate PORT MAP(clk, val2, key2, x"04000000", val3, key3);
	U4 : KeyGenerate PORT MAP(clk, val3, key3, x"08000000", val4, key4);
	U5 : KeyGenerate PORT MAP(clk, val4, key4, x"10000000", val5, key5);
	U6 : KeyGenerate PORT MAP(clk, val5, key5, x"20000000", val6, key6);
	U7 : KeyGenerate PORT MAP(clk, val6, key6, x"40000000", val7, key7);
	U8 : KeyGenerate PORT MAP(clk, val7, key7, x"80000000", val8, key8);
	U9 : KeyGenerate PORT MAP(clk, val8, key8, x"1b000000", val9, key9);
	U10 : KeyGenerate PORT MAP(clk, val9, key9, x"36000000", val10, key10);

	out_key(1407 DOWNTO 1280) <= key;
	out_key(1279 DOWNTO 1152) <= key1;
	out_key(1151 DOWNTO 1024) <= key2;
	out_key(1023 DOWNTO 896)  <= key3;
	out_key(895 DOWNTO 768)   <= key4;
	out_key(767 DOWNTO 640)   <= key5;
	out_key(639 DOWNTO 512)   <= key6;
	out_key(511 DOWNTO 384)   <= key7;
	out_key(383 DOWNTO 256)   <= key8;
	out_key(255 DOWNTO 128)   <= key9;
	out_key(127 DOWNTO 0)     <= key10;
END ARCHITECTURE;