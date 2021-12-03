while True:
    x = input("Instruction Name: ")
    f = open(x+".txt","a+")
    f.write("00000000\n"*2000)
    f.close()
    f = open(x+"expected.txt","a+")
    f.write("00000000\n"*2000)
    f.close()
