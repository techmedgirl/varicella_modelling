# 1) Load/Install GrindR and define the model

# devtools::install_bitbucket("stan_maree/Grind")
library(Grind)   # load GrindR

# Define the SIR model in Grind syntax:
model <- function(t, state, parms) {
  with(as.list(c(state, parms)), {
    dS <- -beta * S * I
    dI <-  beta * S * I - gamma * I
    dR <-  gamma * I
    return(list(c(dS, dI, dR)))
  })
}

# Example parameters for Varicella (Population of England and Wales)
p <- c(beta=8.78e-9,   # chosen so that R0 ~ 3.8 for a population 6.24e7
       gamma=0.143)    # ~7-day infectious period 

# Example initial state
s <- c(S=6.24e7, I=210.84, R=0)

# 3) Time simulation for 200 days, then plot
out <- run(tmax=200, tstep=0.1, table=TRUE)


# 4) Explore the effect of changing beta and gamma
# R0 of 10
p["beta"] <- 1.375e-8  # Increased beta
out2 <- run(tmax=200, tstep=0.1, table=TRUE)
#higher peak, fewer susceptibles

#reset beta:
# Example parameters for Varicella (Population of England and Wales)
p <- c(beta=8.78e-9,   # chosen so that R0 ~ 3.8 for a population 6.24e7
       gamma=0.143)    # ~7-day infectious period 

# gamma = 0.07 (14 day infection)
p["gamma"] <- 0.07 # decreased gamma
out3 <- run(tmax=200, tstep=0.1, table=TRUE)
#initial peak is similar but then it takes longer for population to recover 

# gamma = 0.3 (3 day infection)
p["gamma"] <- 0.3
out4 <- run(tmax=200, tstep=0.1, table=TRUE)

# 5) Phase-plane analysis (we only need 2 variables, say S and I)

#look at S and I plane:
#reset beta:
# Example parameters for Varicella (Population of England and Wales)
p <- c(beta=8.78e-9,   # chosen so that R0 ~ 3.8 for a population 6.24e7
       gamma=0.143)    # ~7-day infectious period 

s <- c(S=6.24e7, I=210.84, R=0)

plane(xmax=6.2e7, ymax=1e6, vector=TRUE,
      main="Phase-plane for SIR (S vs. I)")
eq_df <- newton(c(S=6.24e7, I=0, R=0), plot=TRUE)

plane(xmax=6.2e7, ymax=1e6, vector=TRUE, show = "S",
      main="Phase-plane for SIR (S vs. I)")
eq_df <- newton(c(S=6.24e7, I=0, R=0), plot=TRUE)



