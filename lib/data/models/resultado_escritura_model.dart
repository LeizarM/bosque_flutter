import 'package:bosque_flutter/domain/entities/resultado_escritura_entity.dart';

/// El sobre `{ message, data, status }` de una escritura: `data` es el id y
/// `message` el texto que dejó el procedimiento en `@errormsg`.
class ResultadoEscrituraModel {
  final BigInt id;
  final String mensaje;

  const ResultadoEscrituraModel({required this.id, required this.mensaje});

  factory ResultadoEscrituraModel.fromJson(Map<String, dynamic> json) {
    final dato = json['data'];
    return ResultadoEscrituraModel(
      id: dato is num ? BigInt.from(dato) : BigInt.zero,
      mensaje: (json['message'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'data': id.toInt(), 'message': mensaje};

  ResultadoEscrituraEntity toEntity() =>
      ResultadoEscrituraEntity(id: id, mensaje: mensaje);

  factory ResultadoEscrituraModel.fromEntity(ResultadoEscrituraEntity e) =>
      ResultadoEscrituraModel(id: e.id, mensaje: e.mensaje);
}
