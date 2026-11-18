#!/bin/bash
#SBATCH --job-name=hki-decent-week
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 02.6-helsinki-decent-week-by-postal-code.ipynb in place: the decent
# week per postal code from the per-user table of 02.5. Light job: one Parquet
# table of a few million rows, pandas aggregation and matplotlib maps.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch jobs/helsinki-decent-week.sbatch

set -euo pipefail

source ~/.venvs/HPC-env/bin/activate
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

cd /projappl/project_2010423/cafein

jupyter nbconvert \
    --to notebook \
    --execute \
    --inplace \
    --ExecutePreprocessor.kernel_name=hpc-env \
    --ExecutePreprocessor.timeout=-1 \
    02.6-helsinki-decent-week-by-postal-code.ipynb
echo "=== $(date '+%F %T') done"
