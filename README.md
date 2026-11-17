# Tourism cost of the 2026 heatwaves in Valencia attributable to climate change

Code and data for the tourism section of *[paper title]*, [authors], [journal, year].

The analysis estimates the loss of tourist spending in the city of Valencia
during the three official AEMET heatwaves of summer 2026 (20-27 June,
2-24 July, 28 July-20 August) that is attributable to climate change. The
counterfactual removes the attributable warming of Barnes et al. (2026) from
mean daily temperature on heatwave days, following the factual minus
counterfactual approach of climate attribution studies.

Two channels are computed:

1. **Spending of tourists present** (`scripts/01_channel1_spending.R`):
   -0.13% of daily spending per degree (Heymann 2024).
2. **Tourist nights** (`scripts/02_channel2_tci.R`): daily Tourism Climatic
   Index (Mieczkowski 1985) in the version of Barrutiabengoa et al. (2024),
   computed from ERA5 (Hersbach et al. 2020), and their monthly elasticity
   of hotel nights to the TCI of 0.501 (Mediterranean and Islands).

`scripts/03_uncertainty.R` combines both channels, reports results by
heatwave and by bound of the attributable warming, and runs a joint Monte
Carlo (5,000 draws) following Gasparrini and Leone (2014).
`scripts/04_did_length_of_stay.R` is a check on hotel length of stay
(difference-in-differences against 11 northern cities, placebo inference as
in Abadie et al. 2010).

## Main results (central estimate, EUR)

| Wave | Dates | Spending | Nights | Total |
|---|---|---:|---:|---:|
| 1 | 20-27 Jun | 159,412 | 8,022,292 | 8,181,703 |
| 2 | 2-24 Jul | 444,842 | 16,855,826 | 17,300,668 |
| 3 | 28 Jul-20 Aug | 506,236 | 14,457,750 | 14,963,986 |
| All (joint) | | 1,110,490 | 38,941,214 | 40,051,704 |

Low / high bound of the attributable warming: 18.9 / 68.5 million EUR.
Monte Carlo median 40.4 million EUR (95% interval 19.3-69.0).
Waves 2 and 3 share July; the channel 2 loss is not linear in the TCI, so
the sum over waves (40.4 million) differs slightly from the joint figure.

## Labour productivity

`scripts/05_labour_productivity.R` estimates the direct cost of the heat-induced
loss of work capacity for outdoor work in the city of Valencia, following
Orlov et al. (2020) on hourly ERA5 data: WBGT in the shade (Lemke and
Kjellstrom 2012) and in the sun (Liljegren et al. 2008, R package HeatStressR),
HOTHAPS work capacity function, and hours lost valued at the INE labour cost.
Five sectors are covered (construction, water and waste, warehousing, postal
and courier, buildings and landscape), with Social Security affiliations in the
city at 31 December 2024 (Ajuntament de Valencia 2025). The part attributable
to climate change uses the same counterfactual (Barnes et al. 2026). There is
no attributable warming for September, so it is not computed for wave 4.

This script needs the R package HeatStressR (version 3.0.0 or later):

```r
install.packages("HeatStressR")
source("scripts/05_labour_productivity.R")
```

It reads `era5_valencia_hourly_2026-06-01_2026-09-30.csv`,
`delta_barnes_2026_valencia.csv` and `heatwaves_aemet_2026.csv` from `data/`.
Labour costs, employment and work intensities are entered in the script with
their source. Results are written to `output/labour_productivity_results.csv`.

## Running the code

Requirements: R (tested with 4.3.3), base R only for the tourism scripts. Open
`valencia_heatwave_tourism.Rproj` (or set the working directory to the
repository root) and run

```r
source("run_all.R")
```

Results are written to `output/`. The scripts read only the files in
`data/`; nothing is downloaded.

## Repository structure

```
run_all.R                         runs scripts 00_prepare to 04
R/parameters.R                    parameters and sources
R/functions.R                     weather, TCI, counterfactual, channels
scripts/00_prepare_ine_monthly.R  INE table 2078 -> monthly hotel nights
scripts/01_channel1_spending.R
scripts/02_channel2_tci.R
scripts/03_uncertainty.R
scripts/04_did_length_of_stay.R
scripts/05_labour_productivity.R  labour productivity (needs HeatStressR)
data/                             inputs (see below)
output/                           results (created by the scripts)
```

## Data

