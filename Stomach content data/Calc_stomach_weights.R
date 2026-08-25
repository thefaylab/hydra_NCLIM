remove(list = ls())
gc()

library(tidyverse)
library(glmmTMB)

load("Stomach content data/NEFSC_SurveyData.Rdata")

# Length bin structure used in our current HYDRA model
Bins <- matrix(c(38, 18,	18,	18,	51,
                 18,	5,	5,	5,	11,
                 23,	5,	5,	5,	23,
                 32,	15,	15,	15,	46,
                 31,	13,	13,	13,	30,
                 19,	10,	10,	10,	35,
                 47,	14,	14,	14,	62,
                 26,	9,	9,	9,	33,
                 43,	13,	13,	13,	37,
                 22,	7,	7,	7,	24), nrow = 10, ncol = 5, byrow = TRUE)
rownames(Bins) <- sort(unique(SurveyData$SpeciesName))
BinCum <- t(apply(Bins,1,cumsum))

# Drop observations outside of our modeled max lengths in HYDRA
SurveyData <- SurveyData %>%
  filter(Length <= BinCum[cbind(match(SpeciesName, rownames(BinCum)), 5)])

# Data subset with stomach weight observations
StomachData <- SurveyData %>% drop_na(StomWgt)

# Fit a Tweedie GLMM to predict stomach weight from body length (power law relationship assumed)  
StomachData$logLength <- log(StomachData$Length)
M1 <- glmmTMB(StomWgt ~ logLength + (1 | SpeciesName), data = StomachData, 
              family = tweedie(link = "log"))
summary(M1)

# Check if random slopes are warranted
M2 <- glmmTMB(StomWgt ~ logLength + (logLength | SpeciesName),
              family = tweedie(link = "log"), data = StomachData)
AIC(M1, M2)
# --> a model with random intercepts AND random slopes performs better

StomachData$FittedM2 <- fitted(M2)

StomachData %>% ggplot(aes(x = Length, color = SpeciesName)) +
  geom_point(aes(y = StomWgt)) +
  geom_line(aes(y = FittedM2)) +
  theme_bw() +
  theme(legend.position = "bottom")

SurveyData$logLength <- log(SurveyData$Length)
SurveyData$predStomWgt <- predict(M2, newdata = SurveyData %>% select(SpeciesName, logLength), type = "response")

PredData <- SurveyData %>%
  group_by(SpeciesName) %>%
  reframe(Length = seq(min(Length, na.rm = TRUE),
                       max(Length, na.rm = TRUE),
                       length.out = 100)) %>%
  mutate(logLength = log(Length))
PredData$StomWgt <- predict(M2, newdata = PredData, type = "response")

p1 <- SurveyData %>% ggplot(aes(x = Length, y = StomWgt)) +
  geom_rug(sides = "b", color = "firebrick3", alpha = .15, length = unit(0.08, "npc")) +
  geom_point(data = StomachData, color = "grey60", alpha = .4, pch = 1, show.legend = FALSE) +
  geom_line(data = PredData, show.legend = FALSE) +
  theme_bw() +
  facet_wrap(~SpeciesName, scales = "free")
p1

# Now use the full survey dataset (including predicted stomach weights) to derive length bin-specific mean stomach weights

StomachWeights <- data.frame()
for (sp in 1:nrow(BinCum)) {
  SpName <- rownames(BinCum)[sp]
  SpData <- SurveyData %>% filter(SpeciesName == SpName & Length <= BinCum[SpName,5]) %>% 
    mutate(LengthBin = case_when(Length < BinCum[SpName,1] ~ "1",
                                 Length >= BinCum[SpName,1] & Length < BinCum[SpName,2] ~ "2",
                                 Length >= BinCum[SpName,2] & Length < BinCum[SpName,3] ~ "3",
                                 Length >= BinCum[SpName,3] & Length < BinCum[SpName,4] ~ "4",
                                 Length >= BinCum[SpName,4] ~ "5"))
  SpRes <- SpData %>% group_by(LengthBin) %>% 
    summarise(SpeciesName = SpeciesName[1],
              MeanWeight = round(mean(predStomWgt), 6), 
              n = length(which(!is.na(predStomWgt))),
              nObs = length(which(!is.na(StomWgt))))
  SpRes$Lower <- 0
  SpRes$Lower[2:5] <- BinCum[SpName,1:4]
  SpRes$Upper <- BinCum[SpName,]
  SpRes$Upper[5] <- min(BinCum[SpName,5], max(SpData$Length))
  StomachWeights <- rbind(StomachWeights, SpRes)
}

p2 <- p1 +
  geom_segment(data = StomachWeights, 
               aes(color = LengthBin, y = MeanWeight, x = Lower, xend = Upper),
               show.legend = FALSE) +
  labs(x = "Length (cm)", y = "Stomach weight (g)") + 
  theme(legend.position = "bottom",
        strip.text = element_text(size = 6))
ggsave(p2, file = "Stomach content data/Results_TweedieGLMM.png", dpi = 600, height = 4, width = 6, units = "in")


# Create txt file to directly paste into the .dat input file
for (sp in rownames(BinCum)) {
  SpResults <- matrix(rep(StomachWeights$MeanWeight[StomachWeights$SpeciesName == sp], 123), 
                    nrow = 123, ncol = 5, byrow = TRUE)
  FileName <- paste0("Stomach content data/Stomwgt tables for HYDRA/", sp, ".txt")
  write.table(SpResults, file = FileName, row.names = FALSE, col.names = FALSE)
}
