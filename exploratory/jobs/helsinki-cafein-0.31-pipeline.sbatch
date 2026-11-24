#!/bin/bash
#SBATCH --job-name=hki-cafein031
#SBATCH --account=project_2010423
#SBATCH --partition=small
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# Rebuilds the Helsinki pipeline with cafein 0.31.0 (python-geo/3.14.5 module,
# cafein in the user site-packages), whose cycling profiles ride at 15.3 km/h
# (bicycle, slope-aware) and 17.4 km/h (e-bike, slope-neutral). Networks saved
# by earlier versions cannot be loaded, so the job:
#   0. moves the 0.25.0 network artifacts and every result derived from them
#      to /scratch/project_2010423/carbon-advantage/helsinki-cafein-0.25.0/
#      (the lattice, the POI layers and parameters.json stay in place),
#   1. runs 01.2 to rebuild helsinki-region.cafein,
#   2. runs 02.1 to rebuild helsinki-streets.cafein and the cost matrices,
#   3. runs 02.3 and 02.4 (amenity travel times, value of carbon),
#   4. runs 02.5 and 02.6 (visitation and decent week, bicycle at 15.3 km/h).
# Every notebook is executed in place with the python-geo kernel.
#
# Submit from roihu-cpu.csc.fi:
#   sbatch exploratory/jobs/helsinki-cafein-0.31-pipeline.sbatch

set -euo pipefail

module load python-geo/3.14.5
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
export CAFEIN_SAMPLEDATA_DIR=/scratch/project_2010423/cafein-sampledata

cd /projappl/project_2010423/cafein/exploratory

RESULTS=/scratch/project_2010423/carbon-advantage/helsinki
ARCHIVE=/scratch/project_2010423/carbon-advantage/helsinki-cafein-0.25.0

python -c "import cafein; assert cafein.__version__ == '0.31.0', cafein.__version__; print('cafein', cafein.__version__)"

if [[ ! -d "${ARCHIVE}" ]]; then
    echo "=== $(date '+%F %T') moving the cafein 0.25.0 artifacts and results to ${ARCHIVE}"
    mkdir -p "${ARCHIVE}/artifacts"
    for artifact in networks/helsinki-region.cafein networks/helsinki-streets.cafein; do
        if [[ -e "${artifact}" ]]; then mv "${artifact}" "${ARCHIVE}/artifacts/"; fi
    done
    for item in bicycle car e_bike walk transit transit-bus-bev amenities checks \
                visitation decent-week resident_table.parquet nearest_amenity.parquet \
                fifteen_minute_score.parquet reachable_amenities.parquet \
                nearest_parameters.json budget_by_level.parquet \
                02.4-helsinki-value-of-carbon-access30.ipynb \
                "${RESULTS}"/sacrifice-*.parquet "${RESULTS}"/choice_classes-*.parquet \
                "${RESULTS}"/value_parameters-*.json; do
        path="${item}"
        [[ "${path}" == /* ]] || path="${RESULTS}/${item}"
        if [[ -e "${path}" ]]; then mv "${path}" "${ARCHIVE}/"; fi
    done
    cp "${RESULTS}/parameters.json" "${ARCHIVE}/parameters.json"
    ls "${ARCHIVE}"
fi

for notebook in \
    01.2-network_build.ipynb \
    02.1-helsinki-od-matrices.ipynb \
    02.3-helsinki-nearest-amenities.ipynb \
    02.4-helsinki-value-of-carbon.ipynb \
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
