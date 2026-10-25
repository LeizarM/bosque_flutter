/// Un bolillo del tablero: su letra, si ya salió y en qué orden.
class TtkBingoSorteoEntity {
  final BigInt? codSorteo;
  final BigInt? codBingo;
  final int? nroJuego;
  final int nroBolillo;
  final int columna;
  final String letra;
  final String etiqueta;
  final bool marcado;
  final int? orden;
  final DateTime? audFecha;

  const TtkBingoSorteoEntity({
    this.codSorteo,
    this.codBingo,
    this.nroJuego,
    this.nroBolillo = 0,
    this.columna = 0,
    this.letra = '',
    this.etiqueta = '',
    this.marcado = false,
    this.orden,
    this.audFecha,
  });
}
