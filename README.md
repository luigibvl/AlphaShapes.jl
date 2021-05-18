# AlphaShapes
Progetto per il corso Parallel and Distributed Computing 2020/2021.

Questo progetto contiene l'analisi e la parallelizzaione del pacchetto [AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl).
# AlphaStructures.jl
[AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl) è una libreria Julia che consente di analizzare le nuvole di punti.

Utilizzando AlphaStructures.jl è possibile:

- Valutare la "α-Shape" di una nuvola di punti.
- Calcolare la "α-Filtration" di una nuvola di punti.
- Creare la "α-Complex" di una nuvola di punti.
- Trovare alcune nozioni di base sulla valutazione dell'omologia persistente di una nuvola di punti.

Esempio 2D di questo package al variare del parametro α:
  ![2D example](https://github.com/luigibvl/AlphaShapes.jl/blob/master/docs/lar.png)
Esempio 3D di questo package al variare del parametro α:
  ![2D example](https://github.com/luigibvl/AlphaShapes.jl/blob/master/docs/teapot.png)
 
per maggiori informazioni visitare: [AlphaStructures.jl Documentation](https://eonofri04.github.io/AlphaStructures.jl/dev/)

# Obiettivi di AlphShapes.jl
- Lo studio del pacchetto [AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl) e di tutte le funzioni e strutture dati utilizzate al suo interno
- La successiva suddivisione delle funzioni (quando possibile) in singoli tasks
- La creazione di una descrizione per ogni task, tipologia e significato di ogni parametro e valore di ritorno
- Stimare comportamenti e tempi delle singole funzioni mirando ad una loro ottimizzazione
- Parallelizzare il codice utilizzando le macro Julia dove possibile.
# Dipendenze
AlphShapes.jl ha le seguenti dipendenze:
- [Julia 1.5.3](https://julialang.org/downloads/)
- [LinearAlgebraicRepresentation.jl](https://github.com/cvdlab/LinearAlgebraicRepresentation.jl.git) di CVDLab
- [TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl.git) di KristofferC
- [SharedArrays.jl](https://github.com/JuliaLang/julia/tree/master/stdlib/SharedArrays) di JuliaLang
- [Distributed.jl](https://github.com/JuliaLang/julia/tree/master/stdlib/Distributed) di JuliaLang
- [Triangle.jl](https://github.com/cvdlab/Triangle.jl.git) di CVDLab
- [Combinatorics.jl](https://github.com/JuliaMath/Combinatorics.jl.git) di JuliaMath
- [DataStructures.jl](https://github.com/JuliaCollections/DataStructures.jl.git) di JuliaCollection
- [viewerGL.jl](https://github.com/cvdlab/ViewerGL.jl.git) di CVDLab

# Installazione ed utilizzo
- Installare il package tramite Pkg, gestore di pacchetti di Julia, digitando Pkg.add(url="ht<span>tps://</span>github.com/luigibvl/AlphaShapes.jl")
- Utilizzare il modulo appena installato utilizzando la parola chiave *using*
