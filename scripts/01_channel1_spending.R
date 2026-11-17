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
d$delta <- temp_shift(d$date)
d$loss_eur <- channel1(d, d$delta)

by_wave <- aggregate(cbind(days = 1, nights, spending = nights * spend_per_night, loss_eur) ~ wave,
                     data = d, FUN = sum)
by_scenario <- sapply(params$delta_scenarios, function(s) sum(channel1(d, temp_shift(d$date, s))))

cat("\nChannel 1: spending of tourists present (coefficient", params$spend_coef, "% per C)\n")
print(transform(by_wave, nights = eur(nights), spending = eur(spending), loss_eur = eur(loss_eur)),
      row.names = FALSE)
cat("Total, central delta:", eur(sum(d$loss_eur)), "EUR\n")
cat("Delta low / central / high:", paste(eur(by_scenario), collapse = " / "), "EUR\n")

write.csv(d, output_path("channel1_daily.csv"), row.names = FALSE)
