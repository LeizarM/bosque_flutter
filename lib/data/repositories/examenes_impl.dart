import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/network/dio_client.dart';
import 'package:bosque_flutter/data/models/tcpe_banco_opcion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_banco_pregunta_model.dart';
import 'package:bosque_flutter/data/models/tcpe_catalogo_codec.dart';
import 'package:bosque_flutter/data/models/tcpe_credencial_model.dart';
import 'package:bosque_flutter/data/models/tcpe_disponibles_model.dart';
import 'package:bosque_flutter/data/models/tcpe_duplicado_pregunta_model.dart';
import 'package:bosque_flutter/data/models/tcpe_empleado_elegible_model.dart';
import 'package:bosque_flutter/data/models/tcpe_espejo_item_model.dart';
import 'package:bosque_flutter/data/models/tcpe_fila_importacion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_historial_examen_model.dart';
import 'package:bosque_flutter/data/models/tcpe_informe_categoria_model.dart';
import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/data/models/tcpe_lote_generado_model.dart';
import 'package:bosque_flutter/data/models/tcpe_lote_model.dart';
import 'package:bosque_flutter/data/models/tcpe_monitor_examen_model.dart';
import 'package:bosque_flutter/data/models/tcpe_monitor_lote_model.dart';
import 'package:bosque_flutter/data/models/tcpe_pedido_examenes_model.dart';
import 'package:bosque_flutter/data/models/tcpe_pregunta_importar_model.dart';
import 'package:bosque_flutter/data/models/tcpe_resultado_examen_model.dart';
import 'package:bosque_flutter/data/models/tcpe_resultado_importacion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_revision_item_model.dart';
import 'package:bosque_flutter/data/models/tcpe_solucionario_item_model.dart';
import 'package:bosque_flutter/data/repositories/rendicion_endpoints.dart';
import 'package:bosque_flutter/data/repositories/tcpe_api_base.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_opcion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_catalogo.dart';
import 'package:bosque_flutter/domain/entities/tcpe_credencial_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_duplicado_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_empleado_elegible_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_espejo_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fila_importacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_historial_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_informe_categoria_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_lote_generado_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_monitor_lote_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pedido_examenes_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_importar_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_examen_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_resultado_importacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_revision_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_solucionario_item_entity.dart';
import 'package:bosque_flutter/domain/repositories/examenes_repository.dart';

