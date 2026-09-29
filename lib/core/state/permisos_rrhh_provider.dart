import 'package:bosque_flutter/data/repositories/permisos_rrhh_impl.dart';
import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';
import 'package:bosque_flutter/domain/entities/desglose_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/dia_no_habil_entity.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/simulacion_colectiva_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repositorio del módulo. Se declara aquí y no en `main.dart`: los overrides
/// registrados allá construían el repo (y todo el cliente Dio) antes del primer
/// frame para todos los usuarios; así se fabrica de forma perezosa. (El
/// `CLAUDE.md` que manda registrarlo en `main.dart` está desactualizado.)
final permisosRrhhRepositoryProvider = Provider<PermisosRrhhRepository>(
  (ref) => PermisosRrhhImpl(),
);

// AUTORIZACIÓN (SUPUESTO D4 — pendiente de confirmación de RR.HH., ver plan §5)
// Van aquí y no en `permisos_rrhh_comunes.dart`: la decisión de permiso vive en
// el provider del módulo (como en Rol de Sábados) y el archivo de piezas no sabe
// de ACL; solo queda la constante con el nombre real del botón de `tb_vistaBtn`.

/// Botón del ACL (`tb_vistaBtn` / `tb_usuarioBtn`) que habilita la consulta de
/// saldo dentro de la vista 24. Esconder no es autorizar: el gate real está en el
/// backend (identidad desde el token) y esto solo evita ofrecer una pantalla que
/// devolvería 403. Usuarios `lim`: `tienePermiso` da acceso a todo `ROLE_ADM` sin
/// mirar la tabla; el resto (p. ej. `rramos`) necesita su fila en
/// `tb_usuarioBtn` o el módulo se le esconde.
const String btnConsultaSaldo = 'btnDetalles';

/// Botón del ACL de la **calculadora de antigüedad**. No es el mismo permiso que
/// `btnDetalles`: el backend exige `btnApoyoCalc` en
/// `/permiso-rrhh/herramientas/calculo-antiguedad` y `btnDetalles` en los otros
/// dos endpoints, y los padrones difieren (5 vs 6 usuarios), así que con una sola
/// constante alguien vería la pestaña y recibiría 403. Si RR.HH. quiere un
/// permiso único, cambia el `exigirBoton` de `PermisoRrhhController`, no esto.
const String btnCalculadora = 'btnApoyoCalc';

/// Botón del ACL para **bajar la boleta** de un permiso en PDF; el mismo que
/// exige el backend en `/vacacion/RptPermisoVacacion` (codBtn 109, 6 usuarios).
/// Allá el gate tiene tres puertas (este botón, boleta propia, o empleado en el
/// subárbol de cargos de quien pide): esconderlo aquí solo evita el 403, **quién
/// puede bajar qué lo decide el servidor**.
const String btnBoleta = 'btnReImprimirBoleta';

/// El botón del ACL de los **reportes de saldos** (codBtn 210, 4 usuarios).
/// Es el mismo que el backend exige en `/permiso-rrhh/reportes/*`.
const String btnReportes = 'btnReportesPYV';

/// Botón del ACL de la ABM de vacación asignada. PLACEHOLDER: el legacy usa
/// `btnEditNewVacAsigAntesDos`, inexistente en `tb_vistaBtn`; este nombre propio
/// tampoco existe aún, a propósito: mientras no exista, `tienePermiso` solo deja
/// pasar a `ROLE_ADM` (cerrado por omisión). No reusar `btnEditVacAntPenult`
/// («editar el permiso ya gozado»). Debe coincidir con `BTN_VACACION_ASIGNADA`;
/// para abrirlo a RR.HH.: `sql/04_botones_vacacion_asignada.sql` y `nivelAcceso`.
const String btnVacacionAsignada = 'btnNuevaVacAsignada';

/// Botón del ACL de la **baja** de una vacación asignada. Botón propio, no alias
/// del alta: en el legacy Eliminar está con `rendered="false"` (hoy no lo ejecuta
/// nadie), así que traerlo es habilitar, no migrar. Ambos nombres se crean en el
/// mismo script, y separarlos permite dejar la baja en menos manos sin tocar código.
const String btnVacacionAsignadaBaja = 'btnEliminarVacAsignada';

