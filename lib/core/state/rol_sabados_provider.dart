import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/rol_sabados_impl.dart';
import 'package:bosque_flutter/domain/entities/automatizacion_entity.dart';
import 'package:bosque_flutter/domain/entities/cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/convocatoria_entity.dart';
import 'package:bosque_flutter/domain/entities/cumple_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/excusa_horario_entity.dart';
import 'package:bosque_flutter/domain/entities/intervencion_entity.dart';
import 'package:bosque_flutter/domain/entities/mi_equipo_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/permiso_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/programacion_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_entity.dart';
import 'package:bosque_flutter/domain/entities/puente_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/rrhh_sabados_entity.dart';
import 'package:bosque_flutter/domain/entities/rol_sabados_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/domain/repositories/rol_sabados_repository.dart';

final rolSabadosRepositoryProvider = Provider<RolSabadosRepository>(
  (ref) => RolSabadosImpl(),
);

/// Los roles disponibles, para el selector de arriba.
final rolesSabadosProvider = FutureProvider.autoDispose<List<RolSabadosEntity>>(
  (ref) async {
    return ref.watch(rolSabadosRepositoryProvider).getRoles();
  },
);

/// El rol que se está mirando. null = todavía no eligió ninguno.
final rolSeleccionadoProvider = StateProvider<int?>((ref) => null);

/// Mes que se muestra en la grilla. 0 = el año entero. Arranca en el mes actual
/// a propósito: un rol de 87 personas × 52 sábados son 4.500 cruces y casi
/// siempre importan los del mes en curso.
final filtroMesProvider = StateProvider<int>((ref) => DateTime.now().month);

/// Texto del buscador de personas. Vacío = todas.
final busquedaPersonaProvider = StateProvider<String>((ref) => '');

/// Grupo que se muestra en la pestaña «Grupos». `''` = los dos. **Se suma a
/// [busquedaPersonaProvider], no lo reemplaza** («solo el A» revisa el reparto,
/// «Pérez» va a alguien puntual). Vive aquí y no en la pestaña porque
/// `grillaRolProvider` es `autoDispose` y un estado local se perdería al volver
/// a la grilla (igual que [filtroEstadoCambioProvider]).
final filtroGrupoProvider = StateProvider<String>((ref) => '');

/// El cuarto valor de [filtroGrupoProvider]: en vez de una letra, muestra a
/// quienes RR.HH. sacó de los sábados. Va en el mismo provider y no en un switch
/// aparte para evitar combinaciones imposibles como «grupo A + mostrar
/// excluidos»; nunca choca con un grupo real (una sola letra).
const String filtroSinSabados = 'SIN SABADOS';

// La grilla

/// La grilla ya cruzada y lista para pintar. El backend devuelve tres listas
/// sueltas (filas, columnas y celdas ocupadas) porque la matriz pivoteada
/// tendría columnas dinámicas (52 o 53 según el año); el cruce se hace aquí,
/// una vez, y no en el `build` de cada celda.
class GrillaRol {
  final RolSabadosEntity rol;
  final List<SabadoEntity> sabados;
  final List<ParticipanteTurnoEntity> participantes;

  /// Clave `'idParticipante:idSabado'`. **Si la clave no está, esa persona está
  /// LIBRE ese sábado**: el libre no se guarda, es la ausencia de la fila.
  final Map<String, CeldaTurnoEntity> celdas;

  /// Catálogo indexado por letra, para el color y el nombre del estado.
  final Map<String, EstadoTurnoEntity> estados;

  /// Cuánta gente viene cada sábado y cuántos turnos tiene cada persona.
  /// **Precalculados a propósito:** el encabezado los pide una vez por columna y
  /// recorrer `celdas` daría ~117.000 iteraciones por redibujado (2.262 celdas
  /// × 52 columnas). Se calculan una vez, al armar la grilla.
  final Map<int, int> coberturaPorSabado;
  final Map<int, int> turnosPorParticipante;

  const GrillaRol({
    required this.rol,
    required this.sabados,
    required this.participantes,
    required this.celdas,
    required this.estados,
    required this.coberturaPorSabado,
    required this.turnosPorParticipante,
  });

  static String clave(int idParticipante, int idSabado) =>
      '$idParticipante:$idSabado';

