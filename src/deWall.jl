export delaunayWall;
#===============================================================================
#
#	src/deWall.jl
#
#	This File Contains:
#
#	 - delaunayWall(
#			P::Lar.Points,
#			ax = 1,
#			Pblack = Float64[],
#			AFL = Array{Int64,1}[],
#			tetraDict = DataStructures.Dict{Array{Int64,1},Array{Float64,1}}();
#			DEBUG = false
#		)::Lar.Cells
#
#	 - firstDeWallSimplex(
#			P::Lar.Points,
#			ax::Int64,
#			off::Float64;
#			DEBUG = false
#		)::Array{Int64,1}
#
#	 - findWallSimplex(
#			P::Lar.Points,
#			blackidx::Int64,
#			face::Array{Int64,1},
#			oppoint::Array{Float64,1};
#			DEBUG = false
#		)::Union{Array{Int64,1}, Nothing}
#
#	 - recursiveDelaunayWall(
# 			P::Lar.Points,
#			Pblack::Lar.Points,
# 			tetraDict::DataStructures.Dict{Array{Int64,1},Array{Float64,1}},
# 			AFL::Array{Array{Int64,1},1},
# 			ax::Int64,
# 			off::Float64,
# 			positive::Bool;
# 			DEBUG = false
# 		)::Lar.Cells
#
#	 - updateAFL!(
#			P::Lar.Points
#			new::Array{Int64,1}[],
#			AFLα = Array{Int64,1}[],
#			AFLplus = Array{Int64,1}[],
#			AFLminus = Array{Int64,1}[],
#			ax::Int64,
#			off::Float64;
# 			DEBUG = false
#		)::Bool
#
#	 - updatelist!(
#			list,
#			element
#		)::Bool
#
#	 - updateTetraDict!(
#			P::Lar.Points,
#			tetraDict::DataStructures.Dict{Array{Int64,1},Array{Float64,1}},
#			AFL::Array{Array{Int64,1},1},
#			σ::Array{Int64,1}
#		)::Nothing
#
===============================================================================#

"""
	delaunayWall(
		P::Lar.Points, ax = 1, Pblack::Float64[], AFL = Array{Int64,1}[],
		tetraDict = DataStructures.Dict{Array{Int64,1},Array{Float64,1}}();
		DEBUG = false
	)::Lar.Cells

Return the Delaunay Triangulation of sites `P` via Delaunay Wall algorithm.
The optional argument `ax` specify on wich axis it will build the Wall.
The optional argument `AFL` is used in recursive call.
If the keyword argument `DEBUG` is set to true than all the procedure is shown.

# Examples
```jldoctest

julia> P = [
 0.0 1.0 0.0 1.0 0.0 1.0 0.0 1.0
 0.0 0.0 1.0 1.0 0.0 0.0 1.0 1.0
 0.0 0.0 0.0 0.0 1.0 1.0 1.0 1.0
];

julia> DT = AlphaShapes.delaunayWall(P)
6-element Array{Array{Int64,1},1}:
 [1, 2, 4, 5]
 [1, 3, 4, 5]
 [2, 4, 5, 6]
 [3, 4, 5, 7]
 [4, 5, 6, 7]
 [4, 6, 7, 8]

```
"""

@timeit to "computeFirstSimplex" function computeFirstSimplex(P::Lar.Points,
	ax::Int64,
	off::Float64,
	tetraDict::Dict{Array{Int64,1},Array{Float64,1}},
	DT::Array{Array{Int64,1},1},
	DEBUG::Bool)::Array{Array{Int64,1},1}

	σ = sort(AlphaShapes.firstDeWallSimplex(P, ax, off, DEBUG = DEBUG))
	push!(DT, σ)
	AFL = @spawn AlphaShapes.simplexFaces(σ)
	AFL = fetch(AFL)

	AlphaShapes.updateTetraDict!(P, tetraDict, AFL, σ)
	return AFL
