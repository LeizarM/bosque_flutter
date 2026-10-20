import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_opcion_entity.dart';

/// Opción de una pregunta cerrada del banco (`p_list_tcpe_Banco` O).
class TcpeBancoOpcionModel {
  final BigInt codRsptaOp;
  final BigInt? codRespuesta;
  final BigInt? codPregunta;
  final String? opcionRspta;
  final bool esValido;
  final bool usadaEnExamenes;

  const TcpeBancoOpcionModel({
    required this.codRsptaOp,
    this.codRespuesta,
    this.codPregunta,
    this.opcionRspta,
    this.esValido = false,
    this.usadaEnExamenes = false,
  });

  factory TcpeBancoOpcionModel.fromJson(Map<String, dynamic> json) => TcpeBancoOpcionModel(
    codRsptaOp: tcpeBigInt(json['codRsptaOp']) ?? BigInt.zero,
    codRespuesta: tcpeBigInt(json['codRespuesta']),
    codPregunta: tcpeBigInt(json['codPregunta']),
    opcionRspta: tcpeTexto(json['opcionRspta']),
    esValido: tcpeBool(json['esValido']) ?? false,
    usadaEnExamenes: tcpeBool(json['usadaEnExamenes']) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'codRsptaOp': codRsptaOp.toInt(),
    'codRespuesta': codRespuesta?.toInt(),
    'codPregunta': codPregunta?.toInt(),
    'opcionRspta': opcionRspta,
    'esValido': esValido,
    'usadaEnExamenes': usadaEnExamenes,
  };

  /// Solo lo que recibe el endpoint de escritura.
  Map<String, dynamic> toGuardarJson() => {
    'codRsptaOp': codRsptaOp.toInt(),
    'opcionRspta': opcionRspta,
    'esValido': esValido,
  };

  TcpeBancoOpcionEntity toEntity() => TcpeBancoOpcionEntity(
    codRsptaOp: codRsptaOp,
    codRespuesta: codRespuesta,
    codPregunta: codPregunta,
    opcionRspta: opcionRspta,
    esValido: esValido,
    usadaEnExamenes: usadaEnExamenes,
  );

  factory TcpeBancoOpcionModel.fromEntity(TcpeBancoOpcionEntity e) => TcpeBancoOpcionModel(
    codRsptaOp: e.codRsptaOp,
    codRespuesta: e.codRespuesta,
    codPregunta: e.codPregunta,
    opcionRspta: e.opcionRspta,
    esValido: e.esValido,
    usadaEnExamenes: e.usadaEnExamenes,
  );
}
