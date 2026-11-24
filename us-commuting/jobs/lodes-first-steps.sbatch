#!/bin/bash
#SBATCH --job-name=lodes-first-steps
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=00:40:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.1 in place with the python-geo kernel: downloads the 2023 LODES
# origin-destination files and block crosswalks for New York State and Texas
# into /scratch/project_2010423/data/lodes and reads their counts and units.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/lodes-first-steps.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

cd /projappl/project_2010423/cafein/us-commuting

notebook=05.1-lodes-first-steps.ipynb
echo "=== $(date '+%F %T') ${notebook}"
jupyter nbconvert \
    --to notebook \
    --execute \
    --inplace \
    --ExecutePreprocessor.kernel_name=python-geo \
    --ExecutePreprocessor.timeout=-1 \
    --allow-errors \
    "${notebook}"
echo "=== $(date '+%F %T') done"
