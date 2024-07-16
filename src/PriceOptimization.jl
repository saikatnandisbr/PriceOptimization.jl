module PriceOptimization

# includes
using LinearAlgebra
using JuMP
using GLPK

# code
# type definition
mutable struct PriceOptimLP

    # optimization solution
    objVal::Float64
    pct_change_price::Vector{Float64}

    # coefficients of LP formulation
    c::Vector{Float64}          # coefficients for revenue maximization objective
    A::Matrix{Float64}          # coeffiencits of less than equal inequalitiy constraints
    b::Vector{Float64}          # rhs of inequalitiy constratints

    """
            function PriceOptimLP()

    Default constructor.
    """

    function PriceOptimLP()
        self = new()

        self.objVal = 0.0

        return self
    end
end

"""
    function prep_lp_coefficients(optimObj::PriceOptimLP, current_price::Vector{Float64}, elasticity::Vector{Float64}, max_pct_change::Vector{Float64})

Prepare coefficients of LP formulation: c, A, b which are described in struct definition of PriceOptimLP.

optimObj:       PriceOptimLP object
current_price:  Vector of current prices
elasticity:     Vector of price elasticities
max_pct_change: Vector of max percentage change of price
"""

function prep_lp_coefficients(optimObj::PriceOptimLP, current_price::Vector{Float64}, elasticity::Vector{Float64}, max_pct_change::Vector{Float64})

    # number of products
    n_product = length(current_price)

    # coefficients for revenue maximization objective
    #    change in revenue ≈ current price * change in volume
    #    change in volume = elasticity * change in price = elasticity * current price * percentage change in price / 100
    optimObj.c = @. current_price * elasticity * current_price / 100

    # constraint coefficients
    #    - max allowed <= percentage change in price <= max allowed
    optimObj.A = collect(1:n_product) .== permutedims(collect(1:n_product))
    optimObj.A = vcat(optimObj.A, -1 * optimObj.A)

    # rhs of less than equal constraints
    optimObj.b = repeat(max_pct_change, 2)

    return nothing
end

"""
    function solve_lp(optimObj::PriceOptimLP)

Find optimal solution using LP.

optimObj:       PriceOptimLP object
"""

function solve_lp(optimObj::PriceOptimLP)

    # set up model object
    m = Model(GLPK.Optimizer)                       # model object
    n_product = length(optimObj.c)                  # number of variables = number of products
    @variable(m, x[1:n_product])                    # variables - percent change in price of product
    @objective(m, Max, dot(optimObj.c, x))          # maximize revenue
    @constraint(m, optimObj.A * x .<= optimObj.b)   # price change within allowed max

    # solve
    JuMP.optimize!(m)

    # solution
    optimObj.objVal = JuMP.objective_value(m)
    optimObj.pct_change_price = JuMP.value.(x)

end

end