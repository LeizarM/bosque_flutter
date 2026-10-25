/// Un «¡Bingo!» que avisó un participante desde su pantalla. Solo lo ve el
/// encargado; nunca dice si el cartón ganó: eso se revisa con Validar.
class TtkBingoAvisoEntity {
  final BigInt? codAviso;
  final BigInt? codBingo;
  final BigInt? codJuego;
  final int nroJuego;
  final BigInt? codCarton;
  final int nroCarton;
  final String? nombreEmpleado;
  final bool impreso;

  /// P pendiente, A atendido.
  final String estado;
  final DateTime? fechaAviso;
  final String mensaje;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkBingoAvisoEntity({
    this.codAviso,
    this.codBingo,
    this.codJuego,
    this.nroJuego = 0,
    this.codCarton,
    this.nroCarton = 0,
    this.nombreEmpleado,
    this.impreso = false,
    this.estado = 'P',
    this.fechaAviso,
    this.mensaje = '',
    this.audUsuario,
    this.audFecha,
  });
}
