import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/data/repositories/rol_sabados_impl.dart';
import 'package:bosque_flutter/domain/entities/automatizacion_entity.dart';
import 'package:bosque_flutter/domain/entities/cambio_entity.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/convocatoria_entity.dart';
import 'package:bosque_flutter/domain/entities/cumple_sabado_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_turno_entity.dart';
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

/// Mes que se muestra en la grilla. 0 = el año entero.
///
/// Arranca en el mes actual y no en «todo el año» a propósito: un rol de 87
/// personas × 52 sábados son 4.500 cruces, y de ellos casi siempre importan los
/// del mes en curso. Mostrar el año completo de entrada es pedirle al navegador
/// que dibuje diez veces más de lo que nadie va a mirar.
final filtroMesProvider = StateProvider<int>((ref) => DateTime.now().month);

/// Texto del buscador de personas. Vacío = todas.
final busquedaPersonaProvider = StateProvider<String>((ref) => '');

/// Grupo que se muestra en la pestaña «Grupos». `''` = los dos.
///
/// **Se suma a [busquedaPersonaProvider], no lo reemplaza.** Son dos preguntas
/// distintas y se hacen juntas: «mostrame el A» sirve para revisar el reparto —
/// con 85 personas mezcladas hay que leer fila por fila cuál letra está
/// resaltada— y «mostrame a Pérez» sirve para ir a alguien puntual.
///
/// Vive acá y no adentro de la pestaña por lo mismo que los otros filtros del
/// módulo: `grillaRolProvider` es `autoDispose`, así que ir a la grilla y
/// volver reconstruye la vista entera y un estado local se perdería en cada
/// vuelta. Mismo criterio y mismo tipo que [filtroEstadoCambioProvider].
final filtroGrupoProvider = StateProvider<String>((ref) => '');

/// El cuarto valor de [filtroGrupoProvider]: en vez de una letra, muestra a
/// quienes RR.HH. sacó de los sábados.
///
/// **Va en el mismo provider y no en un switch aparte.** Es otra vista de la
/// misma lista, y los tres chips de arriba ya son mutuamente excluyentes: con
/// un estado nuevo habría dos controles de filtrado con dos formas distintas en
/// la misma barra, y estados imposibles como «grupo A + mostrar excluidos».
/// Nunca choca con un grupo real, que es una sola letra.
const String filtroSinSabados = 'SIN SABADOS';

// ═══════════════════════════════════════════════════════════════════════════
// LA GRILLA
// ═══════════════════════════════════════════════════════════════════════════

/// La grilla ya cruzada y lista para pintar.
///
/// El backend devuelve tres listas sueltas (filas, columnas y celdas ocupadas)
/// porque la matriz pivoteada tendría columnas dinámicas — 52 o 53 según el año.
/// El cruce se hace acá, una sola vez, y no en el `build` de cada celda.
class GrillaRol {
  final RolSabadosEntity rol;
  final List<SabadoEntity> sabados;
  final List<ParticipanteTurnoEntity> participantes;

  /// Clave `'idParticipante:idSabado'`. **Si la clave no está, esa persona está
  /// LIBRE ese sábado** — el libre no se guarda, es la ausencia de la fila.
  final Map<String, CeldaTurnoEntity> celdas;

  /// Catálogo indexado por letra, para el color y el nombre del estado.
  final Map<String, EstadoTurnoEntity> estados;

  /// Cuánta gente viene cada sábado, y cuántos turnos tiene cada persona.
  ///
  /// **Precalculados a propósito.** Antes se contaban recorriendo el mapa de
  /// celdas en cada llamada, y el encabezado llama una vez por columna: con
  /// 2.262 celdas × 52 columnas eran 117.000 iteraciones en CADA redibujado, y
  /// otro tanto por cada fila visible. Se calculan una sola vez, al armar la
  /// grilla, en una pasada.
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

/// Carga la grilla completa de un rol.
///
/// Las cuatro consultas van en paralelo con `Future.wait`: son independientes y
/// en serie sumarían cuatro viajes de red para pintar una sola pantalla.
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

// ═══════════════════════════════════════════════════════════════════════════
// ACCIONES
// ═══════════════════════════════════════════════════════════════════════════

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

