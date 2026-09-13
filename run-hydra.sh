./hydra_sim -ind GB-input/Projection/proj.dat -ainp GB-input/Projection/Sim_SSP126/sim001.pin -nohess -maxfn 0  # works

# No temp. change, no fishing, no recdev+var
./hydra_sim -ind GB-input/Projection/proj_noclimate.dat -ainp GB-input/Projection/proj_norecdev_nofishing_qEst.pin -nohess -maxfn 0  # works

# Temp. change, no fishing, no recdev+var
./hydra_sim -ind GB-input/Projection/proj.dat -ainp GB-input/Projection/proj_norecvar_nofishing_qEst.pin -nohess -maxfn 0  # works

# Temp. change, no fishing, no recdev+var
./hydra_sim -ind GB-input/Projection/proj.dat -ainp GB-input/Projection/proj_norecvar_nofishing_qEst.pin -nohess -maxfn 0  # works