  CeldaTurnoEntity? celda(int idParticipante, int idSabado) =>
      celdas[clave(idParticipante, idSabado)];

  /// Cuántas personas vienen ese sábado. Es el SUBTOTAL de abajo del Excel.
  int coberturaDe(int idSabado) => coberturaPorSabado[idSabado] ?? 0;

  /// Cuántos sábados le tocan a esa persona: el SUM de la derecha del Excel.
  int turnosDe(int idParticipante) =>
      turnosPorParticipante[idParticipante] ?? 0;
}

/// Carga la grilla completa de un rol. Las consultas van en paralelo con
/// `Future.wait`: son independientes y en serie sumarían varios viajes de red.
final grillaRolProvider = FutureProvider.autoDispose.family<GrillaRol, int>((
  ref,
  idRol,
) async {
  final repo = ref.watch(rolSabadosRepositoryProvider);

  final resultados = await Future.wait([
    repo.getRoles(),
    repo.getSabados(idRol),
    repo.getParticipantes(idRol),
    repo.getAsignaciones(idRol),
    repo.getEstadosTurno(),
  ]);

  final roles = resultados[0] as List<RolSabadosEntity>;
  final rol = roles.firstWhere(
    (r) => r.idRol == idRol,
    orElse: () => throw Exception('No se encontró el rol $idRol.'),
  );

  // Una sola pasada por las celdas: el mapa de la grilla y los dos
  // contadores salen juntos.
  final celdas = <String, CeldaTurnoEntity>{};
  final cobertura = <int, int>{};
  final turnos = <int, int>{};
  for (final c in resultados[3] as List<CeldaTurnoEntity>) {
    celdas[GrillaRol.clave(c.idParticipante, c.idSabado)] = c;
    if (c.codigoExcel == '1') {
      cobertura[c.idSabado] = (cobertura[c.idSabado] ?? 0) + 1;
      turnos[c.idParticipante] = (turnos[c.idParticipante] ?? 0) + 1;
    }
  }

  final estados = <String, EstadoTurnoEntity>{};
  for (final e in resultados[4] as List<EstadoTurnoEntity>) {
    estados[e.codigoExcel] = e;
  }

  return GrillaRol(
    rol: rol,
    sabados: resultados[1] as List<SabadoEntity>,
    participantes: resultados[2] as List<ParticipanteTurnoEntity>,
    celdas: celdas,
    estados: estados,
    coberturaPorSabado: cobertura,
    turnosPorParticipante: turnos,
  );
});

// Acciones

/// Las escrituras del módulo. Cada una invalida la grilla al terminar: el
/// backend puede rehacer MUCHAS celdas de una sola llamada (un evento rehace el
/// día entero), así que no alcanza con retocar el estado local.
class RolSabadosAcciones {
  final Ref _ref;
  RolSabadosAcciones(this._ref);

  RolSabadosRepository get _repo => _ref.read(rolSabadosRepositoryProvider);

  Future<int> _usuario() async {
    final notifier = _ref.read(userProvider.notifier);
    return await notifier.getCodUsuario();
  }

  void _refrescar(int idRol) => _ref.invalidate(grillaRolProvider(idRol));

  Future<int> generarRol({
    required int anio,
    int codSucursal = 0,
    String modo = 'CREAR',
  }) async {
    final id = await _repo.generarRol(
      anio: anio,
      codSucursal: codSucursal,
      modo: modo,
      audUsuario: await _usuario(),
    );
    _ref.invalidate(rolesSabadosProvider);
    if (id > 0) _refrescar(id);
    return id;
  }

  Future<void> corregirCelda({
    required int idRol,
    required int idParticipante,
    required int idSabado,
    required String codigoExcel,
    String observacion = '',
  }) async {
    await _repo.corregirCelda(
      idParticipante: idParticipante,
      idSabado: idSabado,
      codigoExcel: codigoExcel,
      observacion: observacion,
      audUsuario: await _usuario(),
    );
    _refrescar(idRol);
  }

  Future<void> liberarCelda({
    required int idRol,
    required int idParticipante,
    required int idSabado,
  }) async {
    await _repo.liberarCelda(
      idParticipante: idParticipante,
      idSabado: idSabado,
      audUsuario: await _usuario(),
    );
    _refrescar(idRol);
  }