/// Botón del ACL del **abono de días individual** (`codBtn` 119, «Editar Abono
/// Dias»): 5 usuarios con `nivelAcceso != 0`. Cubre también el alta: en el legacy
/// no tiene botón propio, se abre desde el mismo modal.
const String btnAbonoDias = 'btnEditarAbonoDia';

/// El botón del ACL del **abono de días colectivo** (`codBtn` 107): 4 usuarios,
/// todos `lim`. `jmonrroy` **no lo tiene** y entra sólo por el fallback de
/// administrador — o sea que el padrón real de esta carga son cuatro personas.
const String btnAbonoGrupal = 'btnNuevoAbonoGrupal';

/// El botón del ACL de la **vacación colectiva** (`codBtn` 108): 5 usuarios.
const String btnVacacionGrupal = 'btnNuevaVacGrupal';

/// Botón del ACL de **«Programar permiso»** (`codBtn` 112): 4 usuarios, uno menos
/// que los otros dos de esta tanda. Constante propia y no compartida con
/// [btnProgramarVacacion]: un solo nombre para las tres operaciones concedería a
/// alguien una atribución que hoy no tiene.
const String btnProgramarPermiso = 'btnProgramarPermiso';

/// El botón del ACL de **«Programar vacación»** (`codBtn` 113): 5 usuarios.
const String btnProgramarVacacion = 'btnProgramarVacacion';

/// Botón del ACL de **«Vacación pagada»** (PVA). Está DUPLICADO en `tb_vistaBtn`
/// (`codBtn` 110 y 114, 5 usuarios cada uno); `AccesoModuloHelper.tieneBoton` usa
/// `anyMatch` y lo tolera, pero si los padrones difieren el permiso efectivo es
/// la unión de ambos. Confirmarlo con RR.HH. antes de habilitar días pagados.
const String btnVacacionPagada = 'btnNuevaVacPagada';

/// El empleado que se está mirando. Global y no estado local del widget: los
/// providers de abajo son `autoDispose` y un `setState` se perdería al salir del
/// módulo; así vuelve mostrando a la misma persona.
final empleadoSeleccionadoProvider = StateProvider<EmpleadoEntity?>(
  (ref) => null,
);

/// Texto tipeado en el buscador, **ya con el rebote aplicado**: lo escribe el
/// campo recién cuando la persona dejó de tipear (ver `buscador_empleado.dart`).
/// Escribirlo en cada tecla dispararía una consulta por letra.
final busquedaEmpleadoProvider = StateProvider<String>((ref) => '');

/// Empresa por la que se filtra la búsqueda. 0 = todas. Los tres `StateProvider`
/// de este archivo no son `autoDispose` a propósito (a diferencia de los
/// `FutureProvider`): son estado de interfaz y se perderían al volver al módulo.
final filtroEmpresaProvider = StateProvider<int>((ref) => 0);

/// Si la búsqueda trae sólo a los empleados activos.
///
/// Arranca en `true`: la consola es para resolver el saldo de quien trabaja hoy.
/// Alguien dado de baja se busca a propósito, no por accidente.
final filtroSoloActivosProvider = StateProvider<bool>((ref) => true);

/// Resultado del buscador (`p_list_Empleado 'Y'`, vía `/rrhh/obtenerLstEmpleados`).
/// No es un `family`: los tres filtros son estado global del módulo y se leen con
/// `watch`, así Riverpod rearma la búsqueda al cambiar cualquiera.
final empleadosBuscadosProvider =
    FutureProvider.autoDispose<List<EmpleadoEntity>>((ref) {
      return ref
          .watch(permisosRrhhRepositoryProvider)
          .buscarEmpleados(
            ref.watch(busquedaEmpleadoProvider),
            soloActivos: ref.watch(filtroSoloActivosProvider),
            // El 0 = «todas» se pasa tal cual: traducirlo a null es cosa del
            // impl, que es quien habla el idioma del backend.
            codEmpresa: ref.watch(filtroEmpresaProvider),
          );
    });