end

@timeit to "delaunayWall" function delaunayWall(
		P::Lar.Points,
		ax = 1,
		Pblack = Float64[],
		AFL = Array{Int64,1}[],
		tetraDict = DataStructures.Dict{Array{Int64,1},Array{Float64,1}}();
		DEBUG = false
	)::Lar.Cells

	if DEBUG @show "Delaunay Wall with parameters" P ax AFL tetraDict end

	# 0 - Data Reading and Container definition
	DT = Array{Int64,1}[]		# Delaunay Triangulation
	AFLα = Array{Int64,1}[]		# (d-1)faces intersecting the Wall
	AFLplus = Array{Int64,1}[]  # (d-1)faces in positive Wall half-space
	AFLminus = Array{Int64,1}[] # (d-1)faces in positive Wall half-space
	off =  AlphaShapes.findMedian(P, ax)

	if !isempty(Pblack) Pext = [P Pblack] else Pext = copy(P) end

	# 1 - Determine first simplex (if necessary)
	if isempty(AFL)
		@assert isempty(Pblack) "delaunayWall: If AFL is empty => Pblack must be"
		@assert isempty(tetraDict) "delaunayWall: If AFL is empty => tetraDict must be"
		AFL =  computeFirstSimplex(P,ax,off,tetraDict,DT,DEBUG)
	else
		@assert !isempty(Pblack) "delaunayWall: Data missing - Pblack"
		@assert !isempty(AFL) "delaunayWall: Data missing - AFL"
		@assert !isempty(tetraDict) "delaunayWall: Data missing - tetraDict"
	end

	# 2 - Build `AFL*` according to the axis `ax` with constant term `off`
	AlphaShapes.updateAFL!(
		P, AFL, AFLα, AFLplus, AFLminus, ax, off, DEBUG = DEBUG
	)

	# 4 - Build simplex Wall
	while !isempty(AFLα)
		# if face ∈ keys(tetraDict) oppoint = tetraDict[face]
		# else Pselection = setdiff([i for i = 1 : n], face) end

		σ =  AlphaShapes.findWallSimplex(
				Pext, AFLα[1], tetraDict[AFLα[1]], size(P, 2), DEBUG = DEBUG
			)
		if σ != nothing && σ ∉ DT
			push!(DT, σ)
			AFL = @spawn AlphaShapes.simplexFaces(σ)
			AFL = fetch(AFL)

			AlphaShapes.updateTetraDict!(P, tetraDict, AFL, σ)
			# Split σ's Faces according in semi-spaces
			AlphaShapes.updateAFL!(
				P, AFL, AFLα, AFLplus, AFLminus, ax, off, DEBUG=DEBUG
			)
		else
			@assert AlphaShapes.updatelist!(AFLα, AFLα[1]) == false "delaunayWall:
				Something unespected happends while removing a face."
		end
	end


	# 5 - Change the axis `ax` and repeat until there are no faces but exposed.
	#      A.K.A. Divide & Conquer phase.

	if !isempty(AFLminus)
		res = @spawn recursiveDelaunayWall(P, Pblack, tetraDict, AFLminus, ax, off, false; DEBUG = DEBUG)
		union!(DT, fetch(res))
	end

	if !isempty(AFLplus)
		res = @spawn recursiveDelaunayWall(P, Pblack, tetraDict, AFLplus, ax, off, true; DEBUG = DEBUG)
		union!(DT, fetch(res))
	end

	return DT
end


