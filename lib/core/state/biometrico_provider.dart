import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/data/repositories/biometrico_impl.dart';
import 'package:bosque_flutter/domain/entities/asistencia_dia_entity.dart';
import 'package:bosque_flutter/domain/entities/bitacora_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_check_in_out_adicional_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_empl_bosq_empl_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_semanal_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hr_semanal_entity.dart';
import 'package:bosque_flutter/domain/entities/bio_hrs_entity.dart';
import 'package:bosque_flutter/domain/entities/resumen_asistencia_empleado_entity.dart';
import 'package:bosque_flutter/domain/repositories/biometrico_repository.dart';

/// LAZY: se fabrica recién cuando algo lo lee (ver el mismo patrón en
/// `entregas_provider.dart`) — nadie paga el costo de este módulo si no
/// entra a la pantalla de Biométrico.
final biometricoRepositoryProvider = Provider<BiometricoRepository>(
  (ref) => BiometricoImpl(),
);

/// El padrón cruce biométrico ⇄ Bosque, para el buscador de empleados.
///
/// Sólo ~400 filas (medido en la base de prueba): se trae completo una vez y
/// se filtra en el cliente con [ComboBuscable] — no hace falta un buscador
/// con rebote como el de `permisos-rrhh`, que sí busca contra miles de
/// empleados en el servidor.
final empleadosBiometricoProvider = FutureProvider<List<BioEmplBosqEmplEntity>>((
  ref,
) async {
  final repo = ref.watch(biometricoRepositoryProvider);
  // soloActivos: true — el backend cruza contra el padrón activo de Bosque y
  // ya excluye a quien dejó la empresa (no es un filtro que se pueda aplicar
  // acá: BioEmplBosqEmplEntity no trae el estado activo/inactivo, sólo el
  // backend lo sabe). Se recalcula en cada carga, así que si el empleado
  // vuelve a estar activo reaparece solo, sin nada que tocar acá.
  final lista = await repo.listarEmpleados({'soloActivos': true});
  // Sólo los enlazados: elegir a alguien sin idEmpleadBio garantiza el 400
  // "El empleado no está enlazado..." del reporte. Mejor no ofrecerlo.
  final enlazados = lista.where((e) => e.enlazado).toList()
    ..sort((a, b) => a.datoNombreBosq.compareTo(b.datoNombreBosq));
  // Un empleado enlazado a DOS usuarios del biométrico (dos filas de
  // tbio_bioEmplBosqEmpl con el mismo idEmpleado — el mismo caso real que
  // hacía aparecer duplicado en el Resumen mensual) aparecería dos veces acá
  // también. El backend ya dedupea el reporte; acá se hace lo mismo por
  // idEmpleado para que el buscador no muestre a la misma persona dos veces
  // — cuál de los dos enlaces quede no importa, `calcularReporte` en el
  // backend resuelve el enlace vigente por su cuenta igual.
  final vistos = <BigInt>{};
  final sinDuplicar = [
    for (final e in enlazados)
      if (vistos.add(e.idEmpleado)) e,
  ];
  return sinDuplicar;
});

/// El padrón COMPLETO del cruce (enlazados y no enlazados) — para la pestaña
/// de Verificación de Empleados. `empleadosBiometricoProvider` de arriba
/// filtra a propósito para el reporte; acá hace falta ver a quién le falta
/// enlazar.
final todosLosEmpleadosBiometricoProvider =
    FutureProvider<List<BioEmplBosqEmplEntity>>((ref) async {
      final repo = ref.watch(biometricoRepositoryProvider);
      final lista = await repo.listarEmpleados({});
      lista.sort((a, b) => a.datoNombreBiom.compareTo(b.datoNombreBiom));
      return lista;
    });

/// El empleado elegido en el buscador. `null` = todavía no eligió a nadie.
final empleadoSeleccionadoBiometricoProvider =
    StateProvider<BioEmplBosqEmplEntity?>((ref) => null);

// ═══════════════════════════════════════════════════════════════════════════
// HORARIOS — plantillas de turno, horarios semanales y asignación
// ═══════════════════════════════════════════════════════════════════════════

/// Las plantillas de turno (`tbio_bioHrs`) — CRUD directo, lista completa.
final bioHrsListProvider = FutureProvider<List<BioHrsEntity>>((ref) async {
  final repo = ref.watch(biometricoRepositoryProvider);
  final lista = await repo.listarHorarios({});
  lista.sort((a, b) => a.nombre.compareTo(b.nombre));
  return lista;
});

/// Los horarios semanales (`tbio_bioHrSemanal`) — cabeceras, lista completa.
final bioHrSemanalListProvider = FutureProvider<List<BioHrSemanalEntity>>((
  ref,
) async {
  final repo = ref.watch(biometricoRepositoryProvider);
  final lista = await repo.listarHorariosSemanales({});
  lista.sort((a, b) => a.nombre.compareTo(b.nombre));
  return lista;
});

