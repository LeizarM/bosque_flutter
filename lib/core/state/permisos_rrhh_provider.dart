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

/// El repositorio del módulo.
///
/// **Se declara acá y no en `main.dart`.** El `ProviderScope` de `main.dart` ya
/// no tiene `overrides`: los registrados ahí construían su repo —y con él todo
/// el cliente Dio— antes del primer frame, para todos los usuarios, entraran o
/// no al módulo. Así se fabrica solo y de forma perezosa. (El `CLAUDE.md` que
/// manda registrarlo en `main.dart` está desactualizado; ver `main.dart:45`.)
final permisosRrhhRepositoryProvider = Provider<PermisosRrhhRepository>(
  (ref) => PermisosRrhhImpl(),
);

// ═══════════════════════════════════════════════════════════════════════════
// AUTORIZACIÓN (SUPUESTO D4 — pendiente de confirmación de RR.HH., ver plan §5)
// ═══════════════════════════════════════════════════════════════════════════
//
// Van acá y no en `permisos_rrhh_comunes.dart`: en el Rol de Sábados la decisión
// de permiso vive entera en el provider del módulo (`administraRolProvider`,
// `permisoDeCeldaProvider`) y el archivo de piezas no sabe nada de ACL. Allá el
// gate es un `Provider<bool>` propio; acá el ACL es el de `tb_vistaBtn`, así que
// lo que queda es la constante con el nombre real del botón.

/// El botón del ACL (`tb_vistaBtn` / `tb_usuarioBtn`) que habilita la consulta
/// de saldo dentro de la vista 24.
///
/// **Esconder no es autorizar.** El gate de verdad está en el backend, que
/// resuelve la identidad desde el token (`Authentication`) y no desde el body;
/// esto es sólo para no ofrecer una pantalla que va a devolver 403.
///
/// **Ojo con los usuarios `lim`.** `tienePermiso` le dice que sí a cualquiera
/// con `tipoUsuario == 'ROLE_ADM'` sin mirar la tabla; el resto —`rramos`, por
/// ejemplo— necesita su fila real en `tb_usuarioBtn` o el módulo se le esconde
/// entero.
const String btnConsultaSaldo = 'btnDetalles';

/// El botón del ACL que habilita la **calculadora de antigüedad**.
///
/// **Son dos permisos distintos, no uno.** El backend exige `btnApoyoCalc` en
/// `/permiso-rrhh/herramientas/calculo-antiguedad` y `btnDetalles` en los otros
/// dos endpoints, y los dos padrones no coinciden: medido contra `BOSQUE-2_0`
/// con `nivelAcceso != 0`, `btnDetalles` lo tienen 5 usuarios y `btnApoyoCalc`
/// 6. Esconder las tres pestañas detrás de una sola constante dejaba a quien
/// tuviera `btnDetalles` sin `btnApoyoCalc` eligiendo dos fechas para recibir un
/// 403 — el callejón sin salida que este gate existe para evitar.
///
/// Si RR.HH. confirma que quiere un permiso único, el que cambia es el backend
/// (`PermisoRrhhController` línea del `exigirBoton` de la calculadora), no esto.
const String btnCalculadora = 'btnApoyoCalc';

/// El botón del ACL que habilita **bajar la boleta** de un permiso en PDF.
///
/// Es el mismo que exige el backend en `/vacacion/RptPermisoVacacion`
/// (codBtn 109, 6 usuarios con `nivelAcceso != 0`). Ahí el gate tiene tres
/// puertas —este botón, o que la boleta sea propia, o que el empleado esté en
/// el subárbol de cargos de quien pide—, así que esconderlo acá sólo evita el
/// 403: **quién puede bajar qué lo decide el servidor**.
const String btnBoleta = 'btnReImprimirBoleta';

/// El botón del ACL de los **reportes de saldos** (codBtn 210, 4 usuarios).
/// Es el mismo que el backend exige en `/permiso-rrhh/reportes/*`.
const String btnReportes = 'btnReportesPYV';

