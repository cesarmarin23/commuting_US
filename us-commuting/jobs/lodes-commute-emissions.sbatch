#!/bin/bash
#SBATCH --job-name=lodes-commute-emissions
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=192G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.9 in place with the python-geo kernel: routes the LODES commuting
# flows of New York and Houston from the home points to the work points of 05.7
# by transit, car, bicycle, e-bike and on foot with life-cycle emissions attached
# (cafein's shipped factors, 30-minute access and egress walk), and writes the
# commute table per area.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/lodes-commute-emissions.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/us-commuting

notebook=05.9-lodes-commute-emissions.ipynb
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