/// El detalle (7 días) de UN horario semanal.
final bioHrSemanalDetalleProvider = FutureProvider.family<
  List<BioHrSemanalDetalleEntity>,
  BigInt
>((ref, idHrSemanal) async {
  final repo = ref.watch(biometricoRepositoryProvider);
  final lista = await repo.listarHorariosSemanalesDetalle({
    'idHrSemanal': idHrSemanal.toInt(),
  });
  lista.sort((a, b) => a.dia.compareTo(b.dia));
  return lista;
});

/// Las asignaciones de horario (`tbio_bioHrEmpleado`) de UN empleado —
/// "Programación Mensual por Empleado" del legacy: acá se ve por qué un
/// empleado puede tener N horarios en el mes (varias filas, cada una con su
/// `inicio`).
final bioHrEmpleadoListProvider =
    FutureProvider.family<List<BioHrEmpleadoEntity>, BigInt>((
      ref,
      idEmplead,
    ) async {
      final repo = ref.watch(biometricoRepositoryProvider);
      final lista = await repo.listarHorarioEmpleado({
        'idEmplead': idEmplead.toInt(),
      });
      lista.sort((a, b) {
        final ai = a.inicio, bi = b.inicio;
        if (ai == null || bi == null) return 0;
        return bi.compareTo(ai);
      });
      return lista;
    });

// ═══════════════════════════════════════════════════════════════════════════
// BITÁCORA — quién y por qué, en Marcaciones olvidadas y Horarios
// ═══════════════════════════════════════════════════════════════════════════

/// La clave del historial de UNA fila puntual: qué tabla (`'BioHrEmpleado'`,
/// `'BioHrs'`, `'BioHrSemanal'`, `'BioHrSemanalDetalle'`,
/// `'BioCHECKINOUTAdicinal'`) y qué `idRegistro` — ver
/// `sql/03_bitacora_biometrico.sql` para cómo se arma cada uno.
typedef BitacoraDeRegistro = ({String tabla, String idRegistro});

final bitacoraBiometricoProvider = FutureProvider.autoDispose
    .family<List<BitacoraEntity>, BitacoraDeRegistro>((ref, p) {
      final repo = ref.watch(biometricoRepositoryProvider);
      return repo.listarBitacora({'tabla': p.tabla, 'idRegistro': p.idRegistro});
    });

// ═══════════════════════════════════════════════════════════════════════════
// MARCACIONES OLVIDADAS
// ═══════════════════════════════════════════════════════════════════════════

/// Las marcaciones adicionales (`tbio_bioCHECKINOUTAdicinal`) de UN usuario
/// del biométrico (USERID), más recientes primero.
final bioCheckInOutAdicionalListProvider =
    FutureProvider.family<List<BioCheckInOutAdicionalEntity>, int>((
      ref,
      userId,
    ) async {
      final repo = ref.watch(biometricoRepositoryProvider);
      final lista = await repo.listarMarcacionesAdicionales({
        'USERID': userId,
      });
      lista.sort((a, b) {
        final at = a.checkTime, bt = b.checkTime;
        if (at == null || bt == null) return 0;
        return bt.compareTo(at);
      });
      return lista;
    });

/// El mes que se está mirando (día siempre 1). Arranca en el mes actual.
final mesSeleccionadoBiometricoProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month, 1),
);

/// Parámetros de `reporteBiometricoProvider`. `codEmpleado`/`anio`/`mes`
/// juntos identifican una corrida del reporte mensual.
class ReporteBiometricoParams {
  final BigInt codEmpleado;
  final int anio;
  final int mes;

  const ReporteBiometricoParams({
    required this.codEmpleado,
    required this.anio,
    required this.mes,
  });

  @override
  bool operator ==(Object other) =>
      other is ReporteBiometricoParams &&
      other.codEmpleado == codEmpleado &&
      other.anio == anio &&
      other.mes == mes;

  @override
  int get hashCode => Object.hash(codEmpleado, anio, mes);
}

/// El reporte mensual de asistencia ya corregido (ver `BiometricoController`
/// en el backend): un feriado o un sábado que no le tocaba ya NO sale como
/// falta.
final reporteBiometricoProvider = FutureProvider.family<
  List<AsistenciaDiaEntity>,
  ReporteBiometricoParams
>((ref, params) async {
  final repo = ref.watch(biometricoRepositoryProvider);
  return repo.reporteMensual(
    codEmpleado: params.codEmpleado,
    anio: params.anio,
    mes: params.mes,
  );
});

/// El resumen mensual de todos los empleados enlazados — una fila por
/// persona, con los totales. Puede tardar (recorre a todos, ver el javadoc
/// de `BiometricoController.calcularResumen`), así que cachea por mes con
/// `.family` igual que el reporte individual.
final resumenMensualBiometricoProvider =
    FutureProvider.family<List<ResumenAsistenciaEmpleadoEntity>, DateTime>((
      ref,
      mes,
    ) async {
      final repo = ref.watch(biometricoRepositoryProvider);
      return repo.reporteMensualResumen(anio: mes.year, mes: mes.month);
    });
