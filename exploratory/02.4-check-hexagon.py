"""Per-mode costs of reaching 20 % access from two central hexagons, and a map of the reached amenities."""
import json
import sys
from pathlib import Path

import geopandas as gpd
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from shapely.geometry import Point

from cafein._streaming import read_shards
from cafein.emissions import default_factors, vehicle_class_factors

RESULTS = Path("/scratch/project_2010423/carbon-advantage/helsinki")
OUT = Path(sys.argv[1])
LEVEL = 0.2
MAX_BUDGET = 60
PLACES = {"Kamppi": (24.9316, 60.1690), "Töölö": (24.9180, 60.1830)}

pd.set_option("display.width", 200)
print("=== default emission factors (g per passenger-km unless stated) ===")
print(default_factors())
print()
print("=== vehicle class factors ===")
print(vehicle_class_factors())
print()

lattice = gpd.read_file(RESULTS / "lattice.gpkg")
index = pd.Index(lattice["id"])
origins = {}
for name, (lon, lat) in PLACES.items():
    hit = lattice[lattice.contains(Point(lon, lat))]
    origins[name] = hit["id"].iloc[0]
    print(f"{name}: hexagon {origins[name]}, population {hit['population'].iloc[0]:.0f}")
ORIGINS = list(origins.values())

pois = gpd.read_file(RESULTS / "pois.gpkg")
pois["point_id"] = pois["osm_type"].str[0] + pois["osm_id"].astype(str)
points = pois.drop_duplicates("point_id")[["point_id", "geometry"]].reset_index(drop=True)
point_index = pd.Index(points["point_id"])
taxonomy = json.loads((RESULTS / "poi_taxonomy.json").read_text())["taxonomy"]
CATEGORIES = list(dict.fromkeys(rule["category"] for rule in taxonomy.values()))
one_hot = (
    pois.assign(one=1.0).pivot_table(index="point_id", columns="category", values="one", aggfunc="max", fill_value=0.0)
    .reindex(index=point_index, columns=CATEGORIES, fill_value=0.0)
)
ONE_HOT = one_hot.to_numpy(dtype=np.float32)
TOTALS = ONE_HOT.sum(axis=0)

hexagons = lattice[["id", "geometry"]]
inside = gpd.sjoin(points, hexagons, predicate="within", how="left")["id"]
nearest = gpd.sjoin_nearest(points.to_crs("EPSG:3067"), hexagons.to_crs("EPSG:3067"), how="left")["id"]
point_hexagon = inside.where(inside.notna(), nearest.groupby(level=0).first()).to_numpy()

MODES = ["walk", "bicycle", "transit", "car"]
times = {}
for mode in MODES:
    frame = read_shards(RESULTS / "amenities" / mode)
    frame = frame[frame["from_id"].isin(ORIGINS)]
    array = np.full((len(ORIGINS), len(point_index)), np.nan, dtype=np.float32)
    array[pd.Index(ORIGINS).get_indexer(frame["from_id"]), point_index.get_indexer(frame["to_id"])] = frame["travel_time"].to_numpy() / 60
    times[mode] = array

resident = pd.read_parquet(RESULTS / "resident_table.parquet")
resident = resident[resident["from_id"].isin(ORIGINS)]
walk = read_shards(RESULTS / "walk")
walk = walk[walk["from_id"].isin(ORIGINS)]
car_factor = vehicle_class_factors()[["vehicle", "fuel", "infrastructure", "operations"]].sum(axis=1)


def gather(frame, column, scale=1.0):
    table = frame.pivot_table(index="from_id", columns="to_id", values=column, aggfunc="first").reindex(index=ORIGINS, columns=index)
    return table.to_numpy(dtype=np.float32)[:, index.get_indexer(point_hexagon)] * scale


costs = {}
for label, mode in [("bicycle", "bicycle"), ("transit", "transit"), ("transit-bus-bev", "transit"), ("car-ICE", "car")]:
    part = resident[resident["mode"] == label.replace("car-ICE", "car")]
    costs[label] = {"time": times[mode], "money": gather(part, "money"), "co2": gather(part, "emissions_g"),
                    "distance_km": gather(part, "distance_m", 1 / 1000)}
costs["walk"] = {"time": times["walk"], "money": gather(walk, "cost_private"), "co2": gather(walk, "emissions"),
                 "distance_km": gather(walk, "network_distance_m", 1 / 1000) if "network_distance_m" in walk else np.full_like(times["walk"], np.nan)}
car_km = gather(resident[resident["mode"] == "car"], "distance_m", 1 / 1000)
costs["car-BEV"] = {**costs["car-ICE"], "co2": car_km * np.float32(car_factor["car-BEV"])}