/// Ficha de saldo del empleado `cod` (`ACCION 'C'`). `family` con un `int`: dos
/// `int` iguales son el mismo parámetro y Riverpod cachea, así un rebuild no
/// vuelve a consultar el backend (el getter del JSF que este módulo reemplaza sí lo
/// hacía en cada render).
final fichaSaldoProvider = FutureProvider.autoDispose.family<
  FichaSaldoEntity?,
  int
>((ref, cod) => ref.watch(permisosRrhhRepositoryProvider).getFichaSaldo(cod));

/// Desglose en 5 tramos del empleado `cod` (`ACCION 'D'`).
final desgloseSaldoProvider = FutureProvider.autoDispose
    .family<DesgloseSaldoEntity?, int>(
      (ref, cod) =>
          ref.watch(permisosRrhhRepositoryProvider).getDesgloseSaldo(cod),
    );

/// El rango de la calculadora de antigüedad. Es un record y no una clase/Entity:
/// la clave de un `family` se compara con `==` y un objeto sin `==`/`hashCode`
/// sería una clave nueva por rebuild (petición y provider vivo cada vez: un
/// bucle). Caso latente: `previsualizarSaldoProvider` usa una Entity.
typedef RangoDeCalculo = ({DateTime desde, DateTime hasta});

/// La frase en prosa del SP para un rango simulado (`ACCION 'U'`). Es
/// orientativa: cuenta años enteros con un `WHILE` (no es el algoritmo del saldo
/// real) y da «= 0 dias por antiguedad» en el aniversario exacto y cuando ambas
/// fechas caen en el mismo mes; la pantalla detecta esa subcadena y avisa.
final calculoAntiguedadProvider = FutureProvider.autoDispose
    .family<String, RangoDeCalculo>(
      (ref, r) => ref
          .watch(permisosRrhhRepositoryProvider)
          .calcularAntiguedad(desde: r.desde, hasta: r.hasta),
    );

/// Empleado + relación laboral: la clave de todo lo que se lee de una persona.
/// Las lecturas del legacy filtran por `codEmpleado` y `codRelEmplEmpr`
/// (`p_list_vacacionAsignada 'B'`, `p_list_AbonoDias 'B'`) porque el saldo es de
/// la relación vigente: dos contratos son dos historias que no deben sumarse.
/// `codRelEmplEmpr` = 0 significa «la vigente, resuélvela tú». Es un record por
/// la misma razón que [RangoDeCalculo] (igualdad estructural en la clave).
typedef ClaveEmpleadoRelacion = ({int codEmpleado, int codRelEmplEmpr});

/// El historial de vacación asignada: una fila por aniversario, con las
/// **sintéticas** (id 0) de los que todavía no tienen registro. De ahí sale el
/// «Nuevo» de la grilla.
final historialVacacionAsignadaProvider = FutureProvider.autoDispose
    .family<List<VacacionAsignadaEntity>, ClaveEmpleadoRelacion>(
      (ref, k) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getHistorialVacacionAsignada(
            k.codEmpleado,
            codRelEmplEmpr: k.codRelEmplEmpr,
          ),
    );

/// El detalle de abonos de días de esa relación laboral, con su acumulado.
final detalleAbonosProvider = FutureProvider.autoDispose
    .family<List<AbonoDiasEntity>, ClaveEmpleadoRelacion>(
      (ref, k) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getDetalleAbonos(k.codEmpleado, codRelEmplEmpr: k.codRelEmplEmpr),
    );

/// El padrón para tildar en una carga colectiva. La clave es la empresa (0 =
/// todas).
final empleadosColectivaProvider = FutureProvider.autoDispose
    .family<List<SimulacionColectivaEntity>, int>(
      (ref, codEmpresa) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getEmpleadosParaColectiva(codEmpresa: codEmpresa),
    );

// NÓMINA DE PERMISOS (el kardex) Y SUS FILTROS