| File | Content | Source |
|---|---|---|
| `heatwaves_aemet_2026.csv` | Dates of the 2026 heatwaves | AEMET, note of 9 Sep 2026, [link](https://www.aemet.es/es/noticias/2026/09/olas_de_calor_2026) |
| `delta_barnes_2026_valencia.csv` | Attributable warming by month, 95% interval | Computed from Barnes et al. (2026), [doi:10.5281/zenodo.22228327](https://doi.org/10.5281/zenodo.22228327), city ES003C |
| `era5_valencia_hourly_2026-06-01_2026-09-30.csv` | ERA5 hourly, local time | Open-Meteo archive API (Zippenfenig 2024), `models=era5`, `elevation=nan`, `cell_selection=land`, nearest land cell to the coordinates of station 8416 in the AEMET inventory, retrieved 4 Nov 2026 |
| `aemet_8416_daily_2026-06-01_2026-09-30.csv` | Daily values, station 8416 Valencia | AEMET OpenData, daily climatological values, retrieved 4 Nov 2026 |
| `aemet_8416_july_2022_2025.csv` | Daily mean temperature, July 2022-2025, station 8416 | AEMET OpenData |
| `raw/ine_2078_valencia_2026M06-M09.csv` | Hotel travellers and nights, Valencia | INE, EOH, [table 2078](https://www.ine.es/jaxiT3/Tabla.htm?t=2078) |
| `ine_eoh_valencia_monthly_2026.csv` | Same, one row per month | `scripts/00_prepare_ine_monthly.R` |
| `ine_eoh_july_cities_2010_2026.csv` | July hotel travellers and nights, 12 cities | INE, EOH, table 2078, retrieved 21 Oct 2026 |

Other figures are entered in `R/parameters.R` with their source and page:
hotel shares of nights and daily spending (Turisme Comunitat Valenciana,
2024 report), the spending coefficient (Heymann 2024) and the TCI elasticity
(Barrutiabengoa et al. 2024).

### Data sources and licences

- **AEMET**: (c) AEMET. Information prepared using, among others, data from
  the Agencia Estatal de Meteorologia. Reused under the AEMET terms
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
  and code (doi:10.5281/zenodo.22228327, CC BY 4.0).
- **Labour productivity inputs entered in the script**: employment from the
  Ajuntament de Valencia statistical yearbook (Social Security affiliations,
  source Ministerio de Trabajo y Economia Social); labour costs from the INE
  ETCL (CC BY 4.0, as above); MET values from the 2024 Adult Compendium of
  Physical Activities (Herrmann et al. 2024) and Tudor-Locke et al. (2011),
  cited, not reproduced.
- **HeatStressR** (Zheng, with code from the HeatStress package of
  A. Casanueva) is GPL-3. It is called as an R dependency and is not
  distributed with this repository.

## Main assumptions

- Attributable warming applied to heatwave days only; other days unchanged.
- Relative humidity held fixed in the counterfactual (dew point fixed as a
  variant, which roughly halves channel 2).
- Monthly TCI taken as the mean of daily TCI.
- Monthly nights spread evenly over the days of the month.
- Hotel shares of the province of Valencia (2024) used to scale INE hotel
  nights to all types of accommodation in the city.
- Daily spending of 2024 applied to summer 2026.
- AEMET check only: cloud cover approximated by 1 - sunshine duration / day
  length (day length from Allen et al. 1998); this proxy is our own choice.
- Dew point from temperature and relative humidity with the Magnus formula
  (Alduchov and Eskridge 1996).

## License

Code: MIT (see `LICENSE`). Data files remain under the terms of their
providers listed above.

## Citation

See `CITATION.cff`.

## References

Abadie, A., Diamond, A., Hainmueller, J. (2010). Synthetic control methods
for comparative case studies: estimating the effect of California's tobacco
control program. *Journal of the American Statistical Association*, 105(490),
493-505. https://doi.org/10.1198/jasa.2009.ap08746

AEMET (2026). Olas de calor 2026. Agencia Estatal de Meteorologia, note of
9 September 2026. https://www.aemet.es/es/noticias/2026/09/olas_de_calor_2026

Alduchov, O. A., Eskridge, R. E. (1996). Improved Magnus form approximation
of saturation vapor pressure. *Journal of Applied Meteorology*, 35(4),
601-609.

Allen, R. G., Pereira, L. S., Raes, D., Smith, M. (1998). *Crop
evapotranspiration: guidelines for computing crop water requirements*. FAO
Irrigation and Drainage Paper 56. FAO, Rome.

Barnes, C., Masselot, P., Xi, D., Clarke, B., Rayner, A., Chen, X., Wang, R.,
Raju, E., Theokritoff, E., Mistry, M., Gasparrini, A., Otto, F.,
Vicedo-Cabrera, A. M., Konstantinoudis, G. (2026). Heat-related urban
mortality attributable to human-induced climate change in Europe from 2000
to 2025. *Nature Health*. https://doi.org/10.1038/s44360-026-00209-8. Data
and code: https://doi.org/10.5281/zenodo.22228327

Barrutiabengoa, J. M., Carta, G., Gonzalez, N., Perez, D., Mas, P., Yucel, G.
(2024). *Climate change scenarios and the evolution of Spanish tourism*.
BBVA Research Working Paper 24/11.
https://www.bbvaresearch.com/wp-content/uploads/2024/09/WP-24-11_Climate-change-scenarios-and-the-evolution-of-Spanish-tourism.pdf

Gasparrini, A., Leone, M. (2014). Attributable risk from distributed lag
models. *BMC Medical Research Methodology*, 14, 55.
https://doi.org/10.1186/1471-2288-14-55

Ajuntament de Valencia (2025). Anuario estadistico 2025, chapter 7, file
070401_AfiliacionSS.xlsx (Social Security affiliations at 31 December 2024).
https://www.valencia.es/val/estadistica/anuari-estadistica?capitulo=7

Hersbach, H., Bell, B., Berrisford, P., et al. (2020). The ERA5 global
reanalysis. *Quarterly Journal of the Royal Meteorological Society*,
146(730), 1999-2049. https://doi.org/10.1002/qj.3803

Herrmann, S. D., Willis, E. A., Ainsworth, B. E., et al. (2024). 2024 Adult
Compendium of Physical Activities: a third update of the energy costs of human
activities. *Journal of Sport and Health Science*, 13(1), 6-12.
https://doi.org/10.1016/j.jshs.2023.10.010

Heymann, D. C. (2024). The impact of climate change on tourism in Spain:
analysis and outlook. CaixaBank Research, 31 January 2024.
https://www.caixabankresearch.com/en/sector-analysis/tourism/impact-climate-change-tourism-spain-analysis-and-outlook

INE (2026). Encuesta Trimestral de Coste Laboral, table 6061 and press
release for the second quarter of 2026. Instituto Nacional de Estadistica.
https://www.ine.es/jaxiT3/files/t/es/csv_bdsc/6061.csv ;
https://www.ine.es/dyngs/Prensa/ETCL2T26.pdf

INE (2026). Encuesta de Ocupacion Hotelera, table 2078: Viajeros y
pernoctaciones por puntos turisticos. Instituto Nacional de Estadistica.
https://www.ine.es/jaxiT3/Tabla.htm?t=2078

Kjellstrom, T., Freyberg, C., Lemke, B., Otto, M., Briggs, D. (2018).
Estimating population heat exposure and impacts on working people in
conjunction with climate change. *International Journal of Biometeorology*,
62(3), 291-306. https://doi.org/10.1007/s00484-017-1407-0

Lemke, B., Kjellstrom, T. (2012). Calculating workplace WBGT from
meteorological data: a tool for climate change assessment. *Industrial
Health*, 50(4), 267-278.

Liljegren, J. C., Carhart, R. A., Lawday, P., Tschopp, S., Sharp, R. (2008).
Modeling the wet bulb globe temperature using standard meteorological
measurements. *Journal of Occupational and Environmental Hygiene*, 5(10),
645-655. https://doi.org/10.1080/15459620802310770

Masterton, J. M., Richardson, F. A. (1979). *Humidex: a method of
quantifying human discomfort due to excessive heat and humidity*. CLI 1-79,
Environment Canada, Atmospheric Environment Service, Downsview, Ontario.

Mieczkowski, Z. (1985). The tourism climatic index: a method of evaluating
world climates for tourism. *Canadian Geographer*, 29(3), 220-233.

Orlov, A., Sillmann, J., Aunan, K., Kjellstrom, T., Aaheim, A. (2020).
Economic costs of heat-induced reductions in worker productivity due to
global warming. *Global Environmental Change*, 63, 102087.
https://doi.org/10.1016/j.gloenvcha.2020.102087

Tudor-Locke, C., Ainsworth, B. E., Washington, T. L., Troiano, R. (2011).
Assigning metabolic equivalent values to the 2002 census occupational
classification system. *Journal of Physical Activity and Health*, 8(4),
581-586. https://doi.org/10.1123/jpah.8.4.581

Turisme Comunitat Valenciana (no date). *Evolucion de la actividad turistica,
provincia de Valencia 2024*.
https://www.turisme.gva.es/tcv/tcv2024/4-Valencia_2024c.pdf

Zheng, Y. (2026). HeatStressR: calculate heat stress indices. R package
version 3.0.0 (fork of HeatStress by A. Casanueva). CRAN.
https://github.com/cran/HeatStressR

Zippenfenig, P. (2024). Open-Meteo.com Weather API (v1.4.0). Zenodo.
https://doi.org/10.5281/zenodo.14582479
