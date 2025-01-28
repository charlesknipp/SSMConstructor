using SSMConstructor

## UC-0 ####################################################################################

uc0_quote = quote
    # observation
    y[t] = τ[t] + ψ[t]

    # transition
    τ[t] = τ[t-1] + μ + η[t]
    ψ[t] = φ1*ψ[t-1] + φ2*ψ[t-2] + ε[t]

    # noise
    η[t] ~ Normal(0, ση)
    ε[t] ~ Normal(0, σε)
end

begin
    vars, body = varwalk(uc0_quote)
    obs, states, varmap = capture_vars(body)
    clean_expr(construct_transition(body, states, varmap))
end

begin
    vars, body = varwalk(uc0_quote)
    obs, states, varmap = capture_vars(body)
    clean_expr(construct_observation(body, obs, states, varmap))
end

## LOCAL LEVEL TREND #######################################################################

uc_quote = quote
    # local level model
    y[t] = x[t] + η[t]
    x[t] = x[t-1] + ε[t]

    # noise
    ε[t] ~ Normal(0, σε)
    η[t] ~ Normal(0, ση)
end

begin
    vars, body = varwalk(uc_quote)
    obs, states, varmap = capture_vars(body)
    clean_expr(construct_transition(body, states, varmap))
end

begin
    vars, body = varwalk(uc_quote)
    obs, states, varmap = capture_vars(body)
    clean_expr(construct_observation(body, obs, states, varmap))
end