  Future<void> marcarEvento({
    required int idRol,
    required int idSabado,
    String? alcanceEvento,
    String motivoEspecial = '',
  }) async {
    await _repo.marcarEvento(
      idSabado: idSabado,
      alcanceEvento: alcanceEvento,
      motivoEspecial: motivoEspecial,
      audUsuario: await _usuario(),
    );
    _refrescar(idRol);
  }

  Future<void> refrescarFeriados({required int idRol}) async {
    await _repo.refrescarFeriados(idRol: idRol, audUsuario: await _usuario());
    _refrescar(idRol);
  }

  /// Publica, reabre o cierra el rol. Invalida **las dos** fuentes del estado:
  /// la etiqueta del selector lee de [rolesSabadosProvider], pero la grilla
  /// guarda su propia copia de la cabecera (`GrillaRol.rol`, que apaga los
  /// botones de editar). [aplicaAsuetoCumple] es el valor que el rol ya tiene;
  /// ver el contrato del repositorio para saber por qué se reenvía.
  Future<void> cambiarEstadoRol({
    required int idRol,
    required String estado,
    required int aplicaAsuetoCumple,
  }) async {
    await _repo.cambiarEstadoRol(
      idRol: idRol,
      estado: estado,
      aplicaAsuetoCumple: aplicaAsuetoCumple,
      audUsuario: await _usuario(),
    );
    _ref.invalidate(rolesSabadosProvider);
    _refrescar(idRol);
  }

  // Cambios

  Future<void> registrarCambio({
    required int idRol,
    required int idSabado,
    required int codEmpleadoTitular,
    int codEmpleadoReemplazo = 0,
    int idSabadoReposicion = 0,
    required String tipo,
    String motivo = '',
  }) async {
    await _repo.registrarCambio(
      idRol: idRol,
      idSabado: idSabado,
      codEmpleadoTitular: codEmpleadoTitular,
      codEmpleadoReemplazo: codEmpleadoReemplazo,
      idSabadoReposicion: idSabadoReposicion,
      tipo: tipo,
      motivo: motivo,
      audUsuario: await _usuario(),
    );
    // La grilla NO cambia: un cambio nace SOLICITADO y no toca ninguna celda.
    _ref.invalidate(cambiosProvider(idRol));
  }

  Future<void> aprobarCambio({
    required int idRol,
    required int idCambio,
  }) async {
    final u = await _usuario();
    await _repo.aprobarCambio(
      idCambio: idCambio,
      codAprobador: u,
      audUsuario: u,
    );
    // Aquí SÍ se movieron celdas: hasta tres, en una transacción.
    _ref.invalidate(cambiosProvider(idRol));
    _refrescar(idRol);
  }

  Future<void> anularCambio({required int idRol, required int idCambio}) async {
    await _repo.anularCambio(idCambio: idCambio, audUsuario: await _usuario());
    _ref.invalidate(cambiosProvider(idRol));
  }

  // Grupos

  /// Cambia a alguien de grupo. NO regenera: armar los grupos son muchos
  /// cambios y una sola regeneración al final, no una por persona.
  Future<void> asignarGrupo({
    required int idRol,
    required int idParticipante,
    required String grupoRotacion,
  }) async {
    await _repo.asignarGrupo(
      idParticipante: idParticipante,
      grupoRotacion: grupoRotacion,
      audUsuario: await _usuario(),
    );
    _refrescar(idRol);
  }

  // Ventana de sábados de una persona. Estas dos SÍ mueven celdas: el backend
  // aplica el corte y la vuelta sin regenerar (bloqueado en un rol publicado).

  /// Saca a alguien de los sábados a partir del día siguiente a [fechaBaja].
  Future<void> sacarDeSabados({
    required int idRol,
    required int idParticipante,
    required DateTime fechaBaja,
  }) async {
    await _repo.sacarDeSabados(
      idParticipante: idParticipante,
      fechaBaja: fechaBaja,
      audUsuario: await _usuario(),
    );
    _refrescar(idRol);
  }

  /// Lo devuelve a la rotación desde [fechaAlta]. El pasado no se toca.
  Future<void> reincorporar({
    required int idRol,
    required int idParticipante,
    required DateTime fechaAlta,
  }) async {
    await _repo.reincorporar(
      idParticipante: idParticipante,
      fechaAlta: fechaAlta,
      audUsuario: await _usuario(),
    );
    _refrescar(idRol);
  }

