# Sanity check: how often is transit as fast as the car, and what are the implied speeds? Reads only the columns needed.
import sys
from pathlib import Path
import numpy as np, pandas as pd

RESULTS = Path("/scratch/project_2010423/carbon-advantage/commuting")
RUN_TAG = sys.argv[1] if len(sys.argv) > 1 else "us-v4-agency"   # the run whose commute tables are checked


def quantiles(values, weights, probs=(0.1, 0.5, 0.9)):
    order = np.argsort(values.to_numpy())
    cumulative = np.cumsum(weights.to_numpy()[order]) / weights.sum()
    return [values.to_numpy()[order][np.searchsorted(cumulative, p)] for p in probs]


for area in ["new-york", "houston"]:
    long = pd.read_parquet(RESULTS / area / f"commute-emissions-{RUN_TAG}-2023.parquet", columns=["from_id", "to_id", "workers", "mode", "minutes", "km"])
    long = long[long["mode"].isin(["car", "transit"])]
    wide = long.pivot(index=["from_id", "to_id", "workers"], columns="mode", values=["minutes", "km"]).reset_index()
    wide.columns = ["from_id", "to_id", "workers"] + [f"{v}_{m}" for v, m in wide.columns[3:]]
    both = wide.dropna(subset=["minutes_car", "minutes_transit"])
    wt = both["workers"]
    print(f"\n=== {area}: {len(wide):,} flows, {wt.sum():,.0f} workers with both car and transit ({wt.sum() / wide['workers'].sum():.1%})")
    extra = both["minutes_transit"] - both["minutes_car"]
    for lim in [-10, -5, 0, 5, 10, 15, 30]:
        print(f"  transit minus car <= {lim:+d} min: {wt[extra <= lim].sum() / wt.sum():.1%} of workers")
    print("  car minutes p10/p50/p90:", np.round(quantiles(both["minutes_car"], wt), 1))
    print("  transit minutes p10/p50/p90:", np.round(quantiles(both["minutes_transit"], wt), 1))
    print("  car km p10/p50/p90:", np.round(quantiles(both["km_car"], wt), 1))
    print("  car implied km/h p10/p50/p90:", np.round(quantiles(both["km_car"] / both["minutes_car"] * 60, wt), 1))
    print("  transit implied km/h over its own route km p10/p50/p90:", np.round(quantiles(both["km_transit"] / both["minutes_transit"] * 60, wt), 1))
    for lo, hi in [(0, 3), (3, 8), (8, 15), (15, 30), (30, 1e9)]:
        band = both[(both["km_car"] > lo) & (both["km_car"] <= hi)]
        wb = band["workers"]
        as_fast = wb[band["minutes_transit"] <= band["minutes_car"]].sum() / wb.sum()
        within15 = wb[band["minutes_transit"] <= band["minutes_car"] + 15].sum() / wb.sum()
        print(f"  car km in ({lo}, {hi}]: {wb.sum() / wt.sum():5.1%} of workers; transit as fast as car {as_fast:5.1%}, within +15 {within15:5.1%}; "
              f"median car min {quantiles(band['minutes_car'], wb)[1]:.0f}, transit min {quantiles(band['minutes_transit'], wb)[1]:.0f}")
    fast = both[extra <= 0]
    print(f"  where transit is as fast: {fast['workers'].sum():,.0f} workers; the five largest destination tracts:")
    print(fast.groupby("to_id")["workers"].sum().sort_values(ascending=False).head(5).to_string())
