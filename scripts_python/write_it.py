import fileinput
import re

f = open("shift_regs.txt", "a")

for i in range(0, 70):
    f.write("delayREG" + str(i+1) + " : REG PORT MAP(clk, vals(" + str(i) + "), aad_delay("  + str(i) + "), sof_delay("  + str(i) + "),  eof_delay("  + str(i) + "), dec_delay("  + str(i) + "),num_bits_delay(" + str(7*(i+1)+i)+ " downto " + str(7*i+i) + "), regs(" + str(127*(i+1)+i) + " downto " + str(127*i+i) + "), vals(" + str(i+1) + "), regs(" + str(127*(i+2)+i+1) + " downto " + str(127*(i+1)+i+1) + "), num_bits_delay(" + str(7*(i+2)+i+1) + " downto " + str(7*(i+1)+i+1) + "), aad_delay("  + str(i+1) + "), sof_delay(" + str(i+1) + "), eof_delay(" + str(i+1) + "), dec_delay("  + str(i+1) +"));\n")