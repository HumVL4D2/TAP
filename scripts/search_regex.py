##!/usr/bin/env python3

import os
import re
from pyspark.sql import SparkSession
import sys

# Inicializar Spark
spark = SparkSession.builder.appName("RegexSearch").getOrCreate()

# Obtener archivos FASTA staged en el directorio actual
files = sorted([f for f in os.listdir('.') if f.endswith('.fna')])

if len(files) < 2:
    sys.exit("Error: Se necesitan al menos 2 archivos FASTA (1 query y 1 target).")

# Query: primer archivo, targets: los demás
query_file = files[0]
target_files = files[1:]

# Leer query y extraer secuencias (simplificado: concatena secuencias)
with open(query_file, 'r') as f:
    query_seq = ''.join(line.strip() for line in f if not line.startswith('>'))

# Regex ejemplo: buscar 'GC{2,}' (GC repetidos >=2)
regex_pattern = r'GC{2,}'

# Procesar targets con PySpark
def search_in_target(target):
    with open(target, 'r') as f:
        target_seq = ''.join(line.strip() for line in f if not line.startswith('>'))
    matches = re.findall(regex_pattern, target_seq)
    return (target, len(matches))

# Paralelizar
rdd = spark.sparkContext.parallelize(target_files)
results = rdd.map(search_in_target).collect()

# Guardar resultados
output = 'regex_results.txt'
with open(output, 'w') as out:
    for target, count in results:
        out.write(f"Target: {target}, Matches encontrados: {count}\n")

spark.stop()