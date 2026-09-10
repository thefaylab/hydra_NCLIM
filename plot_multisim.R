# Routine
remove(list = ls())
gc()

library(tidyverse)
library(tools)
library(furrr)

options(scipen = 999)

Species <- c("Atlantic_cod", "Atlantic_herring", "Atlantic_mackerel", "Goosefish",
             "Haddock", "Silver_hake", "Spiny_dogfish", "Winter_flounder",
             "Winter_skate", "Yellowtail_flounder")

Folder <- "Sim_SSP126_runs_v2"
Suffix <- "mean10yrs"

Files <- list.files(Folder, pattern = "^sim")
StartYear <- 1978   # first year in the model

# Function for extracting a specific variable from the output file
get_par <- function(L, name) {
  is_header <- function(x) {
    tok <- strsplit(trimws(x), "\\s+")[[1]][1]
    nzchar(trimws(x)) && is.na(suppressWarnings(as.numeric(tok)))
  }
  hdr <- which(vapply(L, is_header, logical(1)))
  i <- grep(paste0("^", name), L)[1]
  j <- hdr[hdr > i][1]
  if (is.na(j)) j <- length(L) + 1
  block <- L[(i+1):(j-1)]
  block <- block[nzchar(trimws(block))]
  if (name == "SSB") {
    SSB <- as.matrix(read.table(textConnection(block), header = FALSE))[,-3]
    colnames(SSB) <- c("RngYear", "Species", "SSB")
    SSB <- as.data.frame(SSB)
    return(SSB)
  } else {
    lapply(block, function(x) as.numeric(strsplit(trimws(x), "\\s+")[[1]]))
  }
}

# SSB <- data.frame()
# for (file in Files) {
#   print(paste("Processing file", which(Files == file), "of", length(Files)))
#   L <- readLines(file.path(Folder, file))
#   # Get the SSB time series
#   SSB_i <- get_par(L, "SSB") %>% mutate(RunID = file_path_sans_ext(basename(file)), 
#                                         Year = StartYear + (RngYear-1))
#   SSB <- rbind(SSB, SSB_i)
# }

plan(multisession, workers = 6)

SSB <- future_map_dfr(Files, function(f) {
  L <- readLines(file.path(Folder, f))
  get_par(L, "SSB") %>%
    mutate(RunID = tools::file_path_sans_ext(basename(f)),
           Year  = StartYear + (RngYear - 1))
}, .progress = TRUE)
plan(sequential)

SSB <- SSB %>% mutate(Species = as.factor(Species))
levels(SSB$Species) <- Species

dir.create(file.path(Folder, "Output"), showWarnings = FALSE)
save(SSB, file = paste0(Folder, "/Output/SSBsims_", Suffix, ".rdata"))


# Plot
load(paste0(Folder, "/Output/SSBsims_", Suffix, ".rdata"))

pSSB <- SSB %>% ggplot(aes(x = Year, y = SSB / 1000, color = Species)) +
  geom_line(aes(group = RunID), alpha = .4, show.legend = FALSE) +
  geom_vline(aes(xintercept = 2020), linetype = 2, color = "tomato3") +
  geom_smooth(data = SSB %>% filter(Year >= 2020), aes(group = Species), color = "grey", show.legend = FALSE) +
  scale_y_continuous(name = "Spawning stock biomass (x1,000 metric tons)") +
  facet_wrap(~Species, scales = "free_y", nrow = 2) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle(paste("Version", Suffix))
ggsave(pSSB, file = paste0(Folder, "/Output/SSB_", Suffix, ".png"), dpi = 400, height = 4, width = 8)
