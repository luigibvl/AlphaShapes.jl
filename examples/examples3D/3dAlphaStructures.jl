using LinearAlgebraicRepresentation, ViewerGL
using BenchmarkTools
using Distributed

include("../../src/AlphaStructures.jl")

Lar = LinearAlgebraicRepresentation
GL = ViewerGL
using TimerOutputs

filename = "./examples/examples3D/OBJ/teapot.obj";
W, EVs, FVs = Lar.obj2lar(filename);
WW = [[i] for i = 1:size(W, 2)];
V, VV = Lar.apply(Lar.r(pi / 2, 0, 0), (W, WW)); #object rotated

points = convert(Lar.Points, V')
GL.VIEW([
    GL.GLPoints(points)
    GL.GLAxis(GL.Point3d(-1, -1, -1), GL.Point3d(1, 1, 1))
]);

V, VV = Lar.apply(Lar.r(pi / 2, 0, 0), (W, WW)); #object rotated
@btime AlphaStructures.alphaFilter(V);
filtration = AlphaStructures.alphaFilter(V);
VV, EV, FV, TV = AlphaStructures.alphaSimplex(V, filtration, 3.7)
@btime VV, EV, FV, TV = AlphaStructures.alphaSimplex(V, filtration, 3.7)

GL.VIEW([
    GL.GLGrid(V, EV, GL.COLORS[1], 0.6) # White
    GL.GLGrid(V, FV, GL.COLORS[2], 0.3) # Red
    GL.GLGrid(V, TV, GL.COLORS[3], 0.3) # Green
]);

filter_key = sort(unique(values(filtration)))

granular = 10

reduced_filter =
    filter_key[sort(abs.(rand(Int, granular) .% length(filter_key)))]
reduced_filter = [reduced_filter; max(filter_key...)]
α=0.0

for α in reduced_filter
    #@code_warntype AlphaStructures.alphaSimplex(V, filtration, α)
    @show α
    @btime VVV, EEV, FFV, TTV = AlphaStructures.alphaSimplex(V, filtration, α)
    VVV, EEV, FFV, TTV = AlphaStructures.alphaSimplex(V, filtration, α)
    """
    GL.VIEW(GL.GLExplode(
        V,
        [[[t] for t in TTV]; [[f] for f in FFV]; [[e] for e in EEV]],
        1.0,
        1.0,
        1.0,# Explode Ratio
        99,
        1,# Colors
    ))
    """
end

#print_timer(AlphaStructures.to);
