# Pipeline en Nextflow para Procesamiento de Archivos FASTA

## Descripción del Proyecto
Este proyecto implementa un pipeline en Nextflow para el procesamiento de archivos FASTA genómicos. El pipeline incluye la descarga de datos (usando URLs públicas de NCBI como alternativa temporal debido a problemas con el servidor HPC), cálculo de descripciones estadísticas (número de secuencias, longitud total y %GC), búsqueda de expresiones regulares usando PySpark, verificación e instalación de dependencias (PySpark y Matplotlib), y generación de visualizaciones gráficas. El objetivo es aplicar conceptos de workflows en bioinformática, enfocado en la Segunda Unidad del curso.
El pipeline se ejecuta localmente en WSL (Windows Subsystem for Linux) y está configurado para perfiles local y HPC. Se procesan al menos 5 archivos .fna para cumplir con los requisitos.

## Instrucciones de Uso del Pipeline
1. Requisitos previos:
* Instalar Nextflow: curl -s https://get.nextflow.io | bash (mueve el binario a un directorio en PATH).
* Tener Python 3 instalado con pip (para instalaciones automáticas de PySpark y Matplotlib).
* Acceso a internet para descargas.
2. Clonar el repositorio:
  
    git clone https://github.com/HumVL4D2/TAP.git
  
    cd TAP
3. Ejecutar el pipeline:
* Para ejecución local: nextflow run main.nf -profile local
* Esto creará las carpetas data y results si no existen, descargará archivos si es necesario, procesará los datos y generará resultados en results (incluyendo descriptions.txt, regex_results.txt y gráficos .png).
