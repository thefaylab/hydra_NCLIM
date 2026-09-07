# Routine
remove(list = ls())
gc()

library(tidyverse)

options(scipen = 999)

# Which (output) file to read? 
File <- "ests/hydra_sim.par"

# Read it it line-by-line
L <- readLines(File)

# Function for extracting a specific variable from the output file
get_par <- function(L, name) {
  i <- grep(paste0("^# ", name), L)[1]
  j <- grep("^#", L)
  j <- j[j > i][1]
  block <- L[(i+1):(j-1)]
  lapply(block, function(x) as.numeric(strsplit(trimws(x), "\\s+")[[1]]))
}

# Get F deviations by fleet
F_devs <- get_par(L, "F_devs")
N_years <- sapply(F_devs, function(x) length(x))[1]
N_add <- 123-N_years
(RecentF <- sapply(F_devs, function(x) mean(tail(x, 10))))

# Generate the extended F_devs series
F_Ext <- list()
for (i in 1:length(F_devs)) {
  F_Ext[[i]] <- c(F_devs[[i]], rep(RecentF[i], N_add))
}

# Visualize the 3 fleet series
PlotF <- data.frame(Year = rep(1978:2100, 3),
                    Fleet = as.factor(rep(c(1,2,3), each = length(F_Ext[[1]]))),
                    F_est = c(F_Ext[[1]], F_Ext[[2]], F_Ext[[3]]))
PlotF %>% ggplot(aes(x = Year, y = F_est, color = Fleet)) +
  geom_line()
# --> averaging across the most recent 10 years is probably better than just 5 (especially for fleet 3)

# Replace the extended F series block in the .par "table"
i <- grep(paste0("^# ", "F_devs"), L)[1]
j <- grep("^#", L)
j <- j[j > i][1]

L[(i+1):(j-1)] <- sapply(F_Ext, function(x) paste("", format(x, digits = 10, trim = TRUE), collapse = ""))



# EXTENDING THE RECRUITMENT TIME SERIES
set.seed(100)
Rec_devs <- get_par(L, "recruitment_devs")
Rec_sigma <- get_par(L, "ln_recsigma")
N_years_Rec <- length(Rec_devs[[1]])

# Generate the extended recruitment time series
RecExt <- list()
for (i in 1:length(Rec_devs)) {
  RecExt[[i]] <- c(Rec_devs[[i]], rnorm(122-N_years_Rec, mean = 0, sd = exp(Rec_sigma[[1]][i])))
}

# Insert the extended recruitment_devs block into the .par "table"
i <- grep(paste0("^# ", "recruitment_devs"), L)[1]
j <- grep("^#", L)
j <- j[j > i][1]
L[(i+1):(j-1)] <- sapply(RecExt, function(x) paste("", format(x, digits = 10, trim = TRUE), collapse = ""))

# Store the extended .pin file for projection 
writeLines(L, "GB-input/Projection/hydra_NCLIM_proj.pin")
