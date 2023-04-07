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
