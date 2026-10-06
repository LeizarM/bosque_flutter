import 'package:bosque_flutter/domain/entities/talonario_validacion_entity.dart';

/// Respuesta de `/cheque/talonario/validar`: `{ valido, mensaje, detalle }`.
/// DTO de apoyo del backend, no una tabla.
///
/// Lectura tolerante: solo un `false` explicito (booleano o texto) es un
/// rechazo; si `valido` falta o viene raro se toma por valido, porque el aviso es
/// previo y el servidor vuelve a validar al guardar. Un texto vacio es ausencia.
class TalonarioValidacionModel {
  final bool valido;
  final String? mensaje;
  final String? detalle;

  const TalonarioValidacionModel({
    required this.valido,
    this.mensaje,
    this.detalle,
  });

  factory TalonarioValidacionModel.fromJson(Map<String, dynamic> json) =>
      TalonarioValidacionModel(
        valido: _leerValido(json['valido']),
        mensaje: _texto(json['mensaje']),
        detalle: _texto(json['detalle']),
      );

  static bool _leerValido(Object? v) {
    if (v is bool) return v;
    if (v is String) return v.trim().toLowerCase() != 'false';
    return true;
  }

  static String? _texto(Object? v) {
    final t = v?.toString().trim() ?? '';
    return t.isEmpty ? null : t;
  }

  Map<String, dynamic> toJson() => {
    'valido': valido,
    'mensaje': mensaje,
    'detalle': detalle,
  };

  TalonarioValidacionEntity toEntity() => TalonarioValidacionEntity(
    valido: valido,
    mensaje: mensaje,
    detalle: detalle,
  );

  factory TalonarioValidacionModel.fromEntity(TalonarioValidacionEntity e) =>
      TalonarioValidacionModel(
        valido: e.valido,
        mensaje: e.mensaje,
        detalle: e.detalle,
      );
}
