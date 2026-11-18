#!/bin/bash
#SBATCH --job-name=hki-od-matrices
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=06:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=96G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 02.1-helsinki-od-matrices.ipynb end to end on a compute node.
# Every matrix streams to Parquet with resume=True, so a resubmission after
# a timeout continues where the previous run stopped.
#
# Submit from roihu-cpu.csc.fi:
#   mkdir -p /scratch/project_2010423/carbon-advantage/logs
#   sbatch jobs/helsinki-od-matrices.sbatch

set -euo pipefail

source ~/.venvs/HPC-env/bin/activate
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein

jupyter nbconvert \
    --to notebook \
    --execute \
    --ExecutePreprocessor.kernel_name=hpc-env \
    --ExecutePreprocessor.timeout=-1 \
    --output "02.1-helsinki-od-matrices.executed.ipynb" \
    "02.1-helsinki-od-matrices.ipynb"
