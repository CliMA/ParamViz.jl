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






###############
###############




#= deps
using JSServe, WGLMakie
using SparseArrays
using Statistics
include("src/fun_discretisation.jl")

=#

struct Drivers
  names
  values
  ranges
end

struct Parameters
  names
  values
  ranges
end

struct Constants
  names
  values
end

struct Inputs
  drivers::Drivers
  parameters::Parameters
  constants::Constants
end

drivers = Drivers(("x", "y"), (1, 1), ([-5, 5], [-5, 5]))
parameters = Parameters(("p1", "p2"), (1.0, 1.0), ([-5, 5], [-5, 5]))
constants = Constants(("c1", "c2"), (1.0, 1.0))
inputs = Inputs(drivers, parameters, constants)



"""
    mat(parameterisation::Function, inputs::Inputs, steps::Real)

Evaluate the function parameterisation on grid values of drivers x and y. 
Returns vectors x and y, and a matrix of function output at those points, FMatrix.
"""
function mat(parameterisation::Function, inputs::Inputs, steps::Real)
  # range from min to max for n steps (size = steps) 
  x = collect(range(inputs.drivers.ranges[1][1], length=steps, stop=inputs.drivers.ranges[1][2]))   
  y = collect(range(inputs.drivers.ranges[2][1], length=steps, stop=inputs.drivers.ranges[2][2])) 
  # Grid (size = steps*steps)
  X = repeat(1:steps, inner=steps)  
  Y = repeat(1:steps, outer=steps) 
  # Grid (size = steps*steps)
  X2 = repeat(x, inner=steps)    
  Y2 = repeat(y, outer=steps)
  # args for parameterisation
  drivers = [(X2[i], Y2[i]) for i in 1:steps*steps]
  parameters = repeat([inputs.parameters.values], steps*steps)
  constants = repeat([inputs.parameters.values], steps*steps)
  # parameterisation output on Grid
  FMatrix = Matrix(sparse(X, Y, parameterisation.(drivers, parameters, constants)))
  return x, y, FMatrix
end

"""
    d1_vec(parameterisation::Function, inputs::Inputs, steps::Real)

Evaluate the function parameterisation on a line of driver x, with constant y. 
"""
function d1_vec(parameterisation::Function, inputs::Inputs, steps::Real) # should y be explicit arg?
  x = collect(range(inputs.drivers.ranges[1][1], inputs.drivers.ranges[1][2], steps)) # min d1 to max d1, 31 steps
  # y = repeat([inputs.drivers.ranges[1][2]], steps)
  drivers = [(x[i], y[i]) for i in 1:steps] 
  parameters = repeat([inputs.parameters.values], steps)
  constants = repeat([inputs.parameters.values], steps)
  vec = parameterisation.(drivers, parameters, constants)
  return vec
end

"""
    d2_vec(parameterisation::Function, inputs::Inputs, steps::Real)

Evaluate the function parameterisation on a line of driver y, with constant x.
"""
function d2_vec(parameterisation::Function, inputs::Inputs, steps::Real) # should x be explicit arg?
  # x = repeat([inputs.drivers.ranges[1][1]], steps) 
  y = collect(range(inputs.drivers.ranges[2][1], inputs.drivers.ranges[2][2], 31)) # min d2 to max d2, 31 steps
  drivers = [(x[i], y[i]) for i in 1:steps] 
  parameters = repeat([inputs.parameters.values], steps)
  constants = repeat([inputs.parameters.values], steps)
  vecM = parameterisation.(drivers, parameters, constants)
  return vecM
end


###########################
### example ####
###########################

# Drivers, Parameters, Constants, Inputs struct
function parameterisation(x, y, p1, p2, c1, c2) # most CliMA function are defined like that...
  return p1*sin(x) + p2*sin(y) + c1 + c2
end

# need to be user defined?
# user creates the inputs struct
# then this function to show what are drivers, parameters, constants
function parameterisation(inputs::Inputs) # method for ParamViz
    x, y = inputs.drivers.values[1], inputs.drivers.values[2] 
    p1, p2 = inputs.parameters.values[1], inputs.parameters.values[2]
    c1, c2 = inputs.constants.values[1], inputs.constants.values[2]
    return parameterisation(x, y, p1, p2, c1, c2)
end

# what should be type of args? ::Drivers, ::Parameters, ::Constants 
# or ::Tuple, ::Tuple, ::Tuple ?
function parameterisation(drivers, parameters, constants) # method without names and values
  x, y = drivers[1], drivers[2]
  p1, p2 = parameters[1], parameters[2]
  c1, c2 = constants[1], constants[2]
  return parameterisation(x, y, p1, p2, c1, c2)
end



#=

function Parameterisation(x::Real, y::Real, p::Real) # easy to rewrite like this to call mat function
  c1, c2 = inputs.constants.values[1], inputs.constants.values[2]
  return p[1]*sin(x) + p[2]*sin(y) + c1 + c2
end

parameterisation(inputs)
parameterisation(inputs.drivers.values[1], inputs.drivers.values[2], inputs.parameters.values[1], inputs.parameters.values[1], inputs.constants.values[1], inputs.constants.values[1])
Parameterisation(inputs.drivers.values[1], inputs.drivers.values[2], [inputs.parameters.values[1], inputs.parameters.values[2]])

