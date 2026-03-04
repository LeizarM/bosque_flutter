class SolicitudPagoEntity {
  BigInt idSolicitud;
  int codEmpresa;
  DateTime fechaSolicitud;
  double montoTotalSolicitud;
  String estado;
  int audUsuario;

  SolicitudPagoEntity({
    required this.idSolicitud,
    required this.codEmpresa,
    required this.fechaSolicitud,
    required this.montoTotalSolicitud,
    required this.estado,
    required this.audUsuario,
  });
}
