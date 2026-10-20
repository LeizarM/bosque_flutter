import 'package:bosque_flutter/data/models/tcpe_banco_opcion_model.dart';
import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_importar_entity.dart';

/// Un elemento de `preguntas` en `/examenes/banco/importar[/validar]`. El
/// backend arma el XML y numera las filas desde 1 en este mismo orden.
class TcpePreguntaImportarModel {
  final String pregunta;
  final bool esCerrada;
  final String? respuesta;
  final int? prioridad;
  final List<TcpeBancoOpcionModel> opciones;

  const TcpePreguntaImportarModel({
    required this.pregunta,
    required this.esCerrada,
    this.respuesta,
    this.prioridad,
    this.opciones = const [],
  });

  factory TcpePreguntaImportarModel.fromJson(Map<String, dynamic> json) => TcpePreguntaImportarModel(
    pregunta: tcpeTexto(json['pregunta']) ?? '',
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    respuesta: tcpeTexto(json['respuesta']),
    prioridad: tcpeInt(json['prioridad']),
    opciones: [
      for (final o in (json['opciones'] as List? ?? const []))
        if (o is Map) TcpeBancoOpcionModel.fromJson(Map<String, dynamic>.from(o)),
    ],
  );

  /// Solo las claves del contrato: las opciones viajan con texto y si valen.
  Map<String, dynamic> toJson() => {
    'pregunta': pregunta,
    'esCerrada': esCerrada,
    'respuesta': respuesta,
    'prioridad': prioridad,
    'opciones': [
      for (final o in opciones) {'opcionRspta': o.opcionRspta, 'esValido': o.esValido},
    ],
  };

  TcpePreguntaImportarEntity toEntity() => TcpePreguntaImportarEntity(
    pregunta: pregunta,
    esCerrada: esCerrada,
    respuesta: respuesta,
    prioridad: prioridad,
    opciones: [for (final o in opciones) o.toEntity()],
  );

  factory TcpePreguntaImportarModel.fromEntity(TcpePreguntaImportarEntity e) => TcpePreguntaImportarModel(
    pregunta: e.pregunta,
    esCerrada: e.esCerrada,
    respuesta: e.respuesta,
    prioridad: e.prioridad,
    opciones: [for (final o in e.opciones) TcpeBancoOpcionModel.fromEntity(o)],
  );
}
