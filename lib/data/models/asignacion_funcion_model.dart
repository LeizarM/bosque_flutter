import 'package:bosque_flutter/domain/entities/asignacion_funcion_entity.dart';

/// `tb_asigFunModXEmpl` tal como viaja: `estado` es '1'/'0'.
class AsignacionFuncionModel {
  final BigInt codAsignacion;
  final int codFuncMod;
  final String funcion;
  final int codModulo;
  final String modulo;
  final int codEmpleado;
  final String empleado;
  final int codSucursal;
  final String sucursal;
  final String empresa;
  final String estado;

  const AsignacionFuncionModel({
    required this.codAsignacion,
    required this.codFuncMod,
    required this.codEmpleado,
    required this.codSucursal,
    this.funcion = '',
    this.codModulo = 0,
    this.modulo = '',
    this.empleado = '',
    this.sucursal = '',
    this.empresa = '',
    this.estado = '1',
  });

  static int _entero(Object? v) => (v as num?)?.toInt() ?? 0;
  static String _texto(Object? v) => (v as String?)?.trim() ?? '';

  factory AsignacionFuncionModel.fromJson(Map<String, dynamic> json) =>
      AsignacionFuncionModel(
        codAsignacion: BigInt.from((json['codAsignacion'] as num?) ?? 0),
        codFuncMod: _entero(json['codFuncMod']),
        funcion: _texto(json['funcion']),
        codModulo: _entero(json['codModulo']),
        modulo: _texto(json['modulo']),
        codEmpleado: _entero(json['codEmpleado']),
        empleado: _texto(json['empleado']),
        codSucursal: _entero(json['codSucursal']),
        sucursal: _texto(json['sucursal']),
        empresa: _texto(json['empresa']),
        estado: _texto(json['estado']).isEmpty ? '1' : _texto(json['estado']),
      );

  Map<String, dynamic> toJson() => {
    'codAsignacion': codAsignacion.toInt(),
    'codFuncMod': codFuncMod,
    'codEmpleado': codEmpleado,
    'codSucursal': codSucursal,
    'estado': estado,
  };

  AsignacionFuncionEntity toEntity() => AsignacionFuncionEntity(
    codAsignacion: codAsignacion,
    codFuncMod: codFuncMod,
    funcion: funcion,
    codModulo: codModulo,
    modulo: modulo,
    codEmpleado: codEmpleado,
    empleado: empleado,
    codSucursal: codSucursal,
    sucursal: sucursal,
    empresa: empresa,
    activo: estado == '1',
  );

  factory AsignacionFuncionModel.fromEntity(AsignacionFuncionEntity e) =>
      AsignacionFuncionModel(
        codAsignacion: e.codAsignacion,
        codFuncMod: e.codFuncMod,
        funcion: e.funcion,
        codModulo: e.codModulo,
        modulo: e.modulo,
        codEmpleado: e.codEmpleado,
        empleado: e.empleado,
        codSucursal: e.codSucursal,
        sucursal: e.sucursal,
        empresa: e.empresa,
        estado: e.activo ? '1' : '0',
      );
}
