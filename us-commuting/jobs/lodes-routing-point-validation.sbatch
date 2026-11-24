#!/bin/bash
#SBATCH --job-name=lodes-routing-point-validation
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=01:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=192G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.8 in place with the python-geo kernel: compares the geometric
# centroid, the housing-weighted point of 05.7 and the housing medoid of every
# kept tract of New York and Houston, and routes the most split decile of
# tracts from each origin by transit and car (networks of 05.3 and 05.3.1).
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/lodes-routing-point-validation.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/us-commuting

notebook=05.8-lodes-routing-point-validation.ipynb
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
