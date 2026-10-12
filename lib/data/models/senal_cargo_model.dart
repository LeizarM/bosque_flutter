// Destino final: lib/data/models/senal_cargo_model.dart
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/senal_cargo_entity.dart';

/// Lectura de p_list_tac_SenalCargo 'L' (archivo SQL 82).
class SenalCargoModel {
  SenalCargoModel._();

  static int? _int(dynamic v) => (v as num?)?.toInt();

  /// Las descripciones de las tareas traen saltos de línea y espacios dobles.
  static String? _texto(dynamic v) {
    final s = (v as String?)?.replaceAll(RegExp(r'\s+'), ' ').trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static SenalCargo senal(Map<String, dynamic> j) => SenalCargo(
    codEmpleado: _int(j['codEmpleado']) ?? 0,
    persona: _texto(j['persona']) ?? '—',
    cargo: _texto(j['cargo']),
    cargoDesde: soloFecha(j['cargoDesde']),
    nombreSucursal: _texto(j['nombreSucursal']),
    idTarRuti: _int(j['idTarRuti']) ?? 0,
    tarea: _texto(j['tarea']) ?? '—',
    ocurrencias: _int(j['ocurrencias']) ?? 0,
    desde: soloFecha(j['desde']),
    ultimaHecha: soloFecha(j['ultimaHecha']),
    laHaceOtro: _texto(j['laHaceOtro']),
    tareasDeLaPersona: _int(j['tareasDeLaPersona']) ?? 0,
    motivo: _texto(j['motivo']) ?? '',
    idSC: _int(j['idSC']),
    calladaHasta: soloFecha(j['calladaHasta']),
    obsCallada: _texto(j['obsCallada']),
    calladaPor: _texto(j['calladaPor']),
  );
}
