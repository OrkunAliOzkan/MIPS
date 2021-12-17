import os

def lineswap(filename):
      f = open(filename,"r")
      lines = f.read().split("\n")
      f.close()
      for i in range(100,200,4):
            if lines[i][:2] + lines[i+1][:2] + lines[i+2][:2] + lines[i+3][:2] == "00000008":
                  temp1, temp2, temp3, temp4 = lines[i], lines[i+1], lines[i+2], lines[i+3]
                  n = 1
                  while lines[i-n-3]+lines[i-n-2]+lines[i-n-1]+lines[i-n]=="00000000":
                        n = n + 4
                  lines[i], lines[i+1], lines[i+2], lines[i+3] = lines[i-n-3], lines[i-n-2], lines[i-n-1], lines[i-n]
                  lines[i-n-3], lines[i-n-2], lines[i-n-1], lines[i-n] = temp1, temp2, temp3, temp4
      new = ""
      for i in range(200):
            new = new + lines[i] + "\n"

      f = open(filename, "w")
      f.write(new)
      f.close()

filenames = os.listdir("/Users/matthewsetiawan/Desktop/Python Area/")
for i in range(len(filenames)):
      if filenames[i][-3:] == "txt":
            lineswap(filenames[i])