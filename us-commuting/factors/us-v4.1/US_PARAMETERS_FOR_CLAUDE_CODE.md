# US emission parameters for the commuting runs (15 MSAs)

Version v4, 2026-11-20. DRAFT values: fine for running the pipeline, not yet final for the paper (see "Known limits").

Purpose: apply these factors to the routed commutes (LODES flows, routed by mode with cafein) instead of
cafein's shipped Finnish/ITF factors. The reference notebook is `05.9-lodes-commute-emissions.ipynb` in
`commuting_US`; every parameter below maps to its parameter block (step 1) and factor table (step 2).

Files in this folder:

| File | Content |
|---|---|
| `us_parameters.json` | All scalar parameters and the car factors per MSA |
| `car_factors_msa.csv` | Petrol and electric car factors per MSA, LODES states and year |
| `transit_factors_msa_route_type.csv` | Transit factors per MSA and GTFS route_type (the fallback rows) |
| `transit_factors_agency_mode.csv` | Transit factors per agency and mode (132 rows, use when the GTFS agency can be matched) |

Units: g CO2e per km. Transit rows are per passenger-km. Car rows are per vehicle-km and must be divided by occupancy.

## 1. Study areas and flows

- MSAs: the `cbsa` / `cbsaname` fields of the LODES 8.4 crosswalk (2020 blocks). Look each MSA up by name, as notebook 05.1 does.
- LODES year: 2023 for all MSAs except Detroit, which uses 2021 (Michigan has no OD files for 2022-2023).
- MSAs that cross state lines need the OD and crosswalk files of every state listed in `car_factors_msa.csv` (column `lodes_states`).
- Keep `commutes_per_week`, routing settings and departure time as in notebook 05.9.

## 2. Car occupancy

- `car_occupancy = 1.19` persons per car (US work trips, 2017 National Household Travel Survey; FHWA Conditions and Performance, 24th ed., Exhibit 3-31).
- Per passenger-km = per vehicle-km / 1.19.

## 3. Petrol car (same in every MSA)

| Component | g CO2e per vehicle-km | Source |
|---|---|---|
| Vehicle + fuel (combined) | 274.0 | 441 g/mile, new 2022 small SUV, cradle-to-grave. Kelly et al. 2024, doi:10.4271/2024-01-2830 |
| Infrastructure (roads) | 13.4 | 21.5 g/mile = 68.8 Mt CO2e per year / 3,196,095 million vehicle-miles. Iyer et al. 2024, US DOE record |
| Total | 287.4 | (441 + 21.5) / 1.609344 |
| Per passenger-km | 241.5 | 287.4 / 1.19 |

- Argonne prints one cradle-to-grave number, not a vehicle/fuel split. In cafein's component columns put 274.0 under `fuel`, 0 under `vehicle`, 13.4 under `infrastructure`, 0 under `operations`. Only the total is meaningful.
- Sensitivity: passenger car 258.2 and pickup 385.0 g per vehicle-km (394 and 598 g/mile plus roads).

**Important, cafein label issue.** cafein's shipped car rows (ICE 162, BEV 70) are labelled per vehicle-km but are per passenger-km at 1.5 persons (the ITF default). Henrikki is fixing this. Do not combine the shipped rows with an occupancy. For the US runs, replace the car rows with the values here (per vehicle-km) and set occupancy 1.19, or compute car emissions directly as `network_distance_km * 241.5` g.

## 4. Electric car (full-electrification scenario), per MSA

Method: Argonne's electric small SUV is 214 g/mile at the US average grid = 65 (vehicle and battery) + 149 (electricity). The electricity part is multiplied by the MSA's grid intensity relative to the US average; roads (21.5 g/mile) are added; divide by 1.609344.

