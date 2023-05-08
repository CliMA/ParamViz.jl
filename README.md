drivers = Drivers(("x", "y"), (1, 1), ([-5, 5], [-5, 5]))

parameters = Parameters(("p1", "p2"), (1.0, 1.0), ([-5, 5], [-5, 5]))

constants = Constants(("c1", "c2"), (1.0, 1.0))

inputs = Inputs(drivers, parameters, constants)

function parameterisation(x, y, p1, p2, c1, c2) # most CliMA function are defined like that...
  return p1*sin(x) + p2*sin(y) + c1 + c2
end

function parameterisation(inputs::Inputs) # method for ParamViz
    x, y = inputs.drivers.values[1], inputs.drivers.values[2] 
    p1, p2 = inputs.parameters.values[1], inputs.parameters.values[2]
    c1, c2 = inputs.constants.values[1], inputs.constants.values[2]
    return parameterisation(x, y, p1, p2, c1, c2)
end

function parameterisation(drivers, parameters, constants) # method without names and values
  x, y = drivers[1], drivers[2]
  p1, p2 = parameters[1], parameters[2]
  c1, c2 = constants[1], constants[2]
  return parameterisation(x, y, p1, p2, c1, c2)
end


















To test locally:
first, clone the repo

```ubuntu
$ git clone https://github.com/CliMA/ParamViz.jl.git
```

then start a julia project in that repo, install deps

```ubuntu
$ cd ParamViz.jl
/ParamViz.jl$ julia --project
```

```jl
julia> ]
(ParamViz) pkg> instantiate
```

```jl
julia> using ParamViz
julia> using ClimaLSM, ClimaLSM.Soil.Biogeochemistry
julia> model_parameters = SoilCO2ModelParameters
julia> model_functions = Dict("CO2 production" => (d1, d2, p) -> microbe_source(d1, d2, 5.0, p),
                       "CO2 diffusivity" => co2_diffusivity)
julia> drivers_name = ["T_soil", "M_soil"]
julia> drivers_limit = ([273, 303], [0.0, 0.5])
julia> param_dashboard(model_parameters, model_functions, drivers_name, drivers_limit)
```

then open this URL in your browser 
http://localhost:9384/browser-display


This branch aims to use another formatting of parameter struct. 
The previous format will probably just be removed. 

NOTES:
Let's make it so param_dashboard needs 2 inputs: 

`model_parameters`

A Struct or Dict containing parameters, that includes drivers, their limits, and the step for slider. 
This will mean that user need to enter more info, but it makes things more flexible. 
Could later dispatch simpler methods. 

`model_function`

Let's make it just 1 function for now. As before, user need to specify which arguments of the function are driver 1 (axe x) and driver 2 (axe y). 

Also, as mentionned by Simon, widgets should be JSServe widget, and avoid WGLMakie widgets (works better)
