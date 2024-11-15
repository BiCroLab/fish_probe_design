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

        
   ### Checking if ${BLACKLIST_OUT} exists. Skip the block if it already exists.
   BLACKLIST_OUT="${WORKDIR}/data/blacklist/genome.fa.abundant_L${LENGTH}_T100.fa"

   if [[ ! -f "${BLACKLIST_OUT}" ]]; then
     echo -e "Generating References and Blacklist - $(date)"; 

     ### -- Accessing singularity container  
     CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
     WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
     nHUSH="singularity exec --bind /group/ --bind /scratch/ --workdir ${WORKTMP} ${CONTAINER} nhush"



     ### Creating reference folders and collecting reference annotations
     mkdir -p ${WORKDIR}/data/ref && cd ${WORKDIR}/data
     REF=$(basename ${GENOME} | sed -e 's/.fa.gz$//' -e 's/.fa$//' -e 's/.fasta$//' -e 's/.fna.gz$//')

     ### Fetching chromosome names from fasta index file
     cat "${GENOME}.fai" | cut -f 1 | grep "chr" | grep -v "Un_" | grep -v "_alt" | grep -v "_random" \
      | grep -v "chrKI" | grep -v "chrGL" > ${WORKDIR}/data/ref/chrs.list

     echo -e "Extracting reference genome.."
     if [[ ! -f "${WORKDIR}/data/ref/genome.fa" ]]; then zcat ${GENOME} > "${WORKDIR}/data/ref/genome.fa"; fi

     ### Splitting FASTA into separate files
     module load samtools
     for CHR in $(cat ${WORKDIR}/data/ref/chrs.list); do
      echo -e "Splitting ${REF} > ${CHR}"
      samtools faidx ${WORKDIR}/data/ref/genome.fa "${CHR}" > "${WORKDIR}/data/ref/${CHR}.fa"
     done

     echo -e "Building blacklist - $(date)" ; CUTOFF=100
     cd ${WORKDIR} && mkdir -p -m 770 ${WORKDIR}/data/blacklist
     ### Running < prb generate_blacklist >
     for GF in ${WORKDIR}/ref/genome*.fa; do
         ${nHUSH} find-abundant --file "${GF}" --length "${LENGTH}" --threshold "${CUTOFF}" \
          --out "${WORKDIR}/data/blacklist/$(basename ${GF}).abundant_L${LENGTH}_T${CUTOFF}.fa"
         echo -e "Blacklist object created!"
     done

   else
     echo -e "Blacklist object already exists. Skipping."
   fi



   ### Checking if ${HUSH_TMPFILE} exists. Skip the block if it already exists.
   HUSH_TMPFILE="${WORKDIR}/data/ref/genome.fa.aD"

   if [[ ! -f "${HUSH_TMPFILE}" ]]; then

     ### Generating genome.aD reference files. This might take around 20-30 minutes.
     CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
     WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
     HUSH="singularity exec --bind /group/ --workdir ${WORKTMP} ${CONTAINER} hushp"

     LOGS="${WORKDIR}/logs/prbReferenceHush" && mkdir -p -m 770 ${LOGS}
     SUBLENGTH=21 ; CPU=10

     export WORKDIR=${WORKDIR} ; export HUSH=${HUSH}; export SUBLENGTH=${SUBLENGTH}; export CPU=${CPU}

     echo -e "Building HUSH tmp files - $(date)" 

     sbatch \
      --nodes 1 \
      --ntasks "${CPU}" \
      --mem="40G" \
      --time="00:50:00" \
      --job-name "prbReferenceHush" \
      --export=ALL \
      -e "${LOGS}/slurm-%x_%A_%a.txt" \
      -o "${LOGS}/slurm-%x_%A_%a.txt" \
      --wrap="cd ${WORKDIR}/data/ref/ && ${HUSH} -r ${WORKDIR}/data/ref/genome.fa -l ${SUBLENGTH} -q no_folder -t ${CPU}"

     ### Holding execution to let the process finish
     slurmBlocker --job-name "prbReferenceHush" -s 5
   else

    echo -e "HUSH tmp objects already exist. Skipping."
    
   fi




   ### Adding a symbolic link to each data/ref subdirectory
   echo -e "Linking all subdirectories.."

   LINKDIR=0
   for SPLIT_DIR in ${WORKDIR}/split/*/*/data; do
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



export -f prbReferenceCreate; echo -e "> prbReferenceCreate"