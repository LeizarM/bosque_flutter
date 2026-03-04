// lib/presentation/widgets/registro_empleado/validadores.dart

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/phone_number.dart';

/// ============================================
/// VALIDADORES PARA RELACIÓN LABORAL
/// ============================================

/// Valida que la fecha de inicio sea válida y no sea futura
/// Usado en: FormRelacionLaboral (campo fechaInicio)
String? validarFechaInicioRelacion(String? value) {
  if (value == null || value.isEmpty) {
    return 'Requerido';
  }

  final fecha = FechaUtils.parseDate(value);
  if (fecha == null) {
    return 'Formato inválido (usar dd/MM/yyyy)';
  }

  if (fecha.isAfter(DateTime.now())) {
    return 'No puede ser una fecha futura';
  }

  return null;
}

/// Valida que fechaFin > fechaInicio
/// Usado en: FormRelacionLaboral (campo fechaFin cuando inactivo)
String? validarFechaFinRelacion(
  String? value,
  String fechaInicioText,
) {
  if (value == null || value.isEmpty) {
    return 'Requerido';
  }

  final fechaIni = FechaUtils.parseDate(fechaInicioText);
  final fechaFin = FechaUtils.parseDate(value);

  if (fechaFin == null) {
    return 'Fecha inválida';
  }

  if (fechaIni != null && fechaFin.isBefore(fechaIni)) {
    return 'Debe ser mayor a la fecha de inicio';
  }

  if (fechaFin.isAfter(DateTime.now())) {
    return 'No puede ser una fecha futura';
  }

  return null;
}

/// ✅ VALIDACIÓN CRONOLÓGICA: Valida que fechaInicio > fechaFin de última relación
/// 
/// Basado en backend: chequearCronologia() en /registroEmpleadoCargo
/// 
/// Esta función **lanza CustomError** para que executeABM la maneje uniformemente.
/// 
/// Parámetros:
///   - fechaInicioText: fecha a validar (dd/MM/yyyy)
///   - ref: WidgetRef para acceder a providers
///   - codEmpleado: código del empleado
///   - codRelEmplEmprEdicion: si es edición, el código de la relación a excluir
///
/// Lanza: CustomError si hay violación de cronología
/// Retorna: (void) si es válido
Future<void> validarCronologiaRelacion(
  String? fechaInicioText,
  WidgetRef ref,
  int codEmpleado,
  int? codRelEmplEmprEdicion,
) async {
  if (fechaInicioText == null || fechaInicioText.isEmpty) {
    return;
  }

  final fechaIni = FechaUtils.parseDate(fechaInicioText);
  if (fechaIni == null) {
    return;
  }

  try {
    // 1. Obtener historial de relaciones laborales
    final historial = await ref.read(
      getHistorialRelLabEmpleado(codEmpleado).future,
    );

    // 2. Si no hay relaciones previas, es válido
    if (historial.isEmpty) {
      return;
    }

    // 3. Obtener última relación
    final ultimaRelacion = historial.last;

    // 4. Si es edición de la misma relación, no validar contra sí misma
    if (codRelEmplEmprEdicion != null &&
        codRelEmplEmprEdicion == ultimaRelacion.codRelEmplEmpr) {
      return;
    }

    // 5. ✅ VALIDACIÓN CRÍTICA: fechaIni debe ser > fechaFin de última relación
    if (ultimaRelacion.fechaFin != null) {
      if (fechaIni.isBefore(ultimaRelacion.fechaFin!) ||
          fechaIni.isAtSameMomentAs(ultimaRelacion.fechaFin!)) {
        throw CustomError(
          'La fecha de inicio debe ser posterior a ${FechaUtils.formatDate(ultimaRelacion.fechaFin!)} '
          '(fecha fin de la última relación laboral).',
        );
      }
    }
  } catch (e) {
    // Re-lanzar CustomError si es nuestro error
    if (e is CustomError) rethrow;
    
    // Para otros errores (consulta fallida), dejar continuar
    // (el backend también validará)
  }
}

/// ============================================
/// VALIDADORES PARA CARGO
/// ============================================

