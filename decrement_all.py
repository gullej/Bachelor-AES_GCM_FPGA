import fileinput
import re

pattern = re.compile('\d+')

for line in fileinput.input('e.txt', inplace=True):
    if line:
        print(pattern.sub(lambda m: str(int(m.group(0))-1), line))