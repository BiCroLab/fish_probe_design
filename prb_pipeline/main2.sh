#!/bin/bash

#SBATCH --job-name=prb_main --partition=cpuq --time=240:00:00
#SBATCH --nodes=1 --ntasks-per-node=1 --mem=4G


  ### -----------------------------------------------------------------------------------
  ### -----------------------------------------------------------------------------------
  ### -----------------------------------------------------------------------------------
  ### All input variables will be set using a <prb.config> text file
  ### By default, looking in the current directory.

   CONFIG="prb.config"

   while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --config|-c) CONFIG="${2:-$CONFIG}"; shift ;;
        esac
        shift
    done

  VarReader() { cat ${CONFIG} | grep -w ${1} | grep -v "#" | cut -f 2 -d "=" | sed 's/[" ]//g' ; }

  BASEDIR=$( VarReader "BASEDIR" ) 
  WORKDIR=${BASEDIR}/$( VarReader "WORKDIR" ) && mkdir -p ${WORKDIR}
  PIPELINE_MODS=${BASEDIR}/$( VarReader "MODULES" )
 
  GENOME=$(VarReader "GENOME"); SPACING_FACTOR=$(VarReader "SPACING_FACTOR")
  INPUT_GTF=$(VarReader "INPUT_GTF"); INPUT_FASTA=$(VarReader "INPUT_FASTA") ; INPUT_BED=$(VarReader "INPUT_BED") 
  OLIGO_LENGTH=$(VarReader "OLIGO_LENGTH"); OLIGO_SUBLENGTH=$(VarReader "OLIGO_SUBLENGTH")

  

  ### -----------------------------------------------------------------------------------
  ### -----------------------------------------------------------------------------------
  ### -----------------------------------------------------------------------------------



### 1. Importing Pipeline Modules
echo -e "Importing Pipeline Modules:" && for MOD in ${PIPELINE_MODS}/*.sh; do source ${MOD}; done
### ----------------------------------------------------------------------------------
  
### 2. Input Pre-Processing ----------------------------------------------------------------
### ----------------------------------------------------------------------------------
### --- [prbReadInputGTF] Extracting input objects from provided GTF file
### --- [prbReadInputFasta] Extracting input objects from provided FASTA file
### --- [prbReadInputBed] Extracting input objects from provided BED file


if [[ ${INPUT_GTF} != "" ]]; then 

 prbReadInputGTF         \
  -i ${INPUT_GTF}        \
  -g ${GENOME}           \
  -w ${WORKDIR}          \
  -l ${OLIGO_LENGTH}     \
  -s ${SPACING_FACTOR}   \
  --ccds-only 

fi 


if [[ ${INPUT_FASTA} != "" ]]; then

 prbReadInputFasta       \
  -i ${INPUT_FASTA}      \
  -g ${GENOME}           \
  -w ${WORKDIR}          \
  -l ${OLIGO_LENGTH}     \
  -s ${SPACING_FACTOR}

fi


if [[ ${INPUT_FASTA} != "" ]]; then

 prbReadInputBed         \
  -i ${INPUT_BED}        \
  -g ${GENOME}           \
  -w ${WORKDIR}          \
  -l ${OLIGO_LENGTH}     \
  -s ${SPACING_FACTOR}

fi



### ----------------------------------------------------------------------------------
### 3. Adding References -------------------------------------------------------------
### ----------------------------------------------------------------------------------

### Creating genome and blacklist reference and temporary objects.
### Finally, link all reference objects to each sub-directory

prbReferenceCreate -w ${WORKDIR} -g ${GENOME} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}



### ----------------------------------------------------------------------------------
### 4. Launching Pipeline ------------------------------------------------------------
### ----------------------------------------------------------------------------------




### Launching prbRun_nHUSH
CPU_PER_JOB=10 ; MEM_PER_JOB="40G" ; TIME_PER_JOB="05:00:00"

slurmArrayLauncher \
 --command-name "prbRun_nHUSH"    \
 --command-args "-c ${CPU_PER_JOB} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}" \
 --cpu-per-job "${CPU_PER_JOB}" \
 --mem-per-job "${MEM_PER_JOB}" \
 --time-req "${TIME_PER_JOB}" \
 --work-dir ${WORKDIR} \
 --parallel-jobs 20 \
 --slurm-array-max 900 \
 --slurm-hpc-max 950

### Waiting for prbRun_nHUSH jobs to finish
slurmBlocker --job-name "prbRun_nHUSH" -s 60



### Launching prbRun_cQuery
CPU_PER_JOB=10 ; MEM_PER_JOB="40G" ; TIME_PER_JOB="10:00:00"

slurmArrayLauncher \
 --command-name "prbRun_cQuery" \
 --command-args "-c ${CPU_PER_JOB} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}" \
 --cpu-per-job "${CPU_PER_JOB}" \
 --mem-per-job "${MEM_PER_JOB}" \
 --time-req "${TIME_PER_JOB}" \
 --work-dir ${WORKDIR} \
 --parallel-jobs 20 \
 --slurm-array-max 935 \
 --slurm-hpc-max 950





        ### In case nHUSH crashed and cQuery started, you might want to run:

        # rm -rf ${WORKDIR}/split/regions/*/data/db
        # rm -rf ${WORKDIR}split/regions/*/data/db_tsv
        # rm -rf ${WORKDIR}split/regions/*/data/HUSH_c*
        # rm -rf ${WORKDIR}split/regions/*/data/melt
        # rm -rf ${WORKDIR}split/regions/*/data/secs
        # rm -rf ${WORKDIR}split/regions/*/data/probe_candidates
        # rm -rf ${WORKDIR}split/regions/*/data/logfiles
        # rm -rf ${WORKDIR}split/regions/*/data/selected_probes
        # rm -rf ${WORKDIR}split/regions/*/data/final_probes