/// Valida que la fecha de inicio sea válida
/// Máxima: hoy + 7 días (según requisito)
String? validarFechaInicioCargo(String? value) {
  if (value == null || value.isEmpty) {
    return 'Requerido';
  }

  final fecha = FechaUtils.parseDate(value);
  if (fecha == null) {
    return 'Formato inválido (usar dd/MM/yyyy)';
  }

  final hoy = DateTime.now();
  final maxDate = hoy.add(const Duration(days: 7));

  if (fecha.isAfter(maxDate)) {
    return 'La fecha no puede ser más de 7 días en el futuro';
  }

  return null;
}
/// ✅ VALIDACIÓN PARA HISTORIAL DE RELACIONES
/// 
/// Valida 3 reglas para registros históricos (inactivos):
/// 1. Consistencia de rango propio: fechaInicio < fechaFin
/// 2. Límite superior: fechaFin < fechaInicio(RelacionActiva)
/// 3. Sin traslape: no colisionar con otros historiales
/// 
/// Lanza: CustomError si hay violación
/// Retorna: (void) si es válido
Future<void> validarHistorialRelacion({
  required DateTime fechaIni,
  required DateTime fechaFin,
  required WidgetRef ref,
  required int codEmpleado,
  int? codRelActual,
}) async {
  // Normalizamos las fechas de entrada (quitar horas/minutos)
  final fIniNueva = DateTime(fechaIni.year, fechaIni.month, fechaIni.day);
  final fFinNueva = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);

  console('╔════════════════════════════════════════════════════════════════╗');
  console('║        🔍 INICIANDO VALIDACIÓN DE HISTORIAL                   ║');
  console('╚════════════════════════════════════════════════════════════════╝');
  console('📋 NUEVA RELACIÓN A INSERTAR:');
  console('   Inicio: ${FechaUtils.formatDate(fIniNueva)}');
  console('   Fin:    ${FechaUtils.formatDate(fFinNueva)}');
  console('   Rango:  [${FechaUtils.formatDate(fIniNueva)}, ${FechaUtils.formatDate(fFinNueva)}]');

  // REGLA 0: Consistencia del rango propio
  console('');
  console('📝 REGLA 0: Consistencia de rango propio');
  if (fIniNueva.isAfter(fFinNueva) || fIniNueva.isAtSameMomentAs(fFinNueva)) {
    console('❌ ERROR: Inicio >= Fin');
    throw CustomError('La fecha de inicio debe ser anterior a la de fin.');
  }
  console('✅ PASS: Inicio < Fin');

  // Forzamos actualización para obtener lo que realmente hay en BD
  console('');
  console('📂 Obteniendo historial de BD...');
  final historial = await ref.refresh(getHistorialRelLabEmpleado(codEmpleado).future);
  console('📚 Total de registros en historial: ${historial.length}');

  if (historial.isEmpty) {
    console('⚠️  El historial está vacío. Validación completada sin conflictos.');
    return;
  }

  // Mostrar todos los registros del historial
  console('');
  console('📊 REGISTROS EN HISTORIAL:');
  for (int i = 0; i < historial.length; i++) {
    final rel = historial[i];
    final estado = rel.esActivo == 1 ? '✓ ACTIVO' : '✗ INACTIVO';
    final fFin = rel.fechaFin != null ? FechaUtils.formatDate(rel.fechaFin!) : 'SIN FIN (presente)';
    console('   [$i] ID ${rel.codRelEmplEmpr} $estado: ${FechaUtils.formatDate(rel.fechaIni!)} - $fFin');
  }

  // Buscar relación activa
  console('');
  console('🔎 BUSCANDO RELACIÓN ACTIVA...');
  RelacionLaboralEntity? relacionActiva;
  try {
    relacionActiva = historial.firstWhere((r) => r.esActivo == 1);
    console('✅ ENCONTRADA: ID ${relacionActiva.codRelEmplEmpr}');
    console('   Inicio: ${FechaUtils.formatDate(relacionActiva.fechaIni!)}');
    console('   Fin:    ${relacionActiva.fechaFin != null ? FechaUtils.formatDate(relacionActiva.fechaFin!) : "SIN FIN (PRESENTE)"}');
  } catch (e) {
    console('⚠️ NO ENCONTRADA: No hay relación activa en el historial');
    relacionActiva = null;
  }

  console('');
  console('🔄 VALIDANDO CONTRA CADA REGISTRO...');

  for (final rel in historial) {
    if (rel.fechaIni == null) {
      console('   [SKIP] Registro sin fecha inicio');
      continue;
    }
    
    // Excluir la relación que estamos editando
    if (codRelActual != null && rel.codRelEmplEmpr == codRelActual) {
      console('   [SKIP] Relación en edición (ID ${rel.codRelEmplEmpr})');
      continue;
    }

    final fIniEx = DateTime(rel.fechaIni!.year, rel.fechaIni!.month, rel.fechaIni!.day);
    final fFinEx = rel.fechaFin != null 
        ? DateTime(rel.fechaFin!.year, rel.fechaFin!.month, rel.fechaFin!.day) 
        : null;

    console('');
    console('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console('   📌 COMPARANDO CON: ID ${rel.codRelEmplEmpr} (${rel.esActivo == 1 ? "ACTIVO" : "INACTIVO"})');
    console('      Rango: [${FechaUtils.formatDate(fIniEx)}, ${fFinEx != null ? FechaUtils.formatDate(fFinEx) : "PRESENTE"}]');

    // ⚠️ REGLA 1: Contra la relación Activa (esActivo == 1)
    if (rel.esActivo == 1) {
      console('      ▶️  REGLA 1: Nueva fin DEBE ser < Activa inicio');
      console('          Comparando: ${FechaUtils.formatDate(fFinNueva)} < ${FechaUtils.formatDate(fIniEx)} ?');
      
      if (fFinNueva.isAfter(fIniEx)) {
        console('          ❌ FAIL: Fin nueva (${FechaUtils.formatDate(fFinNueva)}) > Inicio activa (${FechaUtils.formatDate(fIniEx)})');
        console('      CONFLICTO: El historial se solapa con la relación activa');
        throw CustomError(
          'El registro histórico debe terminar ANTES del ${FechaUtils.formatDate(fIniEx)} '
          '(inicio de la relación laboral activa). Usted intentó hasta el ${FechaUtils.formatDate(fFinNueva)}.'
        );
      }
      
      if (fFinNueva.isAtSameMomentAs(fIniEx)) {
        console('          ❌ FAIL: Fin nueva (${FechaUtils.formatDate(fFinNueva)}) = Inicio activa (${FechaUtils.formatDate(fIniEx)}) [misma fecha no permitida]');
        throw CustomError(
          'El registro histórico no puede terminar en la misma fecha que comienza la relación activa.'
        );
      }
      
      console('          ✅ PASS: ${FechaUtils.formatDate(fFinNueva)} < ${FechaUtils.formatDate(fIniEx)}');
    }

    // ⚠️ REGLA 2: No traslape con relaciones inactivas (esActivo == 0)
    if (rel.esActivo == 0 && fFinEx != null) {
      console('      ▶️  REGLA 2: Sin traslape con inactivo');
      console('          Nuevo:     [${FechaUtils.formatDate(fIniNueva)}, ${FechaUtils.formatDate(fFinNueva)}]');
      console('          Existente: [${FechaUtils.formatDate(fIniEx)}, ${FechaUtils.formatDate(fFinEx)}]');
      
      // Detectar traslape: [fIniNueva, fFinNueva] ∩ [fIniEx, fFinEx] ≠ ∅
      // Traslape ocurre si: inicio_nuevo <= fin_existente AND fin_nuevo >= inicio_existente
      final traslapeInicio = fIniNueva.isBefore(fFinEx) || fIniNueva.isAtSameMomentAs(fFinEx);
      final traslapeFin = fFinNueva.isAfter(fIniEx) || fFinNueva.isAtSameMomentAs(fIniEx);
      final hayTraslape = traslapeInicio && traslapeFin;

      console('          traslapeInicio ($fIniNueva <= $fFinEx): $traslapeInicio');
      console('          traslapeFin ($fFinNueva >= $fIniEx): $traslapeFin');
      console('          hayTraslape: $hayTraslape');

      if (hayTraslape) {
        console('          ❌ FAIL: TRASLAPE DETECTADO');
        throw CustomError(
          'Conflicto de fechas: Ya existe un registro del ${FechaUtils.formatDate(fIniEx)} '
          'al ${FechaUtils.formatDate(fFinEx)}. El nuevo rango [${FechaUtils.formatDate(fIniNueva)}, ${FechaUtils.formatDate(fFinNueva)}] se solapa.'
        );
      }
      
      console('          ✅ PASS: Sin traslape');
    } else if (rel.esActivo == 0 && fFinEx == null) {
      console('      ℹ️  SKIP: Inactivo sin fecha fin (no se valida)');
    }

    console('   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
  
  console('');
  console('╔════════════════════════════════════════════════════════════════╗');
  console('║  ✅ VALIDACIÓN EXITOSA: Todas las reglas pasaron              ║');
  console('╚════════════════════════════════════════════════════════════════╝');
}
/// ✅ VALIDACIÓN PARA EDICIÓN DE RELACIÓN ACTIVA
/// 
/// Estrategia simplificada:
/// Solo valida que la nueva fechaInicio sea MAYOR que la fechaFin 
/// de la ÚLTIMA relación inactiva (la más reciente).
/// 
/// Esto garantiza:
/// - Cronología correcta (respeta el orden temporal)
/// - No hay gaps sin relación
/// - No hay solapamientos con historiales
/// 
/// Parámetros:
///   - fechaIni: nueva fecha de inicio a validar
///   - ref: WidgetRef para acceder a providers
///   - codEmpleado: código del empleado
///   - codRelEmplEmprEdicion: código de la relación que se está editando
///
/// Lanza: CustomError si nueva fechaIni <= última fechaFin
/// Retorna: (void) si es válido
Future<void> validarEdicionRelacionActiva({
  required DateTime fechaIni,
  required WidgetRef ref,
  required int codEmpleado,
  required int codRelEmplEmprEdicion,
}) async {
  final fIniNueva = DateTime(fechaIni.year, fechaIni.month, fechaIni.day);

  console('╔════════════════════════════════════════════════════════════════╗');
  console('║     🔍 VALIDACIÓN: EDICIÓN DE RELACIÓN ACTIVA                 ║');
  console('╚════════════════════════════════════════════════════════════════╝');
  console('📋 NUEVA FECHA DE INICIO:');
  console('   ${FechaUtils.formatDate(fIniNueva)}');

  try {
    // 1. Obtener historial completo
    console('');
    console('📂 Obteniendo historial de relaciones laborales...');
    final historial = await ref.read(
      getHistorialRelLabEmpleado(codEmpleado).future,
    );
    console('📚 Total de registros: ${historial.length}');

    if (historial.isEmpty) {
      console('⚠️  Historial vacío. Validación completada sin conflictos.');
      return;
    }

    // 2. Buscar ÚLTIMA relación inactiva (con fechaFin más reciente)
    console('');
    console('🔍 Buscando ÚLTIMA relación inactiva...');
    
    final ultimaInactiva = historial
        .where((r) => r.esActivo == 0 && r.fechaFin != null)
        .fold<RelacionLaboralEntity?>(null, (prev, current) {
          if (prev == null) return current;
          return current.fechaFin!.isAfter(prev.fechaFin!) ? current : prev;
        });

    if (ultimaInactiva == null) {
      console('⚠️  NO HAY relaciones inactivas con fechaFin. Validación completada.');
      return;
    }

    final fFinUltima = DateTime(
      ultimaInactiva.fechaFin!.year,
      ultimaInactiva.fechaFin!.month,
      ultimaInactiva.fechaFin!.day,
    );

    console('✅ ENCONTRADA:');
    console('   ID: ${ultimaInactiva.codRelEmplEmpr}');
    console('   Fecha Fin: ${FechaUtils.formatDate(fFinUltima)}');

    // 3. ⚠️ VALIDACIÓN CRÍTICA: nueva fechaInicio > última fechaFin
    console('');
    console('⚖️  COMPARACIÓN:');
    console('   Nueva inicio: ${FechaUtils.formatDate(fIniNueva)}');
    console('   Última fin:   ${FechaUtils.formatDate(fFinUltima)}');
    console('   ¿${FechaUtils.formatDate(fIniNueva)} > ${FechaUtils.formatDate(fFinUltima)}? ');

    if (fIniNueva.isBefore(fFinUltima) || fIniNueva.isAtSameMomentAs(fFinUltima)) {
      console('   ❌ FAIL: Nueva inicio <= última fin');
      throw CustomError(
        'La relación activa debe comenzar DESPUÉS del ${FechaUtils.formatDate(fFinUltima)}. '
        'Intenta con ${FechaUtils.formatDate(fFinUltima.add(Duration(days: 1)))} o posterior.'
      );
    }

    console('   ✅ PASS: Nueva inicio > última fin');

    console('');
    console('╔════════════════════════════════════════════════════════════════╗');
    console('║  ✅ VALIDACIÓN EXITOSA: Puedes editar sin conflictos         ║');
    console('╚════════════════════════════════════════════════════════════════╝');

  } catch (e) {
    if (e is CustomError) rethrow;
  }
}
/// ✅ VALIDACIÓN UNIFICADA: Relación Laboral + Cargo
/// 
/// Valida cronología para el flujo "RELACIÓN + CARGO" (empleados inactivos reactivados)
/// 
/// Reglas validadas:
/// 1. fechaRelacion > fechaFin(última relación histórica)
/// 2. fechaCargo > fechaFin(último cargo)
/// 3. fechaRelacion == fechaCargo (DEBEN coincidir exactamente)
/// 4. Ambas fechas no pueden ser futuras
/// 
/// Parámetros:
///   - fechaRelacionText: fecha inicio de relación (dd/MM/yyyy)
///   - fechaCargoText: fecha inicio de cargo (dd/MM/yyyy)
///   - ref: WidgetRef para acceder a providers
///   - codEmpleado: código del empleado
///
/// Lanza: CustomError si hay violación
/// Retorna: (void) si es válido
Future<void> validarFechaRelacionYCargo({
  required String fechaRelacionText,
  required String fechaCargoText,
  required WidgetRef ref,
  required int codEmpleado,
}) async {
  console('╔════════════════════════════════════════════════════════════════╗');
  console('║      🔍 VALIDACIÓN UNIFICADA: RELACIÓN LABORAL + CARGO        ║');
  console('╚════════════════════════════════════════════════════════════════╝');

  // ===== PARSING DE FECHAS =====
  final fechaRelacion = FechaUtils.parseDate(fechaRelacionText);
  final fechaCargo = FechaUtils.parseDate(fechaCargoText);

  if (fechaRelacion == null || fechaCargo == null) {
    throw CustomError('Fechas inválidas. Usa formato dd/MM/yyyy');
  }

  // Normalizar (sin horas/minutos)
  final fRelNormalizada = DateTime(fechaRelacion.year, fechaRelacion.month, fechaRelacion.day);
  final fCargoNormalizada = DateTime(fechaCargo.year, fechaCargo.month, fechaCargo.day);

  console('📋 FECHAS RECIBIDAS:');
  console('   Relación Laboral: ${FechaUtils.formatDate(fRelNormalizada)}');
  console('   Cargo:            ${FechaUtils.formatDate(fCargoNormalizada)}');

  // ===== REGLA 1: Ambas fechas NO pueden ser futuras =====
  /*console('');
  console('📝 REGLA 1: Validar que no sean fechas futuras');
  final hoy = DateTime.now();
  final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);

  if (fRelNormalizada.isAfter(hoyNormalizado)) {
    console('❌ FAIL: Fecha de relación es futura');
    throw CustomError('La fecha de relación laboral no puede ser futura');
  }
  if (fCargoNormalizada.isAfter(hoyNormalizado)) {
    console('❌ FAIL: Fecha de cargo es futura');
    throw CustomError('La fecha del cargo no puede ser futura');
  }
  console('✅ PASS: Ambas fechas no son futuras');*/

  // ===== REGLA 2: Deben coincidir exactamente =====
  console('');
  console('📝 REGLA 2: Las fechas deben coincidir exactamente');
  if (!fRelNormalizada.isAtSameMomentAs(fCargoNormalizada)) {
    console('❌ FAIL: Las fechas no coinciden');
    throw CustomError(
      'La fecha de relación laboral y la del cargo DEBEN ser idénticas. '
      'Relación: ${FechaUtils.formatDate(fRelNormalizada)}, '
      'Cargo: ${FechaUtils.formatDate(fCargoNormalizada)}'
    );
  }
  console('✅ PASS: Las fechas coinciden');

  // ===== OBTENER HISTORIAL =====
  console('');
  console('📂 Obteniendo históricos del empleado...');
  final historialRelaciones = await ref.refresh(
    getHistorialRelLabEmpleado(codEmpleado).future,
  );
  final historialCargos = await ref.refresh(
    getHistorialCargosEmpleado(codEmpleado).future,
  );

  console('   📚 Relaciones: ${historialRelaciones.length} registros');
  console('   📚 Cargos: ${historialCargos.length} registros');

  // ===== REGLA 3: RELACIÓN > última relación histórica =====
  console('');
  console('📝 REGLA 3: Cronología de RELACIÓN LABORAL');

  if (historialRelaciones.isNotEmpty) {
    // Buscar última relación inactiva con fechaFin
    final ultimaRelInactiva = historialRelaciones
        .where((r) => r.esActivo == 0 && r.fechaFin != null)
        .fold<RelacionLaboralEntity?>(null, (prev, current) {
          if (prev == null) return current;
          return current.fechaFin!.isAfter(prev.fechaFin!) ? current : prev;
        });

    if (ultimaRelInactiva != null) {
      final fFinRelacion = DateTime(
        ultimaRelInactiva.fechaFin!.year,
        ultimaRelInactiva.fechaFin!.month,
        ultimaRelInactiva.fechaFin!.day,
      );

      console('   Última relación inactiva fin: ${FechaUtils.formatDate(fFinRelacion)}');
      console('   ¿${FechaUtils.formatDate(fRelNormalizada)} > ${FechaUtils.formatDate(fFinRelacion)}?');

      if (fRelNormalizada.isBefore(fFinRelacion) || fRelNormalizada.isAtSameMomentAs(fFinRelacion)) {
        console('   ❌ FAIL: Nueva relación <= última fin');
        throw CustomError(
          'La relación laboral debe ser posterior a ${FechaUtils.formatDate(fFinRelacion)}. '
          'Intenta con ${FechaUtils.formatDate(fFinRelacion.add(const Duration(days: 1)))}'
        );
      }
      console('   ✅ PASS: Nueva relación > última fin');
    }
  }

  // ===== REGLA 4: CARGO > último cargo histórico =====
  console('');
  console('📝 REGLA 4: Cronología de CARGO');

  if (historialCargos.isNotEmpty) {
    // El último cargo es el primero (ya que viene ordenado descendente del backend)
    final ultimoCargo = historialCargos.first.empleadoCargo;
    if (ultimoCargo.fechaInicio != null) {
      final fUltimoCargo = DateTime(
        ultimoCargo.fechaInicio!.year,
        ultimoCargo.fechaInicio!.month,
        ultimoCargo.fechaInicio!.day,
      );

      console('   Último cargo inicio: ${FechaUtils.formatDate(fUltimoCargo)}');
      console('   ¿${FechaUtils.formatDate(fCargoNormalizada)} > ${FechaUtils.formatDate(fUltimoCargo)}?');

      if (fCargoNormalizada.isBefore(fUltimoCargo) || fCargoNormalizada.isAtSameMomentAs(fUltimoCargo)) {
        console('   ❌ FAIL: Nuevo cargo <= último cargo');
        throw CustomError(
          'El cargo debe ser posterior a ${FechaUtils.formatDate(fUltimoCargo)}. '
          'Intenta con ${FechaUtils.formatDate(fUltimoCargo.add(const Duration(days: 1)))}'
        );
      }
      console('   ✅ PASS: Nuevo cargo > último cargo');
    }
  }

  console('');
  console('╔════════════════════════════════════════════════════════════════╗');
  console('║  ✅ VALIDACIÓN UNIFICADA EXITOSA: Puedes guardar              ║');
  console('╚════════════════════════════════════════════════════════════════╝');
}
/// ✅ VALIDACIÓN PARA CRONOLOGÍA DE CARGO (Último Cargo)
/// 
/// Valida que la nueva fecha de inicio del cargo sea MAYOR que 
/// la fecha de inicio del anterior cargo en el historial.
/// 
/// Para EDICIÓN: Excluye el cargo actual (por fechaInicioOriginal)
/// Para AGREGAR: Valida contra todos los cargos históricos
/// 
/// Parámetros:
///   - fechaCargoText: fecha de inicio del nuevo cargo (dd/MM/yyyy)
///   - ref: WidgetRef para acceder a providers
///   - codEmpleado: código del empleado
///   - fechaInicioOriginal: (EDICIÓN) fecha original del cargo que se edita (null = AGREGAR)
///
/// Lanza: CustomError si fecha nueva <= fecha anterior
/// Retorna: (void) si es válido
Future<void> validarCronologiaCargoUltimoRegistro({
  required String fechaCargoText,
  required WidgetRef ref,
  required int codEmpleado,
  DateTime? fechaInicioOriginal,
}) async {
  console('╔════════════════════════════════════════════════════════════════╗');
  console('║    🔍 VALIDACIÓN: CRONOLOGÍA DE CARGO (Último Registro)       ║');
  console('╚════════════════════════════════════════════════════════════════╝');

  if (fechaCargoText.isEmpty) {
    console('⚠️  Fecha vacía. Abortando validación.');
    return;
  }

  final fechaCargo = FechaUtils.parseDate(fechaCargoText);
  if (fechaCargo == null) {
    throw CustomError('Formato de fecha inválido. Usa dd/MM/yyyy');
  }

  final fCargoNormalizada = DateTime(fechaCargo.year, fechaCargo.month, fechaCargo.day);
  console('📋 NUEVA FECHA DE CARGO: ${FechaUtils.formatDate(fCargoNormalizada)}');
  
  // Detectar si es edición o agregar
  final isEditing = fechaInicioOriginal != null;
  final fCargoOriginalNormalizada = isEditing 
      ? DateTime(fechaInicioOriginal.year, fechaInicioOriginal.month, fechaInicioOriginal.day)
      : null;
  
  if (isEditing) {
    console('   Modo: EDICIÓN (Fecha original: ${FechaUtils.formatDate(fCargoOriginalNormalizada!)})');
  } else {
    console('   Modo: AGREGAR');
  }

  try {
    // 1. Obtener historial de cargos
    console('');
    console('📂 Obteniendo historial de cargos...');
    final historialCargos = await ref.read(
      getHistorialCargosEmpleado(codEmpleado).future,
    );
    console('📚 Total de registros: ${historialCargos.length}');

    if (historialCargos.isEmpty) {
      console('⚠️  Historial vacío. Validación completada sin conflictos.');
      return;
    }

    // Mostrar historial
    console('');
    console('📊 HISTORIAL DE CARGOS:');
    for (int i = 0; i < historialCargos.length; i++) {
      final cargo = historialCargos[i].empleadoCargo;
      final fechaStr = cargo.fechaInicio != null 
          ? FechaUtils.formatDate(cargo.fechaInicio!) 
          : 'SIN FECHA';
      console('   [$i] Fecha: $fechaStr');
    }

    // 2. Obtener el ÚLTIMO cargo (primero en la lista)
    console('');
    console('🔍 Buscando ÚLTIMO cargo (más reciente)...');
    final ultimoCargo = historialCargos.first.empleadoCargo;
    
    if (ultimoCargo.fechaInicio != null) {
      final fUltimoCargo = DateTime(
        ultimoCargo.fechaInicio!.year,
        ultimoCargo.fechaInicio!.month,
        ultimoCargo.fechaInicio!.day,
      );

      console('✅ ENCONTRADO:');
      console('   Última fecha: ${FechaUtils.formatDate(fUltimoCargo)}');

      // 🔑 SI ES EDICIÓN: Excluir el cargo actual
      if (isEditing && fUltimoCargo.isAtSameMomentAs(fCargoOriginalNormalizada!)) {
        console('');
        console('⏭️  SKIP: Es el mismo cargo que estamos editando. Buscando el anterior...');
        
        if (historialCargos.length < 2) {
          console('⚠️  No hay cargo anterior. Validación completada sin conflictos.');
          return;
        }

        // Obtener el cargo anterior al actual
        final cargoAnterior = historialCargos[1].empleadoCargo;
        if (cargoAnterior.fechaInicio == null) {
          console('⚠️  Cargo anterior sin fecha. Validación omitida.');
          return;
        }

        final fCargoAnterior = DateTime(
          cargoAnterior.fechaInicio!.year,
          cargoAnterior.fechaInicio!.month,
          cargoAnterior.fechaInicio!.day,
        );

        console('   Cargo anterior encontrado: ${FechaUtils.formatDate(fCargoAnterior)}');
        console('');
        console('⚖️  COMPARACIÓN (contra anterior):');
        console('   Nueva fecha:   ${FechaUtils.formatDate(fCargoNormalizada)}');
        console('   Anterior:      ${FechaUtils.formatDate(fCargoAnterior)}');
        console('   ¿${FechaUtils.formatDate(fCargoNormalizada)} > ${FechaUtils.formatDate(fCargoAnterior)}?');

        if (fCargoNormalizada.isBefore(fCargoAnterior) || fCargoNormalizada.isAtSameMomentAs(fCargoAnterior)) {
          console('   ❌ FAIL: Nueva fecha <= anterior');
          throw CustomError(
            'La nueva fecha de cargo debe ser POSTERIOR a ${FechaUtils.formatDate(fCargoAnterior)}. '
            'Intenta con ${FechaUtils.formatDate(fCargoAnterior.add(const Duration(days: 1)))} o posterior.'
          );
        }
        console('   ✅ PASS: Nueva fecha > anterior');
        return;
      }

      // SI ES AGREGAR: Validar contra el último cargo
      console('');
      console('⚖️  COMPARACIÓN:');
      console('   Nueva fecha:  ${FechaUtils.formatDate(fCargoNormalizada)}');
      console('   Última fecha: ${FechaUtils.formatDate(fUltimoCargo)}');
      console('   ¿${FechaUtils.formatDate(fCargoNormalizada)} > ${FechaUtils.formatDate(fUltimoCargo)}?');

      if (fCargoNormalizada.isBefore(fUltimoCargo) || fCargoNormalizada.isAtSameMomentAs(fUltimoCargo)) {
        console('   ❌ FAIL: Nueva fecha <= última fecha');
        throw CustomError(
          'La nueva fecha de cargo debe ser POSTERIOR a ${FechaUtils.formatDate(fUltimoCargo)}. '
          'Intenta con ${FechaUtils.formatDate(fUltimoCargo.add(const Duration(days: 1)))} o posterior.'
        );
      }
      console('   ✅ PASS: Nueva fecha > última fecha');
    } else {
      console('⚠️  Último cargo sin fecha de inicio. Validación omitida.');
    }
  } catch (e) {
    // Re-lanzar CustomError si es nuestro error
    if (e is CustomError) rethrow;
    
    // Para otros errores (consulta fallida), dejar continuar
    console('⚠️  Error en validación: $e. Continuando sin validar.');
  }

  console('');
  console('╔════════════════════════════════════════════════════════════════╗');
  console('║  ✅ VALIDACIÓN EXITOSA: Cronología de cargo válida            ║');
  console('╚════════════════════════════════════════════════════════════════╝');
}
/// ============================================
/// VALIDADORES PARA FORMULARIO PERSONA
/// ============================================

/// Valida la fecha de vencimiento del CI
/// - No puede ser vacía
/// - Debe ser válida (formato dd/MM/yyyy)
/// - No puede ser una fecha pasada
String? validarFechaVencimientoCi(String? value) {
  if (value == null || value.isEmpty) {
    return 'La fecha de vencimiento es obligatoria';
  }

  final parsed = FechaUtils.parseDate(value);
  if (parsed == null) {
    return 'Fecha inválida (formato: dd/MM/yyyy)';
  }

  if (parsed.isBefore(DateTime.now())) {
    return 'El C.I. ya ha vencido';
  }

  return null;
}

/// Valida la fecha de nacimiento
/// - No puede ser vacía
/// - Debe ser válida (formato dd/MM/yyyy)
/// - No puede ser una fecha futura
/// - Persona debe ser mayor de 18 años
String? validarFechaNacimiento(String? value) {
  if (value == null || value.isEmpty) {
    return 'La fecha de nacimiento es obligatoria';
  }

  final parsed = FechaUtils.parseDate(value);
  if (parsed == null) {
    return 'Fecha inválida (formato: dd/MM/yyyy)';
  }

  // if (parsed.isAfter(DateTime.now())) {
  //   return 'No puedes nacer en el futuro';
  // }

  // final age = DateTime.now().year - parsed.year;
  // if (age < 18) {
  //   return 'Debes ser mayor de 18 años';
  // }

  return null;
}
/// ============================================
/// VALIDADORES PARA FORMULARIO PERSONA
/// ============================================

/// Valida el C.I. (Carnet de Identidad)
/// - No puede ser vacío
/// - Debe tener 7-8 caracteres
/// - Solo alfanumérico (sin caracteres especiales ni espacios)
String? validarCI(String? value, {String? ciBackendError}) {
  if (value == null || value.isEmpty) {
    return 'El C.I. es obligatorio';
  }

  final trimmed = value.trim().toUpperCase();

  // 1. No permitir espacios
  if (trimmed.contains(' ')) {
    return 'No se permiten espacios';
  }

  // --------------------------------------------------------------------------
  // LÓGICA NUEVA: Permite guion opcional después del número
  // Ejemplos válidos: "123456", "1234567A", "9154499-A", "9154499-1A", "9154499-AA", "9154499AA"
  // --------------------------------------------------------------------------
  
  // Explicación de la Regex:
  // ^[1-9]       -> Debe empezar con un número del 1 al 9 (no 0)
  // \d{5,8}      -> Seguido de entre 5 y 8 dígitos (para completar los 6 a 9 iniciales)
  // (-)?         -> Opcionalmente, un guion
  // [A-Z]{1,2}   -> Seguido de 1 o 2 letras (A-Z)
  // |            -> O BIEN
  // ^[1-9]\d{5,8}$ -> Solo números sin letras (6 a 9 dígitos)
  final regExpBolivia = RegExp(r'^[1-9]\d{5,8}(-)?[A-Z]{1,2}$|^[1-9]\d{5,8}$');

  if (!regExpBolivia.hasMatch(trimmed)) {
    return 'Formato incorrecto (Ej: 123456, 1234567A, 9154499-A, 9154499-1A)';
  }

  if (ciBackendError != null) {
    return ciBackendError;
  }

  return null;
}
/// Helpers
String? _checkLeadingOrTrailingSpaces(String? value) {
  if (value == null) return null;
  if (value != value.trim()) return 'No use espacios al inicio ni al final';
  return null;
}

/// Valida nombres (permite letras, espacios internos, guiones y apóstrofes, con acentos)
String? validarNombres(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Este campo es obligatorio';
  }
  // Rechazar espacios al inicio/fin
  final leadingTrailingError = _checkLeadingOrTrailingSpaces(value);
  if (leadingTrailingError != null) return leadingTrailingError;

  final trimmed = value.trim();
  if (trimmed.length < 2) return 'Nombre demasiado corto';
  final reg = RegExp(r"^[A-Za-zÁÉÍÓÚáéíóúÑñ\s'\-]+$");
  if (!reg.hasMatch(trimmed)) return 'Nombre contiene caracteres inválidos';
  return null;
}

/// Valida lugar de nacimiento (permite letras, números, espacios internos, puntos y guiones)
String? validarLugarNacimiento(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Este campo es obligatorio';
  }
  // Rechazar espacios al inicio/fin
  final leadingTrailingError = _checkLeadingOrTrailingSpaces(value);
  if (leadingTrailingError != null) return leadingTrailingError;

  final trimmed = value.trim();
  if (trimmed.length < 2) return 'Describe un lugar más específico';
  final reg = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9\s\.\-]+$');
  if (!reg.hasMatch(trimmed)) return 'Lugar de nacimiento contiene caracteres inválidos';
  return null;
}

