import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Traspaso de tareas rutinarias cuando a alguien le cambian el cargo.
///
/// El generador toma SOLO el cargo más reciente del empleado
/// (`WHERE ec.fechaInicio = MAX(fechaInicio)`), así que el día que RR.HH.
/// carga el cargo nuevo la persona deja de recibir las tareas del anterior y
/// nadie se entera. Medido contra la base: 26 empleados con un traspaso
/// posible y 192 decisiones pendientes.
///
/// Lo que se decide aquí es a nivel CARGO, no persona: copiar una tarea al
/// cargo destino se la asigna a TODA la gente de ese cargo. Por eso la fila
/// trae [personasEnCargoNuevo] — la pantalla tiene que decir a cuántos les va
/// a caer antes de que alguien toque "Copiar".
class TraspasoRepo extends BaseApiRepository {
  Future<List<Map<String, dynamic>>> pendientes({DateTime? desde}) {
    return postAndReturnList<Map<String, dynamic>>(
      endpoint: AppConstants.tarTraspasosPendientes,
      // Mapa vacío y no null: sin `desde` el backend deja que el proc use su
      // default (90 días), pero postAndReturnList necesita un body igual.
      data:
          desde == null
              ? const <String, dynamic>{}
              : {
                'desde':
                    '${desde.year.toString().padLeft(4, '0')}-'
                    '${desde.month.toString().padLeft(2, '0')}-'
                    '${desde.day.toString().padLeft(2, '0')}',
              },
      fromJson: (json) => json,
    );
  }

  Future<void> traspasar({
    required int idTarRuti,
    required int codCargoDestino,
  }) async {
    await postAndReturnId(
      endpoint: AppConstants.tarTraspasarTarea,
      data: {'idTarRuti': idTarRuti, 'codCargoDestino': codCargoDestino},
    );
  }
}

/// Un empleado que cambió de cargo, con las tareas que su cargo anterior tenía.
class Traspaso {
  final int codEmpleado;
  final String nombreEmpleado;
  final DateTime? fechaCambio;
  final String cargoAnterior;
  final String cargoNuevo;
  final int codCargoNuevo;
  final int personasEnCargoNuevo;
  final List<TareaDeTraspaso> tareas;

  const Traspaso({
    required this.codEmpleado,
    required this.nombreEmpleado,
    required this.fechaCambio,
    required this.cargoAnterior,
    required this.cargoNuevo,
    required this.codCargoNuevo,
    required this.personasEnCargoNuevo,
    required this.tareas,
  });

  /// Las que hay que decidir. Las que el cargo nuevo ya tiene se muestran
  /// igual (para que se vea qué SÍ sobrevivió al cambio) pero no cuentan como
  /// pendientes.
  int get porDecidir => tareas.where((t) => !t.yaEstaEnCargoNuevo).length;
}

class TareaDeTraspaso {
  final int idTarRuti;
  final String descripcion;
  final String? frecuencia;
  final bool yaEstaEnCargoNuevo;

  const TareaDeTraspaso({
    required this.idTarRuti,
    required this.descripcion,
    required this.frecuencia,
    required this.yaEstaEnCargoNuevo,
  });
}

class TraspasosState {
  final List<Traspaso> items;
  final bool cargando;
  final String? mensajeError;

  /// idTarRuti que se está copiando ahora mismo, para dejar inerte ese botón.
  final int? copiando;

  const TraspasosState({
    this.items = const [],
    this.cargando = false,
    this.mensajeError,
    this.copiando,
  });

  TraspasosState copyWith({
    List<Traspaso>? items,
    bool? cargando,
    String? mensajeError,
    int? copiando,
    bool limpiarCopiando = false,
  }) => TraspasosState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    mensajeError: mensajeError,
    copiando: limpiarCopiando ? null : (copiando ?? this.copiando),
  );
}

class TraspasosNotifier extends StateNotifier<TraspasosState> {
  final TraspasoRepo _repo;

