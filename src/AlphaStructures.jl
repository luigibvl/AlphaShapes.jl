__precompile__()

module AlphaStructures
	using LinearAlgebraicRepresentation
	using TimerOutputs
	#using MATLAB
	#using Delaunay #BUG in package
	using SharedArrays
	using Combinatorics, DataStructures
	using Distributed, Triangle
	const Lar = LinearAlgebraicRepresentation

	include("alpha_complex.jl")
	include("deWall.jl")
	include("geometry.jl")
	include("delaunayTriangulation.jl")
	const to = TimerOutput()

	export alphaFilter, alphaSimplex, delaunayTriangulation, to
end