/// El botón del ACL de la **ABM de vacación asignada** (alta y edición).
///
/// ## ⚠ PLACEHOLDER — este botón es prestado, no es el suyo
///
/// El legacy gobierna esta ABM con `btnEditNewVacAsigAntesDos`, y **ese nombre
/// no existe en `tb_vistaBtn`**: verificado contra `BOSQUE-2_0`, no está en la
/// vista 24 ni en ninguna otra, ni en `tb_vistaBtnEliminado`. Vive sólo en el
/// `permiso.xhtml`, donde `Loggin.autorizarBtn` no lo encuentra, devuelve
/// permiso 0 y cae en el fallback de administrador.
///
/// Por eso esta constante estrena **nombre propio**, que tampoco existe todavía
/// en la tabla, y eso es deliberado: mientras no exista, `tienePermiso` sólo
/// deja pasar a los `ROLE_ADM` y esconde el botón para el resto. **Cerrado por
/// omisión**, que es lo correcto para un alta que vale 15 a 30 días pagados.
///
/// Antes apuntaba a `btnEditVacAntPenult` (codBtn 117) como parche para que los
/// `lim` no vieran un botón que devolvía 403. Estaba mal: ese botón en el legacy
/// autoriza «editar el permiso ya gozado», así que reusarlo le daba alta y
/// edición de vacación asignada a los 5 usuarios que lo tienen, y que **no**
/// tienen esa atribución.
///
/// **Es el mismo literal que usa el backend** (`BTN_VACACION_ASIGNADA` en
/// `PermisoRrhhController`): cliente y servidor tienen que decir lo mismo o el
/// módulo esconde lo que el servidor deja pasar, y al revés.
///
/// **Para abrirlo a RR.HH.:** correr `sql/04_botones_vacacion_asignada.sql` y
/// después subir el `nivelAcceso` desde la pantalla de permisos. No hay que
/// tocar esta línea.
const String btnVacacionAsignada = 'btnNuevaVacAsignada';

/// El botón del ACL de la **baja** de una vacación asignada.
///
/// **Botón propio, ya no un alias del alta.** Borrar no es lo mismo que cargar:
/// en el legacy el botón Eliminar está con `rendered="false"`, o sea que hoy no
/// lo ejecuta nadie, y traerlo no es migrar sino habilitar. Los dos nombres se
/// crean juntos en el mismo script, así que separarlos no cuesta nada y permite
/// que la baja quede en menos manos que el alta sin tocar código.
const String btnVacacionAsignadaBaja = 'btnEliminarVacAsignada';

/// El botón del ACL del **abono de días individual** (`codBtn` 119, «Editar
/// Abono Dias»): 5 usuarios con `nivelAcceso != 0`.
///
/// Cubre también el alta: en el legacy el alta no tiene botón propio, se abre
/// desde el mismo modal.
const String btnAbonoDias = 'btnEditarAbonoDia';

/// El botón del ACL del **abono de días colectivo** (`codBtn` 107): 4 usuarios,
/// todos `lim`. `jmonrroy` **no lo tiene** y entra sólo por el fallback de
/// administrador — o sea que el padrón real de esta carga son cuatro personas.
const String btnAbonoGrupal = 'btnNuevoAbonoGrupal';

/// El botón del ACL de la **vacación colectiva** (`codBtn` 108): 5 usuarios.
const String btnVacacionGrupal = 'btnNuevaVacGrupal';

/// El botón del ACL de **«Programar permiso»** (`codBtn` 112).
///
/// **Son 4 usuarios, uno menos que los otros dos de esta tanda.** Por eso es
/// una constante propia y no se comparte con [btnProgramarVacacion]: esconder
/// las tres operaciones detrás de un solo nombre le concedería a una persona
/// una atribución que hoy no tiene.
const String btnProgramarPermiso = 'btnProgramarPermiso';

/// El botón del ACL de **«Programar vacación»** (`codBtn` 113): 5 usuarios.
const String btnProgramarVacacion = 'btnProgramarVacacion';

/// El botón del ACL de **«Vacación pagada»** (PVA).
///
/// **Está DUPLICADO en `tb_vistaBtn`** —`codBtn` 110 y 114, 5 usuarios cada
/// uno—. `AccesoModuloHelper.tieneBoton` usa `anyMatch` y lo tolera, así que
/// del lado del cliente no hay nada que hacer; lo que hay que saber es que si
/// los dos padrones no son el mismo conjunto de personas, **el permiso efectivo
/// es la unión de los dos**. Vale confirmarlo con RR.HH. antes de habilitar
/// días pagados.
const String btnVacacionPagada = 'btnNuevaVacPagada';

/// El empleado que se está mirando.
///
/// **Global y no estado local del widget** a propósito: los providers de abajo
/// son `autoDispose`, así que salir del módulo y volver reconstruye la vista, y
/// un `setState` guardado en la pantalla se habría perdido. Acá el módulo
/// vuelve mostrando a la misma persona.
final empleadoSeleccionadoProvider = StateProvider<EmpleadoEntity?>(
  (ref) => null,
);

