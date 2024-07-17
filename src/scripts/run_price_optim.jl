# script to run price optimization

# imports
using .PriceOptimization

# create optimizatio object
optimObj = PriceOptimization.PriceOptimLP()         # call default constructor

# prepare LP coefficients
current_price = [11.1, 20.7, 10.1]
elasticity = [-0.3, -1.1, -0.8]
max_pct_change = [3.0, 3.0, 3.0]

PriceOptimization.prep_lp_coefficients(optimObj, current_price, elasticity, max_pct_change)

# solve LP
PriceOptimization.solve_lp(optimObj)

# solution
optimObj.objVal
optimObj.pct_change_price