  /// Publica, reabre o cierra el rol.
  ///
  /// Invalida **las dos** fuentes del estado y no una: la etiqueta del selector
  /// lee de [rolesSabadosProvider], pero la grilla se queda con su propia copia
  /// de la cabecera dentro de `GrillaRol` —de ahí sale `rol.estaCerrado`, que
  /// es lo que apaga los botones de editar en la matriz, la agenda y Grupos—.
  /// Refrescando sólo la lista, la etiqueta diría CERRADO y la grilla seguiría
  /// dejando tocar celdas hasta que el backend las rebotara de a una.
  ///
  /// [aplicaAsuetoCumple] es el valor que el rol ya tiene; ver el contrato del
  /// repositorio para por qué hay que reenviarlo.
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

  // ── cambios ───────────────────────────────────────────────────────────

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
    // Acá SÍ se movieron celdas: hasta tres, en una transacción.
    _ref.invalidate(cambiosProvider(idRol));
    _refrescar(idRol);
  }

  Future<void> anularCambio({required int idRol, required int idCambio}) async {
    await _repo.anularCambio(idCambio: idCambio, audUsuario: await _usuario());
    _ref.invalidate(cambiosProvider(idRol));
  }

  // ── grupos ─────────────────────────────────

  /// Cambia a alguien de grupo. NO regenera: armar los grupos son muchos
  /// cambios y una sola regeneracion al final, no una por persona.
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

  // ── la ventana de sábados de una persona ──────────────────────────────
  //
  // Estas dos SÍ mueven celdas, y por eso refrescan la grilla igual que
  // corregirCelda: el backend aplica el corte y la vuelta él mismo, sin
  // esperar a una regeneración —que sobre un rol publicado está bloqueada—.

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

  // ── vacaciones y permisos ─────────────────────────────────────────────

  Future<void> refrescarPermisos({required int idRol}) async {
    await _repo.refrescarPermisos(idRol: idRol, audUsuario: await _usuario());
    _ref.invalidate(desfasesPermisoProvider(idRol));
    _refrescar(idRol);
  }

  // ── convocatoria ──────────────────────────────────────────────────────

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

  // ── su equipo (jefes) ─────────────────────────────────────────────────

  /// Un jefe manda a alguien de su equipo a trabajar ('1') o lo libera ('L').
  ///
  /// **No llama a `_usuario()` y no es un olvido:** el endpoint deriva quién
  /// programa del token, justamente para que nadie pueda programar a nombre de
  /// otro. Si le agregás el `audUsuario` que usan todas las demás acciones de
  /// esta clase, el body deja de coincidir con lo que espera el controller.
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

  // ── ABM de programadores (ROLE_ADM) ───────────────────────────────────

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

  // ── El padrón de RR.HH. ───────────────────────────────────────────────

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

  /// Por el mismo motivo que los programadores: el admin puede estar
  /// agregándose o sacándose a sí mismo, y de eso depende si la grilla le deja
  /// tocar celdas. Si no se invalida `miEquipoProvider`, la app sigue creyendo
  /// lo que sabía al entrar y le abre un editor que el servidor va a rechazar.
  void _invalidarRrhh() {
    _ref.invalidate(rrhhSabadosProvider);
    _ref.invalidate(miEquipoProvider);
  }

  /// Declara el puente. Devuelve el mensaje del servidor, que dice cuántos
  /// permisos se crearon y cuántos se saltearon.
  ///
  /// Se invalida la grilla porque las celdas de esa gente pasaron a `V`, y
  /// también las intervenciones: quedaron escritas con origen `M`.
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

// ═══════════════════════════════════════════════════════════════════════════
// CAMBIOS · PROGRAMACIONES · CONTROLES
// ═══════════════════════════════════════════════════════════════════════════

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

/// La lista nominal de un evento. Se pide por sábado, no por rol.
final detalleEventoProvider = FutureProvider.autoDispose
    .family<List<ConvocatoriaEntity>, int>((ref, idSabado) async {
      return ref.watch(rolSabadosRepositoryProvider).getDetalleEvento(idSabado);
    });

// ═══════════════════════════════════════════════════════════════════════════
// SU EQUIPO
// ═══════════════════════════════════════════════════════════════════════════

