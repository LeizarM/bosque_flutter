import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/base_api_repository.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/armado_propuesta_model.dart';
import 'package:bosque_flutter/data/models/articulo_precio_model.dart';
import 'package:bosque_flutter/data/models/articulo_propuesto_model.dart';
import 'package:bosque_flutter/data/models/clasificacion_precio_model.dart';
import 'package:bosque_flutter/data/models/color_producto_model.dart';
import 'package:bosque_flutter/data/models/costo_iva_it_model.dart';
import 'package:bosque_flutter/data/models/grupo_fam_tipo_rango_gram_model.dart';
import 'package:bosque_flutter/data/models/grupo_familia_sap_model.dart';
import 'package:bosque_flutter/data/models/historial_costo_familia_model.dart';
import 'package:bosque_flutter/data/models/porcentaje_precio_model.dart';
import 'package:bosque_flutter/data/models/presentacion_producto_model.dart';
import 'package:bosque_flutter/data/models/producto_familia_model.dart';
import 'package:bosque_flutter/data/models/proveedor_ext_sap_model.dart';
import 'package:bosque_flutter/data/models/rango_gramaje_model.dart';
import 'package:bosque_flutter/data/models/tc_ancla_model.dart';
import 'package:bosque_flutter/data/models/tipo_producto_model.dart';
import 'package:bosque_flutter/data/models/vista_propuesta_model.dart';
import 'package:bosque_flutter/domain/entities/armado_propuesta_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/articulo_propuesto_entity.dart';
import 'package:bosque_flutter/domain/entities/clasificacion_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/color_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/costo_iva_it_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_fam_tipo_rango_gram_entity.dart';
import 'package:bosque_flutter/domain/entities/grupo_familia_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/historial_costo_familia_entity.dart';
import 'package:bosque_flutter/domain/entities/porcentaje_precio_entity.dart';
import 'package:bosque_flutter/domain/entities/presentacion_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/producto_familia_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_ext_sap_entity.dart';
import 'package:bosque_flutter/domain/entities/rango_gramaje_entity.dart';
import 'package:bosque_flutter/domain/entities/tc_ancla_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_producto_entity.dart';
import 'package:bosque_flutter/domain/entities/vista_propuesta_entity.dart';
import 'package:bosque_flutter/domain/repositories/precios_repository.dart';

/// Implementacion del modulo de Precios (tpr) contra el backend Spring.
///
/// Todos los endpoints son POST, incluidas las lecturas, y los helpers de
/// BaseApiRepository ya resuelven el envelope {message, data, status}, tratan
/// el 204 como exito sin datos y levantan el mensaje del backend en el 400.
/// El 401 lo maneja DioClient de forma centralizada.
class PreciosImpl extends BaseApiRepository implements PreciosRepository {
  // ======================= PROPUESTAS: LECTURAS ==========================

  @override
  Future<List<Map<String, dynamic>>> obtenerPropuestasParaAutorizar() =>
      postAndReturnList<Map<String, dynamic>>(
        endpoint: AppConstants.preciosAutorizacion,
        fromJson: _crudo,
      );

  @override
  Future<List<Map<String, dynamic>>> obtenerEstadosPropuesta() =>
      postAndReturnList<Map<String, dynamic>>(
        endpoint: AppConstants.preciosEstadoPropuesta,
        fromJson: _crudo,
      );

  @override
  Future<List<Map<String, dynamic>>> obtenerCostosFlete() =>
      postAndReturnList<Map<String, dynamic>>(
        endpoint: AppConstants.preciosCostoFlete,
        fromJson: _crudo,
      );

