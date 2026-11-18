#!/bin/bash
#SBATCH --job-name=commuting-cities
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=00:20:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 04.1 (WorldCommuting-OD overview of the six validated cities) in place
# with the python-geo kernel. Light work: six small shapefiles and matrices, maps.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch jobs/commuting-validated-cities.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein

notebook=04.1-commuting-validated-cities-overview.ipynb
echo "=== $(date '+%F %T') ${notebook}"
jupyter nbconvert \
    --to notebook \
    --execute \
    --inplace \
    --ExecutePreprocessor.kernel_name=python-geo \
    --ExecutePreprocessor.timeout=-1 \
    "${notebook}"
echo "=== $(date '+%F %T') done"
