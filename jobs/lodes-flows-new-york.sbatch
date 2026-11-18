#!/bin/bash
#SBATCH --job-name=lodes-flows-new-york
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=00:40:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.2 in place with the python-geo kernel: reads the New York
# metropolitan flow table of 05.1, downloads the TIGER block and tract
# boundaries of NY and NJ into /scratch/project_2010423/data/tiger and
# measures the units.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch jobs/lodes-flows-new-york.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

cd /projappl/project_2010423/cafein

notebook=05.2-lodes-flows-new-york.ipynb
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
