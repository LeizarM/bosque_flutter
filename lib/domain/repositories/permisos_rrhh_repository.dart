import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';
import 'package:bosque_flutter/domain/entities/desglose_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/dia_no_habil_entity.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/simulacion_colectiva_entity.dart';
import 'package:bosque_flutter/domain/entities/simulacion_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';

/// Contrato del módulo Permisos RR.HH.: la consola de RR.HH. sobre `trh_permiso`.
///
/// Todo pasa por `/permiso-rrhh` —salvo el buscador, que reutiliza `/rrhh`— y
/// todo es POST, incluidas las lecturas, que es la convención de esta API.
///
/// **No confundir con `PermisosVacacionRepository`**, que es el flujo del
/// EMPLEADO (pide su permiso, ve sus días). Esto es lo que usa RR.HH. para
/// mirar —y desde la Fase 2, corregir— a cualquier empleado.
///
/// **Las escrituras de acá mueven dinero.** Una vacación asignada vale 15 a 30
/// días pagados y un abono son días libres cobrados. Toda escritura pasa por una
/// confirmación explícita en la pantalla, dice a cuántas personas alcanza, y es
/// recuperable: los triggers `dad_` archivan la fila antes de borrarla.
///
/// **La identidad de quien consulta no viaja en ningún parámetro** (D4): el
/// backend la saca del token y contra eso resuelve el ACL. Un `codUsuario` en
/// el body sería un permiso que se puede escribir a mano.
/// El backend rechazó la escritura porque es **inusual**, no porque esté mal:
/// un monto fuera del rango histórico, o un aniversario que ya tiene registro.
/// Se resuelve reintentando **con `confirmado: true`**.
///
/// **Cómo se reconoce, y por qué importa el detalle.** Es un **400 con
/// `confirmable: true` en el cuerpo**, no un 409. Los dos status significan
/// cosas opuestas y hasta agosto de 2026 el cliente los tenía al revés:
///
/// | status | qué es | qué hace la pantalla |
/// |--------|--------|----------------------|
/// | 400 + `confirmable` | repetición legítima o monto raro | avisa y ofrece insistir |
/// | 409 | doble toque / carrera con otro usuario | avisa, recarga la grilla, **sin** reintento |
///
/// El 409 no se arregla insistiendo: el segundo toque manda exactamente el
/// mismo cuerpo, confirmación incluida, y el backend lo vuelve a rechazar. Por
/// eso no llega como este tipo.
///
/// **Existe porque el duplicado acá no se puede bloquear.** Hay 215 grupos con
/// la misma `(codEmpleado, codRelEmplEmpr, fecha)` en `trh_vacacionAsignada`,
/// casi todos del proceso automático que escribe el día 1 de cada mes:
/// rechazarlos sería rechazar datos que el ERP ya da por buenos.
///
/// Es un tipo propio y no un `Exception` cualquiera porque la pantalla tiene
/// que **distinguirlo**: los demás errores se muestran y ahí termina; éste
/// ofrece seguir. El `toString` devuelve el mensaje pelado para que, si alguien
/// lo trata como al resto, igual se lea bien.
class RequiereConfirmacion implements Exception {
  const RequiereConfirmacion(this.mensaje);

  /// El texto del servidor, ya redactado para quien lo lee.
  final String mensaje;

  @override
  String toString() => mensaje;
}

abstract class PermisosRrhhRepository {
  // ── lecturas ──────────────────────────────────────────────────────────

  /// La puerta de entrada del módulo: buscar a la persona. `codEmpresa` en 0 =
  /// sin filtrar.
  ///
  /// **Reutiliza `POST /rrhh/obtenerLstEmpleados`** (`p_list_Empleado 'Y'`), que
  /// ya pagina en SQL y filtra por nombre, estado y empresa. No se crea un
  /// endpoint nuevo.
  ///
  /// **Por qué no se llama a `RegistroEmpleadoImpl.getLstEmpleados`, que hace
  /// exactamente esto.** Ese método envuelve todo en un `try/catch` que devuelve
  /// `[]` ante cualquier excepción: un 403 —el caso de D4, alguien sin el botón
  /// del ACL— se vería en pantalla como «no hay empleados», y quien lo mire va a
  /// ir a buscar el problema al lugar equivocado. Acá el error sube y la
  /// pantalla lo dice.
  ///
  /// **No lleva `get` a propósito**: el verbo dice que hay un texto que filtra,
  /// que es lo que `get` borraría (mismo caso que `previsualizarDependientes`).
  Future<List<EmpleadoEntity>> buscarEmpleados(
    String texto, {
    bool soloActivos = true,
    int codEmpresa = 0,
    int pagina = 1,
    int porPagina = 50,
  });

