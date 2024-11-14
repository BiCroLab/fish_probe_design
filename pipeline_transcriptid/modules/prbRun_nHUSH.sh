#!/bin/bash



prbRun_nHUSH() {


     LENGTH=40      ### Default value, overwritten by setting another --length-oligos
     SUBLENGTH=21

      while [[ "$#" -gt 0 ]]; do
          case "$1" in
              --cpu-per-job|-c) CPU_PER_JOB="${2:-$CPU_PER_JOB}"; shift ;;
              --length-oligos|-l) LENGTH="${2:-LENGTH}"; shift ;;
              --sub-length|-s) SUBLENGTH="${2:-SUBLENGTH}"; shift ;;
              *) echo "Unknown option: $1" >&2; return 1 ;;
          esac
          shift
      done


      ### The ${GROUP} variable is inherited from <slurmArrayLauncher>
      ### Every row in ${GROUP} will be used to access a different sub-directory.
    
      ### Updating ${WORKDIR} to match the current input
      WORKDIR=$( cat ${GROUP} | sed -n "${SLURM_ARRAY_TASK_ID}p" ) && cd ${WORKDIR}

      ### -- Accessing singularity container  
      CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
      WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
      prb="singularity exec --bind /group/ --bind /scratch/ --workdir ${WORKTMP} ${CONTAINER} prb"

      ### -- Printing some messages
      echo -e "Launching Job: ${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
      echo -e "Requested CPUs: ${CPU_PER_JOB}"
      echo -e "Working Directory: \"$(pwd)\""

      ### -- Running prb functions: [get_oligos] and [run_nHUSH]
      ${prb} run_nHUSH -d RNA -t ${CPU_PER_JOB} -L ${LENGTH} -l ${SUBLENGTH} -m 3 -i 14 -y


}


export -f prbRun_nHUSH; echo -e "> prbRun_nHUSH"
