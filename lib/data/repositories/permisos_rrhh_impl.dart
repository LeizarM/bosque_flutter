import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/abono_dias_model.dart';
import 'package:bosque_flutter/data/models/desglose_saldo_model.dart';
import 'package:bosque_flutter/data/models/empleado_model.dart';
import 'package:bosque_flutter/data/models/ficha_saldo_model.dart';
import 'package:bosque_flutter/data/models/nomina_permiso_model.dart';
import 'package:bosque_flutter/data/models/permisos_rrhh_json.dart';
import 'package:bosque_flutter/data/models/simulacion_colectiva_model.dart';
import 'package:bosque_flutter/data/models/simulacion_permiso_model.dart';
import 'package:bosque_flutter/data/models/vacacion_asignada_model.dart';
import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';
import 'package:bosque_flutter/domain/entities/desglose_saldo_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/data/models/dia_no_habil_model.dart';
import 'package:bosque_flutter/domain/entities/dia_no_habil_entity.dart';
import 'package:bosque_flutter/domain/entities/nomina_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/simulacion_colectiva_entity.dart';
import 'package:bosque_flutter/domain/entities/simulacion_permiso_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:dio/dio.dart';

/// **Coherencia obligatoria entre el shape del backend y el helper.**
/// `/saldo/ficha` devuelve una LISTA → `postAndReturnList`; `/saldo/desglose`
/// devuelve un OBJETO → `postAndReturnObject`. Equivocarse no da error: da
/// `null` o lista vacía en silencio, que la pantalla muestra como «sin datos».
///
/// **La identidad no viaja en el body** (SUPUESTO D4 — pendiente de
/// confirmación de RR.HH., ver plan §5): ninguno de estos tres métodos manda
/// `codUsuario`. El backend la saca del `Authentication` del token y con eso
/// resuelve el ACL de `tb_usuarioBtn`. Esconder un botón en Flutter no autoriza
/// nada; el gate real está del otro lado.
class PermisosRrhhImpl extends BaseApiRepository
    implements PermisosRrhhRepository {
  // ══════════════════════════════════════════════════════════════════════
  // LECTURAS
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<List<EmpleadoEntity>> buscarEmpleados(
    String texto, {
    bool soloActivos = true,
    int codEmpresa = 0,
    int pagina = 1,
    int porPagina = 50,
  }) async {
    // **EXCEPCIÓN DOCUMENTADA AL ENVELOPE.** `RrhhController.obtenerLstEmpleados`
    // devuelve `List<Empleado>` CRUDO, no `{message,data,status}`, y con cero
    // resultados devuelve 200 con `[]` en vez de 204. Funciona porque
    // `postAndReturnList` tiene la rama `raw is List ? raw : raw['data']`.
    //
    // Este es el PRIMER llamador de la app que pasa por esa rama contra este
    // endpoint —el único consumidor que había usa Dio a mano—, así que es lo
    // primero a verificar contra el servidor real. Y si alguien «normaliza» ese
    // endpoint al envelope, se rompe la puerta de entrada del módulo.
    // Sin `final r` ni `.map`: `fromJson` ya devuelve la Entity, así que el
    // helper es la respuesta.
    return postAndReturnList<EmpleadoEntity>(
      endpoint: AppConstants.rrhhObtenerLstEmpleados,
      data: {
        'search': texto,
        'esActivo': soloActivos ? 1 : null,
        'pageNumber': pagina,
        'pageSize': porPagina,
        // 0 significa "sin filtrar" y el backend lo espera como null, no como 0:
        // el SP filtra con `(@x IS NULL OR @x = col)`, así que un 0 de más
        // devolvería la lista vacía.
        'codEmpresa': codEmpresa == 0 ? null : codEmpresa,
      },
      fromJson: (json) => EmpleadoModel.fromJson(json).toEntity(),
    );
  }

  @override
  Future<FichaSaldoEntity?> getFichaSaldo(int codEmpleado) async {
    try {
      final r = await postAndReturnList<FichaSaldoModel>(
        endpoint: AppConstants.permRrhhSaldoFicha,
        data: {'codEmpleado': codEmpleado},
        // Tear-off, no lambda: es la misma función, un cierre menos por fila.
        fromJson: FichaSaldoModel.fromJson,
      );
      return r.isEmpty ? null : r.first.toEntity();
    } on DioException catch (e) {
      // **La excepción a la regla del módulo de referencia**, que no tiene ni un
      // try/catch propio: `postAndReturnList` es el único helper que no acepta
      // `errorMessage` y traduce el mensaje del backend SÓLO en el 400 — para
      // cualquier otro status hace `rethrow` de la DioException cruda, y lo que
      // llega a la pantalla es «DioException [bad response]…».
      //
      // Este endpoint tiene un 409 propio y cargado de significado —«el empleado
      // tiene más de una relación laboral activa; corrija en el ERP»— que es
      // justamente el que nadie puede adivinar. Sin esto, el único caso donde el
      // sistema sabe exactamente qué pasa es el único donde no lo dice.
      //
      // Se traduce acá y NO se toca `BaseApiRepository`: ese helper lo comparten
      // unos 40 llamadores en producción. `handleDioError` sí lee
      // `data['message']` para cualquier status.
      throw Exception(
        DioClient.handleDioError(e, 'Error al obtener la ficha de saldo'),
      );
    }
  }

  @override
  Future<DesgloseSaldoEntity?> getDesgloseSaldo(int codEmpleado) async {
    final r = await postAndReturnObject<DesgloseSaldoModel>(
      endpoint: AppConstants.permRrhhSaldoDesglose,
      data: {'codEmpleado': codEmpleado},
      fromJson: DesgloseSaldoModel.fromJson,
      errorMessage: 'Error al obtener el desglose del saldo',
    );
    return r?.toEntity();
  }

  @override
  Future<String> calcularAntiguedad({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    try {
      final r = await postAndReturnList<String>(
        endpoint: AppConstants.permRrhhCalculoAntiguedad,
        data: {'desde': prDia(desde), 'hasta': prDia(hasta)},
        // Sin modelo: la respuesta es una sola columna de texto. Un archivo de
        // modelo para envolver un String sería una capa que no traduce nada.
        fromJson: (json) => json['datoAntCalc']?.toString() ?? '',
      );
      return r.isEmpty ? '' : r.first;
    } on DioException catch (e) {
      // Mismo motivo que en `getFichaSaldo`: `postAndReturnList` traduce el
      // mensaje del backend SÓLO en el 400 y para el resto hace `rethrow` de la
      // DioException cruda. Este endpoint tiene un 403 propio —exige
      // `btnApoyoCalc`, que NO es el mismo botón que piden los otros dos— y sin
      // esto la pantalla mostraría «DioException [bad response]» en vez de «No
      // tienes los permisos necesarios…».
      throw Exception(
        DioClient.handleDioError(e, 'Error al calcular la antigüedad'),
      );
    }
  }

  @override
  Future<List<VacacionAsignadaEntity>> getHistorialVacacionAsignada(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    DateTime? hasta,
  }) async {
    try {
      final r = await postAndReturnList<VacacionAsignadaModel>(
        endpoint: AppConstants.permRrhhVacAsigHistorial,
        data: cuerpoHistorialVacAsig(codEmpleado, codRelEmplEmpr, hasta),
        fromJson: VacacionAsignadaModel.fromJson,
      );
      return r.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      // Mismo motivo que en `getFichaSaldo`: fuera del 400, `postAndReturnList`
      // hace `rethrow` de la DioException cruda. Acá el 403 —el ACL de la ABM,
      // que hoy sólo tienen los administradores— es el caso más probable de
      // todos, y es el que hay que poder leer.
      throw Exception(
        DioClient.handleDioError(e, 'Error al obtener la vacación asignada'),
      );
    }
  }

  @override
  Future<List<AbonoDiasEntity>> getDetalleAbonos(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
  }) async {
    try {
      final r = await postAndReturnList<AbonoDiasModel>(
        endpoint: AppConstants.permRrhhAbonoHistorial,
        data: {
          'codEmpleado': codEmpleado,
          // Null limpio y no 0: `null` es «la relación vigente, resolvela vos»,
          // que es lo único que la pantalla sabe antes de tener la ficha.
          'codRelEmplEmpr': codRelEmplEmpr == 0 ? null : codRelEmplEmpr,
        },
        fromJson: AbonoDiasModel.fromJson,
      );
      return r.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw Exception(
        DioClient.handleDioError(e, 'Error al obtener los abonos de días'),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // ESCRITURAS
  // ══════════════════════════════════════════════════════════════════════
  //
  // **Ni una manda `audUsuario`** (D4): la identidad sale del token, igual que
  // en `programar()` del Rol de Sábados y al revés que en el resto de aquella
  // clase. Si se lo agrega, el cuerpo deja de coincidir con lo que espera el
  // controller.
  //
  // **Ninguna usa `postAndReturnId`, y no es un capricho.** Aquel helper hace
  // `BigInt.from(data)` y acá `data` es un OBJETO —la fila releída—, así que
  // reventaba con «type '_Map' is not a subtype of type 'num'». Además traduce
  // cualquier `DioException` a un `Exception` con el mensaje adentro y ahí se
  // pierde el **status**, que es justo lo que hay que poder distinguir: el 400
  // confirmable ofrece insistir y el 409 no.
  //
  // `postAndReturnFullResponse` sí, para las que borran o cargan en lote: ahí
  // el resultado ES el `message` del servidor —«se acreditaron 3 días a 12
  // personas»— y con la fila sola no habría nada que contar.

  @override
  Future<VacacionAsignadaEntity> registrarVacacionAsignada(
    VacacionAsignadaEntity vacacion, {
    bool confirmado = false,
  }) => _filaEscrita(
    endpoint: AppConstants.permRrhhVacAsigRegistrar,
    data: {...VacacionAsignadaModel(vacacion).toJson(), 'confirmado': confirmado},
    fromJson: (json) => VacacionAsignadaModel.fromJson(json).toEntity(),
    siNoVino: vacacion,
    errorMessage: 'Error al registrar la vacación asignada',
  );

  @override
  Future<String> eliminarVacacionAsignada(
    VacacionAsignadaEntity vacacion,
  ) => _mensaje(
    AppConstants.permRrhhVacAsigEliminar,
    // Va también el `codEmpleado`: el DELETE del SP no comprueba de quién es la
    // fila, así que la pertenencia la verifica Java contra este dato.
    {
      'codVacacionAsignada': vacacion.codVacacionAsignada,
      'codEmpleado': vacacion.codEmpleado,
    },
    'Error al eliminar la vacación asignada',
  );

  @override
  Future<AbonoDiasEntity> registrarAbonoDias(
    AbonoDiasEntity abono, {
    bool confirmado = false,
  }) => _filaEscrita(
    endpoint: AppConstants.permRrhhAbonoRegistrar,
    data: {...AbonoDiasModel(abono).toJson(), 'confirmado': confirmado},
    fromJson: (json) => AbonoDiasModel.fromJson(json).toEntity(),
    siNoVino: abono,
    errorMessage: 'Error al registrar el abono de días',
  );

  @override
  Future<String> eliminarAbonoDias(AbonoDiasEntity abono) => _mensaje(
    AppConstants.permRrhhAbonoEliminar,
    {'codAbonoDias': abono.codAbonoDias, 'codEmpleado': abono.codEmpleado},
    'Error al eliminar el abono de días',
  );

  // ══════════════════════════════════════════════════════════════════════
  // CARGAS COLECTIVAS
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<List<SimulacionColectivaEntity>> getEmpleadosParaColectiva({
    int codEmpresa = 0,
  }) async {
    final r = await postAndReturnList<SimulacionColectivaModel>(
      endpoint: AppConstants.permRrhhColectivaEmpleados,
      data: {'codEmpresa': codEmpresa == 0 ? null : codEmpresa},
      fromJson: SimulacionColectivaModel.fromJson,
    );
    return r.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<SimulacionColectivaEntity>> simularAbonoColectivo({
    required List<int> codEmpleados,
    required double dias,
    required String motivo,
    required DateTime fecha,
  }) async {
    final r = await postAndReturnList<SimulacionColectivaModel>(
      endpoint: AppConstants.permRrhhColectivaAbonoSimular,
      data: cuerpoAbonoColectivo(codEmpleados, dias, motivo, fecha),
      fromJson: SimulacionColectivaModel.fromJson,
    );
    return r.map((m) => m.toEntity()).toList();
  }

  @override
  Future<String> aplicarAbonoColectivo({
    required List<int> codEmpleados,
    required double dias,
    required String motivo,
    required DateTime fecha,
  }) => _mensaje(
    AppConstants.permRrhhColectivaAbonoAplicar,
    cuerpoAbonoColectivo(codEmpleados, dias, motivo, fecha),
    'Error al cargar el abono colectivo',
  );

  @override
  Future<List<SimulacionColectivaEntity>> simularVacacionColectiva({
    required List<int> codEmpleados,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) async {
    final r = await postAndReturnList<SimulacionColectivaModel>(
      endpoint: AppConstants.permRrhhColectivaVacacionSimular,
      data: cuerpoVacacionColectiva(codEmpleados, desde, hasta, motivo),
      fromJson: SimulacionColectivaModel.fromJson,
    );
    return r.map((m) => m.toEntity()).toList();
  }

  @override
  Future<String> aplicarVacacionColectiva({
    required List<int> codEmpleados,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) => _mensaje(
    AppConstants.permRrhhColectivaVacacionAplicar,
    cuerpoVacacionColectiva(codEmpleados, desde, hasta, motivo),
    'Error al declarar la vacación colectiva',
  );

  // ══════════════════════════════════════════════════════════════════════
  // EL PERMISO INDIVIDUAL (Nómina + los tres modales)
  // ══════════════════════════════════════════════════════════════════════

  @override
  Future<List<NominaPermisoEntity>> getBoletas({
    DateTime? desde,
    DateTime? hasta,
    String tipoPermiso = '',
  }) async {
    try {
      final r = await postAndReturnList<NominaPermisoModel>(
        endpoint: AppConstants.permRrhhBoletas,
        data: {
          if (desde != null) 'desde': prDia(desde),
          if (hasta != null) 'hasta': prDia(hasta),
          if (tipoPermiso.isNotEmpty && tipoPermiso != '0')
            'tipoPermiso': tipoPermiso,
        },
        fromJson: NominaPermisoModel.fromJson,
      );
      return r.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw Exception(
        DioClient.handleDioError(e, 'Error al buscar las boletas'),
      );
    }
  }

  @override
  Future<List<NominaPermisoEntity>> getQuienEstaFuera({
    DateTime? fecha,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      // Misma forma que el kardex: es la misma ACCION 'Q', sin filtrar por
      // persona. Por eso reusa el model.
      final r = await postAndReturnList<NominaPermisoModel>(
        endpoint: AppConstants.permRrhhQuienEstaFuera,
        data: {
          if (fecha != null) 'fecRango': prDia(fecha),
          if (desde != null) 'desde': prDia(desde),
          if (hasta != null) 'hasta': prDia(hasta),
        },
        fromJson: NominaPermisoModel.fromJson,
      );
      return r.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw Exception(
        DioClient.handleDioError(e, 'Error al consultar quién está fuera'),
      );
    }
  }

  @override
  Future<List<DiaNoHabilEntity>> getDiasNoHabiles(
    int codEmpleado,
    DateTime desde,
    DateTime hasta,
  ) async {
    try {
      final r = await postAndReturnList<DiaNoHabilModel>(
        endpoint: AppConstants.permRrhhDiasNoHabiles,
        data: {
          'codEmpleado': codEmpleado,
          'desde': prDia(desde),
          'hasta': prDia(hasta),
        },
        fromJson: DiaNoHabilModel.fromJson,
      );
      return r.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw Exception(
        DioClient.handleDioError(e, 'Error al obtener los días no hábiles'),
      );
    }
  }

  @override
  Future<List<NominaPermisoEntity>> getDetalleTramo(
    int codEmpleado,
    String clave,
  ) async {
    try {
      // Misma forma de salida que el kardex: las ACCIONes 'H', 'J' y 'K'
      // devuelven las mismas columnas que 'Q', así que se reusa el model.
      final r = await postAndReturnList<NominaPermisoModel>(
        endpoint: AppConstants.permRrhhSaldoDetalleTramo,
        data: {'codEmpleado': codEmpleado, 'claveTramo': clave},
        fromJson: NominaPermisoModel.fromJson,
      );
      return r.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw Exception(
        DioClient.handleDioError(e, 'Error al obtener el detalle del tramo'),
      );
    }
  }

  @override
  Future<List<NominaPermisoEntity>> getNominaPermisos(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    String tipoPermiso = '',
    DateTime? desde,
    DateTime? hasta,
    DateTime? fecRango,
  }) async {
    try {
      // Lista, no objeto: `p_list_Permiso 'Q'` devuelve la grilla entera.
      final r = await postAndReturnList<NominaPermisoModel>(
        endpoint: AppConstants.permRrhhPermisoHistorial,
        data: cuerpoNominaPermisos(
          codEmpleado,
          codRelEmplEmpr,
          tipoPermiso,
          desde,
          hasta,
          fecRango,
        ),
        fromJson: NominaPermisoModel.fromJson,
      );
      return r.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      // Mismo motivo que en `getFichaSaldo`: fuera del 400, `postAndReturnList`
      // hace `rethrow` de la DioException cruda y la pantalla mostraría
      // «DioException [bad response]». Acá el 403 es el caso más probable.
      throw Exception(
        DioClient.handleDioError(e, 'Error al obtener la nómina de permisos'),
      );
    }
  }

  @override
  Future<List<VacacionAsignadaEntity>> getVacacionesGanadas(
    int codEmpleado, {
    int codRelEmplEmpr = 0,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      // **El mismo cuerpo que la Nómina**: los dos botones van con
      // `PermisoRrhhFiltroDto`. Este endpoint ignora el tipo y la fecha
      // puntual —el legacy también—, así que viajan en null.
      final r = await postAndReturnList<VacacionAsignadaModel>(
        endpoint: AppConstants.permRrhhVacacionesGanadas,
        data: cuerpoNominaPermisos(
          codEmpleado,
          codRelEmplEmpr,
          '',
          desde,
          hasta,
          null,
        ),
        fromJson: VacacionAsignadaModel.fromJson,
      );
      return r.map((m) => m.toEntity()).toList();
    } on DioException catch (e) {
      throw Exception(
        DioClient.handleDioError(e, 'Error al obtener las vacaciones ganadas'),
      );
    }
  }

  @override
  Future<SimulacionPermisoEntity?> simularPermiso({
    required int codEmpleado,
    required DateTime desde,
    required DateTime hasta,
    String tipoPermiso = '',
  }) async {
    // **Objeto y no lista**, al revés que las dos simulaciones colectivas: acá
    // la persona es una sola. Con `postAndReturnList` esto devolvería lista
    // vacía en silencio y el modal mostraría 0 días sobre un rango que sí los
    // tiene.
    final r = await postAndReturnObject<SimulacionPermisoModel>(
      endpoint: AppConstants.permRrhhPermisoSimular,
      data: cuerpoSimulacionPermiso(codEmpleado, desde, hasta, tipoPermiso),
      fromJson: SimulacionPermisoModel.fromJson,
      errorMessage: 'Error al calcular los días del permiso',
    );
    return r?.toEntity();
  }

  @override
  Future<List<TipoPermisoVacacionEntity>> getTiposPermiso({
    bool incluirVacacionYPago = false,
  }) {
    // **Sin modelo propio, y reusando la Entity que ya existe.** Son tres
    // campos de `v_tipos` y `TipoPermisoVacacionEntity` ya los tiene; un
    // archivo de modelo para copiarlos uno a uno sería una capa que no traduce
    // nada. Lo que sí hace falta es leerlos con los conversores del módulo: el
    // `fromJson` de aquel modelo hace `json["codTipos"]` a pelo y revienta con
    // un null.
    //
    // Los alias son porque `v_tipos` tiene las columnas `tipo`/`descripcion` y
    // el modelo del flujo del empleado las expone como `codTipos`/`nombre`: se
    // aceptan las dos formas para no depender de cuál de los dos moldes use el
    // backend.
    return postAndReturnList<TipoPermisoVacacionEntity>(
      endpoint: AppConstants.permRrhhPermisoTipos,
      data: {'incluirVacacionYPago': incluirVacacionYPago},
      fromJson: tipoDeJson,
    );
  }

  /// Una opción del combo, leída del JSON del servidor.
  ///
  /// **`codigo` primero porque es el que manda este backend**: `TipoPermisoDto`
  /// serializa `{codigo, descripcion}`. Leyendo sólo los alias del flujo del
  /// empleado (`codTipos`/`tipo`) el código quedaba en cadena vacía para los 9
  /// tipos: nueve `DropdownMenuItem` con el mismo `value` —el assert «exactly
  /// one item with value» en el filtro— y un botón Guardar que no se habilita
  /// nunca en el modal, porque exige tipo no vacío.
  ///
  /// Estática y con nombre para poder probarla: dentro de una `fromJson`
  /// anónima, ningún test la alcanza — que es exactamente por qué esto pasó.
  static TipoPermisoVacacionEntity tipoDeJson(Map<String, dynamic> json) =>
      TipoPermisoVacacionEntity(
        codTipos: prStr(json['codigo'] ?? json['codTipos'] ?? json['tipo']),
        nombre: prStr(json['descripcion'] ?? json['nombre']),
        codGrupo: prInt(json['codGrupo']),
        listTipos: null,
      );

  @override
  Future<String> registrarPermiso({
    required int codEmpleado,
    required String tipoPermiso,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) => _mensaje(
    AppConstants.permRrhhPermisoRegistrar,
    cuerpoPermiso(codEmpleado, tipoPermiso, desde, hasta, motivo),
    'Error al registrar el permiso',
  );

  @override
  Future<String> registrarVacacion({
    required int codEmpleado,
    required DateTime desde,
    required DateTime hasta,
    required String motivo,
  }) => _mensaje(
    AppConstants.permRrhhVacacionRegistrar,
    // **Sin `tipoPermiso`**: lo pone el servidor en `'vac'`. Mandarlo sería
    // pedirle a una ruta con su propio botón de ACL que grabe cualquier otra
    // cosa.
    cuerpoPermiso(codEmpleado, null, desde, hasta, motivo),
    'Error al registrar la vacación',
  );

  @override
  Future<String> registrarVacacionPagada({
    required int codEmpleado,
    required DateTime fecha,
    required double dias,
    required String motivo,
    bool confirmado = false,
  }) => _mensajeConfirmable(
    AppConstants.permRrhhPermisoVacacionPagada,
    cuerpoVacacionPagada(codEmpleado, fecha, dias, motivo, confirmado),
    'Error al registrar la vacación pagada',
  );

  /// Los filtros de la Nómina de Permisos.
  ///
  /// **Las fechas viajan como `desde` / `hasta` / `fecRango`**, que son los
  /// nombres de los parámetros del SP y los campos que tiene que declarar
  /// `PermisoRrhhFiltroDto`. Los rótulos de la pantalla dicen otra cosa —«Fecha
  /// Inicio», «Fecha Fin», «Fecha Rango»— y por eso los parámetros de acá se
  /// llaman por lo que significan; lo que no se puede es mandar el rótulo.
  ///
  /// **`tipoPermiso` y `fecRango` son los dos campos que el DTO de lecturas NO
  /// declaraba** cuando se escribió esto (sólo tenía `codEmpleado`, `desde` y
  /// `hasta`). Si el backend no los agrega, Jackson los descarta sin decir nada
  /// y la grilla sale **sin filtrar** — la misma falla que tuvo `dias`. Por eso
  /// este cuerpo se compara en `permisos_rrhh_contrato_test`.
  ///
  /// Los tres nulos son «sin filtrar»: el SP filtra con
  /// `(@x IS NULL OR ...)`, así que una fecha de más vacía la grilla.
  /// `prDia` y no `prInstante` porque el SP compara con `CONVERT(date, ...)`:
  /// la hora ahí no significa nada.
  ///
  /// Público y estático por lo mismo que [cuerpoAbonoColectivo].
  static Map<String, dynamic> cuerpoNominaPermisos(
    int codEmpleado,
    int codRelEmplEmpr,
    String tipoPermiso,
    DateTime? desde,
    DateTime? hasta,
    DateTime? fecRango,
  ) => {
    'codEmpleado': codEmpleado,
    'codRelEmplEmpr': codRelEmplEmpr == 0 ? null : codRelEmplEmpr,
    // Vacío = «Todos». Se manda null y no '' porque el DAO del legacy traduce
    // las dos cosas a NULL, y null es el que dice lo que quiere decir.
    'tipoPermiso': tipoPermiso.trim().isEmpty ? null : tipoPermiso.trim(),
    'desde': desde == null ? null : prDia(desde),
    'hasta': hasta == null ? null : prDia(hasta),
    'fecRango': fecRango == null ? null : prDia(fecRango),
  };

  /// El cuerpo del cálculo en vivo.
  ///
  /// **Con hora** (`prInstante`): la hora de `hasta` es la que decide si
  /// `f_CalcularDiasHabilesPermiso` cuenta el día como estándar (480 minutos) o
  /// como continuo (600). Perderla no es perder precisión: es cambiar de
  /// horario.
  ///
  /// **El radio Estándar/Continuo no está y no falta**: la función lo deduce de
  /// esa hora. Ver [SimulacionPermisoEntity].
  ///
  /// **`tipoPermiso` sí va**, aunque no cambie los días: el servidor calcula con
  /// él las «Horas a reponer» (`tipo in ('otro','pcr')`). Sin mandarlo, ese
  /// campo volvía siempre en 0 y la pantalla tenía que recalcularlo por su
  /// cuenta — dos motores para el mismo número.
  static Map<String, dynamic> cuerpoSimulacionPermiso(
    int codEmpleado,
    DateTime desde,
    DateTime hasta,
    String tipoPermiso,
  ) => {
    'codEmpleado': codEmpleado,
    'desde': prInstante(desde),
    'hasta': prInstante(hasta),
    'tipoPermiso': tipoPermiso.trim().isEmpty ? null : tipoPermiso.trim(),
  };

  /// El cuerpo de «Programar permiso» y «Programar vacación». **El mismo para
  /// los dos, y son dos rutas distintas**: lo que cambia es el endpoint y el
  /// botón del ACL, no la forma.
  ///
  /// **`tipoPermiso` en null = vacación**, y entonces la clave no viaja: la ruta
  /// `/vacacion/registrar` lo fuerza a `'vac'` del lado del servidor. En el
  /// permiso sí viaja, y es el campo que `PermisoRrhhEscrituraDto` NO declaraba
  /// cuando se escribió esto. Sin declararlo, Jackson lo descarta y el permiso
  /// se graba con el tipo en NULL: 28 filas de `trh_permiso` ya están así, y
  /// son de un flujo que el legacy dejó muerto.
  ///
  /// **`codRelEmplEmpr` no va**: lo resuelve el servidor, igual que en la
  /// colectiva. **`horasAReponer` tampoco**: `p_abm_Permiso` no tiene parámetro
  /// donde guardarlo. **`confirmado` tampoco**: ninguna de las dos rutas emite
  /// un 400 confirmable —`IPermiso.registrarPermiso` ni siquiera recibe el
  /// flag—, así que mandarlo era una clave que el controlador descarta y un
  /// «Guardar igual» que nunca se dispara.
  static Map<String, dynamic> cuerpoPermiso(
    int codEmpleado,
    String? tipoPermiso,
    DateTime desde,
    DateTime hasta,
    String motivo,
  ) => {
    'codEmpleado': codEmpleado,
    if (tipoPermiso != null) 'tipoPermiso': tipoPermiso,
    'desde': prInstante(desde),
    'hasta': prInstante(hasta),
    'motivo': motivo.trim(),
  };

  /// El cuerpo del pago de vacaciones.
  ///
  /// **`dias` y no `diasAPagar`**: el campo del DTO se llama así y ya sirve
  /// —es el mismo para las tres tablas—. Inventar un nombre nuevo repetiría la
  /// falla de `diasAsignados`, que llegaba en 0 sin que se cayera nada.
  ///
  /// **`prDia` y no `prInstante`**: el modal legacy no tiene hora y el servidor
  /// fuerza `hasta = desde`. **`tipoPermiso` tampoco va**: lo pone el servidor
  /// en `'pva'`; dejar que viaje sería dejar pagar días con la etiqueta de otra
  /// cosa.
  static Map<String, dynamic> cuerpoVacacionPagada(
    int codEmpleado,
    DateTime fecha,
    double dias,
    String motivo,
    bool confirmado,
  ) => {
    'codEmpleado': codEmpleado,
    'fecha': prDia(fecha),
    'dias': dias,
    'motivo': motivo.trim(),
    'confirmado': confirmado,
  };

  /// El cuerpo del historial de vacación asignada.
  ///
  /// **La fecha de corte viaja como `fecha`, no como `hasta`**, aunque el
  /// parámetro de acá se llame por lo que significa. El controller la lee de
  /// `PermisoRrhhEscrituraDto.fecha`
  /// (`vacDao.historial(codEmpleado, codRelEmplEmpr, f.getFecha())`), y ese
  /// mismo DTO **también declara un `hasta`** —el del rango de la vacación
  /// colectiva—, así que mandarla con ese nombre no da error de nada: Jackson
  /// la ata al campo equivocado, `fecha` llega null y el corte se corre a hoy
  /// **en silencio**. Es exactamente la falla que tenía `dias`, y por eso este
  /// cuerpo también se compara en `permisos_rrhh_contrato_test`: mirar que las
  /// claves existan en el DTO no alcanza cuando las dos existen.
  ///
  /// Público y estático por lo mismo que [cuerpoAbonoColectivo].
  static Map<String, dynamic> cuerpoHistorialVacAsig(
    int codEmpleado,
    int codRelEmplEmpr,
    DateTime? hasta,
  ) => {
    'codEmpleado': codEmpleado,
    // 0 = «la relación vigente, resolvela vos». El SP filtra con
    // `(@x IS NULL OR @x = col)`, así que un 0 de más vaciaría la lista.
    'codRelEmplEmpr': codRelEmplEmpr == 0 ? null : codRelEmplEmpr,
    // Null = hoy. El relleno de aniversarios sintéticos corre hasta acá.
    'fecha': hasta == null ? null : prDia(hasta),
  };

  /// El cabezal del abono colectivo, el mismo para simular y para aplicar.
  ///
  /// **La clave es `dias`**, que es como se llama el campo del DTO del
  /// servidor. Con `diasAbonados` —el nombre de la columna, que es otra cosa—
  /// Jackson la descartaba en silencio y, por ser `double` primitivo, el
  /// backend recibía 0: la carga se guardaba con cero días para todos.
  ///
  /// **Público y estático para que `permisos_rrhh_contrato_test` compare las
  /// claves de verdad** y no una copia escrita a mano al lado. Un cuerpo mal
  /// nombrado no da error: da un campo en cero.
  static Map<String, dynamic> cuerpoAbonoColectivo(
    List<int> codEmpleados,
    double dias,
    String motivo,
    DateTime fecha,
  ) => {
    'codEmpleados': codEmpleados,
    'dias': dias,
    'motivo': motivo.trim(),
    'fecha': prDia(fecha),
  };

  /// El mismo cuerpo para simular y para aplicar: si los dos no describen
  /// exactamente el mismo lote, la confirmación estaría hablando de otra cosa
  /// que la que se guarda.
  ///
  /// **Con hora, no sólo día** (`prInstante`): los días se calculan avanzando de
  /// 30 en 30 minutos entre `desde` y `hasta`, así que perder la hora convierte
  /// medio día en cero.
  ///
  /// Público y estático por lo mismo que [cuerpoAbonoColectivo].
  static Map<String, dynamic> cuerpoVacacionColectiva(
    List<int> codEmpleados,
    DateTime desde,
    DateTime hasta,
    String motivo,
  ) => {
    'codEmpleados': codEmpleados,
    'desde': prInstante(desde),
    'hasta': prInstante(hasta),
    'motivo': motivo.trim(),
  };

  /// El alta y la edición: mandan la fila y **devuelven la fila releída**.
  ///
  /// Va por [_postConfirmable] y no por un helper de `BaseApiRepository` por
  /// dos motivos que se tocan:
  ///
  /// 1. **`data` es un objeto, no un id.** El controller responde
  ///    `respuestaEscritura(fila, creado)`, o sea 201 con la fila en el alta y
  ///    200 en la edición. `postAndReturnId` haría `BigInt.from` sobre un Map.
  /// 2. **El status hay que poder leerlo.** Los helpers traducen la
  ///    `DioException` a un `Exception` con el texto adentro y ahí se pierde;
  ///    acá el **400 con `confirmable: true`** es una pregunta que se puede
  ///    contestar insistiendo, y el 409 es un doble toque que no.
  ///
  /// [siNoVino] es lo que se devuelve si el servidor contestó sin cuerpo (204,
  /// o `data` en null): la escritura ocurrió, así que no es un error — se
  /// devuelve lo que se mandó y el refresco de la grilla dirá la verdad.
  Future<T> _filaEscrita<T>({
    required String endpoint,
    required Map<String, dynamic> data,
    required T Function(Map<String, dynamic>) fromJson,
    required T siNoVino,
    required String errorMessage,
  }) async {
    final r = await _postConfirmable(endpoint, data, errorMessage);
    final cuerpo = r.data;
    final fila = cuerpo is Map ? cuerpo['data'] : null;
    return fila is Map<String, dynamic> ? fromJson(fila) : siNoVino;
  }

  /// Para las escrituras que **no devuelven la fila** pero sí necesitan
  /// distinguir el 400 confirmable del 409.
  ///
  /// Es el caso de las tres del permiso individual: `p_abm_Permiso` no devuelve
  /// el id generado ni hace `SELECT` de retorno, así que del otro lado no hay
  /// fila que releer con certeza —sin unique constraint, dos altas simultáneas
  /// de la misma persona confundirían la relectura— y lo que vuelve es el
  /// resumen en el `message`.
  ///
  /// **No se usa [_mensaje] para esto**: aquel va por
  /// `postAndReturnFullResponse`, que traduce la `DioException` a un String y
  /// ahí se pierde el status. En una pantalla que paga días, perder la
  /// diferencia entre «esto es raro, ¿seguís?» y «esto ya se guardó hace diez
  /// segundos» es perder justamente la protección.
  Future<String> _mensajeConfirmable(
    String endpoint,
    Map<String, dynamic> data,
    String errorMessage,
  ) async {
    final r = await _postConfirmable(endpoint, data, errorMessage);
    final cuerpo = r.data;
    return cuerpo is Map ? prStr(cuerpo['message']) : '';
  }

  /// El POST de las escrituras del módulo, con el **status conservado**.
  ///
  /// Va con `dio.post` a mano y no con un helper de `BaseApiRepository` porque
  /// aquellos traducen la `DioException` a un `Exception` con el texto adentro
  /// y ahí se pierde el status — que es justo lo que hay que poder distinguir:
  /// el **400 con `confirmable: true`** es una pregunta que se puede contestar
  /// insistiendo, y el 409 es un doble toque que no.
  ///
  /// No se toca `BaseApiRepository`: lo comparten unos 40 llamadores en
  /// producción. El resto de los status sale por el mismo `handleDioError` que
  /// usan los helpers, así que no cambia nada más.
  Future<Response<dynamic>> _postConfirmable(
    String endpoint,
    Map<String, dynamic> data,
    String errorMessage,
  ) async {
    try {
      return await dio.post(endpoint, data: data);
    } on DioException catch (e) {
      final texto = DioClient.handleDioError(e, errorMessage);
      final cuerpo = e.response?.data;
      // El marcador lo pone el backend en el cuerpo del 400. Se lee el flag y
      // **no el texto**: adivinar por la redacción del mensaje es una regla que
      // se rompe la próxima vez que alguien corrija una tilde.
      final confirmable =
          e.response?.statusCode == 400 &&
          cuerpo is Map &&
          cuerpo['confirmable'] == true;
      if (confirmable) throw RequiereConfirmacion(texto);
      throw Exception(texto);
    }
  }

  /// Para las escrituras cuyo resultado es una frase y no un id.
  ///
  /// `postAndReturnFullResponse` lanza el error como **String pelado** y no
  /// como `Exception`, a propósito: la pantalla lo pinta con `'$e'` y así no
  /// sale el prefijo «Exception: » delante del mensaje del servidor.
  Future<String> _mensaje(
    String endpoint,
    Map<String, dynamic> data,
    String errorMessage,
  ) async {
    final r = await postAndReturnFullResponse<Map<String, dynamic>>(
      endpoint: endpoint,
      data: data,
      fromJson: (json) => json,
      errorMessage: errorMessage,
    );
    return prStr(r['message']);
  }
}
