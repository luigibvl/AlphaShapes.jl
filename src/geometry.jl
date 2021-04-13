using Base.Threads
#===============================================================================
#
#	src/geometry.jl
#
#	This file contains:
#
#	 - findCenter(
#			P::Lar.Points
#		)::Array{Float64,1}
#
#	 - findClosestPoint(
#			Psimplex::Lar.Points,
#			P::Lar.Points;
#			metric = "circumcenter"
#		)::Union{Int64, Nothing}
#
#	 - findMedian(
#			P::Lar.Points,
#			ax::Int64
#		)::Float64
#
#	 - findRadius(
#			P::Lar.Points,
#			center=false;
#			digits=64
#		)::Union{Float64, Tuple{Float64, Array{Float64,1}}}
#
#	 - matrixPerturbation(
#			M::Array{Float64,2};
#			atol = 1e-10,
#			row = [0],
#			col = [0]
#		)::Array{Float64,2}
#
#	 - oppositeHalfSpacePoints(
#			P::Lar.Points,
#			face::Array{Float64,2},
#			point::Array{Float64,1}
#		)::Array{Int64,1}
#
#	 - planarIntersection(
#			P::Lar.Points,
#			face::Array{Int64,1},
#			axis::Int64,
#			off::Float64
#		)::Int64
#
#	 - simplexFaces(
#			σ::Array{Int64,1}
#		)::Array{Array{Int64,1},1}
#
#	 - vertexInCircumball(
#			P::Lar.Points,
#			α_char::Float64,
#			point::Array{Float64,2}
#		)::Bool
#
===============================================================================#

"""
	findCenter(P::Lar.Points)::Array{Float64,1}

Evaluates the circumcenter of the `P` points.

If the points lies on a `d-1` circumball then the function is not able
to perform the evaluation and therefore returns a `NaN` array.

# Examples

```jldoctest
julia> V = [
 0.0 1.0 0.0 0.0
 0.0 0.0 1.0 0.0
 0.0 0.0 0.0 1.0
];

julia> AlphaStructures.findCenter(V)
3-element Array{Float64,1}:
 0.5
 0.5
 0.5

```
"""
@timeit to "findCenter" function findCenter(P::Lar.Points)::Array{Float64,1}
	dim, n = size(P)
	@assert n > 0		"findCenter: at least one points is needed."
	@assert dim >= n-1	"findCenter: Too much points"
	@assert dim < 4		"findCenter: Function not yet Programmed."

	if n == 1
		center =  P[:, 1]

	elseif n == 2
		#for each dimension
		center =  (P[:, 1] + P[:, 2]) / 2

	elseif n == 3
		#https://www.ics.uci.edu/~eppstein/junkyard/circumcenter.html
		if dim == 2
			denom = 2 * Lar.det([ P[:, 2] - P[:, 1]  P[:, 3] - P[:, 1] ])
			deter = (P[:, 2] - P[:, 1]) * Lar.norm(P[:, 3] - P[:, 1])^2 -
					(P[:, 3] - P[:, 1]) * Lar.norm(P[:, 2] - P[:, 1])^2
			numer = [- deter[2], deter[1]]
			center = P[:, 1] + numer / denom

		elseif dim == 3
			#circumcenter of a triangle in R^3
			numer = Lar.norm(P[:, 3] - P[:, 1])^2 * Lar.cross(
						Lar.cross(P[:, 2] - P[:, 1], P[:, 3] - P[:, 1]),
						P[:, 2] - P[:, 1]
					) +
					 Lar.norm(P[:, 2] - P[:, 1])^2 * Lar.cross(
				  		P[:, 3] - P[:, 1],
						 Lar.cross(P[:, 2] - P[:, 1], P[:, 3] - P[:, 1]
					)
			)
			#numer=fetch(numer)
			denom = 2 * ( Lar.norm(
				 Lar.cross(P[:, 2] - P[:, 1], P[:, 3] - P[:, 1])
			))^2
			#denom=fetch(denom)
			center = P[:, 1] + numer / denom
		end

	elseif n == 4 #&& dim = 3
		# https://people.sc.fsu.edu/~jburkardt/presentations
		#	/cg_lab_tetrahedrons.pdf
		# page 6 (matrix are transposed)
		α = Lar.det([P; ones(1, 4)])
		#α=fetch(α)
		sq = sum(abs2, P, dims = 1)
		Dx =  Lar.det([sq; P[2:2,:]; P[3:3,:]; ones(1, 4)])
		#Dx= fetch(Dx)
		Dy = Lar.det([P[1:1,:]; sq; P[3:3,:]; ones(1, 4)])
		#Dy= fetch(Dy)
		Dz = Lar.det([P[1:1,:]; P[2:2,:]; sq; ones(1, 4)])
		#Dz=fetch(Dz)
		center = [Dx; Dy; Dz]/2α
	end

	return center
