/// Ganador confirmado de un juego. Solo lo ve el encargado.
class TtkBingoGanadorEntity {
  final BigInt? codGanador;
  final BigInt? codJuego;
  final BigInt? codBingo;
  final int nroJuego;
  final String nombreJuego;
  final BigInt? codCarton;
  final int nroCarton;
  final BigInt? codEmpleado;
  final String? nombreEmpleado;
  final int? ordenBolillo;
  final int? nroBolillo;
  final bool puedeAnular;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkBingoGanadorEntity({
    this.codGanador,
    this.codJuego,
    this.codBingo,
    this.nroJuego = 0,
    this.nombreJuego = '',
    this.codCarton,
    this.nroCarton = 0,
    this.codEmpleado,
    this.nombreEmpleado,
    this.ordenBolillo,
    this.nroBolillo,
    this.puedeAnular = false,
    this.audUsuario,
    this.audFecha,
  });
}
