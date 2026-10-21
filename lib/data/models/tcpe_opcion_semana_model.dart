import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_opcion_semana_entity.dart';

/// Una opción de una pregunta de la semana vigente (`p_list_tcpe_PreguntaSemana`
/// O). `esValido` null = todavía no se puede mostrar cuál es la correcta.
class TcpeOpcionSemanaModel {
  final BigInt? codPreguntaSemana;
  final BigInt codRsptaOp;
  final String? opcionRspta;
  final bool elegida;
  final bool? esValido;

  const TcpeOpcionSemanaModel({
    this.codPreguntaSemana,
    required this.codRsptaOp,
    this.opcionRspta,
    this.elegida = false,
    this.esValido,
  });

  factory TcpeOpcionSemanaModel.fromJson(Map<String, dynamic> json) => TcpeOpcionSemanaModel(
    codPreguntaSemana: tcpeBigInt(json['codPreguntaSemana']),
    codRsptaOp: tcpeBigInt(json['codRsptaOp']) ?? BigInt.zero,
    opcionRspta: tcpeTexto(json['opcionRspta']),
    elegida: tcpeBool(json['elegida']) ?? false,
    esValido: tcpeBool(json['esValido']),
  );

  Map<String, dynamic> toJson() => {
    'codPreguntaSemana': codPreguntaSemana?.toInt(),
    'codRsptaOp': codRsptaOp.toInt(),
    'opcionRspta': opcionRspta,
    'elegida': elegida,
    'esValido': esValido,
  };

  TcpeOpcionSemanaEntity toEntity() => TcpeOpcionSemanaEntity(
    codPreguntaSemana: codPreguntaSemana,
    codRsptaOp: codRsptaOp,
    opcionRspta: opcionRspta,
    elegida: elegida,
    esValido: esValido,
  );

  factory TcpeOpcionSemanaModel.fromEntity(TcpeOpcionSemanaEntity e) => TcpeOpcionSemanaModel(
    codPreguntaSemana: e.codPreguntaSemana,
    codRsptaOp: e.codRsptaOp,
    opcionRspta: e.opcionRspta,
    elegida: e.elegida,
    esValido: e.esValido,
  );
}
