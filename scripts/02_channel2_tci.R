# Channel 2: fewer tourist nights because of lower climatic comfort.
# Daily TCI from ERA5, observed and counterfactual (T - delta on heatwave
# days); monthly means; BBVA elasticity; nights lost valued at the monthly
# spending per night. Run from the repository root.

source("R/parameters.R")
source("R/functions.R")

weather <- read_tci_weather()
res <- channel2(weather)

by_scenario <- sapply(params$delta_scenarios, function(s) channel2(weather, scenario = s)$loss_eur)

# Contribution of each wave: only the days of that wave are shifted. Waves 2
# and 3 share July, so the contributions do not add up exactly to the total.
by_wave <- data.frame(wave = params$waves_used,
                      loss_eur = sapply(params$waves_used, function(v) channel2(weather, waves = v)$loss_eur))

# Sum over waves for each bound of the attributable warming, and with the
# dew point held fixed instead of relative humidity (sensitivity).
by_wave_scenario <- sapply(params$delta_scenarios, function(s)
  sum(sapply(params$waves_used, function(v) channel2(weather, scenario = s, waves = v)$loss_eur)))
by_wave_td <- sum(sapply(params$waves_used, function(v)
  channel2(weather, waves = v, humidity = "td_fixed")$loss_eur))
variants <- data.frame(variant = c("Sum over waves, RH fixed (main)", "Sum over waves, dew point fixed"),
                       loss_eur = c(sum(by_wave$loss_eur), by_wave_td))

cat("\nChannel 2: tourist nights (TCI, BBVA elasticity", params$tci_elasticity, ")\n")
bm <- res$by_month
print(data.frame(month = bm$month, shifted_days = bm$shifted_days, tci_cf = round(bm$tci_cf, 2),
                 tci_obs = round(bm$tci_obs, 2), nights = eur(bm$nights), change_pct = round(bm$change_pct, 3),
                 nights_lost = eur(bm$nights_lost), loss_eur = eur(bm$loss_eur)), row.names = FALSE)
cat("Total, central delta:", eur(res$loss_eur), "EUR (", eur(res$nights_lost), "nights )\n")
cat("By wave:", paste0("wave ", by_wave$wave, " ", eur(by_wave$loss_eur), collapse = "; "), "EUR\n")
cat("Delta low / central / high, joint:", paste(eur(by_scenario), collapse = " / "), "EUR\n")
cat("Delta low / central / high, sum over waves:", paste(eur(by_wave_scenario), collapse = " / "), "EUR\n")
print(transform(variants, loss_eur = eur(loss_eur)), row.names = FALSE)

write.csv(bm, output_path("channel2_by_month.csv"), row.names = FALSE)
write.csv(by_wave, output_path("channel2_by_wave.csv"), row.names = FALSE)
write.csv(variants, output_path("channel2_variants.csv"), row.names = FALSE)
write.csv(res$daily, output_path("channel2_tci_daily.csv"), row.names = FALSE)
