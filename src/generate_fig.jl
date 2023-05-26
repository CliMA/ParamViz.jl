"""
    param_dashboard(parameterisation::Function, inputs::Inputs, sliders)

Generates a dashboard of a parameterisation(drivers, parameters, constants) function,
where the user can interact with driver and parameter values via sliders. 
"""
function param_dashboard(parameterisation::Function, inputs::Inputs, drivers_sliders, parameters_sliders, output) 
  fig = Figure(resolution = (800, 800))

  # JSServe layout
  ax3D = Axis3(fig[1,1:2][1,1], xlabel = inputs.drivers.names[1], ylabel = inputs.drivers.names[2], zlabel = output.name); zlims!(ax3D, output.range)
  ax_d1 = Axis(fig[2,1], xlabel = inputs.drivers.names[1], ylabel = output.name); ylims!(ax_d1, output.range)
  ax_d2 = Axis(fig[2,2], xlabel = inputs.drivers.names[2], ylabel = output.name); ylims!(ax_d2, output.range)

  n_drivers = 2  
  n_parameters = length(inputs.parameters.values)
  drivers_vals = [drivers_sliders[i].value for i in 1:n_drivers] |> Tuple 
  parameters_vals = [parameters_sliders[i].value for i in 1:n_parameters] |> Tuple 

  steps = 30
  drivers = lift((args...,) -> args, drivers_vals...)
  parameters = lift((args...,) -> args, parameters_vals...)
  constants = inputs.constants.values

  x_d1 = collect(range(inputs.drivers.ranges[1][1], inputs.drivers.ranges[1][2], steps)) # min d1 to max d1, n steps
  x_d2 = collect(range(inputs.drivers.ranges[2][1], inputs.drivers.ranges[2][2], steps)) # min d2 to max d2, n steps
  c_d1 = @lift(repeat([$(drivers_vals[2])], steps)) # constant d1 val, length n
  c_d2 = @lift(repeat([$(drivers_vals[1])], steps)) # constant d2 val, length n
  y_d1 = @lift(d1_vec($(drivers_vals[2]), parameterisation, inputs, $parameters, steps)) # function output at constant driver 1
  y_d2 = @lift(d2_vec($(drivers_vals[1]), parameterisation, inputs, $parameters, steps)) # function output at constant driver 2
  
  # Plot 3D surface of model(drivers, params)
  x = @lift(mat(parameterisation, inputs, $parameters, steps)[1]) 
  y = @lift(mat(parameterisation, inputs, $parameters, steps)[2])
  z = @lift(mat(parameterisation, inputs, $parameters, steps)[3])
  surface!(ax3D, x, y, z, colormap = Reverse((:Spectral, 0.8),), transparency = true, alpha = 0.2, shading = false, colorrange = output.range) 
  cb = Colorbar(fig[1, 1:2][1, 2], colormap = Reverse(:Spectral), limits = output.range, label = output.name)
  cb.alignmode = Mixed(right = 0)

  # Plot 2D lines of model(drivers, params)
  lines!(ax_d1, x_d1, y_d1, color = :red, linewidth = 4)
  lines!(ax_d2, x_d2, y_d2, color = :blue, linewidth = 4)

  # Plot 3D lines of model(drivers, params)
  lines!(ax3D, x_d1, c_d1, y_d1, color = :red, linewidth = 4) 
  lines!(ax3D, c_d2, x_d2, y_d2, color = :blue, linewidth = 4)

  val = @lift(parameterisation($drivers, $parameters, constants))
  point3D = @lift(Vec3f.($(drivers_vals[1]), $(drivers_vals[2]), $val))
  scatter!(ax3D, point3D, color = val, markersize = 20, colormap = Reverse(:Spectral), colorrange = output.range,
          strokewidth = 10, strokecolor = :black) # stroke not supported in WGLMakie?

  DataInspector(fig)

  return fig, val  
end

function webapp(parameterisation, inputs, output)
  Param_app = App() do 
    n_drivers = 2  
    n_parameters = length(inputs.parameters.values)
    drivers_range = [range(inputs.drivers.ranges[i][1], inputs.drivers.ranges[i][2], 12) for i in 1:n_drivers]
    parameters_range = [range(inputs.parameters.ranges[i][1], inputs.parameters.ranges[i][2], 12) for i in 1:n_parameters]
    drivers_sliders = [JSServe.TailwindDashboard.Slider(inputs.drivers.names[i], drivers_range[i], value = drivers_range[i][6]) for i in 1:n_drivers] |> Tuple
    parameters_sliders = [JSServe.TailwindDashboard.Slider(inputs.parameters.names[i], parameters_range[i], value = parameters_range[i][6]) for i in 1:n_parameters] |> Tuple
    fig, out = param_dashboard(parameterisation, inputs, drivers_sliders, parameters_sliders, output)
    output_value = DOM.div(output.name, " = ", @lift(round($(out), sigdigits = 2)))
    return DOM.div(
                   JSServe.TailwindDashboard.Card(
                                                  JSServe.TailwindDashboard.FlexRow(
                     JSServe.TailwindDashboard.Card(
                                                    JSServe.TailwindDashboard.FlexCol(output_value, drivers_sliders..., parameters_sliders...)
                                                   ), fig)      
                                                 )
                  )
  end
  return Param_app
end



