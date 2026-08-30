/// Un evento en la vida de un talonario. Tabla tmto_talonarioDetalle.
///
/// NO es un detalle hijo: es un LOG DE EVENTOS append-only. Cada fila es una
/// transición de estado, y el estado del talonario se deriva contándolas.
/// Por eso no se editan [codEstado] ni las fechas: para corregir se borra el
/// último evento y se vuelve a cargar.
///
/// [codEstado]:
///   1 Adquirido -> lo genera el alta del talonario, nunca se envía
///   2 Entregado -> lleva destinatario, sucursal O empleado, exactamente uno
///   3 Devuelto  -> sin destinatario
///   4 Cerrado   -> sin destinatario, terminal
class TalonarioDetalleEntity {
  BigInt codDetalle;
  BigInt codTalonario;
  int codEstado;

  /// Cuándo se cargó. La fija el backend, no se envía.
  DateTime? fechaDetalle;

  /// Cuándo ocurrió el hecho. La informa el usuario, es obligatoria.
  DateTime? fechaEvento;

  BigInt codSucursal;
  BigInt codEmpleado;
  String observacion;
  BigInt audUsuario;
  DateTime? audFecha;

  // ---- solo lectura ----
  String datoEstado;
  String datoSucursal;
  String datoEmpleado;
  String nroTalonario;
  String sigla;
  String datoTalonario;
  String datoFechaDetalle;
  String datoFechaEvento;

  /// 'SUCURSAL', 'EMPLEADO' o vacío si el evento no lleva destinatario.
  String tipoDestinatario;
  BigInt codDestinatario;
  String datoDestinatario;

  TalonarioDetalleEntity({
    required this.codDetalle,
    required this.codTalonario,
    required this.codEstado,
    this.fechaDetalle,
    this.fechaEvento,
    required this.codSucursal,
    required this.codEmpleado,
    required this.observacion,
    required this.audUsuario,
    this.audFecha,
    this.datoEstado = '',
    this.datoSucursal = '',
    this.datoEmpleado = '',
    this.nroTalonario = '',
    this.sigla = '',
    this.datoTalonario = '',
    this.datoFechaDetalle = '',
    this.datoFechaEvento = '',
    this.tipoDestinatario = '',
    BigInt? codDestinatario,
    this.datoDestinatario = '',
  }) : codDestinatario = codDestinatario ?? BigInt.zero;

  bool get esEntrega => codEstado == 2;
  bool get vaAEmpleado => tipoDestinatario == 'EMPLEADO';
  bool get vaASucursal => tipoDestinatario == 'SUCURSAL';
}
