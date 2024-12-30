#!/bin/bash

prbReadInputBed() {

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

    FLAGMODE="DNA"
    SPACER_FACTOR=10

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --input-regions|-i) ANNOT_INPUT="${2}"; shift ;;
            --genome-reference|-g) GENOME="${2}"; shift ;;
            --length-oligos|-l) LENGTH="${2}"; shift ;;
            --oligo-spacing-factor|-s) SPACER_FACTOR="${2:-$SPACER_FACTOR}"; shift ;;
            --work-dir|-w) WORKDIR="${2}"; shift ;;
            --flag-mode|-f) FLAGMODE="${2:-$FLAGMODE}"; shift ;;
            --singularity-image|-X) CONTAINER="${2}"; shift ;;
        esac
        shift
    done


   ### load bedtools from module or conda enviroment
   module load --silent bedtools2/2.31.0 ### todo, just build bedtools in sing image
   ### -- Accessing singularity container  
   module load --silent singularity
   WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
   ### BEDTOOLS="singularity exec --bind /group/ --bind ${WORKDIR} --workdir ${WORKTMP} ${CONTAINER} bedtools"
   PRB="singularity exec --bind /group/ --bind ${WORKDIR} --workdir ${WORKTMP} ${CONTAINER} python3"


   echo -e "prbReadInputBed - reading input: $(date)" 

   ### Extracting chr, start, end and region id
   if [[ "${ANNOT_INPUT}" == *.gz || "${ANNOT_INPUT}" == *.gzip ]]; then
    zcat ${ANNOT_INPUT} | awk 'BEGIN{FS=OFS="\t"} { print $1, $2, $3, $1"_"$2"_"$3 }' | gzip > ${WORKDIR}/prb_bed.id.txt.gz
   else
    cat ${ANNOT_INPUT} | awk 'BEGIN{FS=OFS="\t"} { print $1, $2, $3, $1"_"$2"_"$3 }' | gzip > ${WORKDIR}/prb_bed.id.txt.gz
   fi


   zcat ${WORKDIR}/prb_bed.id.txt.gz | while read -r INPUT_ID; do
    ### Creating one subset bed file for each region
    REGION_CHR=$(echo "${INPUT_ID}" | awk '{print $1}')
    REGION_START=$(echo "{$INPUT_ID}" | awk '{print $2}')
    REGION_END=$(echo "${INPUT_ID}" | awk '{print $3}')

    REGION_ID=$(echo "${INPUT_ID}" | awk '{print $4}')
    REGION_FILE="${WORKDIR}/split/regions/${REGION_ID}/${REGION_ID}.bed"

    mkdir -p -m 770 ${WORKDIR}/split/regions/${REGION_ID}/
    echo -e "${REGION_CHR}\t${REGION_START}\t${REGION_END}\t${REGION_ID}\t.\t+" > ${REGION_FILE}
    
    ### echo -e "## ${REGION_ID}"; echo -e "--- $(date)"



    ### Checking inputs
    ### Breaking code if FASTA has weird chromosome names in its header
    if [[ ! $(zcat ${GENOME} | head -n1) =~ ">chr" ]]; then
      if [[ $(zcat  ${WORKDIR}/prb_bed.id.txt.gz | cut -f 1 | head -n1) =~ "chr" ]]; then
          echo -e "FASTA and BED chromosome names must match!";
          return
      fi
    fi

    ### If input is gzipped, index files must be present.
    if [[ "${GENOME}" == *.gz ]]; then
      if [[ ! -f "${GENOME}.fai" && -f "${GENOME}.gzi" ]]; then
          echo -e "$(basename ${GENOME}) (.fai/.gzi) index not found"; 
        return
      fi
    fi



    ### Fetching FASTA sequence of each exon. Input ${GENOME} requires .fai / .gzi index files.
    bedtools getfasta -fi ${GENOME} -bed ${REGION_FILE} | gzip > ${REGION_FILE%%.bed}.concat.fa.gz;
    #${BEDTOOLS} getfasta -fi ${GENOME} -bed ${REGION_FILE} | gzip > ${REGION_FILE%%.bed}.concat.fa.gz;


    ### Adjusting input sequence based on strandness ---- not implemented
    # if [[ ${STRANDNESS} == "-" ]]; --------------------  

    ### Printing final width before exiting
    WIDTH_ISOFORM=$(zcat ${REGION_FILE%%.bed}.concat.fa.gz | grep -v "^>" | wc -c)
    MISSING_NTS=$(zcat "${REGION_FILE%%.bed}.concat.fa.gz" | grep -v "^>" | grep -o '[nN]' | wc -l)


    ### ----------------------------------------------------------------------
    ### --- Part 2 -----------------------------------------------------------
    ### ----------------------------------------------------------------------


    ### Extracting Genome Reference Prefix
    REF=$(basename ${GENOME} | sed -e 's/.fa.gz$//' -e 's/.fa$//' -e 's/.fasta$//' -e 's/.fna.gz$//')

    mkdir -p -m 770 ${WORKDIR}/split/regions/${REGION_ID}/data/rois
    mkdir -p -m 770 ${WORKDIR}/split/regions/${REGION_ID}/data/regions

    ### Initializing the headers for < all_regions.tsv >
    h01="Window_start" ; h02="Window_end"  ; h03="window_id" ; h04="chrom"   ; h05="DNA_start";
    h06="DNA_end"      ; h07="window"      ; h08="ref"       ; h09="length"  ; h10="Gene_start";
    h11="Gene_end"     ; h12="Gene_strand" ; h13="Gene_name" ; h14="Gene_id" ; h15="design_type";
    header="${h01}\t${h02}\t${h03}\t${h04}\t${h05}\t${h06}\t${h07}\t${h08}\t${h09}\t${h10}\t${h11}\t${h12}\t${h13}\t${h14}\t${h15}"
    echo -e ${header} > ${WORKDIR}/split/regions/${REGION_ID}/data/rois/all_regions.tsv

    ### Setting MAX number of oligos to be searched for the current elements according to its length
    MAX_OLIGOS=$(echo | awk -v W=${WIDTH_ISOFORM} -v L=${LENGTH} -v S=${SPACER_FACTOR} '{ M=W/(L+S);printf "%.f\n",int(M+0.5)}')


    ### Assigning values for each input transcript isoform to < all_regions.tsv >
    ### -------------------------------------------------------------------------
    v01=${REGION_START}                       ## (h01) "Window_start"
    v02=${REGION_END}                         ## (h02) "Window_end"
    v03=1                                     ## (h03) "window_id"
    v04=${REGION_CHR}                         ## (h04) "chrom"
    v05=""                                    ## (h05) "DNA_start"
    v06=""                                    ## (h06) "DNA_end"
    v07=${MAX_OLIGOS}                         ## (h07) "window"
    v08=${REF}                                ## (h08) "ref" --------- e.g "Homo_sapiens.CHM13.dna"
    v09=${LENGTH}                             ## (h09) "length"
    v10=""                                    ## (h10) "Gene_start"
    v11=""                                    ## (h11) "Gene_end"
    v12="+"                                   ## (h12) "Gene_strand"
    v13=${REGION_ID}                          ## (h13) "Gene_name"
    v14=${REGION_ID}                          ## (h14) "Gene_id"
    v15=${FLAGMODE}                           ## (h15) "design_type"
    ### -------------------------------------------------------------------------
    values="${v01}\t${v02}\t${v03}\t${v04}\t${v05}\t${v06}\t${v07}\t${v08}\t${v09}\t${v10}\t${v11}\t${v12}\t${v13}\t${v14}\t${v15}"

    ### Saving values to ./data/rois
    echo -e ${values} >> ${WORKDIR}/split/regions/${REGION_ID}/data/rois/all_regions.tsv

    ### Saving sequences to ./data/regions
    FASTA_HEADER=">ROI_${v03} pos=${v04}:${v01}-${v02}"

    zcat ${REGION_FILE%%.bed}.concat.fa.gz \
        | grep -v "^>" | awk -v FH="${FASTA_HEADER}" 'BEGIN{FS=OFS="\t"}{ print FH; print $0}' \
        | awk '{ if ($0 ~ /^>/) { print $0; next; } ; print toupper($0); }' \
        > ${WORKDIR}/split/regions/${REGION_ID}/data/regions/roi_${v03}.fa

    ROI_FASTA="${WORKDIR}/split/regions/${REGION_ID}/data/regions/roi_${v03}.fa"
    OUTPUT_FOLDER="${WORKDIR}/split/regions/${REGION_ID}/data/candidates"
    mkdir -p -m 770 ${OUTPUT_FOLDER}


    ### Running Python to mimic <get_oligos.py> starting directly from FASTA files
    ### Accessing singularity container to access the required prb-dependencies
    # CONTAINER="/group/bienko/containers/prb.sif"; module load --silent singularity
    # WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
    # PRB="singularity exec --bind /group/ --bind ${WORKDIR} --workdir ${WORKTMP} ${CONTAINER} python3"

    ${PRB} - <<-EOF &> /dev/null
import os
from Bio.SeqIO.FastaIO import SimpleFastaParser
from ifpd2q.scripts.extract_kmers import main as extract

def main(fasta_file, output_folder, kmer_length, gcfilter):
    # Ensure output directory exists
    os.makedirs(output_folder, exist_ok=True)

    # Read the FASTA file and process each sequence
    with open(fasta_file) as handle:
        for header, sequence in SimpleFastaParser(handle):
            # Create a full path for the output based on input FASTA name without 'roi_n_candidates'
            output_path = os.path.join(output_folder, f"{os.path.basename(fasta_file).replace('.fa', '')}_Reference.fa")
            with open(output_path, 'w') as out_f:
                out_f.write(f"{header}\n{sequence}\n")

            # Call the extract function
            extract(fasta_file, output_folder, kmer_length, gcfilter)

# Pass parameters directly to main
main("${ROI_FASTA}", "${OUTPUT_FOLDER}", ${LENGTH}, True)
EOF

rm "${OUTPUT_FOLDER}/roi_${v03}_Reference.fa"

  done

  echo -e " ✓"


}


export -f prbReadInputBed; echo -e "> prbReadInputBed" 
