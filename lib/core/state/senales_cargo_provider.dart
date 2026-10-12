// Destino final: lib/core/state/senales_cargo_provider.dart
import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/data/repositories/senal_cargo_impl.dart';
import 'package:bosque_flutter/domain/entities/senal_cargo_entity.dart';
import 'package:bosque_flutter/domain/repositories/senal_cargo_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _mensaje(Object e) => mensajeError(e);

/// Cargos por revisar (archivo SQL 82). Qué es una señal y su motivo los
/// decide el servidor; aquí solo se agrupan por persona y se filtran.
class SenalesCargoState {
  final PanelDatos<SenalCargo> senales;

  /// RRHH puede ver también las marcadas "Está bien así".
  final bool verCalladas;

  /// Búsqueda por persona, cargo o sucursal.
  final String busqueda;

  /// Señales que están viajando, para no mandar dos veces.
  final Set<String> guardando;

  /// De un solo uso.
  final String? aviso;
  final String? mensajeError;

  const SenalesCargoState({
    this.senales = const PanelDatos<SenalCargo>(cargando: true),
    this.verCalladas = false,
    this.busqueda = '',
    this.guardando = const {},
    this.aviso,
    this.mensajeError,
  });

  /// Por persona: primero quien no hace ninguna de sus tareas, después quien
  /// deja más sin hacer.
  List<PersonaConSenales> get porPersona {
    final q = busqueda.trim().toLowerCase();
    final mapa = <int, List<SenalCargo>>{};
    for (final s in senales.filas) {
      if (q.isNotEmpty &&
          !'${s.persona} ${s.cargo ?? ''} ${s.nombreSucursal ?? ''}'
              .toLowerCase()
              .contains(q)) {
        continue;
      }
      mapa.putIfAbsent(s.codEmpleado, () => []).add(s);
    }
    final personas = [
      for (final l in mapa.values) PersonaConSenales(l.first, l),
    ];
    personas.sort((a, b) {
      if (a.ninguna != b.ninguna) return a.ninguna ? -1 : 1;
      final c = b.sinHacer.compareTo(a.sinHacer);
      return c != 0 ? c : a.persona.compareTo(b.persona);
    });
    return personas;
  }

  int get personas => senales.filas.map((s) => s.codEmpleado).toSet().length;
  int get tareas => senales.filas.where((s) => !s.callada).length;

  /// Cuántas ocurrencias seguidas mira el servidor (senalOcurrenciasSinHacer).
  int? get ocurrencias =>
      senales.filas.isEmpty ? null : senales.filas.first.ocurrencias;

  SenalesCargoState copyWith({
    PanelDatos<SenalCargo>? senales,
    bool? verCalladas,
    String? busqueda,
    Set<String>? guardando,
    String? aviso,
    String? mensajeError,
  }) => SenalesCargoState(
    senales: senales ?? this.senales,
    verCalladas: verCalladas ?? this.verCalladas,
    busqueda: busqueda ?? this.busqueda,
    guardando: guardando ?? this.guardando,
    aviso: aviso,
    mensajeError: mensajeError,
  );
}

class SenalesCargoNotifier extends StateNotifier<SenalesCargoState> {
  final SenalCargoRepository _repo;

  /// true: las del equipo de quien mira (Mi equipo); false: toda la empresa.
  final bool deMiEquipo;

  SenalesCargoNotifier(this._repo, {required this.deMiEquipo})
    : super(const SenalesCargoState()) {
    Future.microtask(cargar);
  }

  Future<void> cargar() async {
    state = state.copyWith(senales: state.senales.leyendo(limpiar: false));
    try {
      final filas =
          deMiEquipo
              ? await _repo.deMiEquipo()
              : await _repo.lista(verCalladas: state.verCalladas);
      if (mounted) {
        state = state.copyWith(
          senales: PanelDatos<SenalCargo>(filas: filas, cargado: true),
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(senales: PanelDatos<SenalCargo>(error: e));
      }
    }
  }

  Future<void> cambiarVerCalladas(bool ver) async {
    if (ver == state.verCalladas) return;
    state = state.copyWith(verCalladas: ver);
    await cargar();
  }

  void buscar(String texto) => state = state.copyWith(busqueda: texto);

  /// Devuelve el mensaje del servidor si no lo aceptó, para mostrarlo en el
  /// mismo diálogo sin perder lo escrito.
  Future<String?> estaBien(SenalCargo senal, {String? obs}) =>
      _escribir(senal, () => _repo.estaBien(senal, obs: obs));

  Future<String?> volverAMostrar(SenalCargo senal) =>
      _escribir(senal, () => _repo.volverAMostrar(senal));

  Future<String?> _escribir(
    SenalCargo senal,
    Future<String> Function() hacer,
  ) async {
    final clave = senal.clave;
    if (state.guardando.contains(clave)) return null;
    state = state.copyWith(guardando: {...state.guardando, clave});
    try {
      final mensaje = await hacer();
      if (!mounted) return null;
      await cargar();
      if (mounted) {
        state = state.copyWith(guardando: _sin(clave), aviso: mensaje);
      }
      return null;
    } catch (e) {
      if (mounted) state = state.copyWith(guardando: _sin(clave));
      return _mensaje(e);
    }
  }

  Set<String> _sin(String clave) => {...state.guardando}..remove(clave);
}

/// Se expone para poder reemplazarlo en las pruebas.
final senalCargoRepoProvider = Provider<SenalCargoRepository>(
  (ref) => SenalCargoImpl(),
);

/// `family`: true para Mi equipo, false para la pantalla de RRHH.
final senalesCargoProvider = StateNotifierProvider.autoDispose
    .family<SenalesCargoNotifier, SenalesCargoState, bool>(
      (ref, deMiEquipo) => SenalesCargoNotifier(
        ref.read(senalCargoRepoProvider),
        deMiEquipo: deMiEquipo,
      ),
    );
