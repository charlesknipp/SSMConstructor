module SSMConstructor

using SSMProblems
using Distributions
using MacroTools

using MacroTools: postwalk, prewalk

export @statespace, clean_expr, is_affine

# temporary exports for development purposes
export varwalk, capture_vars, construct_transition, construct_observation

include("ssm_macro.jl")

# main macro, which just passes the AST to another function
macro statespace(args...)
    model_definition = splitdef(args[end])
    vars, ex = varwalk(model_definition[:body])
    println(MacroTools.prettify(ex))

    params = Set(model_definition[:args])
    @assert isempty(symdiff(symwalk(ex), params)) "additional parameters not accounted for"
end

end
