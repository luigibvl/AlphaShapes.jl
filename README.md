# AlphaShapes
progetto del corso Parallel Computing e Distrubo 2020
questo progetto contiene analisi e la revisione del pacchetto [AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl).
# AlphaStructures.jl
[AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl) è una libreria di Julia e produce uno strumento per analisi della nuvola di punti.

utilizzando AlphaStructures.jl si può:

- valutare "α-Shape" di una nuvola di punti.
- calcolare "α-Filtration" di una nuvola di punti.
- creare "α-Complex" di una nuvola di punti.
- trovare alcune nozioni di base sulla valutazione dell'omologia persistente di una nuvola di punti.
  foto
foto
foto
per maggiori informazioni può visitare: [AlphaStructures.jl Documentation](https://eonofri04.github.io/AlphaStructures.jl/dev/)

# Immigrazione da AlphStructres.jl ad AlphShapes.jl
 gli obbiettivi di questo progetto sono stati lo studio del pacchetto [AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl) e tutte le funzioni e strutture dati da esso utilizzate, suddivisione delle funzioni (quando possibile) in singoli tasks, descrivere per ogni task tipologia e significato di ogni parametro e valoredi ritorno, stimare comportamenti e tempi delle singole funzioni mirando ad ottimizzarli e parallelizzare il codice utilizzando delle macro dove possibile.
# Dipendenze
AlphShapes.jl ha le seguenti dipendenze:
[LinearAlgebraicRepresentation.jl](https://github.com/cvdlab/LinearAlgebraicRepresentation.jl.git) da CVDLab
[TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl.git)di KristofferC
[SharedArrays.jl]() di JuliaLang
[Distributed.jl di JuliaLang
[Triangle.jl da CVDLab
[Combinatorics.jl di JuliaMath
[DataStructures.jl da JuliaCollection
[Base.Threads di JuliaLang
[viewerGL.jl da CVDLab
