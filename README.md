# ParamViz.jl - dynamic parameterisation web app 
![ParamViz_1 0](https://github.com/CliMA/ParamViz.jl/assets/22160257/895db9ad-b736-4219-98e1-81ca4665dfee)

## Install ParamViz.jl: (unregistered for now)
```jl
julia> ]
pkg> add https://github.com/CliMA/ParamViz.jl
```
## Load package:
```jl
julia> using ParamViz
```
## Create structs:
```jl
julia> drivers = Drivers(("x", "y"), (1, 1), ([-15, 15], [-5, 5]))
julia> parameters = Parameters(("p1", "p2"), (1.0, 1.0), ([-5, 5], [-5, 5]))
julia> constants = Constants(("c1", "c2"), (1.0, 1.0))
julia> inputs = Inputs(drivers, parameters, constants)
julia> output = Output("output", [-12, 12])
```
## Create method:
```jl
julia> import ParamViz.parameterisation 
julia> function parameterisation(x, y, p1, p2, c1, c2) # order is important
         return p1*sin(x) + p2*sin(y) + c1 + c2
       end
```
## Call webapp:
```jl
julia> webapp(parameterisation, inputs, output)
```
## Open app in your browser: 
Open your favorite browser and go to the URL http://localhost:9384/browser-display
