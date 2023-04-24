"""
    param_dashboard(parameterisation::Function, inputs::Inputs, sliders)

Generates a dashboard of a parameterisation(drivers, parameters, constants) function,
where the user can interact with driver and parameter values via sliders. 
"""
function param_dashboard(parameterisation::Function, inputs::Inputs, sliders) 
  fig = Figure(resolution = (1200, 1200))

  # JSServe layout
  ax3D = Axis3(fig[1,1], xlabel = inputs.drivers.names[1], ylabel = inputs.drivers.names[2])
  ax_d1 = Axis(fig[2,1], xlabel = inputs.drivers.names[1])
  ax_d2 = Axis(fig[2,2], xlabel = inputs.drivers.names[2])

  n = length(sliders)
  s_vals = [sliders[i].value for i in 1:n] |> Tuple   

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

