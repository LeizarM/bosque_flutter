import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_revision_item_entity.dart';

/// Una pregunta de un examen entregado, para revisarla (`p_list_tcpe_Resultado` R).
class TcpeRevisionItemModel {
  final BigInt codPreguntaH;
  final BigInt? codRespuestaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;
  final String? respuestaModelo;
  final String? respuestaU;
  final bool? esCorrecta;
  final String? marcadas;
  final String? correctas;

  const TcpeRevisionItemModel({
    required this.codPreguntaH,
    this.codRespuestaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.respuestaModelo,
    this.respuestaU,
    this.esCorrecta,
    this.marcadas,
    this.correctas,
  });

  factory TcpeRevisionItemModel.fromJson(Map<String, dynamic> json) => TcpeRevisionItemModel(
    codPreguntaH: tcpeBigInt(json['codPreguntaH']) ?? BigInt.zero,
    codRespuestaH: tcpeBigInt(json['codRespuestaH']),
    orden: tcpeInt(json['orden']) ?? 0,
    pregunta: tcpeTexto(json['pregunta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    respuestaModelo: tcpeTexto(json['respuestaModelo']),
    respuestaU: tcpeTexto(json['respuestaU']),
    esCorrecta: tcpeBool(json['esCorrecta']),
    marcadas: tcpeTexto(json['marcadas']),
    correctas: tcpeTexto(json['correctas']),
  );

  Map<String, dynamic> toJson() => {
    'codPreguntaH': codPreguntaH.toInt(),
    'codRespuestaH': codRespuestaH?.toInt(),
    'orden': orden,
    'pregunta': pregunta,
    'esCerrada': esCerrada,
    'respuestaModelo': respuestaModelo,
    'respuestaU': respuestaU,
    'esCorrecta': esCorrecta,
    'marcadas': marcadas,
    'correctas': correctas,
  };

  TcpeRevisionItemEntity toEntity() => TcpeRevisionItemEntity(
    codPreguntaH: codPreguntaH,
    codRespuestaH: codRespuestaH,
    orden: orden,
    pregunta: pregunta,
    esCerrada: esCerrada,
    respuestaModelo: respuestaModelo,
    respuestaU: respuestaU,
    esCorrecta: esCorrecta,
    marcadas: marcadas,
    correctas: correctas,
  );

  factory TcpeRevisionItemModel.fromEntity(TcpeRevisionItemEntity e) => TcpeRevisionItemModel(
    codPreguntaH: e.codPreguntaH,
    codRespuestaH: e.codRespuestaH,
    orden: e.orden,
    pregunta: e.pregunta,
    esCerrada: e.esCerrada,
    respuestaModelo: e.respuestaModelo,
    respuestaU: e.respuestaU,
    esCorrecta: e.esCorrecta,
    marcadas: e.marcadas,
    correctas: e.correctas,
  );
}
