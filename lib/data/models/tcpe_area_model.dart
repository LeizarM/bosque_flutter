import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_area_entity.dart';

/// `tcpe_area`: Área de evaluación: agrupa las categorías del banco de preguntas.
/// Columnas de `p_list_tcpe_Area` (sin `password2`) más `nombreUsuario`.
class TcpeAreaModel {
  final BigInt codArea;
  final String? nombreArea;
  final String? descripArea;
  final bool activo;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeAreaModel({
    required this.codArea,
    this.nombreArea,
    this.descripArea,
    this.activo = true,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeAreaModel.fromJson(Map<String, dynamic> json) => TcpeAreaModel(
    codArea: tcpeBigInt(json['codArea']) ?? BigInt.zero,
    nombreArea: tcpeTexto(json['nombreArea']),
    descripArea: tcpeTexto(json['descripArea']),
    activo: tcpeBool(json['activo']) ?? true,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codArea': codArea.toInt(),
    'nombreArea': nombreArea,
    'descripArea': descripArea,
    'activo': activo,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeAreaEntity toEntity() => TcpeAreaEntity(
    codArea: codArea,
    nombreArea: nombreArea,
    descripArea: descripArea,
    activo: activo,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeAreaModel.fromEntity(TcpeAreaEntity e) => TcpeAreaModel(
    codArea: e.codArea,
    nombreArea: e.nombreArea,
    descripArea: e.descripArea,
    activo: e.activo,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
