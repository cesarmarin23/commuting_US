# Which share of commuters work in a tract above a job-density threshold, per metro: the basis for the parking rule.
from pathlib import Path
import geopandas as gpd, numpy as np, pandas as pd

RESULTS = Path("/scratch/project_2010423/carbon-advantage/commuting")
YEAR = 2023
AREAS = {"new-york": "EPSG:32618", "houston": "EPSG:32615"}
THRESHOLDS = [1000, 2000, 5000, 10000, 20000, 50000]   # jobs per km2 of the work tract

for area, utm in AREAS.items():
    flows = pd.read_parquet(RESULTS / area / f"tract-od-{YEAR}.parquet", columns=["to_id", "workers"])
    jobs = flows.groupby(flows["to_id"].astype(str))["workers"].sum().rename("jobs")
    tracts = gpd.read_parquet(RESULTS / area / f"tracts-kept-{YEAR}.parquet")[["tract", "geometry"]].to_crs(utm)
    tracts["tract"] = tracts["tract"].astype(str)
    tracts["km2"] = tracts.geometry.area / 1e6
    tracts = tracts.merge(jobs, left_on="tract", right_index=True, how="left").fillna({"jobs": 0})
    tracts["density"] = tracts["jobs"] / tracts["km2"]
    total = tracts["jobs"].sum()
    print(f"\n=== {area}: {len(tracts):,} work tracts, {total:,.0f} jobs; job density p50/p90/p99 = "
          f"{tracts['density'].quantile(0.5):,.0f} / {tracts['density'].quantile(0.9):,.0f} / {tracts['density'].quantile(0.99):,.0f} jobs per km2")
    for t in THRESHOLDS:
        above = tracts["density"] >= t
        print(f"  >= {t:>6,} jobs/km2: {above.sum():5,} tracts, {tracts.loc[above, 'km2'].sum():7,.0f} km2, {tracts.loc[above, 'jobs'].sum() / total:5.1%} of jobs")
    dense = tracts.sort_values("density", ascending=False).head(8)
    print("  the densest tracts:", ", ".join(f"{r.tract} ({r.density:,.0f}/km2, {r.jobs:,.0f} jobs)" for r in dense.itertuples()))