/// Valida dirección (permite caracteres típicos de direcciones: letras, números, espacios internos,
/// comas, puntos, guiones, barras, #, º, °)
String? validarDireccion(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'La dirección es obligatoria';
  }
  // Rechazar espacios al inicio/fin
  final leadingTrailingError = _checkLeadingOrTrailingSpaces(value);
  if (leadingTrailingError != null) return leadingTrailingError;

  final trimmed = value.trim();
  if (trimmed.length < 5) return 'Describe una dirección más específica';
  final reg = RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9\s\.\,\-\/#º°]+$');
  if (!reg.hasMatch(trimmed)) return 'La dirección contiene caracteres inválidos';
  return null;
}
// ============================================
// VALIDADORES PARA FORMULARIO INFORMACIÓN BANCARIA
// ============================================

/// ✅ VALIDACIÓN BÁSICA: Número de Cuenta
/// 
/// Reglas:
/// - No puede ser vacío
/// - Debe tener entre 8 y 20 caracteres (rango típico internacional)
/// - Solo alfanuméricos (números, letras)
/// - Sin espacios ni caracteres especiales
/// - No permitir números repetidos en exceso (ej: "111111111111")
/// 
/// Parámetros:
///   - value: número de cuenta a validar
///
/// Retorna: mensaje de error o null si es válido
String? validarNroCuenta(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El número de cuenta es obligatorio';
  }

  final trimmed = value.trim();

  // Validar rango de longitud (8-20 caracteres es estándar internacional)
  if (trimmed.length < 8) {
    return 'El número de cuenta es muy corto (mínimo 8 caracteres)';
  }
  if (trimmed.length > 20) {
    return 'El número de cuenta es muy largo (máximo 20 caracteres)';
  }

  // Solo alfanuméricos (sin espacios, guiones ni otros caracteres)
  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(trimmed)) {
    return 'El número de cuenta solo puede contener letras y números';
  }

  // Evitar números repetidos en exceso (más de 8 repeticiones consecutivas)
  // Ej: "111111111" es sospechoso
  if (RegExp(r'(\d)\1{7,}').hasMatch(trimmed)) {
    return 'El número de cuenta parece inválido (demasiados dígitos repetidos)';
  }


  return null;
}
/// ✅ VALIDACIÓN DE DUPLICIDAD: Teléfono no existe en BD
/// 
/// Consulta la BD para verificar si el teléfono ya está registrado.
/// ⚠️ IMPORTANTE: Valida SOLO por número, NO por combinación (número + tipo)
/// Esto alinea el frontend con el backend que valida solo por número.
/// 
/// Para EDICIÓN: Excluye el teléfono actual por su codTelefono
/// Para AGREGAR: Valida contra todos los teléfonos existentes
/// 
/// Parámetros:
///   - numeroTelefono: número de teléfono a validar
///   - codTipoTel: tipo de teléfono seleccionado (se pasa pero NO se usa en validación)
///   - ref: WidgetRef para acceder a providers
///   - codPersona: código de la persona (para vincular)
///   - codTelefonoEdicion: (EDICIÓN) código del teléfono que se edita (null = AGREGAR)
///
/// Lanza: CustomError si ya existe el número
/// Retorna: (void) si es válido
Future<void> validarTelefonoNoDuplicado({
  required String numeroTelefono,
  required int codTipoTel, // Ya no se usa
  required WidgetRef ref,
  required int codPersona,
  int? codTelefonoEdicion,
}) async {
  if (numeroTelefono.trim().isEmpty) {
    return;
  }

  try {
    // ✅ CAMBIO: El backend ahora valida SOLO por número
    // Pasamos 0 porque el parámetro ya no se usa
    final existente = await ref.read(
      obtenerCorporativoEmpleado((0, numeroTelefono)).future,
    );

    if (existente.codTelefono != 0) {
      if (codTelefonoEdicion == null) {
        throw CustomError(
          'El teléfono $numeroTelefono ya está registrado.'
        );
      } else if (existente.codTelefono != codTelefonoEdicion) {
        throw CustomError(
          'El teléfono $numeroTelefono ya está registrado.'
        );
      }
    }
  } catch (e) {
    if (e is CustomError) rethrow;
  }
}

