# FISH Probe Design Pipelines + SLURM parallelization

## Introduction:

Pipeline to design one FISH probeset for each provided input. Three input types are allowed:

<br>

1. Gene annotations in *gtf* / *gtf.gz* format
2. Genomic regions in *bed* / *bed.gz* format
3. Nucleotide sequences in *fasta* / *fasta.gz* format

<br>

The **GTF-based workflow** takes a GTF annotation file to retrieve coordinates and nucleotide sequences of each gene, transcript and exon. In this workflow, all exons belonging to the same transcript isoform are merged together (intronic regions are dropped) to form one concatenated sequence featuring exon-exon junctions, which is used to design a certain number of kmer oligos to be used in RNA FISH experiments. The **BED-based workflow** can be used to test entire ungapped regions based on their coordinates. The **FASTA-based workflow** can be used to test nucleotide sequences, being therefore useful in situations where coordinates or identifiers are not available.

<br>

## Installation:

**A Singularity Image can be provided on request.** Otherwise, the pipeline can be installed using this [`Dockerfile`](./installation/Dockerfile) to produce a Docker Container and convert it to Singularity Image. Follow the guide below to install everything. Both **Singularity** and **SLURM** are required to run the pipeline.<br><br>

1. Download Files: <br> `git clone https://github.com/BiCroLab/fish_probe_design.git`<br>`cd fish_probe_design/installation/`<br>`unzip prbdocker-master.zip && cd prbdocker-master` <br>

2. Create Docker Container: <br> `docker build -t prbdocker .` <br>
  
3. Convert Docker to Singularity: <br>
`docker run -v /var/run/docker.sock:/var/run/docker.sock -v ".":/output \` <br>
`--privileged -t --rm singularityware/docker2singularity:v2.6 prbdocker`
  <br>
  

## Usage:

1. First, `git clone https://github.com/BiCroLab/fish_probe_design.git`
2. Adjust all user-specific variables in _prb.config_
3. Launch the whole pipeline with ```bash main.sh```<br>

<br>


## Inputs / Parameters Tuning

The pipeline consists of a [`main.sh`](./prb_pipeline/main.sh) script that manages a series of *modules*.<br> All variables can be controlled and edited from a `prb.config` text file: <br><br>

- `${INPUT_GTF}` annotation file in `.gtf` / `.gtf.gz` format.
- `${INPUT_FASTA}` annotation file in `.fasta` / `.fasta.gz` format.
- `${INPUT_BED}` annotation file in `.bed` / `.bed.gz` format.
  <br><br>
- `${GENOME}` path to genome `.fa` / `.fa.gz` having `.fai` / `.gzi` index.<br>All chromosome names should start with the prefix _chr_ and have no additional spaces.<br>Required index files can be produced with `samtools faidx`.<br><br>
- `${BASEDIR}` / `${WORKDIR}` base path and output directory name. <br><br>
- `${OLIGO_LENGTH}` length of probe oligos (default is 40).
- `${OLIGO_SUBLENGTH}` sublength of probe oligos (default is 21).
- `${SPACER}` value affecting average oligo density (default is 10bp). <br><br>
  >   For each input, ***N*** represents the maximum number of oligos to be found. This number corresponds to `${WIDTH} / (${OLIGO_LENGTH} + ${SPACER})`. If ***N*** suitable candidates are not found, the pipeline will reduce ***N*** and retry. For example: `5000bp region` / (`40bp oligos` + `10bp spacer`) could yield up to a maximum of 100 oligos.

<br>

## Outputs / Results Selection:

##### Selecting Best Results 
All results will be saved in a single `${WORKDIR}/prb_results` directory, with one file _.tsv_ for each provided input. Output filenames also includes the final ***number of found oligos***, which is equal or inferior to the maximum ***N*** value. At this stage, users might want to double-check whether the number of found oligos dropped significantly with respect to the original ***N*** and control if oligos were evenly distributed throughout the sequence. The ***pw*** score indicates the overall quality of the entire probeset and, if possible, users should try to avoid very low values. However, when using very short regions as inputs, users might consistently get low values. In most situations, provided that there are enough oligos to get a detectable fluorescence signal, users might safely ignore this parameter. General suggestions: (1) try to squeeze as many oligos as possible in a region to get stronger signal; (2) avoid excessively gapped probesets, as they could form separate dots. <br><br>

##### Oligo-pools / Selecting Probes Amplification
Since most companies that synthesize oligos apply big discounts when ordering several sequences at once, it is recommended to group together multiple probesets in one or few oligo-pools. All oligos of a given probeset will be further modified to attach two flanking sequences, called flaps (see [figure](./prb_pipeline/docs/oligo_pic.png)), which can be used to bind fluorophores as well as to selectively amplify the whole probeset from a oligo-pool mixture. The used flaps sequences should not hybridize with the target genome to prevent off-targets and interferences. We provide a series of scripts that can be used to calculate orthogonal kmers for flaps. It is necessary to compute these sequences only once for each reference genome. Combining different left and right flaps sequences can theoretically allow a large number of combinations with a relatively low number of orthogonal sequences. Some pre-computed 20-mers are available for the human genome and can be provided on request.<br><br>

##### Preparing Final Results
This section explains how to integrate the previous information and prepare a final table that can be supplied to companies for oligo synthesis. A semi-manual approach is recommended here. Assuming that users are interested in visualizing several probes in the same experiment, while using a limited number of channels, they might want to consider what fluorescent color will be assigned to each probeset. In this situation, for probes of the same groups or conditions, it is advised to assign a common sequence for one of the two flap sequence. Although this is not fundamental, it can simplify and speed up pipetting for amplification, and also reduce the chances that wrong fluorophores could get attached to some oligos. This strategy can be ignored completely if users are interested in a relatively low number of regions and have an excess of orthogonal sequences to create unique combinations. We provide an example script that integrates flaps and oligo sequences and creates an output excel file that can be used for ordering probes.<br><br>


#### Advanced settings and information: 

Check [here](./prb_pipeline/docs/extra_slurm_settings.md) for further information. 

<br><br>
