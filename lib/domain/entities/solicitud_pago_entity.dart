import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';

class SolicitudPagoEntity {
  BigInt idSolicitud;
  int codEmpresa;
  String nombre;
  DateTime fechaSolicitud;
  double montoTotalSolicitud;
  String estado;
  String project; // Código del proyecto SAP asociado a esta solicitud
  int audUsuario;

  //  La lista de proveedores que le pertenecen
  List<SolicitudProveedorEntity> proveedores;

  SolicitudPagoEntity({
    required this.idSolicitud,
    required this.codEmpresa,
    this.nombre = '',
    required this.fechaSolicitud,
    required this.montoTotalSolicitud,
    required this.estado,
    this.project = '',
    required this.audUsuario,
    this.proveedores = const [],
  });
}