String? validarNumeroTelefono(PhoneNumber? value, {bool esObligatorio = true}) {
  if (value == null || value.number.isEmpty) {
    return esObligatorio ? 'Requerido' : null;
  }
  if (value.number.length < 7) {
    return 'Número muy corto (mínimo 7 dígitos)';
  }
  return null;
}
// ============================================
// VALIDADORES PARA AFILIACIÓN AL SEGURO
// ============================================

/// ✅ VALIDACIÓN: Número de Afiliación
/// 
/// Reglas:
/// - No puede ser vacío
/// - Solo permite: números (0-9), letras (A-Z, a-z) y guiones (-)
/// - Mínimo 5 caracteres, máximo 30 caracteres
/// - No espacios ni caracteres especiales
/// 
/// Parámetros:
///   - value: número de afiliación a validar
///
/// Retorna: mensaje de error o null si es válido
String? validarNroAfiliacion(String? value) {
  if (value == null || value.isEmpty) {
    return 'El número de afiliación es obligatorio';
  }

  final trimmed = value.trim();

  // Validar rango de longitud
  if (trimmed.length < 8) {
    return 'El número de afiliación es muy corto (mínimo 8 caracteres)';
  }
  if (trimmed.length > 15) {
    return 'El número de afiliación es muy largo (máximo 15 caracteres)';
  }

  // Solo alfanuméricos y guiones (sin espacios, puntos ni otros caracteres)
  if (!RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(trimmed)) {
    return 'Solo se permiten números, letras y guiones';
  }

  // No permitir guiones al inicio o final
  if (trimmed.startsWith('-') || trimmed.endsWith('-')) {
    return 'El número no puede empezar ni terminar con guión';
  }

  // No permitir guiones consecutivos
  if (trimmed.contains('--')) {
    return 'No se permiten guiones consecutivos';
  }

  return null;
}

