# Worker-weighted mean and median one-way minutes per mode, all flows with an itinerary for that mode.
import sys
from pathlib import Path
import numpy as np, pandas as pd

RESULTS = Path("/scratch/project_2010423/carbon-advantage/commuting")
RUN_TAG = sys.argv[1] if len(sys.argv) > 1 else "us-v4-agency"   # the run whose commute tables are checked


def weighted_median(values, weights):
    order = np.argsort(values)
    cumulative = np.cumsum(weights[order]) / weights.sum()
    return values[order][np.searchsorted(cumulative, 0.5)]


rows = []
for area in ["new-york", "houston"]:
    long = pd.read_parquet(RESULTS / area / f"commute-emissions-{RUN_TAG}-2023.parquet", columns=["workers", "mode", "minutes", "km"])
    total = long.loc[long["mode"] == "car", "workers"].sum()
    for mode, sub in long.groupby("mode"):
        sub = sub.dropna(subset=["minutes"])
        wt = sub["workers"].to_numpy(dtype=float)
        minutes = sub["minutes"].to_numpy(dtype=float)
        rows.append({"area": area, "mode": mode, "workers with itinerary": int(wt.sum()), "share of car commuters": wt.sum() / total,
                     "mean min": np.average(minutes, weights=wt), "median min": weighted_median(minutes, wt),
                     "mean km": np.average(sub["km"].to_numpy(dtype=float), weights=wt),
                     "mean km/h": np.average(sub["km"].to_numpy(dtype=float) / minutes * 60, weights=wt)})
table = pd.DataFrame(rows).set_index(["area", "mode"])
pd.set_option("display.width", 200)
print(table.round(1).to_string())
