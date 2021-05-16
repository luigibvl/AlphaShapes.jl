# AlphaShapes
Progetto per il corso Parallel Computing e Distributed 2020/2021.

Questo progetto contiene analisi e la revisione del pacchetto [AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl).
# AlphaStructures.jl
[AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl) è una libreria di Julia che consente di analizzare le nuvole di punti.

Utilizzando AlphaStructures.jl si può:

- Valutare la "α-Shape" di una nuvola di punti.
- Calcolare la "α-Filtration" di una nuvola di punti.
- Creare la "α-Complex" di una nuvola di punti.
- Trovare alcune nozioni di base sulla valutazione dell'omologia persistente di una nuvola di punti.
  - foto
  - foto
  - foto/
per maggiori informazioni visitare: [AlphaStructures.jl Documentation](https://eonofri04.github.io/AlphaStructures.jl/dev/)

# Immigrazione da AlphStructres.jl ad AlphShapes.jl
Gli obiettivi di questo progetto sono stati:
- Lo studio del pacchetto [AlphStructures.jl](https://github.com/eOnofri04/AlphaStructures.jl) e di tutte le funzioni e strutture dati utilizzate al suo interno
- La successiva suddivisione delle funzioni (quando possibile) in singoli tasks
- La creazione di una descrizione per ogni task, tipologia e significato di ogni parametro e valoredi ritorno
- Stimare comportamenti e tempi delle singole funzioni mirando ad una loro ottimizzazione
- Parallelizzare il codice utilizzando le macro di Julia dove possibile.
# Dipendenze
AlphShapes.jl ha le seguenti dipendenze:
- [LinearAlgebraicRepresentation.jl](https://github.com/cvdlab/LinearAlgebraicRepresentation.jl.git) da CVDLab
- [TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl.git)di KristofferC
- [SharedArrays.jl](https://github.com/JuliaLang/julia/tree/master/stdlib/SharedArrays) di JuliaLang
- [Distributed.jl](https://github.com/JuliaLang/julia/tree/master/stdlib/Distributed) di JuliaLang
- [Triangle.jl](https://github.com/cvdlab/Triangle.jl.git) da CVDLab
- [Combinatorics.jl](https://github.com/JuliaMath/Combinatorics.jl.git) di JuliaMath
- [DataStructures.jl](https://github.com/JuliaCollections/DataStructures.jl.git) da JuliaCollection
- [Base.Threads](https://github.com/JuliaLang/julia/tree/master/base) di JuliaLang
- [viewerGL.jl](https://github.com/cvdlab/ViewerGL.jl.git) da CVDLab