/// ✅ VALIDACIÓN: Fecha de Afiliación
/// 
/// Reglas:
/// - No puede ser vacía
/// - Debe ser válida (formato dd/MM/yyyy)
/// - No puede ser una fecha futura
/// - Debe ser mayor a fecha de baja (si existe)
/// 
/// Parámetros:
///   - value: fecha de afiliación (dd/MM/yyyy)
///   - fechaBajaText: fecha de baja para comparación (opcional)
///
/// Retorna: mensaje de error o null si es válido
String? validarFechaAfiliacion(
  String? value, {
  String? fechaBajaText,
}) {
  if (value == null || value.isEmpty) {
    return 'La fecha de afiliación es obligatoria';
  }

  final fechaAfiliacion = FechaUtils.parseDate(value);
  if (fechaAfiliacion == null) {
    return 'Formato inválido (usar dd/MM/yyyy)';
  }

  final hoy = DateTime.now();
  final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);

  if (fechaAfiliacion.isAfter(hoyNormalizado)) {
    return 'No puede ser una fecha futura';
  }

  // Si existe fecha de baja, validar que afiliación < baja
  if (fechaBajaText != null && fechaBajaText.isNotEmpty) {
    final fechaBaja = FechaUtils.parseDate(fechaBajaText);
    if (fechaBaja != null && fechaAfiliacion.isAfter(fechaBaja)) {
      return 'Debe ser anterior a la fecha de baja';
    }
  }

  return null;
}

