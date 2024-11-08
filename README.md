# FISH Probe Design Pipelines + SLURM parallelization

<br><br>

### 1. GENE-ID Workflow

Pipeline to design one RNA FISH probeset for any transcript isoform of the specified input gene. This pipeline uses <ins>ENSEMBL gene identifiers</ins> to retrieve coordinates and nucleotide sequences of each exon. All exons belonging to the same transcript isoform get merged together to form one concatenated sequence, which is then used to identify a certain number of kmer oligos to be used in RNA FISH. Since many transcript isoforms differ for relatively short sequences, we advise against using the resulting oligos to selectively target a specific isoform. Instead, pooling together results obtained from all isoforms of the same gene would allow to target any possibly expressed transcript of the gene of interest.

<br>

### 2. Sequence-guided Workflow

This second workflow can be used to design one RNA FISH probeset for each input sequence, in FASTA format, and should be used whenever gene identifiers and exact coordinates are not available. (((<ins>work in progress</ins>)))




<br><br><br><br><br><br><br><br>

---- 
### Standardard Workflow

<br>


#### Installation:

Currently based on `/group/bienko/containers/prb.sif` singularity image.<br>
(((<ins>work in progress</ins>))) To recreate it, see: [prb_docker](./prb_docker)

<br>


#### Usage:

The pipeline consists of a [`main.sh`](./pipeline_geneid/modules/txt) script that manages a series of modules. <br>
The following bash variables must be adjusted manually:

 | Variable | Description | 
 | -------- | ----------- | 
 | **GENE_ID_LIST** | <br>File containing one gene per row, using ENSEMBL gene identifiers.<br><br> |
 | **ANNOT_INPUT** | <br>Path to custom gene annotation `.gtf` / `.gtf.gz`<br><br> |
 | **GENOME**      | <br>Path to genome annotation `.fa` / `.fa.gz`<br>Index `.fai` / `.gzi` files must also exist.<br><br> |
 | **WORKDIR** | <br>Path to working / output directory<br><br> | 
 | **PIPELINE_MODS** | <br>Path to folder with modules<br><br> | 

(((<ins>work in progress</ins>)))
<br>



#### Inputs:

<br>



#### Outputs:


<br>




#### Required Resources / Speed :




