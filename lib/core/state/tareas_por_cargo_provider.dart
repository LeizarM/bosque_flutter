import 'package:bosque_flutter/data/repositories/tareas_por_cargo_impl.dart';
import 'package:bosque_flutter/data/repositories/tar_ru_x_cargo_impl.dart';
import 'package:bosque_flutter/domain/entities/tar_ru_x_cargo_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TareasPorCargoState {
  final List<Map<String, dynamic>> items;
  final bool cargando;
  final bool guardando;
  final String? mensajeError;
  final String? mensajeExito;

  const TareasPorCargoState({
    this.items = const [],
    this.cargando = false,
    this.guardando = false,
    this.mensajeError,
    this.mensajeExito,
  });

  TareasPorCargoState copyWith({
    List<Map<String, dynamic>>? items,
    bool? cargando,
    bool? guardando,
    String? mensajeError,
    String? mensajeExito,
  }) => TareasPorCargoState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
    guardando: guardando ?? this.guardando,
    mensajeError: mensajeError,
    mensajeExito: mensajeExito,
  );
}

/// Reemplaza dlgTarFunXCargo de WizardEstOrg.java (solo lado Tareas
/// Rutinarias). Family por codCargo: cada cargo abierto desde el
/// organigrama tiene su propio estado, no uno compartido.
class TareasPorCargoNotifier extends StateNotifier<TareasPorCargoState> {
  final int codCargo;
  final TareasPorCargoImpl _repo;
  final TarRuXCargoImpl _tarRuXCargoRepo;

  TareasPorCargoNotifier(this.codCargo, this._repo, this._tarRuXCargoRepo)
    : super(const TareasPorCargoState()) {
    Future.microtask(() => cargar());
  }

  Future<void> cargar() async {
    state = state.copyWith(cargando: true);
    try {
      final data = await _repo.obtenerPorCargo(codCargo);
      state = state.copyWith(items: data, cargando: false);
    } catch (e) {
      state = state.copyWith(cargando: false, mensajeError: e.toString());
    }
  }

  /// "Agregar Tarea Rutinaria": crea la tarea y la asigna a ESTE cargo, en
  /// una sola transacción ACID (modo admin, sin restricción de subárbol —
  /// el backend lo fuerza server-side).
  Future<bool> crearTarea({
    required String descripcion,
    int? idFrec,
    int? idArea,
    required DateTime fechaPartida,
    int? idATR,
  }) async {
    state = state.copyWith(guardando: true);
    try {
      await _repo.registrarPorCargoAdmin(
        descripcion: descripcion,
        idFrec: idFrec,
        idArea: idArea,
        fechaPartida: fechaPartida,
        idATR: idATR,
        cargos: [
          {'codCargo': codCargo},
        ],
      );
      state = state.copyWith(
        guardando: false,
        mensajeExito: 'Tarea creada y asignada a este cargo.',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(
        guardando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// "Copiar": reusa una tarea existente (idTarRuti) para otros cargos con el
  /// mismo INSERT de p_abm_tac_TarRuXCargo ACCION='I', una llamada por cargo
  /// elegido. No necesita ser atómico: cada asignación es independiente.
  Future<bool> copiarACargos(int idTarRuti, List<int> codCargosDestino) async {
    state = state.copyWith(guardando: true);
    try {
      for (final destino in codCargosDestino) {
        await _tarRuXCargoRepo.registrar(
          TarRuXCargoEntity(
            idTarXCargo: 0,
            idTarRuti: idTarRuti,
            codCargo: destino,
            estado: 1,
            audUsuario: 0, // el backend lo resuelve del JWT, esto no viaja
          ),
        );
      }
      state = state.copyWith(
        guardando: false,
        mensajeExito: 'Tarea copiada a ${codCargosDestino.length} cargo(s).',
      );
      await cargar();
      return true;
    } catch (e) {
      state = state.copyWith(
        guardando: false,
        mensajeError: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Engancha a ESTE cargo tareas que ya existen (contraparte de [copiarACargos];
  /// ambas terminan en `p_abm_tac_TarRuXCargo ACCION='I'`). A diferencia de
  /// aquélla no se corta en el primer error: el selector ya oculta las que el
  /// cargo tiene, así que un fallo es una carrera (alguien la asignó con el
  /// diálogo abierto) y no debe impedir agregar las demás. Se avisa lo que no entró.
  Future<bool> asignarExistentes(
    List<int> idTarRutis, {
    DateTime? desde,
  }) async {
    state = state.copyWith(guardando: true);
    var puestas = 0;
    final fallidas = <String>[];

    for (final idTarRuti in idTarRutis) {
      try {
        await _tarRuXCargoRepo.registrar(
          TarRuXCargoEntity(
            idTarXCargo: 0,
            idTarRuti: idTarRuti,
            codCargo: codCargo,
            estado: 1,
            // Si quien asigna eligió fecha, se manda; con [desde] null el SP usa
            // CAST(GETDATE() AS DATE) (reloj del SERVIDOR, no del teléfono: correcto para
            // "hoy" cerca de medianoche).
            fechaInicio: desde,
            audUsuario: 0, // lo resuelve el backend desde el JWT
          ),
        );
        puestas++;
      } catch (e) {
        fallidas.add('$idTarRuti');
      }
    }

    await cargar();

    if (fallidas.isEmpty) {
      state = state.copyWith(
        guardando: false,
        mensajeExito:
            puestas == 1
                ? 'Tarea agregada al cargo.'
                : '$puestas tareas agregadas al cargo.',
      );
      return true;
    }

    state = state.copyWith(
      guardando: false,
      mensajeError:
          'Se agregaron $puestas de ${idTarRutis.length}. '
          'No se pudo con: ${fallidas.join(', ')}.',
    );
    return puestas > 0;
  }

  /// Toggle "Estado" inline — misma fila, solo cambia estado.
  Future<bool> toggleEstado(Map<String, dynamic> fila) async {
    state = state.copyWith(guardando: true);
    try {
      final estadoActual = (fila['estado'] as num?)?.toInt() ?? 1;
      await _tarRuXCargoRepo.registrar(
        TarRuXCargoEntity(
          idTarXCargo: (fila['idTarXCargo'] as num).toInt(),
          idTarRuti: (fila['idTarRuti'] as num?)?.toInt(),
          codCargo: (fila['codCargo'] as num?)?.toInt(),
          estado: estadoActual == 1 ? 0 : 1,
          codCargoSucursal: (fila['codCargoSucursal'] as num?)?.toInt(),
          fechaInicio:
              fila['fechaInicio'] != null
                  ? DateTime.tryParse(fila['fechaInicio'].toString())
                  : null,
          fechaFin:
              fila['fechaFin'] != null
                  ? DateTime.tryParse(fila['fechaFin'].toString())
                  : null,
          audUsuario: 0,
        ),
      );
      state = state.copyWith(
        guardando: false,
        mensajeExito: 'Estado actualizado.',
      );
      await cargar();
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

final _tareasPorCargoRepoProvider = Provider((ref) => TareasPorCargoImpl());
final _tarRuXCargoRepoParaCopiarProvider = Provider((ref) => TarRuXCargoImpl());

final tareasRutinariasPorCargoProvider = StateNotifierProvider.autoDispose
    .family<TareasPorCargoNotifier, TareasPorCargoState, int>((ref, codCargo) {
      return TareasPorCargoNotifier(
        codCargo,
        ref.read(_tareasPorCargoRepoProvider),
        ref.read(_tarRuXCargoRepoParaCopiarProvider),
      );
    });
