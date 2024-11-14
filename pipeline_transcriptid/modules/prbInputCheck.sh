#!/bin/bash

prbInputCheck() {

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --work-dir|-w) WORKDIR="${2}"; shift ;;
        esac
        shift
    done


    ### Looking for missing values and possible errors.
    # echo -e "Looking for genes with have empty rois tsv ..."
    # wc -l ${WORKDIR}/split/*/*/data/rois/all_regions.tsv | awk '$1 == 1 {print $2}' \
    #  | cut -d '/' -f 2 

   
    ### Any other check can be inserted here


}



export -f prbInputCheck; echo -e "> prbInputCheck"