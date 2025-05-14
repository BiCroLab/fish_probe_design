#!/bin/bash

prbReadInputFasta() {

    #### -------------------------------------------------------- ####
    #### Inputs: 
    #### - Single or Multi-line FASTA file        <input-fasta>
    ####
    #### Effect:
    #### - For each FASTA header, the function creates one sub-directory
    #### - with the corresponding FASTA sequence. The resulting sequence
    #### - will be used in the following prb function.
    #### -------------------------------------------------------- ####

    FLAGMODE="DNA"
    SPACER_FACTOR=10

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --input-fasta|-i) INPUT_FASTA="${2}"; shift ;;
            --work-dir|-w) WORKDIR="${2}"; shift ;;
            --genome-reference|-g) GENOME="${2}"; shift ;;
            --length-oligos|-l) LENGTH="${2}"; shift ;;
            --oligo-spacing-factor|-s) SPACER_FACTOR="${2:-$SPACER_FACTOR}"; shift ;;
            --flag-mode|-f) FLAGMODE="${2:-$FLAGMODE}"; shift ;;
            --singularity-image|-X) CONTAINER="${2}"; shift ;;
        esac
        shift
    done


    ### Accessing singularity container to access the required prb-dependencies
    ${SINGULARITY_ACTIVATE}
    WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
    IMG="singularity exec --bind /group/ --bind ${WORKDIR} --workdir ${WORKTMP} ${CONTAINER}"    

    echo -e "prbReadInputFasta - reading input: $(date)" 

    if [[ "${INPUT_FASTA}" == *.gz || "${INPUT_FASTA}" == *.gzip ]]; then
     mkdir -p -m 770 ${WORKDIR}; zcat ${INPUT_FASTA} > "${WORKDIR}/${INPUT_FASTA}.tmp"
    else 
     mkdir -p -m 770 ${WORKDIR}; cat ${INPUT_FASTA} > "${WORKDIR}/${INPUT_FASTA}.tmp"
    fi

    ### --------------- Step 1: Preparing FASTA sequences and initializing all sub-directories
    ### ---------------         Reading ${INPUT_FASTA} and saving one ${OUTPUT_FASTA} per header
      
    awk -v WORKDIR="$WORKDIR" ' function adjust_header(h) {
            gsub(/^>/, "", h)
            gsub(/[ :+\/-]/, "_", h)
            gsub(/_+/, "_", h)           # Collapse multiple underscores
            sub(/^_/, "", h)             # Remove leading underscore if present
            return h
        }
    /^>/ {
        if (seq != "") {
            print ">" clean_header > out
            print seq >> out
        }
        raw_header = $0
        clean_header = adjust_header(raw_header)
        out = WORKDIR "/split/sequences/" clean_header "/seq_" clean_header ".fa"
        system("mkdir -p -m 770 \"" WORKDIR "/split/sequences/" clean_header "\"")
        seq = ""
        next
    }
    {
        seq = seq $0
    }
    END {
        if (seq != "") {
            print ">" clean_header > out
            print seq >> out
        }
    }' "${WORKDIR}/${INPUT_FASTA}.tmp" && rm ${WORKDIR}/${INPUT_FASTA}.tmp


    for DIR in ${WORKDIR}/split/sequences/*; do 
    
       HEADER=$(basename ${DIR})
       OUTPUT_DIREC="${WORKDIR}/split/sequences/${HEADER}/"
       OUTPUT_TMP="${OUTPUT_DIREC}/seq_${HEADER}.fa"
       OUTPUT_FASTA="${OUTPUT_DIREC}/${HEADER}.concat.fa.gz"

       ### Compressing output and removing temporary files
       cat "${OUTPUT_TMP}" | gzip > "${OUTPUT_FASTA}" && rm "${OUTPUT_TMP}"
       WIDTH_ISOFORM=$(zcat ${OUTPUT_FASTA} | grep -v "^>" | wc -c)


       ### --------------- Step 2: Generating data/rois and data/region

       ### Extracting Genome Reference Prefix
       REF=$(basename ${GENOME} | sed -e 's/.fa.gz$//' -e 's/.fa$//' -e 's/.fasta$//' -e 's/.fna.gz$//')

       mkdir -p -m 770 ${OUTPUT_DIREC}/data/rois ; mkdir -p -m 770 ${OUTPUT_DIREC}/data/regions

       ### Initializing the headers for < all_regions.tsv >
       h01="Window_start" ; h02="Window_end"  ; h03="window_id" ; h04="chrom"   ; h05="DNA_start";
       h06="DNA_end"      ; h07="window"      ; h08="ref"       ; h09="length"  ; h10="Gene_start";
       h11="Gene_end"     ; h12="Gene_strand" ; h13="Gene_name" ; h14="Gene_id" ; h15="design_type";
       header="${h01}\t${h02}\t${h03}\t${h04}\t${h05}\t${h06}\t${h07}\t${h08}\t${h09}\t${h10}\t${h11}\t${h12}\t${h13}\t${h14}\t${h15}"
       echo -e ${header} > ${OUTPUT_DIREC}/data/rois/all_regions.tsv

       ### Calculating transcript length to assign < Window_start > and < Window_end >
       ### Setting MAX number of oligos to be searched for the current elements according to its length
       MAX_OLIGOS=$(echo | awk -v W=${WIDTH_ISOFORM} -v L=${LENGTH} -v S=${SPACER_FACTOR} '{ M=W/(L+S);printf "%.f\n",int(M+0.5)}')

       ### Assigning values for each input transcript isoform to < all_regions.tsv >
       ### -------------------------------------------------------------------------
       v01="1"                                   ## (h01) "Window_start"
       v02=$(( ${v01} + ${WIDTH_ISOFORM} ))      ## (h02) "Window_end"
       v03=1                                     ## (h03) "window_id"
       v04="chr1"                                ## (h04) "chrom"
       v05=""                                    ## (h05) "DNA_start"
       v06=""                                    ## (h06) "DNA_end"
       v07=${MAX_OLIGOS}                         ## (h07) "window"
       v08=${REF}                                ## (h08) "ref" --------- e.g "Homo_sapiens.CHM13.dna"
       v09=${LENGTH}                             ## (h09) "length"
       v10=""                                    ## (h10) "Gene_start"
       v11=""                                    ## (h11) "Gene_end"
       v12="+"                                   ## (h12) "Gene_strand"
       v13=${HEADER}                             ## (h13) "Gene_name"
       v14=${HEADER}                             ## (h14) "Gene_id"
       v15=${FLAGMODE}                           ## (h15) "design_type"
       ### -------------------------------------------------------------------------
       values="${v01}\t${v02}\t${v03}\t${v04}\t${v05}\t${v06}\t${v07}\t${v08}\t${v09}\t${v10}\t${v11}\t${v12}\t${v13}\t${v14}\t${v15}"

       ### Saving values to ./data/rois
       echo -e ${values} >> ${OUTPUT_DIREC}/data/rois/all_regions.tsv

       ### Saving sequences to ./data/regions
       FASTA_HEADER=">ROI_${v03} pos=${v04}:${v01}-${v02}"

       zcat ${OUTPUT_FASTA} \
        | grep -v "^>" | awk -v FH="${FASTA_HEADER}" 'BEGIN{FS=OFS="\t"}{ print FH; print $0}' \
        | awk '{ if ($0 ~ /^>/) { print $0; next; } ; print toupper($0); }' \
        > ${OUTPUT_DIREC}/data/regions/roi_${v03}.fa

        ROI_FASTA="${OUTPUT_DIREC}/data/regions/roi_${v03}.fa"
        OUTPUT_FOLDER="${OUTPUT_DIREC}/data/candidates"
        mkdir -p -m 770 ${OUTPUT_FOLDER}


        ### Running Python to mimic <get_oligos.py> starting directly from FASTA files
        ${IMG} python3 - <<-EOF &> /dev/null
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


export -f prbReadInputFasta; echo -e "> prbReadInputFasta" 
