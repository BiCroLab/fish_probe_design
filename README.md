# FISH Probe Design Pipelines + SLURM parallelization


## Introduction:

Pipeline to design one FISH probeset for each provided input. Three input types are allowed:

<br>

1. Gene annotations in *gtf* / *gtf.gz* format
2. Genomic regions in *bed* / *bed.gz* format
3. Nucleotide sequences in *fasta* / *fasta.gz* format

<br>

The **GTF-based workflow** takes a GTF annotation file to retrieve coordinates and nucleotide sequences of each gene, transcript and exon. In this workflow, all exons belonging to the same transcript isoform are merged together (intronic regions are dropped) to form one concatenated sequence featuring exon-exon junctions, which is used to design a certain number of kmer oligos to be used in RNA FISH experiments.

The **BED-based workflow** can be used to test entire ungapped regions based on their coordinates. The **FASTA-based workflow** can be used to test nucleotide sequences, being therefore useful in situations where coordinates or identifiers are not available.

<br><br>


## Installation:

Based on `/group/bienko/containers/prb.sif` image and **SLURM** to launch sbatch scripts.<br>
Steps require `module load singularity`, `module load bedtools`,  `module load samtools`.



<br><br>


## Inputs / Parameters Tuning

The pipeline consists of a [`main.sh`](./prb_pipeline/main.sh) script that manages a series of *modules*.<br>
All variables can be controlled and edited from a `prb.config` text file: <br><br>

- `${INPUT_GTF}` annotation file in `.gtf` / `.gtf.gz` format.
- `${INPUT_FASTA}` annotation file in `.fasta` / `.fasta.gz` format.
- `${INPUT_BED}` annotation file in `.bed` / `.bed.gz` format.
  <br><br>
- `${GENOME}` path to genome `.fa` / `.fa.gz` having `.fai` / `.gzi` index.
- `${BASEDIR}` / `${WORKDIR}` base path and output directory name.
  <br><br>
- `${OLIGO_LENGTH}` length of probe oligos (default is 40).
- `${OLIGO_SUBLENGTH}` sublength of probe oligos (default is 21).
- `${SPACER}` value affecting average oligo density (default is 10bp). <br><br>

For each input, ***N*** represents the maximum number of oligos to be found and it corresponds to `${WIDTH} / (${OLIGO_LENGTH} + ${SPACER})`. If ***N*** suitable candidates are not found, the pipeline will reduce ***N*** and retry. For example: `5000bp region` / (`40bp oligos` + `10bp spacer`) could yield up to a maximum of 100 oligos.


<br><br>

---

## Usage:

1. Either download or clone the entire github repository
2. Define user-specific variables in `prb.config`
3. Launch the whole pipeline ➤ ```bash main.sh```<br>

<br><br>

## Outputs:

For every input, one `final_probes` directory can be located as depicted below:

`${WORKDIR}`    
┣╍╍╍╍  data       
┃   ┣╍╍╍╍ blacklist       
┃   ┣╍╍╍╍ ref   
┣╍╍╍╍ split       
┃   ┃   ┣╍╍╍╍ `gene` / `regions` / `fasta`         
┃   ┃   ┃   ┣╍╍╍╍ ***input1***         
┃   ┃   ┃   ┃   ┣╍╍╍╍ data         
┃   ┃   ┃   ┃   ┃   ┣╍╍╍╍ `final_probes`         
┃   ┃   ┃   ┃   ┃   ┣╍╍╍╍ `regions`         
┃   ┃   ┃   ┃   ┃   ┣╍╍╍╍ `rois`     
┃   ┃   ┃   ┃   ┃   ┣╍╍╍╍ `visual_summary`    
┃   ┃   ┃   ┣╍╍╍╍ ***input2***         
┃   ┃   ┃   ┣╍╍╍╍ ***input3***          
┃   ┃   ┃   ┣╍╍╍╍ etc...     

<br> 

In every `final_probes` directory, users will find an output `.tsv` that lists the final set of oligonucleotides. The filename also includes a ***pw*** score value and the ***number of found oligos***, which must be equal or inferior to ***N*** = `${WIDTH} / ( ${OLIGO_LENGTH} + ${SPACING_FACTOR } )`. Depending on the input, users might want to double-check whether the number of found oligos dropped significantly with respect to the original ***N*** and control if oligos were evenly distributed throughout the sequence or if they tend to form local clusters. To some extent, the ***pw*** score indicates the overall quality of the entire probeset and, if possible, users should avoid ⁻¹ / ⁻² values. <br><b>
All `visual_summary` directories include a few reports that indicate average oligo distance and quality.
 < work in progress > 


<br>


<br>


#### Required Resources / Speed :

Some steps consume around **40GB RAM** when using human genome assemblies, but this value might be lower when using smaller genomes. There are few potential bottlenecks when running [`prbRun_nHUSH`](./prb_pipeline/modules/prbRun_nHUSH.sh) and [`prbRun_cQuery`](./prb_pipeline/modules/prbRun_cQuery.sh). Overall, 

- [`main`](./prb_pipeline/main.sh) runtime might require tuning when supplying many inputs.
- [`prbReadInput`](./prb_pipeline/modules/prbReadInputGTF.sh) functions should be quick, unless several inputs are provided.
- [`prbReferenceCreate.sh`](./prb_pipeline/modules/prbReferenceCreate.sh) ~ 1-2 hours with 10 CPU / 40GB (only once).
- [`prbRun_nHUSH`](./prb_pipeline/modules/prbRun_nHUSH.sh) ~ 1-2 hours with 10 CPU / 40GB (for each input).
- [`prbRun_cQuery`](./prb_pipeline/modules/prbRun_cQuery.sh) ~ 1-4 hours with 10 CPU / 40GB (for each input).


---

#### Advanced SLURM settings

All "*prbRun*" steps are controlled by the `slurmArrayLauncher` module, that can be further customized as described below. Users can modify these settings in the `"./modules/prbMain.sh"` script. In short, `--parallel-jobs`, `--slurm-array-max`, `--slurm-hpc-max` can be used to tune SLURM parallelization. Typically, SLURM does not allow users to submit an infinite number of jobs in the HPC, but there is a default HPC limit. To avoid potential crashes, `--slurm-hpc-max` controls the maximum number of either running / queued jobs in the HPC. New jobs are submitted in batches of `--slurm-array-max`, but only if the total number of jobs would not exceed `--slurm-hpc-max`. Finally, to limit resource overconsumption, only `--parallel-jobs` per array are allowed to run simultaneously. These three parameters can be combined depending on the available HPC resources and individual needs.

 | *slurmArrayLauncher* | Description |
 | --------------------------  | ----------- |
 | `--command-name` | "*prbRun*" command ( either *prbRun_nHUSH* / *prbRun_cQuery* ) | 
 | `--command-args` | command-specific arguments of the supplied function | 
 | `--parallel-jobs` | maximum number of jobs allowed to run in parallel in each slurm array (default: 30) |
 | `--slurm-array-max` | maximum number of inputs that can fit in each slurm array (default: 200) | 
 | `--slurm-hpc-max` | maximum number of array jobs that can exist in the whole HPC (default: 800) |
 | `--cpu-per-job` | cpu requested for each slurm array (default:  5CPU) |
 | `--mem-per-job` | memory requested for each slurm array (default: 40GB) |
 | `--time-req`  | run time requested for each slurm array (default: 24h) |
 | `--work-dir` | path to the working directory where the specified "*prbRun*" command will run | 
            

<br><br><br>





