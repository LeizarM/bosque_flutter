import 'package:bosque_flutter/domain/entities/personal_cheque_entity.dart';

/// PersonalChequeDto del backend: `{ codEmpleado, nombreCompleto }`.
class PersonalChequeModel {
  final int codEmpleado;
  final String nombreCompleto;

  const PersonalChequeModel({
    required this.codEmpleado,
    required this.nombreCompleto,
  });

  factory PersonalChequeModel.fromJson(Map<String, dynamic> json) =>
      PersonalChequeModel(
        codEmpleado: (json['codEmpleado'] as num?)?.toInt() ?? 0,
        nombreCompleto: (json['nombreCompleto'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
    'codEmpleado': codEmpleado,
    'nombreCompleto': nombreCompleto,
  };

  PersonalChequeEntity toEntity() => PersonalChequeEntity(
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
  );

  factory PersonalChequeModel.fromEntity(PersonalChequeEntity e) =>
      PersonalChequeModel(
        codEmpleado: e.codEmpleado,
        nombreCompleto: e.nombreCompleto,
      );
}
