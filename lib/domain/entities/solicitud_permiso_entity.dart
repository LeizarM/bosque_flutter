class SolicitudPermisoEntity {
  final int? codSolicitud;
  final int codEmpleado;
  final int codRelEmplEmpr;
  final String tipoPermiso;
  final DateTime desde;
  final DateTime hasta;
  final String motivo;
  final double cantidadDias;
  final int estado;
  final int audUsuarioI;
  // ── Auxiliares (vienen del listado de pendientes) ──
  final String? nombreEmpleado;
  final String? cargoEmpleado;
  final DateTime? fechaSolicitud;
  final String? pasoActual;
  final int? codPermiso;
  final String? autorizador;
  final double? diasDisponibles;
  final String? motivoRechazo;

  // ── Auxiliares para previsualizar saldo (acción 'C') ──────────
  final double? diasSolicitados;
  final double? saldoRestante;
  final double? saldoActualBase;

  SolicitudPermisoEntity({
    required this.codEmpleado,
    required this.codRelEmplEmpr,
    required this.tipoPermiso,
    required this.desde,
    required this.hasta,
    required this.motivo,
    required this.cantidadDias,
    required this.estado,
    required this.audUsuarioI,
    this.codSolicitud,
    this.nombreEmpleado,
    this.cargoEmpleado,
    this.fechaSolicitud,
    this.pasoActual,
    this.codPermiso,
    this.autorizador,
    this.diasDisponibles,
    this.motivoRechazo,
    this.diasSolicitados,
    this.saldoRestante,
    this.saldoActualBase,
  });
}