class ExamenesImpl extends TcpeApiBase
    with RendicionPorEndpoints
    implements ExamenesRepository {
  @override
  RendicionEndpoints get endpointsRendicion => RendicionEndpoints.empleado;

  // ── CRUD genérico ─────────────────────────────────────────────────────
  String _ruta(String plantilla, TcpeCatalogo<Object?> c) =>
      plantilla.replaceFirst(AppConstants.tcpeEntidad, c.entidad);

  @override
  Future<List<E>> listarCatalogo<E>(
    TcpeCatalogo<E> catalogo, {
    Map<String, Object?> filtros = const {},
  }) {
    final codec = codecTcpe(catalogo);
    return postAndReturnList<E>(
      endpoint: _ruta(AppConstants.tcpeCatalogoListar, catalogo),
      data: TcpeApiBase.cuerpo(filtros),
      fromJson: codec.desdeJson,
    );
  }

  @override
  Future<BigInt> guardarCatalogo<E>(TcpeCatalogo<E> catalogo, E registro) {
    // Lo de solo lectura no viaja: audFecha la pone la base, nombreUsuario el
    // listado y audUsuario el backend desde el token.
    final cuerpo = codecTcpe(catalogo).aJson(registro)
      ..remove('audFecha')
      ..remove('nombreUsuario');
    return postAndReturnId(
      endpoint: _ruta(AppConstants.tcpeCatalogoGuardar, catalogo),
      data: cuerpo,
      errorMessage: 'No se pudo guardar el registro.',
    );
  }

  @override
  Future<BigInt> eliminarCatalogo<E>(TcpeCatalogo<E> catalogo, BigInt id) =>
      postAndReturnId(
        endpoint: _ruta(AppConstants.tcpeCatalogoEliminar, catalogo),
        data: {catalogo.pk: id.toInt()},
        errorMessage: 'No se pudo eliminar el registro.',
      );

  // ── Banco de preguntas ────────────────────────────────────────────────
  @override
  Future<List<TcpeBancoPreguntaEntity>> listarPreguntas({
    BigInt? codPregunta,
    BigInt? codClasificacion,
    BigInt? codArea,
    bool? activo,
    String? texto,
  }) => postAndReturnList(
    endpoint: AppConstants.tcpeBancoListar,
    data: TcpeApiBase.cuerpo({
      'codPregunta': codPregunta,
      'codClasificacion': codClasificacion,
      'codArea': codArea,
      'activo': activo,
      'texto': (texto ?? '').trim().isEmpty ? null : texto!.trim(),
    }),
    fromJson: (j) => TcpeBancoPreguntaModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<TcpeBancoOpcionEntity>> listarOpciones({
    BigInt? codPregunta,
    BigInt? codClasificacion,
  }) => postAndReturnList(
    endpoint: AppConstants.tcpeBancoOpciones,
    data: TcpeApiBase.cuerpo({
      'codPregunta': codPregunta,
      'codClasificacion': codClasificacion,
    }),
    fromJson: (j) => TcpeBancoOpcionModel.fromJson(j).toEntity(),
  );

  @override
  Future<BigInt> guardarPregunta(
    TcpeBancoPreguntaEntity pregunta,
    List<TcpeBancoOpcionEntity> opciones,
  ) {
    final cuerpo = TcpeBancoPreguntaModel.fromEntity(pregunta).toGuardarJson();
    if (pregunta.codPregunta == BigInt.zero) cuerpo.remove('codPregunta');
    cuerpo['opciones'] = [
      if (pregunta.esCerrada)
        for (final o in opciones) TcpeBancoOpcionModel.fromEntity(o).toGuardarJson(),
    ];
    return postAndReturnId(
      endpoint: AppConstants.tcpeBancoGuardar,
      data: cuerpo,
      errorMessage: 'No se pudo guardar la pregunta.',
    );
  }

  @override
  Future<void> eliminarPregunta(BigInt codPregunta) => postAndReturnId(
    endpoint: AppConstants.tcpeBancoEliminar,
    data: {'codPregunta': codPregunta.toInt()},
    errorMessage: 'No se pudo eliminar la pregunta.',
  );

  @override
  Future<void> activarPregunta(BigInt codPregunta, bool activo) =>
      postAndReturnId(
        endpoint: AppConstants.tcpeBancoActivar,
        data: {'codPregunta': codPregunta.toInt(), 'activo': activo},
        errorMessage: 'No se pudo cambiar el estado de la pregunta.',
      );

  @override
  Future<List<TcpeDuplicadoPreguntaEntity>> buscarDuplicados(
    BigInt codClasificacion,
    String texto,
  ) => postAndReturnList(
    endpoint: AppConstants.tcpeBancoDuplicados,
    data: {'codClasificacion': codClasificacion.toInt(), 'texto': texto.trim()},
    fromJson: (j) => TcpeDuplicadoPreguntaModel.fromJson(j).toEntity(),
  );

  static Map<String, dynamic> _cuerpoImportacion(
    BigInt codClasificacion,
    List<TcpePreguntaImportarEntity> preguntas,
  ) => {
    'codClasificacion': codClasificacion.toInt(),
    'preguntas': [for (final p in preguntas) TcpePreguntaImportarModel.fromEntity(p).toJson()],
  };

  @override
  Future<List<TcpeFilaImportacionEntity>> validarImportacion(
    BigInt codClasificacion,
    List<TcpePreguntaImportarEntity> preguntas,
  ) => postAndReturnList(
    endpoint: AppConstants.tcpeBancoImportarValidar,
    data: _cuerpoImportacion(codClasificacion, preguntas),
    fromJson: (j) => TcpeFilaImportacionModel.fromJson(j).toEntity(),
  );

  /// Necesita el sobre entero: `message` (resumen del SP) y `data` (insertadas).
  @override
  Future<TcpeResultadoImportacionEntity> importarPreguntas(
    BigInt codClasificacion,
    List<TcpePreguntaImportarEntity> preguntas,
  ) async {
    try {
      final r = await dio.post<Object?>(
        AppConstants.tcpeBancoImportar,
        data: _cuerpoImportacion(codClasificacion, preguntas),
      );
      final cuerpo = r.data;
      if (r.statusCode == 204 || cuerpo is! Map) return const TcpeResultadoImportacionEntity();
      return TcpeResultadoImportacionModel.fromJson(Map<String, dynamic>.from(cuerpo)).toEntity();
    } on DioException catch (e) {
      final cuerpo = e.response?.data;
      if (e.response?.statusCode == 400 && cuerpo is Map && cuerpo['message'] != null) {
        throw Exception(cuerpo['message']);
      }
      throw Exception(DioClient.handleDioError(e, 'No se pudieron importar las preguntas.'));
    }
  }

  // ── Lotes ─────────────────────────────────────────────────────────────
  @override
  Future<List<TcpeLoteEntity>> listarLotes({
    BigInt? codRolExamen,
    BigInt? codArea,
    BigInt? codClasificacion,
    String? modalidad,
  }) => postAndReturnList(
    endpoint: AppConstants.tcpeLotesListar,
    data: TcpeApiBase.cuerpo({
      'codRolExamen': codRolExamen,
      'codArea': codArea,
      'codClasificacion': codClasificacion,
      'modalidad': modalidad,
    }),
    fromJson: (j) => TcpeLoteModel.fromJson(j).toEntity(),
  );

  @override
  Future<int> preguntasDisponibles(BigInt codClasificacion) async {
    final filas = await postAndReturnList(
      endpoint: AppConstants.tcpeLotesDisponibles,
      data: {'codClasificacion': codClasificacion.toInt()},
      fromJson: (j) => TcpeDisponiblesModel.fromJson(j).toEntity(),
    );
    return filas.isEmpty ? 0 : filas.first.disponibles;
  }

  @override
  Future<List<TcpeEmpleadoElegibleEntity>> empleadosElegibles({BigInt? codRolExamen}) => postAndReturnList(
    endpoint: AppConstants.tcpeLotesEmpleados,
    data: TcpeApiBase.cuerpo({'codRolExamen': codRolExamen}),
    fromJson: (j) => TcpeEmpleadoElegibleModel.fromJson(j).toEntity(),
  );

  Future<TcpeLoteGeneradoEntity> _generado(
    String endpoint,
    Map<String, dynamic> cuerpo,
  ) async {
    final r = await postAndReturnObject(
      endpoint: endpoint,
      data: cuerpo,
      fromJson: (j) => TcpeLoteGeneradoModel.fromJson(j).toEntity(),
      errorMessage: 'No se pudieron generar los exámenes.',
    );
    if (r == null) throw Exception('El servidor no devolvió las credenciales.');
    return r;
  }

  @override
  Future<TcpeLoteGeneradoEntity> generarLote(
    TcpeLoteEntity lote,
    TcpePedidoExamenesEntity pedido,
  ) {
    // Lote mixto: externos y empleados en el mismo body; el model manda solo los modos con valor.
    final cuerpo = TcpeLoteModel.fromEntity(lote).toGuardarJson()
      ..remove('codRolExamen')
      ..addAll(TcpePedidoExamenesModel.fromEntity(pedido).toJson());
    return _generado(AppConstants.tcpeLotesGenerar, cuerpo);
  }

  @override
  Future<TcpeLoteGeneradoEntity> agregarExamenes(
    BigInt codRolExamen,
    TcpePedidoExamenesEntity pedido,
  ) {
    final cuerpo = <String, dynamic>{
      'codRolExamen': codRolExamen.toInt(),
      ...TcpePedidoExamenesModel.fromEntity(pedido).toJson(),
    };
    return _generado(AppConstants.tcpeLotesAgregar, cuerpo);
  }

  @override
  Future<void> actualizarLote(TcpeLoteEntity lote) => postAndReturnId(
    endpoint: AppConstants.tcpeLotesActualizar,
    data: TcpeLoteModel.fromEntity(lote).toGuardarJson(),
    errorMessage: 'No se pudo actualizar el lote.',
  );

  @override
  Future<void> eliminarLote(BigInt codRolExamen) => postAndReturnId(
    endpoint: AppConstants.tcpeLotesEliminar,
    data: {'codRolExamen': codRolExamen.toInt()},
    errorMessage: 'No se pudo eliminar el lote.',
  );

  /// Bytes con el token de empleado (Dio de [DioClient]). Un 204 es éxito sin
  /// PDF (nada que imprimir) y vuelve null; el error JSON llega como bytes.
  @override
  Future<Uint8List?> pdfEscrito({
    required BigInt codRolExamen,
    BigInt? codExamen,
    bool solucionario = false,
  }) async {
    try {
      final r = await dio.post<List<int>>(
        solucionario ? AppConstants.tcpeLotesSolucionarioPdf : AppConstants.tcpeLotesExamenEscritoPdf,
        data: TcpeApiBase.cuerpo({'codRolExamen': codRolExamen, 'codExamen': codExamen}),
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.bytes,
          // Un lote grande son muchas páginas: más que los 30 s de siempre.
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      final bytes = r.data;
      if (r.statusCode == 204 || bytes == null || bytes.isEmpty) return null;
      return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    } on DioException catch (e) {
      throw Exception(DioClient.mensajeDeReporteFallido(e));
    }
  }

  // ── Resultados y calificación ─────────────────────────────────────────
  @override
  Future<List<TcpeResultadoExamenEntity>> listarResultados(
    BigInt codRolExamen,
  ) => postAndReturnList(
    endpoint: AppConstants.tcpeResultadosListar,
    data: {'codRolExamen': codRolExamen.toInt()},
    fromJson: (j) => TcpeResultadoExamenModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<TcpeRevisionItemEntity>> revision(BigInt codExamen) =>
      postAndReturnList(
        endpoint: AppConstants.tcpeResultadosRevision,
        data: {'codExamen': codExamen.toInt()},
        fromJson: (j) => TcpeRevisionItemModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<TcpeSolucionarioItemEntity>> solucionario({
    BigInt? codExamen,
    BigInt? codRolExamen,
  }) => postAndReturnList(
    endpoint: AppConstants.tcpeResultadosSolucionario,
    data: TcpeApiBase.cuerpo({
      'codExamen': codExamen,
      'codRolExamen': codRolExamen,
    }),
    fromJson: (j) => TcpeSolucionarioItemModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<TcpeHistorialExamenEntity>> historial(String ci) =>
      postAndReturnList(
        endpoint: AppConstants.tcpeResultadosHistorial,
        data: {'ci': ci.trim()},
        fromJson: (j) => TcpeHistorialExamenModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<TcpeInformeCategoriaEntity>> informe({
    BigInt? codClasificacion,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) => postAndReturnList(
    endpoint: AppConstants.tcpeResultadosInforme,
    data: TcpeApiBase.cuerpo({
      'codClasificacion': codClasificacion,
      'fechaDesde': tcpeFechaJson(fechaDesde),
      'fechaHasta': tcpeFechaJson(fechaHasta),
    }),
    fromJson: (j) => TcpeInformeCategoriaModel.fromJson(j).toEntity(),
  );

  @override
  Future<String?> marcarRespuesta({
    required BigInt codExamen,
    required BigInt codRespuestaH,
    required bool esCorrecta,
  }) => postMensaje(
    AppConstants.tcpeCalificacionMarcar,
    {
      'codExamen': codExamen.toInt(),
      'codRespuestaH': codRespuestaH.toInt(),
      'esCorrecta': esCorrecta,
    },
    errorMessage: 'No se pudo marcar la respuesta.',
  );

  @override
  Future<String?> cerrarCalificacion(BigInt codExamen) => postMensaje(
    AppConstants.tcpeCalificacionCerrar,
    {'codExamen': codExamen.toInt()},
    errorMessage: 'No se pudo cerrar la calificación.',
  );

  @override
  Future<String?> notaManual(BigInt codExamen, double resultado) => postMensaje(
    AppConstants.tcpeCalificacionNota,
    {'codExamen': codExamen.toInt(), 'resultado': resultado},
    errorMessage: 'No se pudo guardar la nota.',
  );

  // ── En vivo ───────────────────────────────────────────────────────────
  @override
  Future<List<TcpeMonitorLoteEntity>> monitorLotes() => postAndReturnList(
    endpoint: AppConstants.tcpeMonitorLotes,
    data: const {},
    fromJson: (j) => TcpeMonitorLoteModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<TcpeMonitorExamenEntity>> monitorExamenes(BigInt codRolExamen) => postAndReturnList(
    endpoint: AppConstants.tcpeMonitorListar,
    data: {'codRolExamen': codRolExamen.toInt()},
    fromJson: (j) => TcpeMonitorExamenModel.fromJson(j).toEntity(),
  );

  @override
  Future<List<TcpeEspejoItemEntity>> espejo(BigInt codExamen) => postAndReturnList(
    endpoint: AppConstants.tcpeMonitorEspejo,
    data: {'codExamen': codExamen.toInt()},
    fromJson: (j) => TcpeEspejoItemModel.fromJson(j).toEntity(),
  );

  // ── Usuarios externos ─────────────────────────────────────────────────
  @override
  Future<TcpeCredencialEntity> regenerarClave(BigInt codUsuario) async {
    final r = await postAndReturnObject(
      endpoint: AppConstants.tcpeUsuariosRegenerarClave,
      data: {'codUsuario': codUsuario.toInt()},
      fromJson: (j) => TcpeCredencialModel.fromJson(j).toEntity(),
      errorMessage: 'No se pudo regenerar la clave.',
    );
    if (r == null) throw Exception('El servidor no devolvió la clave nueva.');
    return r.copyWith(codUsuario: codUsuario);
  }

  @override
  Future<int> migrarClaves() async {
    final dato = await postDato(
      AppConstants.tcpeUsuariosMigrarClaves,
      const {},
      errorMessage: 'No se pudieron migrar las claves.',
    );
    final fila = TcpeApiBase.primeraFila(dato);
    return tcpeInt(fila?['migrados'] ?? dato) ?? 0;
  }
}
