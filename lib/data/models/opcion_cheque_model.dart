import 'package:bosque_flutter/domain/entities/opcion_cheque_entity.dart';

/// OpcionChequeDto del backend: `{ codigo, nombre }`.
class OpcionChequeModel {
  final String codigo;
  final String nombre;

  const OpcionChequeModel({required this.codigo, required this.nombre});

  factory OpcionChequeModel.fromJson(Map<String, dynamic> json) =>
      OpcionChequeModel(
        codigo: (json['codigo'] ?? '').toString(),
        nombre: (json['nombre'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'codigo': codigo, 'nombre': nombre};

  OpcionChequeEntity toEntity() =>
      OpcionChequeEntity(codigo: codigo, nombre: nombre);

  factory OpcionChequeModel.fromEntity(OpcionChequeEntity e) =>
      OpcionChequeModel(codigo: e.codigo, nombre: e.nombre);
}
