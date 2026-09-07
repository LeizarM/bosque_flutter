// Destino final: lib/domain/entities/arqueo_caja_sucursales_entity.dart
class ArqueoCajaSucursalesEntity {
  final int idAC;
  final int? idTarRuti;
  final int? codEmpleadoEncargado;
  final DateTime? fecha;
  final String? hora;
  final double? saldoMovSap;
  final String? obs;
  final int? codEmpleadoSupCierre;
  final double? total;
  final double? diferencia;
  final double? tc;
  final int? idBitTarea;
  final DateTime? fechaRevisado;
  final int audUsuario;
  final DateTime? audFecha;

  ArqueoCajaSucursalesEntity({
    required this.idAC,
    this.idTarRuti,
    this.codEmpleadoEncargado,
    this.fecha,
    this.hora,
    this.saldoMovSap,
    this.obs,
    this.codEmpleadoSupCierre,
    this.total,
    this.diferencia,
    this.tc,
    this.idBitTarea,
    this.fechaRevisado,
    required this.audUsuario,
    this.audFecha,
  });

  ArqueoCajaSucursalesEntity copyWith({
    int? idAC,
    int? idTarRuti,
    int? codEmpleadoEncargado,
    DateTime? fecha,
    String? hora,
    double? saldoMovSap,
    String? obs,
    int? codEmpleadoSupCierre,
    double? total,
    double? diferencia,
    double? tc,
    int? idBitTarea,
    DateTime? fechaRevisado,
    int? audUsuario,
    DateTime? audFecha,
  }) {
    return ArqueoCajaSucursalesEntity(
      idAC: idAC ?? this.idAC,
      idTarRuti: idTarRuti ?? this.idTarRuti,
      codEmpleadoEncargado: codEmpleadoEncargado ?? this.codEmpleadoEncargado,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      saldoMovSap: saldoMovSap ?? this.saldoMovSap,
      obs: obs ?? this.obs,
      codEmpleadoSupCierre: codEmpleadoSupCierre ?? this.codEmpleadoSupCierre,
      total: total ?? this.total,
      diferencia: diferencia ?? this.diferencia,
      tc: tc ?? this.tc,
      idBitTarea: idBitTarea ?? this.idBitTarea,
      fechaRevisado: fechaRevisado ?? this.fechaRevisado,
      audUsuario: audUsuario ?? this.audUsuario,
      audFecha: audFecha ?? this.audFecha,
    );
  }
}
