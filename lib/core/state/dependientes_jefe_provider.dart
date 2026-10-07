import 'package:bosque_flutter/data/repositories/dependientes_jefe_impl.dart';
import 'package:bosque_flutter/domain/entities/dependiente_cargo_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Marca de "no cambiar" para poder limpiar `errorCarga` pasándole null.
const _igual = Object();

class DependientesJefeState {
  final List<DependienteCargoEntity> dependientes;
  final bool cargando;

  /// Si alguna lectura terminó bien. Sin esto, una lectura fallida se veía como
  /// "No hay cargos para este filtro".
  final bool cargado;

  /// Por qué falló la última lectura; queda hasta la próxima buena.
  final Object? errorCarga;
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
    this.cargado = false,
    this.errorCarga,
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
    bool? cargado,
    Object? errorCarga = _igual,
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
    cargado: cargado ?? this.cargado,
    errorCarga: identical(errorCarga, _igual) ? this.errorCarga : errorCarga,
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

  DependientesJefeNotifier(this._repo)
    // Arranca cargando: en reposo, el primer cuadro se vería como un error.
    : super(const DependientesJefeState(cargando: true)) {
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
        cargado: true,
        errorCarga: null,
      );
    } catch (e) {
      // Sin aviso flotante: la pantalla muestra el error en su lugar.
      state = state.copyWith(
        cargando: false,
        cargado: false,
        errorCarga: e,
        dependientes: const [],
      );
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

  List<DependienteCargoEntity> get dependientesSeleccionados =>
      state.dependientes
          .where((d) => state.seleccionados.contains(d.claveSeleccion))
          .toList();

  /// Descripción, frecuencia, al menos un dependiente y el orden de las
  /// fechas los valida p_registrar_tac_tareaRutinariaConCargos (errores 10,
  /// 11, 13 y 18): las reglas de registro van en SQL.
  Future<bool> registrarTarea({
    required String descripcion,
    int? idFrec,
    int? idArea,
    required DateTime fechaPartida,
    int? idATR,
    DateTime? fechaInicioAsignacion,
    DateTime? fechaFinAsignacion,
  }) async {
    state = state.copyWith(guardando: true);
    try {
      final cargos =
          dependientesSeleccionados
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
      state = state.copyWith(
        guardando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final _dependientesJefeRepoProvider = Provider((ref) => DependientesJefeImpl());

final dependientesJefeProvider = StateNotifierProvider.autoDispose<
  DependientesJefeNotifier,
  DependientesJefeState
>((ref) => DependientesJefeNotifier(ref.read(_dependientesJefeRepoProvider)));

/// Si quien entró puede programar tareas a su equipo: su cargo vigente tiene
/// codNivel <= nivelMaximoJefe (tac_configuracion, hoy 3); decide si "Mis tareas
/// rutinarias" muestra el botón "Mi equipo". La regla no se copia aquí: se
/// pregunta al mismo procedimiento que la pantalla, pidiendo lo mínimo (solo
/// directos, su sucursal). Ante cualquier falla, falso: el botón no aparece y la
/// pantalla igual valida en el servidor.
final puedeProgramarAMiEquipoProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  try {
    final resultado = await ref
        .read(_dependientesJefeRepoProvider)
        .listarDependientes(profundidad: 'D', alcanceSucursal: 'M');
    return resultado.autorizado;
  } catch (_) {
    return false;
  }
});
