using CSV
using DataFrames
using Pipe

# weekly sales data used for price elasticity model
df_sales_weekly = CSV.File("data/kaggle/supermarket_weekly.csv") |> DataFrame

# category names
cat_map = Dict(id => cat for (cat, id) in eachrow(df_sales_weekly[:, [:category_id, :category_uid]] |> unique))

# parameter estimates from price elasticity model
df_params = CSV.File("data/kaggle/supermarket_hb_param_summaries.csv") |> DataFrame

df_params_global = @pipe df_params |> 
   select(_, :parameters, :mean) |>
   filter!(row -> row.parameters ∈ ("σ", "α", "β"), _)

df_params_cat = @pipe df_params |>
    select(_, :parameters, :mean) |>
    filter!(row -> occursin("_k", row.parameters), _) |>
    transform!(_, :parameters => (p -> tryparse.(Int, filter.(isdigit, String.(p)))) => :category_uid) |>
    filter!(row -> !isnothing(row.category_uid), _) |>
    transform!(_, :parameters => (p -> replace.(p, r"\[.*\]" => "") ) => :parameters) |>
    unstack(_, :parameters, :mean) |>
    transform!(_, :category_uid => (col -> [cat_map[uid] for uid in col]) => :category_name) |>
    select!(_, Cols(contains("category"), :))


insertcols!(df_params_cat, :α => df_params_global[df_params_global.parameters .== "α", :mean][1])
insertcols!(df_params_cat, :β => df_params_global[df_params_global.parameters .== "β", :mean][1])

# overall intercept and slope
df_params_cat.intercept = @. round(df_params_cat.α + df_params_cat.α_k, digits=4)
df_params_cat.slope = @. round(df_params_cat.β + df_params_cat.β_k, digits=4)

# add sales for latest week to subcat parameter table
df_cat_latest_week = combine(groupby(df_sales_weekly, :category_uid), :invoice_week => maximum => :invoice_week)

leftjoin!(df_cat_latest_week, select(df_sales_weekly, :category_uid, :invoice_week, :invoice_quantity, :unit_price), on=[:category_uid, :invoice_week])

leftjoin!(df_params_cat, df_cat_latest_week, on=:category_uid)

# predicted sales using parameter estimates above
# this is not true Bayesian prediction which needs to be done using posteriors
#    model in price elasticity module
#    η = @. (α + α_k[idx_k]) + (β + β_k[idx_k]) * x
#    y ~ MvNormal(η, σ ^ 2 * I)

df_params_cat.invoice_quantity_pred = @. round(df_params_cat.intercept + df_params_cat.slope * df_params_cat.unit_price, digits=0)

# save output
select!(df_params_cat, Not(r"α", r"β"))
CSV.write("data/kaggle/supermarket_elasticities_cat.csv", df_params_cat)
