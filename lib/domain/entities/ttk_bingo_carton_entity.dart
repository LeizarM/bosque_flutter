/// Un cartón del bingo. El dueño (empleado o invitado, en `nombreEmpleado`)
/// lo ve únicamente el encargado; el participante solo ve los suyos.
class TtkBingoCartonEntity {
  final BigInt? codCarton;
  final BigInt? codBingo;
  final int nroCarton;
  final BigInt? codEmpleado;
  final BigInt? codParticipante;
  final String? nombreEmpleado;
  final bool esInvitado;
  final String? origen;
  final String? origenTexto;
  final DateTime? fechaAsignacion;

  /// Se entrega impreso; impreso o no, el dueño siempre puede marcarlo en pantalla.
  final bool impreso;
  final String? formaTexto;
  final bool esGanador;
  final bool puedeAsignar;
  final bool puedeCambiarForma;
  final bool puedeLiberar;
  final BigInt? audUsuario;
  final DateTime? audFecha;

  const TtkBingoCartonEntity({
    this.codCarton,
    this.codBingo,
    this.nroCarton = 0,
    this.codEmpleado,
    this.codParticipante,
    this.nombreEmpleado,
    this.esInvitado = false,
    this.origen,
    this.origenTexto,
    this.fechaAsignacion,
    this.impreso = false,
    this.formaTexto,
    this.esGanador = false,
    this.puedeAsignar = false,
    this.puedeCambiarForma = false,
    this.puedeLiberar = false,
    this.audUsuario,
    this.audFecha,
  });

  bool get asignado => codEmpleado != null || codParticipante != null;
}
