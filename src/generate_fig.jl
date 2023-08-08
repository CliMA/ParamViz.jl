"""
    param_dashboard(parameterisation::Function, inputs::Inputs, sliders)

Generates a dashboard of a parameterisation(drivers, parameters, constants) function,
where the user can interact with driver and parameter values via sliders. 
"""
function param_dashboard(parameterisation::Function, inputs::Inputs, drivers_sliders, parameters_sliders, output)
  fig = Figure(resolution = (800, 800))

  drivers_ranges_unitconverted = [ustrip.(uconvert.(drivers.units[i][2], (drivers.ranges[i])drivers.units[i][1])) for i = 1:2]
  parameters_ranges_unitconverted = [ustrip.(uconvert.(parameters.units[i][2], (parameters.ranges[i])parameters.units[i][1])) for i = 1:length(parameters.units)]
  output_range_unitconverted = ustrip.(uconvert.(output.unit[2], (output.range)output.unit[1]))

  # JSServe layout
  ax3D = Axis3(fig[1,1:2][1,1], xlabel = inputs.drivers.names[1], ylabel = inputs.drivers.names[2], zlabel = output.name); zlims!(ax3D, output_range_unitconverted)
  ax_d1 = Axis(fig[2,1], xlabel = inputs.drivers.names[1], ylabel = output.name); ylims!(ax_d1, output_range_unitconverted)
  ax_d2 = Axis(fig[2,2], xlabel = inputs.drivers.names[2], ylabel = output.name); ylims!(ax_d2, output_range_unitconverted)

  n_drivers = 2  
  n_parameters = length(inputs.parameters.names)
  drivers_vals = [@lift($(drivers_sliders[i].value)./inputs.drivers.scalers[i]) for i in 1:n_drivers] |> Tuple 
  parameters_vals = [@lift($(parameters_sliders[i].value)./inputs.parameters.scalers[i]) for i in 1:n_parameters] |> Tuple 

  steps = 30
  drivers = lift((args...,) -> args, drivers_vals...)
  parameters = lift((args...,) -> args, parameters_vals...)
  constants = inputs.constants.values

  x_d1 = collect(range(drivers_ranges_unitconverted[1][1], drivers_ranges_unitconverted[1][2], steps)) # min d1 to max d1, n steps
  x_d2 = collect(range(drivers_ranges_unitconverted[2][1], drivers_ranges_unitconverted[2][2], steps)) # min d2 to max d2, n steps
  c_d1 = @lift(repeat([$(drivers_vals[2])], steps).*inputs.drivers.scalers[2]) # constant d1 val, length n
  c_d2 = @lift(repeat([$(drivers_vals[1])], steps).*inputs.drivers.scalers[1]) # constant d2 val, length n
  y_d1 = @lift(d1_vec($(drivers_vals[2]), parameterisation, inputs, $parameters, steps).*output.scaler) # function output at constant driver 1
  y_d2 = @lift(d2_vec($(drivers_vals[1]), parameterisation, inputs, $parameters, steps).*output.scaler) # function output at constant driver 2
  val = @lift(parameterisation($drivers, $parameters, constants).*output.scaler)
  point3D = @lift(Vec3f.($(drivers_vals[1]).*inputs.drivers.scalers[1], $(drivers_vals[2]).*inputs.drivers.scalers[2], $val))
  point2D_ax1 = @lift(Vec2f.($(drivers_vals[1]).*inputs.drivers.scalers[1], $val))
  point2D_ax2 = @lift(Vec2f.($(drivers_vals[2]).*inputs.drivers.scalers[2], $val))

  # Plot 3D surface of model(drivers, params)
  x = @lift(mat(parameterisation, inputs, $parameters, steps)[1].*inputs.drivers.scalers[1]) 
  y = @lift(mat(parameterisation, inputs, $parameters, steps)[2].*inputs.drivers.scalers[2])
  z = @lift(mat(parameterisation, inputs, $parameters, steps)[3].*output.scaler)
  surface!(ax3D, x, y, z, colormap = Reverse((:Spectral, 0.8),), transparency = true, alpha = 0.2, shading = false, colorrange = output_range_unitconverted) 
  cb = Colorbar(fig[1, 1:2][1, 2], colormap = Reverse(:Spectral), limits = output.range.*output.scaler, label = output.name)
  cb.alignmode = Mixed(right = 0)

  # Plot 2D lines of model(drivers, params)
  lines!(ax_d1, x_d1, y_d1, color = :red, linewidth = 4)
  lines!(ax_d2, x_d2, y_d2, color = :blue, linewidth = 4)
  scatter!(ax_d1, point2D_ax1, color = :black, markersize = 20)
  scatter!(ax_d2, point2D_ax2, color = :black, markersize = 20)

  # Plot 3D lines of model(drivers, params)
  lines!(ax3D, x_d1, c_d1, y_d1, color = :red, linewidth = 4) 
  lines!(ax3D, c_d2, x_d2, y_d2, color = :blue, linewidth = 4)
  scatter!(ax3D, point3D, color = :black, markersize = 20, colormap = Reverse(:Spectral), colorrange = output.range,
          strokewidth = 10, strokecolor = :black) # stroke not supported in WGLMakie?

  DataInspector(fig)

  return fig, val  
