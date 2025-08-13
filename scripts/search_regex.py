from pyspark.sql import SparkSession
import sys
import re

# Inicializar Spark
spark = SparkSession.builder.appName("RegexSearch").getOrCreate()

# Asumir archivos en data_dir (pasados como argumentos o hardcoded para simplicidad)
data_dir = './data'
files = [f"{data_dir}/{f}" for f in ["GCF_949788935.1_23220_1_42_h_nanopore_genomic.fna", "GCF_949789875.1_23495_7_287_h_nanopore_genomic.fna", "GCF_949788945.1_23495_7_344_h_nanopore_genomic.fna", "GCF_949790125.1_23220_1_59_h_nanopore_genomic.fna", "GCF_949790135.1_23220_1_60_h_nanopore_genomic.fna"]]

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
output = './results/regex_results.txt'
with open(output, 'w') as out:
    for target, count in results:
        out.write(f"Target: {target}, Matches encontrados: {count}\n")

spark.stop()