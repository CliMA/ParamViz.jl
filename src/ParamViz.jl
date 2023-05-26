module ParamViz

using WGLMakie
using JSServe
using SparseArrays
using Statistics
using UnicodeFun

include("struct_and_functions.jl")
export Drivers, Parameters, Constants, Inputs, Output # struct
export mat, d1_vec, d2_vec # functions

include("generate_fig.jl")
export param_dashboard
export webapp

end 
