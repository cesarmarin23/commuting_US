#!/bin/bash
#SBATCH --job-name=lodes-time-vs-emissions
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.11 in place with the python-geo kernel: the time-against-emissions
# analysis of the New York and Houston commutes from the commute tables of 05.10
# (run us-v4-centre): density of minutes by grams per mode, the time price of
# leaving the car, the frontier against the car and the fleet emissions it avoids,
# and three pairs of tract maps. Figures go to figures/, tract layers to scratch.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/lodes-time-vs-emissions.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

cd /projappl/project_2010423/cafein/us-commuting

notebook=05.11-lodes-time-vs-emissions.ipynb
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
