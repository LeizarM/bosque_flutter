// Modulo Rol de Turnos de Sabado (tablas `trs_` del backend).
// Los nombres llevan sufijo a proposito: en esta app "rol" ya significa
// permiso de usuario (ROLE_ADM), y "asignacion" ya se usa en anticipos y Tigo.

/// **Origen:** tabla `dbo.trs_Participante`, via `p_list_trs_Participante @ACCION='L'`.
///
/// `turnosTrabaja` y los `dias*` (Vacacion, Cambio, Asueto, Excusado) los aporta
/// @T, el SUM de la derecha del Excel. En un listado @L quedan en 0.
///
/// Una persona dentro del rol: una FILA de la grilla.
class ParticipanteTurnoEntity {
  final int idParticipante;
  final int idRol;
  final int codEmpleado;
  final String nombreRol;

  /// 'A' o 'B'. Decide qué sábados le tocan por defecto.
  final String grupoRotacion;
  final int nroOrden;
  final int turnosObjetivo;

  /// Sucursal de la persona: es lo que decide qué feriado le aplica.
  final int codSucursal;

  /// Nombre de la sucursal y del cargo, resueltos por el listado.
  ///
  /// Son la **foto** del organigrama al generar el rol. Si después RR.HH. borra
  /// ese cargo, llegan vacíos — por eso quien los muestra tiene que tolerarlo.
  final String sucursal;
  final String cargo;

  /// La empresa **de la sucursal de esta persona**, no la del rol.
  ///
  /// El rol se genera global: `trs_Rol.codEmpresa` viene en NULL, así que «la
  /// empresa del rol» no existe como dato. La única empresa que hay es ésta, y
  /// se deduce contando: si todos coinciden, el rol es de una sola empresa.
  ///
  /// Los JOIN de `tb_sucursal`/`tb_empresa` son LEFT: quien no tiene sucursal
  /// cargada llega con `codEmpresa` en 0 y `empresa` vacía. **No es cosmético**
  /// — el feriado se resuelve por sucursal, así que a esa persona no le aplica
  /// ninguno.
  final int codEmpresa;
  final String empresa;
  final DateTime? fechaNacimiento;
  final int esProgramador;

  /// **Sigue en la relación laboral vigente**, y nada más que eso.
  ///
  /// Lo escribe únicamente la regeneración del rol, que lo reconcilia contra
  /// `tb_relEmplEmpr` en cada corrida. **No es «hace sábados»**: para eso está
  /// [situacion]. Confundir los dos es lo que hacía que sacar a alguien de los
  /// sábados durara hasta la próxima regeneración.
  final int activo;

  /// Qué le pasa a esta persona con los sábados, resuelto por el servidor.
  ///
  /// `VIGENTE` · `SALE EL dd/mm/aaaa` · `SIN SABADOS` · `VUELVE EL dd/mm/aaaa` ·
  /// `FUERA DE LA EMPRESA`.
  ///
  /// Sale de un CASE del listado y no de una cuenta acá: son cinco
  /// combinaciones de `activo` con la ventana `[fechaAlta, fechaBaja]`, y
  /// calcularlas en el cliente sería hacerlo contra el reloj del teléfono y con
  /// una idea propia de cada pantalla.
  ///
  /// Llega vacía en los listados que no la traen (los turnos por persona) y en
  /// un backend que todavía no la tenga: por eso [haceSabados] trata el vacío
  /// como vigente, que es el comportamiento de antes de esta columna.
  final String situacion;

  /// La fecha que explica [situacion] — desde cuándo no viene, o desde cuándo
  /// vuelve. null cuando está vigente: no hay nada que fechar.
  final DateTime? fechaSituacion;

  // Sólo en la acción de turnos por persona (el SUM de la derecha del Excel).
  final int turnosTrabaja;
  final int diasVacacion;
  final int diasCambio;
  final int diasAsueto;
  final int diasExcusado;

  const ParticipanteTurnoEntity({
    required this.idParticipante,
    required this.idRol,
    required this.codEmpleado,
    required this.nombreRol,
    required this.grupoRotacion,
    required this.nroOrden,
    required this.turnosObjetivo,
    required this.codSucursal,
    this.sucursal = '',
    this.cargo = '',
    this.codEmpresa = 0,
    this.empresa = '',
    this.fechaNacimiento,
    required this.esProgramador,
    required this.activo,
    this.situacion = '',
    this.fechaSituacion,
    required this.turnosTrabaja,
    required this.diasVacacion,
    required this.diasCambio,
    required this.diasAsueto,
    required this.diasExcusado,
  });

  /// Diferencia contra su meta. Negativo = le faltan turnos.
  int get diferencia => turnosTrabaja - turnosObjetivo;

  /// Cargo y sucursal en una línea, saltando lo que no vino.
  String get puesto =>
      [cargo, sucursal].where((x) => x.isNotEmpty).join(' · ');

  /// RR.HH. le cerró la ventana: hoy no le toca ningún sábado.
  bool get sinSabados => situacion == 'SIN SABADOS';

  /// Está afuera hoy pero tiene fecha de vuelta.
  bool get vuelveDespues => situacion.startsWith('VUELVE');

  /// Ya no figura en la relación laboral. **No se reincorpora desde acá**: eso
  /// lo reconcilia la regeneración, que es la única que escribe [activo].
  bool get fueraDeLaEmpresa => situacion == 'FUERA DE LA EMPRESA';

  /// RR.HH. **ya lo sacó**, pero su última fecha todavía no llegó.
  ///
  /// Es el hueco que hacía irreversible la baja: sus sábados futuros ya se
  /// borraron en el momento de sacarlo, pero mientras `fechaBaja` fuera futura
  /// el listado lo devolvía como `VIGENTE` y la pantalla ofrecía «Sacar» a
  /// alguien ya sacado — sin ninguna forma de arrepentirse hasta que pasara la
  /// fecha. La decisión existe desde que se toma, no desde que se cumple.
  bool get saleDespues => situacion.startsWith('SALE');

  /// **Hoy le tocan sábados**, así que cuenta para el reparto A/B y va en la
  /// lista de vigentes.
  ///
  /// [saleDespues] NO cuenta acá, y es deliberado: una salida programada para
  /// diciembre deja intactos los sábados de acá hasta esa fecha —el borrado
  /// sólo alcanza a los posteriores—, así que esa persona sigue viniendo. Si
  /// contara, el contador diría «sin sábados» de alguien que trabaja el sábado
  /// que viene.
  ///
  /// Con [situacion] vacía da `true` a propósito: es el estado de un listado
  /// que no trae la columna, y ahí lo correcto es comportarse como antes.
  bool get haceSabados => !sinSabados && !vuelveDespues && !fueraDeLaEmpresa;

  /// **Hay una decisión de sacarlo**, se haya cumplido o no.
  ///
  /// Es la pregunta que tiene que hacerse el menú, y es distinta de
  /// [haceSabados]: entre que RR.HH. decide la salida y que llega la fecha, la
  /// persona sigue viniendo pero la decisión ya existe. Sin esto, deshacerla
  /// era imposible justo en esa ventana — que es cuando uno se arrepiente.
  ///
  /// [fueraDeLaEmpresa] no entra: eso no lo decidió RR.HH. acá y no se deshace
  /// desde esta pantalla, lo reconcilia la regeneración.
  bool get salidaDecidida => saleDespues || sinSabados;
}
