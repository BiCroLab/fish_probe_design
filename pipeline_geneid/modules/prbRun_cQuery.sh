#!/bin/bash


prbRun_cQuery() {

      LENGTH=40 ### Default value, overwritten by setting another --length-oligos

      while [[ "$#" -gt 0 ]]; do
          case "$1" in
              --work-dir|-w) WORKDIR="${2}"; shift ;;
              --cpu-per-job|-c) CPU_PER_JOB="${2:-$CPU_PER_JOB}"; shift ;;
              --length-oligos|-l) LENGTH="${2:-LENGTH}"; shift ;;
              *) echo "Unknown option: $1" >&2; return 1 ;;
          esac
          shift
      done


      ### The ${GROUP} variable is inherited from <slurmArrayLauncher>
      ### Every row in ${GROUP} corresponds to a different gene-id / sub-directory.
      ### Extracting the current ${GENE_ID} according to ${GROUP} and ${SLURM_ARRAY_TASK_ID}.
      ### Every job is associated with a ${SLURM_ARRAY_TASK_ID}, such as JOB_[1], JOB_[2], JOB_[3], etc.
      GENE_ID=$( cat ${GROUP} | sed -n "${SLURM_ARRAY_TASK_ID}p" )

      ### Updating ${WORKDIR} to match the current input
      WORKDIR="${WORKDIR}/split/${GENE_ID}" && cd ${WORKDIR}
      
      ### Calculating minimum ${STEPDOWN} value for the current ${GENE_ID}
      ### By default, it will correspond to 5% of ${MIN_WIDTH}    
      MIN_WIDTH=$(cat ${WORKDIR}/data/rois/all.regions.tsv | cut -f 7 | tail -n+2 | sort -k1,1n | uniq | head -n1)
      STPERC=5 
      STEPDOWN=$( echo | awk -v W=${MIN_WIDTH} -v P=${STPERC} '{ M=W/100*P; printf "%.f\n",int(M+0.5)}')


      ### -- Accessing singularity container  
      CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
      WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
      prb="singularity exec --bind /group/ --bind /scratch/ --workdir ${WORKTMP} ${CONTAINER} prb"

      ### -- Printing some messages
      echo -e "Launching Job: ${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
      echo -e "Requested CPUs: ${CPU_PER_JOB}"
      echo -e "Working Directory: \"$(pwd)\""



      ### -- Running prb functions

      ## Quite quick. Add header description to this step?
      ${prb} reform_hush_combined RNA ${LENGTH} 21 3  
      
      ## Quite quick. Add header description to this step?
      ${prb} melt_secs_parallel RNA

      ## Quite quick. Add header description to this step?
      ${prb} build-db_BL -f q_bl -m 32 -i 6 -L ${LENGTH} -c 100 -d 8 -T 72 -y


      ### Launching Cycling Query:
      echo -e "$(date) <---- starting"  
      ${prb} cycling_query -s RNA -L ${LENGTH} -m 8 -c 100 -t ${CPU_PER_JOB} -g 2500 -stepdown ${STEPDOWN} -greedy
     
      ### Clearing large temporary files. This part should be fixed, as it is still problematic.
      rm "${WORKDIR}/data/ref/genome.fa.aD" "{WORKDIR}/data/ref/genome.fa.aB8" "${WORKDIR}/data/ref/genome.fa.aH8"
      echo -e "$(date) <---- ending"

      ${prb} summarize_probes_final
      ${prb} visual report

      ### Space to add extra visual reports / summaries, if needed

}


export -f prbRun_cQuery; echo -e "> prbRun_cQuery"