#	AlphaStructures.foundCenter([P[:,i] for i = 1 : size(P, 2)])[:,:]
end

#-------------------------------------------------------------------------------

"""
	findClosestPoint(
		Psimplex::Lar.Points, P::Lar.Points;
		metric = "circumcenter"
	)::Union{Int64, Nothing}

Returns the index of the closest point in `P` to the `Psimplex` points,
according to the distance determined by the keyword argument `metric`.
Possible choices are:
 - `circumcenter`: (default) returns the point that minimize the circumradius
 - `dd`: like `circumcenter` but the circumradius is considered to be negative
    if the circumcenter is opposite to the new point with respect to `Psimplex`.
"""
@timeit to "findClosestPoint" function findClosestPoint(
		Psimplex::Lar.Points, P::Lar.Points;
		metric = "circumcenter"
	)::Union{Int64, Nothing}

	@assert metric ∈ ["circumcenter", "dd"] "findClosestPoint: available metrics are
		`circumcenter` and `dd`."

	simplexDim = size(Psimplex, 2)
	@assert simplexDim <= size(Psimplex, 1) "findClosestPoint: Cannot add
	another point to the simplex."

	@assert (m = size(P, 2)) != 0 "findClosestPoint: No Points in `P`."

	radlist = SharedArray{Float64}(m)
	for col = 1 : m
		r, c =  findRadius([Psimplex P[:,col]], true)
		   #r= fetch(r)
		   #c=fetch(c)
		sameSign = (
			r == Inf ||
			metric != "dd" ||
			isempty(AlphaStructures.oppositeHalfSpacePoints(
				[Psimplex P[:,col]], Psimplex, c
			))
		)
		radlist[col] = ((-1)^(1 + sameSign)) * r
	end

	radius, closestidx = findmin(radlist)
	#radius=fetch(radius)
	#closestidx=fetch(closestidx)

	if radius == Inf
		closestidx = nothing
	end

	return closestidx

end

#-------------------------------------------------------------------------------

"""
	findMedian(P::Lar.Points, ax::Int64)::Float64

Returns the median of the `P` points across the `ax` axis
"""
@timeit to "findMedian" function findMedian(P::Lar.Points, ax::Int64)::Float64
	xp = sort(unique(P[ax, :]))
	if length(xp) == 1
		median = xp[1]
	else
		idx = Int64(floor(length(xp)/2))
		median = (xp[idx] + xp[idx+1])/2
	end
	return median
end

#-------------------------------------------------------------------------------

"""
	findRadius(
		P::Lar.Points, center=false; digits=64
	)::Union{Float64, Tuple{Float64, Array{Float64,1}}}

Returns the value of the circumball radius of the given points.
If the function findCenter is not able to determine the circumcenter
than the function returns `Inf`.

If the optional argument `center` is set to `true` than the function
returns also the circumcenter cartesian coordinates.

_Obs._ Due to numerical approximation errors, the radius is choosen
as the smallest distance between a point in `P` and the center.

# Examples
```jldoctest

julia> V = [
 0.0 1.0 0.0 0.0
 0.0 0.0 1.0 0.0
 0.0 0.0 0.0 1.0
];

julia> AlphaStructures.findRadius(V)
 0.8660254037844386

julia> AlphaStructures.findRadius(V, true)
 (0.8660254037844386, [0.5, 0.5, 0.5])

```
"""
@timeit to "findRadius" function findRadius(
		P::Lar.Points, center=false; digits=64
	)::Union{Float64, Tuple{Float64, Array{Float64,1}}}
	minNorms=0
	norm=[]
 	c = AlphaStructures.findCenter(P)

	if any(isnan, c)
		r = Inf
	else
		#per paralellizzare il metodo abbiamo trasformato questo codice nel
		#codice che segue

		r = round(
			findmin([Lar.norm(c - P[:, i]) for i = 1 : size(P, 2)])[1],
			digits = digits
		)
		"""
		for i = 1 : size(P, 2)
			 push!(norm,Lar.norm(c - P[:, i]))
		end

		minNorms = findmin(norm)
		r = round(minNorms[1],digits = digits)
		"""
	end
	if center
		return r, c
	end
	return r
end

#-------------------------------------------------------------------------------

