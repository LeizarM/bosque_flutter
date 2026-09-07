// Destino final: lib/core/state/dependientes_jefe_provider.dart
import 'package:bosque_flutter/data/repositories/dependientes_jefe_impl.dart';
import 'package:bosque_flutter/domain/entities/dependiente_cargo_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DependientesJefeState {
  final List<DependienteCargoEntity> dependientes;
  final bool cargando;
  final bool guardando;
  final bool autorizado;
  final String? mensajeInfo; // motivo de no-autorizado, o vacío al lista
  final String? mensajeError;
  final String? mensajeExito;
  final String profundidad; // 'T' | 'D'
  final String alcanceSucursal; // 'A' | 'M'
  final Set<String> seleccionados; // claveSeleccion de DependienteCargoEntity

  const DependientesJefeState({
    this.dependientes = const [],
    this.cargando = false,
    this.guardando = false,
    this.autorizado = true,
    this.mensajeInfo,
    this.mensajeError,
    this.mensajeExito,
    this.profundidad = 'T',
    this.alcanceSucursal = 'A',
    this.seleccionados = const {},
  });

  DependientesJefeState copyWith({
    List<DependienteCargoEntity>? dependientes,
    bool? cargando,
    bool? guardando,
    bool? autorizado,
    String? mensajeInfo,
    String? mensajeError,
    String? mensajeExito,
    String? profundidad,
    String? alcanceSucursal,
    Set<String>? seleccionados,
  }) => DependientesJefeState(
    dependientes: dependientes ?? this.dependientes,
    cargando: cargando ?? this.cargando,
    guardando: guardando ?? this.guardando,
    autorizado: autorizado ?? this.autorizado,
    mensajeInfo: mensajeInfo,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
    profundidad: profundidad ?? this.profundidad,
    alcanceSucursal: alcanceSucursal ?? this.alcanceSucursal,
    seleccionados: seleccionados ?? this.seleccionados,
  );
}

class DependientesJefeNotifier extends StateNotifier<DependientesJefeState> {
  final DependientesJefeImpl _repo;

  DependientesJefeNotifier(this._repo) : super(const DependientesJefeState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true, seleccionados: {});
    try {
      final resultado = await _repo.listarDependientes(
        profundidad: state.profundidad,
        alcanceSucursal: state.alcanceSucursal,
      );
      state = state.copyWith(
        cargando: false,
        autorizado: resultado.autorizado,
        dependientes: resultado.dependientes,
        mensajeInfo: resultado.autorizado ? null : resultado.mensaje,
      );
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  void cambiarProfundidad(String p) {
    state = state.copyWith(profundidad: p);
    cargar();
  }

  void cambiarAlcanceSucursal(String a) {
    state = state.copyWith(alcanceSucursal: a);
    cargar();
  }

  void alternarSeleccion(String claveSeleccion) {
    final nuevos = Set<String>.from(state.seleccionados);
    if (!nuevos.remove(claveSeleccion)) nuevos.add(claveSeleccion);
    state = state.copyWith(seleccionados: nuevos);
  }

  List<DependienteCargoEntity> get dependientesSeleccionados => state
      .dependientes
      .where((d) => state.seleccionados.contains(d.claveSeleccion))
      .toList();

  Future<bool> registrarTarea({
    required String descripcion,
    required int idFrec,
    int? idArea,
    required DateTime fechaPartida,
    int? idATR,
    DateTime? fechaInicioAsignacion,
    DateTime? fechaFinAsignacion,
  }) async {
    if (state.seleccionados.isEmpty) {
      state = state.copyWith(mensajeError: 'Elige al menos un dependiente.');
      return false;
    }
    state = state.copyWith(guardando: true);
    try {
      final cargos = dependientesSeleccionados
          .map(
            (d) => {
              'codCargo': d.codCargo,
              'codCargoSucursal': d.codCargoSucursal,
              'fechaInicio': fechaInicioAsignacion?.toIso8601String(),
              'fechaFin': fechaFinAsignacion?.toIso8601String(),
            },
          )
          .toList();

      await _repo.registrarTareaConCargos(
        descripcion: descripcion,
        idFrec: idFrec,
        idArea: idArea,
        fechaPartida: fechaPartida,
        idATR: idATR,
        cargos: cargos,
      );

      state = state.copyWith(
        guardando: false,
        mensajeExito:
            'Tarea creada y asignada a ${cargos.length} dependiente(s).',
        seleccionados: {},
      );
      return true;
    } catch (e) {
      state = state.copyWith(guardando: false, mensajeError: e.toString());
      return false;
    }
  }
}

final _dependientesJefeRepoProvider = Provider(
  (ref) => DependientesJefeImpl(),
);

final dependientesJefeProvider = StateNotifierProvider.autoDispose<
  DependientesJefeNotifier,
  DependientesJefeState
>((ref) => DependientesJefeNotifier(ref.read(_dependientesJefeRepoProvider)));
