# Tourism loss attributable to climate change: channel 1 + channel 2, by
# wave, with the bounds of delta and the sensitivities reported in the paper
# (sections 3.4, 4.3 and 4.6). Run after scripts 01 and 02.

source("R/parameters.R")
source("R/functions.R")

r <- rbind(read.csv(output_path("channel1_results.csv"), colClasses = c(wave = "character")),
           read.csv(output_path("channel2_results.csv"), colClasses = c(wave = "character")))
get <- function(ch, variant, wave = "Total")
  r$loss_eur[startsWith(r$channel, ch) & r$variant == variant & r$wave == wave]

waves <- c(as.character(params$waves_used), "Total")
total <- data.frame(
  wave      = waves,
  channel1  = sapply(waves, function(w) get("1", "central", w)),
  channel2  = sapply(waves, function(w) get("2", "central", w)), row.names = NULL)
total$total <- total$channel1 + total$channel2

variants <- data.frame(
  variant = c("Lower bound of delta", "Upper bound of delta",
              "Channel 1 with the aggregate coefficient (0.12%)",
              "Dew point held fixed in channel 2",
              "Channel 2 computed jointly for all waves"),
  total_eur = c(get("1", "delta_low") + get("2", "delta_low"),
                get("1", "delta_high") + get("2", "delta_high"),
                get("1", "coef_0.12") + get("2", "central"),
                get("1", "central") + get("2", "dew_point_fixed"),
                get("1", "central") + get("2", "joint")))

meur <- function(x) round(x / 1e6, 2)
cat("\nTourism loss attributable to climate change (million EUR)\n")
print(transform(total, channel1 = meur(channel1), channel2 = meur(channel2), total = meur(total)),
      row.names = FALSE)
cat(sprintf("Share of channel 2: %.0f%%\n", 100 * total$channel2[4] / total$total[4]))
cat("\nVariants, total of the three waves (million EUR)\n")
print(transform(variants, total_eur = meur(total_eur)), row.names = FALSE)

write.csv(total, output_path("tourism_total_by_wave.csv"), row.names = FALSE)
write.csv(variants, output_path("tourism_variants.csv"), row.names = FALSE)
