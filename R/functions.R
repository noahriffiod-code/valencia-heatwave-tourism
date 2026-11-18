# Functions shared by the analysis scripts. Requires R/parameters.R.

# ---------------------------------------------------------------------------
# Heatwave days and counterfactual temperature shift
# ---------------------------------------------------------------------------

# Wave number of each date (NA outside the retained waves)
wave_of_day <- function(dates, waves = params$waves_used) {
  out <- rep(NA_integer_, length(dates))
  for (w in waves) {
    r <- params$waves[params$waves$wave == w, ]
    out[dates >= r$start & dates <= r$end] <- w
  }
  out
}

# Attributable warming (C) for the month of each date.
# scenario: "central", or "low" / "high" for the bounds of the 95% interval.
delta_of_day <- function(dates, scenario = "central") {
  d <- params$delta
  i <- match(as.integer(format(dates, "%m")), d$month)
  col <- c(central = "delta", low = "delta_low", high = "delta_high")[[scenario]]
  d[[col]][i]
}

# Temperature removed from each date in the counterfactual: delta on
# heatwave days, zero otherwise.
temp_shift <- function(dates, scenario = "central", waves = params$waves_used) {
  hw <- !is.na(wave_of_day(dates, waves))
  ifelse(hw, delta_of_day(dates, scenario), 0)
}

# ---------------------------------------------------------------------------
# Tourist nights by day
# ---------------------------------------------------------------------------
# Monthly nights are spread evenly over the days of the month (no daily
# data are published).
daily_nights <- function() {
  n <- params$nights
  do.call(rbind, lapply(seq_len(nrow(n)), function(k) {
    data.frame(date = seq(as.Date(paste0(n$month[k], "-01")), by = "day", length.out = n$n_days[k]),
               nights = n$total[k] / n$n_days[k],
               share_abroad = n$share_abroad[k])
  }))
}

# ---------------------------------------------------------------------------
# Weather
# ---------------------------------------------------------------------------

# Dew point (C) from temperature and relative humidity, Magnus formula
# (Alduchov and Eskridge 1996 coefficients)
dew_point <- function(t, rh) {
  g <- log(pmax(rh, 1) / 100) + 17.625 * t / (243.04 + t)
  243.04 * g / (17.625 - g)
}
rel_humidity <- function(t, td)
  100 * exp(17.625 * td / (243.04 + td)) / exp(17.625 * t / (243.04 + t))

# ERA5 hourly values aggregated to local days: 24-h means of temperature,
# dew point and wind; 24-h sum of precipitation; cloud cover averaged over
# the local hours params$cloud_hours (09:00-21:00).
read_era5_daily <- function(months = params$months) {
  h <- read.csv(params$file_era5, stringsAsFactors = FALSE)
  h <- h[substr(h$local_date, 1, 7) %in% months, ]
  day <- function(x, f) as.numeric(tapply(x, h$local_date, f))
  dh <- h$local_hour >= params$cloud_hours[1] & h$local_hour <= params$cloud_hours[2]
  out <- data.frame(date  = as.Date(sort(unique(h$local_date))),
                    tmed  = day(h$era5_t2m_C, mean),
                    tdew  = day(h$era5_td2m_C, mean),
                    prec  = day(h$era5_precip_mm, sum),
                    wind  = day(h$era5_wind10m_ms, mean),
                    cloud = as.numeric(tapply(h$era5_cloud_pct[dh], h$local_date[dh], mean)))
  out$rh <- rel_humidity(out$tmed, out$tdew)
  out
}

# AEMET station 8416, daily mean temperature (script 04).
read_aemet_daily <- function(months = params$months) {
  a <- read.csv(params$file_aemet, stringsAsFactors = FALSE, encoding = "UTF-8")
  a <- a[substr(a$date, 1, 7) %in% months, ]
  data.frame(date = as.Date(a$date), tmed = a$aemet_tmed)
}

read_tci_weather <- function(months = params$months) {
  w <- read_era5_daily(months)
  w$wind_kmh <- w$wind * 3.6
  w$month <- format(w$date, "%Y-%m")
  w
}

# ---------------------------------------------------------------------------
# Tourism Climatic Index (Mieczkowski 1985) in the version of
# Barrutiabengoa et al. (2024, Eq. 2 and Appendix A.1):
# TCI = 5 x thermal comfort + 2 x precipitation + 2 x cloud cover + wind.
# Lower class bounds and scores of their Tables A.1.1 to A.1.4.
# ---------------------------------------------------------------------------
TCI_HUMIDEX_BOUND <- c(-Inf, -21, -16, -11, -6, 0, 5, 10, 16, 17, 18, 19, 20,
                       27, 28, 29, 30, 31, 32, 33, 34, 35, 36)
