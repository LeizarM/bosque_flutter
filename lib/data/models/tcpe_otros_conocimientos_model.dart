import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_otros_conocimientos_entity.dart';

/// `tcpe_otrosConocimientos`: Conocimiento declarado por un postulante (sin uso).
/// Columnas de `p_list_tcpe_OtrosConocimientos` (sin `password2`) más `nombreUsuario`.
class TcpeOtrosConocimientosModel {
  final BigInt codOtrosCono;
  final BigInt? codPersonaPost;
  final BigInt? codConocimiento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeOtrosConocimientosModel({
    required this.codOtrosCono,
    this.codPersonaPost,
    this.codConocimiento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeOtrosConocimientosModel.fromJson(Map<String, dynamic> json) => TcpeOtrosConocimientosModel(
    codOtrosCono: tcpeBigInt(json['codOtrosCono']) ?? BigInt.zero,
    codPersonaPost: tcpeBigInt(json['codPersonaPost']),
    codConocimiento: tcpeBigInt(json['codConocimiento']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codOtrosCono': codOtrosCono.toInt(),
    'codPersonaPost': codPersonaPost?.toInt(),
    'codConocimiento': codConocimiento?.toInt(),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeOtrosConocimientosEntity toEntity() => TcpeOtrosConocimientosEntity(
    codOtrosCono: codOtrosCono,
    codPersonaPost: codPersonaPost,
    codConocimiento: codConocimiento,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeOtrosConocimientosModel.fromEntity(TcpeOtrosConocimientosEntity e) => TcpeOtrosConocimientosModel(
    codOtrosCono: e.codOtrosCono,
    codPersonaPost: e.codPersonaPost,
    codConocimiento: e.codConocimiento,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
