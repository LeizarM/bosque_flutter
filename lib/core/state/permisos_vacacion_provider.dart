import 'dart:typed_data';
import 'dart:ui';

import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/data/repositories/permisos_vacacion_impl.dart';
import 'package:bosque_flutter/domain/entities/permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_vacacion_repository.dart';
import 'package:bosque_flutter/data/models/feriado_model.dart';

/// Provider para la implementación del repositorio.
final permisosVacacionRepositoryProvider = Provider<PermisosVacacionRepository>(
  (ref) {
    return PermisosVacacionImpl();
  },
);

typedef TiposPermisoParams = ({int codEmpleado, int codUsuarioLogueado});

final tiposPermisoProvider =
    FutureProvider.family<List<TipoPermisoVacacionEntity>, TiposPermisoParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(permisosVacacionRepositoryProvider);
      return await repo.getTiposPermisosVacaciones(
        params.codEmpleado,
        params.codUsuarioLogueado,
      );
    });

/// Provider que obtiene el resumen de vacaciones (días disponibles, asignados, abonados)
/// para un empleado específico utilizando la Acción 'H1'
final vacacionResumenProvider = FutureProvider.family<PermisoEntity?, int>((
  ref,
  codEmpleado,
) async {
  final repo = ref.watch(permisosVacacionRepositoryProvider);
  return await repo.getResumenVacaciones(codEmpleado);
});

/// Provider que maneja la acción de envío de formulario para evitar múltiples clics
final enviarSolicitudPermisoProvider =
    StateNotifierProvider<EnviarSolicitudNotifier, AsyncValue<String?>>((ref) {
      final repo = ref.watch(permisosVacacionRepositoryProvider);
      return EnviarSolicitudNotifier(repo);
    });

class EnviarSolicitudNotifier extends StateNotifier<AsyncValue<String?>> {
  final PermisosVacacionRepository _repo;
  EnviarSolicitudNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> ejecutar(
    SolicitudPermisoEntity solicitud, {
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    state = const AsyncValue.loading();
    try {
      final message = await _repo.crearSolicitudPermiso(solicitud);
      state = AsyncValue.data(message);
      onSuccess(message);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      // Gracias a baseapi.txt, e.toString() ya contiene el mensaje exacto enviado por la BD de SQL
      onError(e.toString().replaceAll("Exception: ", ""));
    }
  }
}
// ════════════════════════════════════════════════════════════════════════════
// permisos_vacacion_provider.dart  — agregar al archivo existente
// ════════════════════════════════════════════════════════════════════════════

/// Solicitudes pendientes para el usuario logueado (Jefe o RRHH).
/// Devuelve lista vacía si el usuario no tiene subordinados → widget se oculta.
final solicitudesPendientesProvider =
    FutureProvider.family<List<SolicitudPermisoEntity>, int>(
      (ref, codUsuarioLogueado) => ref
          .watch(permisosVacacionRepositoryProvider)
          .listarPendientes(codUsuarioLogueado),
    );

/// Aprobar / Rechazar solicitud
final accionSolicitudProvider =
    StateNotifierProvider<AccionSolicitudNotifier, AsyncValue<void>>(
      (ref) => AccionSolicitudNotifier(
        ref.watch(permisosVacacionRepositoryProvider),
      ),
    );

class AccionSolicitudNotifier extends StateNotifier<AsyncValue<void>> {
  final PermisosVacacionRepository _repo;
  AccionSolicitudNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> aprobar({
    required int codSolicitud,
    required int audUsuarioI,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    state = const AsyncValue.loading();
    try {
      final msg = await _repo.aprobarSolicitud(codSolicitud, audUsuarioI);
      state = const AsyncValue.data(null);
      onSuccess(msg);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> rechazar({
    required int codSolicitud,
    required int audUsuarioI,
    required String motivo,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    state = const AsyncValue.loading();
    try {
      final msg = await _repo.rechazarSolicitud(
        codSolicitud,
        audUsuarioI,
        motivo,
      );
      state = const AsyncValue.data(null);
      onSuccess(msg);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> anular({
    required int codSolicitud,
    required int audUsuarioI,
    required String motivo,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    state = const AsyncValue.loading();
    try {
      final msg = await _repo.anularSolicitud(
        codSolicitud,
        audUsuarioI,
        motivo,
      );
      state = const AsyncValue.data(null);
      onSuccess(msg);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      onError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

/// De quién y de cuándo. [anio] o [mes] en `null` = ese eje sin filtrar.
typedef FiltroMisSolicitudes = ({int codEmpleado, int? anio, int? mes});

final misSolicitudesProvider = FutureProvider.family.autoDispose<
  List<SolicitudPermisoEntity>,
  FiltroMisSolicitudes
>((ref, filtro) async {
  final lista = await ref
      .watch(permisosVacacionRepositoryProvider)
      .listarMisSolicitudes(
        filtro.codEmpleado,
        anio: filtro.anio,
        mes: filtro.mes,
      );

  // **El orden se arregla acá y no en el SP.** El SP ordena por `audFechaI`
  // —cuándo se pidió—, que no es el orden en que la lista se lee: alguien
  // pide en agosto la vacación de noviembre y en enero la de mayo. La
  // pantalla agrupa por año de `desde`, y con el orden de pedido el mismo
  // año sale partido en varios tramos. Ordenar en el SP tocaría una consulta
  // en producción para cambiar cómo se ve una pantalla.
  return [...lista]..sort((a, b) => b.desde.compareTo(a.desde));
});

final rptPermisoVacacionProvider = FutureProvider.family<Uint8List, int>((
  ref,
  codPermiso,
) async {
  final repo = ref.watch(permisosVacacionRepositoryProvider);
  return await repo.descargarRptPermisoVacacion(codPermiso);
});

final feriadosProvider = FutureProvider.family<List<FeriadoModel>, int>((
  ref,
  codEmpleado,
) async {
  final repo = ref.watch(permisosVacacionRepositoryProvider);
  return await repo.getFeriados(codEmpleado);
});

final previsualizarSaldoProvider =
    FutureProvider.family<SolicitudPermisoEntity?, SolicitudPermisoEntity>((
      ref,
      solicitudFiltro,
    ) async {
      final repo = ref.watch(permisosVacacionRepositoryProvider);
      return await repo.previsualizarSaldo(solicitudFiltro);
    });

final proximosPermisosDashboardProvider = FutureProvider.family<List<SolicitudPermisoEntity>, int>((
  ref,
  audUsuarioI,
) async {
  final repo = ref.watch(permisosVacacionRepositoryProvider);
  return await repo.obtenerPermisosProximosDashboard(audUsuarioI);
});
