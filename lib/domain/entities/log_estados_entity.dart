class LogEstadosEntity {
  BigInt idLog;
  BigInt idSolicitud;
  BigInt idCotizacion;
  BigInt idTransaccion;
  String tipoEntidad;
  String idEntidad;
  String estadoAnterior;
  String estadoNuevo;
  String observaciones;
  DateTime fechaCreacion;
  int audUsuario;

  LogEstadosEntity({
    required this.idLog,
    required this.idSolicitud,
    required this.idCotizacion,
    required this.idTransaccion,
    this.tipoEntidad = '',
    this.idEntidad = '',
    required this.estadoAnterior,
    required this.estadoNuevo,
    required this.observaciones,
    required this.fechaCreacion,
    required this.audUsuario,
  });
}
