#!/bin/bash

prbInitLinks() {

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --work-dir|-w) WORKDIR="${2}"; shift ;;
            --genome-reference|-g) GENOME="${2}"; shift ;;
            --link-only|-x) LINKMODE="true"; shift ;;
            --length-oligos|-l) LENGTH="${2}"; shift ;;
        esac
        shift
    done

    ### Skip to the last part if --link-only is used
   # if [[ "$LINKMODE" != "true" ]]; then
        ### Avoid this whole block if outputs already exist
        BL_OUT="${WORKDIR}/data/blacklist/genome.fa.abundant_L${LENGTH}_T100.fa"
        #if [[ ! -f "${WORKDIR}/data/ref/genome.fa" && ! -f "${BL_OUT}" ]]; then
       # if [[  -f "${WORKDIR}/data/ref/genome.fa" ]]; then         
#           echo -e "Generating References and Blacklist - $(date)"; 
          
#           ## -- Accessing singularity container  
#           CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
#           WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p ${WORKTMP}
#           prb="singularity exec --bind /group/ --bind /scratch/ --workdir ${WORKTMP} ${CONTAINER} prb"
        
#           ### Creating reference folders and collecting reference annotations
#           mkdir -p ${WORKDIR}/data/ref && cd ${WORKDIR}/data

#           REF=$(basename ${GENOME} | sed -e 's/.fa.gz$//' -e 's/.fa$//' -e 's/.fasta$//' -e 's/.fna.gz$//')

#           ### Fetching chromosome names from fasta index file
#           cat "${GENOME}.fai" | cut -f 1 | grep "chr" \
#            | grep -v "Un_" | grep -v "_alt" | grep -v "_random" | grep -v "chrKI" | grep -v "chrGL" \
#            > ${WORKDIR}/data/ref/chrs.list

#           echo -e "Extracting reference genome.."
#           if [[ ! -f "${WORKDIR}/data/ref/genome.fa" ]]; then zcat ${GENOME} > "${WORKDIR}/data/ref/genome.fa"; fi

#           ### Splitting FASTA into separate files
#           module load samtools
#           for CHR in $(cat ${WORKDIR}/data/ref/chrs.list); do
#            echo -e "Splitting ${REF} > ${CHR}"
#            samtools faidx ${WORKDIR}/data/ref/genome.fa "${CHR}" > "${WORKDIR}/data/ref/${CHR}.fa"
#           done

#           echo -e "Building blacklist - $(date)" 
#           cd ${WORKDIR} && mkdir -p -m 770 ${WORKDIR}/data/blacklist
#           ### Running < prb generate_blacklist >
#           ${prb} generate_blacklist -L ${LENGTH} -c 100

#      #   fi
#    # fi

    echo -e "Creating links to all subdirectories - $(date)" 

    LINKDIR=0
    for SPLIT_DIR in ${WORKDIR}/split/*/data; do
        if [[ -d "${SPLIT_DIR}" ]]; then
 
     ((LINKDIR++))
     mkdir -p -m 770 ${SPLIT_DIR}/blacklist ${SPLIT_DIR}/ref
     ### Linking to ${WORKDIR}/data/blacklist and ${WORKDIR}/data/ref to each subdirectory
     ln -sf ${WORKDIR}/data/blacklist/* ${SPLIT_DIR}/blacklist
     ln -sf ${WORKDIR}/data/ref/* ${SPLIT_DIR}/ref
        else
        echo -e "No directories found!"
        fi
    done

    echo -e "Total folders linked: ${LINKDIR}"

}



export -f prbInitLinks; echo -e "> prbInitLinks"