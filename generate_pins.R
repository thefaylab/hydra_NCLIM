# Function for extracting a specific variable from the output file
get_par <- function(L, name) {
  i <- grep(paste0("^# ", name), L)[1]
  j <- grep("^#", L)
  j <- j[j > i][1]
  block <- L[(i+1):(j-1)]
  lapply(block, function(x) as.numeric(strsplit(trimws(x), "\\s+")[[1]]))
}

generate_pins <- function(N, TempFile, FitFile, Folder, RecAssumption) {
  for (iter in 1:N) {
    
  # Read in .pin template line-by-line
  L <- readLines(TempFile)
  Lfit <- readLines(FitFile)

  # EXTENDING THE RECRUITMENT TIME SERIES
  #set.seed(100)
  Rec_devs <- get_par(L, "recruitment_devs")
  Rec_devs_fit <- get_par(Lfit, "recruitment_devs")
  Rec_sigma <- get_par(L, "ln_recsigma")
  Nyears_proj <- length(Rec_devs[[1]])
  Nyears_fit <- length(Rec_devs_fit[[1]])
  if (RecAssumption == 1) {
    MeanProj <- rep(0, length(Rec_devs))
  } else if (RecAssumption == 2) {
    MeanProj <- sapply(Rec_devs_fit, function(x) mean(tail(x, 10)))
  } 
  
  # Generate the extended recruitment time series
  RecExt <- list()
  for (i in 1:length(Rec_devs)) {
    RecExt[[i]] <- c(Rec_devs_fit[[i]], rnorm(Nyears_proj-Nyears_fit, mean = MeanProj[i], sd = exp(Rec_sigma[[1]][i])))
  }
  
  # Insert the extended recruitment_devs block into the .par "table"
  From <- grep(paste0("^# ", "recruitment_devs"), L)[1]
  To <- grep("^#", L)
  To <- To[To > From][1]
  L[(From+1):(To-1)] <- sapply(RecExt, function(x) paste("", format(x, digits = 10, trim = TRUE), collapse = ""))
  
  # Store the extended .pin file for projection 
  Digits <- nchar(N)
  writeLines(L, paste0(Folder, "/sim", sprintf(paste0("%0", Digits, "d"), iter), ".pin"))
  
  }
}

TempFile = "GB-input/Projection/proj_survey_q.pin"   # template file (extended .pin file including projection period; e.g. generated with extend_par_pin)
FitFile = "ests/est_survey_q/hydra_sim.par"   # .pin/.par file from the model fitting (i.e. without projections) 
Folder = "GB-input/Projection/Sim_SSP126_survey_q"   # output folder
RecAssumption = 1

generate_pins(100, TempFile, FitFile, Folder, RecAssumption)
