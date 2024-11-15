#!/bin/bash

slurmBlocker() {

    ### Setting default values
    STIME=60

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --job-name|-j) NAME="${2}"; shift ;;
            --sleep-time|-s) STIME="${2}"; shift ;;
        esac
        shift
    done

    echo -e "slurmBlocker - ${NAME} starting: $(date)"

    ### Waiting for all ${NAME} jobs to have finished before resuming next steps.
    ### The while-loop below will stall execution for an indefinite time.

    while true; do
       PREVIOUS_JOBS=$(squeue -A ${USER} --array -h --name "${NAME}" -o "%.20u %.30j" | wc -l)
       if [[ ${PREVIOUS_JOBS} == 0 ]]; then echo ""; break ; else sleep ${STIME}; fi
    done

    echo -e "slurmBlocker - ${NAME} completed: $(date)"


}

export -f slurmBlocker; echo -e "> slurmBlocker"