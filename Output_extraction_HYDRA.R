# Routine
remove(list = ls())
gc()

library(tidyverse)

options(scipen = 999)

Species <- c("Atlantic_cod", "Atlantic_herring", "Atlantic_mackerel", "Goosefish",
             "Haddock", "Silver_hake", "Spiny_dogfish", "Winter_flounder",
             "Winter_skate", "Yellowtail_flounder")

Folder <- ""
RepFile <- ifelse(Folder == "", "hydra_sim.rep", file.path(Folder, "hydra_sim.rep"))

L <- readLines(RepFile)

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

# Get the SSB time series
SSB <- get_par(L, "SSB") %>% mutate(Year = 1977+RngYear, Species = as.factor(Species))
levels(SSB$Species) <- Species


# Plot the time series by species
SSB %>% ggplot(aes(x = Year, y = SSB)) +
  geom_line() +
  facet_wrap(~Species, scales = "free") +
  theme_bw()

B0 <- SSB %>% group_by(Species) %>% summarise(B0 = mean(tail(SSB, 10)))



Start <- grep("^EstRec", L)
End <- grep("^EstFsize", L)
RecDataRaw <- L[(Start+1):(End-1)]
RecDataRaw <- RecDataRaw[grepl("^\\s*[-0-9]", RecDataRaw)]   # drop any blank/comment lines
RecData <- t(as.matrix(read.table(textConnection(RecDataRaw), header = FALSE)))
colnames(RecData) <- Species
RecData <- as.data.frame(RecData) %>% mutate(Year = 1979:2100)
RecDataLong <- reshape2::melt(RecData, variable.name = "Species", value.name = "Recruitment", id.vars = "Year")

Rec0 <- RecDataLong %>% group_by(Species) %>% summarise(Rec0 = mean(tail(Recruitment, 10)))

RecDataLong %>% ggplot(aes(x = Year, y = Recruitment)) +
  geom_line() +
  facet_wrap(~Species, scales = "free")
