# Reproduces all results of the tourism analysis. Open the .Rproj file (or
# set the working directory to the repository root) and run this file.
# Outputs are written to output/. Base R only; tested with R 4.3.3 and 4.4.3.

source("scripts/00_prepare_ine_monthly.R")
source("scripts/01_channel1_spending.R")
source("scripts/02_channel2_tci.R")
source("scripts/03_total.R")
source("scripts/04_did_length_of_stay.R")
