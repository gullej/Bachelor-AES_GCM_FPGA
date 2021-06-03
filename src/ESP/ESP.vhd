LIBRARY ieee;
USE ieee.std_logic_textio.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ESP IS
	PORT (
		clk, sof, eof : IN STD_LOGIC;
		num_bits : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		is_dec : IN STD_LOGIC;
		input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
		out_val : OUT STD_LOGIC;
		output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
END ENTITY;

ARCHITECTURE ESP_arc OF ESP IS

	COMPONENT SPI_ROM IS
    	PORT (
        	clock, in_val : IN STD_LOGIC;
        	address : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        	out_val : OUT STD_LOGIC;
		out_spi : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		out_salt : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        	out_key : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	COMPONENT Seq_MEM IS
    	PORT (
        	clock, in_val : IN STD_LOGIC;
        	address : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        	out_val : OUT STD_LOGIC;
		out_seq : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
		out_seq_32 : OUT STD_LOGIC);
	END COMPONENT;

	COMPONENT GCM IS
		PORT (
			clk, SOF, aad_val, enc_val : IN STD_LOGIC;
			num_bits : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			isDec, EOF : IN STD_LOGIC;
			key : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			iv : IN STD_LOGIC_VECTOR(95 DOWNTO 0);
			input : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			out_val, out_tag : OUT STD_LOGIC;
			output : OUT STD_LOGIC_VECTOR(127 DOWNTO 0));
	END COMPONENT;

	SIGNAL gcm_aad, gcm_key, gcm_input, gcm_output : STD_LOGIC_VECTOR(127 DOWNTO 0);
	SIGNAL count : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
	SIGNAL sequence_number : STD_LOGIC_VECTOR(63 DOWNTO 0);
	SIGNAL out_salt, out_spi : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL gcm_iv : STD_LOGIC_VECTOR(95 DOWNTO 0);
	SIGNAL after_sof, mem_val, out_seq_val, out_spi_val : STD_LOGIC := '0';
	SIGNAL out_gcm_val, out_gcm_tag, gcm_isDec : STD_LOGIC := '0';
	SIGNAL gcm_sof, gcm_aad_val, gcm_enc_val : STD_LOGIC := '0';
	SIGNAL gcm_eof, after_after_sof, after_eof : STD_LOGIC := '0';
	SIGNAL after_after_after_sof, after_after_eof : STD_LOGIC := '0';
	SIGNAL after_after_after_eof, seq_32 : STD_LOGIC := '0';
	SIGNAL gcm_num_bits, numBitShift1, numBitShift2 : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL shift1, shift2 : STD_LOGIC_VECTOR(127 DOWNTO 0);

BEGIN

	gcm_aad <= out_spi & sequence_number & x"00000000";
	gcm_iv(95 DOWNTO 64) <= out_salt;


	U1 : Seq_MEM PORT MAP(clk, mem_val, count, out_seq_val, sequence_number, seq_32);
	U2 : SPI_ROM PORT MAP(clk, mem_val, count, out_spi_val, out_spi, out_salt, gcm_key);

	U : GCM PORT MAP(clk, gcm_sof, gcm_aad_val, gcm_enc_val, gcm_num_bits, gcm_isDec, gcm_eof, gcm_key, gcm_iv, gcm_input, out_gcm_val, out_gcm_tag, gcm_output);
	
	shiftreg : PROCESS (clk, input, sof, after_sof, after_after_sof, after_after_after_sof, eof, after_eof, after_after_eof, after_after_after_eof)
	BEGIN
		IF (rising_edge(clk)) THEN
			shift1 <= input;
			shift2 <= shift1;

			numBitShift1 <= num_bits;
			numBitShift2 <= numBitShift1;

			after_sof <= sof;
			after_after_sof <= after_sof;
			after_after_after_sof <= after_after_sof;
			after_eof <= eof;
			after_after_eof <= after_eof;
			after_after_after_eof <= after_after_eof;
		END IF;
	END PROCESS;

	starter : PROCESS (sof, after_sof, after_after_sof, eof, after_eof, after_after_eof,after_after_after_eof, shift1, shift2, numBitShift1, numBitShift2, gcm_aad, gcm_input, gcm_enc_val)
	BEGIN
		IF (sof = '1') THEN
			mem_val <= '1';
			gcm_iv(63 DOWNTO 0) <= input(127 DOWNTO 64);
		ELSIF (after_sof = '1') THEN
			mem_val <= '0';
		ELSIF (after_after_sof = '1') THEN
			gcm_aad_val <= '1';
			gcm_sof <= '1';
			gcm_aad_val <= '1';
			gcm_input <= gcm_aad;
			if (seq_32 = '1') THEN
				gcm_num_bits <= x"40";
			ELSE
				gcm_num_bits <= x"60";
			END IF;
		ELSIF (after_after_after_sof = '1') THEN
			gcm_sof <= '0';
			gcm_enc_val <= '1';
			gcm_input <= shift2;
			gcm_num_bits <= numBitShift2;
			gcm_aad_val <= '0';
		ELSIF (after_after_eof = '1') THEN
			gcm_eof <= '1';
			gcm_input <= shift2;
			gcm_num_bits <= numBitShift2;
		ELSIF (after_after_after_eof = '1') THEN
			gcm_eof <= '0';
			gcm_aad_val <= '0';
			gcm_sof <= '0';
			gcm_enc_val <= '0';
		ELSE
			gcm_input <= shift2;
			gcm_num_bits <= numBitShift2;
			gcm_eof <= '0';
			
		END IF;
	END PROCESS;
	
	outer : PROCESS(clk, out_gcm_val, out_gcm_tag, gcm_output)
	BEGIN
		IF (rising_edge(clk)) THEN
			IF (out_gcm_val = '1' or out_gcm_tag = '1') THEN
				output <= gcm_output;
				out_val <= '1';
			ELSE
				out_val <= '0';
				output <= (others => '0');
			END IF;
		END IF;
	END PROCESS;

	counter : PROCESS (clk, eof)
	BEGIN
		IF (rising_edge(clk)) THEN
			IF (eof = '1') THEN
				count <= count + '1';
			END IF;
		END IF;
	END PROCESS;

END;