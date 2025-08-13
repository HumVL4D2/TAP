#!/usr/bin/env nextflow

// Crear carpetas Data y Results si no existen
workflow.onStart {
    def dataDir = file(params.data_dir)
    def resultsDir = file(params.results_dir)
    if (!dataDir.exists()) dataDir.mkdirs()
    if (!resultsDir.exists()) resultsDir.mkdirs()
}

// Procesos
process DOWNLOAD_DATA {
    output:
    path "${params.data_dir}/*.fna"

    script:
    """
    #!/bin/bash
    USUARIO="lruiz"
    HOST="faraday.utem.cl"
    RUTA_REMOTA="/home/amoya/Data_forTap/selected_Genomes"
    ARCHIVOS=("GCF_022693325.1_ASM2269332v1_genomic.fna" "GCF_949788935.1_23220_1_42_h_nanopore_genomic.fna" "GCF_949789875.1_23495_7_287_h_nanopore_genomic.fna" "GCF_949788945.1_23495_7_344_h_nanopore_genomic.fna" "GCF_949790125.1_23220_1_59_h_nanopore_genomic.fna")
    DESTINO_LOCAL="${params.data_dir}"

    for archivo in "${ARCHIVOS[@]}"; do
        scp "$USUARIO@$HOST:$RUTA_REMOTA/$archivo" "$DESTINO_LOCAL"
    done

    echo "✅ Todos los archivos han sido copiados correctamente."
    """
}

process DESCRIBE_FILES {
    input:
    path fasta_files

    output:
    path "${params.results_dir}/descriptions.txt"

    script:
    """
    #!/bin/bash
    OUTPUT="${params.results_dir}/descriptions.txt"
    echo "Descripciones de archivos:" > \$OUTPUT

    for file in ${params.data_dir}/*.fna; do
        echo "Archivo: \$file" >> \$OUTPUT
        # Contar número de secuencias (líneas que empiezan con >)
        num_seq=\$(grep -c '^>' \$file)
        echo "Número de secuencias: \$num_seq" >> \$OUTPUT

        # Longitud total (sumar longitudes de secuencias, ignorando headers)
        total_len=\$(awk '/^>/{next} {len += length(\$0)} END {print len}' \$file)
        echo "Longitud total: \$total_len" >> \$OUTPUT

        # %GC (contar G+C y dividir por total bases)
        gc_count=\$(awk '/^>/{next} {gsub(/[GCgc]/,"&"); gc += gsub(/[GCgc]/,"")} END {print gc}' \$file)
        total_bases=\$total_len
        gc_percent=\$(echo "scale=2; (\$gc_count / \$total_bases) * 100" | bc)
        echo "%GC: \$gc_percent" >> \$OUTPUT
        echo "" >> \$OUTPUT
    done
    """
}

process CHECK_PYSPARK {
    script:
    """
    #!/bin/bash
    if ! python -c "import pyspark" &> /dev/null; then
        echo "Instalando PySpark..."
        pip install pyspark
    else
        echo "PySpark ya está instalado."
    fi
    """
}

process SEARCH_REGEX_PYSPARK {
    input:
    path fasta_files

    output:
    path "${params.results_dir}/regex_results.txt"

    script:
    'scripts/search_regex.py'  // Llama al script Python en carpeta scripts
}

process VISUALIZE_RESULTS {
    input:
    path descriptions
    path regex_results

    output:
    path "${params.results_dir}/*.png"

    script:
    'scripts/visualize.py'  // Llama al script Python para gráficos
}

workflow {
    downloaded = DOWNLOAD_DATA()
    CHECK_PYSPARK()
    descriptions = DESCRIBE_FILES(downloaded)
    regex_results = SEARCH_REGEX_PYSPARK(downloaded)
    VISUALIZE_RESULTS(descriptions, regex_results)
}