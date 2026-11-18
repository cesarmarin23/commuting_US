#!/bin/bash
#SBATCH --job-name=london-routing
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=01:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 04.2 in place with the python-geo kernel: builds the cafein street
# network of Greater London from the Geofabrik extract (saved in
# networks/), builds the R5 network (cached next to the extract) and routes ten
# test trips with both tools. Java heap for R5 is set inside the notebook (24G).
#
# Submit from roihu-cpu.csc.fi:
#   sbatch jobs/london-routing-first-steps.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata
export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=${TMPDIR}"

cd /projappl/project_2010423/cafein

notebook=04.2-london-routing-first-steps.ipynb
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
