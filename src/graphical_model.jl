function graphical_model(vars, expr)
    labels = Dict(var => i for (i, var) in enumerate(vars))
    g = SimpleDiGraph()
    add_vertices!(g, length(vars))

    MacroTools.postwalk(expr) do ex
        if @capture(ex, var_ = terms_) || @capture(ex, var_ ~ terms_)
            for term in collect_vars(terms)
                add_edge!(g, labels[var], labels[term])
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
