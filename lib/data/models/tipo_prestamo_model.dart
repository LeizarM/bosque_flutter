import 'package:bosque_flutter/domain/entities/tipo_prestamo_entity.dart';

class TipoPrestamoModel {
  final String codTipos;
  final String nombre;
  final int codGrupo;

  TipoPrestamoModel({
    required this.codTipos,
    required this.nombre,
    required this.codGrupo,
  });

  factory TipoPrestamoModel.fromJson(Map<String, dynamic> json) {
    return TipoPrestamoModel(
      codTipos: json['codTipos']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      codGrupo: json['codGrupo'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codTipos': codTipos,
      'nombre': nombre,
      'codGrupo': codGrupo,
    };
  }

  TipoPrestamoEntity toEntity() => TipoPrestamoEntity(
        codTipos: codTipos,
        nombre: nombre,
        codGrupo: codGrupo,
      );

  factory TipoPrestamoModel.fromEntity(TipoPrestamoEntity entity) => TipoPrestamoModel(
        codTipos: entity.codTipos,
        nombre: entity.nombre,
        codGrupo: entity.codGrupo,
      );
}
