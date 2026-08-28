remove(list=ls())
gc()


# HERRING - SPRING SURVEY
SpringSVCAT_H <- read.csv("Data/NEFSC Spring Data/22561_UNION_FSCS_SVCAT.csv") %>% 
  filter(SVSPP == 32) 
SpringSVSTA_H <- read.csv("Data/NEFSC Spring Data/22561_UNION_FSCS_SVSTA.csv") %>% 
  mutate(YEAR = as.numeric(substr(CRUISE6, 1, 4))) %>% 
  select(-CRUISE6, -STATUS_CODE, -ID)

SpringData_H <- left_join(SpringSVSTA_H, SpringSVCAT_H, by = c("CRUISE", "STRATUM", "TOW", "STATION")) %>%
  mutate(EXPCATCHWT = replace_na(EXPCATCHWT, 0),
         EXPCATCHNUM = replace_na(EXPCATCHNUM, 0))

StrataAreas <- read.csv("Data/SVDBS_SupportTables/SVDBS_SVMSTRATA.csv") %>% 
  rename(STRATUM = stratum) %>% 
  select(STRATUM, stratum_name, stratum_area, strgrp_desc)

SpringData_H <- left_join(SpringData_H, StrataAreas, by = "STRATUM")

GBStrata <- unique(SpringData_H$STRATUM[grep("^GEO ", SpringData_H$stratum_name)])
GOMStrata <- unique(SpringData_H$STRATUM[grep("^GME ", SpringData_H$stratum_name)])

SpringData_H <- SpringData_H %>% filter(STRATUM %in% c(GBStrata, GOMStrata))

SpringCatches_H <- SpringData_H %>%
  group_by(YEAR, STRATUM) %>%
  summarise(MeanCatch = mean(EXPCATCHWT), stratum_area = stratum_area[1], .groups = "drop") %>%
  mutate(Contrib = MeanCatch * stratum_area)

pSpring_H <- SpringCatches_H %>%
  group_by(YEAR) %>%
  summarise(p = sum(Contrib[STRATUM %in% GBStrata]) / sum(Contrib)) %>% 
  mutate(Survey = "Spring")


# HERRING - FALL SURVEY
FallSVCAT_H <- read.csv("Data/NEFSC Fall Data/22560_UNION_FSCS_SVCAT.csv") %>% 
  filter(SVSPP == 32) 
FallSVSTA_H <- read.csv("Data/NEFSC Fall Data/22560_UNION_FSCS_SVSTA.csv") %>% 
  mutate(YEAR = as.numeric(substr(CRUISE6, 1, 4))) %>% 
  select(-CRUISE6, -STATUS_CODE, -ID)

FallData_H <- left_join(FallSVSTA_H, FallSVCAT_H, by = c("CRUISE", "STRATUM", "TOW", "STATION")) %>%
  mutate(EXPCATCHWT = replace_na(EXPCATCHWT, 0),
         EXPCATCHNUM = replace_na(EXPCATCHNUM, 0),
         STRATUM = as.numeric(STRATUM)) %>% 
  drop_na(STRATUM)

FallData_H <- left_join(FallData_H, StrataAreas, by = "STRATUM") 

GBStrata <- unique(FallData_H$STRATUM[grep("^GEO ", FallData_H$stratum_name)])
GOMStrata <- unique(FallData_H$STRATUM[grep("^GME ", FallData_H$stratum_name)])

FallData_H <- FallData_H %>% filter(STRATUM %in% c(GBStrata, GOMStrata))

FallCatches_H <- FallData_H %>%
  group_by(YEAR, STRATUM) %>%
  summarise(MeanCatch = mean(EXPCATCHWT), stratum_area = stratum_area[1], .groups = "drop") %>%
  mutate(Contrib = MeanCatch * stratum_area)

pFall_H <- FallCatches_H %>%
  group_by(YEAR) %>%
  summarise(p = sum(Contrib[STRATUM %in% GBStrata]) / sum(Contrib)) %>% 
  mutate(Survey = "Fall")

pAll_H <- rbind(pSpring_H, pFall_H)

pAll_H %>% ggplot(aes(x = YEAR, y = p)) +
  geom_line() +
  geom_smooth() +
  facet_wrap(~Survey)

pHerring <- pAll_H %>% group_by(Survey) %>% 
  summarise(MeanP = mean(p))
mean(pHerring$MeanP)