TCI_HUMIDEX_SCORE <- c(-6, -2, -1, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                       9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
TCI_CLOUD_BOUND <- c(0, 16.7, 25, 33.3, 41.7, 50, 58.3, 66.7, 75, 83.3, 91.7)   # %
TCI_PREC_BOUND  <- c(0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5)                 # mm
TCI_WIND_BOUND  <- c(0, 2.88, 5.76, 9.04, 12.24, 19.80, 24.30, 28.80, 38.52)    # km/h
# Table A.1.4 is headed m/s but its values are in km/h. Columns: mean
# temperature <= 23.9 C, 24-32.9 C, >= 32.9 C.
TCI_WIND_SCORE  <- cbind(c(10, 9, 8, 7, 6, 5, 4, 3, 0),
                         c(4, 5, 6, 8, 10, 8, 6, 4, 0),
                         c(4, 3, 2, 1, 0, 0, 0, 0, 0))

# Humidex (Masterton and Richardson 1979), as written in Barrutiabengoa et
# al. (2024), Eq. 3
humidex <- function(t, td)
  t + 0.5555 * (6.11 * exp(5417.7530 * (1 / 273.15 - 1 / (273.15 + td))) - 10)

tci <- function(tmed, tdew, cloud, prec, wind_kmh) {
  hx <- humidex(tmed, pmin(tdew, tmed))
  s_temp  <- TCI_HUMIDEX_SCORE[findInterval(hx, TCI_HUMIDEX_BOUND)]
  s_cloud <- (10:0)[pmax(1, findInterval(pmax(cloud, 0), TCI_CLOUD_BOUND))]
  s_prec  <- (10:0)[pmax(1, findInterval(pmax(prec, 0), TCI_PREC_BOUND))]
  col     <- ifelse(tmed <= 23.9, 1, ifelse(tmed < 32.9, 2, 3))
  s_wind  <- TCI_WIND_SCORE[cbind(pmax(1, findInterval(wind_kmh, TCI_WIND_BOUND)), col)]
  data.frame(humidex = hx, tci = pmax(5 * s_temp + 2 * s_prec + 2 * s_cloud + s_wind, 1))
}

# Observed and counterfactual daily TCI. Only temperature (and, with
# rh_fixed, the dew point) changes in the counterfactual.
tci_obs_cf <- function(w, shift, humidity = params$cf_humidity) {
  tmed_cf <- w$tmed - shift
  tdew_cf <- if (humidity == "rh_fixed") dew_point(tmed_cf, w$rh) else w$tdew
  obs <- tci(w$tmed, w$tdew, w$cloud, w$prec, w$wind_kmh)
  cf  <- tci(tmed_cf, tdew_cf, w$cloud, w$prec, w$wind_kmh)
  data.frame(date = w$date, month = w$month, shift = shift, tmed = w$tmed, tmed_cf = tmed_cf,
             humidex = obs$humidex, humidex_cf = cf$humidex, tci = obs$tci, tci_cf = cf$tci)
}

# ---------------------------------------------------------------------------
# Channel 1: lower spending by tourists present on heatwave days
# loss = nights x spending per night x coefficient (% per C) x shift
# ---------------------------------------------------------------------------
channel1 <- function(d, shift, coef = params$spend_coef)
  d$nights * spend_per_night(d$share_abroad) * coef / 100 * shift

# ---------------------------------------------------------------------------
# Channel 2: fewer tourist nights through the TCI
# Monthly log-log relation (Barrutiabengoa et al. 2024):
#   nights_obs / nights_cf = (TCI_obs / TCI_cf)^beta,
# with the monthly TCI taken as the mean of daily values. Observed nights
# are the INE-based totals; counterfactual nights are nights_obs / ratio.
# ---------------------------------------------------------------------------
channel2 <- function(w, scenario = "central", waves = params$waves_used,
                     humidity = params$cf_humidity, beta = params$tci_elasticity) {
  daily <- tci_obs_cf(w, temp_shift(w$date, scenario, waves), humidity)
  months <- intersect(params$nights$month, unique(daily$month))
  by_month <- do.call(rbind, lapply(months, function(m) {
    t <- daily[daily$month == m, ]
    n <- params$nights[params$nights$month == m, ]
    tci_obs <- mean(t$tci, na.rm = TRUE)
    tci_cf  <- mean(t$tci_cf, na.rm = TRUE)
    ratio   <- (tci_obs / tci_cf)^beta
    lost    <- n$total * (1 / ratio - 1)
    spend   <- spend_per_night(n$share_abroad)
    data.frame(month = m, shifted_days = sum(t$shift > 0), tci_obs = tci_obs, tci_cf = tci_cf,
               nights = n$total, change_pct = 100 * (ratio - 1), nights_lost = lost,
               spend_per_night = spend, loss_eur = lost * spend)
  }))
  list(by_month = by_month, daily = daily,
       loss_eur = sum(by_month$loss_eur), nights_lost = sum(by_month$nights_lost))
}

eur <- function(x) format(round(x), big.mark = ",")
