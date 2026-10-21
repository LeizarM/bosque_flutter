import 'package:bosque_flutter/domain/entities/opcion_entity.dart';

/// `OpcionDto` del backend: `{codigo, nombre, grupo}`.
class OpcionModel {
  final int codigo;
  final String nombre;
  final String grupo;

  const OpcionModel({
    required this.codigo,
    required this.nombre,
    this.grupo = '',
  });

  factory OpcionModel.fromJson(Map<String, dynamic> json) => OpcionModel(
    codigo: (json['codigo'] as num?)?.toInt() ?? 0,
    nombre: (json['nombre'] as String?)?.trim() ?? '',
    grupo: (json['grupo'] as String?)?.trim() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    'nombre': nombre,
    'grupo': grupo,
  };

  OpcionEntity toEntity() =>
      OpcionEntity(codigo: codigo, nombre: nombre, grupo: grupo);

  factory OpcionModel.fromEntity(OpcionEntity e) =>
      OpcionModel(codigo: e.codigo, nombre: e.nombre, grupo: e.grupo);
}
