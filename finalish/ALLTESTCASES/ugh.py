import os
dir = r"C:\Users\harsh\Documents\Code\Scripts\MIPS\finalish\ALLTESTCASES\\"
print(__file__)

for file in os.listdir(r"C:\Users\harsh\Documents\Code\Scripts\MIPS\finalish\ALLTESTCASES"):
    #print(file)
    if file == __file__:
        continue
    name = file[:-4] #remove .txt
    expected = False
    if name.endswith("expected"):
        name = name[:-8]
        expected = True
    if name[-1].isdigit():
        name = name[:-1] + "_" + name[-1]
    else:
        name = name + "_1"


    if expected:
        name = name + "_expected.txt"
    else:
        name = name + "_test.txt"

    os.rename(dir+ file,dir + name)

