// Destino final: lib/core/state/coches_provider.dart
import 'package:bosque_flutter/data/repositories/coches_impl.dart';
import 'package:bosque_flutter/domain/entities/coche_del_dia_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Parámetros de la ocurrencia puntual que identifican qué lista de coches
/// cargar. codSucursal ya NO viaja aquí — el proc lo resuelve server-side
/// del cargo vigente del empleado dueño de la ocurrencia, no del login del
/// cliente (un empleado puede tener cargos en más de una sucursal — code-
/// review, 2026-09-03).
typedef CochesParams = ({int idTarRuti, int idBitTarea});

// Marca de "no cambiar" para poder limpiar `errorCarga` pasándole null.
const _igual = Object();

class CochesState {
  final List<CocheDelDiaEntity> items;
  final bool cargando;

  /// Si alguna lectura terminó bien.
  ///
  /// Sin esto, una lectura fallida se veía como "No hay coches activos
  /// configurados para tu sucursal": un error de red contado como una
  /// configuración (auditoría del 2026-09-11).
  final bool cargado;

  /// Por qué falló la última lectura; queda hasta la próxima buena.
  final Object? errorCarga;

  final int? guardandoIdCo;
  final String? mensajeError;
  final bool tareaCerrada;

  const CochesState({
    this.items = const [],
    this.cargando = false,
    this.cargado = false,
    this.errorCarga,
    this.guardandoIdCo,
    this.mensajeError,
    this.tareaCerrada = false,
  });

  CochesState copyWith({
    List<CocheDelDiaEntity>? items,
    bool? cargando,
    bool? cargado,
    Object? errorCarga = _igual,
    int? guardandoIdCo,
    bool limpiarGuardando = false,
    String? mensajeError,
    bool? tareaCerrada,
  }) => CochesState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    errorCarga: identical(errorCarga, _igual) ? this.errorCarga : errorCarga,
    guardandoIdCo:
        limpiarGuardando ? null : (guardandoIdCo ?? this.guardandoIdCo),
    mensajeError: mensajeError,
    tareaCerrada: tareaCerrada ?? this.tareaCerrada,
  );

  bool get todosMarcados => items.isNotEmpty && items.every((c) => c.yaMarcado);
}

class CochesNotifier extends StateNotifier<CochesState> {
  final CochesImpl _repo;
  final CochesParams _params;

  CochesNotifier(this._repo, this._params)
    // Arranca cargando: en reposo, el primer cuadro se vería como un error.
    : super(const CochesState(cargando: true)) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final items = await _repo.listarDelDia(
        idTarRuti: _params.idTarRuti,
        idBitTarea: _params.idBitTarea,
      );
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
        mensajeError: state.cargado ? e.toString() : null,
      );
    }
  }

  Future<void> marcarLlegada(int idCo, int llego, {String? obs}) async {
    state = state.copyWith(guardandoIdCo: idCo);
    try {
      final cerroLaTarea = await _repo.marcarLlegada(
        idCo: idCo,
        llego: llego,
        obs: obs,
      );
      final nuevos =
          state.items
              .map(
                (c) => c.idCo == idCo ? c.copyWith(llego: llego, obs: obs) : c,
              )
              .toList();
      state = state.copyWith(
        items: nuevos,
        limpiarGuardando: true,
        tareaCerrada: cerroLaTarea,
      );
    } catch (e) {
      state = state.copyWith(
        limpiarGuardando: true,
        mensajeError: e.toString(),
      );
    }
  }
}

final _cochesRepoProvider = Provider((ref) => CochesImpl());

final cochesProvider = StateNotifierProvider.autoDispose
    .family<CochesNotifier, CochesState, CochesParams>((ref, params) {
      return CochesNotifier(ref.read(_cochesRepoProvider), params);
    });
