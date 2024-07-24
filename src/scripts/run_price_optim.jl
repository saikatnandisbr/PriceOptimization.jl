# script to run price optimization

# imports
using .PriceOptimization
using CSV
using DataFrames
using Plots

# create optimizatio object
optimObj = PriceOptimization.PriceOptim()         # call default constructor

# prepare optimization model coefficients
df = CSV.File("data/kaggle/supermarket_elasticities_cat.csv") |> DataFrame

# E = [-30.0, -20.0, -8.0]
# P = [11.1, 20.7, 10.1]
# C = [0.8, 0.7, 0.9] .* P
# Q = [100.0, 89.0, 60.0]
# ΔP_pct_max = [30.0, 30.0, 30.0]

E = 100 .* df.slope                                     # elasticity
P = df.unit_price                                       # price
C = round.(P .* rand(0.6:0.8, length(E)), digits=2)     # assign cost to be in range of price
Q = Float64.(df.invoice_quantity)                       # quantity
ΔP_pct_max = fill(5.0, length(E))                       # max allowed percent price change

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

# choose a range for min GP change
#   range chosen in feasible range
for ΔGP in 160:10.0:260.0

    PriceOptimization.solve_optim(optimObj, ΔGP_min=ΔGP);

    push!(ΔR_pareto, optimObj.ΔR)
    push!(ΔGP_pareto, optimObj.ΔGP)
end

plot(ΔR_pareto, ΔGP_pareto, legend=:none, xticks=round.(ΔR_pareto, digits=0), yticks=round.(ΔGP_pareto, digits=0))
scatter!(ΔR_pareto, ΔGP_pareto, color=:blue, legend=:none)
xlabel!("Change in Revenue\n")
ylabel!("\nChange in Gross Profit")
title!("\nPareto Frontier for Price Optimization")
