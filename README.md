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