#-------------------------------------------------------------------------------
"""
	findWallSimplex(
		P::Lar.Points,
		face::Array{Int64,1}, oppoint::Array{Float64,1},
		blackidx = size(P, 2);
		DEBUG = false
	)::Union{Array{Int64,1}, Nothing}

Returns the simplex 'σ' build with `face` and a point from `P[:, 1:blackidx]`
such that it is in the opposite half plane of `oppoint`.
If such a simplex do not exists it returns `nothing`.
If `blackidx` is not specified all the points `P` are treaten as valid.
If the keyword argument `DEBUG` is set to true than all the procedure is shown.

# Examples
```jldoctest

julia> P = [
 0. 1. 0. 0. 2.;
 0. 0. 1. 0. 2.;
 0. 0. 0. 1. 2.
];

julia> newtetra = AlphaShapes.findWallSimplex(P,[2,3,4],[0., 0., 0.])
4-element Array{Int64,1}:
 2
 3
 4
 5

```
"""
@timeit to "findWallSimplex" function findWallSimplex(
		P::Lar.Points,
		face::Array{Int64,1},
		oppoint::Array{Float64,1},
		blackidx = size(P, 2);
		DEBUG = false
	)::Union{Array{Int64,1}, Nothing}

	if DEBUG @show "find Wall Simplex of" face oppoint end
	# Find the points in the halfspace defined by `face` that do not
	#  containsother the other point of the simplex.
	Pselection =
		@spawn AlphaShapes.oppositeHalfSpacePoints(P, P[:, face], oppoint)
	Pselection = fetch(Pselection)


	if DEBUG @show Pselection end

	# If there are no such points than the face is part of the convex hull.
	if isempty(Pselection)
		return nothing
	end

	# Find the Closest Point in the other halfspace with respect to σ
	#  according to dd-distance.
	idxbase = @spawn Pselection[ AlphaShapes.findClosestPoint(
		P[:, face], P[:, Pselection], metric = "dd"
	) ]
	idxbase=fetch(idxbase)

	# It prevent from adding the same simplex again (cause it has been
	#  determined in a previous recursive call in the stacktrace).
	if idxbase > blackidx
		if DEBUG println("Excluding $face cause simplex already inside.") end
		return nothing
	end


	σ =  sort([face; idxbase])
	if DEBUG @show "Found face" σ end

	# Check the simplex correctness
	radius, center = AlphaShapes.findRadius(P[:, σ], true)

	for i = 1 : size(P, 2)
		if Lar.norm(center - P[:, i]) < radius - 1.e-14
			# @assert i ∉ Pselection "ERROR: Numerical error
			# 	evaluating minimum radius for $σ"
			if DEBUG println("$σ discarded due to a closer point.") end
			return nothing
		end
	end

	return σ
end


#-------------------------------------------------------------------------------

"""
 	firstDeWallSimplex(
		P::Lar.Points, ax::Int64, off::Float64;
		DEBUG = false
	)::Array{Int64,1}

Returns the indices array of the points in `P` that form the first thetrahedron
built over the Wall if the `ax` axes with contant term `off`.
If the keyword argument `DEBUG` is set to true than all the procedure is shown.

# Examples
```jldoctest

julia> V = [
	0.0 1.0 0.0 0.0 2.0
	0.0 0.0 1.0 0.0 2.0
	0.0 0.0 0.0 1.0 2.0
];

julia> firstDeWallSimplex(V, 1, AlphaShapes.findMedian(V,1))
4-element Array{Int64,1}:
 1
 2
 3
 4

```
"""
@timeit to "firstDeWallSimplex" function firstDeWallSimplex(
		P::Lar.Points,
		ax::Int64,
		off::Float64;
		DEBUG = false
	)::Array{Int64,1}

	dim = size(P, 1)
    n = size(P, 2)

	if DEBUG println("Determine first Simplex with ax = $ax") end
    # the first point of the simplex is the one with coordinate `ax` maximal
    #  such that it is less than `off` (closer to α from minus)

	Pselection = findall(x -> x < off, P[ax, :])
	# it gives an error if no point are less than `off`
	#  in fact it means that all the points are located on the median,
	#  with respect to `ax`.
	@assert !isempty(Pselection) "firstDeWallSimplex: not able to build the first Delaunay
		dimplex; all the points have the same `ax` coordinate."

	newidx =  Pselection[findmax(P[ax, Pselection])[2]]
    # indices will store the indices of the simplex ...
    indices = [newidx]                      #Array{Int64,1}
    # ... and `Psimplex` will store the corresponding points
    Psimplex = P[:, newidx][:,:]    #Array{Float64,2}

    # the second point must be seeken across those with coordinate `ax`
    #  grater than `off`
	Pselection = findall(x -> x > off, P[ax, :])

    @inbounds @simd for d = 1 : dim
		idxbase = @spawn AlphaShapes.findClosestPoint(Psimplex, P[:, Pselection])
		idxbase = fetch(idxbase)

		@assert !isnothing(idxbase) "firstDeWallSimplex:
			not able to determine first Delaunay Simplex"
        newidx = Pselection[idxbase]
        indices = [indices; newidx]
        Psimplex = [Psimplex P[:, newidx]]
        Pselection = [i for i = 1 : n if i ∉ indices]
    end

    # Correctness check
	radius, center = AlphaShapes.findRadius(Psimplex, true)

    for i = 1 : n
		@assert Lar.norm(center - P[:, i]) >= radius "firstDeWallSimplex:
			Unable to find first Simplex."
	end

	if DEBUG println("First Simplex = $indices") end

	return indices
