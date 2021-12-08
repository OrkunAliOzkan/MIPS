def tobin(integer,bits):
      return bin(int(integer))[2:].zfill(bits)

def tohex(B):
      intval = int(B,2)
      hexval = hex(intval)[2:].zfill(8)
      return hexval[0:2], hexval[2:4], hexval[4:6], hexval[6:8]

def translator(command):
      op = command.split(" ")[0]
      oprd = command.split(" ")

      for i in range(len(oprd)):
            if oprd[i][len(oprd[i])-1]==",":
                  oprd[i]=oprd[i][:-1]

      B = "00000000000000000000000000000000"
      H1 = "0"
      H2 = "0"
      H3 = "0"
      H4 = "0"

      if op=="ADDIU":
            B = "001001" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],16)

      elif op=="ADDU":
            B = "000000" + tobin(oprd[2],5) + tobin(oprd[3],5) + tobin(oprd[1],5) + "00000100001"

      elif op=="AND":
            B = "000000" + tobin(oprd[2],5) + tobin(oprd[3],5) + tobin(oprd[1],5) + "00000100100"

      elif op=="ANDI":
            B = "001100" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],16)

      elif op=="BEQ":
            B = "000100" + tobin(oprd[1],5) + tobin(oprd[2],5) + tobin(oprd[3],16)

      elif op=="BGEZ":
            B = "000001" + tobin(oprd[1],5) + "00001" + tobin(oprd[2],16)

      elif op=="BGEZAL":
            B = "000001" + tobin(oprd[1],5) + "10001" + tobin(oprd[2],16)

      elif op=="BGTZ":
            B = "000111" + tobin(oprd[1],5) + "00000" + tobin(oprd[2],16)

      elif op=="BLEZ":
            B = "000110" + tobin(oprd[1],5) + "00000" + tobin(oprd[2],16)

      elif op=="BLTZ":
            B = "000001" + tobin(oprd[1],5) + "00000" + tobin(oprd[2],16)

      elif op=="BLTZAL":
            B = "000001" + tobin(oprd[1],5) + "10000" + tobin(oprd[2],16)

      elif op=="BNE":
            B = "000101" + tobin(oprd[1],5) + tobin(oprd[2],5) + tobin(oprd[3],16)

      elif op=="DIV":
            B = "000000" + tobin(oprd[1],5) + tobin(oprd[2],5) + "0000000000011010"

      elif op=="DIVU":
            B = "000000" + tobin(oprd[1],5) + tobin(oprd[2],5) + "0000000000011011"
            
      elif op=="J":
            B = "000010" + tobin(oprd[1],26)

      elif op=="JALR":
            B = "000000" + tobin(oprd[2],5) + "00000" + tobin(oprd[1],5) + "00000001001"

      elif op=="JAL":
            B = "000011" + tobin(oprd[1],26)

      elif op=="JR":
            B = "000000" + tobin(oprd[1],5) + "000000000000000001000"

      elif op=="LB":
            B = "100000" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="LBU":
            B = "100100" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="LH":
            B = "100001" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="LHU":
            B = "100101" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="LUI":
            B = "00111100000" + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="LW":
            B = "100011" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="LWL":
            B = "100010" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="LWR":
            B = "100110" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="MTHI":
            B = "000000" + tobin(oprd[1],5) + "000000000000000010001"

      elif op=="MTLO":
            B = "000000" + tobin(oprd[1],5) + "000000000000000010011"

      elif op=="MFHI":
            B = "0000000000000000" + tobin(oprd[1],5) + "00000010000"

      elif op=="MFLO":
            B = "0000000000000000" + tobin(oprd[1],5) + "00000010010"

      elif op=="MULT":
            B = "000000" + tobin(oprd[1],5) + tobin(oprd[2],5) + "0000000000011000"

      elif op=="MULTU":
            B = "000000" + tobin(oprd[1],5) + tobin(oprd[2],5) + "0000000000011001"

      elif op=="OR":
            B = "000000" + tobin(oprd[2],5) + tobin(oprd[3],5) + tobin(oprd[1],5) + "00000100101"

      elif op=="ORI":
            B = "001101" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],16)
            
      elif op=="SB":
            B = "101000" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="SH":
            B = "101001" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="SLL":
            B = "00000000000" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],5) + "000000"

      elif op=="SLLV":
            B = "000000" + tobin(oprd[3],5) + tobin(oprd[2],5) + tobin(oprd[1],5) + "00000000100"

      elif op=="SLT":
            B = "000000" + tobin(oprd[2],5) + tobin(oprd[3],5) + tobin(oprd[1],5) + "00000101010"

      elif op=="SLTI":
            B = "001010" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],16)

      elif op=="SLTIU":
            B = "001011" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],16)

      elif op=="SLTU":
            B = "000000" + tobin(oprd[2],5) + tobin(oprd[3],5) + tobin(oprd[1],5) + "00000101011"

      elif op=="SRA":
            B = "00000000000" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],5) + "000011"

      elif op=="SRAV":
            B = "000000" + tobin(oprd[3],5) + tobin(oprd[2],5) + tobin(oprd[1],5) + "00000000111"

      elif op=="SRL":
            B = "00000000000" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],5) + "000010" 

      elif op=="SRLV":
            B = "000000" + tobin(oprd[3],5) + tobin(oprd[2],5) + tobin(oprd[1],5) + "00000000110" 

      elif op=="SUBU":
            B = "000000" + tobin(oprd[2],5) + tobin(oprd[3],5) + tobin(oprd[1],5) + "00000100011" 

      elif op=="SW":
            B = "101011" + tobin(oprd[3],5) + tobin(oprd[1],5) + tobin(oprd[2],16)

      elif op=="XOR":
            B = "000000" + tobin(oprd[2],5) + tobin(oprd[3],5) + tobin(oprd[1],5) + "00000100110"

      elif op=="XORI":
            B = "001110" + tobin(oprd[2],5) + tobin(oprd[1],5) + tobin(oprd[3],16)

      H1, H2, H3, H4 = tohex(B)
      return H1, H2, H3, H4

def mips_cpu_bus(RAM):
      return 0

RAM = ["0"]*200

RAM[4], RAM[5], RAM[6], RAM[7] = "AA", "BB", "CC", "DD"
RAM[103], RAM[102], RAM[101], RAM[100] = translator("LW 1, 4, 0")
RAM[107], RAM[106], RAM[105], RAM[104] = translator("SW 1, 4, 0")

for i in range(100, 108):
      print(RAM[i])

