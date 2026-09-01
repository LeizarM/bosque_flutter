/// Origen: tabla `dbo.tbio_bioCHECKINOUTAdicinal`, via
/// `p_list_BioCHECKINOUTAdicinal`.
///
/// Marcacion olvidada / corregida manualmente por un administrador.
class BioCheckInOutAdicionalEntity {
  final int userId;
  final DateTime? checkTime;
  final int codEmpleado;
  final String fechaString;
  final int audUsuario;
  final DateTime? audFecha;

  const BioCheckInOutAdicionalEntity({
    required this.userId,
    this.checkTime,
    required this.codEmpleado,
    required this.fechaString,
    required this.audUsuario,
    this.audFecha,
  });
}
