## Extra Slurm Settings

All "*prbRun*" steps are controlled by the `slurmArrayLauncher` module, that can be further customized as described below. Users that have access to powerful HPC might want to modify these settings in the `"./modules/prbMain.sh"` script. In short, `--parallel-jobs`, `--slurm-array-max`, `--slurm-hpc-max` can be used to tune SLURM parallelization. Typically, SLURM does not allow users to submit an infinite number of jobs in the HPC, but there is a default HPC limit. To avoid potential crashes, `--slurm-hpc-max` controls the maximum number of either running / queued jobs in the HPC. New jobs are submitted in batches of `--slurm-array-max`, but only if the total number of jobs would not exceed `--slurm-hpc-max`. Finally, to limit resource overconsumption, only `--parallel-jobs` per array are allowed to run simultaneously. These three parameters can be combined depending on the available HPC resources and individual needs.

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


## Performance and Speed

Some steps consume around **40GB RAM** when using human genome assemblies, but this value might be lower when using smaller genomes. Pipeline duration depends on the total number and type of provided inputs. Using **10 CPU**, **40GM RAM** and 100KB region, every input might take between 1-3 hours to be fully processed with [`prbRun_nHUSH`](./prb_pipeline/modules/prbRun_nHUSH.sh) and [`prbRun_cQuery`](./prb_pipeline/modules/prbRun_cQuery.sh). Highly problematic regions might require more time and yield suboptimal results. 
