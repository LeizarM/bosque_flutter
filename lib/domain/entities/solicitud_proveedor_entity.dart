import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';

class SolicitudProveedorEntity {
  BigInt idSolicitudProveedor;
  BigInt idSolicitud;
  String cardCode;
  String cardName;
  double totalFacturasUsd;
  double totalAmortizadoUsd;
  double totalAPagarUsd;
  String obs;
  int audUsuario;

  int codEmpresa;

  // --- Estado de aprobación por proveedor ---
  String estado; // PENDIENTE / APROBADO / RECHAZADO
  DateTime? fechaAprobacion;
  int? usuarioAprobador;
  String obsAprobacion;

  List<DetalleSolicitudEntity> detalles;

  SolicitudProveedorEntity({
    required this.idSolicitudProveedor,
    required this.idSolicitud,
    required this.cardCode,
    required this.cardName,
    required this.totalFacturasUsd,
    required this.totalAmortizadoUsd,
    required this.totalAPagarUsd,
    required this.obs,
    required this.audUsuario,
    required this.codEmpresa,
    this.estado = 'PENDIENTE',
    this.fechaAprobacion,
    this.usuarioAprobador,
    this.obsAprobacion = '',
    this.detalles = const [],
  });
}