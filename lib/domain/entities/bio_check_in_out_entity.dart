// Modulo Biometrico (tablas `tbio_` del backend).

/// Origen: tabla `dbo.tbio_bioCHECKINOUT`, via `p_list_BioCHECKINOUT`.
///
/// Marcacion cruda del reloj biometrico. Sin columnas de auditoria: no la
/// escribe la app, la puebla el software del dispositivo.
class BioCheckInOutEntity {
  final int userId;
  final DateTime? checkTime;
  final String checkType;
  final int? verifyCode;
  final String sensorId;
  final String memoInfo;
  final String workCode;
  final String sn;
  final int? userExtFmt;
  final String fechaString;

  const BioCheckInOutEntity({
    required this.userId,
    this.checkTime,
    required this.checkType,
    this.verifyCode,
    required this.sensorId,
    required this.memoInfo,
    required this.workCode,
    required this.sn,
    this.userExtFmt,
    required this.fechaString,
  });
}
