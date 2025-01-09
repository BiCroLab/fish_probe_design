#!/bin/bash

prbTmpClear() {

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --work-dir|-w) WORKDIR="${2}"; shift ;;
        esac
        shift
    done


  ### Clearing a large number of temporary files and directories
  ### In case debugging is needed, this part should be commented out.

  rm -rf ${WORKDIR}/singularity.tmp 
  rm -rf ${WORKDIR}/slurm.tmp 
  rm -rf ${WORKDIR}/data
  rm -rf ${WORKDIR}/split/*/*/singularity.tmp
  rm -rf ${WORKDIR}/split/*/*/HUSH
  rm -rf ${WORKDIR}/split/*/*/data/blacklist
  rm -rf ${WORKDIR}/split/*/*/data/candidates
  rm -rf ${WORKDIR}/split/*/*/data/db
  rm -rf ${WORKDIR}/split/*/*/data/db_tsv
  rm -rf ${WORKDIR}/split/*/*/data/HUSH_candidates
  rm -rf ${WORKDIR}/split/*/*/data/logfiles
  rm -rf ${WORKDIR}/split/*/*/data/melt
  rm -rf ${WORKDIR}/split/*/*/data/probe_candidates
  rm -rf ${WORKDIR}/split/*/*/data/ref
  rm -rf ${WORKDIR}/split/*/*/data/secs
  rm -rf ${WORKDIR}/split/*/*/data/selected_probes
  rm ${WORKDIR}/split/*/*/data/final_probes_summary.tsv

  ### Directories that should be left untouched:
  ###
  ### -- {WORKDIR}/split/*/*/data/final_probes
  ### -- {WORKDIR}/split/*/*/data/regions
  ### -- {WORKDIR}/split/*/*/data/rois
  ### -- {WORKDIR}/split/*/*/data/visual_summary

  
  mkdir -p -m 770 ${WORKDIR}/prb_results

  for PRB in ${WORKDIR}/split/*/*/data/final_probes/*.tsv; do

   ### ---- Copying all final_probes results in a common [ ${WORKDIR}/prb_results ]   
   ID=$( echo ${PRB} | awk '{split($0, A, "split"); print A[2]}' | cut -f 3 -d "/" )
   INFO=$(basename ${PRB} | sed -e s'/probe_roi_1.//'g -e s'/.tsv//'g)
   cp ${PRB} ${WORKDIR}/prb_results/prb_${ID}_${INFO}.out

  done
  
    


}


export -f prbTmpClear; echo -e "> prbTmpClear" 
