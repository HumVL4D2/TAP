#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Variables
params.results_dir = "results"       // Output directory for all results
params.data_dir = "data"


// Create output directory
new File(params.results_dir).mkdirs()

// Crear carpetas Data y Results si no existen
workflow onStart {
    def dataDir = file(params.data_dir)
    def resultsDir = file(params.results_dir)
    if (!dataDir.exists()) dataDir.mkdirs()
    if (!resultsDir.exists()) resultsDir.mkdirs()
}

//Comentado porque Faraday esta caido
//process DOWNLOAD_DATA {
//    output:
//    path "${params.data_dir}/*.fna"

//    script:
//    '''
//    #!/bin/bash
//    USUARIO="lruiz"
//    HOST="faraday.utem.cl"
//    RUTA_REMOTA="/home/amoya/Data_forTap/selected_Genomes"
//    ARCHIVOS=("GCF_022693325.1_ASM2269332v1_genomic.fna" "GCF_949788935.1_23220_1_42_h_nanopore_genomic.fna")
//    DESTINO_LOCAL="${params.data_dir}"
//
//    for archivo in "${ARCHIVOS[@]}"; do
//        scp "$USUARIO@$HOST:$RUTA_REMOTA/$archivo" "$DESTINO_LOCAL"
//    done
//
//    echo "✅ Todos los archivos han sido copiados correctamente."
//    '''
//}

//Debido a que Faraday esta caido, este proceso alternativo permite descargar data
//publica desde el FTP de NCBI

process DOWNLOAD_DATA {
    publishDir "${params.data_dir}", mode: 'copy'

    output:
    path "*.fna"

    script:
    """
    #!/bin/bash

    # URLs directas válidas para 5 genomas bacterianos públicos de NCBI (usando path 'all' para consistencia)
    URLS=(
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/006/945/GCF_000006945.2_ASM694v2/GCF_000006945.2_ASM694v2_genomic.fna.gz"
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/009/045/GCF_000009045.1_ASM904v1/GCF_000009045.1_ASM904v1_genomic.fna.gz"
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/013/425/GCF_000013425.1_ASM1342v1/GCF_000013425.1_ASM1342v1_genomic.fna.gz"
        "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/269/985/GCF_000269985.1_ASM26998v1/GCF_000269985.1_ASM26998v1_genomic.fna.gz"  # Reemplazo válido para Streptococcus agalactiae
    )

    for url in "\${URLS[@]}"; do
        archivo=\$(basename "\$url")
        wget "\$url" -O "\$archivo"  # Removido -q para ver errores
        if [ ! -s "\$archivo" ]; then
            echo "Error: Descarga fallida para \$url"
            exit 1
        fi
        gunzip "\$archivo"
        if [ \$? -ne 0 ]; then
            echo "Error: gunzip falló para \$archivo"
            exit 1
        fi
    done

    echo "✅ Se han descargado y descomprimido 5 archivos .fna correctamente."
    """
}

process DESCRIBE_FILES {
    input:
    path fasta_files

    output:
    path "descriptions.txt"

    publishDir "${params.results_dir}", mode: 'copy'

    script:
    """
    #!/bin/bash
    OUTPUT="descriptions.txt"
    > \$OUTPUT  # Inicializa el archivo vacío, sin cabecera

    for file in *.fna; do
        echo "Archivo: \$file" >> \$OUTPUT
        num_seq=\$(grep -c '^>' \$file)
        echo "Número de secuencias: \$num_seq" >> \$OUTPUT
        total_len=\$(awk '!/^>/ {len += length(\$0)} END {print len}' \$file)
        echo "Longitud total: \$total_len" >> \$OUTPUT
        gc_count=\$(awk '!/^>/ {gc += gsub(/[GCgc]/,"")} END {print gc}' \$file)
        total_bases=\$total_len
        if [ "\$total_bases" -eq 0 ]; then
            gc_percent="0.00"
        else
            gc_percent=\$(echo "scale=2; (\$gc_count / \$total_bases) * 100" | bc)
        fi
        echo "%GC: \$gc_percent" >> \$OUTPUT
        echo "" >> \$OUTPUT
    done
    """
}

process CHECK_PYSPARK {
    script:
    '''
    #!/bin/bash
    if ! python -c "import pyspark" &> /dev/null; then
        echo "Instalando PySpark..."
        pip install pyspark
    else
        echo "PySpark ya está instalado."
    fi
    '''
}

process SEARCH_REGEX_PYSPARK {
    input:
    path fasta_files
    output:
    path "regex_results.txt"
    publishDir "${params.results_dir}", mode: 'copy'
    script:
    "python3 ${baseDir}/scripts/search_regex.py"
}

process VISUALIZE_RESULTS {
    input:
    path descriptions
    path regex_results

    output:
    path "*.png"

    publishDir "${params.results_dir}", mode: 'copy'

    script:
    "python3 ${baseDir}/scripts/visualize.py"
}

process CHECK_MATPLOTLIB {
    script:
    '''
    #!/bin/bash
    if ! python -c "import matplotlib" &> /dev/null; then
        echo "Instalando Matplotlib..."
        pip install matplotlib
    else
        echo "Matplotlib ya está instalado."
    fi
    '''
}

// Workflow principal
workflow {
    fasta_files = DOWNLOAD_DATA().collect()
    CHECK_PYSPARK()
    descriptions = DESCRIBE_FILES(fasta_files)
    regex_results = SEARCH_REGEX_PYSPARK(fasta_files)
    CHECK_MATPLOTLIB()
    VISUALIZE_RESULTS(descriptions, regex_results)
}