end

function webapp(parameterisation, inputs, output)
  Param_app = App() do 
    n_drivers = 2  
    n_parameters = length(inputs.parameters.names)
    drivers_range = [round.(range(inputs.drivers.ranges[i][1].*inputs.drivers.scalers[i], inputs.drivers.ranges[i][2].*inputs.drivers.scalers[i], 12), sigdigits = 2) for i in 1:n_drivers]
    parameters_range = [round.(range(inputs.parameters.ranges[i][1].*inputs.parameters.scalers[i], inputs.parameters.ranges[i][2].*inputs.parameters.scalers[i], 12), sigdigits = 2) for i in 1:n_parameters]
    drivers_sliders = [JSServe.TailwindDashboard.Slider(inputs.drivers.names[i], drivers_range[i], value = drivers_range[i][6]) for i in 1:n_drivers] |> Tuple
    parameters_sliders = [JSServe.TailwindDashboard.Slider(inputs.parameters.names[i], parameters_range[i], value = parameters_range[i][6]) for i in 1:n_parameters] |> Tuple
    fig, out = param_dashboard(parameterisation, inputs, drivers_sliders, parameters_sliders, output)
    output_value = DOM.div(output.name, " = ", @lift(round($(out), sigdigits = 2)); style="font-size: 20px; font-weight: bold")
    drivers_label = DOM.div("Drivers:"; style="font-size: 16px; font-weight: bold")
    parameters_label = DOM.div("Parameters:"; style="font-size: 16px; font-weight: bold")
    return DOM.div(
                   JSServe.TailwindDashboard.Card(
                   JSServe.TailwindDashboard.FlexCol(
                                                     JSServe.TailwindDashboard.Card(output_value; class="container mx-auto"),
                                                     JSServe.TailwindDashboard.FlexRow(
                                                                                       JSServe.TailwindDashboard.Card(JSServe.TailwindDashboard.FlexCol(parameters_label, parameters_sliders...)),
                                                                                       JSServe.TailwindDashboard.Card(JSServe.TailwindDashboard.FlexCol(drivers_label, drivers_sliders...))
                                                                                      ),
                                                     fig)      
                                                    )
                  )
  end
  return Param_app
end


#= with units
using ParamViz
using JSServe

using Unitful: R, L, mol, K, kJ, °C, m, g, cm, hr, mg, s, μmol
using UnitfulMoles: molC
using Unitful, UnitfulMoles
@compound CO₂

drivers = Drivers(("PAR (μmol m⁻² s⁻¹))", "LAI (m² m⁻²))"),
                  FT.((500 * 1e-6, 5)),
                  (FT.([0, 1500 * 1e-6]), FT.([0, 10])),
                  (1e6, 1.0) # scalers
                 )

parameters = Parameters(("canopy reflectance, ρ_leaf",
                         "extinction coefficient, K",
                         "clumping index, Ω"),
                        (FT(0.1), FT(0.6), FT(0.69)),
                        (FT.([0, 1]), FT.([0, 1]), FT.([0, 1])),
                        (1, 1, 1) # scalers
                       )

# need a method with no constant! 
# hack: useless constants
constants = Constants(("a", "b"), (FT(1), FT(2)))

inputs = Inputs(drivers, parameters, constants)

output = Output("APAR (μmol m⁻² s⁻¹)", [0, 1500 * 1e-6], 1e6)

import ParamViz.parameterisation
function parameterisation(PAR, LAI, ρ_leaf, K, Ω, a, b)   
  APAR = plant_absorbed_ppfd(PAR, ρ_leaf, K, LAI, Ω) 
  return APAR
end

beer_app = webapp(parameterisation, inputs, output)

=#
