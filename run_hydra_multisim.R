Out <- "Sim_SSP126_runs_survey_q"   # specify folder in which to store output
FolderPin <- "GB-input/Projection/Sim_SSP126_survey_q"

PinFiles <- list.files(FolderPin, pattern = "^sim", full.names = TRUE)
Nsims <- length(PinFiles)

dir.create(Out, showWarnings = FALSE)
dir.create(paste0(Out, "/Log files"), showWarnings = FALSE)


for (i in 1:Nsims) {
  if (file.exists("hydra_sim.rep")) file.remove("hydra_sim.rep")
  Tag <- tools::file_path_sans_ext(basename(PinFiles[i]))
  LogFile <- paste0(Out, "/Log files/log_", Tag, ".txt")
  st <- system2("hydra_sim.exe",
                c("-ind","GB-input/Projection/proj.dat",
                  "-ainp", PinFiles[i],
                  "-nohess","-maxfn","0"),
                stdout = LogFile, stderr = LogFile)
  if (file.exists("HYDRA_~1.rep")) {
    file.rename("HYDRA_~1.rep", file.path(Out, paste0(Tag, ".rep")))
  } else message("run ", i, " failed")
}