  // Vacaciones y permisos

  Future<void> refrescarPermisos({required int idRol}) async {
    await _repo.refrescarPermisos(idRol: idRol, audUsuario: await _usuario());
    _ref.invalidate(desfasesPermisoProvider(idRol));
    _refrescar(idRol);
  }

  // El biométrico pisa al rol

  /// Aplica de verdad las excusas por horario (no `soloInformar`). La
  /// previsualización vive en [excusasHorarioProvider], que llama al mismo
  /// endpoint con `soloInformar=true` y no pasa por aquí.
  Future<List<ExcusaHorarioEntity>> aplicarExcusasHorario({
    required int idRol,
  }) async {
    final resultado = await _repo.refrescarExcusasHorario(
      idRol: idRol,
      audUsuario: await _usuario(),
    );
    _ref.invalidate(excusasHorarioProvider(idRol));
    _refrescar(idRol);
    return resultado;
  }

  // Convocatoria

  Future<void> convocar({
    required int idRol,
    required int idSabado,
    required String tipo,
    int codEmpleado = 0,
    int codEmpleadoJefe = 0,
    int codCargo = 0,
    String motivo = '',
  }) async {
    await _repo.convocar(
      idSabado: idSabado,
      tipo: tipo,
      codEmpleado: codEmpleado,
      codEmpleadoJefe: codEmpleadoJefe,
      codCargo: codCargo,
      motivo: motivo,
      audUsuario: await _usuario(),
    );
    _ref.invalidate(detalleEventoProvider(idSabado));
    _refrescar(idRol);
  }

  // Su equipo (jefes)

  /// Un jefe manda a alguien de su equipo a trabajar ('1') o lo libera ('L').
  /// **No llama a `_usuario()` a propósito:** el endpoint deriva quién programa
  /// del token para que nadie programe a nombre de otro; agregar `audUsuario`
  /// rompería el body que espera el controller.
  Future<void> programar({
    required int idRol,
    required int idSabado,
    required int codEmpleadoDependiente,
    required String codigoExcel,
    String motivo = '',
  }) async {
    await _repo.programar(
      idSabado: idSabado,
      codEmpleadoDependiente: codEmpleadoDependiente,
      codigoExcel: codigoExcel,
      motivo: motivo,
    );
    // Una programación deja rastro en tres lados: la celda de la grilla, la
    // fila de trs_Programacion y el listado de intervenciones.
    _refrescar(idRol);
    _ref.invalidate(programacionesProvider(idRol));
    _ref.invalidate(intervencionesProvider(idRol));
  }

  // ABM de programadores (ROLE_ADM)

  /// Alta o modificación. `idProgramador` 0 = alta.
  Future<void> registrarProgramador({
    int idProgramador = 0,
    required int codEmpleado,
    int codSucursal = 0,
    String alcance = 'DIRECTOS',
    int codEmpleadoReemplazo = 0,
    String observacion = '',
  }) async {
    await _repo.registrarProgramador(
      idProgramador: idProgramador,
      codEmpleado: codEmpleado,
      codSucursal: codSucursal,
      alcance: alcance,
      codEmpleadoReemplazo: codEmpleadoReemplazo,
      observacion: observacion,
      audUsuario: await _usuario(),
    );
    _invalidarProgramadores();
  }

  Future<void> eliminarProgramador({required int idProgramador}) async {
    await _repo.eliminarProgramador(
      idProgramador: idProgramador,
      audUsuario: await _usuario(),
    );
    _invalidarProgramadores();
  }

  /// El ABM puede estar tocando MI propio permiso: si el admin se agrega o se
  /// saca a sí mismo, la pestaña «Su Equipo» tiene que aparecer o desaparecer
  /// sin obligarlo a volver a entrar.
  void _invalidarProgramadores() {
    _ref.invalidate(programadoresProvider);
    _ref.invalidate(miEquipoProvider);
  }

  // El padrón de RR.HH.

  Future<void> registrarRrhh({
    required int codEmpleado,
    String observacion = '',
  }) async {
    await _repo.registrarRrhh(
      // 0 = alta. El SP reactiva solo si esa persona ya había estado.
      idRrhh: 0,
      codEmpleado: codEmpleado,
      observacion: observacion,
      audUsuario: await _usuario(),
    );
    _invalidarRrhh();
  }

