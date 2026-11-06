/// Estado de «Mis horas extras» y de las teclas de marcar (D37), tal como lo
/// decide el SP para la jornada actual. La app solo lo muestra: no es un
/// permiso y la marca se vuelve a validar al registrarla.
class HexVistaMarcacionEntity {
  /// Hay una asignación activa para la jornada actual; si no, la vista queda
  /// bloqueada con [textoVista].
  final bool vistaHabilitada;
  final String textoVista;
  final DateTime? fechaJornadaAsignada;
  final BigInt? idAsignacion;
  final String? nombreAsignador;
  final bool puedeMarcarEntrada;
  final String textoMarcarEntrada;

  /// `ANTES` o `SIN_HORARIO`.
  final String? tipoEntrada;
  final bool puedeMarcarSalida;
  final String textoMarcarSalida;
  final DateTime? fechaJornadaSalida;

  /// `DESPUES` o `SIN_HORARIO`.
  final String? tipoSalida;

  /// El corte de la salida: el ingreso del día siguiente, 06:00 o 24 h.
  final DateTime? horaLimiteSalida;

  /// D41: lo que escribió quien asignó; el operario solo lo lee y pasa tal
  /// cual a su reporte.
  final String? motivoAsignacion;

  const HexVistaMarcacionEntity({
    this.vistaHabilitada = false,
    this.textoVista = '',
    this.fechaJornadaAsignada,
    this.idAsignacion,
    this.nombreAsignador,
    this.puedeMarcarEntrada = false,
    this.textoMarcarEntrada = '',
    this.tipoEntrada,
    this.puedeMarcarSalida = false,
    this.textoMarcarSalida = '',
    this.fechaJornadaSalida,
    this.tipoSalida,
    this.horaLimiteSalida,
    this.motivoAsignacion,
  });
}
