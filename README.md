# Tourism cost of the 2026 heatwaves in Valencia attributable to climate change

Code and data for the tourism section of *Attributing the economic cost of
the summer 2026 heat waves in València to climate change*, by N. Riffiod,
A. G. Fernández-Garza, D. Ávila-Velásquez, E. Gielen and M. Pulido-Velazquez
(2026).

The analysis estimates the loss of tourist spending in the city of Valencia
during the three official AEMET heatwaves of summer 2026 (20-27 June,
2-24 July, 28 July-20 August) that is attributable to climate change. The
counterfactual removes the attributable warming of Barnes et al. (2026) from
mean daily temperature on heatwave days, following the factual minus
counterfactual approach of climate attribution studies.

Two channels are computed:

1. **Spending of tourists present** (`scripts/01_channel1_spending.R`):
   -0.13% of daily spending per degree, the coefficient estimated by
   Heymann (2024) for supermarket spending; his aggregate coefficient of
   -0.12% is used as a variant.
2. **Tourist nights** (`scripts/02_channel2_tci.R`): daily Tourism Climatic
   Index (Mieczkowski 1985) in the version of Barrutiabengoa et al. (2024),
   with thermal comfort based on the humidex (Masterton and Richardson
   1979), computed from ERA5 (Hersbach et al. 2020), and their monthly
   elasticity of hotel nights to the TCI of 0.501 (Mediterranean and
   Islands). Cloud cover is the mean of the hourly ERA5 values from 09:00
   to 21:00 local time.

`scripts/03_total.R` adds the two channels and computes the bounds and
sensitivities reported in the paper. `scripts/04_did_length_of_stay.R` is a
descriptive check on observed hotel data: change in travellers, length of
stay and nights in Valencia between July 2026 and July 2022-2025, relative
to 11 northern cities.

### Why the two channels are added

Tourist spending is the number of nights times the spending per night, so
its change has two parts. Channel 2 counts the nights that did not take
place, valued at the full spending per night. Channel 1 counts the lower
spending of the tourists who did come, and is applied only to observed
nights. The two channels therefore apply to different nights and are
added. The cross term (lost nights times the lower spending per night) is
left out; it is about 0.08 million EUR.

The decomposition holds if Heymann's coefficient measures spending per
tourist. It is estimated on total card spending per day, which may also
reflect fewer tourists present on hot days; to that extent the two
channels overlap. This overlap is not tested. Channel 1 is 3% of the total,
so the overlap is at most 1.1 million EUR.

## Main results (central estimate, EUR)

| Wave | Dates | Spending | Nights | Total |
|---|---|---:|---:|---:|
| 1 | 20-27 Jun | 159,412 | 8,195,317 | 8,354,728 |
| 2 | 2-24 Jul | 444,842 | 17,109,769 | 17,554,611 |
| 3 | 28 Jul-20 Aug | 506,236 | 14,642,558 | 15,148,794 |
| Sum over waves | | 1,110,490 | 39,947,643 | 41,058,133 |
| All waves shifted together | | 1,110,490 | 39,541,436 | 40,651,926 |

The figure reported in the article is the sum over waves, 41.1 million EUR.
Low / high bound of the attributable warming (sum over waves): 19.3 / 70.3
million EUR. With the dew point held fixed instead of relative humidity:
17.0 million EUR. With the aggregate spending coefficient of 0.12%, channel 1
is 1.03 million EUR instead of 1.11. All these values are printed by
`scripts/03_total.R`; Table 9 of the article is printed by
`scripts/02_channel2_tci.R`. Waves 2 and 3 share July and the channel 2 loss
is not linear in the TCI, so the sum over waves differs slightly from the
joint figure.

## Running the code

Requirements: R, base packages only (tested with R 4.3.3 and 4.4.3). Open
`valencia_heatwave_tourism.Rproj` (or set the working directory to the
repository root) and run

```r
source("run_all.R")
```

Results are written to `output/`. The scripts read only the files in
`data/`; nothing is downloaded. A full run takes a few seconds.

## Repository structure

```
run_all.R                         runs scripts 00 to 04
R/parameters.R                    parameters and sources
R/functions.R                     weather, TCI, counterfactual, channels
scripts/00_prepare_ine_monthly.R  INE table 2078 -> monthly hotel nights
scripts/01_channel1_spending.R    channel 1
scripts/02_channel2_tci.R         channel 2, Table 9 of the article
scripts/03_total.R                channels 1 + 2, bounds and sensitivities
scripts/04_did_length_of_stay.R   check on observed hotel data
data/                             inputs (see below)
output/                           results (created by the scripts)
```

## Data