/// El combo de tipo de la Nómina. Vacío = «Todos» (el DAO del legacy lo traduce a
/// `@tipoPermiso = NULL`). `StateProvider` sin `autoDispose`, como los demás
/// filtros del módulo.
final filtroTipoPermisoProvider = StateProvider<String>((ref) => '');

/// «Fecha Inicio» del filtro. **Compara contra el INICIO del permiso**
/// (`CONVERT(date, tp.desde) >= @desde`), no contra el rango entero.
final filtroFechaInicioProvider = StateProvider<DateTime?>((ref) => null);

/// «Fecha Fin» del filtro. **Compara contra el FIN del permiso**
/// (`CONVERT(date, tp.hasta) <= @hasta`).
final filtroFechaFinProvider = StateProvider<DateTime?>((ref) => null);

/// «Fecha Rango» del filtro, que es **«quién estaba de permiso el día X»** y no
/// un extremo de nada: el SP pregunta si esa fecha cae DENTRO del `[desde,
/// hasta]` del permiso. El rótulo del legacy es de los que engañan, y por eso
/// el nombre de aquí dice fecha y no rango.
final filtroFechaRangoProvider = StateProvider<DateTime?>((ref) => null);

/// La clave de la Nómina: la persona, su relación laboral y los tres filtros.
/// Es un record por lo mismo que [RangoDeCalculo]. Es `family` y no un provider
/// que observe los filtros (al revés que [empleadosBuscadosProvider]) porque en
/// el legacy la consulta la dispara el botón «Buscar Permisos», no cada tecla:
/// con `watch`, elegir una fecha en el calendario consultaría al servidor en cada
/// toque. La pantalla arma la clave cuando la persona aprieta buscar.
typedef FiltroNominaPermisos =
    ({
      int codEmpleado,
      int codRelEmplEmpr,
      String tipoPermiso,
      DateTime? desde,
      DateTime? hasta,
      DateTime? fecRango,
    });

/// La grilla del kardex (`p_list_Permiso 'Q'`).
final nominaPermisosProvider = FutureProvider.autoDispose
    .family<List<NominaPermisoEntity>, FiltroNominaPermisos>(
      (ref, f) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getNominaPermisos(
            f.codEmpleado,
            codRelEmplEmpr: f.codRelEmplEmpr,
            tipoPermiso: f.tipoPermiso,
            desde: f.desde,
            hasta: f.hasta,
            fecRango: f.fecRango,
          ),
    );

/// La clave del drill-down: la persona y qué tramo se abrió.
///
/// Record y no una clase: `family` compara por igualdad, y con un objeto sin
/// `==` cada rebuild pediría el detalle de nuevo.
typedef TramoAbierto = ({int codEmpleado, String clave});

/// Los permisos que suman un tramo del desglose (`'H'`, `'J'` o `'K'`).
final detalleTramoProvider = FutureProvider.autoDispose
    .family<List<NominaPermisoEntity>, TramoAbierto>(
      (ref, t) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getDetalleTramo(t.codEmpleado, t.clave),
    );

/// La clave del buscador de boletas: la ventana y el tipo.
typedef FiltroBoletas =
    ({DateTime? desde, DateTime? hasta, String tipoPermiso});

/// Las boletas emitidas en una ventana, de toda la empresa.
final boletasProvider = FutureProvider.autoDispose
    .family<List<NominaPermisoEntity>, FiltroBoletas>(
      (ref, f) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getBoletas(
            desde: f.desde,
            hasta: f.hasta,
            tipoPermiso: f.tipoPermiso,
          ),
    );

/// «Quién está fuera» hoy: los permisos que atrapan la fecha de hoy.
final quienEstaFueraHoyProvider =
    FutureProvider.autoDispose<List<NominaPermisoEntity>>(
      (ref) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getQuienEstaFuera(fecha: DateTime.now()),
    );

