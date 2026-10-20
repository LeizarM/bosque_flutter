import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_opcion_rendicion_entity.dart';

/// Opción de una pregunta cerrada en curso (`p_list_tcpe_Rendir` O).
/// Nunca trae `esValido`: quien rinde no puede saber cuál es la correcta.
class TcpeOpcionRendicionModel {
  final BigInt codRsptaOpH;
  final BigInt? codPreguntaH;
  final String? opcionRspta;
  final bool marcada;

  const TcpeOpcionRendicionModel({
    required this.codRsptaOpH,
    this.codPreguntaH,
    this.opcionRspta,
    this.marcada = false,
  });

  factory TcpeOpcionRendicionModel.fromJson(Map<String, dynamic> json) => TcpeOpcionRendicionModel(
    codRsptaOpH: tcpeBigInt(json['codRsptaOpH']) ?? BigInt.zero,
    codPreguntaH: tcpeBigInt(json['codPreguntaH']),
    opcionRspta: tcpeTexto(json['opcionRspta']),
    marcada: tcpeBool(json['marcada']) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'codRsptaOpH': codRsptaOpH.toInt(),
    'codPreguntaH': codPreguntaH?.toInt(),
    'opcionRspta': opcionRspta,
    'marcada': marcada,
  };

  TcpeOpcionRendicionEntity toEntity() => TcpeOpcionRendicionEntity(
    codRsptaOpH: codRsptaOpH,
    codPreguntaH: codPreguntaH,
    opcionRspta: opcionRspta,
    marcada: marcada,
  );

  factory TcpeOpcionRendicionModel.fromEntity(TcpeOpcionRendicionEntity e) => TcpeOpcionRendicionModel(
    codRsptaOpH: e.codRsptaOpH,
    codPreguntaH: e.codPreguntaH,
    opcionRspta: e.opcionRspta,
    marcada: e.marcada,
  );
}
