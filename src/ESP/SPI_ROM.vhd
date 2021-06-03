LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY SPI_ROM IS
    PORT (
        clock, in_val : IN STD_LOGIC;
        address : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        out_val : OUT STD_LOGIC;
	out_spi : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
	out_salt : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        out_key : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE SPI_ROM_ARC OF SPI_ROM IS

    TYPE ROM_type IS ARRAY(0 TO 3) OF STD_LOGIC_VECTOR(191 DOWNTO 0);

    CONSTANT ROM : ROM_type := (
	0 => x"00004321" & x"2e443b68" & x"4c80cdefbb5d10da906ac73c3613a634",
	1 => x"00000000" & x"00000000" & x"00000000000000000000000000000000",
        2 => x"0000a5f8" & x"cafebabe" & x"feffe9928665731c6d6a8f9467308308",    
        3 => x"42f67e3f" & x"57690e43" & x"3de09874b388e6491988d0c3607eae1f");

BEGIN

    MEMORY : PROCESS (clock)
	variable temp : STD_LOGIC_VECTOR(191 downto 0);
    BEGIN
        IF (rising_edge(clock)) THEN
            IF (in_val = '1') THEN
		temp := ROM(to_integer(unsigned(address)));
		out_spi <= temp(191 downto 160);
                out_salt <= temp(159 downto 128);
		out_key <= temp(127 downto 0);
                out_val <= '1';
            ELSE
                out_val <= '0';
            END IF;

        END IF;
    END PROCESS;
END ARCHITECTURE;