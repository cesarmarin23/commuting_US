"""Convert shape_dist_traveled to metres in GTFS feeds that record it in feet.

cafein 0.31 validates a trip's shape_dist_traveled against the crow-fly length of its stop
sequence and accepts any ratio between 0.8 and 5 as metres. A feed in feet gives ratios of
3.3 to 5 on most trips, so it passes as metres and every ridden distance, and the grams
computed from it, come out 3.28 times too large (CTA in Chicago; Sound Transit, King
County Metro and Intercity Transit in Seattle). Kilometre feeds (ratio about 0.001) are
recognised by cafein already; mile feeds (about 0.0006) fail the tier and fall back to the
shape geometry, which is fine.

Per feed, the unit is decided once from the ratio between the shape_dist_traveled span of
its shapes and their geodesic length (the GTFS specification requires one unit per feed).
A feed in feet is rewritten in place with shapes.txt and stop_times.txt converted to
metres; everything else in the zip is copied byte for byte. The rewrite is idempotent:
a converted feed measures as metres and is left alone.

Usage:
    python fix-gtfs-shape-dist-units.py <gtfs folder> [...]          # report only
    python fix-gtfs-shape-dist-units.py <gtfs folder> [...] --apply  # rewrite feet feeds
"""
import csv
import io
import math
import os
import shutil
import sys
import tempfile
import zipfile
from collections import defaultdict
from pathlib import Path

FEET_TO_METRES = 0.3048
SAMPLE_SHAPES = 60


def geodesic(a, b):
    radius = 6371000.0
    lat1, lon1, lat2, lon2 = map(math.radians, (a[0], a[1], b[0], b[1]))
    h = math.sin((lat2 - lat1) / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin((lon2 - lon1) / 2) ** 2
    return 2 * radius * math.asin(math.sqrt(h))


def unit_ratio(archive):
    """Median ratio of shape_dist_traveled span to geodesic shape length over a sample of shapes; None without usable data."""
    names = set(archive.namelist())
    if "shapes.txt" not in names:
        return None
    reader = csv.DictReader(io.TextIOWrapper(archive.open("shapes.txt"), encoding="utf-8-sig"))
    if reader.fieldnames is None or "shape_dist_traveled" not in reader.fieldnames:
        return None
    shapes, seen = defaultdict(list), set()
    for row in reader:
        shape_id = row["shape_id"]
        if shape_id not in seen:
            if len(seen) >= SAMPLE_SHAPES:
                break
            seen.add(shape_id)
        try:
            shapes[shape_id].append((int(row["shape_pt_sequence"]), float(row["shape_pt_lat"]), float(row["shape_pt_lon"]), float(row["shape_dist_traveled"])))
        except (ValueError, KeyError):
            continue
    ratios = []
    for points in shapes.values():
        points.sort()
        if len(points) < 3:
            continue
        length = sum(geodesic(points[i][1:3], points[i + 1][1:3]) for i in range(len(points) - 1))
        span = points[-1][3] - points[0][3]
        if length > 500 and span > 0:
            ratios.append(span / length)
    if not ratios:
        return None
    ratios.sort()
    return ratios[len(ratios) // 2]


def unit_name(ratio):
    if ratio is None:
        return "none"
    candidates = {"metres": 1.0, "feet": 1 / FEET_TO_METRES, "kilometres": 1e-3, "miles": 1 / 1609.344}
    name = min(candidates, key=lambda key: abs(math.log(ratio / candidates[key])))
    return name if abs(math.log(ratio / candidates[name])) < math.log(1.25) else f"unclear ({ratio:.4f})"


def convert_table(data, factor):
    text = data.decode("utf-8-sig")
    reader = csv.DictReader(io.StringIO(text))
    out = io.StringIO()
    writer = csv.DictWriter(out, fieldnames=reader.fieldnames, lineterminator="\n")
    writer.writeheader()
    for row in reader:
        value = row.get("shape_dist_traveled")
        if value not in (None, ""):
            row["shape_dist_traveled"] = f"{float(value) * factor:.1f}"
        writer.writerow(row)
    return out.getvalue().encode("utf-8")


def rewrite(path, factor):
    handle, temporary = tempfile.mkstemp(suffix=".zip", dir=os.environ.get("TMPDIR", str(path.parent)))
    os.close(handle)
    with zipfile.ZipFile(path) as source, zipfile.ZipFile(temporary, "w", zipfile.ZIP_DEFLATED) as target:
        for item in source.infolist():
            data = source.read(item.filename)
            if item.filename in ("shapes.txt", "stop_times.txt"):
                data = convert_table(data, factor)
            target.writestr(item, data)
    shutil.move(temporary, path)


def main(argv):
    apply = "--apply" in argv
    folders = [Path(arg) for arg in argv if arg != "--apply"]
    for folder in folders:
        for path in sorted(folder.glob("*.zip")):
            with zipfile.ZipFile(path) as archive:
                ratio = unit_ratio(archive)
            unit = unit_name(ratio)
            action = ""
            if unit == "feet":
                action = "converted to metres" if apply else "would convert to metres"
                if apply:
                    rewrite(path, FEET_TO_METRES)
                    with zipfile.ZipFile(path) as archive:
                        action += f", now {unit_name(unit_ratio(archive))}"
            print(f"{folder.name:10} {path.name[:52]:52} {unit:12} {action}")


if __name__ == "__main__":
    main(sys.argv[1:])
