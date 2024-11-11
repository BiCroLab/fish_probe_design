#!/bin/bash

prbDesign002() {

    #### -------------------------------------------------------- ####
    #### Inputs: 
    #### - Ensembl Gene identifier        <gene-id>
    #### - Genome Reference (fa)          <genome-reference>
    ####
    #### Effect 1:
    #### - Generating "${WORKDIR}/${GENE_ID}/data/rois/all_regions.tsv"
    #### - Every entry in this file will correspond to a different isoform.
    ####
    #### Effect 2:
    #### - Generating "${WORKDIR}/${GENE_ID}/data/regions/roi_${#}.fa"
    #### 
    #### Effect 3:
    #### - Generating "${WORKDIR}/${GENE_ID}/data/candidates/" files
    #### - Input sequences are split in K-mers (see "get_oligos.py")
    #### 
    #### All outputs can now be passed to the next functions.
    #### -------------------------------------------------------- ####

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --gene-id|-i) GENE_ID="${2}"; shift ;;
            --genome-reference|-g) GENOME="${2}"; shift ;;
            --length-oligos|-l) LENGTH="${2}"; shift ;;
            --fake-chrom-name|-f) CHRFAKE="${2}"; shift ;;
            --directory|-d) BASEPATH="${2}"; shift ;;
            --work-dir|-w) WORKDIR="${2}"; shift ;;
        esac
        shift
    done

    ### Retrieving previously obtained object
    ANNOT_FILTERED="${WORKDIR}/split/${GENE_ID}/${GENE_ID}.annot.tsv.gz"

    ### Extracting some information
    STRANDNESS=$(zcat ${ANNOT_FILTERED} | cut -f 6 | sort | uniq | head -n1)
    TRANSCRIPTS=$(zcat ${ANNOT_FILTERED} | cut -f 8 | sort | uniq)
    GENE_NAME=$(zcat ${ANNOT_FILTERED} | cut -f 7 | sort | uniq | head -n1)

    ### Extracting Genome Reference Prefix
    REF=$(basename ${GENOME} | sed -e 's/.fa.gz$//' -e 's/.fa$//' -e 's/.fasta$//' -e 's/.fna.gz$//')

    #MAX_OLIGOS=1000 ### (window column)--- let it vary dynamically TODO
    MAX_OLIGOS=$(echo | awk -v W=${WIDTH_ISOFORM} -v L=${LENGTH} '{ M=W/(L+10);printf "%.f\n",int(M+0.5)}')

    mkdir -p ${WORKDIR}/split/${GENE_ID}/data/rois
    mkdir -p ${WORKDIR}/split/${GENE_ID}/data/regions

    ### Initializing the headers for < all_regions.tsv >
    h01="Window_start" ; h02="Window_end"  ; h03="window_id" ; h04="chrom"   ; h05="DNA_start";
    h06="DNA_end"      ; h07="window"      ; h08="ref"       ; h09="length"  ; h10="Gene_start";
    h11="Gene_end"     ; h12="Gene_strand" ; h13="Gene_name" ; h14="Gene_id" ; h15="design_type";
    header="${h01}\t${h02}\t${h03}\t${h04}\t${h05}\t${h06}\t${h07}\t${h08}\t${h09}\t${h10}\t${h11}\t${h12}\t${h13}\t${h14}\t${h15}"
#   echo -e ${header} > ${WORKDIR}/split/${GENE_ID}/data/rois/all.regions.tsv
    echo -e ${header} > ${WORKDIR}/split/${GENE_ID}/data/rois/all_regions_tsv

    ### Initializing numeric index for different isoforms, assigned to < window_id >
    ISOFORM_INDEX=1

    for TRANSCRIPT_ID in ${TRANSCRIPTS}; do

      ANNOT_ISOFORM="${WORKDIR}/split/${GENE_ID}/iso/${TRANSCRIPT_ID}/${TRANSCRIPT_ID}.annot.tsv.gz"
      ### Calculating transcript length to assign < Window_start > and < Window_end >
      WIDTH_ISOFORM=$(zcat ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz | grep -v "^>" | wc -c)

      ### Assigning values for each input transcript isoform to < all_regions.tsv >
      ### -------------------------------------------------------------------------
      v01="1"                                   ## (h01) "Window_start"
      v02=$(( ${v01} + ${WIDTH_ISOFORM} ))      ## (h02) "Window_end"
      v03=${ISOFORM_INDEX}                      ## (h03) "window_id"
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
      v14=${TRANSCRIPT_ID}                            ## (h14) "Gene_id"
      v15="RNA"                                 ## (h15) "design_type"
      ### -------------------------------------------------------------------------
      values="${v01}\t${v02}\t${v03}\t${v04}\t${v05}\t${v06}\t${v07}\t${v08}\t${v09}\t${v10}\t${v11}\t${v12}\t${v13}\t${v14}\t${v15}"

      ### Saving values to ./data/rois
    #  echo -e ${values} >> ${WORKDIR}/split/${GENE_ID}/data/rois/all.regions.tsv
      echo -e ${values} >> ${WORKDIR}/split/${GENE_ID}/data/rois/all_regions_tsv

      ### Saving sequences to ./data/regions
      FASTA_HEADER=">ROI_${v03} pos=${v04}:${v01}-${v02}"

      zcat ${ANNOT_ISOFORM%%.tsv.gz}.concat.fa.gz \
         | grep -v "^>" | awk -v FH="${FASTA_HEADER}" 'BEGIN{FS=OFS="\t"}{ print FH; print $0}' \
         > ${WORKDIR}/split/${GENE_ID}/data/regions/roi_${v03}.fa

      ROI_FASTA="${WORKDIR}/split/${GENE_ID}/data/regions/roi_${v03}.fa"
      OUTPUT_FOLDER="${WORKDIR}/split/${GENE_ID}/data/candidates"
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

      ### Shifting index for next iteration, used for next < window_id >
      ISOFORM_INDEX=$(( ${ISOFORM_INDEX} + 1 ))

    done
    echo -e " ✓"

}

export -f prbDesign002; echo -e "> prbDesign002" 