| MSA | LODES states | LODES year | eGRID region | Grid g/kWh | BEV vehicle | BEV fuel | BEV infra | BEV total g/vkm | BEV g/pkm | BEV/ICE |
|---|---|---|---|---|---|---|---|---|---|---|
| NY New York-Newark-Jersey City | ny,nj | 2023 | NYCW | 507.0 | 40.4 | 117.2 | 13.4 | 171.0 | 143.7 | 0.595 |
| LA Los Angeles-Long Beach-Anaheim | ca | 2023 | CAMX | 244.8 | 40.4 | 56.6 | 13.4 | 110.3 | 92.7 | 0.384 |
| CHI Chicago-Naperville-Elgin | il,in | 2023 | RFCW | 467.3 | 40.4 | 108.0 | 13.4 | 161.8 | 136.0 | 0.563 |
| DAL Dallas-Fort Worth-Arlington | tx | 2023 | ERCT | 389.2 | 40.4 | 90.0 | 13.4 | 143.7 | 120.8 | 0.5 |
| HOU Houston-Pasadena-The Woodlands | tx | 2023 | ERCT | 389.2 | 40.4 | 90.0 | 13.4 | 143.7 | 120.8 | 0.5 |
| ATL Atlanta-Sandy Springs-Roswell | ga | 2023 | SRSO | 440.0 | 40.4 | 101.7 | 13.4 | 155.5 | 130.7 | 0.541 |
| WAS Washington-Arlington-Alexandria | dc,va,md,wv | 2023 | RFCE | 332.4 | 40.4 | 76.9 | 13.4 | 130.6 | 109.8 | 0.454 |
| MIA Miami-Fort Lauderdale-West Palm Beach | fl | 2023 | FRCC | 442.1 | 40.4 | 102.2 | 13.4 | 156.0 | 131.1 | 0.543 |
| PHL Philadelphia-Camden-Wilmington | pa,nj,de,md | 2023 | RFCE | 332.4 | 40.4 | 76.9 | 13.4 | 130.6 | 109.8 | 0.454 |
| PHX Phoenix-Mesa-Chandler | az | 2023 | AZNM | 365.8 | 40.4 | 84.6 | 13.4 | 138.3 | 116.2 | 0.481 |
| BOS Boston-Cambridge-Newton | ma,nh | 2023 | NEWE | 302.7 | 40.4 | 70.0 | 13.4 | 123.7 | 104.0 | 0.431 |
| RIV Riverside-San Bernardino-Ontario | ca | 2023 | CAMX | 244.8 | 40.4 | 56.6 | 13.4 | 110.3 | 92.7 | 0.384 |
| SF San Francisco-Oakland-Fremont | ca | 2023 | CAMX | 244.8 | 40.4 | 56.6 | 13.4 | 110.3 | 92.7 | 0.384 |
| DET Detroit-Warren-Dearborn | mi | 2021 | RFCM | 548.7 | 40.4 | 126.8 | 13.4 | 180.6 | 151.8 | 0.628 |
| SEA Seattle-Tacoma-Bellevue | wa | 2023 | NWPP | 304.9 | 40.4 | 70.5 | 13.4 | 124.3 | 104.4 | 0.432 |
- Petrol total for the ratio: 287.4 g per vehicle-km. `BEV/ICE` is the factor to rescale car emissions per MSA (replaces the Finnish 70/162).
- BEV g/pkm = total / 1.19.
- Grid g/kWh = eGRID2023 subregion generation mix (EPA, Table 2) x ITF life-cycle factor per source (coal 1061.8, oil 1033.5, natural gas 507.1, biomass 65.2, nuclear 8.3, hydro/wind/solar/geothermal 0). US average 400.5.

## 5. Public transport

Rows are in cafein's component format: `route_type, vehicle, fuel, infrastructure, operations` in g CO2e per passenger-km, at the occupancy observed in the 2024 National Transit Database.

How to assign a factor to each ridden leg:

