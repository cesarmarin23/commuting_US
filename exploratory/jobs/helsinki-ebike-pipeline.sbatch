#!/bin/bash
#SBATCH --job-name=hki-ebike
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=06:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=96G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes the Helsinki pipeline end to end with the e-bike added:
#   02.1 cost matrices (completed modes are skipped, the resident table is rebuilt),
#   02.3 amenity travel times (only the e-bike matrix is new),
#   02.4 value of carbon over all modes.
# The notebooks are executed in place so their outputs are refreshed.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch exploratory/jobs/helsinki-ebike-pipeline.sbatch

set -euo pipefail

source ~/.venvs/HPC-env/bin/activate
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/exploratory

for notebook in \
    02.1-helsinki-od-matrices.ipynb \
    02.3-helsinki-nearest-amenities.ipynb \
    02.4-helsinki-value-of-carbon.ipynb
do
    echo "=== $(date '+%F %T') ${notebook}"
    jupyter nbconvert \
        --to notebook \
        --execute \
        --inplace \
        --ExecutePreprocessor.kernel_name=hpc-env \
        --ExecutePreprocessor.timeout=-1 \
        "${notebook}"
done
echo "=== $(date '+%F %T') done"