/// Texto tipeado en el buscador, **ya con el rebote aplicado**: lo escribe el
/// campo recién cuando la persona dejó de tipear (ver `buscador_empleado.dart`).
/// Escribirlo en cada tecla dispararía una consulta por letra.
final busquedaEmpleadoProvider = StateProvider<String>((ref) => '');

/// Empresa por la que se filtra la búsqueda. 0 = todas.
///
/// Los tres `StateProvider` de este archivo **no son `autoDispose` a
/// propósito**, al revés que los `FutureProvider`: son estado de interfaz y se
/// perderían en cada vuelta al módulo.
final filtroEmpresaProvider = StateProvider<int>((ref) => 0);

/// Si la búsqueda trae sólo a los empleados activos.
///
/// Arranca en `true`: la consola es para resolver el saldo de quien trabaja hoy.
/// Alguien dado de baja se busca a propósito, no por accidente.
final filtroSoloActivosProvider = StateProvider<bool>((ref) => true);

/// Resultado del buscador (`p_list_Empleado 'Y'`, vía `/rrhh/obtenerLstEmpleados`).
///
/// **No es un `family`**: los tres filtros son estado global del módulo, así que
/// se leen con `watch` y Riverpod rearma la búsqueda cuando cambia cualquiera.
/// Un `family` acá pediría una clave, y la clave sería justamente esos tres.
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

/// Ficha de saldo del empleado `cod` (`ACCION 'C'`).
///
/// `family` con un `int`: dos `int` iguales son el mismo parámetro, así que
/// Riverpod cachea. Un rebuild no vuelve a pegarle al backend — que es lo que
/// hacía el getter del JSF que este módulo reemplaza, en cada render.
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

/// El rango de la calculadora de antigüedad.
///
/// **Es un record y no una clase ni una Entity**, y no es un detalle: la clave
/// de un `family` se compara con `==`. Un objeto sin `==`/`hashCode` es una
/// clave nueva en cada rebuild, así que cada rebuild dispararía otra petición y
/// dejaría otro provider vivo — un bucle. Los records tienen igualdad
/// estructural de fábrica. (Hay un caso latente de esto en
/// `previsualizarSaldoProvider`, que usa una Entity como parámetro.)
typedef RangoDeCalculo = ({DateTime desde, DateTime hasta});

/// La frase en prosa del SP para un rango simulado (`ACCION 'U'`).
///
/// Es **orientativa**: la función cuenta años enteros con un `WHILE` y no es el
/// mismo algoritmo que calcula el saldo real. Además da «= 0 dias por
/// antiguedad» en el aniversario exacto y cuando las dos fechas caen en el mismo
/// mes; la pantalla detecta esa subcadena y avisa.
final calculoAntiguedadProvider = FutureProvider.autoDispose
    .family<String, RangoDeCalculo>(
      (ref, r) => ref
          .watch(permisosRrhhRepositoryProvider)
          .calcularAntiguedad(desde: r.desde, hasta: r.hasta),
    );

/// Empleado + relación laboral: la clave de todo lo que se lee de una persona.
///
/// **Son las dos cosas y no sólo el empleado.** Las lecturas del legacy filtran
/// por `codEmpleado` **y** `codRelEmplEmpr` (`p_list_vacacionAsignada 'B'`,
/// `p_list_AbonoDias 'B'`), porque el saldo es de la relación vigente: la misma
/// persona en dos contratos tiene dos historias distintas y sumarlas daría un
/// número que no es el de nadie. `codRelEmplEmpr` en 0 = «la vigente, resolvela
/// vos», que es lo que sabe la pantalla antes de tener la ficha.
///
/// Es un **record** por lo mismo que [RangoDeCalculo]: la clave de un `family`
/// se compara con `==`, y un objeto sin igualdad estructural sería una clave
/// nueva por rebuild — una petición por frame.
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

// ═══════════════════════════════════════════════════════════════════════════
// NÓMINA DE PERMISOS (el kardex) Y SUS FILTROS
// ═══════════════════════════════════════════════════════════════════════════

/// El combo de tipo de la Nómina. **Vacío = «Todos»**, que es lo que el DAO del
/// legacy traduce a `@tipoPermiso = NULL`.
///
/// `StateProvider` y no `autoDispose`, igual que los otros filtros del módulo:
/// es estado de interfaz y se perdería en cada vuelta.
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
/// el nombre de acá dice fecha y no rango.
final filtroFechaRangoProvider = StateProvider<DateTime?>((ref) => null);

