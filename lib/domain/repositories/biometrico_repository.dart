import 'dart:typed_data';

import 'package:bosque_flutter/domain/entities/asistencia_dia_entity.dart';
import 'package:bosque_flutter/domain/entities/bitacora_entity.dart';
import 'package:bosque_flutter/domain/entities/resumen_asistencia_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_check_in_out_adicional_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_check_in_out_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_empl_bosq_empl_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_semanal_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_semanal_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_x_empl_expandido_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hrs_entity.dart';

/// Módulo Biométrico (tablas `tbio_`). Un repositorio para las 8 tablas más
/// el reporte compuesto, siguiendo el mismo patrón de un repositorio por
/// feature que `PagosExtranjerosRepository` (no uno por tabla).
///
/// Los `registrar*` reciben el payload como `Map` (no un Model — el dominio
/// no depende de `data/models`) más `acc` ('I'|'U'|'D'); no devuelven id
/// (los `p_abm_Bio*` son legacy, ver `CLAUDE.md` del backend) — sólo
/// lanzan si el backend respondió error.
abstract class BiometricoRepository {
  // ── Marcaciones crudas ──────────────────────────────────────────────────
  Future<List<BioCheckInOutEntity>> listarMarcaciones(
    Map<String, dynamic> filtro,
  );

  /// Dispara la importación mensual desde el dispositivo; retorna el texto
  /// de diagnóstico (conteo antes/después) que manda el backend.
  Future<String> importarMarcacionesMensual(DateTime checkTime);

  // ── Marcaciones adicionales / olvidadas ─────────────────────────────────
  Future<List<BioCheckInOutAdicionalEntity>> listarMarcacionesAdicionales(
    Map<String, dynamic> filtro,
  );
  Future<void> registrarMarcacionAdicional(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  });

  // ── Cruce empleado biométrico ⇄ Bosque ──────────────────────────────────
  Future<List<BioEmplBosqEmplEntity>> listarEmpleados(
    Map<String, dynamic> filtro,
  );

  /// Para ACCION='I'/'U' devuelve `idEmpleadBio` (sin uso real hoy). Para
  /// ACCION='A' ("Importar nuevos"), desde el fix de
  /// `sql/06_fix_p_abm_BioEmplBosqEmpl_ACCION_A.sql`, devuelve la CANTIDAD de
  /// empleados nuevos que entraron — antes ese ACCION nunca tocaba
  /// `@idGenerado` (quedaba en 0 pase lo que pase) y el botón mostraba
  /// siempre el mismo "Importación completada." sin decir si de verdad pasó
  /// algo. Requiere que el script 06 ya haya corrido contra la BD.
  Future<BigInt> registrarEmpleado(Map<String, dynamic> payload, String acc);

  // ── Plantillas de turno ──────────────────────────────────────────────────
  Future<List<BioHrsEntity>> listarHorarios(Map<String, dynamic> filtro);
  Future<void> registrarHorario(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  });

  // ── Horarios semanales — cabecera ───────────────────────────────────────
  Future<List<BioHrSemanalEntity>> listarHorariosSemanales(
    Map<String, dynamic> filtro,
  );
  Future<void> registrarHorarioSemanal(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  });

  // ── Horarios semanales — detalle por día ────────────────────────────────
  Future<List<BioHrSemanalDetalleEntity>> listarHorariosSemanalesDetalle(
    Map<String, dynamic> filtro,
  );
  Future<void> registrarHorarioSemanalDetalle(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  });

  // ── Horario asignado a un empleado ──────────────────────────────────────
  Future<List<BioHrEmpleadoEntity>> listarHorarioEmpleado(
    Map<String, dynamic> filtro,
  );
  Future<void> registrarHorarioEmpleado(
    Map<String, dynamic> payload,
    String acc, {
    String? motivo,
  });

  // ── Calendario expandido (legacy, no lo usa el reporte) ─────────────────
  Future<List<BioHrXEmplExpandidoEntity>> listarCalendarioExpandido(
    Map<String, dynamic> filtro,
  );
  Future<void> registrarCalendarioExpandido(
    Map<String, dynamic> payload,
    String acc,
  );

  /// Regenera el calendario expandido de UN empleado para UN mes — llamar
  /// después de asignar/editar/inactivar un horario en "Por empleado", no
  /// como acción independiente. `p_Rpt_Biometrico` (el reporte legacy, no
  /// éste) es quien lee esta tabla; el reporte nuevo no la necesita.
  Future<void> regenerarCalendarioExpandido({
    required BigInt codEmpleado,
    required int anio,
    required int mes,
  });

  // ── Bitácora de cambios manuales (Marcaciones olvidadas y Horarios) ────
  /// Filtros esperados: `tabla`, `idRegistro` (historial de UNA fila
  /// puntual), `desde`/`hasta` — todos opcionales.
  Future<List<BitacoraEntity>> listarBitacora(Map<String, dynamic> filtro);

  // ── Reporte mensual corregido ───────────────────────────────────────────
  Future<List<AsistenciaDiaEntity>> reporteMensual({
    required BigInt codEmpleado,
    required int anio,
    required int mes,
  });

  /// El mismo reporte, como PDF (`RptBiometricoDetallado.jrxml`) — trae la
  /// columna Obs con el motivo de cada día (feriado / vacación / permiso /
  /// no le tocaba sábado).
  Future<Uint8List> reporteMensualPdf({
    required BigInt codEmpleado,
    required int anio,
    required int mes,
  });

  // ── Resumen mensual — todos los empleados enlazados, un mes ────────────
  Future<List<ResumenAsistenciaEmpleadoEntity>> reporteMensualResumen({
    required int anio,
    required int mes,
  });

  Future<Uint8List> reporteMensualResumenPdf({
    required int anio,
    required int mes,
  });

  /// El reporte DETALLADO día a día (mismo `.jrxml`/columna Obs que
  /// [reporteMensualPdf]) pero de TODOS los empleados enlazados del mes, uno
  /// atrás del otro — no el resumen de una fila por persona
  /// ([reporteMensualResumenPdf]).
  Future<Uint8List> reporteMensualDetalladoTodosPdf({
    required int anio,
    required int mes,
  });

  /// Qué `BioHrSemanal` tiene HOY cada empleado enlazado — una fila por
  /// empleado con el horario semanal vigente y las horas de cada día de la
  /// semana (`RptBiometricoHorarioVigente.jrxml`). No es un reporte
  /// mensual — "ahora mismo", no toma `anio`/`mes`.
  Future<Uint8List> horarioVigentePorEmpleadoPdf();
}
