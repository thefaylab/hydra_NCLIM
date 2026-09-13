# Routine
remove(list = ls())
gc()

library(tidyverse)
library(tools)
library(furrr)
library(RColorBrewer)

options(scipen = 999)

# Specify input and output folders
Out <- "Simulation runs/Sim_runs_SSP126_nocovwt_rec"   # specify folder in which to store output (does not have to exist yet)
FolderPin <- "GB-input/Projection/Sim_SSP126_nocovwt_rec"   # folder in which the .pin files to be used is stored
DatFile <- "GB-input/Projection/proj_nocovwt_rec.dat"  # .dat file path 

PinFiles <- list.files(FolderPin, pattern = "^sim", full.names = TRUE)
Nsims <- length(PinFiles)

dir.create(Out, showWarnings = FALSE)
dir.create(paste0(Out, "/Log files"), showWarnings = FALSE)


for (i in 1:Nsims) {
  if (file.exists("hydra_sim.rep")) file.remove("hydra_sim.rep")
  Tag <- tools::file_path_sans_ext(basename(PinFiles[i]))
  LogFile <- paste0(Out, "/Log files/log_", Tag, ".txt")
  st <- system2("hydra_sim.exe",
                c("-ind", DatFile,
                  "-ainp", PinFiles[i],
                  "-nohess","-maxfn","0"),
                stdout = LogFile, stderr = LogFile)
  if (file.exists("HYDRA_~1.rep")) {
    file.rename("HYDRA_~1.rep", file.path(Out, paste0(Tag, ".rep")))
  } else message("run ", i, " failed")
}

# Define species names
Species <- c("Atlantic cod", "Atlantic herring", "Atlantic mackerel", "Goosefish",
             "Haddock", "Silver hake", "Spiny dogfish", "Winter flounder",
             "Winter skate", "Yellowtail flounder")

Files <- list.files(Out, pattern = ".rep")
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

plan(multisession, workers = 6)

SSB <- future_map_dfr(Files, function(f) {
  L <- readLines(file.path(Out, f))
  get_par(L, "SSB") %>%
    mutate(RunID = tools::file_path_sans_ext(basename(f)),
           Year  = StartYear + (RngYear - 1))
}, .progress = TRUE)
plan(sequential)

SSB <- SSB %>% mutate(Species = as.factor(Species))
levels(SSB$Species) <- Species

dir.create(file.path(Out, "Output"), showWarnings = FALSE)
save(SSB, file = paste0(Out, "/Output/SSBsims.rdata"))
