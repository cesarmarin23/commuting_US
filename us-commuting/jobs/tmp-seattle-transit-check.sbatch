#!/bin/bash
#SBATCH --job-name=tmp-seattle-transit-check
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Temporary diagnostic: executes tmp-seattle-transit-check.ipynb in place, reading the
# 05.3.3 artifacts on scratch (matrices, street and transit networks). Writes only
# figures/tmp-*.png beside the notebook and one parquet in the Seattle matrices folder.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/tmp-seattle-transit-check.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/us-commuting/cities/seattle

notebook=tmp-seattle-transit-check.ipynb
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