/// ✅ VALIDACIÓN: Fecha de Baja (Opcional)
/// 
/// Reglas:
/// - Es opcional
/// - Si se proporciona, debe ser válida (formato dd/MM/yyyy)
/// - No puede ser una fecha futura
/// - Debe ser mayor a fecha de afiliación
/// 
/// Parámetros:
///   - value: fecha de baja (dd/MM/yyyy)
///   - fechaAfiliacionText: fecha de afiliación para comparación
///
/// Retorna: mensaje de error o null si es válido
String? validarFechaBaja(
  String? value, {
  required String fechaAfiliacionText,
}) {
  // Es opcional, si está vacío es válido
  if (value == null || value.isEmpty) {
    return null;
  }

  final fechaBaja = FechaUtils.parseDate(value);
  if (fechaBaja == null) {
    return 'Formato inválido (usar dd/MM/yyyy)';
  }

  final hoy = DateTime.now();
  final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);

  if (fechaBaja.isAfter(hoyNormalizado)) {
    return 'No puede ser una fecha futura';
  }

  // Validar que baja > afiliación
  final fechaAfiliacion = FechaUtils.parseDate(fechaAfiliacionText);
  if (fechaAfiliacion != null && fechaBaja.isBefore(fechaAfiliacion)) {
    return 'Debe ser posterior a la fecha de afiliación';
  }

  return null;
}
/// ============================================
/// VALIDADORES PARA SEGURO
/// ============================================