/// Quiénes salen en los próximos 30 días.
final quienSaleProntoProvider =
    FutureProvider.autoDispose<List<NominaPermisoEntity>>((ref) {
      final hoy = DateTime.now();
      return ref
          .watch(permisosRrhhRepositoryProvider)
          .getQuienEstaFuera(
            desde: hoy.add(const Duration(days: 1)),
            hasta: hoy.add(const Duration(days: 30)),
          );
    });

/// El mes elegido en la sección "Vacaciones y permisos del mes" del sheet de
/// Quién está fuera. `autoDispose` a propósito: el sheet se reconstruye
/// entero cada vez que se abre (`showModalBottomSheet`), así que no hace
/// falta recordar el mes de la vez anterior — arranca siempre en el actual.
final mesQuienEstaFueraProvider = StateProvider.autoDispose<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month, 1),
);

/// Todos los permisos/vacaciones de la empresa que caen en un mes dado —
/// mismo `getQuienEstaFuera` de arriba ("Hoy"/"próximos 30 días"), pero
/// acotado a los bordes del mes en vez de una ventana relativa a hoy. Sin
/// límite superior: un mes futuro es válido (vacaciones ya programadas).
final quienEstaFueraMesProvider = FutureProvider.autoDispose
    .family<List<NominaPermisoEntity>, DateTime>((ref, mes) {
      final desde = DateTime(mes.year, mes.month, 1);
      final hasta = DateTime(mes.year, mes.month + 1, 0); // último día del mes
      return ref
          .watch(permisosRrhhRepositoryProvider)
          .getQuienEstaFuera(desde: desde, hasta: hasta);
    });

/// La clave del desglose de días no hábiles: persona y rango.
typedef RangoDelPermiso = ({int codEmpleado, DateTime desde, DateTime hasta});

/// Los días del rango que NO descuentan, con su motivo. Es lo que deja
/// explicar la resta en la hoja de alta en vez de mostrar sólo el total.
final diasNoHabilesProvider = FutureProvider.autoDispose
    .family<List<DiaNoHabilEntity>, RangoDelPermiso>(
      (ref, r) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getDiasNoHabiles(r.codEmpleado, r.desde, r.hasta),
    );

/// La clave de «Buscar Vac Ganadas»: la persona y el rango de fechas. Ese botón
/// ignora el combo de tipo y la «Fecha Rango» (en el legacy solo usa Fecha Inicio
/// y Fecha Fin), así que la clave es más corta que la de la Nómina a propósito:
/// con la clave grande, cambiar el combo invalidaría una lista que no filtra.
typedef ClaveVacGanadas =
    ({int codEmpleado, int codRelEmplEmpr, DateTime? desde, DateTime? hasta});

/// «Buscar Vac Ganadas»: la segunda grilla de la pantalla («Nómina de Vacaciones
/// Asignadas»). Va a `/permisos/vacaciones-ganadas` (`p_list_vacacionAsignada
/// 'D'`, el mismo SP y ACCION del legacy). No recortar en memoria lo que trajo
/// [historialVacacionAsignadaProvider] (ACCION 'B'): parte de una fecha de corte
/// e inventa filas sintéticas por aniversario, así que filtrarlo con `where`
/// podía dar un conjunto distinto al del ERP y un 200 con la lista vacía.
final vacGanadasProvider = FutureProvider.autoDispose
    .family<List<VacacionAsignadaEntity>, ClaveVacGanadas>(
      (ref, k) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getVacacionesGanadas(
            k.codEmpleado,
            codRelEmplEmpr: k.codRelEmplEmpr,
            desde: k.desde,
            hasta: k.hasta,
          ),
    );

/// Los tipos del combo (`v_tipos` grupo 13). La clave es `incluirVacacionYPago`:
/// `false` da los 7 del modal de permiso (sin `vac` ni `pva`), `true` los 9 del
/// filtro de la Nómina. Se llama `...RrhhProvider` porque `tiposPermisoProvider`
/// ya lo usa el flujo del EMPLEADO (`permisos_vacacion_provider.dart`), que
/// filtra por `codEmpleado` + `codUsuarioLogueado`; aquí RR.HH. carga a nombre de
/// otro y la lista es otra.
final tiposPermisoRrhhProvider = FutureProvider.autoDispose
    .family<List<TipoPermisoVacacionEntity>, bool>(
      (ref, incluirVacacionYPago) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getTiposPermiso(incluirVacacionYPago: incluirVacacionYPago),
    );

