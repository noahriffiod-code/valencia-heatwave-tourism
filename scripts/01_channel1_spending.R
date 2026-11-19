# Channel 1: tourists present during a heatwave spend less.
# For each heatwave day: loss = nights x spending per night x 0.13% x delta,
# where delta is the attributable warming of Barnes et al. (2026).
# Run from the repository root.

source("R/parameters.R")
source("R/functions.R")

d <- daily_nights()
d$wave <- wave_of_day(d$date)
d <- d[!is.na(d$wave), ]
d$spend_per_night <- spend_per_night(d$share_abroad)

loss <- function(scenario = "central", coef = params$spend_coef)
  channel1(d, temp_shift(d$date, scenario), coef)

central <- tapply(loss(), d$wave, sum)
results <- data.frame(
  channel  = "1 spending",
  variant  = c(rep("central", 4), "delta_low", "delta_high", "coef_0.12"),
  wave     = c(names(central), rep("Total", 4)),
  loss_eur = c(central, sum(central), sum(loss("low")), sum(loss("high")),
               sum(loss(coef = params$spend_coef_aggregate))))

cat("\nChannel 1: spending of tourists present (coefficient", params$spend_coef, "% per C)\n")
print(transform(results, loss_eur = eur(loss_eur)), row.names = FALSE)

write.csv(results, output_path("channel1_results.csv"), row.names = FALSE)
