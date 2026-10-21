import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';

/// Una fila de `p_list_RelEmplEmpr 'G'`. Los teléfonos llegan en un solo texto
/// separado por comas y la entidad los recibe como lista.
class AgendaEmpleadoModel {
  final BigInt codEmpleado;
  final String nombreCompleto;
  final String cargo;
  final int codSucursal;
  final String sucursal;
  final String empresa;
  final String telefonos;

  const AgendaEmpleadoModel({
    required this.codEmpleado,
    required this.nombreCompleto,
    this.cargo = '',
    this.codSucursal = 0,
    this.sucursal = '',
    this.empresa = '',
    this.telefonos = '',
  });

  static String _texto(Object? v) => (v as String?)?.trim() ?? '';

  factory AgendaEmpleadoModel.fromJson(Map<String, dynamic> json) =>
      AgendaEmpleadoModel(
        codEmpleado: BigInt.from((json['codEmpleado'] as num?) ?? 0),
        nombreCompleto: _texto(json['nombreCompleto']),
        cargo: _texto(json['cargo']),
        codSucursal: (json['codSucursal'] as num?)?.toInt() ?? 0,
        sucursal: _texto(json['sucursal']),
        empresa: _texto(json['empresa']),
        telefonos: _texto(json['telefonos']),
      );

  Map<String, dynamic> toJson() => {
    'codEmpleado': codEmpleado.toInt(),
    'nombreCompleto': nombreCompleto,
    'cargo': cargo,
    'codSucursal': codSucursal,
    'sucursal': sucursal,
    'empresa': empresa,
    'telefonos': telefonos,
  };

  AgendaEmpleadoEntity toEntity() => AgendaEmpleadoEntity(
    codEmpleado: codEmpleado,
    nombreCompleto: nombreCompleto,
    cargo: cargo,
    codSucursal: codSucursal,
    sucursal: sucursal,
    empresa: empresa,
    telefonos: [
      for (final t in telefonos.split(','))
        if (t.trim().isNotEmpty) t.trim(),
    ],
  );

  factory AgendaEmpleadoModel.fromEntity(AgendaEmpleadoEntity e) =>
      AgendaEmpleadoModel(
        codEmpleado: e.codEmpleado,
        nombreCompleto: e.nombreCompleto,
        cargo: e.cargo,
        codSucursal: e.codSucursal,
        sucursal: e.sucursal,
        empresa: e.empresa,
        telefonos: e.telefonos.join(', '),
      );
}