"""
	matrixPerturbation(
		M::Array{Float64,2};
		atol = 1e-10,
		row = [0],
		col = [0]
	)::Array{Float64,2}

Returns the matrix `M` with a ±`atol` perturbation on each value determined
by the `row`-th rows and `col`-th columns.
If `row` / `col` are set to `[0]` (or not specified) then all the
rows / columns are perturbated.

# Examples
```jldoctest

julia> V = [
 0.0 1.0 0.0 0.0
 0.0 0.0 1.0 0.0
 0.0 0.0 0.0 1.0
];

julia> AlphaStructures.matrixPerturbation(V)
3×4 Array{Float64,2}:
 -1.27447e-11   1.0           4.68388e-11  3.08495e-11
  1.17657e-11  -4.25106e-11   1.0          5.62396e-11
  7.01741e-11  -4.10229e-11  -4.36708e-11  1.0

"""
@timeit to "matrixPerturbation" function matrixPerturbation(
		M::Array{Float64,2};
		atol=1e-10, row = [0], col = [0]
	)::Array{Float64,2}

	if atol == 0.0
		println("Warning: no perturbation has been performed.")
		return M
	end

	if row == [0]
		#Per parallelizzare il metodo, abbiamo trasformato questo codice nel
		#codice che segue
		row = [i for i = 1 : size(M, 1)]
		"""
		row=[0]
		for i=1 : size(M,1)
			push!(row,i)
		end
		"""
	end
	if col == [0]
		#Per parallelizzare il metodo, abbiamo trasformato questo codice nel
		#codice che segue
		#col = [i for i = 1 : size(M, 2)]
		col=[]
		for i=1 :size(M,2)
			push!(col,i)
		end

	end

	N = copy(M)
	perturbation = mod.(rand(Float64, length(row), length(col)), 2*atol).-atol
	N[row, col] = M[row, col] + perturbation
	return N
end

#-------------------------------------------------------------------------------

"""
	oppositeHalfSpacePoints(
			P::Lar.Points,
			face::Array{Float64,2},
			point::Array{Float64,1}
		)::Array{Int64,1}

Returns the index list of the points `P` located in the halfspace defined by
`face` points that do not contains the point `point`.

_Obs._ Dimension Dipendent, only works if dimension is three or less and
	the number of points in the face is the same than the dimension.

# Examples
```jldoctest
julia> V = [
 0.0 1.0 0.0 0.0 4.0 -1. 1.0
 0.0 0.0 1.0 0.0 1.0 0.0 1.0
 0.0 0.0 0.0 1.0 2.0 0.0 1.0
];

julia> oppositeHalfSpacePoints(V, V[:, [2; 3; 4]], V[:, 1])
2-element Array{Int64,1}:
 5
 7

julia> oppositeHalfSpacePoints(V, V[:, [1; 2; 3]], V[:, 4])
0-element Array{Int64,1}

julia> oppositeHalfSpacePoints(V, V[:, [1; 3; 4]], V[:, 2])
1-element Array{Int64,1}:
 6

```
"""
@timeit to "oppositeHalfSpacePoints" function oppositeHalfSpacePoints(
		P::Lar.Points,
		face::Array{Float64,2},
		point::Array{Float64,1}
	)::Array{Int64,1}

	dim, n = size(P)
	noV = size(face, 2)
	@assert dim <= 3 "oppositeHalfSpacePoints: Not yet coded."
	@assert noV == dim "oppositeHalfSpacePoints:
		Cannot determine opposite to non hyperplanes."
	if dim == 1
		threshold = face[1]
		opposite=[]
		if point[1] < threshold
			#Per parallelizzare il metodo, abbiamo trasformato questo codice nel
			#codice che segue
			opposite = [i for i = 1 : n if P[1, i] > threshold]
			"""
			for i=1 : n
				if P[1,i] > threshold
					push!(opposite,i)
				end
			end
			"""
		else
			#Per parallelizzare il metodo, abbiamo trasformato questo codice nel
			#codice che segue
			opposite = [i for i = 1 : n if P[1, i] < threshold]
			"""
			for i =1 : n
				if P[1,i]< threshold
					push!(opposite,i)
				end
			end
			"""
		end
	elseif dim == 2
		if (Δx = face[1, 1] - face[1, 2]) != 0.0
			m = (face[2, 1] - face[2, 2]) / Δx
			q = face[2, 1] - m * face[1, 1]
			# false = under the line, true = over the line
			@assert point[2] ≠ m * point[1] + q "oppositeHalfSpacePoints,
				the point belongs to the face"
			side = sign(m * point[1] + q - point[2])
			#Per parallelizzare il metodo, abbiamo trasformato questo codice nel
			#codice che segue
			opposite =
				[i for i = 1 : n if side * (m * P[1, i] + q - P[2, i]) < 0]
				"""
			for i=1 : n
				if side * (m * P[1, i] + q - P[2, i]) < 0
					push!(opposite,i)
				end
			end
			"""
		else
			q = face[1, 1]
			side = sign(point[1] - q)
			opposite = [i for i = 1 : n if side * (P[1, i] - q) < 0]
			"""
			for i = 1 : n
				if side * (P[1, i] - q) < 0
					push!(opposite,i)
				end
			end
			"""
		end


	elseif dim == 3
		axis =Threads.@spawn Lar.cross(
			face[:, 2] - face[:, 1],
			face[:, 3] - face[:, 1]
		)
		axis = fetch(axis)
		off = Threads.@spawn Lar.dot(axis, face[:, 1])
		off = fetch(off)
		position = Threads.@spawn Lar.dot(point, axis)
		position = fetch(position)
		#Per parallelizzare il metodo, abbiamo trasformato questo codice nel
		#codice che segue
		if position < off
			opposite = [i for i = 1:size(P, 2) if Lar.dot(P[:,i], axis) > off]
			"""
			for i=1 : size(P,2)
				if Lar.dot(P[:,i], axis) > off
					push!(opposite,i)
				end
			end
			"""
		else
			opposite = [i for i = 1:size(P, 2) if Lar.dot(P[:,i], axis) < off]
			"""
			for i = 1:size(P, 2)
				if Lar.dot(P[:,i], axis) < off
					push!(opposite,i)
				end
			end
			"""
		end
	end

	return [
		i for i in opposite
		if sum([P[:, i] == face[:, j] for j = 1 : noV]) == 0
	]
	"""
	faces=[]
	for i in opposite
		check= 0
		for j = 1 : noV
			if P[: , i] == face[:,j]
				check=check + 1
			end
		end
		if check == 0
			push!(faces,1)
		end
	end
	"""


