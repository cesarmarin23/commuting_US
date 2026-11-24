#!/bin/bash
#SBATCH --job-name=hki-visitation
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=00:45:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=24G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 02.5 (per-user typical trips and postal-code summaries) and then 02.6
# (the decent week per postal code) in place with the python-geo kernel. Light
# work: Parquet filters of the paper's matrices, pandas aggregation, maps.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch exploratory/jobs/helsinki-visitation-decent-week.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/exploratory

for notebook in \
    02.5-helsinki-postal-code-visitation.ipynb \
    02.6-helsinki-decent-week-by-postal-code.ipynb
do
    echo "=== $(date '+%F %T') ${notebook}"
    jupyter nbconvert \
        --to notebook \
        --execute \
        --inplace \
        --ExecutePreprocessor.kernel_name=python-geo \
        --ExecutePreprocessor.timeout=-1 \
        "${notebook}"
done
echo "=== $(date '+%F %T') done"
