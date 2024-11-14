#!/bin/bash

prbReferenceLinker() {

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --work-dir|-w) WORKDIR="${2}"; shift ;;
        esac
        shift
    done

    echo -e "Creating links to all subdirectories - $(date)" 

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



export -f prbReferenceLinker; echo -e "> prbReferenceLinker"