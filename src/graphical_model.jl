function graphical_model(vars, expr)
    labels = Dict(var => i for (i, var) in enumerate(vars))
    g = SimpleDiGraph()
    add_vertices!(g, length(vars))

    MacroTools.postwalk(expr) do ex
        if @capture(ex, var_ = terms_) || @capture(ex, var_ ~ terms_)
            for term in collect_vars(terms)
                add_edge!(g, labels[term], labels[var])
            end
        else
            return ex
        end
    end

    return g
end

function print_digraph(g, vars)
    varlist = [vars...]
    for edge in collect(edges(g))
        s = varlist[edge.src]
        d = varlist[edge.dst]
        println("$s => $d")
    end
end

#=
    I might fall back to the utilities in AbstractPPL from a couple years ago, where a graph
    is constructed with stochastic and logical nodes. The only change would be in the function
    representation of the node, which I will still keep as an expression.
    
    https://github.com/TuringLang/AbstractPPL.jl/blob/0f289206b22da5feee03218c157afb28706ed8ec/src/graphinfo.jl
=#

# this is using the VarInfo substituted expressions
function construct_model(expr::Expr)
    model = Dict()
    for ex in expr.args
        if @capture(ex, var_ = val_)
            inputs = SSMConstructor.collect_vars(val)
            func = MacroTools.prettify(Expr(:(->), (inputs...,), val))
            model[var] = (func, :logical)
        elseif @capture(ex, var_ ~ val_)
            inputs = SSMConstructor.collect_vars(val)
            func = MacroTools.prettify(Expr(:(->), (inputs...,), val))
            model[var] = (func, :stochastic)
        else
            error("improper model definition")
        end
    end
    return model
end

# potentially rewrite the AbstractPPL graphical model info... or just do what I did before

# also consider doing the above on the reduced form model, where non-latent states are
# substituted in...
