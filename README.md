# FISH Probe Design Pipelines + SLURM parallelization

<br><br>

Pipeline to design one FISH probeset for each provided input. Three input types are allowed:

<br>

1. Gene annotations in *gtf* / *gtf.gz* format
2. Genomic regions in *bed* / *bed.gz* format
3. Nucleotide sequences in *fasta* / *fasta.gz* format


<br><br>
The **GTF-based workflow** takes a GTF annotation file to retrieve coordinates and nucleotide sequences of each gene, transcript and exon. In this workflow, all exons belonging to the same transcript isoform are merged together (intronic regions are dropped) to form one concatenated sequence featuring exon-exon junctions, which is used to design a certain number of kmer oligos to be used in RNA FISH experiments.

The **BED-based workflow** can be used to test entire ungapped regions based on their coordinates. The **FASTA-based workflow** can be used to test nucleotide sequences, being therefore useful in situations where coordinates or identifiers are not available.

---- 


#### Inputs / Parameters Tuning

The pipeline consists of a [`main.sh`](./pipeline_geneid/modules/main.sh) script that manages a series of *modules*. Input variables are explained below and should be manually adjusted by users according to their needs. The whole workflow can be launched using:
         
    sbatch main.sh

<br>

> General Variables 
- `${WORKDIR}` path to any working directory
- `${GENOME}` path to genome annotation in `.fa` / `.fa.gz` format. and having `.fai` / `.gzi` index files.
- `${OLIGO_LENGTH}` length of probe oligos (default is 40).
- `${OLIGO_SUBLENGTH}` sublength of probe oligos (default is 21).

<br>

 | Module | Input | Arguments |
 | -------- | ----------- | ----------- | 
 | prbReadInputGTF |  `-i ${GTF}`  | `-g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH}` |
 | prbReadInputBed | `-i ${BED}` |  `-g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH}` |
 | prbReadInputFasta | `-i ${FASTA}` | `-g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH}` |
 | <br> | |
 | prbReferenceCreate | | `-g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}` |
 | <br> | |
 | prbRun_nHUSH | |  `-g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}` |
 | prbRun_cQuery | | `-g ${GENOME} -w ${WORKDIR} -l ${OLIGO_LENGTH} -s ${OLIGO_SUBLENGTH}` |

<br>

> Input Variables (at least one input must be provided)

- `${GTF}` path to gene annotation in `.gtf` / `.gtf.gz` format.
- `${BED}` path to bed annotation in `.bed` / `.bed.gz` format. 
- `${FASTA}` path to sequences in `.fasta` / `.fasta.gz` format.

<br>

---

<br>

All "*prbRun*" steps are controlled by the `slurmArrayLauncher` module, that can be customized as:

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
            
In short, `--parallel-jobs`, `--slurm-array-max`, `--slurm-hpc-max` can be used to tune SLURM parallelization. Typically, SLURM does not allow users to submit an infinite number of jobs in the HPC, but there is a default HPC limit. To avoid potential crashes, `--slurm-hpc-max` controls the maximum number of either running / queued jobs in the HPC. New jobs are submitted in batches of `--slurm-array-max`, but only if the total number of jobs would not exceed `--slurm-hpc-max`. Finally, to limit resource overconsumption, only `--parallel-jobs` per array are allowed to run simultaneously. These three parameters can be combined depending on the available HPC resources and individual needs.

<br><br><br>


#### Usage:


         

#### Outputs:


<br>


<br>


#### Installation:

Currently based on `/group/bienko/containers/prb.sif` singularity image.<br>
(((<ins>work in progress</ins>))) To recreate it, see: [prb_docker](./prb_docker)

<br>

#### Required Resources / Speed :



Few potential bottlenecks when running the [`nHUSH`](./pipeline_geneid/modules/txt) and [`cycling query`](./pipeline_geneid/modules/txt) steps. For each input isoform: 

- [`nHUSH`](./pipeline_geneid/modules/txt) ~1-2 hours with 5CPU / 35-40GB memory
- [`cycling query`](./pipeline_geneid/modules/txt) ~ ??? hours with ? CPU / ?-? GB memory (((<ins>work in progress</ins>))) 

All tests are related to the hg38 genome reference. Smaller genomes may result in lower memory usage and runtime.




blabla: other notes to be moved later on:
Since many transcript isoforms differ for relatively short sequences, we advise against using the resulting oligos to selectively target a specific isoform. Instead, pooling together results obtained from all isoforms of the same gene would allow to target any possibly expressed transcript of the gene of interest.


