# Check: did hotel stays in Valencia shorten in July 2026 relative to
# northern Spanish cities? Difference-in-differences on log travellers,
# log length of stay and log nights (INE EOH, table 2078, hotels only):
#   gap(city) = log(July 2026) - mean(log(July 2022-2025))
#   DiD       = gap(Valencia) - mean(gap(controls))
# Since nights = travellers x stay, DiD(nights) = DiD(travellers) + DiD(stay).
# Descriptive check only: nothing is added to channel 2.
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

res <- data.frame(variable = c("travellers", "stay", "nights"))
res$did_pct     <- sapply(res$variable, function(v) 100 * (exp(did(v)) - 1))

# July 2026 temperature anomaly at station 8416 relative to 2022-2025
t_ref  <- read.csv(params$file_aemet_july_ref)
t_2026 <- read_aemet_daily("2026-07")
dT <- mean(t_2026$tmed) - mean(t_ref$tmed)

cat("\nDifference-in-differences, July", params$year, "vs", min(ref_years), "-", max(ref_years), "\n")
print(transform(res, did_pct = round(did_pct, 1)), row.names = FALSE)
cat(sprintf("July 2026 at station 8416: %+.2f C relative to July %d-%d\n", dT, min(ref_years), max(ref_years)))

write.csv(res, output_path("did_length_of_stay.csv"), row.names = FALSE)
