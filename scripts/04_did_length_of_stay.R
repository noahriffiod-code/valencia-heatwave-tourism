# Check: did hotel stays in Valencia shorten in July 2026 relative to
# northern Spanish cities? Difference-in-differences on log travellers,
# log length of stay and log nights (INE EOH, table 2078, hotels only):
#   gap(city) = log(July 2026) - mean(log(July 2022-2025))
#   DiD       = gap(Valencia) - mean(gap(controls))
# Since nights = travellers x stay, DiD(nights) = DiD(travellers) + DiD(stay).
# Inference by placebo: each control city is treated in turn (Abadie,
# Diamond and Hainmueller 2010).
# Not additive to channel 2, whose elasticity already covers length of stay.
# Run from the repository root.

source("R/parameters.R")
source("R/functions.R")

treated   <- "Valencia"
ref_years <- 2022:2025   # post-COVID reference years
controls  <- c("Bilbao", "Donostia-San Sebasti\u00e1n", "Santander", "Gij\u00f3n", "Oviedo", "Coru\u00f1a",
               "Vigo", "Santiago De Compostela", "Pamplona", "Vitoria-Gast\u00e9iz", "Logro\u00f1o")

ine <- read.csv(data_path("ine_eoh_july_cities_2010_2026.csv"), stringsAsFactors = FALSE, encoding = "UTF-8")
ine$travellers <- ine$travellers_spain + ine$travellers_abroad
ine$nights     <- ine$nights_spain + ine$nights_abroad
ine$stay       <- ine$nights / ine$travellers

gap <- function(var, city) {
  x <- ine[ine$city == city, ]
  log(x[[var]][x$year == params$year]) - mean(log(x[[var]][x$year %in% ref_years]))
}
did <- function(var, tr = treated, ctrl = controls)
  gap(var, tr) - mean(sapply(ctrl, function(city) gap(var, city)))
placebo <- function(var)
  sapply(controls, function(city) did(var, city, setdiff(controls, city)))

res <- data.frame(variable = c("travellers", "stay", "nights"))
res$did_pct     <- sapply(res$variable, function(v) 100 * (exp(did(v)) - 1))
res$placebo_min <- sapply(res$variable, function(v) 100 * (exp(min(placebo(v))) - 1))
res$placebo_max <- sapply(res$variable, function(v) 100 * (exp(max(placebo(v))) - 1))
res$p_placebo   <- sapply(res$variable, function(v) mean(abs(c(placebo(v), did(v))) >= abs(did(v))))

# July 2026 temperature anomaly at station 8416 relative to 2022-2025
t_ref  <- read.csv(params$file_aemet_july_ref)
t_2026 <- read_aemet_daily("2026-07")
dT <- mean(t_2026$tmed) - mean(t_ref$tmed)

# Nights lost through shorter stays, counted only if stays are shorter and
# the effect stands out from the placebos (p <= 0.10); scaled to the
# attributable share by delta / dT (linear assumption).
july <- daily_nights()
july <- july[format(july$date, "%Y-%m") == "2026-07", ]
effect <- did("stay")
effect_used <- if (effect < 0 && res$p_placebo[res$variable == "stay"] <= 0.10) effect else 0
nights_lost <- sum(july$nights) * (exp(-effect_used) - 1)
hw_days <- july$date[!is.na(wave_of_day(july$date))]
delta_hw <- mean(temp_shift(hw_days))
loss_cc <- nights_lost * delta_hw / dT * spend_per_night(july$share_abroad[1])

cat("\nDifference-in-differences, July", params$year, "vs", min(ref_years), "-", max(ref_years), "\n")
print(transform(res, did_pct = round(did_pct, 1), placebo_min = round(placebo_min, 1),
                placebo_max = round(placebo_max, 1), p_placebo = round(p_placebo, 2)), row.names = FALSE)
cat(sprintf("July 2026 at station 8416: %+.2f C relative to July %d-%d\n", dT, min(ref_years), max(ref_years)))
cat("Loss from shorter stays attributable to climate change:", eur(loss_cc), "EUR\n")

write.csv(res, output_path("did_length_of_stay.csv"), row.names = FALSE)