  /// Ficha resumen de un empleado (`ACCION 'C'`).
  ///
  /// `null` cuando el backend contesta 204: consulta correcta, sin filas.
  /// Los casos que sí tienen explicación —empleado inexistente, sin relación
  /// activa, sin cargo, o con más de una relación activa— llegan como
  /// excepción con el mensaje del backend adentro, listo para `avisar`.
  Future<FichaSaldoEntity?> getFichaSaldo(int codEmpleado);

  /// Desglose en 5 tramos (`ACCION 'D'`). `null` en 204.
  Future<DesgloseSaldoEntity?> getDesgloseSaldo(int codEmpleado);

  /// Calculadora de antigüedad (`ACCION 'U'`).
  ///
  /// Devuelve **la frase del SP tal cual**, en prosa: «Trabajo 11 año(s) 5
  /// mes(es) y 10 dia(s) y le corresponden = 30 dias por antiguedad…».
  /// **No se parsea**: su algoritmo no es el mismo que el del saldo real y el
  /// número que dice es orientativo. Cadena vacía si no vino nada.
  Future<String> calcularAntiguedad({
    required DateTime desde,
    required DateTime hasta,
  });

  /// El historial de vacación asignada de una relación laboral
  /// (`p_list_vacacionAsignada 'B'`): una fila por aniversario, mezclando las
  /// reales con las **sintéticas** (`codVacacionAsignada = 0`) de los
  /// aniversarios que todavía no tienen registro. De ahí sale el «Nuevo» de la
  /// grilla: no es un botón suelto.
  ///
  /// `hasta` acota hasta qué aniversario se rellena; sin ella, hoy.
  Future<List<VacacionAsignadaEntity>> getHistorialVacacionAsignada(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    DateTime? hasta,
  });

  /// El detalle de abonos de una relación laboral (`p_list_AbonoDias`), con
  /// `fila` y `totalDias` ya calculados.
  Future<List<AbonoDiasEntity>> getDetalleAbonos(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
  });

  // ── escrituras ────────────────────────────────────────────────────────
  //
  // **Sin `audUsuario`**, al revés de lo que decía el hueco que había acá: D4
  // vale también para las escrituras, y con más razón. La identidad sale del
  // token; un `audUsuario` en el cuerpo sería una firma que se puede tipear.
  //
  // **Ninguno de los tres SP de escritura devuelve envelope de error, id
  // generado ni transacción**, así que todo lo que estos métodos prometen lo
  // sostiene Java, no la base. Lo que llega acá ya viene resuelto del otro lado.

  /// Da de alta o edita una vacación asignada. **La acción la decide el id**
  /// (`codVacacionAsignada == 0` → alta), igual que el legacy.
  ///
  /// **Devuelve la fila releída, no un id.** El SP no devuelve
  /// `SCOPE_IDENTITY`, así que el backend relee y contesta la fila entera; con
  /// ella la hoja puede mostrar lo que de verdad quedó guardado y no lo que se
  /// tipeó. (Hasta agosto de 2026 el cliente leía ese objeto como si fuera un
  /// número y reventaba en el `BigInt.from`.)
  ///
  /// **`confirmado` no es una comodidad.** Sin él, el backend rechaza con
  /// **400 + `confirmable: true`** lo inusual —un monto fuera del rango
  /// histórico, un aniversario que ya tiene registro—; la pantalla muestra el
  /// aviso y sólo entonces reintenta en `true`. Ver [RequiereConfirmacion], y
  /// ojo con el 409, que es lo contrario y no se reintenta.
  Future<VacacionAsignadaEntity> registrarVacacionAsignada(
    VacacionAsignadaEntity vacacion, {
    bool confirmado = false,
  });

  /// Borra una vacación asignada (`ACCION 'D'`).
  ///
  /// **Es un DELETE físico**, pero el trigger `dad_vacacionAsignada` copia la
  /// fila entera a `trh_vacacionAsignadaEliminado` antes de que desaparezca:
  /// Sistemas puede recuperarla. Devuelve el mensaje del servidor.
  ///
  /// **Es una operación que hoy nadie puede ejecutar**: en el legacy el botón
  /// Eliminar está con `rendered="false"`. Traerla no es migrar, es habilitar.
  Future<String> eliminarVacacionAsignada(VacacionAsignadaEntity vacacion);

  /// Da de alta o edita un abono de días. Mismas reglas de id, de relectura y
  /// de [confirmado] que [registrarVacacionAsignada].
  ///
  /// **El duplicado exacto y reciente sí se bloquea duro** (409, y ahí no hay
  /// reintento que valga): en `trh_abonoDias` no hay ni un duplicado exacto en
  /// 184 filas, así que un segundo idéntico a segundos del primero es un doble
  /// toque. Lo que sí es confirmable —400 con `confirmable`— es otro abono del
  /// mismo día con distinto monto o motivo, y un monto fuera del rango
  /// histórico.
  Future<AbonoDiasEntity> registrarAbonoDias(
    AbonoDiasEntity abono, {
    bool confirmado = false,
  });

  /// Borra un abono de días (`ACCION 'D'`, archivado por `dad_abonoDias`).
  ///
  /// **No se copia el `eliminarAbonDia()` del legacy**, que llama a `registrar()`
  /// y termina mandando una 'U' con todo en NULL: código que parece que borra y
  /// no borra.
  Future<String> eliminarAbonoDias(AbonoDiasEntity abono);

  // ── cargas colectivas ─────────────────────────────────────────────────

  /// El padrón para tildar: todos los empleados con relación laboral activa
  /// (`p_list_Permiso 'E'`). `codEmpresa` en 0 = sin filtrar.
  Future<List<SimulacionColectivaEntity>> getEmpleadosParaColectiva({
    int codEmpresa = 0,
  });

  /// A quiénes les entraría el abono colectivo y a quiénes no. **No escribe
  /// nada.**
  ///
  /// **Los días son uno solo para todos y aun así hay que preguntar.** Lo que
  /// el cliente no sabe es quién tiene relación laboral activa, quién tiene más
  /// de una, y quién ya cobró un abono ese mismo día: eso sale de la base y por
  /// eso el paso de confirmación se arma con esto y no con la lista tildada. Sin
  /// esta llamada la pantalla decía «3 días a 40 empleados» sin saber a cuántos
  /// alcanzaba de verdad.
  ///
  /// El cuerpo es el mismo que el de [aplicarAbonoColectivo]: si los dos no
  /// describen exactamente el mismo lote, la confirmación estaría hablando de
  /// otra cosa que la que se guarda.
  Future<List<SimulacionColectivaEntity>> simularAbonoColectivo({
    required List<int> codEmpleados,
    required double dias,
    required String motivo,
    required DateTime fecha,
  });

  /// Acredita los mismos días a varias personas, **todo o nada**.
  ///
  /// El legacy no es transaccional: cuenta los fallos y deja cargados a los que
  /// sí entraron. Acá va en una transacción de Java, así que el mensaje de error
  /// también cambia — si algo falla **no se guardó ninguno**, y eso es lo que
  /// tiene que decir. Copiar el texto viejo con la semántica nueva sería mentir.
  ///
  /// Viajan sólo los `codEmpleado`: la relación laboral de cada uno la resuelve
  /// el servidor.
  ///
  /// El parámetro se llama `dias` y no `diasAbonados` porque así se llama el
  /// campo del otro lado (`PermisoRrhhEscrituraDto.dias`): un nombre por
  /// concepto, para que no vuelva a haber dos.
  Future<String> aplicarAbonoColectivo({
    required List<int> codEmpleados,
    required double dias,
    required String motivo,
    required DateTime fecha,
  });

  /// Cuántos días le tocaría a cada uno si se declara la vacación colectiva.
  /// **No escribe nada.**
  ///
  /// Existe porque el número del cabezal no es el que se graba: los feriados son
  /// por sucursal y cada persona puede terminar con un total distinto. Ver
  /// [SimulacionColectivaEntity].
  Future<List<SimulacionColectivaEntity>> simularVacacionColectiva({
    required List<int> codEmpleados,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  });

  /// Declara la vacación colectiva: una fila en `trh_permiso` por persona, con
  /// `tipoPermiso = 'vac'`, **todo o nada**.
  ///
  /// **No escribe en `trh_vacacionAsignada`.** Es una vacación *gozada* (haber),
  /// no una asignación (debe): descuenta saldo en vez de darlo. El autorizador
  /// es quien la lanza, y sale del token.
  Future<String> aplicarVacacionColectiva({
    required List<int> codEmpleados,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  });

  // ── El permiso individual ─────────────────────────────────────────────

  /// La **Nómina de Permisos**: el kardex de `trh_permiso` de una persona
  /// (`p_list_Permiso 'Q'`).
  ///
  /// Todos los filtros son opcionales y se combinan con AND, con la semántica
  /// exacta del SP —que no es la que sugieren los rótulos—:
  ///
  /// * [tipoPermiso] vacío = todos (el SP lo recibe en NULL).
  /// * [desde] compara contra el **inicio** del permiso (`CONVERT(date, tp.desde) >= @desde`).
  /// * [hasta] compara contra el **fin** (`CONVERT(date, tp.hasta) <= @hasta`).
  /// * [fecRango] es «**quién estaba de permiso el día X**»: el rango del
  ///   permiso tiene que atrapar esa fecha, no al revés. Es el filtro que el
  ///   legacy llama «Fecha Rango» y el único que no es un extremo.
  ///
  /// [codRelEmplEmpr] en 0 = «la relación vigente, resolvela vos».
  Future<List<NominaPermisoEntity>> getNominaPermisos(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    String tipoPermiso = '',
    DateTime? desde,
    DateTime? hasta,
    DateTime? fecRango,
  });

  /// Los permisos que suman un tramo del desglose: de dónde sale ese número.
  ///
  /// [clave] es la del tramo (`SALDO_PENULTIMO`, `UTILIZADA`, `PROGRAMADA`).
  /// Sólo esos tres se abren: los otros dos no son listas de permisos. Las
  /// fechas del corte las resuelve el servidor, así que acá no se mandan.
  /// **Boletas entre fechas**: el buscador global, de toda la empresa.
  ///
  /// Acota por permisos **contenidos** en la ventana, no por los que la cruzan:
  /// una vacación del 28/07 al 03/08 no aparece buscando boletas de agosto.
  /// Hay que mandar al menos una fecha.
  Future<List<NominaPermisoEntity>> getBoletas({
    DateTime? desde,
    DateTime? hasta,
    String tipoPermiso = '',
  });

  /// **Quién está fuera**: los permisos de toda la empresa en una fecha o en
  /// un rango. Es la única lectura del módulo que no es por empleado.
  ///
  /// [fecha] responde «quién estaba de permiso ese día» —el rango del permiso
  /// atrapa a la fecha—; [desde]/[hasta] responden «quiénes salen en esa
  /// ventana». Hay que mandar al menos uno: sin filtro el backend rechaza,
  /// porque serían las 8.459 filas de la tabla.
  Future<List<NominaPermisoEntity>> getQuienEstaFuera({
    DateTime? fecha,
    DateTime? desde,
    DateTime? hasta,
  });

  /// Los días del rango que no descuentan vacación, con su motivo. Es lo que
  /// deja explicar la resta en vez de mostrar sólo el total.
  Future<List<DiaNoHabilEntity>> getDiasNoHabiles(
    int codEmpleado,
    DateTime desde,
    DateTime hasta,
  );

  Future<List<NominaPermisoEntity>> getDetalleTramo(
    int codEmpleado,
    String clave,
  );

  /// Las vacaciones **ganadas** (asignadas) de una persona entre dos fechas:
  /// el botón «Buscar Vac Ganadas» de la Nómina (`p_list_vacacionAsignada 'D'`).
  ///
  /// **No es [getHistorialVacacionAsignada]**, que es la ACCION `'B'`: aquella
  /// se pide con una fecha de corte y además **inventa** filas por aniversario
  /// (`codVacacionAsignada = 0`) para ofrecer el «Nuevo» de su grilla. Ésta es
  /// un SELECT pelado sobre las filas reales, recortado por el SP. Recortar la
  /// otra en memoria daría un conjunto distinto al del ERP para el mismo botón.
  Future<List<VacacionAsignadaEntity>> getVacacionesGanadas(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    DateTime? desde,
    DateTime? hasta,
  });

  /// Cuántos días y horas daría el rango **antes** de grabarlo, y si el alta va
  /// a poder guardarse. **No escribe nada.**
  ///
  /// Es lo que alimenta los campos calculados de los dos modales, y el mismo
  /// número que después se graba: el backend re-simula dentro de la transacción
  /// en vez de confiar en lo que trajo el cliente.
  ///
  /// [tipoPermiso] no cambia los días —la función SQL no lo recibe— pero sí las
  /// «Horas a reponer», que salen de la regla `tipo in ('otro','pcr')`. Va acá
  /// y no se recalcula en el cliente: dos motores para el mismo número es lo
  /// que este módulo evita en todos lados.
  ///
  /// `null` cuando el backend contesta 204 —el empleado no tiene relación
  /// laboral activa—, que la pantalla muestra como «no se puede calcular».
  Future<SimulacionPermisoEntity?> simularPermiso({
    required int codEmpleado,
    required DateTime desde,
    required DateTime hasta,
    String tipoPermiso = '',
  });

  /// Los tipos de `v_tipos` grupo 13 para el combo.
  ///
  /// [incluirVacacionYPago] `false` replica `Tipos.cargarList13A()` del legacy
  /// —los 7 del modal de permiso, **sin** `vac` ni `pva`—; `true` devuelve los
  /// 9 para el filtro de la Nómina. La opción «Todos» del filtro no viene de
  /// acá: es el vacío, y lo pone la pantalla.
  Future<List<TipoPermisoVacacionEntity>> getTiposPermiso({
    bool incluirVacacionYPago = false,
  });

  /// Programa **un permiso** a nombre de un empleado: una fila en `trh_permiso`
  /// vía `p_abm_Permiso` ACCION 'I'.
  ///
  /// Es el mismo camino de escritura que [aplicarVacacionColectiva] con una
  /// lista de un solo elemento. [tipoPermiso] es uno de los 7 de
  /// `cargarList13A`; **`'vac'` no entra por acá** —el servidor lo rechaza con
  /// un 400— porque la vacación individual pide otro botón del ACL: es
  /// [registrarVacacion]. Devuelve el mensaje del servidor.
  ///
  /// **Lo que sostiene esto es Java, no la base.** `p_abm_Permiso` es un INSERT
  /// pelado: no valida nada, no devuelve envelope ni id generado, y no hay
  /// unique constraint en la tabla. El cruce de rangos, el mínimo de medio día,
  /// el motivo y el control de duplicado están todos del otro lado.
  ///
  /// **`codRelEmplEmpr` no viaja**: lo resuelve el servidor, igual que en la
  /// colectiva. **`horasAReponer` tampoco**: ese campo del modal legacy es puro
  /// display —`p_abm_Permiso` no tiene parámetro donde guardarlo—, así que
  /// mandarlo sería prometer que se registra algo que no se registra.
  ///
  /// **Sin `confirmado`**: este camino no tiene ningún aviso confirmable. Lo que
  /// el servidor no acepta lo rechaza y punto —el cruce de rangos, el medio día,
  /// el motivo—, y el cliente ya apaga el botón con lo que devolvió
  /// [simularPermiso]. Mandar un flag que el controlador descarta era prometer
  /// un «Guardar igual» que no existe. El de [registrarVacacionPagada] sí es
  /// real, porque ahí el aviso lo emite el DAO.
  Future<String> registrarPermiso({
    required int codEmpleado,
    required String tipoPermiso,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  });

  /// Programa **una vacación individual** (`tipoPermiso = 'vac'`): el modal
  /// «Registro de vacación individual».
  ///
  /// **Ruta propia, y no [registrarPermiso] con `'vac'`.** Es el mismo DAO y el
  /// mismo INSERT, pero el servidor lo partió en dos endpoints con dos botones
  /// de ACL distintos (`btnProgramarVacacion`, 5 usuarios, contra
  /// `btnProgramarPermiso`, 4) y **el tipo lo pone él**, no el cuerpo: si
  /// viniera del cliente, esta ruta sería un atajo para dar de alta cualquier
  /// permiso salteándose el botón del otro.
  Future<String> registrarVacacion({
    required int codEmpleado,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  });

  /// **Paga días de vacación** (`tipoPermiso = 'pva'`): el modal «Pago de
  /// vacaciones».
  ///
  /// **Es la única escritura del módulo donde los días los tipea el usuario y
  /// no los calcula nadie.** El servidor fuerza `hasta = desde` (por eso una
  /// PVA siempre ocupa un solo día) y `tipoPermiso = 'pva'`.
  ///
  /// **Lo que el legacy no hace y acá sí:** `savePagoDiasVacac` acepta cualquier
  /// cantidad sin mirar el saldo, sin tope y sin confirmar —hay una fila
  /// histórica de 247 días pagados y otra de 30—, y un doble toque mete dos
  /// filas. Acá va con confirmación explícita diciendo el saldo antes y
  /// después, y el backend rechaza el duplicado reciente con 409.
  ///
  /// Son 32 filas en 10 años: la pantalla se justifica por el impacto, no por
  /// el volumen.
  Future<String> registrarVacacionPagada({
    required int codEmpleado,
    required DateTime fecha,
    required double dias,
    required String motivo,
    bool confirmado = false,
  });
}
