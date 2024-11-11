#!/bin/bash

prbDesign001() {

    #### -------------------------------------------------------- ####
    #### Inputs: 
    #### - Ensembl Gene identifier        <gene-id>
    #### - Gencode GTF annotation         <gene-annotation>
    #### - Genome Reference (fa)          <genome-reference>
    ####
    #### Effect:
    #### - For each transcript isoform, the function collects all exons 
    #### - and retrieves the corresponding FASTA sequence. The resulting 
    #### - sequence is concatenated to form only one stretch per isoform.
    #### - Next, these outputs will be used in the following prb function.
    #### -------------------------------------------------------- ####

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --gene-id|-i) GENE_ID="${2}"; shift ;;
            --genome-reference|-g) GENOME="${2}"; shift ;;
            --gene-annotation|-a) ANNOT_INPUT="${2}"; shift ;;
            --ccds-only|-c) CCDS_FILTER="${2}"; shift ;;
            --directory|-d) BASEPATH="${2}"; shift ;;
            --work-dir|-w) WORKDIR="${2}"; shift ;;
        esac
        shift
    done


                ### TODO = specify conda environment? --- required: bedtools
   #source "/home/${USER}/miniconda3/bin/activate" gt ### module load bedtools?             --conda-env-name|
    module load bedtools2/2.31.0
  
   echo -e "${GENE_ID} ($(date))";

                 ### TODO = --ccds-only: OPTIONAL BEHAVIOUR:
                 ### FILTER OUT TRANSCRIPTS WITHOUT CCDS TAGS
                 #    zcat ${ANNOT_INPUT}  | grep -w "ccdsid"



   ANNOT_FILTERED="${WORKDIR}/split/${GENE_ID}/${GENE_ID}.annot.tsv.gz" 
   mkdir -p -m 770 ${WORKDIR}/split/${GENE_ID}


   if [[ ! $(zcat ${GENOME} | head -n1) =~ ">chr" ]]; then
    if [[ $(zcat $ANNOT_FILTERED | cut -f 1 | head -n1) =~ "chr" ]]; then
        ### Breaking code if FASTA has weird chromosome names in its header
        echo -e "FASTA and BED chromosome names must match!";
        return
    fi
   fi

   ### If input is gzipped, index files must be present.
   if [[ "$GENOME" == *.gz ]]; then
     if [[ ! -f "${GENOME}.fai" && -f "${GENOME}.gzi" ]]; then
        echo -e "$(basename ${GENOME}) (.fai/.gzi) index not found"; 
       return
     fi
   fi




   ### 1. Extracting Exons from input GTF object
   zcat ${ANNOT_INPUT} | grep -w ${GENE_ID} \
    | awk 'BEGIN{FS=OFS="\t"} { 
     if($3 == "exon") { split($9, X, ";");
      for(i in X) { if(X[i] ~ /gene_id/) {              # looking for <gene_id>
         for(k in X) { if(X[k] ~ /gene_name/) {         # looking for <gene_name>
           for(j in X) { if(X[j] ~ /transcript_id/) {   # looking for <transcript_id>
                gsub("gene_id", "", X[i]);
                gsub("gene_name", "", X[k]);
                gsub("transcript_id", "", X[j]);
                gsub("\"", "", X[i]);
                gsub("\"", "", X[k]); 
                gsub("\"", "", X[j]); 
                print $1, $4, $5, X[i], $6, $7, X[k], X[j] ; break; }}}}}}}}' \
    | sed s'/ //'g | gzip > ${ANNOT_FILTERED}

    ### 2. Extracting Strandness, Extracting List of Transcripts
    STRANDNESS=$(zcat ${ANNOT_FILTERED} | cut -f 6 | sort | uniq)
    TRANSCRIPTS=$(zcat ${ANNOT_FILTERED} | cut -f 8 | sort | uniq) 

    for TRANSCRIPT_ID in ${TRANSCRIPTS}; do

        mkdir -p ${WORKDIR}/split/${GENE_ID}/iso/${TRANSCRIPT_ID}/
        ANNOT_ISOFORM="${WORKDIR}/split/${GENE_ID}/iso/${TRANSCRIPT_ID}/${TRANSCRIPT_ID}.annot.tsv.gz"

        ### Extracting isoform-specific exons pr
        zcat ${ANNOT_FILTERED} \
         | awk -v ID=${TRANSCRIPT_ID} 'BEGIN{FS=OFS="\t"} { 
            if ( $8 == ID ) { print $0 }}' | gzip > ${ANNOT_ISOFORM}

        ### Fetching FASTA sequence of each exon. Input ${GENOME} requires .fai / .gzi index files.
        bedtools getfasta -fi ${GENOME} -bed ${ANNOT_ISOFORM} | gzip > ${ANNOT_ISOFORM%%.tsv.gz}.fa.gz;


        ### Concatenating FASTA of all isoform-specific exons
        zcat ${ANNOT_ISOFORM%%.tsv.gz}.fa.gz \
        | awk -v ID="${TRANSCRIPT_ID}" 'BEGIN{FS=OFS="\t"} { 
               if (/^>/) { next; } else { seq = seq $0; }
             } END { print ">" ID; print seq; }' \
        | gzip > ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz

        WIDTH_ISOFORM=$(zcat ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz | grep -v "^>" | wc -c)
        echo -e " >>> ${TRANSCRIPT_ID}\t(${STRANDNESS})\t${WIDTH_ISOFORM}bp"

        ### Note that all sequences are obtained from 5' -> 3' 
        ### Strandness is not being considered here.
        ### Later, make sure the pipeline actually computes reverse complement.
        
    done

}


export -f prbDesign001; echo -e "> prbDesign001" 