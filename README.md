# SSMConstructor
A modeling language which uses mathematically familiar syntax to interface with SSMProblems.jl

## A Simple Example

Consider a local level trend model with two parameters `σε` and `ση`

```julia
@statespace function UC(ση, σε)
    # local level model
    y[t] = x[t] + η[t]
    x[t] = x[t-1] + ε[t]

    # noise
    ε[t] ~ Normal(0, σε)
    η[t] ~ Normal(0, ση)
end
```

The aim of this macro is to define a `LatentDynamics` and `ObservationProcess` from the above block.

Additionally, the above block defines a linear and Gaussian model; which is easy to detect by rearranging the AST such that the first expression is an addition call with subsequent layers containing the multiplication. In theory, we should be able to rearrange any affine transformation to this structure and define a respective linear system.

For conditionally linear Gaussian models, this again should be easy by only defining the scope of the first 2 layers of the AST.

## Things to Note

- In it's nascant state, this module will only define the recursive calls; therefore the user must define the initial draws
- I only intend for automatic marginalization on linear Gaussian models
- Compared to something like [OnlineSampling.jl](https://github.com/wazizian/OnlineSampling.jl), this macro refrains from symbolic execution, leading to an enormous gain in computation time.
- My demo cases in `tests/linear_models.jl` and `tests/conditionally_linear_models.jl` only consider scalar time series