| File | Content | Source |
|---|---|---|
| `heatwaves_aemet_2026.csv` | Dates of the 2026 heatwaves | AEMET, note of 9 Sep 2026, [link](https://www.aemet.es/es/noticias/2026/09/olas_de_calor_2026) |
| `delta_barnes_2026_valencia.csv` | Attributable warming by month, 95% interval | Computed from Barnes et al. (2026), [doi:10.5281/zenodo.22228326](https://doi.org/10.5281/zenodo.22228326), city ES003C |
| `era5_valencia_hourly_2026-06-01_2026-09-30.csv` | ERA5 hourly, local time | Open-Meteo archive API (Zippenfenig 2023), `models=era5`, `elevation=nan`, `cell_selection=land`, nearest land cell to the coordinates of station 8416 in the AEMET inventory, retrieved 4 Nov 2026 |
| `aemet_8416_daily_2026-06-01_2026-09-30.csv` | Daily values, station 8416 Valencia (mean temperature of July 2026 used in script 04) | AEMET OpenData, daily climatological values, retrieved 4 Nov 2026 |
| `aemet_8416_july_2022_2025.csv` | Daily mean temperature, July 2022-2025, station 8416 | AEMET OpenData |
| `raw/ine_2078_valencia_2026M06-M09.csv` | Hotel travellers and nights, Valencia | INE, EOH, [table 2078](https://www.ine.es/jaxiT3/Tabla.htm?t=2078) |
| `ine_eoh_valencia_monthly_2026.csv` | Same, one row per month | `scripts/00_prepare_ine_monthly.R` |
| `ine_eoh_july_cities_2010_2026.csv` | July hotel travellers and nights, 12 cities | INE, EOH, table 2078, retrieved 21 Oct 2026 |

Other figures are entered in `R/parameters.R` with their source and page:
hotel shares of nights and daily spending (Turisme Comunitat Valenciana
2025, report on 2024), the spending coefficients (Heymann 2024) and the TCI
elasticity (Barrutiabengoa et al. 2024).

### Data sources and licences

- **AEMET**: © AEMET. Information prepared using, among others, data from
  the Agencia Estatal de Meteorología. Reused under the AEMET terms
  ([nota legal](https://www.aemet.es/es/nota_legal)); AEMET does not endorse
  this work.
- **INE**: Own elaboration with data extracted from the INE website,
  www.ine.es. Reused under CC BY 4.0
  ([aviso legal](https://ine.es/dyngs/AYU/index.htm?cid=125)); the INE does
  not endorse this work.
- **ERA5**: Contains modified Copernicus Climate Change Service information
  2026. Neither the European Commission nor ECMWF is responsible for any use
  that may be made of the Copernicus information or data it contains.
  Weather data by [Open-Meteo.com](https://open-meteo.com/), licensed under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); column names
  changed.
- **Barnes et al. (2026)**: monthly values derived from the authors' data
  and code (doi:10.5281/zenodo.22228326, CC BY 4.0).

## Main assumptions

- Attributable warming applied to heatwave days only; other days unchanged.
- Relative humidity held fixed in the counterfactual (dew point fixed as a
  variant, which lowers channel 2 from 39.9 to 15.9 million EUR).
- Monthly TCI taken as the mean of daily TCI.
- Monthly nights spread evenly over the days of the month.
- Hotel shares of the province of Valencia (2024) used to scale INE hotel
  nights to all types of accommodation in the city.
- Daily spending of 2024 applied to summer 2026.
- Cloud cover averaged over 09:00-21:00 local time (daytime conditions).
- Dew point from temperature and relative humidity with the Magnus formula
  (Alduchov and Eskridge 1996).

## License

Code: MIT (see `LICENSE`). Data files remain under the terms of their
providers listed above.

## Citation

See `CITATION.cff`.

## References

AEMET (2026). España registra 61 días bajo ola de calor en 2026, más que en
ningún otro año. Agencia Estatal de Meteorología, 9 September 2026.
https://www.aemet.es/es/noticias/2026/09/olas_de_calor_2026

Alduchov, O. A., Eskridge, R. E. (1996). Improved Magnus form approximation
of saturation vapor pressure. *Journal of Applied Meteorology*, 35(4),
601-609. https://doi.org/10.1175/1520-0450(1996)035<0601:IMFAOS>2.0.CO;2

Barnes, C., Masselot, P., Xi, D., Clarke, B., Rayner, A., Chen, X., Wang, R.,
Raju, E., Theokritoff, E., Mistry, M., Gasparrini, A., Otto, F.,
Vicedo-Cabrera, A. M., Konstantinoudis, G. (2026). Heat-related urban
mortality attributable to human-induced climate change in Europe from 2000
to 2025. *Nature Health*. https://doi.org/10.1038/s44360-026-00209-8. Data
and code: https://doi.org/10.5281/zenodo.22228326

Barrutiabengoa, J. M., Carta, G., González, N., Pérez, D., Más, P., Yücel, G.
(2024). *Climate change scenarios and the evolution of Spanish tourism*.
BBVA Research Working Paper 24/11, September 2024.
https://www.bbvaresearch.com/wp-content/uploads/2024/09/WP-24-11_Climate-change-scenarios-and-the-evolution-of-Spanish-tourism.pdf

Hersbach, H., Bell, B., Berrisford, P., et al. (2020). The ERA5 global
reanalysis. *Quarterly Journal of the Royal Meteorological Society*,
146(730), 1999-2049. https://doi.org/10.1002/qj.3803

Heymann, D. C. (2024). The impact of climate change on tourism in Spain:
analysis and outlook. CaixaBank Research, 31 January 2024.
https://www.caixabankresearch.com/en/sector-analysis/tourism/impact-climate-change-tourism-spain-analysis-and-outlook

INE (2026). Encuesta de Ocupación Hotelera, table 2078: Viajeros y
pernoctaciones por puntos turísticos. Instituto Nacional de Estadística.
https://www.ine.es/jaxiT3/Tabla.htm?t=2078

Masterton, J. M., Richardson, F. A. (1979). *Humidex: a method of
quantifying human discomfort due to excessive heat and humidity*. CLI 1-79,
Environment Canada, Atmospheric Environment Service, Downsview, Ontario.

Mieczkowski, Z. (1985). The tourism climatic index: a method of evaluating
world climates for tourism. *The Canadian Geographer*, 29(3), 220-233.
https://doi.org/10.1111/j.1541-0064.1985.tb00365.x

Turisme Comunitat Valenciana (2025). *Evolución de la actividad turística en
la provincia de Valencia, año 2024*. Estadístiques de Turisme de la
Comunitat Valenciana.
https://www.turisme.gva.es/tcv/tcv2024/4-Valencia_2024c.pdf

Zippenfenig, P. (2023). Open-Meteo.com Weather API. Zenodo.
https://doi.org/10.5281/zenodo.7970649
