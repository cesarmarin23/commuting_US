#!/bin/bash
#SBATCH --job-name=cafein-smoke
#SBATCH --account=project_2010423
#SBATCH --partition=test
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Runs jobs/cafein-smoke-test.py with the python-geo module and the cafein
# 0.31.0 user-site install, before the full pipeline rebuild.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch jobs/cafein-smoke-test.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein
python jobs/cafein-smoke-test.py
