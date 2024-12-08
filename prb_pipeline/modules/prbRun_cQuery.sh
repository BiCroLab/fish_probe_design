#!/bin/bash


prbRun_cQuery() {

      LENGTH=40 ### Default value, overwritten by setting another --length-oligos
      SUBLENGTH=21
      FLAGMODE="DNA"

      while [[ "$#" -gt 0 ]]; do
          case "$1" in
              --cpu-per-job|-c) CPU_PER_JOB="${2:-$CPU_PER_JOB}"; shift ;;
              --length-oligos|-l) LENGTH="${2:-LENGTH}"; shift ;;
              --sub-length|-s) SUBLENGTH="${2:-SUBLENGTH}"; shift ;;
              --flag-mode|-f) FLAGMODE="${2:-FLAGMODE}"; shift ;;
              *) echo "Unknown option: $1" >&2; return 1 ;;
          esac
          shift
      done


      ### The ${GROUP} variable is inherited from <slurmArrayLauncher>
      ### Every row in ${GROUP} will be used to access a different sub-directory.

      ### Updating ${WORKDIR} to match the current input
      WORKDIR=$( cat ${GROUP} | sed -n "${SLURM_ARRAY_TASK_ID}p" ) && cd ${WORKDIR}

      ### Calculating minimum ${STEPDOWN} value for the current ${GENE_ID}
      ### By default, it will correspond to 5% of ${MAX_OLIGOS}    
      MAX_OLIGOS=$(cat ${WORKDIR}/data/rois/all_regions.tsv | cut -f 7 | tail -n+2 | sort -k1,1n | uniq | head -n1)
      STPERC=10
      STEPDOWN=$( echo | awk -v W=${MAX_OLIGOS} -v P=${STPERC} '{ M=W/100*P; printf "%.f\n",int(M+0.5)}')
      echo -e "Looking for ${MAX_OLIGOS} with --stepdown: ${STEPDOWN}"


      ### -- Accessing singularity container  
      CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
      WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
      prb="singularity exec --bind /group/ --bind /scratch/ --workdir ${WORKTMP} ${CONTAINER} prb"

      ### -- Printing some messages
      echo -e "Launching Job: ${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
      echo -e "Requested CPUs: ${CPU_PER_JOB}"
      echo -e "Working Directory: \"$(pwd)\""


      if [[ -z $(ls ${WORKDIR}/data/candidates/*.uint8 2>/dev/null) ]]; then 
       touch ${WORKDIR}/error.log && echo -e "Missing Files: check \"data/candidates/\"" > ${WORKDIR}/error.log
       echo "Necessary files are missing! Check if nHUSH has run correctly"; exit 1;
      fi


      ### -- Running prb functions

      ## Quite quick. Add header description to this step?
      ${prb} reform_hush_combined ${FLAGMODE} ${LENGTH} ${SUBLENGTH} 3  

      ## Quite quick. Add header description to this step?
      ${prb} melt_secs_parallel ${FLAGMODE}

      ## Quite quick. Add header description to this step?
      ${prb} build-db_BL -f q_bl -m 32 -i 6 -L ${LENGTH} -c 100 -d 8 -T 72 -y


      ### Launching Cycling Query:
      echo -e "$(date) <---- starting"  
      ${prb} cycling_query -s ${FLAGMODE} -L ${LENGTH} -m 8 -c 100 -t ${CPU_PER_JOB} -g 2500 -stepdown ${STEPDOWN} -greedy

      ### Clearing large temporary files. This part should be fixed, as it is still problematic.
      rm ${WORKDIR}/data/ref/genome.fa.aD 
      rm ${WORKDIR}/data/ref/genome.fa.aB*
      rm ${WORKDIR}/data/ref/genome.fa.aH*
      echo -e "$(date) <---- ending"

      ${prb} summarize_probes_final
      ${prb} visual report

      ### Space to add extra visual reports / summaries, if needed

}


export -f prbRun_cQuery; echo -e "> prbRun_cQuery"
