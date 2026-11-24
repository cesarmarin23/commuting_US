#!/bin/bash
#SBATCH --job-name=check-job-density
#SBATCH --account=project_2010423
#SBATCH --partition=test
#SBATCH --time=00:15:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --output=/scratch/project_2010423/carbon-advantage/logs/%x-%j.out
#SBATCH --error=/scratch/project_2010423/carbon-advantage/logs/%x-%j.err

# One-off check for 05.11: share of jobs in tracts above job-density thresholds, for the parking rule.
set -euo pipefail
module load python-geo/3.14.5
cd /projappl/project_2010423/cafein/us-commuting
python3 jobs/check-job-density.py
echo "=== done"
