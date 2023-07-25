module ParamViz

using WGLMakie
using JSServe
using SparseArrays
using Statistics

include("struct_and_functions.jl")
export Drivers, Parameters, Constants, Inputs, Output # struct
export mat, d1_vec, d2_vec, parameterisation # functions

include("generate_fig.jl")
export param_dashboard
export webapp

end 
