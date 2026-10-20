import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_exp_lab_post_entity.dart';

/// `tcpe_reqExpLabPost`: Experiencia declarada por un postulante (sin uso).
/// Columnas de `p_list_tcpe_ReqExpLabPost` (sin `password2`) más `nombreUsuario`.
class TcpeReqExpLabPostModel {
  final BigInt codExpLabPost;
  final BigInt? codPersonaPost;
  final String? nombreEmpresa;
  final String? cargo;
  final String? descripcion;
  final DateTime? fechaFin;
  final DateTime? fechaInicio;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeReqExpLabPostModel({
    required this.codExpLabPost,
    this.codPersonaPost,
    this.nombreEmpresa,
    this.cargo,
    this.descripcion,
    this.fechaFin,
    this.fechaInicio,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeReqExpLabPostModel.fromJson(Map<String, dynamic> json) => TcpeReqExpLabPostModel(
    codExpLabPost: tcpeBigInt(json['codExpLabPost']) ?? BigInt.zero,
    codPersonaPost: tcpeBigInt(json['codPersonaPost']),
    nombreEmpresa: tcpeTexto(json['nombreEmpresa']),
    cargo: tcpeTexto(json['cargo']),
    descripcion: tcpeTexto(json['descripcion']),
    fechaFin: tcpeFecha(json['fechaFin']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codExpLabPost': codExpLabPost.toInt(),
    'codPersonaPost': codPersonaPost?.toInt(),
    'nombreEmpresa': nombreEmpresa,
    'cargo': cargo,
    'descripcion': descripcion,
    'fechaFin': tcpeFechaJson(fechaFin),
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeReqExpLabPostEntity toEntity() => TcpeReqExpLabPostEntity(
    codExpLabPost: codExpLabPost,
    codPersonaPost: codPersonaPost,
    nombreEmpresa: nombreEmpresa,
    cargo: cargo,
    descripcion: descripcion,
    fechaFin: fechaFin,
    fechaInicio: fechaInicio,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeReqExpLabPostModel.fromEntity(TcpeReqExpLabPostEntity e) => TcpeReqExpLabPostModel(
    codExpLabPost: e.codExpLabPost,
    codPersonaPost: e.codPersonaPost,
    nombreEmpresa: e.nombreEmpresa,
    cargo: e.cargo,
    descripcion: e.descripcion,
    fechaFin: e.fechaFin,
    fechaInicio: e.fechaInicio,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