/// Mi permiso para programar y la gente que puedo mover.
///
/// **No es autoDispose a propósito.** De esto depende que la pestaña exista, y
/// se consulta desde varias pantallas del módulo: si se tirara al salir, cada
/// vuelta costaría un viaje de red para preguntar algo que no cambia mientras
/// dure la sesión.
///
/// Mira `userProvider` para rehacerse cuando cambia el usuario: el permiso lo
/// resuelve el servidor con el token, así que otro login es otro equipo.
final miEquipoProvider = FutureProvider<MiEquipoEntity>((ref) async {
  ref.watch(userProvider);
  return ref.watch(rolSabadosRepositoryProvider).getMiEquipo();
});

/// El sábado sobre el que está trabajando el jefe. null = todavía no eligió.
///
/// La pestaña trabaja de a un sábado y no con la grilla entera: la decisión que
/// toma un jefe es «este sábado, quién viene», no «el año que viene, quiénes».
final sabadoElegidoProvider = StateProvider<int?>((ref) => null);

/// Si la cabecera de «Su equipo» está plegada. null = todavía no lo decidió
/// nadie y manda el ancho de la pantalla.
///
/// **Por qué `bool?` y no `bool`.** El default depende del ancho —en el teléfono
/// la cabecera se come más de la mitad del alto útil, en escritorio no le saca
/// lugar a nadie— pero la elección de quien la usa NO depende del ancho. Con un
/// `bool` no habría forma de distinguir «lo abrió» de «viene así de fábrica», y
/// el default por dispositivo sería imposible. El ancho propone, el usuario
/// dispone.
///
/// **Sin `autoDispose`, igual que [sabadoElegidoProvider] y por lo mismo:**
/// `grillaRolProvider` sí lo es, así que al ir a otra pestaña y volver la vista
/// se reconstruye entera y habría que replegar la cabecera cada vez.
///
/// **No va a disco.** En el módulo no persiste ningún estado de interfaz —ni el
/// mes de la grilla, ni la búsqueda, ni el sábado elegido—, y acá persistir
/// sería peor que no hacerlo: el plegado se decide planificando («abrime los
/// meses») y se cobra el jueves siguiente, que es el contexto opuesto.
final cabeceraEquipoPlegadaProvider = StateProvider<bool?>((ref) => null);

/// El padrón de programadores, para el ABM de ROLE_ADM.
final programadoresProvider =
    FutureProvider.autoDispose<List<ProgramadorEntity>>((ref) async {
      return ref.watch(rolSabadosRepositoryProvider).getProgramadores();
    });

/// Quién manda en el módulo: Sistemas (`ROLE_ADM`) o RR.HH. (`trs_Rrhh`).
///
/// **Una sola definición, y a propósito.** Esta cuenta —`esAdmin || soyRrhh`—
/// estaba escrita tres veces: en el encabezado de la pantalla, en el permiso de
/// celda y en la etiqueta de estado del rol. Tres copias de una regla de
/// permisos es tres lugares donde puede quedar desincronizada, y el que se
/// olvide no falla: silenciosamente deja pasar a alguien, o deja afuera a quien
/// debía entrar.
///
/// **Falla cerrado.** Ser de RR.HH. no viaja en el token, es una fila en
/// `trs_Rrhh` que llega por `/mi-equipo`. Mientras esa respuesta viaja —o si
/// falla— acá se contesta que no. Un `ROLE_ADM` no depende de esa llamada, así
/// que ese pasa igual. Equivocarse para este lado se ve —«no me deja»— y se
/// pregunta; para el otro lado no se ve hasta que alguien encuentra su año
/// rehecho.
///
/// Espeja a `exigirAdminORrhh` del backend, que es quien decide de verdad: esto
/// sólo evita ofrecer botones que iban a rebotar con un 403.
final administraRolProvider = Provider<bool>((ref) {
  if (ref.watch(userProvider)?.tipoUsuario == 'ROLE_ADM') return true;
  return ref.watch(miEquipoProvider).valueOrNull?.soyRrhh == true;
});

/// Quién puede escribir celdas, resuelto UNA vez para toda la grilla.
///
/// El servidor decide de verdad —`p_abm_trs_Asignacion` corta con el error 29—;
/// esto es para no ofrecer un editor que va a rebotar. Sin esta clase, tocar la
/// celda de alguien ajeno abría la hoja, dejaba elegir una letra y recién
/// después mostraba un cartel: tres pasos para averiguar que no se podía.
class PermisoDeCelda {
  const PermisoDeCelda({required this.todas, required this.miGente});

