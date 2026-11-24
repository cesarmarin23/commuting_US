# Transit factors v4.1 (2026-11-24): monorail, people movers and cable car

Fixes the unresolved Seattle pairs (GTFS route_type 12 had no factor row) and closes the same gap for
the metros still to come. Replace these two files in `us-commuting/factors/` (new folder `us-v4.1`):

- `transit_factors_msa_route_type.csv` (64 rows, was 58)
- `transit_factors_agency_mode.csv` (150 rows, was 146)

All 58 earlier metro rows are unchanged (checked: maximum difference 0.0), so only itineraries that ride
a route_type 12 or 5 leg change.

## Rows added (g CO2e per passenger-km, NTD report year 2024)

| MSA | route_type | System | Passenger-miles | Passengers per train | vehicle | fuel | infrastructure | total |
|---|---|---|---|---|---|---|---|---|
| SEA | 12 | Seattle Center Monorail (NTD 00023) | 1,944,795 | 35.0 | 11.0 | 48.9 | 59.8 | 119.8 |
| DET | 12 | Detroit People Mover (NTD 50141) | 1,456,388 | 10.1 | 38.2 | 635.9 | 207.3 | 881.4 |
| SF | 12 | BART Oakland Airport Connector (NTD 90003) | 1,373,827 | 5.3 | 72.5 | 632.6 | 393.1 | 1098.2 |
| SF | 5 | San Francisco cable cars (NTD 90015) | 4,875,106 | 24.4 | 15.8 | 87.0 | 85.6 | 188.4 |
| US | 12 | All six monorail / automated guideway reporters | 14,648,159 | 9.0 | 42.8 | 314.2 | 232.4 | 589.4 |
| US | 5 | Cable car (San Francisco is the only system) | 4,875,106 | 24.4 | 15.8 | 87.0 | 85.6 | 188.4 |

Miami's Metromover row (MIA, 12) was already there and is unchanged.

Method, same as every other row: fuel = propulsion electricity (NTD Fuel and Energy) x the regional grid
factor / passenger-km; vehicle and infrastructure = the ITF train values per train-km (385.4 and 2,090.6 g)
/ passengers per train (passenger-miles / train revenue miles, NTD Service). Operations 0.

Seattle worked example: 502,326 kWh x 304.9 g/kWh (NWPP) / (1,944,795 x 1.609344 pkm) = 48.9;
1,944,795 / 55,625 train-miles = 35.0 passengers per train; 385.4 / 35.0 = 11.0; 2,090.6 / 35.0 = 59.8.

## What to change in 05.10

1. Point `FACTORS_DIR` at the new folder and bump `RUN_TAG` (for example `us-v4.1-centre`).
2. Seattle crosswalk: add the monorail feed's `agency_name` (check agency.txt; probably
   "Seattle Center Monorail") -> "Seattle Center Monorail (City of Seattle)". The metro row SEA / 12 is the
   same system, so the fallback gives the same value if the name is not matched.
3. Only the Seattle transit cost matrix needs re-annotating; the other four metros have no type 12 or 5
   legs in their feeds, and no street matrix changes. Expect `transit pairs with unresolved emissions` = 0.
4. Safety net for route types that still have no row (6 aerial lift, 7 funicular, or anything new): use
   the metro's row for route_type 0, else the US row for route_type 0, and list the affected routes in the
   coverage table. Do not fall back to cafein's shipped Finnish values.

## Notes

- These systems are small (1.4 to 4.9 million passenger-miles a year), below the 5-million threshold used
  for the other agency rows. They are included because the routing can ride them; their values are noisy
  and they are flagged in the `notes` column.
- The people movers are very high per passenger-km (Detroit, Oakland airport) because they run nearly empty.
- The ITF train archetype is a rough stand-in for a monorail guideway or a cable-car system.
- Electricity for the Seattle monorail was retrieved twice and agreed; train-miles and the other systems
  were retrieved once. Regenerate from the raw NTD files with the rest of the table before the paper is final.
