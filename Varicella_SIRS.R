
# 1) Load GrindR and define the SIRS model
library(Grind)

# SIRS model with loss of immunity rate "l":
#  dS/dt = l*R - beta*S*I
#  dI/dt = beta*S*I - gamma*I
#  dR/dt = gamma*I - l*R


modelSIRS <- function(t, state, parms) {
  with(as.list(c(state, parms)), {
    R <- N-S-I
    dS <- l*R - beta*S*I
    dI <- beta*S*I - gamma*I
    return(list(c(dS, dI)))
  })
}

# Here we assume that reactivation of VZV is loss of immunity:
# beta : infection rate
# gamma: recovery rate
# l: rate of loss of immunity
# N = starting population
# 1/l= 30 years
# 1/gamma=7 days of infectiousness
p <- c(beta = 8.78e-9, gamma = 0.143, l = 1 / (30 * 365), N= 6.24e7) 

# Initial conditions (S+I+R ~ N):
s <- c(S=6.24e7, I=1) 

# 3) Time simulation
# We'll run for tmax=82 years (in days), just to see if there's an endemic equilibrium
run(odes=modelSIRS, tmax=30000, tstep=30, table=TRUE)  

# 4) Phase-plane analysis in (S,I)

# We'll keep R in the background, but plot S vs. I in a plane.
# x=1, y=2 by default means "S" on x-axis and "I" on y-axis, but let's be explicit:
plane(odes=modelSIRS,  # use our model
      state=s, 
      parms=p,
      x="S", y="I",
      xmax = 6.2e7,
      ymax = 5e5,
      vector=TRUE,# show direction field
      main="Phase-plane for SIRS (S vs. I)")

end<-run(odes=modelSIRS, tmax=25000, tstep=1, traject = T)  
newton(odes=modelSIRS, plot=TRUE)
newton(odes=modelSIRS,state=end, plot=TRUE)