=#

# Then call param_dashboard(parameterisation::Function, inputs::Inputs)


# slider should be a Dict or struct of sliders... with n sliders (n = number of params)


"""


"""
function param_dashboard(parameterisation::Function, inputs::Inputs, slider1, slider2, slider3, slider4) # JSServe sliders
  fig = Figure(resolution = (1200, 1200))

  #= GLMakie layout
  ax3D = Axis3(fig[5,2], xlabel = inputs.drivers.names[1], ylabel = inputs.drivers.names[2])
  ax_d1 = Axis(fig[6,1], xlabel = inputs.drivers.names[1])
  ax_d2 = Axis(fig[6,2], xlabel = inputs.drivers.names[2])
  =#

  # JSServe layout
  ax3D = Axis3(fig[1,1], xlabel = inputs.drivers.names[1], ylabel = inputs.drivers.names[2])
  ax_d1 = Axis(fig[2,1], xlabel = inputs.drivers.names[1])
  ax_d2 = Axis(fig[2,2], xlabel = inputs.drivers.names[2])
  # 
  
  # JSServe sliders
  s1_d_v = slider1.value 
  s2_d_v = slider2.value
  s1_p_v = slider3.value
  s2_p_v = slider4.value
  #

  #=
  # GLMakie slider
  # For this example we will need 2 driver sliders and 2 parameter sliders
  s1_d = Slider(fig[1, 1], range = -5:1:5, startvalue = 0) # driver
  s2_d = Slider(fig[2, 1], range = -5:1:5, startvalue = 0)
  s1_p = Slider(fig[3, 1], range = -5:1:5, startvalue = 0) # parameter
  s2_p = Slider(fig[4, 1], range = -5:1:5, startvalue = 0)
  s1_d_v = s1_d.value
  s2_d_v = s2_d.value
  s1_p_v = s1_p.value
  s2_p_v = s2_p.value
  =#

  parameters = @lift(($s1_p_v, $s2_p_v)) # parameters values
  x_d1 = collect(range(inputs.drivers.ranges[1][1], inputs.drivers.ranges[1][2], 31)) # min d1 to max d1, 31 steps
  x_d2 = collect(range(inputs.drivers.ranges[2][1], inputs.drivers.ranges[2][2], 31)) # min d2 to max d2, 31 steps
  c_d1 = @lift(repeat([$s1_d_v], 31)) # constant d1 val, length 31
  c_d2 = @lift(repeat([$s2_d_v], 31)) # constant d2 val, length 31
  y_d1 = @lift(d1_vec(x_d1, $s1_d_v, Parameterisation, $parameters)) # function output at constant driver 1
  y_d2 = @lift(d2_vec($s2_d_v, x_d2, Parameterisation, $parameters)) # function output at constant driver 2
  
  # Plot 3D surface of model(drivers, params)
  x = @lift(mat(inputs.drivers.ranges[1], inputs.drivers.ranges[2], 30, Parameterisation, $parameters)[1]) 
  y = @lift(mat(inputs.drivers.ranges[1], inputs.drivers.ranges[2], 30, Parameterisation, $parameters)[2])
  z = @lift(mat(inputs.drivers.ranges[1], inputs.drivers.ranges[2], 30, Parameterisation, $parameters)[3])
  surface!(ax3D, x, y, z, colormap = Reverse(:Spectral), transparency = true, alpha = 0.2, shading = false)

  # Plot 2D lines of model(drivers, params)
  lines!(ax_d1, x_d1, y_d1, color = :red, linewidth = 4)
  lines!(ax_d2, x_d2, y_d2, color = :blue, linewidth = 4)

  # Plot 3D lines of model(drivers, params)
  lines!(ax3D, x_d1, c_d1, y_d1, color = :red, linewidth = 4) 
  lines!(ax3D, c_d2, x_d2, y_d2, color = :blue, linewidth = 4)

  # Update parameters and rescale x and y limits  
  on(s1_p_v) do val 
    autolimits!(ax3D)
    autolimits!(ax_d1)
    autolimits!(ax_d2)
  end

  on(s2_p_v) do val 
    autolimits!(ax3D)
    autolimits!(ax_d1)
    autolimits!(ax_d2)
  end

  on(s1_d_v) do val
    autolimits!(ax_d1)
    autolimits!(ax_d2)
  end

  on(s2_d_v) do val
    autolimits!(ax_d1)
    autolimits!(ax_d2)
  end
  
  DataInspector(fig)

  return fig  
end

Param_app = App() do 
  slider1 = Slider(-5:1:5) # driver
  slider2 = Slider(-5:1:5)
  slider3 = Slider(-5:1:5) # parameter
  slider4 = Slider(-5:1:5)
  fig = param_dashboard(Parameterisation, inputs, slider1, slider2, slider3, slider4)
  sl1 = DOM.div("x: ", slider1, slider1.value)
  sl2 = DOM.div("y: ", slider2, slider2.value)
  sl3 = DOM.div("p1: ", slider3, slider3.value)
  sl4 = DOM.div("p2: ", slider4, slider4.value)
  return DOM.div(sl1, sl2, sl3, sl4, fig)
end