// La simulación del permiso individual NO tiene provider: la dispara alguien al
// cambiar una fecha (con rebote), no la observa la pantalla. El modal la llama a
// mano; un `family` (empleado, desde, hasta) dejaría un provider vivo por prueba.

// La simulación de la vacación colectiva NO tiene provider, a propósito: su clave
// incluiría la lista de marcados y dos `List` iguales no son `==` en Dart, así que
// cada rebuild sería otra petición y otro provider vivo (como `RangoDeCalculo`,
// pero sin salida). La hoja la llama a mano contra el repositorio.

// ACCIONES

/// Las escrituras del módulo. Toda escritura invalida la ficha y el desglose, no
/// solo la lista (como el legacy: `saveVacAsign()` recarga saldo y ficha): un día
/// asignado cambia el saldo. Se relee siempre: los SP de escritura no devuelven el
/// id y un proceso automático inserta en `trh_vacacionAsignada` el día 1 de cada
/// mes a las 07:00. El error no se atrapa aquí: sube al widget, que decide cómo
/// mostrarlo (igual que `RolSabadosAcciones`).
class PermisosRrhhAcciones {
  final Ref _ref;
  PermisosRrhhAcciones(this._ref);

  PermisosRrhhRepository get _repo => _ref.read(permisosRrhhRepositoryProvider);

  /// Invalida lo que quedó viejo tras escribir: con `codEmpleado`, la ficha y el
  /// desglose de esa persona; sin él (carga colectiva) las dos familias enteras.
  /// Las dos listas siempre completas: su clave lleva la relación laboral, que
  /// quien escribió no siempre conoce. Público: la pantalla lo usa en «actualizar».
  void refrescar([int? codEmpleado]) {
    if (codEmpleado == null) {
      _ref.invalidate(fichaSaldoProvider);
      _ref.invalidate(desgloseSaldoProvider);
    } else {
      _ref.invalidate(fichaSaldoProvider(codEmpleado));
      _ref.invalidate(desgloseSaldoProvider(codEmpleado));
    }
    _ref.invalidate(historialVacacionAsignadaProvider);
    _ref.invalidate(detalleAbonosProvider);
    // El kardex se invalida entero: su clave lleva los cuatro filtros y quien escribió
    // no sabe con cuáles se mira la grilla. `vacGanadas` no hace falta nombrarlo:
    // deriva del historial y Riverpod lo recalcula solo.
    _ref.invalidate(nominaPermisosProvider);
  }

  /// Alta o edición de una vacación asignada. **Devuelve la fila releída**, lo que
  /// de verdad quedó guardado (el SP no devuelve el id y un proceso automático
  /// también escribe en esa tabla). [confirmado] solo en el reintento tras el aviso
  /// del 400 confirmable: la repetición es sospechosa pero legítima, no se bloquea.
  Future<VacacionAsignadaEntity> registrarVacacionAsignada(
    VacacionAsignadaEntity vacacion, {
    bool confirmado = false,
  }) async {
    final fila = await _repo.registrarVacacionAsignada(
      vacacion,
      confirmado: confirmado,
    );
    refrescar(vacacion.codEmpleado);
    return fila;
  }

  /// Baja de una vacación asignada. Devuelve el mensaje del servidor.
  Future<String> eliminarVacacionAsignada(
    VacacionAsignadaEntity vacacion,
  ) async {
    final msg = await _repo.eliminarVacacionAsignada(vacacion);
    refrescar(vacacion.codEmpleado);
    return msg;
  }

  /// Alta o edición de un abono de días. Devuelve la fila releída, igual que
  /// [registrarVacacionAsignada].
  Future<AbonoDiasEntity> registrarAbonoDias(
    AbonoDiasEntity abono, {
    bool confirmado = false,
  }) async {
    final fila = await _repo.registrarAbonoDias(abono, confirmado: confirmado);
    refrescar(abono.codEmpleado);
    return fila;
  }

