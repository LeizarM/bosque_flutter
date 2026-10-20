import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_conocimientos_entity.dart';

/// `tcpe_conocimientos`: Conocimiento pedido por una convocatoria (sin uso).
/// Columnas de `p_list_tcpe_Conocimientos` (sin `password2`) más `nombreUsuario`.
class TcpeConocimientosModel {
  final BigInt codConocimiento;
  final BigInt? codConvocatoria;
  final String? grado;
  final String? conocimiento;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeConocimientosModel({
    required this.codConocimiento,
    this.codConvocatoria,
    this.grado,
    this.conocimiento,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeConocimientosModel.fromJson(Map<String, dynamic> json) => TcpeConocimientosModel(
    codConocimiento: tcpeBigInt(json['codConocimiento']) ?? BigInt.zero,
    codConvocatoria: tcpeBigInt(json['codConvocatoria']),
    grado: tcpeTexto(json['grado']),
    conocimiento: tcpeTexto(json['conocimiento']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codConocimiento': codConocimiento.toInt(),
    'codConvocatoria': codConvocatoria?.toInt(),
    'grado': grado,
    'conocimiento': conocimiento,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeConocimientosEntity toEntity() => TcpeConocimientosEntity(
    codConocimiento: codConocimiento,
    codConvocatoria: codConvocatoria,
    grado: grado,
    conocimiento: conocimiento,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeConocimientosModel.fromEntity(TcpeConocimientosEntity e) => TcpeConocimientosModel(
    codConocimiento: e.codConocimiento,
    codConvocatoria: e.codConvocatoria,
    grado: e.grado,
    conocimiento: e.conocimiento,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
