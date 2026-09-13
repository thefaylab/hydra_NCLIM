# Routine
remove(list = ls())
gc()

library(tidyverse)
library(tools)
library(furrr)
library(RColorBrewer)

Out <- "Simulation runs/Sim_runs_SSP126_nocovwt_rec"   # specify folder in which the HYDRA (multi)sim output was stored
Suffix <- "SSP126_nocovwt_rec"  # a model version name that you want displayed on plots and plot file names 

# Plot
load(paste0(Out, "/Output/SSBsims.rdata"))
ProjStart <- 2020   # specify the first projection year

pSSB <- SSB %>% ggplot(aes(x = Year, y = SSB / 1000, color = Species)) +
  geom_line(aes(group = RunID), alpha = .4, show.legend = FALSE) +
  geom_vline(aes(xintercept = ProjStart), linetype = 2, color = "tomato3") +
  scale_y_continuous(name = "Spawning stock biomass (x1,000 metric tons)") +
  facet_wrap(~Species, scales = "free_y", nrow = 2) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle(paste("Version", Suffix))
if (length(unique(SSB$RunID)) > 1) pSSB <- pSSB + geom_smooth(data = SSB %>% filter(Year >= ProjStart), aes(group = Species), color = "grey", show.legend = FALSE) 

ggsave(pSSB, file = paste0(Out, "/Output/SSB_", Suffix, ".png"), dpi = 400, height = 4, width = 8)



# Comparison of two scenarios
load("Simulation runs/Sim_SSP126_runs_nocovwts/Output/SSBsims.rdata")
SSB1 <- SSB %>% mutate(CompGroup = "None")
load(paste0(Out, "/Output/SSBsims.rdata"))
SSB2 <- SSB %>% mutate(CompGroup = "Recruitment")
load(paste0(Out, "/Output/SSBsims.rdata"))
SSB3 <- SSB %>% mutate(CompGroup = "Growth")
load(paste0(Out, "/Output/SSBsims.rdata"))
SSB4 <- SSB %>% mutate(CompGroup = "Maturation")

SSBComp <- rbind(SSB1, SSB2, SSB3, SSB4) %>%
  mutate(#CompGroup = factor(CompGroup, levels = c("Yes", "No")),
         Group  = paste(Species, CompGroup),
         Group2 = paste(Species, CompGroup, RunID)) %>%
  arrange(CompGroup) %>%
  mutate(Group2 = factor(Group2, levels = unique(Group2)))

Palette <- brewer.pal(4, "Set2") #[c(9,3)]
Palette <- c("None" = "grey70", "Recruitment" = Palette[1], "Growth" = Palette[2], "Maturation" = Palette[3])  #"#FF6666"
#Palette <- c("No" = "grey15", "Yes" = alpha("grey75", .1))

Smoother <- 1   # add a smoother?
  
pSSBComp <- SSBComp %>% ggplot(aes(x = Year, y = SSB / 1000, color = CompGroup)) +
  geom_line(aes(group = Group2), alpha = .05, show.legend = FALSE) +
  geom_vline(aes(xintercept = (ProjStart-1)), linetype = 2, color = "tomato3") +
  scale_y_continuous(name = "Spawning stock biomass (x1,000 metric tons)") + 
  scale_color_manual(values = Palette, name = "Covwt's included for") +
  facet_wrap(~Species, scales = "free_y", nrow = 2) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom") +
  ggtitle("Comparison of trait inclusions under constant fishing and changing climate")
if (Smoother) {
  pSSBComp <- pSSBComp + 
  #geom_smooth(data = SSBComp %>% filter(Year >= ProjStart), aes(group = Group), color = "grey80", se = FALSE) +
  geom_smooth(data = SSBComp %>% filter(Year >= ProjStart), aes(group = Group, color = CompGroup), linewidth = .7, se = FALSE) 
}

ggsave(pSSBComp, file = "Simulation runs/Comparisons/SSB_comparison_traits.png", dpi = 600, height = 6, width = 12)
