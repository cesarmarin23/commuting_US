# Car travel times at peak hours: congestion adjustment inside the urban area

Version v2, 2026-11-23. Companion to `US_PARAMETERS_FOR_CLAUDE_CODE.md`. Data: `congestion_tti_urban_areas.csv`.

## Goal

Keep cafein's own peak-hour car times everywhere in the MSA, and raise them only for the part of each
commute driven inside the metro's main Census urban area, where measured congestion is higher than
cafein assumes. Suburban and rural parts of the MSA are not penalised further.

This changes car travel TIME only. Car distance and car emissions stay exactly as they are.

## Inputs

1. `r_cafein`: the ratio of peak to free-flow car time that cafein's rush profile already applies.
   Nominal value 1.2. Check it before using it: for each MSA, route a sample of at least 5,000 OD pairs
   with the rush profile and with the uncongested profile (intersection delays on in both), and take the
   median of rush_time / freeflow_time. If cafein applies a fixed factor, use that factor. Record the
   value used per MSA.
2. `tti`: Travel Time Index 2024 per metro, from `congestion_tti_urban_areas.csv` (column `tti_2024`).
   Definition: travel time in the peak period (weekdays 6-10 a.m. and 3-7 p.m.) divided by travel time at
   free-flow (measured speeds at low-volume hours, 10 p.m.-5 a.m.), on freeways and arterial streets.
   Source: 2025 Urban Mobility Report, Table 1 (Texas A&M Transportation Institute, INRIX speeds).
3. Urban area polygons: 2020 Census Urban Areas, national TIGER/Line "UAC20" file. For each MSA use the
   one urban area whose name starts with the text in column `census_urban_area_2020_name_to_match`.
   The names in that column were written from memory: confirm each one in the file and stop if a name
   does not match exactly one polygon. Other, smaller urban areas inside the MSA are NOT adjusted.

## Calculation, per commuting flow (home point -> work point)

In words: inside the urban area the peak factor is the metro's Travel Time Index; outside it the peak
factor is cafein's own (nominally 1.2). Both are applied to the FREE-FLOW time.

1. `f_urban` = share of the car trip that lies inside the urban area polygon, between 0 and 1.
   - Preferred: the routed car path geometry, if cafein can return it: length inside / total length.
   - Otherwise: the straight line from home point to work point, intersected with the polygon:
     length inside / total length. (Both points inside usually gives 1; both outside usually 0.)
   - State in the run's parameter table which of the two was used.
2. `car_minutes_adjusted = car_minutes_freeflow * [ f_urban * tti + (1 - f_urban) * r_cafein ]`
   - If only the rush time is stored, use the identical form
     `car_minutes_adjusted = car_minutes_rush * [ 1 + f_urban * (tti / r_cafein - 1) ]`.
     The division by `r_cafein` only removes cafein's peak factor from the urban part before the index
     is applied, so the two factors are never multiplied together.
   - If `tti <= r_cafein`, keep cafein's time (never speed cafein up).
3. Keep the columns `car_minutes_rush`, `car_minutes_adjusted`, `f_urban`. Apply the same adjusted time
   to the `car_bev` mode. Do not touch `km` or `grams`.

Worked example, Los Angeles (tti 1.64, r_cafein 1.2), free-flow time 25.0 minutes (cafein rush 30.0):
- entirely inside the urban area: 25.0 x 1.64 = 41.0 minutes;
- 40% inside: 25.0 x (0.4 x 1.64 + 0.6 x 1.2) = 34.4 minutes;
- entirely outside: 25.0 x 1.2 = 30.0 minutes (cafein's time, unchanged).

## Outputs to report per MSA

- `r_cafein` used and `tti`.
- Share of commuters, and of car-km, with `f_urban` = 1, between 0 and 1, and = 0.
- Worker-weighted median car minutes before and after.
- Worker-weighted share of commuters for whom transit is faster than car, before and after.
- Route nothing again: this is a post-processing step on the existing car matrices. Save under a new tag.

## Limits to keep in the notes

- The index is one average for the whole urban area and both directions; commutes into the centre are
  slower than this and reverse commutes faster.
- It assumes time is spread along the trip like distance.
- The urban area used by the report may not match the 2020 Census polygon exactly (the report does not
  state the vintage).
- The nominal 1.2 for cafein must be replaced by the measured value.

## Source

Schrank, D., Albert, L., Jha, K. & Eisele, B. (2025). 2025 Urban Mobility Report. Texas A&M
Transportation Institute, August 2025. Report: https://tti.tamu.edu/documents/mobility-report-2025.pdf ;
Table 1: https://tti.tamu.edu/documents/umr/data/national/national-table-1.pdf ;
methodology (Appendix A): https://tti.tamu.edu/documents/mobility-report-2025-appx-a.pdf ;
full data (Excel): https://tti.tamu.edu/documents/umr/data/complete-data-2025-umr-by-tti.xlsx

## Implementation note (05.10, 2026-11-23)

cafein's rush effect is a sum of per-crossing penalties plus a 1.2 multiplier on junction-free links at
70 km/h and above only, so the rush-to-uncongested ratio varies by trip and no single `r_cafein` exists;
the rush profile also overshoots the Census commute times, so it is not used in the final time. The
index and cafein's crossing penalties describe different things: the index is slower driving between
crossings at the peak, the penalties are the stops themselves and do not multiply with congestion. 05.10
therefore takes as base the midday-profile time (cafein's lightest per-crossing delays, no congestion
multiplier) and applies the index only to the link time, the speed-limit (no-delay) time of the same
trip, on the urban share:
`t_car = t_midday + f_urban * (tti - 1) * t_speedlimit + t_parking`.
`f_urban` is the share of 41 equally spaced points on the home-to-work straight line inside the
urban-area polygon; `t_parking` is 3 minutes where the work tract is an employment centre, at least 10,000 LODES jobs
per km2 of the tract (Manhattan's core; downtown Houston, the Medical Center and the Galleria), and 0
elsewhere; the index itself keeps the whole urban area, as the report measures it. Three car matrices feed this: midday profile, speed-limit regime, and the rush profile kept in
the commute table as `minutes_rush` for reference.
