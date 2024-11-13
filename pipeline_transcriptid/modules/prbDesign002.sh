#!/bin/bash

prbDesign002() {

    #### -------------------------------------------------------- ####

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --input-id|-i) INPUT_ID="${2}"; shift ;;
            --genome-reference|-g) GENOME="${2}"; shift ;;
            --length-oligos|-l) LENGTH="${2}"; shift ;;
            --directory|-d) BASEPATH="${2}"; shift ;;
            --work-dir|-w) WORKDIR="${2}"; shift ;;
        esac
        shift
    done

   CHRFAKE="chr1"  ### not needed? --fake-chrom-name|-f) CHRFAKE="${2}"; shift ;;


   ### Reading input variables and setting paths
   TRANSCRIPT_ID=$(echo ${INPUT_ID} | awk '{print $1}')
   GENE_ID=$(echo ${INPUT_ID} | awk '{print $2}')
   GENE_NAME=$(echo ${INPUT_ID} | awk '{print $3}')

   ### Retrieving previously obtained object
   ANNOT_FILTERED="${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/${TRANSCRIPT_ID}.annot.tsv.gz"
   STRANDNESS=$(zcat ${ANNOT_FILTERED} | cut -f 6 | sort | uniq | head -n1)

   ### Extracting Genome Reference Prefix
   REF=$(basename ${GENOME} | sed -e 's/.fa.gz$//' -e 's/.fa$//' -e 's/.fasta$//' -e 's/.fna.gz$//')

   mkdir -p -m 770 ${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/data/rois
   mkdir -p -m 770 ${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/data/regions

   ### Initializing the headers for < all_regions.tsv >
   h01="Window_start" ; h02="Window_end"  ; h03="window_id" ; h04="chrom"   ; h05="DNA_start";
   h06="DNA_end"      ; h07="window"      ; h08="ref"       ; h09="length"  ; h10="Gene_start";
   h11="Gene_end"     ; h12="Gene_strand" ; h13="Gene_name" ; h14="Gene_id" ; h15="design_type";
   header="${h01}\t${h02}\t${h03}\t${h04}\t${h05}\t${h06}\t${h07}\t${h08}\t${h09}\t${h10}\t${h11}\t${h12}\t${h13}\t${h14}\t${h15}"
   echo -e ${header} > ${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/data/rois/all_regions.tsv

   ### tocheck, maybe skippable now;
   ANNOT_ISOFORM="${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/iso/${TRANSCRIPT_ID}.annot.tsv.gz"
   ### Calculating transcript length to assign < Window_start > and < Window_end >
   WIDTH_ISOFORM=$(zcat ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz | grep -v "^>" | wc -c)
   ### Setting MAX number of oligos to be searched for the current elements according to its length
   MAX_OLIGOS=$(echo | awk -v W=${WIDTH_ISOFORM} -v L=${LENGTH} '{ M=W/(L+10);printf "%.f\n",int(M+0.5)}')
    
    
   ### Assigning values for each input transcript isoform to < all_regions.tsv >
   ### -------------------------------------------------------------------------
   v01="1"                                   ## (h01) "Window_start"
   v02=$(( ${v01} + ${WIDTH_ISOFORM} ))      ## (h02) "Window_end"
   v03=1                                     ## (h03) "window_id"
   v04=${CHRFAKE}                            ## (h04) "chrom"
   v05=""                                    ## (h05) "DNA_start"
   v06=""                                    ## (h06) "DNA_end"
   v07=${MAX_OLIGOS}                         ## (h07) "window"
   v08=${REF}                                ## (h08) "ref" --------- e.g "Homo_sapiens.CHM13.dna"
   v09=${LENGTH}                             ## (h09) "length"
   v10=""                                    ## (h10) "Gene_start"
   v11=""                                    ## (h11) "Gene_end"
   v12=${STRANDNESS}                         ## (h12) "Gene_strand"
   v13=${GENE_NAME}                          ## (h13) "Gene_name"
   v14=${TRANSCRIPT_ID}                      ## (h14) "Gene_id"
   v15="RNA"                                 ## (h15) "design_type"
   ### -------------------------------------------------------------------------
   values="${v01}\t${v02}\t${v03}\t${v04}\t${v05}\t${v06}\t${v07}\t${v08}\t${v09}\t${v10}\t${v11}\t${v12}\t${v13}\t${v14}\t${v15}"

   ### Saving values to ./data/rois
   echo -e ${values} >> ${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/data/rois/all_regions.tsv

   ### Saving sequences to ./data/regions
   FASTA_HEADER=">ROI_${v03} pos=${v04}:${v01}-${v02}"

   zcat ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz \
      | grep -v "^>" | awk -v FH="${FASTA_HEADER}" 'BEGIN{FS=OFS="\t"}{ print FH; print $0}' \
      > ${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/data/regions/roi_${v03}.fa

      ROI_FASTA="${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/data/regions/roi_${v03}.fa"
      OUTPUT_FOLDER="${WORKDIR}/split/${GENE_NAME}/${TRANSCRIPT_ID}/data/candidates"
      mkdir -p -m 770 ${OUTPUT_FOLDER}


      ### Running Python to mimic <get_oligos.py> starting directly from FASTA files
      ### Accessing singularity container to access the required prb-dependencies
      CONTAINER="/group/bienko/containers/prb.sif"; module load --silent singularity
      WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
      prb="singularity exec --bind /group/ --bind /scratch/ --workdir ${WORKTMP} ${CONTAINER}"

      ${prb} python3 - <<-EOF
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

  echo -e " ✓"


}

export -f prbDesign002; echo -e "> prbDesign002" 
