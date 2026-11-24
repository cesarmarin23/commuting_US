#!/bin/bash
#SBATCH --job-name=lodes-routing-points
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=02:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=192G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.7 in place with the python-geo kernel: reads the 2020 Census
# block counts from the TIGER/Line block files (downloaded once to scratch), builds the housing-
# weighted home point and the jobs-weighted work point of every kept tract of
# New York and Houston, compares them with the points of 05.3, and snaps both
# onto the street networks saved by 05.3 and 05.3.1 (the New York network is
# large: 16 cores and 192 GB as in jobs/lodes-routing-new-york.sbatch), then
# routes transit from home points to work points and compares with 05.3.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/lodes-routing-points.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/us-commuting

notebook=05.7-lodes-routing-points.ipynb
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
