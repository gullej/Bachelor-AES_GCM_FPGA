LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY REG IS
	PORT (
		clk, in_val, aad, frame_start, frame_end, isDec : IN STD_LOGIC;
		num_bits : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		state : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		out_state : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_bits : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		out_aad, out_frame_start, out_frame_end, out_isDec : OUT STD_LOGIC);
END ENTITY;

ARCHITECTURE REG_arc OF REG IS


BEGIN

	clock : PROCESS (clk)
	BEGIN
		IF (rising_edge(clk)) THEN
				out_val <= in_val;
				out_state <= state;
				out_bits <= num_bits;
				
				out_aad <= aad;
				out_frame_start <= frame_start;
				out_frame_end <= frame_end;
				out_isDec <= isDec;
		END IF;
	END PROCESS;
END;