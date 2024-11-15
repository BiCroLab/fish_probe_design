#!/bin/bash


slurmArrayLauncher() {

    ### -- Setting default values. Overwritten by user-defined variables.
    MAX_RUNNING_JOBS=50 ; CPU_PER_JOB=5 ; MEM_PER_JOB="40G" ; RUN_TIME="24:00:00"
    
    ARRAY_MAX=400  ### Each SLURM Array will have a maximum of ${ARRAY_MAX} elements
    HPC_MAX=800    ### No more than ${HPC_MAX} jobs can co-exist in the HPC (both running / pending).


    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --work-dir|-w) WORKDIR="${2}"; shift ;;
            --command-name|-N) COMMAND="${2}"; shift ;;
            --command-args|-A) COMMAND_ARGS="${2}"; shift ;;
            --parallel-jobs|-p) MAX_RUNNING_JOBS="${2:-$MAX_RUNNING_JOBS}"; shift ;;
            --cpu-per-job|-c) CPU_PER_JOB="${2:-$CPU_PER_JOB}"; shift ;;
            --mem-per-job|-m) MEM_PER_JOB="${2:-$MEM_PER_JOB}"; shift ;;
            --time-req|-t) RUN_TIME="${2:-$RUN_TIME}"; shift ;;
            --slurm-array-max|-Q) ARRAY_MAX="${2:-$ARRAY_MAX}"; shift ;;
            --slurm-hpc-max|-Q) HPC_MAX="${2:-$HPC_MAX}"; shift ;;
            *) echo "Unknown option: $1" >&2; return 1 ;;
        esac
        shift
    done


    ### Assuming folders of interest start with a fixed pattern (ENSG) #Note will be a possible issue for genes coming from ONT/Sala annotation
    ## SPLIT_FOLDERS=$( ls ${WORKDIR}/split/ | grep -e "ENSG" -e "PATTERN2" ) # Test if grep is actually needed
    SPLIT_FOLDERS=$( ls ${WORKDIR}/split/*/ ) # Test if this works anyway. Probably yes.
    SPLIT_FOLDERS=$( find ${WORKDIR}/split -mindepth 2 -maxdepth 2 -type d)


    LOGS="${WORKDIR}/logs/$(date +%d%h.%H%M)" && mkdir -p -m 770 ${LOGS}

    ### Creating a file storing the total number of input entries.
    ### Then, splitting it into sub-files, each having a ${HPC_MAX} number of rows.
    mkdir -p -m 770 ${WORKDIR}/slurm.tmp/ && cd ${WORKDIR}/slurm.tmp/
    TOTAL_JOBS_INPUTS="${WORKDIR}/slurm.tmp/.split.folders.txt"
    rm -f "${TOTAL_JOBS_INPUTS}"; touch "${TOTAL_JOBS_INPUTS}"
    for SD in ${SPLIT_FOLDERS}; do echo ${SD} >> "${TOTAL_JOBS_INPUTS}"; done
    split -l ${ARRAY_MAX} ${TOTAL_JOBS_INPUTS} --numeric-suffixes=1 "slurm_subgroup_" -a 5
    SPLIT_NUM=$(ls ${WORKDIR}/slurm.tmp | grep 'slurm_subgroup' | wc -l )
    echo -e "Found a total of ${SPLIT_NUM} arrays, each with up to ${ARRAY_MAX} elements"
    ### --------------------------------------------------------------------------------


    ### Launching a slurm array for each sub-file group.
    SLURM_ARRAY_GROUPS=$( ls ${WORKDIR}/slurm.tmp | grep "slurm_subgroup" ); ARRAY_COUNTER=0

    for GROUP in ${SLURM_ARRAY_GROUPS}; do
    
        ### Passing ${GROUP} full path to each slurm array script
        GROUP="${WORKDIR}/slurm.tmp/${GROUP}" ; export GROUP=${GROUP}

        ### Total number of jobs in current array:
        TOTAL_JOBS_COUNT=$(cat ${GROUP} | wc -l ); ((ARRAY_COUNTER++))
        ### 
        echo -e "Processing Array #${ARRAY_COUNTER} - $(basename ${GROUP}) - (${TOTAL_JOBS_COUNT})"
    
        ### -------------------------------------------------------------------------------
        ### Slurm does not allow an infinite number of jobs to exist in the HPC queue.
        ### To prevent issues, only a maximum of ${HPC_MAX} of jobs will be submitted at the same time.
        ### If ${HPC_CURRENT} + ${ARRAY_MAX} exceeds the maximum number of allowed jobs: stalling.
        while true; do
          HPC_CURRENT=$(squeue -A ${USER} --array -h --name "${COMMAND}" -o "%.20u %.30j" | wc -l)
          ### This allows to start a new array, as long as the total jobs count does not exceed ${HPC_MAX}
          if [[ $(( ${HPC_CURRENT} + ${ARRAY_MAX} )) -lt ${HPC_MAX} ]]; then break ; else ((SLEEP_COUNTER++));
           if [[ ${SLEEP_COUNTER} = 1 ]]; then echo -e "Waiting for some jobs to finish... $(date +%d"-"%h" "%H":"%M)"; fi
           sleep 10; 
          fi
        done

        ### Submit the current array job
        sbatch \
         --nodes 1 \
         --ntasks "${CPU_PER_JOB}" \
         --mem="${MEM_PER_JOB}" \
         --time="${RUN_TIME}" \
         --job-name "${COMMAND}" \
         --export=ALL \
         --array=1-${TOTAL_JOBS_COUNT}%${MAX_RUNNING_JOBS} \
         -e "${LOGS}/slurm-%x_%A_%a.txt" \
         -o "${LOGS}/slurm-%x_%A_%a.txt" \
         --wrap="${COMMAND} ${COMMAND_ARGS}"

    done


}


export -f slurmArrayLauncher; echo -e "> slurmArrayLauncher"


    ### Usage Example:

            # slurmArrayLauncher \
            #  --work-dir ${WORKDIR}                                                  \
            #  --command-name prbRun_nHUSH                                            \
            #  --command-args "--work-dir ${WORKDIR} --cpu-per-job ${CPU_PER_JOB}"    \
            #  --parallel-jobs 30                                                     \
            #  --cpu-per-job 10                                                       \
            #  --mem-per-job "40G"                                                    \
            #  --time-req "10:00:00"



