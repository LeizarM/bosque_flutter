import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_formacion_entity.dart';

/// `tcpe_formacion`: Grado de formación académica (sin uso).
/// Columnas de `p_list_tcpe_Formacion` (sin `password2`) más `nombreUsuario`.
class TcpeFormacionModel {
  final BigInt codFormacion;
  final String? nombreGrado;
  final String? grado;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeFormacionModel({
    required this.codFormacion,
    this.nombreGrado,
    this.grado,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeFormacionModel.fromJson(Map<String, dynamic> json) => TcpeFormacionModel(
    codFormacion: tcpeBigInt(json['codFormacion']) ?? BigInt.zero,
    nombreGrado: tcpeTexto(json['nombreGrado']),
    grado: tcpeTexto(json['grado']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codFormacion': codFormacion.toInt(),
    'nombreGrado': nombreGrado,
    'grado': grado,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeFormacionEntity toEntity() => TcpeFormacionEntity(
    codFormacion: codFormacion,
    nombreGrado: nombreGrado,
    grado: grado,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeFormacionModel.fromEntity(TcpeFormacionEntity e) => TcpeFormacionModel(
    codFormacion: e.codFormacion,
    nombreGrado: e.nombreGrado,
    grado: e.grado,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
