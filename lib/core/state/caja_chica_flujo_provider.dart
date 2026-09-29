// Destino final: lib/core/state/caja_chica_flujo_provider.dart
import 'package:bosque_flutter/data/repositories/caja_chica_flujo_impl.dart';
import 'package:bosque_flutter/domain/entities/caja_chica_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// codSucursal ya NO viaja aquí — el proc lo resuelve server-side del cargo
// vigente del empleado dueño de la ocurrencia (code-review, 2026-09-03).
typedef CajaChicaParams = ({int idBitTarea});

// Marca de "no cambiar" para poder limpiar `errorCarga` pasándole null.
const _igual = Object();

class CajaChicaFlujoState {
  final List<CajaChicaEntity> items;
  final bool cargando;

  /// Si alguna lectura terminó bien. Sin esto, una lectura fallida se veía
  /// como "Todavía no hay movimientos en este lote" con "Finalizar"
  /// habilitado (auditoría del 2026-09-11).
  final bool cargado;

  /// Por qué falló la última lectura; queda hasta la próxima buena.
  final Object? errorCarga;
  final bool guardando;
  final bool finalizando;
  final bool cerrandoLote;
  final String? mensajeError;
  final bool finalizado;

  const CajaChicaFlujoState({
    this.items = const [],
    this.cargando = false,
    this.cargado = false,
    this.errorCarga,
    this.guardando = false,
    this.finalizando = false,
    this.cerrandoLote = false,
    this.mensajeError,
    this.finalizado = false,
  });

  CajaChicaFlujoState copyWith({
    List<CajaChicaEntity>? items,
    bool? cargando,
    bool? cargado,
    Object? errorCarga = _igual,
    bool? guardando,
    bool? finalizando,
    bool? cerrandoLote,
    String? mensajeError,
    bool? finalizado,
  }) => CajaChicaFlujoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    cargado: cargado ?? this.cargado,
    errorCarga: identical(errorCarga, _igual) ? this.errorCarga : errorCarga,
    guardando: guardando ?? this.guardando,
    finalizando: finalizando ?? this.finalizando,
    cerrandoLote: cerrandoLote ?? this.cerrandoLote,
    mensajeError: mensajeError,
    finalizado: finalizado ?? this.finalizado,
  );

  double get saldoActual => items.isEmpty ? 0 : (items.last.saldo ?? 0);

  /// Con qué monto abrió el lote — la primera fila, la que siembra
  /// `p_list_tac_CajaChica` ACCION='D' como "Saldo inicial del lote".
  double get saldoInicial => items.isEmpty ? 0 : (items.first.montoIng ?? 0);

  /// Lo gastado en el lote. Se suma de las filas y no se despeja como
  /// `inicial - actual`: si algún día entra una reposición como `montoIng` en
  /// medio del lote, esa resta daría un egreso menor al real; la suma sigue
  /// diciendo la verdad.
  double get totalEgresos =>
      items.fold<double>(0, (a, f) => a + (f.montoEg ?? 0));

  /// Movimientos reales, sin contar la fila sembrada de saldo inicial.
  int get cantidadEgresos => items.where((f) => (f.montoEg ?? 0) > 0).length;
}

class CajaChicaFlujoNotifier extends StateNotifier<CajaChicaFlujoState> {
  final CajaChicaFlujoImpl _repo;
  final CajaChicaParams _params;

  CajaChicaFlujoNotifier(this._repo, this._params)
    // Arranca cargando: en reposo, el primer cuadro se vería como un error.
    : super(const CajaChicaFlujoState(cargando: true)) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final items = await _repo.listarDelLote(idBitTarea: _params.idBitTarea);
      if (!mounted) return;
      state = state.copyWith(
        cargando: false,
        cargado: true,
        errorCarga: null,
        items: items,
      );
    } catch (e) {
      if (!mounted) return;
      // Con el libro ya en pantalla se queda y se avisa; en la primera
      // lectura la pantalla muestra el error en su lugar.
      state = state.copyWith(
        cargando: false,
        errorCarga: e,
        mensajeError: state.cargado ? e.toString() : null,
      );
    }
  }

  Future<bool> registrarEgreso({
    required double montoEg,
    required String descripcion,
    required int codEmpDestino,
    int? numFactura,
    int? numVale,
  }) async {
    state = state.copyWith(guardando: true);
    try {
      await _repo.registrarEgreso(
        idBitTarea: _params.idBitTarea,
        montoEg: montoEg,
        descripcion: descripcion,
        codEmpDestino: codEmpDestino,
        numFactura: numFactura,
        numVale: numVale,
      );
      state = state.copyWith(guardando: false);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(guardando: false, mensajeError: e.toString());
      return false;
    }
  }

  Future<void> finalizar() async {
    state = state.copyWith(finalizando: true);
    try {
      await _repo.finalizar(_params.idBitTarea);
      state = state.copyWith(finalizando: false, finalizado: true);
    } catch (e) {
      state = state.copyWith(finalizando: false, mensajeError: e.toString());
    }
  }

  /// Cierra el lote vigente y abre uno nuevo (con su saldo inicial ya
  /// sembrado). A diferencia de [finalizar], no marca la tarea como
  /// completada — recarga el lote (ahora el nuevo) para que la pantalla
  /// siga mostrando algo útil. Devuelve `true` si se pudo cerrar; el error,
  /// si lo hay, ya queda en [CajaChicaFlujoState.mensajeError] para el
  /// listener de la pantalla.
  Future<bool> cerrarLote() async {
    state = state.copyWith(cerrandoLote: true);
    try {
      await _repo.cerrarLote(_params.idBitTarea);
      state = state.copyWith(cerrandoLote: false);
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(cerrandoLote: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _cajaChicaFlujoRepoProvider = Provider((ref) => CajaChicaFlujoImpl());

final cajaChicaFlujoProvider = StateNotifierProvider.autoDispose.family<
  CajaChicaFlujoNotifier,
  CajaChicaFlujoState,
  CajaChicaParams
>((ref, params) {
  return CajaChicaFlujoNotifier(ref.read(_cajaChicaFlujoRepoProvider), params);
});
