#!/bin/bash



prbRun_nHUSH() {


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

      ### TODO: add other flags to control the arguments of nHUSH without having to change this code later on?


      ### The ${GROUP} variable is inherited from <slurmArrayLauncher>
      ### Every row in ${GROUP} corresponds to a different gene-id / sub-directory.
      ### Extracting the current ${GENE_ID} according to ${GROUP} and ${SLURM_ARRAY_TASK_ID}.
      ### Every job is associated with a ${SLURM_ARRAY_TASK_ID}, such as JOB_[1], JOB_[2], JOB_[3], etc.
      GENE_ID=$( cat ${GROUP} | sed -n "${SLURM_ARRAY_TASK_ID}p" )

      ### Updating ${WORKDIR} to match the current input
      WORKDIR="${WORKDIR}/split/${GENE_ID}" && cd ${WORKDIR}
      

      ### -- Accessing singularity container  
      CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
      WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
      prb="singularity exec --bind /group/ --bind /scratch/ --workdir ${WORKTMP} ${CONTAINER} prb"

      ### -- Printing some messages
      echo -e "Launching Job: ${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
      echo -e "Requested CPUs: ${CPU_PER_JOB}"
      echo -e "Working Directory: \"$(pwd)\""

      ### -- Running prb functions: [get_oligos] and [run_nHUSH]
      ${prb} run_nHUSH -d RNA -t ${CPU_PER_JOB} -L ${LENGTH} -l 21 -m 3 -i 14 -y

}


export -f prbRun_nHUSH; echo -e "> prbRun_nHUSH"
