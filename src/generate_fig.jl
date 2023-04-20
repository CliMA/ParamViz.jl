#= 
using GLMakie # can't be WGLMakie because bug https://github.com/MakieOrg/Makie.jl/issues/2575
using SparseArrays
using Statistics
=#

#= 
using JSServe, WGLMakie
=#

struct Drivers # Need 2 drivers always
  names 
  values
  ranges
end

struct Parameters
  names
  values
  ranges
end

struct Constants # should be able to be 0, or have a way to deal with 0
  names
  values
end

struct Inputs
  drivers::Drivers
  parameters::Parameters
  constants::Constants
end

"""
    mat(parameterisation::Function, parameters, steps::Real)

Evaluate the function parameterisation on grid values of drivers x and y. 
Returns vectors x and y, and a matrix of function output at those points, FMatrix.
"""
function mat(parameterisation::Function, parameters, steps::Real)
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
  parameters = repeat([parameters], steps*steps)
  constants = repeat([inputs.constants.values], steps*steps)
  # parameterisation output on Grid
  FMatrix = Matrix(sparse(X, Y, parameterisation.(drivers, parameters, constants)))
  return x, y, FMatrix
end

"""
    d1_vec(y, parameterisation::Function, parameters, steps::Real)

Evaluate the function parameterisation on a line of driver x, with constant y. 
"""
function d1_vec(y, parameterisation::Function, parameters, steps::Real) 
  x = collect(range(inputs.drivers.ranges[1][1], inputs.drivers.ranges[1][2], steps)) # min d1 to max d1, n steps
  y = repeat([y], steps)
  drivers = [(x[i], y[i]) for i in 1:steps] 
  parameters = repeat([parameters], steps)
  constants = repeat([inputs.parameters.values], steps)
  vec = parameterisation.(drivers, parameters, constants)
  return vec
end

"""
    d2_vec(x, parameterisation::Function, parameters, steps::Real)

Evaluate the function parameterisation on a line of driver y, with constant x.
"""
function d2_vec(x, parameterisation::Function, parameters, steps::Real)
  y = collect(range(inputs.drivers.ranges[2][1], inputs.drivers.ranges[2][2], steps)) # min d2 to max d2, n steps
  x = repeat([x], steps)
  drivers = [(x[i], y[i]) for i in 1:steps] 
  parameters = repeat([parameters], steps)
  constants = repeat([inputs.parameters.values], steps)
  vecM = parameterisation.(drivers, parameters, constants)
  return vecM
end

#= Example
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
=#

"""
    param_dashboard(parameterisation::Function, inputs::Inputs, sliders)

Generates a dashboard of a parameterisation(drivers, parameters, constants) function,
where the user can interact with driver and parameter values via sliders. 
"""
function param_dashboard(parameterisation::Function, inputs::Inputs, sliders) 
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

  n = length(sliders)
  s_vals = [sliders[i].value for i in 1:n] |> Tuple   

  #= GLMakie slider  
  sliders = [Slider(fig[i, 1], range = -5:1:5, startvalue = 0) for i in 1:4]
  s_vals = [sliders[i].value for i in 1:4]   
  s1_d = Slider(fig[1, 1], range = -5:1:5, startvalue = 0) # driver
  s2_d = Slider(fig[2, 1], range = -5:1:5, startvalue = 0)
  s1_p = Slider(fig[3, 1], range = -5:1:5, startvalue = 0) # parameter
  s2_p = Slider(fig[4, 1], range = -5:1:5, startvalue = 0)
  s1_d_v = s1_d.value
  s2_d_v = s2_d.value
  s1_p_v = s1_p.value
  s2_p_v = s2_p.value
  =#

  steps = 30
  n = length(sliders) 
  #parameters = @lift(($s1_p_v, $s2_p_v)) # parameters values   
  parameters = lift((args...,) -> args, s_vals[3:end]...)

  x_d1 = collect(range(inputs.drivers.ranges[1][1], inputs.drivers.ranges[1][2], steps)) # min d1 to max d1, n steps
  x_d2 = collect(range(inputs.drivers.ranges[2][1], inputs.drivers.ranges[2][2], steps)) # min d2 to max d2, n steps
  c_d1 = @lift(repeat([$(s_vals[1])], steps)) # constant d1 val, length n
  c_d2 = @lift(repeat([$(s_vals[2])], steps)) # constant d2 val, length n
  y_d1 = @lift(d1_vec($(s_vals[1]), parameterisation, $parameters, steps)) # function output at constant driver 1
  y_d2 = @lift(d2_vec($(s_vals[2]), parameterisation, $parameters, steps)) # function output at constant driver 2
  
  # Plot 3D surface of model(drivers, params)
  x = @lift(mat(parameterisation, $parameters, steps)[1]) 
  y = @lift(mat(parameterisation, $parameters, steps)[2])
  z = @lift(mat(parameterisation, $parameters, steps)[3])
  surface!(ax3D, x, y, z, colormap = Reverse(:Spectral), transparency = true, alpha = 0.2, shading = false)

  # Plot 2D lines of model(drivers, params)
  lines!(ax_d1, x_d1, y_d1, color = :red, linewidth = 4)
  lines!(ax_d2, x_d2, y_d2, color = :blue, linewidth = 4)

  # Plot 3D lines of model(drivers, params)
  lines!(ax3D, x_d1, c_d1, y_d1, color = :red, linewidth = 4) 
  lines!(ax3D, c_d2, x_d2, y_d2, color = :blue, linewidth = 4)

  # Update parameters and rescale x and y limits  
  #=
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
  =#
  DataInspector(fig)

  return fig  
end

Param_app = App() do 
  n = length(parameters.values)+2 
  sliders = [Slider(-5:1:5) for i in 1:n] |> Tuple
  fig = param_dashboard(parameterisation, inputs, sliders)
  sls = [DOM.div("text i: ", sliders[i], sliders[i].value) for i in 1:n]
  return DOM.div(sls..., fig)  
end

