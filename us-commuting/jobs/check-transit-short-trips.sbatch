#!/bin/bash
#SBATCH --job-name=check-transit-short-trips
#SBATCH --account=project_2010423
#SBATCH --partition=test
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# One-off check for 05.11: walk-only transit itineraries, same-tract flows and Manhattan-bound flows.
set -euo pipefail
module load python-geo/3.14.5
cd /projappl/project_2010423/cafein/us-commuting
python3 jobs/check-transit-short-trips.py "${1:-us-v4-congestion}"
echo "=== done"