  TraspasosNotifier(this._repo) : super(const TraspasosState()) {
    cargar();
  }

  /// Ventana de búsqueda en días. 90 es el default del proc; se sube a 365
  /// desde la pantalla porque los cambios de cargo son pocos y espaciados
  /// (41 en el último año, 2 en los últimos 90 días).
  int dias = 365;

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final filas = await _repo.pendientes(
        desde: DateTime.now().subtract(Duration(days: dias)),
      );
      state = state.copyWith(cargando: false, items: _agrupar(filas));
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  /// El proc devuelve una fila por (empleado × tarea) para no obligar a ir y
  /// volver por cada empleado. Aquí se agrupa para la pantalla.
  List<Traspaso> _agrupar(List<Map<String, dynamic>> filas) {
    final porEmpleado = <int, List<Map<String, dynamic>>>{};
    for (final f in filas) {
      final cod = (f['codEmpleado'] as num?)?.toInt();
      if (cod == null) continue;
      porEmpleado.putIfAbsent(cod, () => []).add(f);
    }

    return porEmpleado.entries.map((e) {
        final primera = e.value.first;
        return Traspaso(
          codEmpleado: e.key,
          nombreEmpleado: (primera['nombreEmpleado'] as String?)?.trim() ?? '—',
          fechaCambio: DateTime.tryParse('${primera['fechaCambio']}'),
          cargoAnterior:
              (primera['descripCargoAnterior'] as String?)?.trim() ?? '—',
          cargoNuevo: (primera['descripCargoNuevo'] as String?)?.trim() ?? '—',
          codCargoNuevo: (primera['codCargoNuevo'] as num?)?.toInt() ?? 0,
          personasEnCargoNuevo:
              (primera['personasEnCargoNuevo'] as num?)?.toInt() ?? 0,
          tareas:
              e.value
                  .map(
                    (f) => TareaDeTraspaso(
                      idTarRuti: (f['idTarRuti'] as num?)?.toInt() ?? 0,
                      descripcion:
                          (f['descripcionTarea'] as String?)?.trim() ?? '—',
                      frecuencia:
                          (f['descripcionFrecuencia'] as String?)?.trim(),
                      yaEstaEnCargoNuevo:
                          ((f['yaEstaEnCargoNuevo'] as num?)?.toInt() ?? 0) ==
                          1,
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.descripcion.compareTo(b.descripcion)),
        );
      }).toList()
      ..sort((a, b) {
        final fa = a.fechaCambio ?? DateTime(1900);
        final fb = b.fechaCambio ?? DateTime(1900);
        return fb.compareTo(fa);
      });
  }

  /// Copia una tarea al cargo nuevo.
  ///
  /// No revalida nada de su lado a propósito — las tres guardas están del lado
  /// del servidor, que es el único que puede sostenerlas: el proc rechaza los
  /// cargos sin gente activa (error 24) y no duplica si ya la tiene, y el
  /// endpoint verifica contra la lista viva que el traspaso siga vigente
  /// (409 si la persona volvió a cambiar de cargo mientras la pantalla estaba
  /// abierta). Aquí alcanza con recargar y mostrar lo que responda.
  Future<bool> traspasar({
    required int idTarRuti,
    required int codCargoDestino,
  }) async {
    if (state.copiando != null) return false;
    state = state.copyWith(copiando: idTarRuti);
    try {
      await _repo.traspasar(
        idTarRuti: idTarRuti,
        codCargoDestino: codCargoDestino,
      );
      await cargar();
      state = state.copyWith(limpiarCopiando: true);
      return true;
    } catch (e) {
      state = state.copyWith(limpiarCopiando: true, mensajeError: e.toString());
      return false;
    }
  }
}

final _traspasoRepoProvider = Provider((ref) => TraspasoRepo());

final traspasosProvider =
    StateNotifierProvider.autoDispose<TraspasosNotifier, TraspasosState>(
      (ref) => TraspasosNotifier(ref.watch(_traspasoRepoProvider)),
    );
