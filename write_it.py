for i in range(0, 69):
    print("U" + str(i+1) + " : REG PORT MAP(clk, vals(" + str(i) + ") , regs(" + str(127*(i+1)+i) + " downto " + str(127*i+i) + "), vals(" + str(i+1) + "), regs(" + str(127*(i+2)+i+1) + " downto " + str(127*(i+1)+i+1) + "));")