end

#-------------------------------------------------------------------------------

"""
	recursiveDelaunayWall(
		P::Lar.Points,
		Pblack::Lar.Points,
		tetraDict::DataStructures.Dict{Array{Int64,1},Array{Float64,1}},
		AFL::Array{Array{Int64,1},1},
		ax::Int64,
		off::Float64,
		positive::Bool;
		DEBUG = false
	)::Lar.Cells

Utility function that prepeares the Divide phase for Delaunay Wall.
Returns the Delaunay Triangulation for the positve or negative subspace of `P`
(according to `positive`) determined by the hyperplane with normal `ax` and
constant term `off`.
If the keyword argument `DEBUG` is set to true than all the procedure is shown.
"""
@timeit to "recursiveDelaunayWall" function recursiveDelaunayWall(
		P::Lar.Points,
		Pblack::Array{Float64},
		tetraDict::DataStructures.Dict{Array{Int64,1},Array{Float64,1}},
		AFL::Array{Array{Int64,1},1},
		ax::Int64,
		off::Float64,
		positive::Bool;
		DEBUG = false
	)::Lar.Cells

	#DEBUG = true

	dim, n = size(P)
	newaxis = mod(ax, dim) + 1

	if DEBUG println("Divide Plus/Minus $positive") end

	Psubset = @spawn findall(x -> (x > off) == positive, P[ax, :])
	Psubset = fetch(Psubset)

	blacklist = @spawn setdiff(unique([(keys(tetraDict)...)...]), Psubset)
	blacklist = fetch(blacklist)

	if !isempty(Pblack)
		Pblack = [Pblack P[:, blacklist]]
	else
	 	Pblack = P[:, blacklist]
	end

	if DEBUG println("Step In") end

	newAFL= @spawn findAFL(Psubset,AFL)
	newAFL=fetch(newAFL)
	newTetraDict= @spawn findTetradict(Psubset,tetraDict)
	newTetraDict=fetch(newTetraDict)
	DT = AlphaShapes.delaunayWall(
			P[:, Psubset],
			newaxis,
			Pblack,
			newAFL,
			newTetraDict,
			DEBUG = DEBUG
		)

	if DEBUG @show "Step Out with " DT end

	return [[Psubset[i] for i in σ] for σ in DT]
end

@timeit to "findTetradict" function findTetradict(Psubset::Array{Int64,1},tetraDict::DataStructures.Dict{Array{Int64,1},Array{Float64,1}})::Dict{Array{Int64,1},Array{Float64,1}}
	return Dict([
		[findall(Psubset.==p)[1] for p in k] => v
		 for (k,v) in tetraDict
			if k ⊆ Psubset
	])
