# script to run price optimization

# imports
using .PriceOptimization
using Plots

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
PriceOptimization.solve_optim(optimObj, ΔGP_min=0.0)

# solution
optimObj.ΔR
optimObj.ΔGP
optimObj.ΔP

# percent change in price suggested
optimObj.ΔP ./ P .* 100

# pareto frontier
ΔR_pareto = Vector{Float64}()
ΔGP_pareto = Vector{Float64}()

for ΔGP in -30.0:5.0:30.0
    PriceOptimization.solve_optim(optimObj, ΔGP_min=ΔGP);

    push!(ΔR_pareto, optimObj.ΔR)
    push!(ΔGP_pareto, optimObj.ΔGP)
end

plot(ΔR_pareto, ΔGP_pareto, legend=:none, xticks=round.(ΔR_pareto, digits=0), yticks=round.(ΔGP_pareto, digits=0))
scatter!(ΔR_pareto, ΔGP_pareto, color=:blue, legend=:none)
xlabel!("Change in Revenue")
ylabel!("Change in Gross Profit")
title!("Pareto Frontier for Price Optimization")