  Future<void> eliminarRrhh(int idRrhh) async {
    await _repo.eliminarRrhh(idRrhh: idRrhh, audUsuario: await _usuario());
    _invalidarRrhh();
  }

  /// Igual que con los programadores: si el admin se agrega o se saca a sí
  /// mismo, hay que invalidar `miEquipoProvider` o la app abriría un editor que
  /// el servidor va a rechazar.
  void _invalidarRrhh() {
    _ref.invalidate(rrhhSabadosProvider);
    _ref.invalidate(miEquipoProvider);
  }

  /// Declara el puente. Devuelve el mensaje del servidor (cuántos permisos se
  /// crearon y cuántos se saltearon). Se invalida la grilla porque las celdas de
  /// esa gente pasaron a `V`, y las intervenciones porque quedaron con origen `M`.
  Future<String> aplicarPuente({
    required int idRol,
    required int idSabado,
    String horaDesde = '',
    String horaHasta = '',
    String motivo = '',
  }) async {
    final msg = await _repo.aplicarPuente(
      idSabado: idSabado,
      horaDesde: horaDesde,
      horaHasta: horaHasta,
      motivo: motivo,
    );
    _refrescar(idRol);
    _ref.invalidate(intervencionesProvider(idRol));
    return msg;
  }
}

final rolSabadosAccionesProvider = Provider<RolSabadosAcciones>(
  (ref) => RolSabadosAcciones(ref),
);

// Cambios, programaciones y controles

/// Filtro de estado de la pestaña de cambios. '' = todos.
final filtroEstadoCambioProvider = StateProvider<String>((ref) => '');

final cambiosProvider = FutureProvider.autoDispose
    .family<List<CambioEntity>, int>((ref, idRol) async {
      final estado = ref.watch(filtroEstadoCambioProvider);
      return ref
          .watch(rolSabadosRepositoryProvider)
          .getCambios(idRol, estado: estado);
    });

final programacionesProvider = FutureProvider.autoDispose
    .family<List<ProgramacionEntity>, int>((ref, idRol) async {
      return ref.watch(rolSabadosRepositoryProvider).getProgramaciones(idRol);
    });

final intervencionesProvider = FutureProvider.autoDispose
    .family<List<IntervencionEntity>, int>((ref, idRol) async {
      return ref.watch(rolSabadosRepositoryProvider).getIntervenciones(idRol);
    });

final cumplesSabadoProvider = FutureProvider.autoDispose
    .family<List<CumpleSabadoEntity>, int>((ref, idRol) async {
      return ref.watch(rolSabadosRepositoryProvider).getCumplesSabado(idRol);
    });

final feriadosDesincronizadosProvider = FutureProvider.autoDispose
    .family<List<SabadoEntity>, int>((ref, idRol) async {
      return ref
          .watch(rolSabadosRepositoryProvider)
          .getFeriadosDesincronizados(idRol);
    });

final automatizacionProvider = FutureProvider.autoDispose
    .family<AutomatizacionEntity?, int>((ref, idRol) async {
      return ref.watch(rolSabadosRepositoryProvider).getAutomatizacion(idRol);
    });

/// Los permisos de RR.HH. que la grilla todavía no refleja.
final desfasesPermisoProvider = FutureProvider.autoDispose
    .family<List<PermisoSabadoEntity>, int>((ref, idRol) async {
      return ref.watch(rolSabadosRepositoryProvider).getDesfasesPermiso(idRol);
    });

/// Previsualización de a quién le tocaría excusar por horario biométrico —
/// llama al endpoint real con `soloInformar=true`, no escribe nada.
final excusasHorarioProvider = FutureProvider.autoDispose
    .family<List<ExcusaHorarioEntity>, int>((ref, idRol) async {
      return ref
          .watch(rolSabadosRepositoryProvider)
          .refrescarExcusasHorario(
            idRol: idRol,
            soloInformar: true,
            audUsuario: 0, // sólo lee: el backend no lo usa en modo INFORMAR
          );
    });