  @override
  Future<List<ProveedorExtSapEntity>> obtenerProveedoresSap() async {
    final modelos = await postAndReturnList<ProveedorExtSapModel>(
      endpoint: AppConstants.preciosProveedoresSap,
      fromJson: ProveedorExtSapModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerFamilias({
    int? codigoFamilia,
    BigInt? idGrpFamiliaSap,
    BigInt? idProveedorSap,
    BigInt? idPresentacion,
    BigInt? idTipo,
    BigInt? idRangoGram,
    String? formato,
    String? gramaje,
    BigInt? idColor,
    int? estado,
  }) => postAndReturnList<Map<String, dynamic>>(
    endpoint: AppConstants.preciosFamilias,
    // Las claves que no viajan quedan en NULL en el procedimiento y no
    // filtran. Por eso el cuerpo se arma sin los campos nulos en vez de
    // mandar el model completo: el model serializa los ids vacios como 0, y
    // un 0 SI filtra, con lo que el listado volveria vacio.
    data: _filtro({
      'codigoFamilia': codigoFamilia,
      'idGrpFamiliaSap': idGrpFamiliaSap?.toInt(),
      'idProveedorSap': idProveedorSap?.toInt(),
      'idPresentacion': idPresentacion?.toInt(),
      'idTipo': idTipo?.toInt(),
      'idRangoGram': idRangoGram?.toInt(),
      'formato': formato,
      'gramaje': gramaje,
      'idColor': idColor?.toInt(),
      'estado': estado,
    }),
    fromJson: _crudo,
  );

  @override
  Future<List<Map<String, dynamic>>> obtenerFamiliasPorGrupo(
    BigInt idGrpFamiliaSap,
  ) => postAndReturnList<Map<String, dynamic>>(
    endpoint: AppConstants.preciosFamiliasPorGrupo,
    data: {'id': idGrpFamiliaSap.toInt()},
    fromJson: _crudo,
  );

  @override
  Future<List<ArticuloPrecioEntity>> obtenerArticulosPorFamilias(
    List<int> codigosFamilia,
  ) async {
    // Sin familias no hay nada que preguntar: el procedimiento concatena la
    // cadena dentro de un sp_executesql y una cadena vacia no significa
    // "todas".
    if (codigosFamilia.isEmpty) return const [];

    final modelos = await postAndReturnList<ArticuloPrecioModel>(
      endpoint: AppConstants.preciosArticulosPorFamilias,
      // Codigos separados por coma y con coma final: "12,13,14,".
      data: {'codCad': '${codigosFamilia.join(',')},'},
      fromJson: ArticuloPrecioModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Map<String, dynamic>?> obtenerFamilia(int codigoFamilia) =>
      postAndReturnObject<Map<String, dynamic>>(
        endpoint: AppConstants.preciosCargarFamilia,
        data: {'codigoFamilia': codigoFamilia},
        fromJson: _crudo,
      );

  @override
  Future<BigInt> registrarFamilia(
    ProductoFamiliaEntity familia, {
    required bool alta,
    List<PorcentajePrecioEntity>? porcentajes,
  }) => postAndReturnId(
    endpoint:
        alta
            ? AppConstants.preciosFamiliaRegistrar
            : AppConstants.preciosFamiliaActualizar,
    data: {
      ..._sinAudUsuario(ProductoFamiliaModel.fromEntity(familia).toJson()),
      if (porcentajes != null)
        'porcentajes': [
          for (final p in porcentajes)
            _sinAudUsuario(PorcentajePrecioModel.fromEntity(p).toJson()),
        ],
    },
  );

  @override
  Future<List<Map<String, dynamic>>> obtenerListasParaPorcentaje() =>
      postAndReturnList<Map<String, dynamic>>(
        endpoint: AppConstants.preciosFamiliaListasParaPorcentaje,
        data: const {},
        fromJson: _crudo,
      );

  @override
  Future<void> cambiarEstadoFamilia(
    int codigoFamilia, {
    required bool activa,
  }) => postAndReturnId(
    endpoint: AppConstants.preciosFamiliaCambiarEstado,
    data: {'codigoFamilia': codigoFamilia, 'estado': activa ? 1 : 0},
  );

  @override
  Future<void> eliminarFamilia(int codigoFamilia) => postAndReturnId(
    endpoint: AppConstants.preciosFamiliaEliminar,
    data: {'codigoFamilia': codigoFamilia},
  );

  @override
  Future<void> asignarSapFamilia(
    int codigoFamilia, {
    BigInt? idGrpFamiliaSap,
    BigInt? idProveedorSap,
  }) => postAndReturnId(
    endpoint: AppConstants.preciosFamiliaAsignarSap,
    data: {
      'codigoFamilia': codigoFamilia,
      'idGrpFamiliaSap': (idGrpFamiliaSap ?? BigInt.zero).toInt(),
      'idProveedorSap': (idProveedorSap ?? BigInt.zero).toInt(),
    },
  );

  @override
  Future<void> sincronizarCatalogosSap() => postAndReturnId(
    endpoint: AppConstants.preciosFamiliaSincronizarSap,
    data: const {},
  );

  @override
  Future<List<HistorialCostoFamiliaEntity>> obtenerHistorialCosto(
    int codigoFamilia,
  ) async {
    final modelos = await postAndReturnList<HistorialCostoFamiliaModel>(
      endpoint: AppConstants.preciosFamiliaHistorialCosto,
      data: {'codigoFamilia': codigoFamilia},
      fromJson: HistorialCostoFamiliaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerPreciosTonPorFamilia(
    int codigoFamilia,
  ) => postAndReturnList<Map<String, dynamic>>(
    endpoint: AppConstants.preciosPrecioTonPorFamilia,
    data: {'codigoFamilia': codigoFamilia},
    fromJson: _crudo,
  );

  @override
  Future<VistaPropuestaEntity> obtenerVistaPropuesta(BigInt idPropuesta) async {
    final modelo = await postAndReturnObject<VistaPropuestaModel>(
      endpoint: AppConstants.preciosVistaPropuesta,
      data: {'id': idPropuesta.toInt()},
      fromJson: VistaPropuestaModel.fromJson,
      errorMessage: 'No se pudo cargar la propuesta.',
    );
    // Sin cuerpo es una propuesta sin nada que mostrar, no un error.
    return modelo?.toEntity() ??
        const VistaPropuestaEntity(
          tipo: 1,
          conComparacion: false,
          listas: [],
          filas: [],
        );
  }

  // ====================== PROPUESTAS: ESCRITURAS =========================

  // Las escrituras sueltas de la cabecera, el flete, el precio y el costo se
  // quitaron el 2026-09-25 (ver precios_repository.dart).

  // ======================= ARMADO DE UNA PROPUESTA =======================

  @override
  Future<FletesArmadoEntity> obtenerFletesArmado(BigInt? idPropuesta) async {
    final modelo = await postAndReturnObject<FletesArmadoModel>(
      endpoint: AppConstants.preciosArmadoFletes,
      // 0 = alta: el backend devuelve las sucursales con el flete sugerido.
      data: {'id': idPropuesta?.toInt() ?? 0},
      fromJson: FletesArmadoModel.fromJson,
    );
    return modelo?.toEntity() ??
        const FletesArmadoEntity(deLaPropuesta: false, fletes: []);
  }

  @override
  Future<List<FamiliaArmadaEntity>> obtenerFamiliasArmadas(
    BigInt idPropuesta,
  ) async {
    final modelos = await postAndReturnList<FamiliaArmadaModel>(
      endpoint: AppConstants.preciosArmadoFamilias,
      data: {'id': idPropuesta.toInt()},
      fromJson: FamiliaArmadaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CalculoFamiliaEntity> calcularFamiliaArmado({
    BigInt? idPropuesta,
    required int codigoFamilia,
    double? costo,
    List<FleteArmadoEntity>? fletes,
    Map<BigInt, double>? porcentajes,
  }) => _calculoFamilia(
    AppConstants.preciosArmadoCalcularFamilia,
    PedidoFamiliaArmadoModel(
      idPropuesta: idPropuesta,
      codigoFamilia: codigoFamilia,
      costo: costo,
      fletes: fletes,
      porcentajes: porcentajes,
    ),
  );

  @override
  Future<CalculoFamiliaEntity> guardarFamiliaArmado({
    BigInt? idPropuesta,
    String? titulo,
    String? obs,
    List<FleteArmadoEntity>? fletes,
    required int codigoFamilia,
    required double costo,
    Map<BigInt, double>? porcentajes,
  }) => _calculoFamilia(
    AppConstants.preciosArmadoGuardarFamilia,
    PedidoFamiliaArmadoModel(
      idPropuesta: idPropuesta,
      titulo: titulo,
      obs: obs,
      fletes: fletes,
      codigoFamilia: codigoFamilia,
      costo: costo,
      porcentajes: porcentajes,
    ),
  );

  /// Un lote de veinte familias tarda unos segundos; se espera hasta dos
  /// minutos por si la base esta ocupada, en lugar de los 30 s de BaseOptions.
  static const _esperaLote = Duration(minutes: 2);

  @override
  Future<List<CalculoFamiliaEntity>> calcularFamiliasArmado({
    BigInt? idPropuesta,
    List<FleteArmadoEntity>? fletes,
    required Map<int, double> costos,
  }) async {
    final datos = await _postLote(
      AppConstants.preciosArmadoCalcularFamilias,
      PedidoLoteArmadoModel(
        idPropuesta: idPropuesta,
        fletes: fletes,
        costos: costos,
      ).toJson(),
      'No se pudieron calcular las familias.',
    );
    return [
      for (final f in (datos as List<dynamic>? ?? const []))
        CalculoFamiliaModel.fromJson(
          Map<String, dynamic>.from(f as Map),
        ).toEntity(),
    ];
  }

  @override
  Future<ResultadoArmadoEntity> guardarFamiliasArmado({
    BigInt? idPropuesta,
    String? titulo,
    String? obs,
    List<FleteArmadoEntity>? fletes,
    required Map<int, double> costos,
  }) async {
    final datos = await _postLote(
      AppConstants.preciosArmadoGuardarFamilias,
      PedidoLoteArmadoModel(
        idPropuesta: idPropuesta,
        titulo: titulo,
        obs: obs,
        fletes: fletes,
        costos: costos,
      ).toJson(),
      'No se pudieron guardar las familias.',
    );
    if (datos is! Map) {
      throw Exception('El servidor no confirmó la operación.');
    }
    return ResultadoArmadoModel.fromJson(
      Map<String, dynamic>.from(datos),
    ).toEntity();
  }

  /// El `data` de la respuesta de una operacion en lote, con la espera larga.
  Future<Object?> _postLote(
    String endpoint,
    Map<String, dynamic> cuerpo,
    String siFalla,
  ) async {
    try {
      final r = await dio.post(
        endpoint,
        data: cuerpo,
        options: Options(receiveTimeout: _esperaLote),
      );
      final raiz = r.data;
      return raiz is Map ? raiz['data'] : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        throw Exception(e.response!.data['message'] ?? siFalla);
      }
      throw Exception(DioClient.handleDioError(e, siFalla));
    }
  }

  @override
  Future<ResultadoArmadoEntity> guardarFletesArmado({
    required BigInt idPropuesta,
    required List<FleteArmadoEntity> fletes,
  }) => _resultado(AppConstants.preciosArmadoGuardarFletes, {
    'idPropuesta': idPropuesta.toInt(),
    'fletes': [for (final f in fletes) FleteArmadoModel.fromEntity(f).toJson()],
  });

  @override
  Future<List<ArticuloPropuestoEntity>> obtenerArticulosArmados(
    BigInt idPropuesta,
  ) async {
    final modelos = await postAndReturnList<ArticuloPropuestoModel>(
      endpoint: AppConstants.preciosArmadoArticulos,
      data: {'id': idPropuesta.toInt()},
      fromJson: ArticuloPropuestoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ResultadoArmadoEntity> agregarArticulosArmado({
    BigInt? idPropuesta,
    String? titulo,
    String? obs,
    required List<String> codArticulos,
  }) {
    final esAlta = idPropuesta == null || idPropuesta <= BigInt.zero;
    return _resultado(AppConstants.preciosArmadoAgregarArticulos, {
      if (!esAlta) 'idPropuesta': idPropuesta.toInt(),
      if (esAlta) 'titulo': titulo,
      if (esAlta) 'obs': obs,
      'codArticulos': codArticulos,
    });
  }

  @override
  Future<ResultadoArmadoEntity> quitarArticuloArmado({
    required BigInt idPropuesta,
    required BigInt idArticulo,
  }) => _resultado(AppConstants.preciosArmadoQuitarArticulo, {
    'idPropuesta': idPropuesta.toInt(),
    'idArticulo': idArticulo.toInt(),
  });

  @override
  Future<void> sincronizarArticulosSap() async {
    try {
      await dio.post(
        AppConstants.preciosArmadoSincronizarArticulosSap,
        data: const <String, dynamic>{},
        // El legacy mide hasta diez minutos para esta rama. Los 30 s de
        // BaseOptions cortarian la espera mientras el servidor sigue
        // trabajando, y el usuario veria un error que no es.
        options: Options(receiveTimeout: const Duration(minutes: 10)),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        throw Exception(
          e.response!.data['message'] ??
              'No se pudieron actualizar los artículos desde SAP.',
        );
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'La actualización desde SAP tardó más de diez minutos y se dejó de '
          'esperar. Puede que el servidor la termine igual: vuelva a buscar '
          'los artículos en unos minutos.',
        );
      }
      throw Exception(
        DioClient.handleDioError(
          e,
          'No se pudieron actualizar los artículos desde SAP.',
        ),
      );
    }
  }

  // ============================== REPORTES ===============================

  /// Los 30 s de BaseOptions no alcanzan para la propuesta: los articulos no
  /// creados salen de un OPENROWSET a otro servidor.
  static const _esperaPropuesta = Duration(minutes: 3);
  static const _esperaReporte = Duration(minutes: 2);

  @override
  Future<Uint8List> reportePropuesta(BigInt idPropuesta) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.preciosReportePropuesta,
        data: {'id': idPropuesta.toInt()},
        receiveTimeout: _esperaPropuesta,
      );

  @override
  Future<Uint8List> reportePreciosGrupo(BigInt idGrpFamiliaSap) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.preciosReportePreciosGrupo,
        data: {'id': idGrpFamiliaSap.toInt()},
        receiveTimeout: _esperaReporte,
      );

  @override
  Future<Uint8List> reportePreciosTodas() => DioClient.descargarReportePdf(
    endpoint: AppConstants.preciosReportePreciosTodas,
    data: const {},
    receiveTimeout: _esperaReporte,
  );

  @override
  Future<Uint8List> reporteFamiliasActivas() => DioClient.descargarReportePdf(
    endpoint: AppConstants.preciosReporteFamiliasActivas,
    data: const {},
    receiveTimeout: _esperaReporte,
  );

  /// calcularFamilia y guardarFamilia devuelven la misma grilla.
  Future<CalculoFamiliaEntity> _calculoFamilia(
    String endpoint,
    PedidoFamiliaArmadoModel pedido,
  ) async {
    final modelo = await postAndReturnObject<CalculoFamiliaModel>(
      endpoint: endpoint,
      data: pedido.toJson(),
      fromJson: CalculoFamiliaModel.fromJson,
    );
    if (modelo == null) {
      throw Exception('El servidor no devolvió la grilla de la familia.');
    }
    return modelo.toEntity();
  }

  Future<ResultadoArmadoEntity> _resultado(
    String endpoint,
    Map<String, dynamic> cuerpo,
  ) async {
    final modelo = await postAndReturnObject<ResultadoArmadoModel>(
      endpoint: endpoint,
      data: cuerpo,
      fromJson: ResultadoArmadoModel.fromJson,
    );
    if (modelo == null) {
      throw Exception('El servidor no confirmó la operación.');
    }
    return modelo.toEntity();
  }

  // ====================== CIRCUITO DE AUTORIZACION =======================

  @override
  Future<BigInt> resolverPropuesta({
    required BigInt idPropuesta,
    required int esAprobada,
  }) => postAndReturnId(
    endpoint: AppConstants.preciosResolverPropuesta,
    data: {'idPropuesta': idPropuesta.toInt(), 'esAprobada': esAprobada},
  );

  @override
  Future<BigInt> marcarEnEspera(BigInt idPropuesta) => postAndReturnId(
    endpoint: AppConstants.preciosMarcarEnEspera,
    data: {'id': idPropuesta.toInt()},
  );

  /// El archivo viaja crudo, como los PDF: por eso el mismo descargador.
  @override
  Future<Uint8List> generarPropuesta(BigInt idPropuesta) =>
      DioClient.descargarReportePdf(
        endpoint: AppConstants.preciosGenerarPropuesta,
        data: {'id': idPropuesta.toInt()},
        receiveTimeout: _esperaReporte,
      );

  // ============================ PORCENTAJES ==============================

  @override
  Future<List<Map<String, dynamic>>> obtenerPorcentajesPorFamilia(
    int codigoFamilia,
  ) => postAndReturnList<Map<String, dynamic>>(
    endpoint: AppConstants.preciosPorcentajePorFamilia,
    // El backend recibe la familia dentro de un Producto y solo mira este
    // campo. Va crudo y no por _filtro: es obligatorio, y si faltara el
    // backend responde 400 con su mensaje, que es la respuesta correcta.
    data: {'codigoFamilia': codigoFamilia},
    // Grilla y no tabla: trae el nombre de la sucursal, el de la lista de
    // precios y el vpp, que no son columnas de tpr_porcentaje. Ademas el
    // margen viene como `porcentaje` y no como `porcen`, asi que el model de
    // la tabla no lo leeria.
    fromJson: _crudo,
  );

  @override
  Future<List<Map<String, dynamic>>> obtenerDestinosPorcentajeGrupo(
    BigInt idGrpFamiliaSap,
  ) => postAndReturnList<Map<String, dynamic>>(
    endpoint: AppConstants.preciosPorcentajeParaGrupo,
    data: {'id': idGrpFamiliaSap.toInt()},
    fromJson: _crudo,
  );

  @override
  Future<List<Map<String, dynamic>>> obtenerPorcentajesFaltantes(
    int codigoFamilia,
  ) => postAndReturnList<Map<String, dynamic>>(
    endpoint: AppConstants.preciosPorcentajeFaltante,
    data: {'codigoFamilia': codigoFamilia},
    fromJson: _crudo,
  );

  @override
  Future<List<PorcentajePrecioEntity>> obtenerPorcentajes({
    int? codigoFamilia,
    BigInt? idClasificacion,
  }) async {
    final modelos = await postAndReturnList<PorcentajePrecioModel>(
      endpoint: AppConstants.preciosPorcentajeListar,
      // Los campos ausentes llegan como NULL y no filtran; un 0 SI filtra. Por
      // eso el cuerpo no se arma con el toJson del model, que rellena los
      // vacios con cero.
      data: _filtro({
        'codigoFamilia': codigoFamilia,
        'idClasificacion': idClasificacion?.toInt(),
      }),
      fromJson: PorcentajePrecioModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarPorcentaje(PorcentajePrecioEntity porcentaje) =>
      postAndReturnId(
        endpoint: AppConstants.preciosRegistrarPorcentaje,
        // Una fila por llamada: el procedimiento no aplica un porcentaje a
        // varias listas de precios de una vez.
        data: _sinAudUsuario(
          PorcentajePrecioModel.fromEntity(porcentaje).toJson(),
        ),
      );

  // ============================== COLOR ==================================

  @override
  Future<List<ColorProductoEntity>> obtenerColores({BigInt? idColor}) async {
    final modelos = await postAndReturnList<ColorProductoModel>(
      endpoint: AppConstants.preciosColorListar,
      data: {'id': (idColor ?? BigInt.zero).toInt()},
      fromJson: ColorProductoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ColorProductoEntity>> obtenerColoresActivos() async {
    final modelos = await postAndReturnList<ColorProductoModel>(
      endpoint: AppConstants.preciosColorActivos,
      fromJson: ColorProductoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarColor(ColorProductoEntity color) => postAndReturnId(
    endpoint: AppConstants.preciosColorRegistrar,
    data: _sinAudUsuario(ColorProductoModel.fromEntity(color).toJson()),
  );

  @override
  Future<BigInt> eliminarColor(ColorProductoEntity color) => postAndReturnId(
    endpoint: AppConstants.preciosColorEliminar,
    data: _sinAudUsuario(ColorProductoModel.fromEntity(color).toJson()),
  );

  // =========================== TIPO DE PAPEL =============================

  @override
  Future<List<TipoProductoEntity>> obtenerTipos({BigInt? idTipo}) async {
    final modelos = await postAndReturnList<TipoProductoModel>(
      endpoint: AppConstants.preciosTipoListar,
      data: {'id': (idTipo ?? BigInt.zero).toInt()},
      fromJson: TipoProductoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<TipoProductoEntity>> obtenerTiposActivos() async {
    final modelos = await postAndReturnList<TipoProductoModel>(
      endpoint: AppConstants.preciosTipoActivos,
      fromJson: TipoProductoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarTipo(TipoProductoEntity tipo) => postAndReturnId(
    endpoint: AppConstants.preciosTipoRegistrar,
    data: _sinAudUsuario(TipoProductoModel.fromEntity(tipo).toJson()),
  );

  @override
  Future<BigInt> eliminarTipo(TipoProductoEntity tipo) => postAndReturnId(
    endpoint: AppConstants.preciosTipoEliminar,
    data: _sinAudUsuario(TipoProductoModel.fromEntity(tipo).toJson()),
  );

  // =========================== PRESENTACION ==============================

  @override
  Future<List<PresentacionProductoEntity>> obtenerPresentaciones() async {
    final modelos = await postAndReturnList<PresentacionProductoModel>(
      endpoint: AppConstants.preciosPresentacionListar,
      fromJson: PresentacionProductoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<PresentacionProductoEntity>> buscarPresentaciones({
    BigInt? idPresentacion,
    String? presentacion,
    int? estado,
  }) async {
    final modelos = await postAndReturnList<PresentacionProductoModel>(
      endpoint: AppConstants.preciosPresentacionBuscar,
      data: _filtro({
        'idPresentacion': idPresentacion?.toInt(),
        'presentacion': presentacion,
        'estado': estado,
      }),
      fromJson: PresentacionProductoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<PresentacionProductoEntity>>
  obtenerPresentacionesActivas() async {
    final modelos = await postAndReturnList<PresentacionProductoModel>(
      endpoint: AppConstants.preciosPresentacionActivas,
      fromJson: PresentacionProductoModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<PresentacionProductoEntity?> obtenerPresentacion(
    BigInt idPresentacion,
  ) async {
    final modelo = await postAndReturnObject<PresentacionProductoModel>(
      endpoint: AppConstants.preciosPresentacionObtener,
      data: {'id': idPresentacion.toInt()},
      fromJson: PresentacionProductoModel.fromJson,
    );
    return modelo?.toEntity();
  }

  @override
  Future<BigInt> registrarPresentacion(
    PresentacionProductoEntity presentacion,
  ) => postAndReturnId(
    endpoint: AppConstants.preciosPresentacionRegistrar,
    data: _sinAudUsuario(
      PresentacionProductoModel.fromEntity(presentacion).toJson(),
    ),
  );

  @override
  Future<BigInt> eliminarPresentacion(
    PresentacionProductoEntity presentacion,
  ) => postAndReturnId(
    endpoint: AppConstants.preciosPresentacionEliminar,
    data: _sinAudUsuario(
      PresentacionProductoModel.fromEntity(presentacion).toJson(),
    ),
  );

  // ========================= RANGO DE GRAMAJE ============================

  @override
  Future<List<RangoGramajeEntity>> obtenerRangosGramaje() async {
    final modelos = await postAndReturnList<RangoGramajeModel>(
      endpoint: AppConstants.preciosRangoGramajeListar,
      fromJson: RangoGramajeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<RangoGramajeEntity?> obtenerRangoGramaje(BigInt idRangoGram) async {
    final modelo = await postAndReturnObject<RangoGramajeModel>(
      endpoint: AppConstants.preciosRangoGramajeObtener,
      data: {'id': idRangoGram.toInt()},
      fromJson: RangoGramajeModel.fromJson,
    );
    return modelo?.toEntity();
  }

  @override
  Future<List<RangoGramajeEntity>> obtenerRangosGramajeParaCombo() async {
    // El backend agrega la etiqueta armada "[ min - max ]"; el model la ignora
    // y la entity la vuelve a armar, asi el texto es el mismo venga de la
    // lista cruda o de esta.
    final modelos = await postAndReturnList<RangoGramajeModel>(
      endpoint: AppConstants.preciosRangoGramajeCombo,
      fromJson: RangoGramajeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<RangoGramajeEntity>> obtenerRangosPorGrupoFamiliaYTipo({
    required int idGrpFamiliaSap,
    required int idTipo,
  }) async {
    final modelos = await postAndReturnList<RangoGramajeModel>(
      endpoint: AppConstants.preciosRangoGramajePorGrupoFamiliaTipo,
      // El cuerpo es la clave natural de la tabla puente: los dos ids son
      // obligatorios y el backend responde 400 si falta alguno.
      data: {'idGrpFamiliaSap': idGrpFamiliaSap, 'idTipo': idTipo},
      fromJson: RangoGramajeModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarRangoGramaje(RangoGramajeEntity rango) =>
      postAndReturnId(
        endpoint: AppConstants.preciosRangoGramajeRegistrar,
        data: _sinAudUsuario(RangoGramajeModel.fromEntity(rango).toJson()),
      );

  @override
  Future<BigInt> eliminarRangoGramaje(RangoGramajeEntity rango) =>
      postAndReturnId(
        endpoint: AppConstants.preciosRangoGramajeEliminar,
        data: _sinAudUsuario(RangoGramajeModel.fromEntity(rango).toJson()),
      );

  // ======================= GRUPO DE FAMILIA SAP ==========================

  @override
  Future<List<GrupoFamiliaSapEntity>> obtenerGruposFamiliaSap() async {
    final modelos = await postAndReturnList<GrupoFamiliaSapModel>(
      endpoint: AppConstants.preciosGrupoFamiliaSapListar,
      fromJson: GrupoFamiliaSapModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<GrupoFamiliaSapEntity?> obtenerGrupoFamiliaSap(
    BigInt idGrpFamiliaSap,
  ) async {
    // El backend devuelve una lista de una sola fila, no un objeto: usa el
    // mismo helper de listado que el resto de sus lecturas.
    final modelos = await postAndReturnList<GrupoFamiliaSapModel>(
      endpoint: AppConstants.preciosGrupoFamiliaSapObtener,
      data: {'id': idGrpFamiliaSap.toInt()},
      fromJson: GrupoFamiliaSapModel.fromJson,
    );
    return modelos.isEmpty ? null : modelos.first.toEntity();
  }

  @override
  Future<List<GrupoFamiliaSapEntity>> buscarGruposFamiliaSap({
    BigInt? idGrpFamiliaSap,
    String? codGrpFamSap,
    String? codGrpFamSapEpp,
    String? codGrpFamSapProdPap,
    String? grpFam,
    String? alias,
  }) async {
    final modelos = await postAndReturnList<GrupoFamiliaSapModel>(
      endpoint: AppConstants.preciosGrupoFamiliaSapBuscar,
      // Igual que en el listado de familias: se mandan solo los campos con
      // valor, porque el model serializa los vacios como 0 o cadena vacia y
      // eso filtraria de verdad.
      data: _filtro({
        'idGrpFamiliaSap': idGrpFamiliaSap?.toInt(),
        'codGrpFamSap': codGrpFamSap,
        'codGrpFamSapEpp': codGrpFamSapEpp,
        'codGrpFamSapProdPap': codGrpFamSapProdPap,
        'grpFam': grpFam,
        'alias': alias,
      }),
      fromJson: GrupoFamiliaSapModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarGrupoFamiliaSap(GrupoFamiliaSapEntity grupo) =>
      postAndReturnId(
        endpoint: AppConstants.preciosGrupoFamiliaSapRegistrar,
        data: _sinAudUsuario(GrupoFamiliaSapModel.fromEntity(grupo).toJson()),
      );

  @override
  Future<BigInt> eliminarGrupoFamiliaSap(BigInt idGrpFamiliaSap) =>
      postAndReturnId(
        endpoint: AppConstants.preciosGrupoFamiliaSapEliminar,
        data: {'id': idGrpFamiliaSap.toInt()},
      );

  // ======================= PROVEEDOR EXTERNO SAP =========================

  @override
  Future<List<ProveedorExtSapEntity>> obtenerProveedores() async {
    final modelos = await postAndReturnList<ProveedorExtSapModel>(
      endpoint: AppConstants.preciosProveedorSapListar,
      fromJson: ProveedorExtSapModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ProveedorExtSapEntity>> buscarProveedores({
    BigInt? idProveedorSap,
    String? codProvExtSap,
    String? proveedorExtSap,
  }) async {
    final modelos = await postAndReturnList<ProveedorExtSapModel>(
      endpoint: AppConstants.preciosProveedorSapBuscar,
      data: _filtro({
        'idProveedorSap': idProveedorSap?.toInt(),
        'codProvExtSap': codProvExtSap,
        'proveedorExtSap': proveedorExtSap,
      }),
      fromJson: ProveedorExtSapModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ProveedorExtSapEntity?> obtenerProveedor(BigInt idProveedorSap) async {
    final modelo = await postAndReturnObject<ProveedorExtSapModel>(
      endpoint: AppConstants.preciosProveedorSapObtener,
      data: {'id': idProveedorSap.toInt()},
      fromJson: ProveedorExtSapModel.fromJson,
    );
    return modelo?.toEntity();
  }

  @override
  Future<BigInt> registrarProveedor(ProveedorExtSapEntity proveedor) =>
      postAndReturnId(
        endpoint: AppConstants.preciosProveedorSapRegistrar,
        data: _sinAudUsuario(
          ProveedorExtSapModel.fromEntity(proveedor).toJson(),
        ),
      );

  @override
  Future<BigInt> eliminarProveedor(ProveedorExtSapEntity proveedor) =>
      postAndReturnId(
        endpoint: AppConstants.preciosProveedorSapEliminar,
        data: _sinAudUsuario(
          ProveedorExtSapModel.fromEntity(proveedor).toJson(),
        ),
      );

  // ===================== PARAMETROS DE GRAMAJE ===========================

  @override
  Future<List<GrupoFamTipoRangoGramEntity>> obtenerParametrosGramaje() async {
    final modelos = await postAndReturnList<GrupoFamTipoRangoGramModel>(
      endpoint: AppConstants.preciosGrupoFamTipoRangoListar,
      fromJson: GrupoFamTipoRangoGramModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<GrupoFamTipoRangoGramEntity>> obtenerParametrosPorGrupoFamilia(
    BigInt idGrpFamiliaSap,
  ) async {
    final modelos = await postAndReturnList<GrupoFamTipoRangoGramModel>(
      endpoint: AppConstants.preciosGrupoFamTipoRangoPorGrupoFamilia,
      data: {'id': idGrpFamiliaSap.toInt()},
      fromJson: GrupoFamTipoRangoGramModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<GrupoFamTipoRangoGramEntity?> obtenerParametroGramaje({
    required int idGrpFamiliaSap,
    required int idTipo,
  }) async {
    final modelo = await postAndReturnObject<GrupoFamTipoRangoGramModel>(
      endpoint: AppConstants.preciosGrupoFamTipoRangoObtener,
      data: {'idGrpFamiliaSap': idGrpFamiliaSap, 'idTipo': idTipo},
      fromJson: GrupoFamTipoRangoGramModel.fromJson,
    );
    return modelo?.toEntity();
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerParametrosGramajePivote() =>
      postAndReturnList<Map<String, dynamic>>(
        endpoint: AppConstants.preciosGrupoFamTipoRangoParametros,
        fromJson: _crudo,
      );

  @override
  Future<BigInt> registrarParametroGramaje(GrupoFamTipoRangoGramEntity par) =>
      postAndReturnId(
        // El id generado vuelve siempre en cero: la tabla no tiene IDENTITY.
        endpoint: AppConstants.preciosGrupoFamTipoRangoRegistrar,
        data: _sinAudUsuario(
          GrupoFamTipoRangoGramModel.fromEntity(par).toJson(),
        ),
      );

  @override
  Future<BigInt> eliminarParametroGramaje(GrupoFamTipoRangoGramEntity par) =>
      postAndReturnId(
        endpoint: AppConstants.preciosGrupoFamTipoRangoEliminar,
        data: _sinAudUsuario(
          GrupoFamTipoRangoGramModel.fromEntity(par).toJson(),
        ),
      );

  // ========================= LISTAS DE PRECIOS ===========================

  @override
  Future<List<ClasificacionPrecioEntity>> obtenerClasificacionesPrecio({
    BigInt? idClasificacion,
    BigInt? codSucursal,
  }) async {
    final modelos = await postAndReturnList<ClasificacionPrecioModel>(
      endpoint: AppConstants.preciosClasificacionListar,
      // El backend solo mira estos dos campos del cuerpo.
      data: _filtro({
        'idClasificacion': idClasificacion?.toInt(),
        'codSucursal': codSucursal?.toInt(),
      }),
      fromJson: ClasificacionPrecioModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> obtenerClasificacionesConSucursal() =>
      postAndReturnList<Map<String, dynamic>>(
        endpoint: AppConstants.preciosClasificacionConSucursal,
        fromJson: _crudo,
      );

  @override
  Future<List<int>> obtenerVppsUsados() async {
    // El envelope trae data: [1, 2, 3], una lista de enteros crudos.
    final crudo = await _datoCrudo(
      AppConstants.preciosClasificacionVpps,
      const <String, dynamic>{},
    );
    // Null es el 204: todavia no hay ningun vpp cargado, y eso no es un error.
    if (crudo is! List) return const <int>[];
    return [
      for (final e in crudo)
        if (e is num) e.toInt(),
    ];
  }

  @override
  Future<bool> existeVpp({required int vpp, BigInt? idClasificacion}) async {
    final crudo = await _datoCrudo(
      AppConstants.preciosClasificacionExisteVpp,
      // idClasificacion se manda al editar para que la lista no choque
      // consigo misma; en un alta va nulo.
      _filtro({'vpp': vpp, 'idClasificacion': idClasificacion?.toInt()}),
    );
    // data viene como un booleano crudo, no como un objeto.
    return crudo == true;
  }

  /// El contenido de `data` tal como llega, para las lecturas cuyo `data` NO
  /// es un objeto: una lista de enteros, un booleano.
  ///
  /// **Por que no `postAndReturnObject`.** Su `fromJson` es una funcion que
  /// recibe un `Map<String, dynamic>`, y el valor se convierte a ese tipo
  /// ANTES de llegar a la funcion, aunque la funcion se escriba con un
  /// parametro `dynamic`. Con `data: [1, 2, 3]` eso revienta con un
  /// TypeError -en web, "JSArray is not a subtype of Map"- y el dialogo de
  /// la lista de precios mostraba la pantalla roja al abrirse.
  Future<Object?> _datoCrudo(
    String endpoint,
    Map<String, dynamic> cuerpo,
  ) async {
    try {
      final respuesta = await dio.post(endpoint, data: cuerpo);
      final status = respuesta.statusCode ?? 0;
      if (status == 204 || respuesta.data == null) return null;
      final cuerpoRespuesta = respuesta.data;
      return cuerpoRespuesta is Map ? cuerpoRespuesta['data'] : cuerpoRespuesta;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        throw Exception(
          e.response!.data['message'] ?? 'Error al obtener los datos',
        );
      }
      throw Exception(
        DioClient.handleDioError(e, 'Error al obtener los datos'),
      );
    }
  }

  @override
  Future<BigInt> registrarClasificacionPrecio(
    ClasificacionPrecioEntity clasificacion,
  ) => postAndReturnId(
    endpoint: AppConstants.preciosClasificacionRegistrar,
    data: _sinAudUsuario(
      ClasificacionPrecioModel.fromEntity(clasificacion).toJson(),
    ),
  );

  @override
  Future<BigInt> cambiarEstadoClasificacionPrecio({
    required BigInt idClasificacion,
    required int estado,
  }) => postAndReturnId(
    endpoint: AppConstants.preciosClasificacionCambiarEstado,
    // Solo los dos campos que la operacion escribe: mandar el resto abriria
    // la puerta a pisar el nombre o el vpp sin querer.
    data: {'idClasificacion': idClasificacion.toInt(), 'estado': estado},
  );

  @override
  Future<BigInt> eliminarClasificacionPrecio(BigInt idClasificacion) =>
      postAndReturnId(
        endpoint: AppConstants.preciosClasificacionEliminar,
        data: {'id': idClasificacion.toInt()},
      );

  // ============================== IVA / IT ===============================

  @override
  Future<List<CostoIvaItEntity>> obtenerCostosIvaIt() async {
    final modelos = await postAndReturnList<CostoIvaItModel>(
      endpoint: AppConstants.preciosCostoIvaItListar,
      fromJson: CostoIvaItModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<CostoIvaItEntity?> obtenerCostoIvaItVigente() async {
    final modelo = await postAndReturnObject<CostoIvaItModel>(
      endpoint: AppConstants.preciosCostoIvaItVigente,
      data: const {},
      // El backend manda ademas totalIvaIt ya sumado; el model no lo guarda
      // porque no es una columna y la entity lo deriva de iva + it.
      fromJson: CostoIvaItModel.fromJson,
    );
    return modelo?.toEntity();
  }

  @override
  Future<List<CostoIvaItEntity>> obtenerCostosIvaItPorPropuesta(
    BigInt idPropuesta,
  ) async {
    final modelos = await postAndReturnList<CostoIvaItModel>(
      endpoint: AppConstants.preciosCostoIvaItPorPropuesta,
      data: {'id': idPropuesta.toInt()},
      fromJson: CostoIvaItModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<BigInt> registrarCostoIvaIt(CostoIvaItEntity costo) => postAndReturnId(
    endpoint: AppConstants.preciosCostoIvaItRegistrar,
    data: _sinAudUsuario(CostoIvaItModel.fromEntity(costo).toJson()),
  );

  // ==================== ANCLA DEL TIPO DE CAMBIO =========================

  @override
  Future<List<TcAnclaEntity>> obtenerAnclasTipoCambio() async {
    final modelos = await postAndReturnList<TcAnclaModel>(
      endpoint: AppConstants.preciosTcAnclaListar,
      fromJson: TcAnclaModel.fromJson,
    );
    return modelos.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TcAnclaEntity?> obtenerAnclaTipoCambio(String companyDB) async {
    final modelo = await postAndReturnObject<TcAnclaModel>(
      endpoint: AppConstants.preciosTcAnclaObtener,
      // La PK es el nombre de la base de datos de la empresa en SAP, texto y
      // no un id numerico.
      data: {'companyDB': companyDB},
      fromJson: TcAnclaModel.fromJson,
    );
    return modelo?.toEntity();
  }

  // ============================== APOYO ==================================

  /// Deja la respuesta tal como llega, para las lecturas que el backend arma
  /// con DTO de despliegue: no hay tabla detras, asi que no hay model ni
  /// entity que las represente.
  static Map<String, dynamic> _crudo(Map<String, dynamic> json) => json;

  /// Quita del cuerpo el usuario de auditoria.
  ///
  /// El backend lo toma del token JWT en todas las escrituras del modulo:
  /// mandarlo desde el cliente no cambia nada y es justamente el habito que
  /// permitia colgar un costo o un precio de la propuesta de otra persona.
  static Map<String, dynamic> _sinAudUsuario(Map<String, dynamic> json) =>
      Map<String, dynamic>.from(json)..remove('audUsuario');

  /// Arma un cuerpo de filtro sin las claves nulas.
  ///
  /// Una clave ausente llega como NULL al procedimiento y no filtra; un 0 o
  /// una cadena vacia SI filtran. Por eso los filtros no se arman con el
  /// toJson del model, que rellena los vacios con 0 y ''.
  static Map<String, dynamic> _filtro(Map<String, dynamic> campos) {
    final cuerpo = <String, dynamic>{};
    campos.forEach((clave, valor) {
      if (valor != null) cuerpo[clave] = valor;
    });
    return cuerpo;
  }
}
