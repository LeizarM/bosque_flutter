import 'package:bosque_flutter/domain/entities/empresa_cheque_entity.dart';

/// EmpresaChequeDto del backend: `{ codEmpresa, nombre }`.
class EmpresaChequeModel {
  final int codEmpresa;
  final String nombre;

  const EmpresaChequeModel({required this.codEmpresa, required this.nombre});

  factory EmpresaChequeModel.fromJson(Map<String, dynamic> json) =>
      EmpresaChequeModel(
        codEmpresa: (json['codEmpresa'] as num?)?.toInt() ?? 0,
        nombre: (json['nombre'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'codEmpresa': codEmpresa, 'nombre': nombre};

  EmpresaChequeEntity toEntity() =>
      EmpresaChequeEntity(codEmpresa: codEmpresa, nombre: nombre);

  factory EmpresaChequeModel.fromEntity(EmpresaChequeEntity e) =>
      EmpresaChequeModel(codEmpresa: e.codEmpresa, nombre: e.nombre);
}
