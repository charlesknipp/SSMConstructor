function is_affine()
    #=
    I haven't confirmed whether this is necessary yet, I guess we will see
    =#
end

function restructure_muladd(expr, latent_states)
    #=
    use commutativity and associativity of (+, *, ℝ) such that addition calls are first, and
    multiplication is the next edge along the AST; this is theoretically easy.

    since we know the latent states and obsevations, again, defining constructors for linear
    models should be pretty easy; thus we have functions for calc_A, calc_Q, etc.

    alas, this is easier said than done...
    =#
end
