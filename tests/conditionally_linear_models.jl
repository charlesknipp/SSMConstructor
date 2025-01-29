using SSMConstructor

## UC-SV ###################################################################################

ucsv_quote = quote
    # local level trend
    y[t] = x[t] + η[t]
    x[t] = x[t-1] + ε[t]

    # noise
    ε[t] ~ Normal(0, exp(logσε[t]))
    η[t] ~ Normal(0, exp(logση[t]))

    # volatility process
    logσε[t] = logσε[t-1] + hε[t]
    logση[t] = logση[t-1] + hη[t]

    # noise
    hε[t] ~ Normal(0, γ)
    hη[t] ~ Normal(0, γ)
end

begin
    vars, body = varwalk(ucsv_quote)
    obs, states, varmap = capture_vars(body)
    clean_expr(construct_transition(body, states, varmap))
end

begin
    vars, body = varwalk(ucsv_quote)
    obs, states, varmap = capture_vars(body)
    clean_expr(construct_observation(body, obs, states, varmap))
end
