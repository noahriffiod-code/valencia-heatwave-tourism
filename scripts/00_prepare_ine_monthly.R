# Monthly hotel travellers and nights for the city of Valencia, June-September
# 2026, from the INE Encuesta de Ocupacion Hotelera, table 2078 ("Viajeros y
# pernoctaciones por puntos turisticos"), tourist point 46250 Valencia.
#
# Input : data/raw/ine_2078_valencia_2026M06-M09.csv, the tab-separated file
#         exported from https://www.ine.es/jaxiT3/Tabla.htm?t=2078
#         (Latin-1, "." as thousands separator).
# Output: data/ine_eoh_valencia_monthly_2026.csv

raw <- read.delim("data/raw/ine_2078_valencia_2026M06-M09.csv", encoding = "latin1",
                  colClasses = "character", check.names = FALSE)
names(raw) <- c("point", "variable", "residence", "period", "value")

# "340.290" is 340290: drop the thousands separator before conversion
raw$value  <- as.numeric(gsub(".", "", raw$value, fixed = TRUE))
raw$month  <- sub("M", "-", raw$period)
raw$origin <- ifelse(grepl("Espa", raw$residence), "spain", "abroad")
raw$var    <- ifelse(grepl("^Pernoct", raw$variable), "hotel_nights", "hotel_travellers")

pick <- function(m, var, origin) raw$value[raw$month == m & raw$var == var & raw$origin == origin]
months <- sort(unique(raw$month))
out <- data.frame(month = months,
                  hotel_nights_spain        = sapply(months, pick, "hotel_nights", "spain"),
                  hotel_nights_abroad       = sapply(months, pick, "hotel_nights", "abroad"),
                  hotel_travellers_spain    = sapply(months, pick, "hotel_travellers", "spain"),
                  hotel_travellers_abroad   = sapply(months, pick, "hotel_travellers", "abroad"),
                  source = "INE, EOH table 2078, point 46250 Valencia")

write.csv(out, "data/ine_eoh_valencia_monthly_2026.csv", row.names = FALSE)
print(out[, -6], row.names = FALSE)
