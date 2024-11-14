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

    CCDS_FILTER="FALSE"

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --input-id|-i) INPUT_ID="${2}"; shift ;;
            --genome-reference|-g) GENOME="${2}"; shift ;;
            --gene-annotation|-a) ANNOT_INPUT="${2}"; shift ;;
            --ccds-only|-c) CCDS_FILTER="TRUE"; shift ;;
            --directory|-d) BASEPATH="${2}"; shift ;;
            --work-dir|-w) WORKDIR="${2}"; shift ;;
        esac
        shift
    done

   
   ### load bedtools from module or conda enviroment
   module load --silent bedtools2/2.31.0 ### todo, just build bedtools in sing image

   ### Reading input variables and setting paths
   TRANSCRIPT_ID=$(echo ${INPUT_ID} | awk '{print $1}')
   GENE_ID=$(echo ${INPUT_ID} | awk '{print $2}')
   GENE_NAME=$(echo ${INPUT_ID} | awk '{print $3}')
   
   echo -e "${GENE_NAME} ${GENE_ID} ${TRANSCRIPT_ID}"; echo -e "--- $(date)"

   ANNOT_FILTERED="${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/${TRANSCRIPT_ID}.annot.tsv.gz"
   ANNOT_FILTERED_TMP="${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/${TRANSCRIPT_ID}.annot.tmp"
   
   mkdir -p -m 770 ${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/


   ### 1. Checking inputs
   ### Breaking code if FASTA has weird chromosome names in its header
   if [[ ! $(zcat ${GENOME} | head -n1) =~ ">chr" ]]; then
    if [[ $(zcat ${ANNOT_FILTERED} | cut -f 1 | head -n1) =~ "chr" ]]; then
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

   ### Extracting Gene from input GTF object. CCDS-filtering is applied here, if requested.
   if [[ "$CCDS_FILTER" == "TRUE" ]]; then
       echo "Applying CCDS filter to ${TRANSCRIPT_ID}"
       zcat ${ANNOT_INPUT} | grep -w ${TRANSCRIPT_ID} | grep -E 'tag "CCDS"|ccdsid'  > ${ANNOT_FILTERED_TMP}
       if [[ ! -s ${ANNOT_FILTERED_TMP} ]]; then
          echo -e "No CCDS tag found. Ignoring CCDS filter."
          zcat ${ANNOT_INPUT} | grep -w ${TRANSCRIPT_ID} > ${ANNOT_FILTERED_TMP}
        else
          echo "CCDS transcript found"
       fi
   else
       echo "Selecting ${TRANSCRIPT_ID} without considering CCDS."
       zcat ${ANNOT_INPUT} | grep -w ${TRANSCRIPT_ID} > ${ANNOT_FILTERED_TMP}
   fi
        

   ### 2. Extracting Exons from input GTF object
   cat ${ANNOT_FILTERED_TMP} | grep -w ${TRANSCRIPT_ID} \
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
                print $1, $4-1, $5, X[i], $6, $7, X[k], X[j] ; break; }}}}}}}}' \
    | sed s'/ //'g | gzip > ${ANNOT_FILTERED}

    ### 3. Extracting Strandness information
    STRANDNESS=$(zcat ${ANNOT_FILTERED} | cut -f 6 | sort | uniq)


    mkdir -p ${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/iso/
    ANNOT_ISOFORM="${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/iso/${TRANSCRIPT_ID}.annot.tsv.gz"


    ### Extracting isoform-specific exons -- todo, check if this is still necessary
    zcat ${ANNOT_FILTERED} | awk -v ID=${TRANSCRIPT_ID} 'BEGIN{FS=OFS="\t"} { 
            if ( $8 == ID ) { print $0 }}' | gzip > ${ANNOT_ISOFORM}


    ### 4. Fetching FASTA sequence of each exon. Input ${GENOME} requires .fai / .gzi index files.
    bedtools getfasta -fi ${GENOME} -bed ${ANNOT_ISOFORM} | gzip > ${ANNOT_ISOFORM%%.tsv.gz}.fa.gz;

    ### 5. Concatenating FASTA of all isoform-specific exons
    zcat ${ANNOT_ISOFORM%%.tsv.gz}.fa.gz \
      | awk -v ID="${TRANSCRIPT_ID}" 'BEGIN{FS=OFS="\t"} { 
               if (/^>/) { next; } else { seq = seq $0; }
           } END { print ">" ID; print seq; }' \
      | gzip > ${ANNOT_ISOFORM%%.tsv.gz}.concat.unstranded.tmp

    ### 6. Adjust input sequence based on strandness
    if [[ ${STRANDNESS} == "-" ]];
     then 
       ### Getting reverse complement 
       zcat ${ANNOT_ISOFORM%%.tsv.gz}.concat.unstranded.tmp \
        | awk '/^>/ {print; next} {print | "tr \"ACGTacgt\" \"TGCAtgca\" | rev"}' \
        | gzip > ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz
     else
       zcat ${ANNOT_ISOFORM%%.tsv.gz}.concat.unstranded.tmp \
        | gzip > ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz
    fi

    ### 7. Clearing temporary files
    rm ${ANNOT_FILTERED_TMP}
    rm ${ANNOT_ISOFORM%%.tsv.gz}.concat.unstranded.tmp 

    ### 8. Printing final width before exiting
    WIDTH_ISOFORM=$(zcat ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz | grep -v "^>" | wc -c)
    echo -e " >>> ${TRANSCRIPT_ID}\t(${STRANDNESS})\t${WIDTH_ISOFORM}bp"

}


export -f prbDesign001; echo -e "> prbDesign001" 
