#!/bin/bash

parseGTF() {

 while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --gene-annotation|-a) ANNOT_INPUT="${2}"; shift ;;
            --work-dir|-w) WORKDIR="${2}"; shift ;;
            --out-name|-o) OUTNAME="${2}"; shift ;;
        esac
        shift
    done

    ### Extract gene_id, gene_name and transcript_id values from GTF
    zcat ${ANNOT_INPUT} | awk 'BEGIN{FS=OFS="\t"} { split($9, X, ";");
      for(i in X) { if(X[i] ~ /gene_id/) {
         for(k in X) { if(X[k] ~ /gene_name/) {
           for(j in X) { if(X[j] ~ /transcript_id/) {
                gsub("gene_id", "", X[i]);
                gsub("gene_name", "", X[k]);
                gsub("transcript_id", "", X[j]);
                gsub("\"", "", X[i]);
                gsub("\"", "", X[k]);
                gsub("\"", "", X[j]); 
                print X[j], X[i], X[k] ; break; }}}}}}}' \
    | sed s'/ //'g | sort | uniq | gzip > ${WORKDIR}/${OUTNAME}

    echo -e "Saved ${WORKDIR}/${OUTNAME}" 

}

export -f parseGTF