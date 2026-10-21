import 'package:bosque_flutter/domain/entities/funcion_modulo_entity.dart';

/// `tb_funcionesXModulo` tal como viaja: `requerido` es 'SI'/'NO' y `estado`
/// '1'/'0'; en la entidad son booleanos.
class FuncionModuloModel {
  final BigInt codFuncMod;
  final int codModulo;
  final String modulo;
  final String funcion;
  final String detalle;
  final String requerido;
  final String estado;
  final int asignaciones;

  const FuncionModuloModel({
    required this.codFuncMod,
    required this.codModulo,
    required this.funcion,
    this.modulo = '',
    this.detalle = '',
    this.requerido = 'NO',
    this.estado = '1',
    this.asignaciones = 0,
  });

  factory FuncionModuloModel.fromJson(Map<String, dynamic> json) =>
      FuncionModuloModel(
        codFuncMod: BigInt.from((json['codFuncMod'] as num?) ?? 0),
        codModulo: (json['codModulo'] as num?)?.toInt() ?? 0,
        modulo: (json['modulo'] as String?)?.trim() ?? '',
        funcion: (json['funcion'] as String?)?.trim() ?? '',
        detalle: (json['detalle'] as String?)?.trim() ?? '',
        requerido: (json['requerido'] as String?)?.trim().toUpperCase() ?? 'NO',
        estado: (json['estado'] as String?)?.trim() ?? '1',
        asignaciones: (json['asignaciones'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'codFuncMod': codFuncMod.toInt(),
    'codModulo': codModulo,
    'funcion': funcion,
    'detalle': detalle,
    'requerido': requerido,
    'estado': estado,
  };

  FuncionModuloEntity toEntity() => FuncionModuloEntity(
    codFuncMod: codFuncMod,
    codModulo: codModulo,
    modulo: modulo,
    funcion: funcion,
    detalle: detalle,
    requerido: requerido == 'SI',
    activo: estado == '1',
    asignaciones: asignaciones,
  );

  factory FuncionModuloModel.fromEntity(FuncionModuloEntity e) =>
      FuncionModuloModel(
        codFuncMod: e.codFuncMod,
        codModulo: e.codModulo,
        modulo: e.modulo,
        funcion: e.funcion,
        detalle: e.detalle,
        requerido: e.requerido ? 'SI' : 'NO',
        estado: e.activo ? '1' : '0',
        asignaciones: e.asignaciones,
      );
}