  /// Baja de un abono de días. Devuelve el mensaje del servidor.
  Future<String> eliminarAbonoDias(AbonoDiasEntity abono) async {
    final msg = await _repo.eliminarAbonoDias(abono);
    refrescar(abono.codEmpleado);
    return msg;
  }

  /// Acredita los mismos días a varias personas, en una sola transacción.
  ///
  /// Refresca **todo el módulo**: los tocados son N y cualquiera de ellos puede
  /// estar abierto en otra pestaña.
  Future<String> aplicarAbonoColectivo({
    required List<int> codEmpleados,
    required double dias,
    required String motivo,
    required DateTime fecha,
  }) async {
    final msg = await _repo.aplicarAbonoColectivo(
      codEmpleados: codEmpleados,
      dias: dias,
      motivo: motivo,
      fecha: fecha,
    );
    refrescar();
    return msg;
  }

  /// Declara la vacación colectiva. Ver [aplicarAbonoColectivo] sobre el
  /// refresco.
  Future<String> aplicarVacacionColectiva({
    required List<int> codEmpleados,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async {
    final msg = await _repo.aplicarVacacionColectiva(
      codEmpleados: codEmpleados,
      desde: desde,
      hasta: hasta,
      motivo: motivo,
    );
    refrescar();
    return msg;
  }

  // ── El permiso individual ─────────────────────────────────────────────

  /// Programa un permiso a nombre del empleado («Registro de permisos»).
  /// [tipoPermiso] es uno de los 7 del combo (`baja`, `clb`, `def`, `libre`, `otro`,
  /// `pcr`, `sinsuel`); `'vac'` NO entra aquí (400: pide otro botón del ACL), para
  /// eso está [registrarVacacion]. Devuelve el mensaje del servidor: `p_abm_Permiso`
  /// no devuelve el id, así que lo guardado lo dice el kardex, que se refresca aquí.
  Future<String> registrarPermiso({
    required int codEmpleado,
    required String tipoPermiso,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async {
    final msg = await _repo.registrarPermiso(
      codEmpleado: codEmpleado,
      tipoPermiso: tipoPermiso,
      desde: desde,
      hasta: hasta,
      motivo: motivo,
    );
    refrescar(codEmpleado);
    return msg;
  }

  /// Programa una vacación individual («Registro de vacación individual»). Es otra
  /// ruta, no [registrarPermiso] con `'vac'`: mismo DAO e INSERT, pero otro botón
  /// del ACL ([btnProgramarVacacion], 5 usuarios contra 4) y el tipo lo pone el
  /// servidor. Mandar `'vac'` por la ruta del permiso da 400 (o 403 sin ese botón).
  Future<String> registrarVacacion({
    required int codEmpleado,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async {
    final msg = await _repo.registrarVacacion(
      codEmpleado: codEmpleado,
      desde: desde,
      hasta: hasta,
      motivo: motivo,
    );
    refrescar(codEmpleado);
    return msg;
  }

  /// Paga días de vacación («Pago de vacaciones», `tipoPermiso = 'pva'`). Es dinero
  /// y la única escritura donde una persona tipea los días (32 filas en 10 años,
  /// una de 247): confirmar en dos pasos con el saldo antes y después y bloquear
  /// el reenvío mientras la llamada está en vuelo. El refresco muestra el saldo nuevo.
  Future<String> registrarVacacionPagada({
    required int codEmpleado,
    required DateTime fecha,
    required double dias,
    required String motivo,
    bool confirmado = false,
  }) async {
    final msg = await _repo.registrarVacacionPagada(
      codEmpleado: codEmpleado,
      fecha: fecha,
      dias: dias,
      motivo: motivo,
      confirmado: confirmado,
    );
    refrescar(codEmpleado);
    return msg;
  }
}

final permisosRrhhAccionesProvider = Provider<PermisosRrhhAcciones>(
  (ref) => PermisosRrhhAcciones(ref),
);
