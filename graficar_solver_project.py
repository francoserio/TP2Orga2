import matplotlib as mpl
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.cbook as cbook
#import statistics

#recordar np.mean(lista) para el promedio y np.median(lista) para para la mediana
cantTiempos=1000
#levantar archivos y poner en listas
archivo_asm128 = open('solver_project_asm_128.csv', "r")
archivo_c128 = open('solver_project_c_128.csv', "r")

archivo_asm256 = open('solver_project_asm_256.csv', "r")
archivo_c256 = open('solver_project_c_256.csv', "r")

archivo_asm512 = open('solver_project_asm_512.csv', "r")
archivo_c512 = open('solver_project_c_512.csv', "r")

# LISTA DE TIEMPOS PARA TAMANIO 128X128
lista_asm128_str=archivo_asm128.readlines()

lista_asm128_int=[]
for tiempo in lista_asm128_str[0:cantTiempos]: #obtengo los tiempo para asm
    lista_asm128_int.append( int( tiempo.rstrip('\n') ) )


lista_c128_str=archivo_c128.readlines()

lista_c128_int=[]
for tiempo in lista_c128_str: #obtengo los tiempo para c
    lista_c128_int.append( int( tiempo.rstrip('\n') ) )

lista_c128_int_O0=lista_c128_int[0:cantTiempos]
lista_c128_int_O2=lista_c128_int[cantTiempos:2*cantTiempos]
lista_c128_int_O3=lista_c128_int[2*cantTiempos:3*cantTiempos]

# LISTA DE TIEMPOS PARA TAMANIO 256x256
lista_asm256_str=archivo_asm256.readlines()

lista_asm256_int=[]
for tiempo in lista_asm256_str[0:cantTiempos]: #obtengo los tiempo para asm
    lista_asm256_int.append( int( tiempo.rstrip('\n') ) )


lista_c256_str=archivo_c256.readlines()

lista_c256_int=[]
for tiempo in lista_c256_str: #obtengo los tiempo para c
    lista_c256_int.append( int( tiempo.rstrip('\n') ) )

lista_c256_int_O0=lista_c256_int[0:cantTiempos]
lista_c256_int_O2=lista_c256_int[cantTiempos:2*cantTiempos]
lista_c256_int_O3=lista_c256_int[2*cantTiempos:3*cantTiempos]

# LISTA DE TIEMPOS PARA TAMANIO 512x512
lista_asm512_str=archivo_asm512.readlines()

lista_asm512_int=[]
for tiempo in lista_asm512_str[0:cantTiempos]: #obtengo los tiempo para asm
    lista_asm512_int.append( int( tiempo.rstrip('\n') ) )


lista_c512_str=archivo_c512.readlines()

lista_c512_int=[]
for tiempo in lista_c512_str: #obtengo los tiempo para c
    lista_c512_int.append( int( tiempo.rstrip('\n') ) )

lista_c512_int_O0=lista_c512_int[0:cantTiempos]
lista_c512_int_O2=lista_c512_int[cantTiempos:2*cantTiempos]
lista_c512_int_O3=lista_c512_int[2*cantTiempos:3*cantTiempos]

#graficar rendimiento para matriz de 128x128
lenguajes = ["ASM", "C_O3", "C_O2", "C_O0"]
colors = ['#d3c0ab', '#babbb4', '#dda1ad', '#b9b8a4']
x = np.arange(1, len(lenguajes) + 1)
medianas_128 = [np.median(lista_asm128_int), np.median(lista_c128_int_O3), np.median(lista_c128_int_O2), np.median(lista_c128_int_O0)]

plt.ylabel('Mediana Clocks')
plt.xlabel('Implementaciones - Matriz 128 x 128')

plt.bar(x, medianas_128, align='center', color=colors)
plt.xticks(x, lenguajes)

plt.show()

#graficar rendimiento para matriz de 256x256
x = np.arange(1, len(lenguajes) + 1)
medianas_256 = [np.median(lista_asm256_int), np.median(lista_c256_int_O3), np.median(lista_c256_int_O2), np.median(lista_c256_int_O0)]

plt.ylabel('Mediana Clocks')
plt.xlabel('Implementaciones - Matriz 256 x 256')

plt.bar(x, medianas_256, align='center', color=colors)
plt.xticks(x, lenguajes)

plt.show()

#graficar rendimiento para matriz de 512x512
x = np.arange(1, len(lenguajes) + 1)
medianas_512 = [np.median(lista_asm512_int), np.median(lista_c512_int_O3), np.median(lista_c512_int_O2), np.median(lista_c512_int_O0)]

plt.ylabel('Mediana Clocks')
plt.xlabel('Implementaciones - Matriz 512 x 512')

plt.bar(x, medianas_512, align='center', color=colors)
plt.xticks(x, lenguajes)

plt.show()
