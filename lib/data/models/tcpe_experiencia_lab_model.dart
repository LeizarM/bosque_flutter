import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_experiencia_lab_entity.dart';

/// `tcpe_experienciaLab`: Experiencia laboral pedida por una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_ExperienciaLab` (sin `password2`) más `nombreUsuario`.
class TcpeExperienciaLabModel {
  final BigInt codExpLab;
  final BigInt? codConvocatoria;
  final int? cantidad;
  final String? medida;
  final String? ocupacion;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeExperienciaLabModel({
    required this.codExpLab,
    this.codConvocatoria,
    this.cantidad,
    this.medida,
    this.ocupacion,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeExperienciaLabModel.fromJson(Map<String, dynamic> json) => TcpeExperienciaLabModel(
    codExpLab: tcpeBigInt(json['codExpLab']) ?? BigInt.zero,
    codConvocatoria: tcpeBigInt(json['codConvocatoria']),
    cantidad: tcpeInt(json['cantidad']),
    medida: tcpeTexto(json['medida']),
    ocupacion: tcpeTexto(json['ocupacion']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codExpLab': codExpLab.toInt(),
    'codConvocatoria': codConvocatoria?.toInt(),
    'cantidad': cantidad,
    'medida': medida,
    'ocupacion': ocupacion,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeExperienciaLabEntity toEntity() => TcpeExperienciaLabEntity(
    codExpLab: codExpLab,
    codConvocatoria: codConvocatoria,
    cantidad: cantidad,
    medida: medida,
    ocupacion: ocupacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeExperienciaLabModel.fromEntity(TcpeExperienciaLabEntity e) => TcpeExperienciaLabModel(
    codExpLab: e.codExpLab,
    codConvocatoria: e.codConvocatoria,
    cantidad: e.cantidad,
    medida: e.medida,
    ocupacion: e.ocupacion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
