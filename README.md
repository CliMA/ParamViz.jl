# ParamViz.jl - dynamic parameterisation web app 
![ParamViz_demo_0 2](https://github.com/CliMA/ParamViz.jl/assets/22160257/04e9d64b-2a07-4486-aa63-0434ea7533b1)

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
## Create methods:
```jl
julia> function parameterisation(x, y, p1, p2, c1, c2) # most CliMA function are defined like that...
  return p1*sin(x) + p2*sin(y) + c1 + c2
end

julia> function parameterisation(inputs::Inputs) # method for ParamViz
    x, y = inputs.drivers.values[1], inputs.drivers.values[2] 
    p1, p2 = inputs.parameters.values[1], inputs.parameters.values[2]
    c1, c2 = inputs.constants.values[1], inputs.constants.values[2]
    return parameterisation(x, y, p1, p2, c1, c2)
end

julia> function parameterisation(drivers, parameters, constants) # method without names and values
  x, y = drivers[1], drivers[2]
  p1, p2 = parameters[1], parameters[2]
  c1, c2 = constants[1], constants[2]
  return parameterisation(x, y, p1, p2, c1, c2)
end
```
## Call webapp:
```jl
julia> webapp(parameterisation, inputs, output)
```
## Open app in your browser: 
Open your favorite browser and go to the URL http://localhost:9384/browser-display