  /// ROLE_ADM o RR.HH.: cualquier celda, cualquier letra.
  final bool todas;

  /// Los `codEmpleado` de mi equipo, si soy jefe programador.
  final Set<int> miGente;

  bool puedeCon(int codEmpleado) => todas || miGente.contains(codEmpleado);

  /// Nadie puede nada. Es el valor mientras `miEquipoProvider` carga, y el que
  /// queda si esa llamada falla: ante la duda, no ofrecer el editor. Equivocarse
  /// para este lado se ve —«no me deja»— y se pregunta; para el otro lado no se
  /// ve hasta que alguien encuentra su sábado cambiado.
  static const nadie = PermisoDeCelda(todas: false, miGente: {});
}

/// Lo que la grilla necesita saber antes de dejar tocar una celda.
///
/// Se calcula acá y no en cada celda: una matriz de 85 × 52 son 4.420 celdas, y
/// que cada una observe providers por su cuenta es 4.420 suscripciones para
/// responder siempre lo mismo.
final permisoDeCeldaProvider = Provider.autoDispose<PermisoDeCelda>((ref) {
  // `todas` es exactamente «quién administra»: la misma gente que abre los ABM
  // y regenera el rol es la que puede escribir cualquier celda con cualquier
  // letra. Sale de [administraRolProvider] para que sea una sola definición.
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
final rrhhSabadosProvider =
    FutureProvider.autoDispose<List<RrhhSabadosEntity>>((ref) async {
      return ref.watch(rolSabadosRepositoryProvider).getRrhh();
    });

/// Lo que define un puente: el sábado y el horario del permiso.
///
/// Las horas van en la clave porque **cambiarlas cambia cuánto se le descuenta
/// a cada uno** — la simulación hay que rehacerla, no reutilizarla.
typedef PuenteAConsultar = ({int idSabado, String horaDesde, String horaHasta});

/// Qué pasaría si se declarara ese sábado como puente a cuenta de vacación.
///
/// **No escribe nada**: con `@ACCION='S'` el backend hace `RETURN` antes de
/// cualquier transacción. Es lo que alimenta el diálogo de confirmación.
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

/// Lo que define una previsualización de permiso.
///
/// Es un `record` y no una clase porque Riverpod compara la clave de la familia
/// por `==`, y los records ya lo traen estructural: tocar el `SegmentedButton`
/// del alcance produce otra clave y la lista se vuelve a pedir sola. Con una
/// clase habría que escribir `==` y `hashCode` a mano, y olvidarse de uno de los
/// cuatro campos dejaría la lista vieja en pantalla sin que nada falle.
typedef PreviaDePermiso =
    ({int codEmpleado, int codSucursal, String alcance, int idRol});

/// A quiénes le quedaría a cargo ese permiso, **antes** de darlo de alta.
///
/// `autoDispose` porque vive adentro de una hoja modal: al cerrarla no queda
/// nada que refrescar, y sin esto la caché se quedaría con una entrada por cada
/// combinación que el admin probó mientras dudaba.
final previaDependientesProvider = FutureProvider.autoDispose
    .family<List<ProgramadorDependienteEntity>, PreviaDePermiso>((ref, p) async {
      // Sin persona no hay nada que preguntar: se corta acá para no pegarle al
      // servidor mientras todavía se está buscando a alguien en el combo.
      //
      // **`codSucursal == 0` NO corta**, aunque acá antes cortaba. Cuando el 0
      // quería decir «no sé cuál es su sucursal» tenía sentido; desde que
      // significa «todas las sucursales» —el mismo idioma que el NULL de
      // `trs_Programador.codSucursal`— cortar acá dejaba a la opción «Todas»
      // devolviendo lista vacía sin llegar nunca al backend. La pantalla
      // entonces decía «el organigrama no le da NINGÚN dependiente», que era
      // exactamente lo contrario de la verdad.
      //
      // El caso «no sé cuál es su sucursal» lo resuelve la pantalla, que no
      // dibuja la previsualización ni deja guardar. Es donde se puede explicar
      // qué hacer al respecto; acá sólo se sabría que hay un cero.
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
