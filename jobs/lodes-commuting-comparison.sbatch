#!/bin/bash
#SBATCH --job-name=lodes-commuting-comparison
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.4 in place with the python-geo kernel: reads the OD tables of
# 05.3 (New York) and 05.3.1 (Houston) from scratch, compares the modes and
# draws one median-commute map per area (saved as HTML in figures/).
#
# Submit from roihu-cpu.csc.fi:
#   sbatch jobs/lodes-commuting-comparison.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein

notebook=05.4-lodes-commuting-comparison.ipynb
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
