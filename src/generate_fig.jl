#= step by step for code dive in
using GLMakie # can't be WGLMakie because bug https://github.com/MakieOrg/Makie.jl/issues/2575
using SparseArrays
using Statistics
using ClimaLSM, ClimaLSM.Soil.Biogeochemistry
include(joinpath(pkgdir(ClimaLSM), "parameters", "create_parameters.jl")) 
include("src/fun_discretisation.jl")

model_parameters = SoilCO2ModelParameters
model_functions = Dict("CO2 production" => (d1, d2, p) -> microbe_source(d1, d2, 5.0, p),
                       "CO2 diffusivity" => co2_diffusivity)
drivers_name = ["T_soil", "M_soil"]
drivers_limit = ([273, 303], [0.0, 0.5])
=#

#= Test with vegetation format, e.g., Penman Monteith
using ClimaLSM

ClimaLSM.Canopy.medlyn_conductance # the function
ClimaLSM.Canopy.medlyn_term # term needed for function
ClimaLSM.Canopy.MedlynConductanceParameters # default values for Drel, g0 and g1. Drel is a constant
=#


#= get names of arguments of a function f
f(x,y,z) = xyz # for example
ms = collect(methods(f)) 
function method_argnames(m::Method) # from https://github.com/JuliaLang/julia/blob/master/base/methodshow.jl
    argnames = ccall(:jl_uncompress_argnames, Vector{Symbol}, (Any,), m.slot_syms)
    isempty(argnames) && return argnames
    return argnames[1:m.nargs]
end
method_argnames(last(ms))[2:end]
=#

# maybe by default, x axis is 1st argument, y axis is 2nd argument. 
# add a menu to select x axis and y axis (from argument list). 

# Arguments of param_dashboard: Model (a function...)
# Optional argument of param_dashboard: Range (a Tuple, e.g., ([min, max], [min, max], ...))

# if no Range given, just do val/2:val/4:val*2

# Need starting values too! Should this be optional arg as well? These starting values need to be within Range...

# Try with ClimaLSM.Canopy.penman_monteith

# First, let's redefine function without constants

# Lv = 2453 MJ m−3 # Volumetric latent heat of vaporization
# cp = 1005 J/kg-K # specific heat of air at constant pressure
# Δ =  125 Pa K−1
# ρa = 1.293 kg m−3 # dry air density 
# γ = 66 Pa K−1 # Psychrometric constant

#= ga is calculated...
conditions = surface_fluxes(atmos, canopy, Y, p, t0) #Per unit m^2 of leaf
r_ae = 1 / (conditions.Ch * abs(atmos.u(t0))) # s/m
ga = 1 / r_ae
=#

# penman_monteith(Rn, G, VPD, ga, gs) -> ClimaLSM.Canopy.penman_monteith(125, Rn, G, 1.293, 1005, VPD, ga, 66, gs, 2453)

# Maybe try another function... 

struct drivers
  x
  y
end


function testf((x, y), (p1, p2), (c1)) # testf(drivers(x, y), parameters(p1, p2), constants(c1))
    p1*sin(x) + p2*sin(y) + c1
end

# for param_dashboard, give functions as f(drivers, parameters, constants)
# and Ranges(drivers, parameters) 


# make a function to make it work with param_dashboard(testf, ([-5 5], [-5 5], [-5 5], [-5 5]))
# for now, let's make it that first argument is x, second argument is y
# as param_dashboard(Model, Ranges)
# intial value will be middle of Range

