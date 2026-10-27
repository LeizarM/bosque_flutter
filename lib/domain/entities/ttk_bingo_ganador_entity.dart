/// Ganador confirmado de un juego. El encargado lo ve con su cartón; la sala,
/// solo con nombre y foto (codEmpleado; sin él es un invitado).
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

  /// Ganó el desempate entre los confirmados del juego; los demás empataron.
  final bool ganoDesempate;
  final String? motivoDesempate;
  final DateTime? fechaDesempate;

  /// Dos o más confirmados con el juego en curso: se puede resolver o cambiar.
  final bool puedeResolverEmpate;
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
    this.ganoDesempate = false,
    this.motivoDesempate,
    this.fechaDesempate,
    this.puedeResolverEmpate = false,
    this.audUsuario,
    this.audFecha,
  });
}
