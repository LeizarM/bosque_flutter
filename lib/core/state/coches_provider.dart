import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/data/repositories/coches_impl.dart';
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Marca de "no cambiar" para poder limpiar `errorCarga` pasándole null.
const _igual = Object();

class CochesState {
  final List<CocheDelDiaEntity> items;
  final bool cargando;

  /// Si alguna lectura terminó bien: sin esto, un error de red se veía como
  /// "No hay autos activos en tu sucursal".
  final bool cargado;

  /// Por qué falló la última lectura; queda hasta la próxima buena.
  final Object? errorCarga;

  /// Los autos que viajan. Un conjunto: terminar uno no libera a otro.
  final Set<int> guardandoIds;
  final String? mensajeError;

  const CochesState({
    this.items = const [],
    this.cargando = false,
    this.cargado = false,
    this.errorCarga,
    this.guardandoIds = const {},
    this.mensajeError,
  });

  CochesState copyWith({
    List<CocheDelDiaEntity>? items,
    bool? cargando,
    bool? cargado,
    Object? errorCarga = _igual,
    Set<int>? guardandoIds,
    String? mensajeError,
  }) => CochesState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    errorCarga: identical(errorCarga, _igual) ? this.errorCarga : errorCarga,
    guardandoIds: guardandoIds ?? this.guardandoIds,
    mensajeError: mensajeError,
  );

  bool get todosMarcados => items.isNotEmpty && items.every((c) => c.yaMarcado);
}

/// La lista de autos de hoy de tu sucursal (archivo SQL 96). No hay ocurrencia
/// ni parámetros: el backend saca la sucursal del cargo vigente del token.
class CochesNotifier extends StateNotifier<CochesState> {
  final CochesImpl _repo;

  CochesNotifier(this._repo)
    // Arranca cargando: en reposo, el primer cuadro se vería como un error.
    : super(const CochesState(cargando: true)) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final items = await _repo.listarDelDia();
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        cargado: true,
        errorCarga: null,
        items: items,
      );
    } catch (e) {
      if (!mounted) return;
      // Con una lista ya en pantalla se queda y se avisa; en la primera
      // lectura la pantalla muestra el error en su lugar.
      state = state.copyWith(
        cargando: false,
        errorCarga: e,
        mensajeError: state.cargado ? mensajeError(e) : null,
      );
    }
  }

  Future<void> marcarLlegada(int idCo, int llego, {String? obs}) async {
    state = state.copyWith(guardandoIds: {...state.guardandoIds, idCo});
    try {
      await _repo.marcarLlegada(idCo: idCo, llego: llego, obs: obs);
      if (!mounted) return;
      state = state.copyWith(
        items:
            state.items
                .map(
                  (c) =>
                      c.idCo == idCo ? c.copyWith(llego: llego, obs: obs) : c,
                )
                .toList(),
        guardandoIds: {...state.guardandoIds}..remove(idCo),
      );
      await _releer();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        guardandoIds: {...state.guardandoIds}..remove(idCo),
        mensajeError: mensajeError(e),
      );
    }
  }

  /// Después de marcar: trae quién y cuándo, y lo que marcaron otros de la
  /// sucursal. Si falla, queda la marca local; la marca ya se guardó.
  Future<void> _releer() async {
    try {
      final items = await _repo.listarDelDia();
      if (!mounted) return;
      state = state.copyWith(items: items, errorCarga: null);
    } catch (_) {}
  }
}

final _cochesRepoProvider = Provider((ref) => CochesImpl());

final cochesProvider =
    StateNotifierProvider.autoDispose<CochesNotifier, CochesState>(
      (ref) => CochesNotifier(ref.read(_cochesRepoProvider)),
    );
