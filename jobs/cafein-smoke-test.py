"""Smoke test of cafein 0.31.0 in the python-geo kernel against the Helsinki sample data.

Builds a small slope-aware street network around central Helsinki, compares the
bicycle, e-bike and walking times on one trip, exercises the speeds= override,
streams a tiny cost matrix and round-trips a saved network. Run it in a batch job
(jobs/cafein-smoke-test.sbatch), not on a login node.
"""

import os
import sys
import time
from pathlib import Path

import geopandas as gpd
from shapely.geometry import Point

import cafein
import cafein.sampledata.helsinki as helsinki
import pyrosm
from cafein import StreetNetwork, TravelCostMatrix
from cafein._streaming import read_shards

print("python", sys.version.split()[0], "| cafein", cafein.__version__, "| pyrosm", pyrosm.__version__)
assert cafein.__version__ == "0.31.0", cafein.__version__

scratch = Path(os.environ.get("TMPDIR", ".")) / "cafein-smoke"
scratch.mkdir(parents=True, exist_ok=True)

# Kamppi to Kalasatama, inside a central bounding box (min_lon, min_lat, max_lon, max_lat).
bounding_box = (24.90, 60.15, 25.00, 60.20)
origin = (60.16891, 24.93300)
destination = (60.18700, 24.97800)

started = time.time()
streets = StreetNetwork.from_osm(
    helsinki.osm_pbf,
    modes=("walk", "bicycle", "car"),
    bounding_box=bounding_box,
    dem=helsinki.dem,
    dem_interval=25,
    country="FI",
)
print(f"street network built in {time.time() - started:.0f} s: "
      f"{streets.vertex_count:,} vertices, {streets.edge_count:,} edges, "
      f"DEM coverage {streets.elevation_metadata['coverage']:.1%}")

times = {mode: streets.travel_time(origin, destination, mode=mode) for mode in ("walk", "bicycle", "e_bike")}
for mode, seconds in times.items():
    print(f"{mode:8} {seconds / 60:6.1f} min")
assert times["e_bike"] < times["bicycle"] < times["walk"], times

faster = streets.travel_time(origin, destination, mode="e_bike", speeds={"e_bike": 20})
explicit = streets.travel_time(origin, destination, mode="e_bike", speeds={"e_bike": 17.4})
print(f"e_bike at 20 km/h {faster / 60:.1f} min; at the explicit default 17.4 km/h {explicit / 60:.1f} min")
assert faster < times["e_bike"] and explicit == times["e_bike"], (faster, explicit, times["e_bike"])

points = gpd.GeoDataFrame(
    {"id": ["kamppi", "kalasatama", "kallio"]},
    geometry=[Point(24.93300, 60.16891), Point(24.97800, 60.18700), Point(24.95200, 60.18400)],
    crs="EPSG:4326",
)
for mode in ("bicycle", "e_bike"):
    output = scratch / mode
    TravelCostMatrix.to_parquet(
        streets, points, points,
        transport_mode=mode,
        speeds={mode: {"bicycle": 15.3, "e_bike": 17.4}[mode]},
        max_street_time=120,
        perspectives="private",
        output_time_units="seconds",
        output=output,
    )
    matrix = read_shards(output)
    print(f"{mode} matrix: {len(matrix)} rows, columns {list(matrix.columns)}")
    print(matrix.round(1).to_string(index=False))

saved = scratch / "smoke.cafein"
streets.save(saved)
reloaded = StreetNetwork.load(saved)
assert reloaded.travel_time(origin, destination, mode="e_bike") == times["e_bike"]
print("save and load round trip ok")
print("SMOKE TEST PASSED")
