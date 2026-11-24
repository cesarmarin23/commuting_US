#!/bin/bash
#SBATCH --job-name=lodes-commute-emissions-us-factors
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=02:30:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Executes 05.10 in place with the python-geo kernel: routes the LODES commuting
# flows of New York and Houston from the home points to the work points of 05.7
# by transit, car, bicycle, e-bike and on foot with life-cycle emissions attached
# at the US-specific factors of factors/us-v4/ (NTD 2024 transit rows per metro
# and route type, Argonne GREET petrol car at occupancy 1.19, BEV at the metro's
# eGRID subregion), transit routed as the median over a 30-minute departure
# window, the car at cafein's midday-profile time plus the Urban Mobility Report
# congestion index on the link time of the share of the trip inside the main urban area, plus a
# 3-minute parking search where the work tract is an employment centre (run tag us-v4-centre), and
# writes the commute table per area beside the Finnish-factor table of 05.9.
# Transit factors resolve agency rows first (GTFS agency crosswalk in step 3),
# then metro rows by route type, then the US rows; the street matrices of the
# earlier us-v4 run are reused for the bicycle, the e-bike and walking.
# The previous run of 05.9 took 9.5 min on 16 cores with a 15 GiB peak.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch us-commuting/jobs/lodes-commute-emissions-us-factors.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/us-commuting

notebook=05.10-lodes-commute-emissions-us-factors.ipynb
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
