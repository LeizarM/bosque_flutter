import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_postulacion_entity.dart';

/// `tcpe_postulacion`: Postulación a una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_Postulacion` (sin `password2`) más `nombreUsuario`.
/// `codPostulacion` no es IDENTITY: en 0 el SP toma el siguiente número.
class TcpePostulacionModel {
  final BigInt codPostulacion;
  final BigInt? codPersonaPost;
  final BigInt? codConvocatoria;
  final DateTime? fechaPost;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpePostulacionModel({
    required this.codPostulacion,
    this.codPersonaPost,
    this.codConvocatoria,
    this.fechaPost,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpePostulacionModel.fromJson(Map<String, dynamic> json) => TcpePostulacionModel(
    codPostulacion: tcpeBigInt(json['codPostulacion']) ?? BigInt.zero,
    codPersonaPost: tcpeBigInt(json['codPersonaPost']),
    codConvocatoria: tcpeBigInt(json['codConvocatoria']),
    fechaPost: tcpeFecha(json['fechaPost']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codPostulacion': codPostulacion.toInt(),
    'codPersonaPost': codPersonaPost?.toInt(),
    'codConvocatoria': codConvocatoria?.toInt(),
    'fechaPost': tcpeFechaJson(fechaPost),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpePostulacionEntity toEntity() => TcpePostulacionEntity(
    codPostulacion: codPostulacion,
    codPersonaPost: codPersonaPost,
    codConvocatoria: codConvocatoria,
    fechaPost: fechaPost,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpePostulacionModel.fromEntity(TcpePostulacionEntity e) => TcpePostulacionModel(
    codPostulacion: e.codPostulacion,
    codPersonaPost: e.codPersonaPost,
    codConvocatoria: e.codConvocatoria,
    fechaPost: e.fechaPost,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
