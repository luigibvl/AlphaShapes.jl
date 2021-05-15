__precompile__()

module AlphaShapes

	using LinearAlgebraicRepresentation
	using TimerOutputs
	#using MATLAB
	#using Delaunay #BUG in package
	using SharedArrays
	using Distributed, Triangle
	using Combinatorics, DataStructures
	using Base.Threads
	const Lar = LinearAlgebraicRepresentation

	include("alpha_complex.jl")
	include("deWall.jl")
	include("geometry.jl")
	include("delaunayTriangulation.jl")
	const to = TimerOutput()

	export alphaFilter, alphaSimplex, delaunayTriangulation, to
end
