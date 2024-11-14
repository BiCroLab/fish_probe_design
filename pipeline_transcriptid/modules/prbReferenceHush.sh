#!/bin/bash


prbReferenceHush() {

    SUBLENGTH=21 ; CPU=5

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --work-dir|-w) WORKDIR="${2}"; shift ;;
        esac
        shift
    done

    CONTAINER="/group/bienko/containers/prb.sif" ; module load --silent singularity
    WORKTMP="${WORKDIR}/singularity.tmp/" && mkdir -p -m 770 ${WORKTMP}
    HUSH="singularity exec --bind /group/ --workdir ${WORKTMP} ${CONTAINER} hushp"

    LOGS="${WORKDIR}/logs/prbReferenceHush" && mkdir -p -m 770 ${LOGS}
    export WORKDIR=${WORKDIR} ; export HUSH=${HUSH}; export SUBLENGTH=${SUBLENGTH}; export CPU=${CPU}

    sbatch \
     --nodes 1 \
     --ntasks "${CPU}" \
     --mem="40G" \
     --time="01:00:00" \
     --job-name "prbReferenceHush" \
     --export=ALL \
     -e "${LOGS}/slurm-%x_%A_%a.txt" \
     -o "${LOGS}/slurm-%x_%A_%a.txt" \
     --wrap="
   cd ${WORKDIR}/data/ref/ && ${HUSH} -r ${WORKDIR}/data/ref/genome.fa -l ${SUBLENGTH} -q no_folder -t ${CPU}
            "

}


export -f prbReferenceHush; echo -e "> prbReferenceHush"