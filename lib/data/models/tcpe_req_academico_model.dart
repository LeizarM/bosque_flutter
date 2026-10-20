import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_req_academico_entity.dart';

/// `tcpe_reqAcademico`: Requisito académico de una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_ReqAcademico` (sin `password2`) más `nombreUsuario`.
class TcpeReqAcademicoModel {
  final BigInt codReqAcademico;
  final BigInt? codConvocatoria;
  final BigInt? codFormacion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeReqAcademicoModel({
    required this.codReqAcademico,
    this.codConvocatoria,
    this.codFormacion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeReqAcademicoModel.fromJson(Map<String, dynamic> json) => TcpeReqAcademicoModel(
    codReqAcademico: tcpeBigInt(json['codReqAcademico']) ?? BigInt.zero,
    codConvocatoria: tcpeBigInt(json['codConvocatoria']),
    codFormacion: tcpeBigInt(json['codFormacion']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codReqAcademico': codReqAcademico.toInt(),
    'codConvocatoria': codConvocatoria?.toInt(),
    'codFormacion': codFormacion?.toInt(),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeReqAcademicoEntity toEntity() => TcpeReqAcademicoEntity(
    codReqAcademico: codReqAcademico,
    codConvocatoria: codConvocatoria,
    codFormacion: codFormacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeReqAcademicoModel.fromEntity(TcpeReqAcademicoEntity e) => TcpeReqAcademicoModel(
    codReqAcademico: e.codReqAcademico,
    codConvocatoria: e.codConvocatoria,
    codFormacion: e.codFormacion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
