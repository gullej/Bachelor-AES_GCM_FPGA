LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;


ENTITY Seq_MEM IS
    PORT (
        clock, in_val : IN STD_LOGIC;
        address : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        out_val : OUT STD_LOGIC;
	out_seq : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
	out_seq_32 : OUT STD_LOGIC);
END ENTITY;

ARCHITECTURE Seq_MEM_ARC OF Seq_MEM IS

    TYPE RW_type IS ARRAY(0 TO 3) OF STD_LOGIC_VECTOR(64 DOWNTO 0);

    signal RW : RW_type := (
		0 => x"8765432100000000" & '0',
		1 => x"00000001" & x"00000000" & '1',
		2 => x"0000000a" & x"00000000" & '1',
		3 => x"1010101010101010" & '0');

BEGIN

    MEMORY : PROCESS (clock)
    variable temp : STD_LOGIC_VECTOR(64 downto 0);
    BEGIN
	IF (rising_edge(clock)) THEN
            IF (in_val = '1') THEN
		
                temp := RW(to_integer(unsigned(address)));
		out_seq <= temp(64 downto 1);
		out_seq_32 <= temp(0);
		if (temp(0) = '0') THEN
			temp(64 downto 1) := temp(64 downto 1) + '1';
		else
			temp(64 downto 33) := temp(64 downto 33) + '1';
		end if;
		RW(to_integer(unsigned(address))) <= temp;
                out_val <= '1';
            ELSE
                out_val <= '0';
            END IF;

        END IF;
    END PROCESS;
END ARCHITECTURE;