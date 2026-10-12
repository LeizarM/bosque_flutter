import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/data/repositories/traspaso_mov_caja_impl.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de la tarea 295, "Verificar traspaso Caja AXA contra movimiento de
/// caja" (idATR 12). El nombre del archivo viene de cuando se creyó que era la
/// 289 (TesBase, en `traspaso_efectivo_tesbase_provider.dart`).
///
/// La lista NO sale de la base de Bosque: el servidor consulta SAP y cruza
/// contra lo ya verificado, así que cargar puede tardar o fallar.
class TraspasoEntreSistemasState {
  final List<TraspasoMovCajaEntity> filas;
  final DateTime fecha;
  final bool cargando;

  /// Si la última lectura de la fecha terminó bien. Sin esto, una lectura
  /// fallida dejaba `filas` vacía y la pantalla mostraba "No hubo traspasos"
  /// con el botón "Sin novedad", confundiendo "no pude preguntarle a SAP" con
  /// "SAP dice que no hubo nada".
  final bool cargado;

  /// Las filas que viajan (`idTrasp`), para que dos toques no manden dos
  /// escrituras. Un conjunto: terminar una fila no libera a otra que sigue.
  final Set<int> guardando;

  final String? error;

  /// Mensaje para mostrar una sola vez y limpiar.
  final String? aviso;

  const TraspasoEntreSistemasState({
    required this.fecha,
    this.filas = const [],
    this.cargando = false,
    this.cargado = false,
    this.guardando = const {},
    this.error,
    this.aviso,
  });

  /// Lo que falta responder. Es lo que decide si se puede cerrar el día.
  int get sinResponder => filas.where((f) => f.fueVerificado == null).length;

  /// `true` cuando SAP respondió y no devolvió nada para la fecha: el caso del
  /// botón "Sin novedad". Una lectura fallida NO es un día vacío.
  bool get diaVacio => cargado && filas.isEmpty;

  TraspasoEntreSistemasState copyWith({
    List<TraspasoMovCajaEntity>? filas,
    DateTime? fecha,
    bool? cargando,
    bool? cargado,
    Set<int>? guardando,
    String? error,
    String? aviso,
  }) {
    return TraspasoEntreSistemasState(
      filas: filas ?? this.filas,
      fecha: fecha ?? this.fecha,
      cargando: cargando ?? this.cargando,
      cargado: cargado ?? this.cargado,
      guardando: guardando ?? this.guardando,
      // error y aviso NO se arrastran: son de un solo uso. Si se propagaran
      // con `?? this.x`, un error viejo reaparecería en cada recarga.
      error: error,
      aviso: aviso,
    );
  }
}

class TraspasoEntreSistemasNotifier
    extends StateNotifier<TraspasoEntreSistemasState> {
  final TraspasoMovCajaImpl _repo;

  TraspasoEntreSistemasNotifier(this._repo, DateTime fecha)
    // Arranca cargando: en reposo, el primer cuadro se vería como un error de lectura.
    : super(TraspasoEntreSistemasState(fecha: fecha, cargando: true)) {
    Future.microtask(cargar);
  }

  Future<void> cargar() async {
    final fecha = state.fecha;
    state = state.copyWith(cargando: true);
    try {
      final filas = await _repo.obtenerDelDia(fecha);
      if (!mounted || state.fecha != fecha) return;
      state = state.copyWith(filas: filas, cargando: false, cargado: true);
    } catch (e) {
      if (!mounted || state.fecha != fecha) return;
      // Se deja el error a la vista y `cargado` en false: "no pude preguntarle
      // a SAP" y "SAP dice que no hubo nada" llevan a acciones opuestas.
      state = state.copyWith(
        cargando: false,
        cargado: false,
        filas: const [],
        error: 'No se pudo leer los traspasos del sistema. ${mensajeError(e)}',
      );
    }
  }

  Future<void> cambiarFecha(DateTime fecha) async {
    state = state.copyWith(fecha: fecha, filas: const [], cargado: false);
    await cargar();
  }

  /// Marca una fila. Que [obs] sea obligatoria cuando no cuadra lo exige el
  /// servidor (error 23 de p_abm_tac_TraspasoMovCaja 'V'), no la app: las
  /// reglas de registro van en SQL.
  Future<bool> verificar({
    required int idBitTarea,
    required TraspasoMovCajaEntity fila,
    required bool cuadra,
    String? obs,
  }) async {
    final id = fila.idTrasp;
    state = state.copyWith(guardando: {...state.guardando, id});
    try {
      await _repo.verificar(
        idBitTarRuti: idBitTarea,
        fila: fila,
        cuadra: cuadra,
        obs: obs,
      );
      if (!mounted) return true;
      // Se recarga en vez de parchear en memoria: la fila puede haber nacido
      // recién en el servidor y necesita su idTrasp para el próximo cambio.
      await cargar();
      if (!mounted) return true;
      state = state.copyWith(
        guardando: {...state.guardando}..remove(id),
        aviso:
            cuadra
                ? 'Traspaso verificado.'
                : 'Traspaso marcado como que no cuadra.',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        guardando: {...state.guardando}..remove(id),
        error: mensajeError(e),
      );
      return false;
    }
  }

  /// Cierra el día cuando no hubo ningún traspaso.
  Future<bool> sinNovedad(int idBitTarea) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.sinNovedad(idBitTarRuti: idBitTarea, fecha: state.fecha);
      if (!mounted) return true;
      state = state.copyWith(
        cargando: false,
        aviso: 'Día cerrado como sin novedad.',
      );
      return true;
    } catch (e) {
      // Llega aquí también si el servidor rechaza porque SÍ hay traspasos
      // (error 24): alguien intentó cerrar sin mirar, o la pantalla quedó vieja.
      if (!mounted) return false;
      state = state.copyWith(cargando: false, error: mensajeError(e));
      return false;
    }
  }

  // error y aviso no se arrastran en copyWith: copiar el estado los limpia.
  void limpiarMensajes() {
    state = state.copyWith();
  }
}

final _traspasoEntreSistemasRepoProvider = Provider(
  (ref) => TraspasoMovCajaImpl(),
);

/// `family` por fecha inicial: cada apertura de la tarea arranca en el día de
/// su ocurrencia, no en "hoy".
final traspasoEntreSistemasProvider = StateNotifierProvider.autoDispose
    .family<
      TraspasoEntreSistemasNotifier,
      TraspasoEntreSistemasState,
      DateTime
    >(
      (ref, fecha) => TraspasoEntreSistemasNotifier(
        ref.watch(_traspasoEntreSistemasRepoProvider),
        fecha,
      ),
    );
