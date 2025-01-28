struct VarInfo
    name::Symbol
    index::Symbol
    lag::Int
end

function VarInfo(name::Symbol, index::Symbol)
    return VarInfo(name, index, 0)
end

function VarInfo(name::Symbol, index::Expr)
    if index.head == :call
        if index.args[1] == :(-)
            return VarInfo(name, index.args[2], index.args[3])
        elseif index.args[1] == :(+)
            throw("no support for forward looking models")
        end
    end
end

function Base.show(io::IO, vi::VarInfo)
    if vi.lag == 0
        return print(io, "$(vi.name)[$(vi.index)]")
    else
        return print(io, "$(vi.name)[$(vi.index)-$(vi.lag)]")
    end
end

function lag(vi::VarInfo)
    return VarInfo(vi.name, vi.index, vi.lag+1)
end

function lead(vi::VarInfo)
    return VarInfo(vi.name, vi.index, vi.lag-1)
end

struct ModelInfo
    varlist::Vector{VarInfo}
    obslist::Vector{VarInfo}
    index::Symbol
    noise::Vector{VarInfo}
end

# remove nothings
function clean_expr(expr::Expr)
    not_nothing = Vector{Expr}()
    for arg in expr.args
        if arg isa Expr
            push!(not_nothing,arg)
        end
    end

    return Expr(:block, not_nothing...)
end

# restructure as expression of VarInfos and constants
function varwalk(expr::Expr)
    vars = Set{VarInfo}()
    clean_expr = MacroTools.postwalk(expr) do ex
        if @capture(ex, var_[idx_])
            # NOTE: this only captures ref calls where the first arg is a Symbol
            if ex.args[1] isa Symbol
                # does not account for stuff like θ[1] which will likely error
                vi = VarInfo(ex.args[1], ex.args[2])
                push!(vars, vi)
                return vi
            end
        else
            return ex
        end
    end
    return vars, clean_expr
end

# redefine expression walking across variable calls
symwalk!(list) = ex -> begin
    if ex isa Symbol
        ex != :I && push!(list,ex)
    end

    if ex isa Expr
        if ex.head == :call || ex.head == :macrocall
            map(symwalk!(list),ex.args[2:end])
        elseif ex.head == :ref
            ex.args[1] |> symwalk!(list)
        else
            map(symwalk!(list),ex.args)
        end
    end

    return list
end

symwalk(ex::Expr) = ex |> symwalk!(Set{Symbol}())

# collects all VarInfo objects in an expression
function collect_vars(expr::Expr)
    vars = Set{VarInfo}()
    MacroTools.postwalk(expr) do ex
        if ex isa VarInfo
            push!(vars, ex)
        else
            return ex
        end
    end
    return vars
end

# returns a dictionary denoting which RHS VarInfos are used to directly calculate the LHS 
function consolidate_assignment(expr::Expr)
    varmap = Dict{VarInfo,Set{VarInfo}}()
    MacroTools.postwalk(expr) do ex
        if @capture(ex, var_ = terms_) || @capture(ex, var_ ~ terms_)
            varmap[var] = collect_vars(terms)
        else
            return ex
        end
    end
    return varmap
end

# identifies which time series are latent states and observations
function capture_vars(expr::Expr)
    varmap = consolidate_assignment(expr)
    RHS = union(values(varmap)...)
    latent_states = Set(lead(vi, ) for vi in RHS if vi.lag > 0)

    # TODO: make sure this is well tested
    var_names = union(vi.name for vi in RHS)
    observations = Set(vi for vi in keys(varmap) if vi.name ∉ var_names)

    return observations, latent_states, varmap
end

# this handles latent states which don't explicitly transition
function gather_relevant(varlist, varmap)
    relevant_vars = Set{VarInfo}()
    identity_vars = Set{VarInfo}()
    for var in varlist
        if var in keys(varmap)
            push!(relevant_vars, varmap[var]...)
        else
            push!(identity_vars, var)
        end
    end
    return union(varlist, relevant_vars), identity_vars
end

# TODO: this is a temporary method for proof of concept's sake
function fill_identity(varlist)
    return [:($var = $var) for var in varlist]
end

# turn this into a "nearly" executable block of relevant equations
function create_process(expr, varlist)
    MacroTools.postwalk(expr) do ex
        if @capture(ex, var_ = val_)
            if var in varlist
                return ex
            else
                return nothing
            end
        elseif @capture(ex, var_ ~ val_)
            if var in varlist
                return :($var = rand($val))
            else
                return nothing
            end
        else
            return ex
        end
    end
end

function reduce_block(expr, varlist)
    # TODO: reduce the graph so there are length(varlist) of assingments in the block
    return expr
end

function construct_transition(expr, latent_states, varmap)
    relevant_vars, id_vars = gather_relevant(latent_states, varmap)
    clean_expr = Expr(
        :block,
        create_process(expr, relevant_vars).args...,
        fill_identity(id_vars)...
    )

    return reduce_block(clean_expr, latent_states)
end

function construct_observation(expr, observations, latent_states, varmap)
    relevant_vars = setdiff(
        union(observations, (varmap[obs] for obs in observations)...), latent_states
    )
    clean_expr = create_process(expr, relevant_vars)
    
    return reduce_block(clean_expr, observations)
end
