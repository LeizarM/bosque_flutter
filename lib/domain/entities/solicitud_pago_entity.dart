import 'package:bosque_flutter/domain/entities/solicitud_proveedor_entity.dart';

class SolicitudPagoEntity {
  BigInt idSolicitud;
  int codEmpresa;
  String nombre;
  DateTime fechaSolicitud;
  double montoTotalSolicitud;
  String estado;
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
    required this.audUsuario,
    this.proveedores = const [],
  });
}