"""
    param_dashboard(model_parameters, model_functions, drivers_name, drivers_limit)

Generates an interactive web dashboard of the parameterization functions of a model. 
"""
function param_dashboard(model_parameters, model_functions, drivers_name, drivers_limit) 
  # Create a Figure and its layout: a Menu, a 3D axis, and 2 2D axis 
  fig = Figure(resolution = (1200, 1200))
  menu_opt = collect(keys(model_functions)) 
  menu = Menu(fig[1,1:2], options = menu_opt); m = menu.selection
  ax3D = Axis3(fig[2,2], xlabel = drivers_name[1], ylabel = drivers_name[2])#, alignmode = Outside(50))
  ax_d1 = Axis(fig[3,1], xlabel = drivers_name[1])#, alignmode = Outside(50))
  ax_d2 = Axis(fig[3,2], xlabel = drivers_name[2])#, alignmode = Outside(50))

  # Get SliderGrid args for parameters
  FT = Float64 
  earth_param_set = create_lsm_parameters(FT)
  params = model_parameters{FT}(; earth_param_set = earth_param_set)
  labels = ["$(s)" for s in fieldnames(model_parameters)[1:end-1]] # without earth_param_set
  ranges = [(val/2 : val/4: val*2, val) for val in [getfield(params, i) for i in fieldnames(model_parameters)[1:end-1]]]
  sliders = [(label = label, range = range, startvalue = startvalue) for (label, (range, startvalue)) in zip(labels, ranges)]

  # Get SliderGrid args for drivers
  startval_d = [mean(drivers_limit[1]), mean(drivers_limit[2])]  
  ranges_d = [(range(drivers_limit[i][1], drivers_limit[i][2], 31), startval_d[i]) for i in 1:2]
  sliders_d = [(label = label, range = range, startvalue = startvalue) for (label, (range, startvalue)) in zip(drivers_name, ranges_d)]
  
  # Layouting sliders
  s_layout = GridLayout()
  param_title = s_layout[1,1] = Label(fig, "Parameters")
  sg = s_layout[2,1] = SliderGrid(fig, sliders..., width = 250)
  param_title_d = s_layout[1,2] = Label(fig, "Drivers")
  sg_d = s_layout[2,2] = SliderGrid(fig, sliders_d..., width = 220)
  fig.layout[2,1] = s_layout

  # Get Observable and their values from SliderGrid
  sd = Dict(i => sg.sliders[i].value for i in 1:length(sliders))
  sd_v = Dict(i => sg.sliders[i].value[] for i in 1:length(sliders))
  sd_d = Dict(i => sg_d.sliders[i].value for i in 1:length(sliders_d))
  sd_v_d = Dict(i => sg_d.sliders[i].value[] for i in 1:length(sliders_d))

  # Create struct of parameters from SliderGrid values
  param_keys = Symbol.(labels) 
  s = collect(values(sort(sd_v)))
  args = (; zip(param_keys, s)...)
  parameters = Observable(model_parameters{FT}(; args..., earth_param_set = earth_param_set)) 

  # Plot 3D surface of model(drivers, params)
  x = @lift(mat(drivers_limit[1], drivers_limit[2], 30, model_functions[$m], $parameters)[1]) 
  y = @lift(mat(drivers_limit[1], drivers_limit[2], 30, model_functions[$m], $parameters)[2])
  z = @lift(mat(drivers_limit[1], drivers_limit[2], 30, model_functions[$m], $parameters)[3])
  surface!(ax3D, x, y, z, colormap = Reverse(:Spectral), transparency = true, alpha = 0.2, shading = false)

  # Plot 2D lines of model(drivers, params)
  x_d1 = collect(range(drivers_limit[1][1], drivers_limit[1][2], 31)) 
  x_d2 = collect(range(drivers_limit[2][1], drivers_limit[2][2], 31))
  y_d1 = @lift(d1_vec(x_d1, $(sd_d[2]), model_functions[$m], $parameters)) 
  y_d2 = @lift(d2_vec($(sd_d[1]), x_d2, model_functions[$m], $parameters))
  lines!(ax_d1, x_d1, y_d1, color = :red, linewidth = 4)
  lines!(ax_d2, x_d2, y_d2, color = :blue, linewidth = 4)

  # Plot 3D lines of model(drivers, params)
  c_d2 = @lift(repeat([$(sd_d[2])], 31)) 
  c_d1 = @lift(repeat([$(sd_d[1])], 31))
  lines!(ax3D, x_d1, c_d2, y_d1, color = :red, linewidth = 4) 
  lines!(ax3D, c_d1, x_d2, y_d2, color = :blue, linewidth = 4)

  # Update parameters and rescale x and y limits
  for i in 1:length(sd)
    on(sd[i]) do val 
      sd_v = Dict(i => sg.sliders[i].value[] for i in 1:length(sliders))
      s = collect(values(sort(sd_v)))
      args = (; zip(param_keys, s)...)
      parameters[] = model_parameters{FT}(; args..., earth_param_set = earth_param_set)  # new args
      autolimits!(ax3D)
      autolimits!(ax_d1)
      autolimits!(ax_d2)
    end
  end
  for i in 1:2
    on(sd_d[i]) do val
      autolimits!(ax_d1)
      autolimits!(ax_d2)
    end
  end
  on(menu.selection) do val
    autolimits!(ax3D)
    autolimits!(ax_d1)
    autolimits!(ax_d2)
  end

  colsize!(fig.layout, 1, Relative(1/2))
  rowsize!(fig.layout, 3, Relative(1/3))

  DataInspector(fig)

  return fig
end

