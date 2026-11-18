# Parameters and input data for the tourism cost of the 2026 heatwaves in
# Valencia. Sourced by every analysis script. All paths are relative to the
# repository root.

params <- list()

data_path   <- function(f) file.path("data", f)
output_path <- function(f) file.path("output", f)
dir.create("output", showWarnings = FALSE)

# ---------------------------------------------------------------------------
# 1. Heatwaves
# ---------------------------------------------------------------------------
# Official 2026 heatwaves for mainland Spain and the Balearic Islands
# (AEMET, note of 9 September 2026,
# https://www.aemet.es/es/noticias/2026/09/olas_de_calor_2026).
# AEMET criterion: at least 10% of reference stations above the 95th
# percentile of July-August Tmax (1971-2000) for at least 3 consecutive days.
# Wave 4 (2-7 September) is provisional in the AEMET note and is excluded.
params$year <- 2026
params$waves <- read.csv(data_path("heatwaves_aemet_2026.csv"), stringsAsFactors = FALSE)
params$waves$start <- as.Date(params$waves$start)
params$waves$end   <- as.Date(params$waves$end)
params$waves_used  <- c(1, 2, 3)

# Months containing at least one day of a retained wave. The TCI and the
# number of nights are monthly quantities.
params$months <- sort(unique(unlist(lapply(
  which(params$waves$wave %in% params$waves_used),
  function(i) format(seq(params$waves$start[i], params$waves$end[i], by = "day"), "%Y-%m")))))

# ---------------------------------------------------------------------------
# 2. Weather
# ---------------------------------------------------------------------------
# Main source for the TCI: ERA5 hourly reanalysis (Hersbach et al. 2020),
# retrieved through the Open-Meteo archive API (models = era5, nearest
# 0.25 degree land cell to AEMET station 8416, no elevation correction).
# ERA5 is the source used by Barrutiabengoa et al. (2024, p. 9) to estimate the
# elasticity applied in channel 2.
params$file_era5 <- data_path("era5_valencia_hourly_2026-06-01_2026-09-30.csv")

# AEMET station 8416 "VALENCIA" (city centre, 13 m), daily climatological
# values. Used for the July temperature anomaly in the hotel-data check
# (script 04).
params$file_aemet <- data_path("aemet_8416_daily_2026-06-01_2026-09-30.csv")
params$file_aemet_july_ref <- data_path("aemet_8416_july_2022_2025.csv")

# Cloud cover: mean of the hourly values from 09:00 to 21:00 local time
# (daytime conditions).
params$cloud_hours <- c(9, 21)

# ---------------------------------------------------------------------------
# 3. Counterfactual climate
# ---------------------------------------------------------------------------
# Counterfactual temperature on heatwave days: T_cf = T_obs - delta, where
# delta is the warming of mean daily temperature attributable to climate
# change in Valencia for the calendar month, from Barnes et al. (2026),
# Nature Health, doi:10.1038/s44360-026-00209-8. Data and code:
# doi:10.5281/zenodo.22228326, city ES003C, row "Unweighted".
#   delta(month) = beta(month) x W_2026,  W_2026 = 1.319 C
# Barnes et al. provide June, July and August only.
# Days outside the retained waves are left unchanged.
params$delta <- read.csv(data_path("delta_barnes_2026_valencia.csv"), stringsAsFactors = FALSE)
params$delta_scenarios <- c("low", "central", "high")   # bounds of the 95% interval

# Humidity in the counterfactual: relative humidity is held fixed and the
# dew point is recomputed ("rh_fixed"); alternative: dew point held fixed
# ("td_fixed").
params$cf_humidity <- "rh_fixed"

# ---------------------------------------------------------------------------
# 4. Tourist nights, all types of accommodation, city of Valencia
# ---------------------------------------------------------------------------
# (a) Hotel nights by month: INE, Encuesta de Ocupacion Hotelera, table
#     2078, tourist point 46250 Valencia (residents in Spain / abroad).
#     Built from data/raw/ by scripts/00_prepare_ine_monthly.R.
params$ine_monthly <- read.csv(data_path("ine_eoh_valencia_monthly_2026.csv"), stringsAsFactors = FALSE)

# (b) Share of hotels in total nights, province of Valencia, 2024 (Turisme
#     Comunitat Valenciana, "Evolucion de la actividad turistica, provincia
#     de Valencia 2024", https://www.turisme.gva.es/tcv/tcv2024/4-Valencia_2024c.pdf).
#     Foreign tourists (INE Frontur-Egatur), p. 3: rented dwelling 26.4%,
#     friends or family 21.5%, second homes 13.2%; the remainder is hotels
#     and other collective accommodation.
params$hotel_share_abroad <- 1 - (0.264 + 0.215 + 0.132)
#     Domestic tourists (INE ETR-Familitur), p. 5: 7.1 million trips of
#     3.9 days on average; second homes 8.0, friends or family 10.3,
#     rented dwelling 3.4 million nights.
params$hotel_share_spain <- 1 - (8 + 10.3 + 3.4) / (7.1 * 3.9)
# Provincial annual shares are applied to the city in every month. For
# domestic tourists the non-hotel share is probably overstated for the city.

params$nights <- data.frame(month = params$months)
k <- match(params$months, params$ine_monthly$month)
params$nights$abroad <- params$ine_monthly$hotel_nights_abroad[k] / params$hotel_share_abroad
params$nights$spain  <- params$ine_monthly$hotel_nights_spain[k]  / params$hotel_share_spain
params$nights$total  <- params$nights$abroad + params$nights$spain
params$nights$share_abroad <- params$nights$abroad / params$nights$total
params$nights$n_days <- sapply(params$months, function(m) {
  d <- as.Date(paste0(m, "-01"))
  as.numeric(seq(d, by = "month", length.out = 2)[2] - d)
}, USE.NAMES = FALSE)
rm(k)

# ---------------------------------------------------------------------------
# 5. Tourist spending
# ---------------------------------------------------------------------------
# Daily spending in the city of Valencia, 2024 (same Turisme CV report):
# foreign tourists p. 4, domestic tourists p. 6 (EUR per person per day).
params$spend_abroad <- 153.6
params$spend_spain  <- 84.3
spend_per_night <- function(share_abroad)
  share_abroad * params$spend_abroad + (1 - share_abroad) * params$spend_spain

# ---------------------------------------------------------------------------
# 6. Behavioural coefficients
# ---------------------------------------------------------------------------
# Channel 1. Heymann (2024), CaixaBank Research, "The impact of climate
# change on tourism in Spain: analysis and outlook":
# -0.12% aggregate tourist spending per degree, -0.13% in supermarkets.
# The supermarket figure is used; no standard error is reported. The
# aggregate figure is reported as a sensitivity (script 01).
params$spend_coef     <- 0.13
params$spend_coef_aggregate <- 0.12

# Channel 2. Barrutiabengoa et al. (2024), BBVA Research Working Paper 24/11,
# "Climate change scenarios and the evolution of Spanish tourism", Table 2: elasticity of
# monthly hotel nights to the TCI, "Mediterranean and Islands" group
# (which includes the province of Valencia, Figure 4); t = 24.65.
params$tci_elasticity <- 0.501

