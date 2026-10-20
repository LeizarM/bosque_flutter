import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/models/tcpe_config_model.dart';
import 'package:bosque_flutter/data/models/tcpe_devolucion_item_model.dart';
import 'package:bosque_flutter/data/models/tcpe_estado_rendicion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_opcion_rendicion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_pregunta_rendicion_model.dart';
import 'package:bosque_flutter/data/repositories/tcpe_api_base.dart';
import 'package:bosque_flutter/domain/entities/tcpe_config_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_devolucion_item_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estado_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_opcion_rendicion_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_rendicion_entity.dart';
import 'package:bosque_flutter/domain/repositories/rendicion_examen_repository.dart';

/// Los endpoints de rendición de cada origen: el mismo SP detrás, distinto
/// token y distinto prefijo.
class RendicionEndpoints {
  final String listar;
  final String estado;
  final String preguntas;
  final String opciones;
  final String iniciar;
  final String responder;
  final String finalizar;
  final String revision;
  final String config;
  final String latido;

  const RendicionEndpoints._({
    required this.listar,
    required this.estado,
    required this.preguntas,
    required this.opciones,
    required this.iniciar,
    required this.responder,
    required this.finalizar,
    required this.revision,
    required this.config,
    required this.latido,
  });

  static const empleado = RendicionEndpoints._(
    listar: AppConstants.tcpeMisExamenesListar,
    estado: AppConstants.tcpeMisExamenesEstado,
    preguntas: AppConstants.tcpeMisExamenesPreguntas,
    opciones: AppConstants.tcpeMisExamenesOpciones,
    iniciar: AppConstants.tcpeMisExamenesIniciar,
    responder: AppConstants.tcpeMisExamenesResponder,
    finalizar: AppConstants.tcpeMisExamenesFinalizar,
    revision: AppConstants.tcpeMisExamenesRevision,
    config: AppConstants.tcpeConfig,
    latido: AppConstants.tcpeMisExamenesLatido,
  );

  static const postulante = RendicionEndpoints._(
    listar: AppConstants.tcpePublicoListar,
    estado: AppConstants.tcpePublicoEstado,
    preguntas: AppConstants.tcpePublicoPreguntas,
    opciones: AppConstants.tcpePublicoOpciones,
    iniciar: AppConstants.tcpePublicoIniciar,
    responder: AppConstants.tcpePublicoResponder,
    finalizar: AppConstants.tcpePublicoFinalizar,
    revision: AppConstants.tcpePublicoRevision,
    config: AppConstants.tcpePublicoConfig,
    latido: AppConstants.tcpePublicoLatido,
  );
}

/// Rendición compartida: empleado y postulante solo cambian de endpoints.
mixin RendicionPorEndpoints on TcpeApiBase implements RendicionExamenRepository {
  RendicionEndpoints get endpointsRendicion;

  @override
  Future<List<TcpeEstadoRendicionEntity>> listarExamenes() => postAndReturnList(
    endpoint: endpointsRendicion.listar,
    data: const {},
    fromJson: (j) => TcpeEstadoRendicionModel.fromJson(j).toEntity(),
  );

  @override
  Future<TcpeEstadoRendicionEntity?> estadoExamen(BigInt codExamen) async {
    final dato = await postDato(endpointsRendicion.estado, {
      'codExamen': codExamen.toInt(),
    }, errorMessage: 'No se pudo consultar el examen.');
    final fila = TcpeApiBase.primeraFila(dato);
    return fila == null ? null : TcpeEstadoRendicionModel.fromJson(fila).toEntity();
  }

  @override
  Future<List<TcpePreguntaRendicionEntity>> preguntasExamen(BigInt codExamen) =>
      postAndReturnList(
        endpoint: endpointsRendicion.preguntas,
        data: {'codExamen': codExamen.toInt()},
        fromJson: (j) => TcpePreguntaRendicionModel.fromJson(j).toEntity(),
      );

  @override
  Future<List<TcpeOpcionRendicionEntity>> opcionesExamen(BigInt codExamen) =>
      postAndReturnList(
        endpoint: endpointsRendicion.opciones,
        data: {'codExamen': codExamen.toInt()},
        fromJson: (j) => TcpeOpcionRendicionModel.fromJson(j).toEntity(),
      );

  @override
  Future<int?> iniciarExamen(BigInt codExamen) async => segundosDe(
    await postDato(endpointsRendicion.iniciar, {
      'codExamen': codExamen.toInt(),
    }, errorMessage: 'No se pudo iniciar el examen.'),
  );

  @override
  Future<int?> responderPregunta({
    required BigInt codExamen,
    required BigInt codPreguntaH,
    List<BigInt>? opciones,
    String? respuestaU,
  }) async {
    final dato = await postDato(
      endpointsRendicion.responder,
      cuerpoResponder(
        codExamen: codExamen,
        codPreguntaH: codPreguntaH,
        opciones: opciones,
        respuestaU: respuestaU,
      ),
      errorMessage: 'No se pudo guardar la respuesta.',
    );
    return segundosDe(dato);
  }

  /// El body de `responder` (`TcpeRendirAccionDto`): `opciones` va como lista
  /// de números (el backend arma la lista para el SP). Vacía = sin responder;
  /// null = no es una cerrada y la clave no se manda.
  static Map<String, dynamic> cuerpoResponder({
    required BigInt codExamen,
    required BigInt codPreguntaH,
    List<BigInt>? opciones,
    String? respuestaU,
  }) => {
    'codExamen': codExamen.toInt(),
    'codPreguntaH': codPreguntaH.toInt(),
    if (opciones != null) 'opciones': [for (final o in opciones) o.toInt()],
    if (respuestaU != null) 'respuestaU': respuestaU,
  };

  /// `I` y `R` devuelven en `data` el idGenerado, que en ellos son los segundos
  /// restantes. Se acepta también un objeto con `segundosRestantes`.
  static int? segundosDe(Object? dato) {
    if (dato is num) return dato.toInt();
    final fila = TcpeApiBase.primeraFila(dato);
    final s = fila?['segundosRestantes'] ?? fila?['idGenerado'];
    return s is num ? s.toInt() : int.tryParse('${s ?? ''}');
  }

  @override
  Future<void> finalizarExamen(BigInt codExamen) => postAndReturnId(
    endpoint: endpointsRendicion.finalizar,
    data: {'codExamen': codExamen.toInt()},
    errorMessage: 'No se pudo entregar el examen.',
  );

  @override
  Future<List<TcpeDevolucionItemEntity>> devolucionExamen(BigInt codExamen) =>
      postAndReturnList(
        endpoint: endpointsRendicion.revision,
        data: {'codExamen': codExamen.toInt()},
        fromJson: (j) => TcpeDevolucionItemModel.fromJson(j).toEntity(),
      );

  @override
  Future<int?> latido({required BigInt codExamen, BigInt? codPreguntaH, bool salioPestana = false}) async =>
      segundosDe(
        await postDato(endpointsRendicion.latido, {
          'codExamen': codExamen.toInt(),
          if (codPreguntaH != null) 'codPreguntaH': codPreguntaH.toInt(),
          'salioPestana': salioPestana,
        }, errorMessage: 'No se pudo avisar que sigues en el examen.'),
      );

  @override
  Future<List<TcpeConfigEntity>> configuracion() => postAndReturnList(
    endpoint: endpointsRendicion.config,
    data: const {},
    fromJson: (j) => TcpeConfigModel.fromJson(j).toEntity(),
  );
}