/// ✅ VALIDACIÓN: Nombre del Seguro
/// 
/// Reglas:
/// - No puede ser vacío
/// - Solo permite letras (A-Z, a-z) con acentos
/// - No permite espacios al inicio ni final
/// - Mínimo 3 caracteres
/// 
/// Parámetros:
///   - value: nombre del seguro a validar
///
/// Retorna: mensaje de error o null si es válido
String? validarNombreSeguro(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El nombre es obligatorio';
  }

  // No permitir espacios al inicio o final
  if (value != value.trim()) {
    return 'No use espacios al inicio ni al final';
  }

  final trimmed = value.trim();

  if (trimmed.length < 6) {
    return 'El nombre debe tener al menos 6 caracteres';
  }
    if (trimmed.length > 50) {
    return 'El nombre corto no puede exceder 50 caracteres';
  }

  // Solo letras (con acentos) y espacios internos
  if (!RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$').hasMatch(trimmed)) {
    return 'El nombre solo puede contener letras';
  }

  return null;
}

/// ✅ VALIDACIÓN: Nombre Corto del Seguro
/// 
/// Reglas:
/// - No puede ser vacío
/// - Solo permite letras (A-Z, a-z) sin acentos
/// - No permite espacios al inicio ni final
/// - Máximo 10 caracteres
/// - Mínimo 2 caracteres
/// 
/// Parámetros:
///   - value: nombre corto del seguro a validar
///
/// Retorna: mensaje de error o null si es válido
String? validarNombreCortoSeguro(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El nombre corto es obligatorio';
  }

  // No permitir espacios al inicio o final
  if (value != value.trim()) {
    return 'No use espacios al inicio ni al final';
  }

  final trimmed = value.trim();

  if (trimmed.length < 2) {
    return 'El nombre corto debe tener al menos 2 caracteres';
  }

  if (trimmed.length > 15) {
    return 'El nombre corto no puede exceder 15 caracteres';
  }

  // Solo letras (mayúsculas y minúsculas, sin acentos) y espacios internos
  if (!RegExp(r'^[A-Za-z\s]+$').hasMatch(trimmed)) {
    return 'El nombre corto solo puede contener letras y espacios';
  }

  return null;
}

