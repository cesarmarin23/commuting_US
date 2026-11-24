#!/bin/bash
#SBATCH --job-name=london-travelwhiz
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=01:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 04.2.1 in place with the python-geo kernel: builds the cafein transit
# network of London from the TravelWhiz GTFS feeds (saved as
# networks/london-transit-travelwhiz.cafein), routes the test trips and the full matrices,
# and compares the transit times with those of 04.2.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch exploratory/jobs/london-routing-travelwhiz.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/exploratory

notebook=04.2.1-london-routing-travelwhiz.ipynb
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
