#./hydra_sim -ind hydra_sim_NOBA.dat -nohess -ainp hydra_sim_NOBA.pin 
#./hydra_sim -ind hydra_sim_NOBA.dat -nohess -ainp nu.pin
#./hydra_sim -ind hydra_sim_NOBA_5bin.dat -nohess -ainp nu.pin

#./hydra_sim -ind hydra_sim_NOBA_5bin.dat  -nohess -ainp hydra_sim_NOBA_5bin.pin 
#cp hydra_sim.r* hydra_sim.p* hydra_sim.b* hydra_sim.log results/NOBA05bin

#./hydra_sim -ind NOBA-input/hydra_sim_NOBA_5bin_0comp.dat -nohess -ainp NOBA-input/hydra_sim_NOBA_5bin_0comp.pin -maxfn 5000
#cp hydra_sim.r* hydra_sim.p* hydra_sim.b*  hydra_sim.log results/NOBA05bin_5k2 

#./hydra_sim -ind hydra_sim_NOBA_5bin_0comp.dat -nohess -ainp hydra_sim_NOBA_5bin2.pin
#cp hydra_sim.r* hydra_sim.p* hydra_sim.b*  hydra_sim.log results/NOBA05bin_2 

#./hydra_sim -ind hydra_sim_NOBA_10bin.dat -nohess  -ainp hydra_sim_NOBA_10bin.pin 
#cp hydra_sim.r* hydra_sim.p* hydra_sim.b* hydra_sim.log results/NOBA10bin

# ./hydra_sim -ind NOBA-input/hydra_sim_NOBA_10bin_0comp.dat -nohess -ainp NOBA-input/hydra_sim_NOBA_10bin_0comp.pin -maxfn 5000
# cp hydra_sim.r* hydra_sim.p* hydra_sim.b* hydra_sim.log results/NOBA10bin_5k2

#./hydra_sim -ind hydra_sim_NOBA_10bin_0comp.dat -nohess -ainp hydra_sim_NOBA_10bin2.pin 
#cp hydra_sim.r* hydra_sim.p* hydra_sim.b* hydra_sim.log results/NOBA10bin_2

#./hydra_sim -ind hydra_sim_NOBA_15bin.dat -nohess -ainp hydra_sim_NOBA_15bin.pin
#cp hydra_sim.r* hydra_sim.p* hydra_sim.b* hydra_sim.log results/15bin
#./hydra_sim -ind hydra_sim_NOBA_20bin.dat -nohess -ainp hydra_sim_NOBA_20bin.pin
#cp hydra_sim.r* hydra_sim.p* hydra_sim.b* hydra_sim.log results/20bin

# ./hydra_sim -ind hydra_sim_GB_5bin.dat -nohess -ainp hydra_sim_GB_5bin.pin
# cp hydra_sim.r* hydra_sim.p* hydra_sim.b* hydra_sim.log results/GB05bin
#-maxfn 30
# -dd 1
#./hydra_sim -ind GB-input/hydra_sim_GB_5bin_1978.dat -ainp GB-input/hydra_sim_GB_5bin_1978.pin -maxfn 1 -maxph 1 -nohess
#./hydra_sim -ind GB-temp.dat -ainp GB-temp.pin -maxfn 1 -maxph 1 -nohess
#./hydra_sim -ind GB-input/hydra_sim_GB_5bin_1978_inpN.dat -ainp GB-input/hydra_sim_GB_5bin_1978_inpN.pin -nohess
#./hydra_sim -ind GB-input/hydra_sim_GB_5bin_1978_inpN.dat -ainp hydra_sim.par -nohess -maxfn 2000
#./hydra_sim -ind GB-input/hydra_sim_GB_5bin_1978_inpN_noM1.dat -ainp GB-input/hydra_sim_GB_5bin_1978_inpN.pin -nohess
#./hydra_sim -ind GB-input/hydra_sim_GB_5bin_1978_inpN_noM1.dat -ainp hydra_sim.par -nohess
#./hydra_sim -ind GB-input/hydra_sim_GB_5bin_1978_10F.dat -ainp GB-input/hydra_sim_GB_5bin_1978_10F.pin -nohess
#./hydra_sim -ind GB-input/hydra_sim_GB_5bin_1978_10F.dat -ainp hydra_sim.par -nohess

./hydra_sim -ind GB-input/hydra_sim_2100.dat -ainp hydra_sim.pin -nohess   # works
./hydra_sim -ind GB-input/hydra_sim_2100_v2.dat -ainp hydra_sim.pin -nohess   # works
./hydra_sim -ind GB-input/hydra_sim_2100_v3.dat -ainp hydra_sim.pin -nohess   # works
./hydra_sim -ind GB-input/hydra_sim_2100_v4.dat -ainp hydra_sim.pin -nohess -maxfn 1 -maxph1  # works, diagnostics ok
./hydra_sim -ind GB-input/hydra_sim_2100_v4_MatEnvRec.dat -ainp hydra_sim.pin -nohess  # works, diagnostics ok
./hydra_sim -ind GB-input/hydra_sim_MatRecEnvGroPart.dat -ainp hydra_sim.pin -nohess  # works, but addition of any other env betas on growth leads to NaNs in some likelihoods
./hydra_sim -ind GB-input/hydra_sim_MatRecEnvGroPart_v2.dat -ainp hydra_sim.pin -nohess -maxfn 1  # works; growth, length bin, stomach weights updated for Cod, Silver Hake
./hydra_sim -ind GB-input/hydra_sim_MatRecEnvGroPart_v3.dat -ainp hydra_sim.pin -nohess -maxfn 1  # works; growth, length bin, stomach weights updated for YT Flounder 
./hydra_sim -ind GB-input/hydra_sim_MatRecEnvGroPart_v4.dat -ainp hydra_sim.pin -nohess -1   # works; growth and length bins (but not stomach weights!) updated for Herring
./hydra_sim -ind GB-input/hydra_sim_MatRecEnvGroPart_v5.dat -ainp hydra_sim.pin -nohess -maxfn 1   # works; growth, length bins and stomach weights updated for Haddock; growth/length bins updated for Mackerel, Goosefish, Spiny Dogfish
./hydra_sim -ind GB-input/hydra_sim_MatRecEnvGroPart_v6.dat -ainp hydra_sim.pin -nohess -maxfn 1   # works; growth and length bins updated for Winter Flounder; length bins updated for Winter Skate

./hydra_sim -ind GB-input/hydra_sim_trouble.dat -ainp no-recdevs.pin -nohess -maxfn 1   # NaNs in likelihoods

