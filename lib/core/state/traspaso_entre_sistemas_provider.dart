// Destino final: lib/core/state/traspaso_entre_sistemas_provider.dart
import 'package:bosque_flutter/data/repositories/traspaso_mov_caja_impl.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de la tarea 295, "Verificar traspaso Caja AXA contra movimiento de
/// caja" (idATR 12). El nombre del archivo es de cuando se creyó que era la
/// 289; la 289 es TesBase y vive en `traspaso_efectivo_tesbase_provider.dart`.
///
/// El cajero compara el formulario manual de Caja AXA contra lo que quedó en
/// el movimiento de caja del sistema, fila por fila. La lista NO sale de la
/// base de Bosque: el servidor le pregunta a SAP y cruza contra lo que ya se
/// verificó, así que cargar puede tardar y puede fallar.
class TraspasoEntreSistemasState {
  final List<TraspasoMovCajaEntity> filas;
  final DateTime fecha;
  final bool cargando;

  /// Si la última lectura de la fecha terminó bien.
  ///
  /// Sin esto, una lectura fallida dejaba `filas` vacía y la pantalla mostraba
  /// "No hubo traspasos" con el botón "Sin novedad": exactamente la confusión
  /// entre "no pude preguntarle a SAP" y "SAP dice que no hubo nada" que este
  /// estado existe para evitar. Se vio en una captura de la pantalla con un
  /// error de lectura (2026-09-11).
  final bool cargado;

  /// Mientras una fila viaja, para que dos toques no manden dos escrituras.
  /// Es el `idTrasp`, o `-1` cuando la fila todavía no tiene id (aún no se
  /// guardó nunca) y se la identifica por su posición.
  final int? guardando;

  final String? error;

  /// Mensaje para mostrar una sola vez y limpiar.
  final String? aviso;

  const TraspasoEntreSistemasState({
    required this.fecha,
    this.filas = const [],
    this.cargando = false,
    this.cargado = false,
    this.guardando,
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
    int? guardando,
    bool limpiarGuardando = false,
    String? error,
    String? aviso,
  }) {
    return TraspasoEntreSistemasState(
      filas: filas ?? this.filas,
      fecha: fecha ?? this.fecha,
      cargando: cargando ?? this.cargando,
      cargado: cargado ?? this.cargado,
      guardando: limpiarGuardando ? null : (guardando ?? this.guardando),
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
    // Arranca cargando: si arrancara en reposo, el primer cuadro —antes de que
    // corra la lectura— se vería como un error de lectura.
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
      // a SAP" y "SAP dice que no hubo nada" llevan a acciones opuestas, y una
      // de ellas habilita el botón de "Sin novedad".
      state = state.copyWith(
        cargando: false,
        cargado: false,
        filas: const [],
        error: 'No se pudo leer los traspasos del sistema. $e',
      );
    }
  }

  Future<void> cambiarFecha(DateTime fecha) async {
    state = state.copyWith(fecha: fecha, filas: const [], cargado: false);
    await cargar();
  }

  /// Marca una fila. [obs] es obligatoria cuando no cuadra; el servidor
  /// también lo exige, esto solo evita el viaje.
  Future<bool> verificar({
    required int idBitTarea,
    required TraspasoMovCajaEntity fila,
    required bool cuadra,
    String? obs,
  }) async {
    if (!cuadra && (obs == null || obs.trim().isEmpty)) {
      state = state.copyWith(
        error: 'Escribe qué fue lo que no cuadró antes de guardar.',
      );
      return false;
    }

    state = state.copyWith(guardando: fila.idTrasp);
    try {
      await _repo.verificar(
        idBitTarRuti: idBitTarea,
        fila: fila,
        cuadra: cuadra,
        obs: obs,
      );
      // Se recarga en vez de parchear en memoria: la fila puede haber nacido
      // recién en el servidor y necesita su idTrasp para el próximo cambio.
      await cargar();
      state = state.copyWith(
        limpiarGuardando: true,
        aviso:
            cuadra
                ? 'Traspaso verificado.'
                : 'Traspaso marcado como que no cuadra.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(limpiarGuardando: true, error: '$e');
      return false;
    }
  }

  /// Cierra el día cuando no hubo ningún traspaso.
  Future<bool> sinNovedad(int idBitTarea) async {
    state = state.copyWith(cargando: true);
    try {
      await _repo.sinNovedad(idBitTarRuti: idBitTarea, fecha: state.fecha);
      state = state.copyWith(
        cargando: false,
        aviso: 'Día cerrado como sin novedad.',
      );
      return true;
    } catch (e) {
      // Llega aquí también cuando el servidor rechaza porque SÍ hay
      // traspasos (error 24). Es el caso que importa: alguien intentó cerrar
      // sin mirar, o la pantalla quedó vieja.
      state = state.copyWith(cargando: false, error: '$e');
      return false;
    }
  }

  void limpiarMensajes() {
    state = state.copyWith(limpiarGuardando: true);
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