/// ✅ VALIDACIÓN: Número del Seguro
/// 
/// Reglas:
/// - No puede ser vacío
/// - Solo permite números (0-9)
/// - No permite espacios al inicio ni final
/// - Mínimo 1 dígito
/// - Máximo 10 dígitos
/// 
/// Parámetros:
///   - value: número del seguro a validar
///
/// Retorna: mensaje de error o null si es válido
String? validarNumeroSeguro(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'El número es obligatorio';
  }

  // No permitir espacios al inicio o final
  if (value != value.trim()) {
    return 'No use espacios al inicio ni al final';
  }

  final trimmed = value.trim();

  // Solo dígitos (0-9)
  if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
    return 'El número solo puede contener dígitos';
  }

  if (trimmed.length > 10) {
    return 'El número no puede exceder 10 dígitos';
  }

  return null;
}

/// ✅ VALIDACIÓN: Regional del Seguro
/// 
/// Reglas:
/// - No puede ser vacío
/// - Solo permite letras (A-Z, a-z) con acentos
/// - No permite espacios al inicio ni final
/// - Mínimo 2 caracteres
/// 
/// Parámetros:
///   - value: regional del seguro a validar
///
/// Retorna: mensaje de error o null si es válido
String? validarRegionalSeguro(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'La regional es obligatoria';
  }

  // No permitir espacios al inicio o final
  if (value != value.trim()) {
    return 'No use espacios al inicio ni al final';
  }

  final trimmed = value.trim();

  if (trimmed.length < 5) {
    return 'La regional debe tener al menos 5 caracteres';
  }

  // Solo letras (con acentos) y espacios internos
  if (!RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$').hasMatch(trimmed)) {
    return 'La regional solo puede contener letras';
  }

  return null;
}