print()
print("=== per-trip medians over all amenity points reached within 60 min, by origin and label ===")
rows = []
for o, name in enumerate(PLACES):
    for label, cost in costs.items():
        reached = np.isfinite(cost["time"][o])
        rows.append({"origin": name, "label": label, "reached_points": int(reached.sum()),
                     "median_min": np.nanmedian(cost["time"][o][reached]),
                     "median_eur": np.nanmedian(cost["money"][o][reached]), "median_g": np.nanmedian(cost["co2"][o][reached]),
                     "median_km": np.nanmedian(cost["distance_km"][o][reached]),
                     "unpriced_money": int(np.isnan(cost["money"][o][reached]).sum()), "unpriced_co2": int(np.isnan(cost["co2"][o][reached]).sum())})
print(pd.DataFrame(rows).round(2).to_string(index=False))


def access_index(mask):
    return ((mask.astype(np.float32) @ ONE_HOT) / TOTALS).mean(axis=1)


print()
print(f"=== reaching {LEVEL:.0%} access: matching budget and mean cost of the trips inside it ===")
budget_grid = np.arange(1, MAX_BUDGET + 1)
summary = []
reach_masks = {}
for o, name in enumerate(PLACES):
    for label, cost in costs.items():
        curve = np.array([access_index(cost["time"][o:o + 1] <= b)[0] for b in budget_grid])
        hit = np.flatnonzero(curve >= LEVEL)
        budget = budget_grid[hit[0]] if len(hit) else np.nan
        reach = cost["time"][o] <= (budget if len(hit) else -1)
        reach_masks[(name, label)] = reach
        summary.append({
            "origin": name, "label": label, "matching_budget_min": budget, "access_at_budget": curve[hit[0]] if len(hit) else curve[-1],
            "access_at_30min": curve[29], "points_inside": int(reach.sum()),
            "mean_min": np.nanmean(cost["time"][o][reach]) if reach.any() else np.nan,
            "mean_eur": np.nanmean(cost["money"][o][reach]) if reach.any() else np.nan,
            "mean_g": np.nanmean(cost["co2"][o][reach]) if reach.any() else np.nan,
            "mean_km": np.nanmean(cost["distance_km"][o][reach]) if reach.any() else np.nan,
            "g_per_km": np.nanmean(cost["co2"][o][reach]) / np.nanmean(cost["distance_km"][o][reach]) if reach.any() else np.nan,
        })
summary = pd.DataFrame(summary)
print(summary.round(2).to_string(index=False))

print()
print("=== transit trips from Kamppi: emissions against distance (sample of priced pairs) ===")
kamppi = resident[(resident["from_id"] == origins["Kamppi"]) & (resident["mode"] == "transit")].copy()
kamppi["g_per_km"] = kamppi["emissions_g"] / (kamppi["distance_m"] / 1000)
print(kamppi[["time_s", "money", "emissions_g", "distance_m", "g_per_km"]].describe().round(2))
print()
print("resident table columns:", list(resident.columns))

# Map: the origin hexagon and the amenity points inside each mode's matching budget.
colours = {"walk": "#2a78d6", "bicycle": "#1baf7a", "transit": "#eb6834", "car-ICE": "#eda100"}
lattice_m = lattice.to_crs("EPSG:3067")
points_m = points.to_crs("EPSG:3067")
figure, axes = plt.subplots(nrows=2, ncols=4, figsize=(20, 10))
for row, name in zip(axes, PLACES):
    origin_geom = lattice_m.loc[lattice_m["id"] == origins[name]]
    for axis, label in zip(row, colours):
        reach = reach_masks[(name, label)]
        budget = summary.loc[(summary["origin"] == name) & (summary["label"] == label), "matching_budget_min"].iloc[0]
        lattice_m.plot(ax=axis, color="#eeeeec", edgecolor="#ffffff", linewidth=0.3)
        points_m[reach].plot(ax=axis, color=colours[label], markersize=2, alpha=0.6)
        origin_geom.plot(ax=axis, facecolor="none", edgecolor="#0b0b0b", linewidth=2)
        axis.set_title(f"{name}, {label}: {int(reach.sum()):,} points within {budget:.0f} min", fontsize=10)
        axis.set_axis_off()
figure.suptitle(f"Amenity points reached at each mode's matching budget for {LEVEL:.0%} access", y=0.99)
figure.tight_layout()
figure.savefig(OUT / "hexagon_reach.png", dpi=90)

# Budget curves per mode for both origins.
figure, axes = plt.subplots(ncols=2, figsize=(12, 4.2), sharey=True)
for axis, (o, name) in zip(axes, enumerate(PLACES)):
    for label, colour in colours.items():
        curve = [access_index(costs[label]["time"][o:o + 1] <= b)[0] for b in budget_grid]
        axis.plot(budget_grid, curve, color=colour, label=label, linewidth=2)
    axis.axhline(LEVEL, color="#9a9a96", linestyle=":")
    axis.set_title(name, loc="left", fontsize=10)
    axis.set_xlabel("Time budget (minutes)")
    axis.grid(color="#e6e6e3")
axes[0].set_ylabel("Access index")
axes[0].legend(frameon=False)
figure.tight_layout()
figure.savefig(OUT / "hexagon_curves.png", dpi=90)
print("figures written")