/// La clave de la Nómina: la persona, su relación laboral y los tres filtros.
///
/// **Es un record por lo mismo que [RangoDeCalculo]**: la clave de un `family`
/// se compara con `==` y un objeto sin igualdad estructural sería una clave
/// nueva por rebuild, o sea una petición por frame.
///
/// **Es `family` y no un provider que observe los filtros** —al revés que
/// [empleadosBuscadosProvider]— porque en el legacy la consulta la dispara un
/// botón («Buscar Permisos»), no cada tecla: con `watch` sobre cuatro filtros,
/// elegir una fecha en el calendario pegaría un viaje al servidor por cada
/// toque. La pantalla arma la clave cuando la persona aprieta buscar.
typedef FiltroNominaPermisos = ({
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
typedef FiltroBoletas = ({DateTime? desde, DateTime? hasta, String tipoPermiso});

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

/// La clave de «Buscar Vac Ganadas»: la persona y el rango de fechas.
///
/// **Ese botón ignora el combo de tipo y la «Fecha Rango»** —en el legacy sólo
/// usa Fecha Inicio y Fecha Fin—, así que la clave es más corta que la de la
/// Nómina a propósito. Con la clave grande, cambiar el combo invalidaría una
/// lista que el combo no filtra.
typedef ClaveVacGanadas = ({
  int codEmpleado,
  int codRelEmplEmpr,
  DateTime? desde,
  DateTime? hasta,
});

/// «Buscar Vac Ganadas»: la segunda grilla de la pantalla («Nómina de
/// Vacaciones Asignadas»).
///
/// **Va a `/permisos/vacaciones-ganadas`, que es `p_list_vacacionAsignada 'D'`:
/// el mismo SP y la misma ACCION que el botón del legacy.** No se recorta en
/// memoria lo que trajo [historialVacacionAsignadaProvider], que es la ACCION
/// 'B': aquella se pide con una fecha de corte —o sea que el conjunto de
/// partida ya viene recortado por otra cosa— y además **inventa** filas
/// sintéticas por aniversario para ofrecer el «Nuevo» de su grilla. Filtrar eso
/// con un `where` de Dart devolvía un conjunto que podía no ser el del ERP, sin
/// que nada avisara: un 200 con la lista vacía.
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

/// Los tipos del combo (`v_tipos` grupo 13). La clave es
/// `incluirVacacionYPago`: `false` da los 7 del modal de permiso (sin `vac` ni
/// `pva`), `true` los 9 del filtro de la Nómina.
///
/// **Se llama `...RrhhProvider` y no `tiposPermisoProvider` porque ese nombre
/// ya está tomado** por el flujo del EMPLEADO
/// (`permisos_vacacion_provider.dart`), que filtra por `codEmpleado` +
/// `codUsuarioLogueado` — los tipos que ESA persona puede pedirse—. Acá RR.HH.
/// carga a nombre de otro, así que la lista es otra. Dos nombres iguales en un
/// mismo widget serían un `import as` y un error esperando.
final tiposPermisoRrhhProvider = FutureProvider.autoDispose
    .family<List<TipoPermisoVacacionEntity>, bool>(
      (ref, incluirVacacionYPago) => ref
          .watch(permisosRrhhRepositoryProvider)
          .getTiposPermiso(incluirVacacionYPago: incluirVacacionYPago),
    );

// **La simulación del permiso individual NO tiene provider**, por lo mismo que
// la colectiva: simular es algo que alguien dispara al cambiar una fecha —con
// su rebote—, no algo que la pantalla observa. El modal la llama a mano contra
// el repositorio y se guarda el resultado en su propio estado; un `family` con
// (empleado, desde, hasta) dejaría un provider vivo por cada media hora que
// alguien pruebe en el selector.

// **La simulación de la vacación colectiva NO tiene provider, y no es un
// olvido.** Su clave incluiría la lista de empleados tildados, y en Dart dos
// `List` con el mismo contenido no son `==`: cada rebuild sería una clave nueva,
// o sea otra petición y otro provider vivo. Es exactamente la trampa que
// documenta `RangoDeCalculo`, pero sin salida —no se puede hacer estructural una
// lista—. La hoja de la carga colectiva la llama a mano contra el repositorio y
// se guarda el resultado en su propio estado, que además es lo que corresponde:
// simular es algo que alguien aprieta, no algo que la pantalla observa.

// ═══════════════════════════════════════════════════════════════════════════
// ACCIONES
// ═══════════════════════════════════════════════════════════════════════════

/// Las escrituras del módulo, todas juntas.
///
/// **Toda escritura invalida la ficha y el desglose, no sólo la lista.** Es lo
/// que hace el legacy —`saveVacAsign()` llama a `cargarSaldoPenultVac()` **y** a
/// `cargarRegSaldoEmpl()`— y con razón: un día asignado cambia el saldo, y dejar
/// la cifra vieja en pantalla mientras la grilla ya muestra la fila nueva es la
/// forma más barata de que alguien cargue el mismo día dos veces.
///
/// **Y se relee siempre, aunque parezca de más.** Los SP de escritura no
/// devuelven el id generado, así que el estado de después sólo se conoce
/// preguntando; y esta pantalla no es la única que escribe: un proceso
/// automático inserta en `trh_vacacionAsignada` el día 1 de cada mes a las 07:00
/// y ya dejó filas fechadas en 2026. Nada de cachear como si la tabla fuera
/// nuestra.
///
/// **El error no se atrapa acá**: sube al widget, que es el único que puede
/// decidir si lo muestra en la hoja, en un aviso o cerrando el modal. Igual que
/// en `RolSabadosAcciones`.
class PermisosRrhhAcciones {
  final Ref _ref;
  PermisosRrhhAcciones(this._ref);

  PermisosRrhhRepository get _repo => _ref.read(permisosRrhhRepositoryProvider);

  /// Tira todo lo que quedó viejo después de escribir.
  ///
  /// Con `codEmpleado` invalida la ficha y el desglose de esa persona; sin él
  /// —una carga colectiva, donde los tocados son N— invalida las dos familias
  /// enteras, que es lo que hace `Ref.invalidate` cuando se le pasa la familia
  /// en vez de una instancia.
  ///
  /// Las dos listas se invalidan siempre completas: su clave lleva la relación
  /// laboral, y quien acaba de escribir no siempre sabe con cuál se pidió.
  ///
  /// **Es el `_recargar` que hoy vive en `permisos_rrhh_screen.dart`**, mudado
  /// acá como su propio comentario pedía. Público porque la pantalla también lo
  /// usa para su «actualizar» a mano.
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
    // El kardex se invalida entero: su clave lleva los cuatro filtros, y quien
    // acaba de escribir no sabe con cuáles está mirando la grilla. `vacGanadas`
    // no hace falta nombrarlo —deriva del historial, así que Riverpod lo
    // recalcula solo cuando aquel se invalida—.
    _ref.invalidate(nominaPermisosProvider);
  }

  /// Alta o edición de una vacación asignada. **Devuelve la fila releída**, que
  /// es lo que de verdad quedó guardado: el SP no devuelve el id generado y en
  /// esa tabla escribe además un proceso automático.
  ///
  /// [confirmado] sólo en el reintento, después de que la persona haya leído el
  /// aviso del 400 confirmable: en esta tabla la repetición es sospechosa pero
  /// legítima, así que se advierte y no se bloquea.
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
  ///
  /// [tipoPermiso] es uno de los 7 del combo —`baja`, `clb`, `def`, `libre`,
  /// `otro`, `pcr`, `sinsuel`—; **`'vac'` no entra por acá**: el servidor lo
  /// rechaza con un 400 porque la vacación pide otro botón del ACL. Es
  /// [registrarVacacion].
  ///
  /// Devuelve el mensaje del servidor: `p_abm_Permiso` no devuelve el id
  /// generado, así que no hay fila que releer con certeza. Lo que quedó
  /// guardado lo dice el kardex, que se refresca acá.
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

  /// Programa una vacación individual («Registro de vacación individual»).
  ///
  /// **Es otra ruta, no [registrarPermiso] con `'vac'`.** Del otro lado es el
  /// mismo DAO y el mismo INSERT, pero con otro botón del ACL
  /// ([btnProgramarVacacion], 5 usuarios contra 4) y con el tipo puesto por el
  /// servidor. Mandar `'vac'` por la ruta del permiso da un 400 —y, para quien
  /// tiene el botón de vacación y no el de permiso, un 403 después de haber
  /// llenado el formulario.
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

  /// Paga días de vacación («Pago de vacaciones», `tipoPermiso = 'pva'`).
  ///
  /// **Esto es plata**, y es la única escritura del módulo donde los días los
  /// tipea una persona y no los calcula nadie: 32 filas en 10 años, una de
  /// ellas de 247 días. La pantalla tiene que confirmar en dos pasos diciendo
  /// el saldo antes y después, y bloquear el reenvío mientras la llamada está
  /// en vuelo — un doble toque acá cuesta dinero.
  ///
  /// El refresco de la ficha no es decorativo: es lo que muestra el saldo nuevo
  /// inmediatamente después, que es la única forma de que quien pagó vea lo que
  /// hizo.
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
