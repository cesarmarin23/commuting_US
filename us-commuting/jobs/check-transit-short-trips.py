# Why transit so rarely matches the car: walk-only itineraries, same-tract flows, Manhattan-bound flows, and the walking mode.
import sys
from pathlib import Path
import numpy as np, pandas as pd

RESULTS = Path("/scratch/project_2010423/carbon-advantage/commuting")
RUN_TAG = sys.argv[1] if len(sys.argv) > 1 else "us-v4-congestion"
WALK_G_PER_KM = 56.0


def wshare(mask, weights):
    return weights[mask].sum() / weights.sum()


def wmedian(values, weights):
    values, weights = np.asarray(values, float), np.asarray(weights, float)
    keep = ~np.isnan(values)
    order = np.argsort(values[keep])
    cumulative = np.cumsum(weights[keep][order]) / weights[keep].sum()
    return values[keep][order][np.searchsorted(cumulative, 0.5)]


for area in ["new-york", "houston"]:
    long = pd.read_parquet(RESULTS / area / f"commute-emissions-{RUN_TAG}-2023.parquet", columns=["from_id", "to_id", "workers", "mode", "minutes", "km", "grams"])
    wide = long.pivot(index=["from_id", "to_id", "workers"], columns="mode", values=["minutes", "km", "grams"]).reset_index()
    wide.columns = ["from_id", "to_id", "workers"] + [f"{v}_{m}" for v, m in wide.columns[3:]]
    drivers = wide[wide["minutes_car"].notna()].copy()
    wt = drivers["workers"].to_numpy(float)
    has_transit = drivers["minutes_transit"].notna().to_numpy()
    walk_only = has_transit & np.isclose((drivers["grams_transit"] / drivers["km_transit"]).to_numpy(), WALK_G_PER_KM, atol=0.5)
    same_tract = (drivers["from_id"] == drivers["to_id"]).to_numpy()
    transit_fast = has_transit & (drivers["minutes_transit"] <= drivers["minutes_car"]).to_numpy()
    walk_fast = drivers["minutes_walk"].notna().to_numpy() & (drivers["minutes_walk"] <= drivers["minutes_car"]).to_numpy()
    print(f"\n=== {area}: {wt.sum():,.0f} drivers")
    print(f"  with a transit itinerary {wshare(has_transit, wt):.1%}; of which walk-only (no vehicle ridden) {wt[walk_only].sum() / wt[has_transit].sum():.1%}")
    print(f"  same-tract flows {wshare(same_tract, wt):.1%} of drivers; their median car min {wmedian(drivers.loc[same_tract, 'minutes_car'], wt[same_tract]):.0f}, transit {wmedian(drivers.loc[same_tract, 'minutes_transit'], wt[same_tract]):.0f}, walk {wmedian(drivers.loc[same_tract, 'minutes_walk'], wt[same_tract]):.0f}")
    print(f"  transit as fast as the car: {wshare(transit_fast, wt):.1%} of drivers; excluding walk-only itineraries {wshare(transit_fast & ~walk_only, wt):.1%}; among same-tract flows {wt[transit_fast & same_tract].sum() / max(wt[same_tract].sum(), 1):.1%}")
    print(f"  walking as fast as the car: {wshare(walk_fast, wt):.1%} of drivers; walking or transit as fast: {wshare(transit_fast | walk_fast, wt):.1%}")
    for label, mask in [("car under 2 km", (drivers["km_car"] <= 2).to_numpy()), ("car 2 to 5 km", ((drivers["km_car"] > 2) & (drivers["km_car"] <= 5)).to_numpy())]:
        print(f"  {label}: {wshare(mask, wt):.1%} of drivers; median car {wmedian(drivers.loc[mask, 'minutes_car'], wt[mask]):.0f} min, transit {wmedian(drivers.loc[mask, 'minutes_transit'], wt[mask]):.0f}, walk {wmedian(drivers.loc[mask, 'minutes_walk'], wt[mask]):.0f}, e-bike {wmedian(drivers.loc[mask, 'minutes_e_bike'], wt[mask]):.0f}")
    if area == "new-york":
        manhattan = drivers["to_id"].str.startswith("36061").to_numpy()
        from_manhattan = drivers["from_id"].str.startswith("36061").to_numpy()
        for label, mask in [("to Manhattan", manhattan), ("within Manhattan", manhattan & from_manhattan), ("to Manhattan from outside", manhattan & ~from_manhattan)]:
            sub = drivers.loc[mask]; ws = wt[mask]
            print(f"  {label}: {wshare(mask, wt):.1%} of drivers; median car {wmedian(sub['minutes_car'], ws):.0f} min ({wmedian(sub['km_car'], ws):.1f} km), transit {wmedian(sub['minutes_transit'], ws):.0f} min; "
                  f"transit as fast as the car {wshare(transit_fast[mask], ws):.1%}, within +15 {wshare((has_transit & (drivers['minutes_transit'] <= drivers['minutes_car'] + 15).to_numpy())[mask], ws):.1%}")