1. If the GTFS `agency_name` of the route matches an agency in `transit_factors_agency_mode.csv` for that MSA, use that agency's row for the leg's mode. Match by agency name (build a small crosswalk per MSA; there is no ready GTFS-to-NTD id table). NTD mode to route_type: MB, CB, RB -> 3; HR -> 1; LR, SR -> 0; CR, YR -> 2; FB -> 4; TB -> 11; MG -> 12; CC -> 5.
2. Otherwise use the MSA row in `transit_factors_msa_route_type.csv` for the leg's `route_type`.
3. If the MSA has no row for that route_type, use the `US` row.

Notes:
- Extended GTFS route types should be collapsed first (100-117 -> 2, 400-405 -> 1, 700-716 -> 3, 900-906 -> 0, 1000/1200 -> 4, 800 -> 11).
- Trolleybuses are often coded 3 in feeds; use the trolleybus row only when route_type is 11 (or the route is known to be a trolleybus).
- Ferries (route_type 4) are fuel only and high (650-1050 g/pkm).
- `operations` is 0 everywhere: empty running is already inside the reported fuel.
- Amtrak and other intercity services are not in the table; exclude them or use the US commuter-rail row.
- Columns `total_low`, `total_high` and `biogenic_zero_variant_total` are for sensitivity runs.

MSA x route_type rows (same as the CSV):

