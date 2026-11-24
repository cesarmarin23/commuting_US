# Commuting in the US: time against emissions

Routed commutes of US metros from LODES tract-to-tract flows, by transit, car, bicycle, e-bike and on
foot, with life-cycle emissions per trip at US-specific factors, and the time price of the cleaner
modes. Routing and emissions come from `cafein`; everything runs as Slurm jobs on CSC Roihu.

## Layout

```
cafein/
├── us-commuting/            the LODES pipeline, one notebook per step, all metros in one run
│   ├── 05.1  … 05.11        the steps (see the order below)
│   ├── cities/<city>/       the two city-specific notebooks per metro, and their figures
│   ├── factors/us-v4/       the US emission factors and the car congestion inputs
│   ├── figures/             figures of the current run tag; superseded tags in earlier-runs/
│   ├── jobs/                one sbatch per notebook, plus the check-*.py sanity scripts
│   └── archive/             stale copies, safe to delete
├── exploratory/             earlier work: cafein basics (01), Helsinki (02), WorldCommuting-OD
│                            Helsinki and Santiago (03), London routing (04), with figures/ and jobs/
├── networks/                cafein network artifacts shared by both (*.cafein, not in git)
└── jobs/cafein-smoke-test   checks the cafein install on a compute node
```

Data lives on scratch: `/scratch/project_2010423/carbon-advantage/commuting/<city>/` holds each
metro's flows, routing points, matrices and commute tables; `/scratch/project_2010423/data/` holds
LODES, GTFS, OSM and TIGER inputs.

## The pipeline, in order

| Step | Notebook | Scope | What it does |
|---|---|---|---|
| 1 | `05.1-lodes-first-steps` | all | how LODES counts people, the kept tracts |
| 2 | `cities/<city>/05.2*-lodes-flows-<city>` | per city | the tract-to-tract commuting table of one metro |
| 3 | `cities/<city>/05.3*-lodes-routing-<city>` | per city | street and transit networks of the metro, the first routing |
| 4 | `05.4-lodes-commuting-comparison` | all | the metros side by side |
| 5 | `05.6-lodes-transit-gap-and-unreached` | all | the transit gap and the unreached tracts |
| 6 | `05.7-lodes-routing-points` | all | housing-weighted home points, jobs-weighted work points |
| 7 | `05.8-lodes-routing-point-validation` | all | the routing points validated against block-level routing |
| 8 | `05.9-lodes-commute-emissions` | all | commute emissions at the Finnish factors (reference) |
| 9 | `05.10-lodes-commute-emissions-us-factors` | all | the main routing and emissions run at the US factors, with the departure window, parking and urban congestion; writes the commute tables |
| 10 | `05.11-lodes-time-vs-emissions` | all | time against emissions: densities, the frontier against the car, the maps |

Each notebook is executed in place by its job: from the repository root,
`sbatch us-commuting/jobs/<name>.sbatch`. The jobs change into the notebook's folder, so relative
paths inside a notebook are relative to that folder; the shared networks are reached as
`../networks/` from `us-commuting/` and `../../../networks/` from a city folder.

The run tag (`RUN_TAG` in 05.10, repeated in 05.11) names the commute tables and the figures of one
set of routing and factor choices. Current: `us-v4.1-centre`. Earlier tags are kept beside it on
scratch and under `figures/earlier-runs/`.

## Rules that hold in every metro

- **Metros covered:** New York, Houston, Chicago, Seattle and Phoenix (added 2026-11-24), routed on a
  Tuesday, 2026-11-10, departing 08:30.
- **Transit walking cap.** Every transit routing, the first pass of step 3 included, caps the walk to
  the first stop and from the last stop at 30 minutes (`ACCESS_EGRESS_WALK_MIN` in each 05.3*
  notebook, `access_egress_walk_min` in 05.10). Step 3 writes its matrix to `matrices/transit-walk30`.
  Houston's steps 10 to 14 are the exception: they explain the unreached commutes of the first routing
  with cafein's default 120-minute walk, which they keep as `transit_uncapped_min`.
- **Departure window.** 05.10's transit minutes are the median over every departure minute of 08:30
  to 09:00; the 08:30 journey supplies distance and grams.
- **Units of GTFS shape distances.** cafein 0.31 reads `shape_dist_traveled` in feet as metres (CTA,
  Sound Transit, King County Metro, Intercity Transit), which inflates ridden distances and grams by
  3.28. Each 05.3* notebook runs `jobs/fix-gtfs-shape-dist-units.py` on its feed folder right after the
  fetch: feet feeds are converted to metres in place, idempotently. Once cafein decides the unit per
  feed the step becomes a no-op.
- **Unresolved factors.** A transit leg with no factor row keeps its time and gets no grams; 05.10
  counts those pairs, zero in every metro since the v4.1 rows (Seattle's monorail was the case).

## Adding a metro

1. Get its LODES states and year from `factors/us-v4/car_factors_msa.csv`, its GTFS feeds into
   `/scratch/project_2010423/data/gtfs/<city>/`, and its MSA code from the same CSV.
2. Create `cities/<city>/` by copying the two Houston notebooks and their job scripts, and point them
   at the new metro; run them (steps 2 and 3).
3. Add the metro to the `AREAS` dictionary of 05.4, 05.6, 05.7, 05.8, 05.9, 05.10 and 05.11 (folder,
   MSA code, GTFS folder, network artifacts, departure, UTM zone, map zoom), to the `STREET_ARTIFACTS`
   and `TRANSIT_ARTIFACTS` of 05.7, to the per-city map calls of 05.4, 05.6 and 05.7, and its GTFS
   agencies to the `AGENCY_CROSSWALK` and `ROUTE_OVERRIDES` of 05.10 (the coverage table of its step 3
   lists the agencies left on the fallback rows; an empty crosswalk is fine).
4. Run steps 6 to 10. The congestion step needs the metro's row in
   `factors/us-v4/congestion_tti_urban_areas.csv`, already present for the 15 planned metros.

## Factors

`us-commuting/factors/us-v4.1/` holds the factor set in force: version v4 (2026-11-20, draft), the
source document `US_PARAMETERS_FOR_CLAUDE_CODE.md`, the car and transit factor tables and the car
travel-time instructions with the Urban Mobility Report congestion indices, plus the v4.1 transit patch
of 2026-11-24 (`TRANSIT_FACTORS_V4_1_PATCH.md`: rows for monorail and people movers, route type 12, and
the cable car, type 5; the 58 earlier rows unchanged). `us-v4/` is kept as delivered. 05.10 records
which files and version a run used in its parameter table; a route type with no row anywhere takes the
light-rail row as a stand-in, never cafein's shipped values.
