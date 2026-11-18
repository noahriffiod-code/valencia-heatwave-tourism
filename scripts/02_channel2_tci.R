# Channel 2: fewer tourist nights because of lower climatic comfort.
# Daily TCI from ERA5, observed and counterfactual (T - delta on heatwave
# days); monthly means; BBVA elasticity; nights lost valued at the monthly
# spending per night. Run from the repository root.
#
# The contribution of a wave is computed by shifting the days of that wave
# only. Waves 2 and 3 share July and the response is not linear, so the
# contributions do not add up exactly to the joint computation (all waves
# shifted together), which is also reported. The main result is the sum of
# the contributions.

source("R/parameters.R")
source("R/functions.R")

weather <- read_tci_weather()

# Sum over waves of the loss, for one scenario of delta and one humidity rule
by_wave <- function(scenario = "central", humidity = params$cf_humidity)
  sapply(params$waves_used, function(v)
    channel2(weather, scenario = scenario, waves = v, humidity = humidity)$loss_eur)

central <- by_wave()
joint   <- channel2(weather)
results <- data.frame(
  channel  = "2 nights",
  variant  = c(rep("central", 4), "delta_low", "delta_high", "dew_point_fixed", "joint"),
  wave     = c(params$waves_used, rep("Total", 5)),
  loss_eur = c(central, sum(central), sum(by_wave("low")), sum(by_wave("high")),
               sum(by_wave(humidity = "td_fixed")), joint$loss_eur))

# Table 9 of the paper: joint computation by month
bm <- joint$by_month
cat("\nChannel 2: tourist nights (TCI, BBVA elasticity", params$tci_elasticity, ")\n")
print(data.frame(month = bm$month, shifted_days = bm$shifted_days, tci_cf = round(bm$tci_cf, 1),
                 tci_obs = round(bm$tci_obs, 1), tci_change_pct = round(100 * (bm$tci_obs / bm$tci_cf - 1)),
                 nights_lost = eur(bm$nights_lost),
                 share_of_nights_pct = round(100 * bm$nights_lost / bm$nights, 1),
                 loss_meur = round(bm$loss_eur / 1e6, 2)), row.names = FALSE)
cat(sprintf("Total: %s nights lost, %.1f%% of the nights of the months; %.2f million EUR\n",
            eur(joint$nights_lost), 100 * joint$nights_lost / sum(bm$nights), joint$loss_eur / 1e6))
print(transform(results, loss_eur = eur(loss_eur)), row.names = FALSE)

write.csv(bm, output_path("channel2_by_month.csv"), row.names = FALSE)
write.csv(results, output_path("channel2_results.csv"), row.names = FALSE)
