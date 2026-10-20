import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_academico_post_entity.dart';

/// `tcpe_reqAcademicoPost`: Formación declarada por un postulante (sin uso).
/// Columnas de `p_list_tcpe_ReqAcademicoPost` (sin `password2`) más `nombreUsuario`.
class TcpeReqAcademicoPostModel {
  final BigInt codReqAcaPost;
  final BigInt? codPersonaPost;
  final BigInt? codFormacion;
  final int? gestion;
  final String? nomInstitucion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeReqAcademicoPostModel({
    required this.codReqAcaPost,
    this.codPersonaPost,
    this.codFormacion,
    this.gestion,
    this.nomInstitucion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeReqAcademicoPostModel.fromJson(Map<String, dynamic> json) => TcpeReqAcademicoPostModel(
    codReqAcaPost: tcpeBigInt(json['codReqAcaPost']) ?? BigInt.zero,
    codPersonaPost: tcpeBigInt(json['codPersonaPost']),
    codFormacion: tcpeBigInt(json['codFormacion']),
    gestion: tcpeInt(json['gestion']),
    nomInstitucion: tcpeTexto(json['nomInstitucion']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codReqAcaPost': codReqAcaPost.toInt(),
    'codPersonaPost': codPersonaPost?.toInt(),
    'codFormacion': codFormacion?.toInt(),
    'gestion': gestion,
    'nomInstitucion': nomInstitucion,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeReqAcademicoPostEntity toEntity() => TcpeReqAcademicoPostEntity(
    codReqAcaPost: codReqAcaPost,
    codPersonaPost: codPersonaPost,
    codFormacion: codFormacion,
    gestion: gestion,
    nomInstitucion: nomInstitucion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeReqAcademicoPostModel.fromEntity(TcpeReqAcademicoPostEntity e) => TcpeReqAcademicoPostModel(
    codReqAcaPost: e.codReqAcaPost,
    codPersonaPost: e.codPersonaPost,
    codFormacion: e.codFormacion,
    gestion: e.gestion,
    nomInstitucion: e.nomInstitucion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
