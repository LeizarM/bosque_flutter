import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_devolucion_item_entity.dart';

/// Una fila de la devolución de un examen entregado (`p_list_tcpe_Rendir` F).
class TcpeDevolucionItemModel {
  final BigInt codPreguntaH;
  final int orden;
  final String? pregunta;
  final bool esCerrada;
  final bool? esCorrecta;
  final String? respuestaU;
  final BigInt? codRsptaOpH;
  final String? opcionRspta;
  final bool marcada;
  final bool? esValido;

  const TcpeDevolucionItemModel({
    required this.codPreguntaH,
    this.orden = 0,
    this.pregunta,
    this.esCerrada = false,
    this.esCorrecta,
    this.respuestaU,
    this.codRsptaOpH,
    this.opcionRspta,
    this.marcada = false,
    this.esValido,
  });

  factory TcpeDevolucionItemModel.fromJson(Map<String, dynamic> json) => TcpeDevolucionItemModel(
    codPreguntaH: tcpeBigInt(json['codPreguntaH']) ?? BigInt.zero,
    orden: tcpeInt(json['orden']) ?? 0,
    pregunta: tcpeTexto(json['pregunta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    esCorrecta: tcpeBool(json['esCorrecta']),
    respuestaU: tcpeTexto(json['respuestaU']),
    codRsptaOpH: tcpeBigInt(json['codRsptaOpH']),
    opcionRspta: tcpeTexto(json['opcionRspta']),
    marcada: tcpeBool(json['marcada']) ?? false,
    esValido: tcpeBool(json['esValido']),
  );

  Map<String, dynamic> toJson() => {
    'codPreguntaH': codPreguntaH.toInt(),
    'orden': orden,
    'pregunta': pregunta,
    'esCerrada': esCerrada,
    'esCorrecta': esCorrecta,
    'respuestaU': respuestaU,
    'codRsptaOpH': codRsptaOpH?.toInt(),
    'opcionRspta': opcionRspta,
    'marcada': marcada,
    'esValido': esValido,
  };

  TcpeDevolucionItemEntity toEntity() => TcpeDevolucionItemEntity(
    codPreguntaH: codPreguntaH,
    orden: orden,
    pregunta: pregunta,
    esCerrada: esCerrada,
    esCorrecta: esCorrecta,
    respuestaU: respuestaU,
    codRsptaOpH: codRsptaOpH,
    opcionRspta: opcionRspta,
    marcada: marcada,
    esValido: esValido,
  );

  factory TcpeDevolucionItemModel.fromEntity(TcpeDevolucionItemEntity e) => TcpeDevolucionItemModel(
    codPreguntaH: e.codPreguntaH,
    orden: e.orden,
    pregunta: e.pregunta,
    esCerrada: e.esCerrada,
    esCorrecta: e.esCorrecta,
    respuestaU: e.respuestaU,
    codRsptaOpH: e.codRsptaOpH,
    opcionRspta: e.opcionRspta,
    marcada: e.marcada,
    esValido: e.esValido,
  );
}
