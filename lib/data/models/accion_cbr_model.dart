import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/accion_cbr_entity.dart';

/// Espeja 1:1 la tabla tcbr_accion y el POJO AccionCbr del backend.
class AccionCbrModel {
  final BigInt codAccion;
  final BigInt codGarantia;
  final DateTime? fecha;
  final String estado;
  final String? observacion;
  final int audUsuario;
  final DateTime? audFecha;

  const AccionCbrModel({
    required this.codAccion,
    required this.codGarantia,
    required this.fecha,
    required this.estado,
    required this.observacion,
    required this.audUsuario,
    required this.audFecha,
  });

  factory AccionCbrModel.fromJson(Map<String, dynamic> json) => AccionCbrModel(
    codAccion: BigInt.from((json['codAccion'] as num?) ?? 0),
    codGarantia: BigInt.from((json['codGarantia'] as num?) ?? 0),
    fecha: fechaHora(json['fecha']),
    estado: (json['estado'] ?? '').toString().trim(),
    observacion: json['observacion'] as String?,
    audUsuario: (json['audUsuario'] as num?)?.toInt() ?? 0,
    audFecha: fechaHora(json['audFecha']),
  );

  /// Lo que acepta `/garantias/accion/registrar`.
  Map<String, dynamic> toJson() => {
    'codAccion': codAccion.toInt(),
    'codGarantia': codGarantia.toInt(),
    'fecha': fecha == null ? null : fechaParaSql(fecha!),
    'estado': estado,
    'observacion': observacion,
  };

  AccionCbrEntity toEntity() => AccionCbrEntity(
    codAccion: codAccion,
    codGarantia: codGarantia,
    fecha: fecha,
    estado: estado,
    observacion: observacion,
    audUsuario: audUsuario,
    audFecha: audFecha,
  );

  factory AccionCbrModel.fromEntity(AccionCbrEntity e) => AccionCbrModel(
    codAccion: e.codAccion,
    codGarantia: e.codGarantia,
    fecha: e.fecha,
    estado: e.estado,
    observacion: e.observacion,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
  );
}
