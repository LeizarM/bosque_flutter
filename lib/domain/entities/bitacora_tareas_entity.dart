// Destino final: lib/domain/entities/bitacora_tareas_entity.dart
import 'package:bosque_flutter/core/utils/fecha_sql.dart';

/// Cómo terminó una ocurrencia, vista desde la bitácora (archivo SQL 55).
///
/// **No es `fueRealizado`.** En seis años hubo cinco respuestas "No": la gente
/// no marca que no hizo algo, deja de responder. Por eso una pendiente cuya
/// fecha ya pasó cuenta como no realizada, y "En plazo" es solo la pendiente
/// que todavía está a tiempo.
enum Cumplimiento {
  realizada('R', 'Realizada', 'Realizadas'),
  noRealizada('N', 'No realizada', 'No realizadas'),
  noAplica('A', 'No aplica', 'No aplica'),
  enPlazo('P', 'En plazo', 'En plazo');

  const Cumplimiento(this.codigo, this.etiqueta, this.plural);

  /// La letra que devuelve y acepta el SP.
  final String codigo;
  final String etiqueta;
  final String plural;

  static Cumplimiento? desdeCodigo(String? codigo) {
    for (final c in values) {
      if (c.codigo == codigo) return c;
    }
    return null;
  }
}

/// Una ocurrencia de la bitácora de cumplimiento.
class BitacoraCumplimientoEntity {
  final int idBitTarea;
  final DateTime? fechaPresentacion;
  final DateTime? fechaCompletado;
  final int? idTarRuti;
  final String nombreTareaRutinaria;
  final int? idFrec;
  final String? descripcionFrecuencia;
  final int? codEmpleado;
  final String nombreEmpleado;

  /// El cargo y la sucursal que la persona tenía en la fecha de la tarea, no
  /// los de hoy: si cambió de cargo, la tarea vieja sigue contando para el
  /// cargo que tenía.
  final int? codCargo;
  final String? descripcionCargo;
  final int? codSucursal;
  final String? nombreSucursal;

  final int? fueRealizado;
  final Cumplimiento? cumplimiento;
  final String? obs;

  /// Quién respondió. Vacío en las que nadie respondió.
  final String? nombreRespondio;

  const BitacoraCumplimientoEntity({
    required this.idBitTarea,
    this.fechaPresentacion,
    this.fechaCompletado,
    this.idTarRuti,
    required this.nombreTareaRutinaria,
    this.idFrec,
    this.descripcionFrecuencia,
    this.codEmpleado,
    required this.nombreEmpleado,
    this.codCargo,
    this.descripcionCargo,
    this.codSucursal,
    this.nombreSucursal,
    this.fueRealizado,
    this.cumplimiento,
    this.obs,
    this.nombreRespondio,
  });
}

/// Los filtros de la bitácora de cumplimiento, tal como viajan al servidor.
///
/// La pantalla y el PDF usan este mismo objeto: si el PDF armara sus filtros
/// por su cuenta, tarde o temprano imprimiría algo distinto de lo que se ve.
class FiltroBitacora {
  final DateTime desde;
  final DateTime hasta;
  final int? codSucursal;
  final int? codCargo;
  final int? codEmpleado;
  final int? idTarRuti;
  final Cumplimiento? cumplimiento;

  const FiltroBitacora({
    required this.desde,
    required this.hasta,
    this.codSucursal,
    this.codCargo,
    this.codEmpleado,
    this.idTarRuti,
    this.cumplimiento,
  });

  Map<String, dynamic> toJson() => {
    'fechaIni': fechaParaSql(desde),
    'fechaFin': fechaParaSql(hasta),
    if (codSucursal != null) 'codSucursal': codSucursal,
    if (codCargo != null) 'codCargo': codCargo,
    if (codEmpleado != null) 'codEmpleado': codEmpleado,
    if (idTarRuti != null) 'idTarRuti': idTarRuti,
    if (cumplimiento != null) 'cumplimiento': cumplimiento!.codigo,
  };
}

/// Los motivos del resumen de generación, en el orden en que el generador los
/// evalúa (archivo SQL 54). "Generadas" va aparte: no es un motivo para
/// quedar afuera.
const motivosDelGenerador = [
  'A requerimiento',
  'Empleado dado de baja',
  'Asignacion inactiva',
  'Cargo no vigente',
  'Asignacion fuera de vigencia',
  'De permiso',
  'Paso los filtros (frecuencia o ya existia)',
];

const motivoGeneradas = 'Generadas';