end

@timeit to "findAFL" function findAFL(Psubset::Array{Int64,1},AFL::Array{Array{Int64,1},1})::Array{Array{Int64,1},1}
	return [[findall(Psubset.==p)[1] for p in σ] for σ in AFL]
end

#-------------------------------------------------------------------------------

"""
	updateAFL!(
		P::Lar.Points
		new::Array{Int64,1}[],
		AFLα = Array{Int64,1}[],
		AFLplus = Array{Int64,1}[],
		AFLminus = Array{Int64,1}[],
		ax::Int64, off::Float64;
		DEBUG = false
	)::Bool

Modify the `AFL*` lists of faces by adding to them the faces inside `new`
(that refers to the points `P`) according to their position with respect
to the axis defined by the normal direction `ax` and the contant term `off`.
The function returns a Bool value that states if the operation was succesfully.
If the keyword argument `DEBUG` is set to true than all the procedure is shown.
"""
@timeit to "updateAFL!" function updateAFL!(
		P::Lar.Points,
		newσ::Array{Array{Int64,1},1},
		AFLα::Array{Array{Int64,1},1},
		AFLplus::Array{Array{Int64,1},1},
		AFLminus::Array{Array{Int64,1},1},
		ax::Int64, off::Float64;
		DEBUG = false
	)::Bool

	@simd for face in newσ
		inters = AlphaShapes.planarIntersection(P, face, ax, off)
    	if inters == 0 # intersected by plane α
			AlphaShapes.updatelist!(AFLα, face)
		elseif inters == -1 # in NegHalfspace(α)
        	AlphaShapes.updatelist!(AFLminus, face)
    	elseif inters == 1 # in PosHalfspace(α)
        	AlphaShapes.updatelist!(AFLplus, face)
    	else
			return false
		end
	end

	if DEBUG @show AFLα AFLminus AFLplus end

	return true

end

#-------------------------------------------------------------------------------

"""
	updatelist!(list, element)::Bool

If `element` is in `list` then it is removed (returns `false`);
If `element` is not in `list` then it is added (returns `true`).

# Examples
```jldoctest
julia> list = [[1, 2, 3, 4], [2, 3, 4, 5]]
2-element Array{Array{Int64,1},1}:
 [1, 2, 3, 4]
 [2, 3, 4, 5]

julia> updatelist!(list, [1, 2, 4, 5])
 true

julia> list
3-element Array{Array{Int64,1},1}:
 [1, 2, 3, 4]
 [2, 3, 4, 5]
 [1, 2, 4, 5]

julia> updatelist!(list, [1, 2, 4, 5])
 false

julia> list
2-element Array{Array{Int64,1},1}:
 [1, 2, 3, 4]
 [2, 3, 4, 5]

```
"""

@timeit to "updatelist!" function updatelist!(list, element)::Bool
	if element ∈ list
		setdiff!(list, [element])
		return false
	else
		push!(list, element)
		return true
	end
end

#-------------------------------------------------------------------------------

"""
	updateTetraDict!(
		P::Lar.Points,
		tetraDict::DataStructures.Dict{Array{Int64,1},Array{Float64,1}},
		AFL::Array{Array{Int64,1},1},
		σ::Array{Int64,1}
	)::Nothing

Update the content of `tetraDict` by adding the outer points of the faces of `σ`
in the dictionary.
"""
@timeit to "updateTetraDict" function updateTetraDict!(
		P::Lar.Points,
		tetraDict::DataStructures.Dict{Array{Int64,1},Array{Float64,1}},
		AFL::Array{Array{Int64,1},1},
		σ::Array{Int64,1}
	)::Nothing

	@simd for cell in AFL
		point = setdiff(σ, cell)
		@assert length(point) == 1 "updateTetraDict!: Error during update of TetraDict $σ, $cell"
		tetraDict[ cell ] = P[:, point[1]]
	end

end
