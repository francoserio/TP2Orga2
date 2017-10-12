import matplotlib as mpl
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cbook as cbook
import statistics

listaCV = []
listaASMV = []
listaCU = []
listaASMU = []

with open("informe/data/solver_set_bnd.csv") as f:
    for row in f:
        if int(row.split()[0]) == int(0):                  #es de C
            if int(row.split()[4]) == int(0):              #es de V
                listaCV.append((int(row.split()[2]), int(row.split()[3])))
            else:                                          #es de U
                listaCU.append((int(row.split()[2]), int(row.split()[3])))
        else:                                              #es de ASM
            if int(row.split()[4]) == int(3):              #es de V
                listaASMV.append((int(row.split()[2]), int(row.split()[3])))
            else:                                          #es de U
                listaASMU.append((int(row.split()[2]), int(row.split()[3])))

listas = [listaCV, listaASMV, listaCU, listaASMU]
listasMedianaCV = []
listasMedianaASMV = []
listasMedianaCU = []
listasMedianaASMU = []

listasMedianas = [listasMedianaCV
, listasMedianaASMV
, listasMedianaCU
, listasMedianaASMU]

position = 0
for lista in listas:
    lista16 = []
    lista32 = []
    lista64 = []
    lista128 = []
    lista256 = []
    lista512 = []

    for x in lista:
        if x[0] == int(16):
            lista16.append(x[1])
        elif x[0] == int(32):
            lista32.append(x[1])
        elif x[0] == int(64):
            lista64.append(x[1])
        elif x[0] == int(128):
            lista128.append(x[1])
        elif x[0] == int(256):
            lista256.append(x[1])
        else:
            lista512.append(x[1])

    mediana16 = statistics.median(lista16)
    listasMedianas[position].append(mediana16)
    mediana32 = statistics.median(lista32)
    listasMedianas[position].append(mediana32)
    mediana64 = statistics.median(lista64)
    listasMedianas[position].append(mediana64)
    mediana128 = statistics.median(lista128)
    listasMedianas[position].append(mediana128)
    mediana256 = statistics.median(lista256)
    listasMedianas[position].append(mediana256)
    mediana512 = statistics.median(lista512)
    listasMedianas[position].append(mediana512)

    sizes = [16, 32, 64, 128, 256, 512]
    x = np.arange(1, len(sizes) + 1)

    plt.ylabel('clocks promedios')
    plt.xlabel('sizes')

    plt.bar(x, [mediana16, mediana32, mediana64, mediana128, mediana256, mediana512], align='center')
    plt.xticks(x, sizes, rotation=35)

    plt.show()
    position += 1


sizes = [16, 32, 64, 128, 256, 512]
x = np.arange(1, len(sizes) + 1)

plt.ylabel('clocks promedios')
plt.xlabel('sizes')

pcv, = plt.plot(x, listasMedianaCV, 'r^', label="C matriz V")
pasmv, = plt.plot(x, listasMedianaASMV, 'ro', label="ASM matriz V")
pcu, = plt.plot(x, listasMedianaCU, 'b^', label="C matriz U")
pasmu, = plt.plot(x, listasMedianaASMU, 'bo', label="ASM matriz U")

plt.xlim(0, 7)
plt.xticks(x, sizes, rotation=35)


plt.legend(bbox_to_anchor=(0, 1), loc=2)


plt.show()