| MSA | route_type | mode | vehicle | fuel | infrastructure | operations | total |
|---|---|---|---|---|---|---|---|
| NY | 0 | light rail / streetcar | 9.4 | 102.8 | 51.2 | 0.0 | 163.5 |
| NY | 1 | subway / heavy rail | 1.9 | 64.8 | 10.4 | 0.0 | 77.1 |
| NY | 2 | commuter rail | 1.9 | 101.8 | 10.2 | 0.0 | 113.9 |
| NY | 3 | bus | 9.1 | 185.4 | 4.1 | 0.0 | 198.6 |
| NY | 4 | ferry | 0.0 | 647.7 | 0.0 | 0.0 | 647.7 |
| LA | 0 | light rail / streetcar | 8.6 | 69.0 | 46.4 | 0.0 | 124.0 |
| LA | 1 | subway / heavy rail | 4.1 | 78.0 | 22.0 | 0.0 | 104.0 |
| LA | 2 | commuter rail | 6.1 | 356.7 | 33.3 | 0.0 | 396.1 |
| LA | 3 | bus | 13.5 | 252.0 | 6.1 | 0.0 | 271.6 |
| CHI | 1 | subway / heavy rail | 4.8 | 136.5 | 26.2 | 0.0 | 167.5 |
| CHI | 2 | commuter rail | 3.6 | 270.5 | 19.4 | 0.0 | 293.5 |
| CHI | 3 | bus | 16.3 | 270.3 | 7.3 | 0.0 | 293.9 |
| DAL | 0 | light rail / streetcar | 13.4 | 172.1 | 72.4 | 0.0 | 257.9 |
| DAL | 2 | commuter rail | 15.5 | 534.2 | 84.3 | 0.0 | 634.0 |
| DAL | 3 | bus | 28.6 | 497.1 | 12.8 | 0.0 | 538.5 |
| HOU | 0 | light rail / streetcar | 20.7 | 141.2 | 112.5 | 0.0 | 274.5 |
| HOU | 3 | bus | 14.3 | 249.4 | 6.4 | 0.0 | 270.1 |
| ATL | 1 | subway / heavy rail | 5.8 | 99.0 | 31.4 | 0.0 | 136.2 |
| ATL | 3 | bus | 19.9 | 312.4 | 9.0 | 0.0 | 341.3 |
| WAS | 1 | subway / heavy rail | 6.3 | 165.2 | 34.2 | 0.0 | 205.7 |
| WAS | 2 | commuter rail | 4.1 | 306.6 | 22.3 | 0.0 | 333.0 |
| WAS | 3 | bus | 17.1 | 285.7 | 7.7 | 0.0 | 310.6 |
| MIA | 1 | subway / heavy rail | 7.1 | 165.2 | 38.4 | 0.0 | 210.6 |
| MIA | 2 | commuter rail | 4.0 | 182.3 | 21.8 | 0.0 | 208.1 |
| MIA | 3 | bus | 12.8 | 209.1 | 5.7 | 0.0 | 227.6 |
| MIA | 12 | automated guideway | 32.6 | 244.4 | 176.8 | 0.0 | 453.8 |
| PHL | 0 | light rail / streetcar | 27.1 | 129.1 | 147.2 | 0.0 | 303.4 |
| PHL | 1 | subway / heavy rail | 5.9 | 120.8 | 32.1 | 0.0 | 158.8 |
| PHL | 2 | commuter rail | 5.2 | 119.6 | 27.9 | 0.0 | 152.7 |
| PHL | 3 | bus | 16.8 | 260.8 | 7.6 | 0.0 | 285.1 |
| PHL | 11 | trolleybus | 12.5 | 167.5 | 5.6 | 0.0 | 185.7 |
| PHX | 0 | light rail / streetcar | 10.3 | 108.7 | 56.1 | 0.0 | 175.1 |
| PHX | 3 | bus | 34.7 | 566.2 | 15.6 | 0.0 | 616.5 |
| BOS | 0 | light rail / streetcar | 13.1 | 97.5 | 71.2 | 0.0 | 181.8 |
| BOS | 1 | subway / heavy rail | 3.9 | 93.8 | 21.2 | 0.0 | 119.0 |
| BOS | 2 | commuter rail | 2.9 | 168.8 | 15.6 | 0.0 | 187.3 |
| BOS | 3 | bus | 11.4 | 198.8 | 5.1 | 0.0 | 215.4 |
| BOS | 4 | ferry | 0.0 | 1044.6 | 0.0 | 0.0 | 1044.6 |
| RIV | 2 | commuter rail | 6.1 | 356.7 | 33.3 | 0.0 | 396.1 |
| RIV | 3 | bus | 23.1 | 314.3 | 10.4 | 0.0 | 347.8 |
| SF | 0 | light rail / streetcar | 15.8 | 123.6 | 85.9 | 0.0 | 225.3 |
| SF | 1 | subway / heavy rail | 5.2 | 60.5 | 28.0 | 0.0 | 93.6 |
| SF | 2 | commuter rail | 4.6 | 227.8 | 24.7 | 0.0 | 257.1 |
| SF | 3 | bus | 14.8 | 252.7 | 6.6 | 0.0 | 274.1 |
| SF | 4 | ferry | 0.0 | 875.2 | 0.0 | 0.0 | 875.2 |
| SF | 11 | trolleybus | 9.5 | 60.2 | 4.3 | 0.0 | 74.0 |
| DET | 3 | bus | 19.8 | 279.0 | 8.9 | 0.0 | 307.7 |
| SEA | 0 | light rail / streetcar | 4.7 | 37.6 | 25.5 | 0.0 | 67.8 |
| SEA | 2 | commuter rail | 2.9 | 212.3 | 15.6 | 0.0 | 230.8 |
| SEA | 3 | bus | 13.8 | 223.8 | 6.2 | 0.0 | 243.8 |
| SEA | 4 | ferry | 0.0 | 830.8 | 0.0 | 0.0 | 830.8 |
| SEA | 11 | trolleybus | 14.6 | 115.7 | 6.5 | 0.0 | 136.8 |
| US | 0 | light rail / streetcar | 12.1 | 123.8 | 65.4 | 0.0 | 201.3 |
| US | 1 | subway / heavy rail | 3.0 | 77.7 | 16.3 | 0.0 | 97.0 |
| US | 2 | commuter rail | 2.7 | 138.4 | 14.8 | 0.0 | 155.9 |
| US | 3 | bus | 18.2 | 261.3 | 8.2 | 0.0 | 287.7 |
| US | 4 | ferry | 0.0 | 739.9 | 0.0 | 0.0 | 739.9 |
| US | 11 | trolleybus | 10.7 | 116.3 | 4.8 | 0.0 | 131.8 |
How these were built: fuel = agency fuel and electricity (NTD 2024) x emission factors (US EPA 2025 for fuels incl. CH4/N2O, + upstream fuel production from FTA/GREET; electricity x regional grid g/kWh above), divided by passenger-km. Vehicle and infrastructure = ITF values per vehicle-km (bus 122.6 and 55.1; train 385.4 and 2090.6 g per vehicle- or train-km) divided by observed passengers per vehicle or train.

