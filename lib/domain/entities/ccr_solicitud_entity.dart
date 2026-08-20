/// Cabecera de una solicitud de servicio de corte (`tccr_ccrSolicitud`).
class CcrSolicitudEntity {
  final int idSolicitud;
  final int codEmpresa;
  final int numeracion;

  /// 'ESP' especial, 'STD' estandar (historico, ya no se genera).
  final String tipoSolicitud;

  final DateTime? fechaSistema;
  final DateTime fechaSolicitud;
  final int idSolicitante;
  final String datoSolicitante;

  /// 'SOL' solicitada, 'CNC' cancelada.
  final String estado;

  final String observacion;
  final double totalToneladas;
  final String sapObservacion;
  final double sapToneladas;
  final int audUsuario;

  /// Campos de solo lectura: los resuelve el SP.
  final String datoNroSolicitud;
  final String datoEmpresa;
  final String datoEstado;
  final String datoTipoSolicitud;
  final String fechaSolicitudString;

  const CcrSolicitudEntity({
    required this.idSolicitud,
    required this.codEmpresa,
    required this.numeracion,
    required this.tipoSolicitud,
    this.fechaSistema,
    required this.fechaSolicitud,
    required this.idSolicitante,
    required this.datoSolicitante,
    required this.estado,
    required this.observacion,
    required this.totalToneladas,
    this.sapObservacion = '',
    this.sapToneladas = 0,
    required this.audUsuario,
    this.datoNroSolicitud = '',
    this.datoEmpresa = '',
    this.datoEstado = '',
    this.datoTipoSolicitud = '',
    this.fechaSolicitudString = '',
  });

  bool get estaCancelada => estado == 'CNC';

  /// Los estados desde los que ya no se puede cancelar.
  bool get sePuedeCancelar => !const {'FIN', 'CNC', 'REC'}.contains(estado);
}
