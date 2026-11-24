# A first look across the metros before any routing: the straight-line distance of the kept commutes, worker-weighted.
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np, pandas as pd

RESULTS = Path("/scratch/project_2010423/carbon-advantage/commuting")
FIGURES = Path("/projappl/project_2010423/cafein/us-commuting/figures")
YEAR = 2023
METROS = ["new-york", "chicago", "seattle", "houston", "phoenix"]
LABELS = {"new-york": "New York", "chicago": "Chicago", "seattle": "Seattle", "houston": "Houston", "phoenix": "Phoenix"}
COLOURS = {"new-york": "#0072B2", "chicago": "#D55E00", "seattle": "#009E73", "houston": "#E69F00", "phoenix": "#CC79A7"}   # Okabe-Ito, fixed order
GRID = np.arange(0, 80.5, 0.5)

plt.rcParams.update({"font.family": "sans-serif", "font.size": 9, "axes.spines.top": False, "axes.spines.right": False})
figure, axes = plt.subplots(ncols=2, figsize=(13, 4.8), layout="constrained")
rows = []
for metro in METROS:
    flows = pd.read_parquet(RESULTS / metro / f"lodes-metro-od-JT01-{YEAR}-kept.parquet", columns=["S000", "km"])
    km, wt = flows["km"].to_numpy(float), flows["S000"].to_numpy(float)
    order = np.argsort(km); cumulative = np.cumsum(wt[order]) / wt.sum()
    cdf = np.interp(GRID, km[order], cumulative, left=0.0)
    axes[0].plot(GRID, cdf, color=COLOURS[metro], linewidth=2, label=LABELS[metro])
    density, edges = np.histogram(km, bins=np.arange(0, 60.5, 2.5), weights=wt)
    axes[1].plot((edges[:-1] + edges[1:]) / 2, density / wt.sum() / 2.5 * 10, color=COLOURS[metro], linewidth=2)
    quantiles = [km[order][np.searchsorted(cumulative, q)] for q in (0.1, 0.25, 0.5, 0.75, 0.9)]
    rows.append({"metro": LABELS[metro], "workers (kept flows)": int(wt.sum()), "tract pairs": len(flows),
                 "p10 km": quantiles[0], "p25 km": quantiles[1], "median km": quantiles[2], "p75 km": quantiles[3], "p90 km": quantiles[4],
                 "mean km": np.average(km, weights=wt), "under 5 km": wt[km < 5].sum() / wt.sum(), "over 30 km": wt[km > 30].sum() / wt.sum()})
axes[0].set_xlim(0, 80); axes[0].set_ylim(0, 1)
axes[0].set_xlabel("straight-line home-to-work distance, km"); axes[0].set_ylabel("share of workers commuting at most this far")
axes[0].set_title("Cumulative, worker-weighted", loc="left", fontsize=9); axes[0].grid(axis="y", alpha=0.25, linewidth=0.5)
axes[1].set_xlim(0, 60); axes[1].set_ylim(bottom=0)
axes[1].set_xlabel("straight-line home-to-work distance, km"); axes[1].set_ylabel("share of workers per 10 km")
axes[1].set_title("Distribution, 2.5 km bins", loc="left", fontsize=9); axes[1].grid(axis="y", alpha=0.25, linewidth=0.5)
axes[0].legend(frameon=False, fontsize=8, loc="lower right")
figure.suptitle("Where the commutes of the five metros sit, before any routing: LODES 2023 primary jobs, tracts under 20 km2", x=0, ha="left", fontsize=10)
figure.savefig(FIGURES / "05.2-flows-distance-by-metro.png", dpi=200, bbox_inches="tight")
table = pd.DataFrame(rows).set_index("metro")
pd.set_option("display.width", 220)
print(table.round({"p10 km": 1, "p25 km": 1, "median km": 1, "p75 km": 1, "p90 km": 1, "mean km": 1, "under 5 km": 3, "over 30 km": 3}).to_string())
print("saved", FIGURES / "05.2-flows-distance-by-metro.png")
