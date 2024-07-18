# price (P) as determinant of revenue (R) and gross profit (GP) via elasticity (E), cost (C), and intial quantity (Q)
#
#   ΔR = 1/2 . E . ΔP . ΔP
#   ΔGP = E . ΔP . ΔP + ΔP . (P . E + Q - C . E)

module PriceOptimization

# includes
using LinearAlgebra
using JuMP
using Ipopt

# code
# type definition
mutable struct PriceOptim

    # optimization solution
    objVal::Float64
    ΔP::Vector{Float64}

    # coefficients of LP formulation
    E::Vector{Float64}          # elsticities - coefficients of quadratic term in objective function
    QPE::Vector{Float64}        # Q + P x E - coefficients of linear term in objective function
    A::Matrix{Float64}          # coeffiencits of less than equal inequalitiy constraints
    B::Vector{Float64}          # rhs of inequalitiy constratints
    QPECE::Vector{Float64}      # Q + P x E - C x E - coefficients in linear term for GP constraint

    """
            function PriceOptimLP()

    Default constructor.
    """

    function PriceOptim()
        self = new()

        self.objVal = 0.0

        return self
    end
end

"""
    function prep_coefficients(optimObj::PriceOptim; E::Vector{Float64}, P::Vector{Float64}, C::Vector{Float64}, Q::Vector{Float64}, ΔP_pct_max::Vector{Float64})

Prepare coefficients of optimization model formulation.

optimObj:       PriceOptim object
E:              Vector of price elasticities
P:              Vector of current prices
C:              Vector of costs
Q:              Vector of current quantitites
ΔP_pct_max:     Vector of max percentage price changes
"""

function prep_optim_coefficients(optimObj::PriceOptim; E::Vector{Float64}, P::Vector{Float64}, C::Vector{Float64}, Q::Vector{Float64}, ΔP_pct_max::Vector{Float64})

    # number of products
    n_product = length(E)

    # coefficients for revenue maximization objective
    optimObj.E = E
    optimObj.QPE = Q .+ P .* E

    # coefficients for constraint for max allowed change in price
    optimObj.A = collect(1:n_product) .== permutedims(collect(1:n_product))
    optimObj.A = vcat(optimObj.A, -1 * optimObj.A)
    
    # rhs of less than equal constraints for max allowed change in price
    optimObj.B = repeat(P .* ΔP_pct_max ./ 100, 2)

    # coefficients needed to put constrating on gross profit (GP)
    optimObj.QPECE = optimObj.QPE .- C .* E

    return nothing
end

"""
    function solve_optim(optimObj::PriceOptim)

Find optimal solution.

optimObj:       PriceOptim object
"""

function solve_optim(optimObj::PriceOptim)

    # set up model object
    m = Model(Ipopt.Optimizer)                      # model object

    n_product = length(optimObj.E)                  # number of variables = number of products

    @variable(m, x[1:n_product])                    # variables - change in price of product

    # maximize change in revenue
    @objective(m, Max, x' * Diagonal(optimObj.E) * x  +  dot(x,  optimObj.QPE))          

    # price change within allowed limit
    @constraint(m, optimObj.A * x .<= optimObj.B)   

    # constraint to preserve GP
    @constraint(m, x' * Diagonal(optimObj.E) * x  +  dot(x,  optimObj.QPECE) >= 0)

    # solve
    JuMP.optimize!(m)

    # solution
    optimObj.objVal = JuMP.objective_value(m)
    optimObj.ΔP = JuMP.value.(x)

end

end