## 6. Walking and cycling

Unchanged from the Finnish study: walking 56 g per km (walk mode and walking legs of transit trips); bicycle and e-bike as cafein's default rows.

## 7. What to produce

For each MSA and commuting flow: minutes, km and g CO2e per mode (transit, car, car_bev, bicycle, e_bike, walk), as in notebook 05.9. Route into a fresh `matrices-emissions` folder because the factors changed. Record in the run's parameter table which factor file and version was used.

## Known limits (do not block the run)

- Transit inputs were pulled through the NTD query interface (twice, agreeing) and should be regenerated from the raw NTD files before the paper is final.
- The unit of NTD natural-gas gallons is unconfirmed (about 9% on the gas part of CNG bus fleets).
- The eGRID region of each MSA and agency was assigned by utility territory and not yet checked in EPA Power Profiler.
- Petrol and electric car values are for new 2022 vehicles, not the in-use fleet.
- Finnish factors assume 1.5 persons per car; the US commuting value is 1.19.

## Sources

- Kelly, J. C. et al. (2024). Comprehensive Cradle to Grave Life Cycle Analysis of On-Road Vehicles in the United States Based on GREET. SAE Technical Paper 2024-01-2830. https://doi.org/10.4271/2024-01-2830
- Iyer, R., Kelly, J., Shen, K. & Wang, M. (2024). Greenhouse Gas Emissions for Annual Construction and Maintenance of U.S. Roadways. US DOE Vehicle Technologies Office record. https://www.energy.gov/sites/default/files/2024-08/DOE_Program_Record_for_Road_Infrastructure_GHG_Emissions_08.14.2024.pdf
- US EPA (2025). eGRID2023 Summary Tables, rev. 2. https://www.epa.gov/system/files/documents/2025-06/summary_tables_rev2.pdf
- Cazzola, P. & Crist, P. (2020). Good to Go? Assessing the Environmental Performance of New Mobility. ITF/OECD. https://doi.org/10.1787/f5cd236b-en
- Federal Transit Administration. National Transit Database, report year 2024. https://data.transportation.gov/d/8ehq-7his ; https://data.transportation.gov/d/wwdp-t4re
- US EPA (2025). Emission Factors for Greenhouse Gas Inventories. https://www.epa.gov/system/files/documents/2025-01/ghg-emission-factors-hub-2025.pdf
- FTA (2021). Transit Greenhouse Gas Emissions Estimator v2.0 User Guide. https://www.transit.dot.gov/sites/fta.dot.gov/files/2021-04/FTA-GHG-Emissions-Estimator-v2-User-Guide.pdf
- US DOT, FHWA & FTA. Conditions and Performance, 24th edition, Exhibit 3-31. https://www.fhwa.dot.gov/policy/24cpr/pdf/Chapter3.pdf
- US Census Bureau (2025). LODES Dataset Structure, Format Version 8.4. https://lehd.ces.census.gov/data/lodes/LODES8/LODESTechDoc8.4.pdf

## Addendum (2026-11-23): car travel times

Peak-hour car times get a congestion adjustment inside each metro's main urban area. See
`CAR_TRAVEL_TIME_INSTRUCTIONS.md` and `congestion_tti_urban_areas.csv`. Emissions are not affected.
