// Destino final: lib/data/models/bitacora_tareas_model.dart
import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/bitacora_tareas_entity.dart';

/// Lectura de las respuestas de /tareas-rutinarias/bitacora/*.
///
/// Los nombres de las claves son los alias del SP (archivo SQL 55), que el
/// backend pasa tal cual por sus DTO.
class BitacoraTareasModel {
  BitacoraTareasModel._();

  static int? _int(dynamic v) => (v as num?)?.toInt();

  /// El catálogo conserva el formato del sistema anterior: dos espacios entre
  /// palabras y saltos de línea en medio de una descripción.
  static String? _texto(dynamic v) {
    final s = (v as String?)?.replaceAll(RegExp(r'\s+'), ' ').trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static BitacoraCumplimientoEntity cumplimiento(Map<String, dynamic> j) {
    final codEmpleado = _int(j['codEmpleado']);
    return BitacoraCumplimientoEntity(
      idBitTarea: _int(j['idBitTarea']) ?? 0,
      fechaPresentacion: soloFecha(j['fechaPresentacion']),
      fechaCompletado: fechaHora(j['fechaCompletado']),
      idTarRuti: _int(j['idTarRuti']),
      nombreTareaRutinaria:
          _texto(j['nombreTareaRutinaria']) ?? 'Tarea sin nombre',
      idFrec: _int(j['idFrec']),
      descripcionFrecuencia: _texto(j['descripcionFrecuencia']),
      codEmpleado: codEmpleado,
      nombreEmpleado:
          _texto(j['nombreEmpleado']) ?? 'Empleado ${codEmpleado ?? '?'}',
      codCargo: _int(j['codCargo']),
      descripcionCargo: _texto(j['descripcionCargo']),
      codSucursal: _int(j['codSucursal']),
      nombreSucursal: _texto(j['nombreSucursal']),
      fueRealizado: _int(j['fueRealizado']),
      cumplimiento: Cumplimiento.desdeCodigo(j['cumplimiento'] as String?),
      obs: (j['obs'] as String?)?.trim(),
      nombreRespondio: _texto(j['nombreRespondio']),
    );
  }

  static ResumenGeneracionEntity resumen(Map<String, dynamic> j) =>
      ResumenGeneracionEntity(
        corrida: fechaHora(j['corrida']) ?? DateTime(1900),
        motivo: (j['motivo'] as String?)?.trim() ?? '',
        cantidad: _int(j['cantidad']) ?? 0,
      );

  static DiagnosticoGeneracionEntity diagnostico(Map<String, dynamic> j) =>
      DiagnosticoGeneracionEntity(
        idTarRuti: _int(j['idTarRuti']),
        tarea: _texto(j['tarea']),
        idFrec: _int(j['idFrec']),
        frecuencia: _texto(j['frecuencia']),
        codCargo: _int(j['codCargo']),
        cargo: _texto(j['cargo']),
        sucursal: _texto(j['sucursal']),
        filtro: _int(j['filtro']) ?? 0,
        motivo: (j['motivo'] as String?)?.trim() ?? '',
        existeOcurrencia: j['existeOcurrencia'] == true,
        idBitTarea: _int(j['idBitTarea']),
        fueRealizado: _int(j['fueRealizado']),
      );

  /// Un resultado del buscador de empleados (el mismo de Caja Chica): el
  /// nombre viene en `persona.datoPersona` y el cargo tres niveles adentro.
  static PersonaBuscada? persona(Map<String, dynamic> emp) {
    final cod = _int(emp['codEmpleado']);
    if (cod == null || cod <= 0) return null;
    final persona = emp['persona'] as Map<String, dynamic>?;
    final nombre = _texto(persona?['datoPersona']);
    final cargo =
        ((emp['empleadoCargo'] as Map<String, dynamic>?)?['cargoSucursal']
                as Map<String, dynamic>?)?['cargo']
            as Map<String, dynamic>?;
    return PersonaBuscada(
      codEmpleado: cod,
      nombre: nombre ?? 'Empleado $cod',
      cargo: _texto(cargo?['descripcion']),
    );
  }
}
