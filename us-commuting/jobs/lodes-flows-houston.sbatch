#!/bin/bash
#SBATCH --job-name=lodes-flows-houston
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.2.1 in place with the python-geo kernel: reads the Houston
# metropolitan flow table of 05.1, downloads the TIGER block and tract
# boundaries of TX into /scratch/project_2010423/data/tiger and
# measures the units.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/lodes-flows-houston.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

cd /projappl/project_2010423/cafein/us-commuting/cities/houston

notebook=05.2.1-lodes-flows-houston.ipynb
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
