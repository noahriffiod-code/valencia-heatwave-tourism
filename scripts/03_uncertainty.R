# Total tourism loss (channels 1 + 2): sensitivity to the attributable
# warming, results by wave, and joint Monte Carlo uncertainty.
#
# Monte Carlo as in Gasparrini and Leone (2014, BMC Med Res Methodol 14:55):
# parameters are drawn from their distributions, losses recomputed, and the
# 2.5th and 97.5th percentiles reported. The same draw of delta and of the
# share of foreign tourists is used in both channels.
# Run from the repository root.

source("R/parameters.R")
source("R/functions.R")

d <- daily_nights()
d$wave <- wave_of_day(d$date)
d <- d[!is.na(d$wave), ]
weather <- read_tci_weather()

# ---------------------------------------------------------------------------
# Sensitivity to delta (other parameters at central values)
# ---------------------------------------------------------------------------
sens <- t(sapply(params$delta_scenarios, function(s) {
  c1 <- sum(channel1(d, temp_shift(d$date, s)))
  c2 <- channel2(weather, scenario = s)$loss_eur
  c(channel1 = c1, channel2 = c2, total = c1 + c2)
}))

cat("\nDelta by month (C):\n")
mid <- as.Date(paste0(params$months, "-15"))
print(round(sapply(params$delta_scenarios, function(s) setNames(delta_of_day(mid, s), params$months)), 2))
cat("\nLoss by delta scenario (EUR):\n")
print(format(as.data.frame(round(sens)), big.mark = ","), quote = FALSE)

# ---------------------------------------------------------------------------
# By wave (central delta)
# ---------------------------------------------------------------------------
w <- params$waves[match(params$waves_used, params$waves$wave), c("wave", "start", "end")]
w$channel1 <- sapply(w$wave, function(v) sum(channel1(d[d$wave == v, ], temp_shift(d$date[d$wave == v]))))
w$channel2 <- sapply(w$wave, function(v) channel2(weather, waves = v)$loss_eur)
w$total <- w$channel1 + w$channel2
cat("\nBy wave (central delta, EUR):\n")
print(transform(w, channel1 = eur(channel1), channel2 = eur(channel2), total = eur(total)), row.names = FALSE)
cat("Sum over waves:", eur(sum(w$total)), "; joint calculation:", eur(sens["central", "total"]), "\n")

# ---------------------------------------------------------------------------
# Monte Carlo
# ---------------------------------------------------------------------------
set.seed(params$seed)
n <- params$n_sim
draws <- data.frame(
  beta  = rnorm(n, params$tci_elasticity, params$tci_elasticity / params$tci_elasticity_tval),
  coef  = runif(n, params$spend_coef_min, params$spend_coef_max),
  z     = rnorm(n),   # common to all months
  share = runif(n, -params$share_abroad_range, params$share_abroad_range))
draws$delta_july <- delta_of_day(rep(as.Date("2026-07-15"), n), z = draws$z)

draws$channel1 <- draws$channel2 <- NA_real_
for (i in seq_len(n)) {
  draws$channel1[i] <- sum(channel1(d, temp_shift(d$date, z = draws$z[i]), draws$coef[i], draws$share[i]))
  draws$channel2[i] <- channel2(weather, z = draws$z[i], beta = draws$beta[i],
                                share_shift = draws$share[i])$loss_eur
}
draws$total <- draws$channel1 + draws$channel2

summ <- function(x) c(median = median(x), p2.5 = unname(quantile(x, 0.025)), p97.5 = unname(quantile(x, 0.975)))
mc <- round(rbind(channel1 = summ(draws$channel1), channel2 = summ(draws$channel2), total = summ(draws$total)))
cat("\nMonte Carlo,", n, "draws (EUR):\n")
print(format(mc, big.mark = ","), quote = FALSE)
cat("Mean total:", eur(mean(draws$total)), "EUR\n")
cat(sprintf("July delta drawn: median %.2f C, 95%% range %.2f-%.2f C\n", median(draws$delta_july),
            quantile(draws$delta_july, 0.025), quantile(draws$delta_july, 0.975)))
rank_cor <- sapply(draws[, c("beta", "coef", "delta_july", "share")],
                   function(p) cor(p, draws$total, method = "spearman"))
cat("Spearman correlation with total loss:\n")
print(round(rank_cor, 2))

write.csv(data.frame(scenario = rownames(sens), sens), output_path("sensitivity_delta.csv"), row.names = FALSE)
write.csv(w, output_path("loss_by_wave.csv"), row.names = FALSE)
write.csv(draws, output_path("monte_carlo_draws.csv"), row.names = FALSE)

png(output_path("monte_carlo_total.png"), width = 1600, height = 1100, res = 200)
hist(draws$total / 1e6, breaks = 50, col = "grey80", border = "white", main = "",
     xlab = "Tourism loss attributable to climate change (million EUR)")
abline(v = quantile(draws$total / 1e6, c(0.025, 0.5, 0.975)), lty = c(2, 1, 2), col = "firebrick")
invisible(dev.off())
