# Top commands ----
# Create empty R application (no figures, data frames, packages, etc.)
# https://stackoverflow.com/questions/7505547/detach-all-packages-while-working-in-r
detachAllPackages <- function() {
        basic.packages <- c("package:stats","package:graphics","package:grDevices","package:utils","package:datasets","package:methods","package:base")
        package.list <- search()[ifelse(unlist(gregexpr("package:",search()))==1,TRUE,FALSE)]
        package.list <- setdiff(package.list,basic.packages)
        if (length(package.list)>0)  for (package in package.list) detach(package, character.only=TRUE)
        
}
detachAllPackages()

rm(list=ls(all=TRUE))

# FOLDERS
setwd("/Users/jonathanlatner/GitHub/latner_2017/")

data_files = "data_files/"

# LIBRARY
library(tidyverse)
library(survival)
library(texreg)
library(cmprsk)
library(kmi)
library(mlogit)

# Load data ----

df_reo <- read.csv(file = paste0(data_files, "test_compare_stata_r_small.csv"))

# Clean data ----

df_reo$outcome <- as.factor(df_reo$outcome)

# create stata like interval censored data
df_reo <- df_reo %>%
        group_by(id) %>%
        mutate(reo = ifelse(outcome == "2", yes = 1, no = 0),
               end = dur,
               start = lag(dur,1)) %>%
        filter(row_number()>1) %>%
        ungroup()

# Variables ----

vars_base <- "black + hispanic + other + putoption + calloption"

# Model Competing Risks: The Fine and Gray Model ----

model_cox <- coxph(as.formula(paste("Surv(start, dur, reo) ~ ",vars_base)), data=df_reo, id=id)

# Using survival package
df_data <- finegray(as.formula(paste("Surv(dur, outcome) ~ ",vars_base)), data = df_reo, etype="2")
model_fg_1 <- coxph(as.formula(paste("Surv(fgstart, fgstop, fgstatus) ~ ",vars_base)), data=df_data, weight=fgwt)

model_aj <- coxph(as.formula(paste("Surv(start, dur, outcome) ~ ",vars_base)), data=df_reo, id=id)
summary(model_aj)

# Using cmprsk package
model_fg_2 <- crr(df_reo$dur, 
                df_reo$outcome,
                df_reo[,c("black", "hispanic", "other", "putoption", "calloption")],
                failcode = "2", cencode = "0")

screenreg(list(model_cox,model_fg_1,model_fg_2,model_aj))

# Using kmi package - this is the only one that is similar to stata
imp.dat <- kmi(Surv(start, end, outcome != 0) ~ 1,data = df_reo, etype = outcome, id = id, failcode = 2)
kmi.sh.hap <- cox.kmi(as.formula(paste("Surv(start, end, outcome == 2) ~ ",vars_base)), imp.dat)

summary(kmi.sh.hap)

# compare to mlogit


mldata <- mlogit.data(df_reo, choice="outcome", shape ="wide", id.var = "id")

m <- mlogit(formula = outcome ~ 1 | black + hispanic + other + putoption + calloption, data = mldata)
summary(m)
