#!/bin/bash

prbReferenceCreate() {

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --work-dir|-w) WORKDIR="${2}"; shift ;;
            --genome-reference|-g) GENOME="${2}"; shift ;;
            --length-oligos|-l) LENGTH="${2}"; shift ;;
        esac
        shift
    done

        
   ### Avoid this whole block if outputs already exist
   BL_OUT="${WORKDIR}/data/blacklist/genome.fa.abundant_L${LENGTH}_T100.fa"
   if [[ ! -f "${BL_OUT}" ]]; then
     echo -e "Generating References and Blacklist - $(date)"; 
     ### -- Accessing singularity container  
     CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
     WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p ${WORKTMP}
     prb="singularity exec --bind /group/ --bind /scratch/ --workdir ${WORKTMP} ${CONTAINER} prb"
        
     ### Creating reference folders and collecting reference annotations
     mkdir -p ${WORKDIR}/data/ref && cd ${WORKDIR}/data
     REF=$(basename ${GENOME} | sed -e 's/.fa.gz$//' -e 's/.fa$//' -e 's/.fasta$//' -e 's/.fna.gz$//')

     ### Fetching chromosome names from fasta index file
     cat "${GENOME}.fai" | cut -f 1 | grep "chr" \
      | grep -v "Un_" | grep -v "_alt" | grep -v "_random" | grep -v "chrKI" | grep -v "chrGL" \
      > ${WORKDIR}/data/ref/chrs.list

     echo -e "Extracting reference genome.."
     if [[ ! -f "${WORKDIR}/data/ref/genome.fa" ]]; then zcat ${GENOME} > "${WORKDIR}/data/ref/genome.fa"; fi

     ### Splitting FASTA into separate files
     module load samtools
     for CHR in $(cat ${WORKDIR}/data/ref/chrs.list); do
      echo -e "Splitting ${REF} > ${CHR}"
      samtools faidx ${WORKDIR}/data/ref/genome.fa "${CHR}" > "${WORKDIR}/data/ref/${CHR}.fa"
     done

     echo -e "Building blacklist - $(date)" 
     cd ${WORKDIR} && mkdir -p -m 770 ${WORKDIR}/data/blacklist
     ### Running < prb generate_blacklist >
     ${prb} generate_blacklist -L ${LENGTH} -c 100
    
    else

     echo -e "Blacklist object found. Skipping <prbReferenceCreate>"
    
    fi


}



export -f prbReferenceCreate; echo -e "> prbReferenceCreate"