import 'package:bosque_flutter/domain/entities/agenda_empleado_entity.dart';

/// Una fila de `p_list_RelEmplEmpr 'G'`. Los teléfonos llegan en un solo texto
/// separado por comas y la entidad los recibe como lista.
class AgendaEmpleadoModel {
  final BigInt codEmpleado;
  final String nombreCompleto;
  final String iniciales;
  final String cargo;
  final int codSucursal;
  final String sucursal;
  final String empresa;
  final String telefonos;
  final bool puedeVerFicha;

  const AgendaEmpleadoModel({
    required this.codEmpleado,
    required this.nombreCompleto,
    this.iniciales = '',
    this.cargo = '',
    this.codSucursal = 0,
    this.sucursal = '',
    this.empresa = '',
    this.telefonos = '',
    this.puedeVerFicha = false,
  });

  static String _texto(Object? v) => (v as String?)?.trim() ?? '';

  factory AgendaEmpleadoModel.fromJson(Map<String, dynamic> json) =>
      AgendaEmpleadoModel(
        codEmpleado: BigInt.from((json['codEmpleado'] as num?) ?? 0),
        nombreCompleto: _texto(json['nombreCompleto']),
        iniciales: _texto(json['iniciales']),
        cargo: _texto(json['cargo']),
        codSucursal: (json['codSucursal'] as num?)?.toInt() ?? 0,
        sucursal: _texto(json['sucursal']),
        empresa: _texto(json['empresa']),
        telefonos: _texto(json['telefonos']),
        // Sin el dato (backend viejo), no se ofrece la ficha: más vale de menos.
        puedeVerFicha: json['puedeVerFicha'] == true,
      );

  Map<String, dynamic> toJson() => {
    'codEmpleado': codEmpleado.toInt(),
    'nombreCompleto': nombreCompleto,
    'iniciales': iniciales,
    'cargo': cargo,
    'codSucursal': codSucursal,
    'sucursal': sucursal,
    'empresa': empresa,
    'telefonos': telefonos,
    'puedeVerFicha': puedeVerFicha,
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
    puedeVerFicha: puedeVerFicha,
    iniciales: iniciales,
  );

  factory AgendaEmpleadoModel.fromEntity(AgendaEmpleadoEntity e) =>
      AgendaEmpleadoModel(
        codEmpleado: e.codEmpleado,
        nombreCompleto: e.nombreCompleto,
        iniciales: e.iniciales,
        cargo: e.cargo,
        codSucursal: e.codSucursal,
        sucursal: e.sucursal,
        empresa: e.empresa,
        telefonos: e.telefonos.join(', '),
        puedeVerFicha: e.puedeVerFicha,
      );
}
