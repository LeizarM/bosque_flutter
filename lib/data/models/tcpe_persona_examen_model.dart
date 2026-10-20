import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_persona_examen_entity.dart';

/// `{ci, nombres, apellidoPaterno, apellidoMaterno}` del modo `personas`.
class TcpePersonaExamenModel {
  final String ci;
  final String nombres;
  final String apellidoPaterno;
  final String? apellidoMaterno;

  const TcpePersonaExamenModel({
    required this.ci,
    required this.nombres,
    required this.apellidoPaterno,
    this.apellidoMaterno,
  });

  factory TcpePersonaExamenModel.fromJson(Map<String, dynamic> json) =>
      TcpePersonaExamenModel(
        ci: tcpeTexto(json['ci']) ?? '',
        nombres: tcpeTexto(json['nombres']) ?? '',
        apellidoPaterno: tcpeTexto(json['apellidoPaterno']) ?? '',
        apellidoMaterno: tcpeTexto(json['apellidoMaterno']),
      );

  /// Recorta los textos; el apellido materno vacío viaja como null.
  Map<String, dynamic> toJson() {
    final materno = apellidoMaterno?.trim() ?? '';
    return {
      'ci': ci.trim(),
      'nombres': nombres.trim(),
      'apellidoPaterno': apellidoPaterno.trim(),
      'apellidoMaterno': materno.isEmpty ? null : materno,
    };
  }

  TcpePersonaExamenEntity toEntity() => TcpePersonaExamenEntity(
    ci: ci,
    nombres: nombres,
    apellidoPaterno: apellidoPaterno,
    apellidoMaterno: apellidoMaterno,
  );

  factory TcpePersonaExamenModel.fromEntity(TcpePersonaExamenEntity e) =>
      TcpePersonaExamenModel(
        ci: e.ci,
        nombres: e.nombres,
        apellidoPaterno: e.apellidoPaterno,
        apellidoMaterno: e.apellidoMaterno,
      );
}
