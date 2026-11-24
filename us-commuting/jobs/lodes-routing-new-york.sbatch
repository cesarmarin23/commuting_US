#!/bin/bash
#SBATCH --job-name=lodes-routing-new-york
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=05:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=192G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.3 in place with the python-geo kernel: sums the kept block flows
# of 05.2 to tract pairs, places one routing point per tract, downloads the
# Geofabrik US Northeast extract into /scratch/project_2010423/data/osm if
# missing and builds the cafein street network of the area (saved in
# networks/).
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/lodes-routing-new-york.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/us-commuting/cities/new-york

notebook=05.3-lodes-routing-new-york.ipynb
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