end

#-------------------------------------------------------------------------------

"""
	planarIntersection(
		P::Lar.Points,
		face::Array{Int64,1},
		axis::Int64,
		off::Float64
	)::Int64

Computes the position of `face` with respect to the hyperplane `α` defined by
the normal `axis` and the contant term `off`. It returns:
 - `+0` if `f` intersect `α` internum (not only the boundary)
 - `+1` if `f` is completely contained in the positive half space of `α`
 - `-1` if `f` is completely contained in the negative half space of `α`
"""
@timeit to "planarIntersection" function planarIntersection(
		P::Lar.Points,
		face::Array{Int64,1},
		axis::Int64,
		off::Float64
	)::Int64
	#per paralellizzare il metodo abbiamo trasformato questo codice nel
	#codice che segue

<<<<<<< HEAD
	pos = [P[axis, i] > off for i in face]
	#for i in face
	#	pos=[P[axis,i] > off]
	#end
	if sum([P[axis, i] == off for i in face]) == length(pos)
		position = 0
	"""
=======
	#pos = [P[axis, i] > off for i in face]
	pos=[]
	for i in face
		if P[axis,i] > off
			push!(pos,1)
		else
			push!(pos,0)
		end
	end
	#if sum([P[axis, i] == off for i in face]) == length(pos)
>>>>>>> 6c3cd26046eee2ab163b23d199c2fd43dcd06f4b
	S=0
	for i in face
		if P[axis,i] == off
			S+=1
		end
	end
	position = 0 # face coplanar with axis
	"""
	#if S==length(pos)
	#	position= 0

	elseif sum(pos) == 0
		position = -1
	elseif sum(pos) == length(pos)
		position = +1
	else
		position = 0
	end

	return position
end

#-------------------------------------------------------------------------------

"""
	simplexFaces(σ::Array{Int64,1})::Array{Array{Int64,1},1}

Returns the faces of the simplex `σ`.

_Obs._ The faces are ordered by the index value.

# Examples
```jldoctest

julia> σ = [1; 3; 2; 4];

julia> AlphaStructures.implexFaces(σ)
4-element Array{Array{Int64,1},1}:
 [1, 2, 3]
 [1, 2, 4]
 [1, 3, 4]
 [2, 3, 4]
```
"""
@timeit to "simplexFaces" function simplexFaces(σ::Array{Int64,1})::Array{Array{Int64,1},1}
    sort!(sort!.(collect(Combinatorics.combinations(σ, length(σ)-1))))
end

#-------------------------------------------------------------------------------

"""
	vertexInCircumball(
		P::Lar.Points,
		α_char::Float64,
		point::Array{Float64,2}
	)::Bool

Determine if a point is inner of the circumball determined by `P` points
	and radius `α_char`.

"""
@timeit to "vertexInCircumball" function vertexInCircumball(
		P::Lar.Points,
		α_char::Float64,
		point::Array{Float64,2}
	)::Bool

	center = AlphaStructures.findCenter(P)
	return Lar.norm(point - center) <= α_char
end