/// **Dispara la excusa automática por horario biométrico al entrar al módulo,
/// sin job programado ni botón** (pedido explícito del usuario).
/// `RolSabadosScreen` lo observa una vez por `idRol` y usa la MISMA regla que
/// [excusasHorarioProvider] y [RolSabadosAcciones.aplicarExcusasHorario].
/// **Atrapa el error a propósito:** no todo el que abre la pantalla es RR.HH.
/// (el endpoint exige `ROLE_ADM` o `trs_Rrhh`) y un 403 o un fallo de red no
/// deben interrumpir la grilla; por eso nunca se observa con `.when()`.
final aplicarExcusasHorarioAlEntrarProvider = FutureProvider.autoDispose
    .family<void, int>((ref, idRol) async {
      try {
        await ref
            .read(rolSabadosAccionesProvider)
            .aplicarExcusasHorario(idRol: idRol);
      } catch (_) {
        // Silencioso a propósito: ver la documentación de arriba.
      }
    });

/// La lista nominal de un evento. Se pide por sábado, no por rol.
final detalleEventoProvider = FutureProvider.autoDispose
    .family<List<ConvocatoriaEntity>, int>((ref, idSabado) async {
      return ref.watch(rolSabadosRepositoryProvider).getDetalleEvento(idSabado);
    });

// Su equipo

/// Mi permiso para programar y la gente que puedo mover. **No es autoDispose a
/// propósito:** de esto depende que exista la pestaña y se consulta desde varias
/// pantallas. Observa `userProvider` porque el permiso lo resuelve el servidor
/// con el token: otro login es otro equipo.
final miEquipoProvider = FutureProvider<MiEquipoEntity>((ref) async {
  ref.watch(userProvider);
  return ref.watch(rolSabadosRepositoryProvider).getMiEquipo();
});

/// El sábado sobre el que está trabajando el jefe. null = todavía no eligió.
///
/// La pestaña trabaja con un sábado a la vez y no con la grilla entera: la
/// decisión de un jefe es «este sábado, quién viene».
final sabadoElegidoProvider = StateProvider<int?>((ref) => null);

/// Si la cabecera de «Su equipo» está plegada. null = nadie lo decidió aún y
/// manda el ancho de la pantalla (`bool?` distingue «lo abrió» de «viene así de
/// fábrica»). Sin `autoDispose`, como [sabadoElegidoProvider]: al cambiar de
/// pestaña habría que replegarla cada vez. No va a disco: el plegado se decide
/// planificando y se cobra otro día, en el contexto opuesto.
final cabeceraEquipoPlegadaProvider = StateProvider<bool?>((ref) => null);

/// El padrón de programadores, para el ABM de ROLE_ADM.
final programadoresProvider =
    FutureProvider.autoDispose<List<ProgramadorEntity>>((ref) async {
      return ref.watch(rolSabadosRepositoryProvider).getProgramadores();
    });

/// Quién manda en el módulo: Sistemas (`ROLE_ADM`) o RR.HH. (`trs_Rrhh`).
/// Definición única a propósito: `esAdmin || soyRrhh` estaba copiada en tres
/// lugares y una copia desincronizada deja pasar o excluye a alguien sin fallar.
/// **Falla cerrado:** ser de RR.HH. no viaja en el token sino en `trs_Rrhh` (vía
/// `/mi-equipo`), así que mientras esa respuesta viaja, o si falla, contesta que
/// no. Espeja a `exigirAdminORrhh` del backend, que es quien decide de verdad.
final administraRolProvider = Provider<bool>((ref) {
  if (ref.watch(userProvider)?.tipoUsuario == 'ROLE_ADM') return true;
  return ref.watch(miEquipoProvider).valueOrNull?.soyRrhh == true;
});

/// Quién puede escribir celdas, resuelto UNA vez para toda la grilla.
///
/// El servidor decide de verdad (`p_abm_trs_Asignacion` corta con el error 29);
/// esto evita ofrecer un editor que va a rebotar.
class PermisoDeCelda {
  const PermisoDeCelda({required this.todas, required this.miGente});

  /// ROLE_ADM o RR.HH.: cualquier celda, cualquier letra.
  final bool todas;

  /// Los `codEmpleado` de mi equipo, si soy jefe programador.
  final Set<int> miGente;

  bool puedeCon(int codEmpleado) => todas || miGente.contains(codEmpleado);

