import os 
print("Alo, mundo!")
print("UM_SEGREDO: %s" % os.environ.get("UM_SEGREDO"))
arquivo = open("/etc/segredo.txt", "r")
print(arquivo.read())
arquivo.close()
