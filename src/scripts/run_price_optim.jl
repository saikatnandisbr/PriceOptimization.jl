# script to run price optimization

# imports
using .PriceOptimization

# create optimizatio object
optimObj = PriceOptimization.PriceOptim()         # call default constructor

# prepare optimization model coefficients
E = [-30.0, -20.0, -8.0]
P = [11.1, 20.7, 10.1]
C = [0.8, 0.7, 0.9] .* P
Q = [100.0, 89.0, 60.0]
ΔP_pct_max = [30.0, 30.0, 30.0]

PriceOptimization.prep_optim_coefficients(optimObj, E=E, P=P, C=C, Q=Q, ΔP_pct_max=ΔP_pct_max)

# solve optimization problem
PriceOptimization.solve_optim(optimObj)

# solution
optimObj.objVal
optimObj.ΔP

# percent change in price suggested
optimObj.ΔP ./ P .* 100
