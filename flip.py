import fileinput
import re

pattern = re.compile('\d+')

for line in fileinput.input('big.txt', inplace=True):
    if line:
        print(pattern.sub(lambda m: str(127 - int(m.group(0))), line))