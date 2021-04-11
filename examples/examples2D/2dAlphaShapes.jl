#using AlphaStructures

include("/Users/luigibevilacqua/Desktop/AlphaShapes/src/AlphaStructures.jl")

using LinearAlgebraicRepresentation, ViewerGL
using TimerOutputs
Lar = LinearAlgebraicRepresentation
GL =  ViewerGL


"""
	pointsRand(V, VV, n, m)

Generate random points inside and otuside `(V, VV)`.
"""
function pointsRand(
		V::Lar.Points, EV::Lar.Cells, n = 1000, m = 0
	)::Tuple{Lar.Points, Lar.Points, Lar.Cells, Lar.Cells}
	classify = Lar.pointInPolygonClassification(V, EV)
	Vi = [0;0]
	Ve = [0;0]
	k1 = 0
	k2 = 0
	while k1 < n || k2 < m
		queryPoint = [rand();rand()]
		inOut = classify(queryPoint)

		if k1 < n && inOut == "p_in"
			Vi = hcat(Vi, queryPoint)
			k1 = k1 + 1;
		end
		if k2 < m && inOut == "p_out"
			Ve = hcat(Ve, queryPoint)
			k2 = k2 + 1;
		end
	end
	VVi = [[i] for i = 1 : n]
	VVe = [[i] for i = 1 : m]
	return Vi[:,2:end], Ve[:,2:end], VVi, VVe
end

filename = "/Users/luigibevilacqua/Desktop/AlphaShapes/examples/examples2D/svg_files/Lar2.svg";

#filename = "examples/examples2D/svg_files/Lar2.svg";
V,EV = Lar.svg2lar(filename);

Vi, Ve, VVi, VVe = pointsRand(V, EV, 1000, 10000);

# GL.VIEW([
# 	GL.GLGrid(Vi, VVi, GL.COLORS[1], 1)
# 	GL.GLGrid(Ve, VVe, GL.COLORS[12], 1)
# ])


AlphaStructures.tt("ciao!tt")
AlphaStructures.ttt("ciao!ttt")
filtration = AlphaStructures.alphaFilter(Vi);
VV,EV,FV = AlphaStructures.alphaSimplex(Vi, filtration, 0.02)

points = [[p] for p in VV]
faces = [[f] for f in FV]
edges = [[e] for e in EV]
#GL.VIEW(
GL.GLExplode(Vi, [edges; faces], 1.5, 1.5, 1.5, 99, 1)
# );

filter_key = sort(unique(values(filtration)))

granular = 10

reduced_filter = filter_key[sort(abs.(rand(Int, granular).%length(filter_key)))]
reduced_filter = [reduced_filter; max(filter_key...)]

#
# Arlecchino's Lar
#
#=
for α in reduced_filter
	@show α
	VV,EV,FV = AlphaStructures.alphaSimplex(Vi, filtration, α)
	GL.VIEW(
		GL.GLExplode(
			Vi,
			[[[f] for f in FV]; [[e] for e in EV]],
			1., 1., 1.,	# Explode Ratio
			99, 1		# Colors
		)
	)
end
=#
#
# Appearing Colors
#

reduced_filter = [
	0.002;	0.003;	0.004;	0.005;  0.006;
	0.007;	0.008;	0.009;	0.010;	0.013;
	0.015;	0.020;	0.050;	1.000
]

for i = 2 : length(reduced_filter)
	VV0, EV0, FV0 = AlphaStructures.alphaSimplex(Vi, filtration, reduced_filter[i-1])
	VV,  EV,  FV  = AlphaStructures.alphaSimplex(Vi, filtration, reduced_filter[i])
	EV0mesh = GL.GLGrid(Vi, EV0)
	FV0mesh = GL.GLGrid(Vi, FV0)
	EVmesh = GL.GLGrid(Vi, setdiff(EV, EV0), GL.COLORS[2], 1)
	FVmesh = GL.GLGrid(Vi, setdiff(FV, FV0), GL.COLORS[7], 1)
	#GL.VIEW([EV0mesh; FV0mesh; EVmesh; FVmesh])
end

print_timer(AlphaStructures.to);
