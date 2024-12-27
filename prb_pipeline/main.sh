#!/bin/bash

### -----------------------------------------------------------------------------------
### All input variables will be set using a <prb.config> text file
### By default, looking for <prb.config> in the same directory as <main.sh>

DIRECTORY=$(realpath ${0%%$(basename ${0})})
PRB_PIPELINE="${DIRECTORY}/modules/prbMain.sh"
CONFIG="${DIRECTORY}/prb.config"

### -----------------------------------------------------------------------------------
### Reading variables from <prb.config>
VarReader() { cat ${CONFIG} | grep -w ${1} | grep -v "#" | cut -f 2 -d "=" | sed 's/[" ]//g' ; }

 BASEDIR=$( VarReader "BASEDIR" ) 
 WORKDIR=${BASEDIR}/$( VarReader "WORKDIR" ) && mkdir -p -m 770 ${WORKDIR}
 PIPELINE_MODS=${BASEDIR}/$( VarReader "MODULES" )
 
 GENOME=$(VarReader "GENOME")
 SPACING_FACTOR=$(VarReader "SPACING_FACTOR")
 INPUT_GTF=$(VarReader "INPUT_GTF")
 INPUT_FASTA=$(VarReader "INPUT_FASTA")
 INPUT_BED=$(VarReader "INPUT_BED") 
 OLIGO_LENGTH=$(VarReader "OLIGO_LENGTH")
 OLIGO_SUBLENGTH=$(VarReader "OLIGO_SUBLENGTH")


### -----------------------------------------------------------------------------------
### Starting prb pipeline and passing all variables

echo -e "Launching prbMain pipeline in ${WORKDIR}"

LOGS="${WORKDIR}/logs" && mkdir -p -m 770 ${LOGS}
LOGSFILE="${LOGS}/slurm-%x_%A_%a.txt"

export WORKDIR=${WORKDIR} PIPELINE_MODS=${PIPELINE_MODS} 
export GENOME=${GENOME} SPACING_FACTOR=${SPACING_FACTOR}
export INPUT_GTF=${INPUT_GTF} INPUT_FASTA=${INPUT_FASTA} INPUT_BED=${INPUT_BED}
export OLIGO_LENGTH=${OLIGO_LENGTH} OLIGO_SUBLENGTH=${OLIGO_SUBLENGTH}

sbatch                  \
 --job-name="prbMain"   \
 --nodes=1              \
 --ntasks-per-node=1    \
 --mem=4G               \
 --partition=cpuq       \
 --export=ALL           \
 -e ${LOGSFILE}         \
 -o ${LOGSFILE}         \
 --time=500:00:00       \
 ${PRB_PIPELINE}

