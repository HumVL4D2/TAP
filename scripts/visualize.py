import matplotlib.pyplot as plt
import sys

# Leer descriptions.txt
with open('./results/descriptions.txt', 'r') as f:
    desc = f.read().split('\n\n')  # Separar por archivo

files = []
num_seqs = []
total_lens = []
gc_percents = []

for block in desc:
    if block:
        lines = block.split('\n')
        files.append(lines[0].split(': ')[1])
        num_seqs.append(int(lines[1].split(': ')[1]))
        total_lens.append(int(lines[2].split(': ')[1]))
        gc_percents.append(float(lines[3].split(': ')[1]))

# Gráfico 1: Número de secuencias
plt.bar(files, num_seqs)
plt.title('Número de Secuencias por Archivo')
plt.xticks(rotation=45)
plt.savefig('./results/num_seqs.png')
plt.clf()

# Gráfico 2: Longitud total
plt.bar(files, total_lens)
plt.title('Longitud Total por Archivo')
plt.xticks(rotation=45)
plt.savefig('./results/total_lens.png')
plt.clf()

# Gráfico 3: %GC (de regex_results para variedad)
with open('./results/regex_results.txt', 'r') as f:
    regex = [int(line.split(': ')[2]) for line in f if line]

plt.bar(files[1:], regex)  # Solo targets
plt.title('Número de Matches Regex por Target')
plt.xticks(rotation=45)
plt.savefig('./results/regex_matches.png')