// Los textos salen del SQL sin tildes (el archivo se corre con sqlcmd y así
// no hay problemas de codificación). Se ponen aquí, al mostrarlos.
const _conTildes = {
  'Asignacion inactiva': 'Asignación inactiva',
  'Asignacion fuera de vigencia': 'Asignación fuera de vigencia',
  'Paso los filtros (frecuencia o ya existia)':
      'Pasó los filtros (frecuencia o ya existía)',
  'Es a requerimiento: la ocurrencia se crea al entrar al submodulo, el Job no la genera.':
      'Es a requerimiento: la ocurrencia se crea al entrar al submódulo, el Job no la genera.',
  'La persona no tiene una relacion laboral activa.':
      'La persona no tiene una relación laboral activa.',
  'La asignacion de esta tarea a su cargo esta inactiva.':
      'La asignación de esta tarea a su cargo está inactiva.',
  'Ese cargo no es el que la persona tenia en esa fecha.':
      'Ese cargo no es el que la persona tenía en esa fecha.',
  'La asignacion no estaba vigente en esa fecha.':
      'La asignación no estaba vigente en esa fecha.',
  'La persona estaba de permiso ese dia.':
      'La persona estaba de permiso ese día.',
  'Se genero.': 'Se generó.',
  'Paso todos los filtros, pero el Job todavia no corrio hoy.':
      'Pasó todos los filtros, pero el Job todavía no corrió hoy.',
  'Paso todos los filtros: la frecuencia de la tarea no vence en esa fecha.':
      'Pasó todos los filtros: la frecuencia de la tarea no vence en esa fecha.',
};

/// Un texto del SQL con sus tildes. Lo que no conoce lo devuelve igual.
String conTildes(String texto) => _conTildes[texto] ?? texto;

/// Qué quiere decir cada motivo del resumen de generación, en una línea.
///
/// Marcelo (2026-09-11), mirando "Corridas del generador": "¿qué significa ese
/// panel, es de todos o de cada persona? No lo ubico bien". Los nombres de los
/// motivos salen del SQL y solo se entendían conociendo el generador.
const _explicacionDelMotivo = {
  'A requerimiento':
      'Tareas que se abren desde su módulo (Caja Chica, Coches…): el Job no las genera.',
  'Empleado dado de baja': 'La persona ya no trabaja en la empresa.',
  'Asignacion inactiva': 'La tarea está desactivada para ese cargo.',
  'Cargo no vigente': 'Es un cargo que la persona tuvo antes: hoy tiene otro.',
  'Asignacion fuera de vigencia':
      'La asignación al cargo todavía no empieza o ya terminó.',
  'De permiso': 'La persona está de permiso ese día.',
  'Paso los filtros (frecuencia o ya existia)':
      'Quedó habilitada: se genera si su frecuencia cae ese día y no existía ya.',
  motivoGeneradas: 'Ocurrencias nuevas que creó esta corrida.',
};

/// La explicación de un motivo del generador, o `null` si no se conoce.
String? explicacionDelMotivo(String motivo) => _explicacionDelMotivo[motivo];

/// Cuántos candidatos cayeron en un motivo, en una corrida del generador.
class ResumenGeneracionEntity {
  final DateTime corrida;
  final String motivo;
  final int cantidad;

  const ResumenGeneracionEntity({
    required this.corrida,
    required this.motivo,
    required this.cantidad,
  });

  bool get esGeneradas => motivo == motivoGeneradas;

  /// Posición del motivo en el orden del generador; los desconocidos al final.
  int get orden {
    final i = motivosDelGenerador.indexOf(motivo);
    return i < 0 ? motivosDelGenerador.length : i;
  }
}

/// Por qué una tarea le llegó o no a una persona en una fecha.
class DiagnosticoGeneracionEntity {
  final int? idTarRuti;
  final String? tarea;
  final int? idFrec;
  final String? frecuencia;
  final int? codCargo;
  final String? cargo;
  final String? sucursal;

  /// -1 ninguno de sus cargos la tuvo; 0 pasó todos los filtros; 1 a 6 el
  /// primer filtro del generador que la dejó afuera.
  final int filtro;
  final String motivo;
  final bool existeOcurrencia;
  final int? idBitTarea;
  final int? fueRealizado;

  const DiagnosticoGeneracionEntity({
    this.idTarRuti,
    this.tarea,
    this.idFrec,
    this.frecuencia,
    this.codCargo,
    this.cargo,
    this.sucursal,
    required this.filtro,
    required this.motivo,
    required this.existeOcurrencia,
    this.idBitTarea,
    this.fueRealizado,
  });

  String get motivoLegible => conTildes(motivo);

  /// Pasó los filtros pero no hay ocurrencia: no vencía ese día, o el Job
  /// todavía no corrió.
  bool get sinGenerar => !existeOcurrencia && filtro == 0;

  /// Algún filtro la dejó afuera, o ninguno de sus cargos la tuvo.
  bool get quedoFuera => !existeOcurrencia && filtro != 0;
}

/// Una persona elegida en el buscador.
class PersonaBuscada {
  final int codEmpleado;
  final String nombre;
  final String? cargo;

  const PersonaBuscada({
    required this.codEmpleado,
    required this.nombre,
    this.cargo,
  });
}
