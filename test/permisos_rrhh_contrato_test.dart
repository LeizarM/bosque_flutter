import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/abono_dias_model.dart';
import 'package:bosque_flutter/data/models/vacacion_asignada_model.dart';
import 'package:bosque_flutter/data/repositories/permisos_rrhh_impl.dart';
import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Las dos pruebas que faltaban**, y por las que las escrituras salieron rotas
/// con los 61 tests del backend y los 200 de acá en verde.
///
/// Ninguna de las dos suites veía el desajuste: el backend mockea el DAO y estas
/// pruebas mockean el repositorio, así que **nadie comparaba el cuerpo que sale
/// con el cuerpo que entra**. Los dos defectos que se escaparon fueron de esa
/// clase y los dos fallan callados:
///
/// 1. **La clave de los días.** El cliente mandaba `diasAsignados` /
///    `diasAbonados` y el DTO del servidor declara `dias`. Jackson descarta lo
///    que no conoce —no hay `FAIL_ON_UNKNOWN_PROPERTIES`— y `dias` es un
///    `double` primitivo, así que llegaba **0**: la vacación se guardaba en cero
///    días y el abono lo rechazaba con «tiene que ser mayor a 0» sobre un
///    formulario donde decía 3.
/// 2. **Las rutas.** Seis de las diez constantes apuntaban a un camino que no
///    existe (`/abonos/...`, `/colectivas/...`). Eso es un 404, que la pantalla
///    muestra como un error de conexión cualquiera.
///
/// Las dos listas de abajo están escritas a mano **a propósito**: son la copia
/// del contrato del servidor. Si el backend cambia un campo o una ruta, esta
/// prueba tiene que fallar — es justamente su trabajo — y el que la arregle
/// tiene que ir a mirar el otro repo antes de tocar nada.
void main() {
  // ═════════════════════════════════════════════════════════════════════════
  // 1. LA FORMA DEL CUERPO CONTRA LOS CAMPOS DEL DTO
  // ═════════════════════════════════════════════════════════════════════════

  /// Los campos de `PermisoRrhhEscrituraDto` (el `@RequestBody` de las ocho
  /// rutas de escritura), copiados uno por uno.
  ///
  /// **`confirmado` y no `confirmarDuplicado`**; **`dias` y no `diasAsignados`
  /// ni `diasAbonados`**. Lo que no está acá, el servidor lo tira.
  const camposDelDto = {
    'codVacacionAsignada',
    'codAbonoDias',
    'codEmpleado',
    'codRelEmplEmpr',
    'dias',
    'motivo',
    'fecha',
    'confirmado',
    'codEmpleados',
    // ── Los dos de la vacación colectiva ────────────────────────────────
    //
    // **OJO: al cerrar esta corrección, `PermisoRrhhEscrituraDto` NO los
    // declaraba todavía** —los tenía `PermisoRrhhFiltroDto`, que es el de las
    // lecturas—. Los endpoints `/colectivo/vacacion/{simular,aplicar}` se
    // están creando con este mismo contrato, así que el DTO de escritura tiene
    // que llevarlos. Si el backend los nombra distinto, Jackson los descarta en
    // silencio y la vacación colectiva se graba con el rango vacío: es la misma
    // falla que tenía `dias`, y esta línea es el recordatorio de verificarlo
    // contra el controller antes de dar por buena la carga.
    'desde',
    'hasta',
    // ── Los del permiso individual (Fase 3) ─────────────────────────────
    //
    // **`tipoPermiso` NO estaba declarado en `PermisoRrhhEscrituraDto`** cuando
    // se escribió esto. Es el único campo que distingue «Programar permiso» de
    // «Programar vacación»; si el backend no lo declara, Jackson lo descarta en
    // silencio y el permiso se graba con el tipo en NULL —hay 28 filas así en
    // `trh_permiso`, residuo de un flujo muerto del legacy—. Esta línea es el
    // recordatorio de verificarlo contra el DTO antes de dar por buena un alta.
    'tipoPermiso',
  };

  /// Los campos de `PermisoRrhhFiltroDto` (el `@RequestBody` de las lecturas).
  ///
  /// **`tipoPermiso` y `fecRango` tampoco estaban declarados**: el DTO sólo
  /// tenía `codEmpleado`, `desde` y `hasta`. Sin ellos la Nómina sale **sin
  /// filtrar** —el SP filtra con `(@x IS NULL OR ...)`, así que un filtro que
  /// no llega es un filtro que no se aplica— y nadie ve un error: se ve la
  /// grilla completa, que es un resultado plausible.
  ///
  /// `codRelEmplEmpr` es el otro que hay que mirar: `p_list_Permiso 'Q'` filtra
  /// por él, y sin declararlo la grilla mezcla las dos relaciones laborales de
  /// quien tenga dos, o sea dos historias de saldo sumadas en una.
  const camposDelFiltroDto = {
    'codEmpleado',
    'codRelEmplEmpr',
    'desde',
    'hasta',
    'tipoPermiso',
    'fecRango',
    'incluirVacacionYPago',
  };

  group('el cuerpo que se manda entra entero en el DTO del servidor', () {
    test('VacacionAsignadaModel.toJson', () {
      final j =
          VacacionAsignadaModel(
            VacacionAsignadaEntity(
              codVacacionAsignada: 0,
              codEmpleado: 130,
              codRelEmplEmpr: 411,
              diasAsignados: 15,
              motivo: 'Aniversario 2026',
              fecha: DateTime(2026, 7, 31),
            ),
          ).toJson();

      expect(
        j.keys,
        everyElement(isIn(camposDelDto)),
        reason: 'una clave que el DTO no declara se descarta en silencio',
      );
      // El caso puntual, dicho aparte porque es el que costó plata: los días
      // viajan como `dias`, y con el nombre de la columna llegaban en 0.
      expect(j['dias'], 15);
      expect(j.containsKey('diasAsignados'), isFalse);
    });

    test('AbonoDiasModel.toJson', () {
      final j =
          AbonoDiasModel(
            AbonoDiasEntity(
              codAbonoDias: 0,
              codEmpleado: 130,
              codRelEmplEmpr: 411,
              diasAbonados: 2.5,
              motivo: 'Compensación',
              fecha: DateTime(2026, 8, 12),
            ),
          ).toJson();

      expect(j.keys, everyElement(isIn(camposDelDto)));
      expect(j['dias'], 2.5);
      expect(j.containsKey('diasAbonados'), isFalse);
    });

    test('el cabezal del abono colectivo', () {
      final j = PermisosRrhhImpl.cuerpoAbonoColectivo(
        const [130, 48],
        3,
        'Inventario',
        DateTime(2026, 8, 12),
      );

      expect(j.keys, everyElement(isIn(camposDelDto)));
      expect(j['dias'], 3);
      // `date` del otro lado: con la hora, un reloj corrido cambia de día.
      expect(j['fecha'], '2026-08-12');
    });

    test('la fecha de corte del historial va en `fecha`, no en `hasta`', () {
      final j = PermisosRrhhImpl.cuerpoHistorialVacAsig(
        130,
        0,
        DateTime(2026, 8, 12),
      );

      expect(j.keys, everyElement(isIn(camposDelDto)));
      // **Acá el chequeo de claves NO alcanza y por eso va aparte.** El DTO
      // declara los dos campos: `fecha` (la fecha de corte, que es la que lee
      // `vacDao.historial`) y `hasta` (el fin del rango de la vacación
      // colectiva). Mandarla como `hasta` pasa el filtro de claves, Jackson la
      // ata al campo equivocado, `fecha` llega null y el corte se va a hoy sin
      // que se caiga nada.
      expect(j['fecha'], '2026-08-12');
      expect(j.containsKey('hasta'), isFalse);
      // Sin relación, va null limpio: un 0 de más vaciaría la grilla.
      expect(j['codRelEmplEmpr'], isNull);
    });

    test('el cabezal de la vacación colectiva', () {
      final j = PermisosRrhhImpl.cuerpoVacacionColectiva(
        const [130, 48],
        DateTime(2026, 4, 3, 8, 30),
        DateTime(2026, 4, 10, 18, 30),
        'Cierre de gestión',
      );

      expect(j.keys, everyElement(isIn(camposDelDto)));
      // Acá la hora SÍ viaja: los días se cuentan de a media hora entre las
      // dos, así que perderla convierte medio día en cero.
      expect(j['desde'], '2026-04-03T08:30:00');
      expect(j['hasta'], '2026-04-10T18:30:00');
    });

    test('los filtros de la Nómina de Permisos', () {
      final j = PermisosRrhhImpl.cuerpoNominaPermisos(
        130,
        411,
        'otro',
        DateTime(2026, 1, 1),
        DateTime(2026, 12, 31),
        DateTime(2026, 8, 12),
      );

      expect(j.keys, everyElement(isIn(camposDelFiltroDto)));
      // `date` del otro lado: el SP compara con `CONVERT(date, ...)`, así que
      // la hora no significa nada y mandarla sólo agrega superficie de error.
      expect(j['desde'], '2026-01-01');
      expect(j['hasta'], '2026-12-31');
      expect(j['fecRango'], '2026-08-12');
      expect(j['tipoPermiso'], 'otro');
    });

    test('«Todos» viaja como null, no como cadena vacía ni como 0', () {
      final j = PermisosRrhhImpl.cuerpoNominaPermisos(
        130,
        0,
        '',
        null,
        null,
        null,
      );

      // Los cinco filtros vacíos tienen que llegar en null: el SP filtra con
      // `(@x IS NULL OR @x = col)` y un 0 o un '' de más devuelve la grilla
      // vacía, que en pantalla se lee como «esta persona nunca se tomó nada».
      expect(j['tipoPermiso'], isNull);
      expect(j['codRelEmplEmpr'], isNull);
      expect(j['desde'], isNull);
      expect(j['hasta'], isNull);
      expect(j['fecRango'], isNull);
      // El empleado sí va siempre: la Nómina es de una persona.
      expect(j['codEmpleado'], 130);
    });

    test('la simulación individual manda la hora, que es la que elige horario', () {
      final j = PermisosRrhhImpl.cuerpoSimulacionPermiso(
        130,
        DateTime(2026, 8, 17, 8),
        DateTime(2026, 8, 17, 18),
        'otro',
      );

      expect(j.keys, everyElement(isIn(camposDelFiltroDto)));
      // **El tipo va aunque no cambie los días**: es lo que el servidor usa
      // para las «Horas a reponer» (`tipo in ('otro','pcr')`). Sin él vuelven
      // siempre en 0 y la pantalla tendría que recalcularlas por su cuenta.
      expect(j['tipoPermiso'], 'otro');
      expect(j['desde'], '2026-08-17T08:00:00');
      // **`hasta > 17:30` es lo que conmuta `f_CalcularDiasHabilesPermiso` a
      // horario continuo** (tope 600 min, almuerzo 60) en vez de estándar (480
      // y 30). Perder la hora no es perder precisión: es cambiar de horario y
      // de resultado.
      expect(j['hasta'], '2026-08-17T18:00:00');
      // El radio Estándar/Continuo NO viaja: la función lo deduce de esa hora,
      // así que un flag acá sería un control que el servidor ignora.
      expect(j.containsKey('horario'), isFalse);
      expect(j.containsKey('continuo'), isFalse);
    });

    test('el alta de un permiso lleva el tipo y NO lleva horas a reponer', () {
      final j = PermisosRrhhImpl.cuerpoPermiso(
        130,
        'otro',
        DateTime(2026, 8, 17, 8),
        DateTime(2026, 8, 17, 12, 30),
        '  Trámite personal  ',
      );

      expect(j.keys, everyElement(isIn(camposDelDto)));
      expect(j['tipoPermiso'], 'otro');
      expect(j['desde'], '2026-08-17T08:00:00');
      expect(j['motivo'], 'Trámite personal');
      // **`p_abm_Permiso` no tiene parámetro donde guardar las horas a
      // reponer** (11 parámetros, ninguno es ese): el campo del modal legacy es
      // display puro. Mandarlo sería prometer que se registra algo que no se
      // registra en ningún lado.
      expect(j.containsKey('horasAReponer'), isFalse);
      // La relación laboral la resuelve el servidor, igual que en la colectiva.
      expect(j.containsKey('codRelEmplEmpr'), isFalse);
      // **Ni `confirmado`**: ninguna de las dos altas emite un 400 confirmable
      // —`IPermiso.registrarPermiso` ni recibe el flag—, así que mandarlo era
      // una clave que el controlador descarta y un «Guardar igual» que nunca se
      // dispara. El de la vacación pagada sí es real.
      expect(j.containsKey('confirmado'), isFalse);
    });

    test('la vacación individual NO manda el tipo: lo pone el servidor', () {
      final j = PermisosRrhhImpl.cuerpoPermiso(
        130,
        null,
        DateTime(2026, 9, 1, 8),
        DateTime(2026, 9, 5, 17, 30),
        'Vacación programada',
      );

      // Va por `/vacacion/registrar`, que fuerza `'vac'`. Si el tipo viniera
      // del cuerpo, esa ruta —con su propio botón de ACL— sería un atajo para
      // dar de alta cualquier permiso salteándose el botón del otro.
      expect(j.containsKey('tipoPermiso'), isFalse);
      expect(j['desde'], '2026-09-01T08:00:00');
      expect(j['motivo'], 'Vacación programada');
    });

    test('el pago de vacaciones: días tipeados, fecha sin hora, sin tipo', () {
      final j = PermisosRrhhImpl.cuerpoVacacionPagada(
        130,
        DateTime(2026, 8, 12),
        2.5,
        'Pago autorizado',
        false,
      );

      expect(j.keys, everyElement(isIn(camposDelDto)));
      // `dias` y no `diasAPagar`: el campo del DTO ya se llama así y sirve para
      // las tres tablas. Un nombre nuevo repetiría la falla de `diasAsignados`,
      // que llegaba en 0 sin que se cayera nada — y acá el 0 es plata.
      expect(j['dias'], 2.5);
      expect(j.containsKey('diasAPagar'), isFalse);
      // El modal legacy no tiene hora y el servidor fuerza `hasta = desde`.
      expect(j['fecha'], '2026-08-12');
      // El tipo lo pone el servidor en 'pva': dejarlo viajar sería dejar pagar
      // días con la etiqueta de otra cosa.
      expect(j.containsKey('tipoPermiso'), isFalse);
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 2. LAS RUTAS CONTRA LOS @PostMapping DEL CONTROLLER
  // ═════════════════════════════════════════════════════════════════════════

  group('las rutas del módulo son las que expone el controller', () {
    /// La lista canónica: cada `@PostMapping` de `PermisoRrhhController` bajo
    /// `@RequestMapping("/permiso-rrhh")`, copiado letra por letra.
    const rutasCanonicas = {
      // Lecturas (Fase 1, en producción)
      AppConstants.permRrhhSaldoFicha: '/permiso-rrhh/saldo/ficha',
      AppConstants.permRrhhSaldoDesglose: '/permiso-rrhh/saldo/desglose',
      AppConstants.permRrhhBoletas: '/permiso-rrhh/permisos/boletas',
      AppConstants.permRrhhQuienEstaFuera:
          '/permiso-rrhh/permisos/quien-esta-fuera',
      AppConstants.permRrhhDiasNoHabiles:
          '/permiso-rrhh/permisos/dias-no-habiles',
      AppConstants.permRrhhSaldoDetalleTramo:
          '/permiso-rrhh/saldo/detalle-tramo',
      AppConstants.permRrhhEstadoCuenta: '/permiso-rrhh/reportes/estado-cuenta',
      AppConstants.permRrhhEstadoCuentaFiscal:
          '/permiso-rrhh/reportes/estado-cuenta-fiscal',
      AppConstants.permRrhhCalculoAntiguedad:
          '/permiso-rrhh/herramientas/calculo-antiguedad',
      // Vacación asignada
      AppConstants.permRrhhVacAsigHistorial:
          '/permiso-rrhh/vacacion-asignada/historial',
      AppConstants.permRrhhVacAsigRegistrar:
          '/permiso-rrhh/vacacion-asignada/registrar',
      AppConstants.permRrhhVacAsigEliminar:
          '/permiso-rrhh/vacacion-asignada/eliminar',
      // Abono de días. `historial`, no `detalle`: es el listado de una persona.
      AppConstants.permRrhhAbonoHistorial: '/permiso-rrhh/abono-dias/historial',
      AppConstants.permRrhhAbonoRegistrar: '/permiso-rrhh/abono-dias/registrar',
      AppConstants.permRrhhAbonoEliminar: '/permiso-rrhh/abono-dias/eliminar',
      // Cargas colectivas. `colectivo`, en singular.
      AppConstants.permRrhhColectivaEmpleados: '/permiso-rrhh/colectivo/empleados',
      AppConstants.permRrhhColectivaAbonoSimular:
          '/permiso-rrhh/colectivo/abono-dias/simular',
      AppConstants.permRrhhColectivaAbonoAplicar:
          '/permiso-rrhh/colectivo/abono-dias/aplicar',
      AppConstants.permRrhhColectivaVacacionSimular:
          '/permiso-rrhh/colectivo/vacacion/simular',
      AppConstants.permRrhhColectivaVacacionAplicar:
          '/permiso-rrhh/colectivo/vacacion/aplicar',
      // El permiso individual. **`registrar` son DOS rutas**, una por botón del
      // ACL: `/permisos/registrar` (btnProgramarPermiso, 4 usuarios) rechaza
      // `tipoPermiso: 'vac'` con un 400, y la vacación va por
      // `/vacacion/registrar` (btnProgramarVacacion, 5), que pone el tipo del
      // lado del servidor. `/vacacion/pagar` es la tercera, con su propio botón,
      // porque paga plata.
      //
      // El plural de `/permisos/...` es del backend y no se toca: las 21 rutas
      // están congeladas por `RutasPermisoRrhhTest` del otro lado.
      AppConstants.permRrhhPermisoHistorial: '/permiso-rrhh/permisos/kardex',
      AppConstants.permRrhhVacacionesGanadas:
          '/permiso-rrhh/permisos/vacaciones-ganadas',
      AppConstants.permRrhhPermisoSimular: '/permiso-rrhh/permisos/calcular',
      AppConstants.permRrhhPermisoTipos: '/permiso-rrhh/permisos/tipos',
      AppConstants.permRrhhPermisoRegistrar: '/permiso-rrhh/permisos/registrar',
      AppConstants.permRrhhVacacionRegistrar:
          '/permiso-rrhh/vacacion/registrar',
      AppConstants.permRrhhPermisoVacacionPagada: '/permiso-rrhh/vacacion/pagar',
    };

    test('cada constante coincide con su @PostMapping, letra por letra', () {
      rutasCanonicas.forEach((constante, canonica) {
        expect(
          constante,
          canonica,
          reason: 'una ruta que no existe del otro lado es un 404, y en '
              'pantalla se lee como un problema de conexión',
        );
      });
    });

    test('todas cuelgan de /permiso-rrhh y ninguna se repite', () {
      for (final r in rutasCanonicas.keys) {
        expect(r, startsWith('/permiso-rrhh/'));
        // Sin barra final ni doble barra: Spring no las normaliza.
        expect(r, isNot(endsWith('/')));
        expect(r.contains('//'), isFalse);
      }
      expect(
        rutasCanonicas.keys.toSet(),
        hasLength(rutasCanonicas.length),
        reason: 'dos constantes con la misma ruta: una de las dos está mal',
      );
    });

    test('el buscador de empleados NO cuelga de este módulo', () {
      // Reutiliza `/rrhh/obtenerLstEmpleados`, que ya pagina en SQL. Si alguien
      // lo "ordena" moviéndolo bajo /permiso-rrhh, se rompe la puerta de
      // entrada del módulo y además el otro consumidor que ya lo usa.
      expect(AppConstants.rrhhObtenerLstEmpleados, '/rrhh/obtenerLstEmpleados');
    });
  });

  // ═════════════════════════════════════════════════════════════════════════
  // 3. LO QUE VUELVE, CON LOS NOMBRES QUE USA EL SERVIDOR
  // ═════════════════════════════════════════════════════════════════════════

  group('el combo de tipos se lee con los nombres de TipoPermisoDto', () {
    test('el JSON real {codigo, descripcion} llega entero', () {
      // Es lo que serializa `TipoPermisoDto`: `SELECT codigo, descripcion FROM
      // v_tipos WHERE grupo = 13`. Leyendo sólo `codTipos`/`tipo` —los alias
      // del flujo del empleado— el código quedaba en '' para los 9 tipos: nueve
      // `DropdownMenuItem` con el mismo `value` (assert de Flutter en el filtro)
      // y un botón Guardar que no se habilita nunca en el modal.
      final t = PermisosRrhhImpl.tipoDeJson(const {
        'codigo': 'otro',
        'descripcion': 'Otros',
      });

      expect(t.codTipos, 'otro');
      expect(t.nombre, 'Otros');
    });

    test('los alias del otro molde siguen valiendo, y un JSON vacío no revienta',
        () {
      final t = PermisosRrhhImpl.tipoDeJson(const {
        'codTipos': 'pcr',
        'nombre': 'Permiso con Reposición',
      });
      expect(t.codTipos, 'pcr');
      expect(t.nombre, 'Permiso con Reposición');

      final vacio = PermisosRrhhImpl.tipoDeJson(const {});
      expect(vacio.codTipos, '');
    });
  });
}