  /// Nadie puede nada: el valor mientras `miEquipoProvider` carga y si esa
  /// llamada falla. Ante la duda no se ofrece el editor: equivocarse para este
  /// lado se ve («no me deja»); para el otro no, hasta que alguien encuentra su
  /// sábado cambiado.
  static const nadie = PermisoDeCelda(todas: false, miGente: {});
}

/// Lo que la grilla necesita saber antes de dejar tocar una celda. Se calcula
/// aquí y no en cada celda: 85 × 52 son 4.420 celdas y que cada una observe
/// providers serían 4.420 suscripciones para responder siempre lo mismo.
final permisoDeCeldaProvider = Provider.autoDispose<PermisoDeCelda>((ref) {
  // `todas` = quién administra (abre los ABM y regenera el rol); sale de
  // [administraRolProvider] para tener una sola definición.
  final todas = ref.watch(administraRolProvider);
  final equipo = ref.watch(miEquipoProvider).valueOrNull;
  if (equipo == null) {
    return todas
        ? const PermisoDeCelda(todas: true, miGente: {})
        : PermisoDeCelda.nadie;
  }
  return PermisoDeCelda(todas: todas, miGente: equipo.codigosDeMiGente);
});

/// El padrón de RR.HH., para el ABM de ROLE_ADM.
///
/// Sin filtro de estado a propósito: la pantalla necesita ver también a los
/// dados de baja, porque volver a agregar a alguien es reactivar esa fila.
final rrhhSabadosProvider = FutureProvider.autoDispose<List<RrhhSabadosEntity>>(
  (ref) async {
    return ref.watch(rolSabadosRepositoryProvider).getRrhh();
  },
);

/// Lo que define un puente: el sábado y el horario del permiso. Las horas van en
/// la clave porque **cambiarlas cambia cuánto se le descuenta a cada uno**: hay
/// que rehacer la simulación, no reutilizarla.
typedef PuenteAConsultar = ({int idSabado, String horaDesde, String horaHasta});

/// Qué pasaría si se declarara ese sábado como puente a cuenta de vacación.
///
/// **No escribe nada** (con `@ACCION='S'` el backend hace `RETURN` antes de
/// cualquier transacción); alimenta el diálogo de confirmación.
final previaPuenteProvider = FutureProvider.autoDispose
    .family<List<PuenteVacacionEntity>, PuenteAConsultar>((ref, p) async {
      if (p.idSabado == 0) return const <PuenteVacacionEntity>[];
      return ref
          .watch(rolSabadosRepositoryProvider)
          .simularPuente(
            idSabado: p.idSabado,
            horaDesde: p.horaDesde,
            horaHasta: p.horaHasta,
          );
    });

/// Lo que define una previsualización de permiso. Es un `record` porque Riverpod
/// compara la clave de la familia por `==` y los records ya lo traen estructural;
/// con una clase, olvidar un campo en `==`/`hashCode` dejaría la lista vieja en
/// pantalla sin que nada falle.
typedef PreviaDePermiso =
    ({int codEmpleado, int codSucursal, String alcance, int idRol});

/// A quiénes le quedaría a cargo ese permiso, **antes** de darlo de alta.
///
/// `autoDispose` porque vive dentro de una hoja modal: sin esto la caché
/// guardaría una entrada por cada combinación que el admin probó mientras dudaba.
final previaDependientesProvider = FutureProvider.autoDispose
    .family<List<ProgramadorDependienteEntity>, PreviaDePermiso>((
      ref,
      p,
    ) async {
      // Sin persona no hay nada que preguntar: se corta aquí para no llamar al
      // servidor mientras se busca a alguien en el combo. **`codSucursal == 0`
      // NO corta:** significa «todas las sucursales» (como el NULL de
      // `trs_Programador.codSucursal`); cortar dejaba a «Todas» devolviendo lista
      // vacía sin llegar al backend. El caso «no sé cuál es su sucursal» lo
      // resuelve la pantalla, que no dibuja la previsualización ni deja guardar.
      if (p.codEmpleado == 0) {
        return const <ProgramadorDependienteEntity>[];
      }
      return ref
          .watch(rolSabadosRepositoryProvider)
          .previsualizarDependientes(
            codEmpleado: p.codEmpleado,
            codSucursal: p.codSucursal,
            alcance: p.alcance,
            idRol: p.idRol,
          );
    });
