import 'package:bosque_flutter/domain/entities/recuperacion_enviada_entity.dart';

/// `data` de `POST /auth/recuperacion/solicitar` (RecuperacionEnviadaDto en el backend).
class RecuperacionEnviadaModel {
  final String correo;
  final int minutosVigencia;
  final int segundosParaReenviar;

  const RecuperacionEnviadaModel({
    required this.correo,
    required this.minutosVigencia,
    required this.segundosParaReenviar,
  });

  factory RecuperacionEnviadaModel.fromJson(Map<String, dynamic> json) {
    return RecuperacionEnviadaModel(
      correo: json['correo'] as String? ?? '',
      minutosVigencia: (json['minutosVigencia'] as num?)?.toInt() ?? 0,
      segundosParaReenviar: (json['segundosParaReenviar'] as num?)?.toInt() ?? 60,
    );
  }

  RecuperacionEnviadaEntity toEntity() => RecuperacionEnviadaEntity(
    correo: correo,
    minutosVigencia: minutosVigencia,
    segundosParaReenviar: segundosParaReenviar,
  );
}
