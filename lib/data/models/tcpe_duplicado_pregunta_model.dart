import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_duplicado_pregunta_entity.dart';

/// Una pregunta igual o parecida de la categoría (`p_list_tcpe_Banco` D).
class TcpeDuplicadoPreguntaModel {
  final BigInt codPregunta;
  final String? pregunta;
  final bool activo;
  final bool igual;

  const TcpeDuplicadoPreguntaModel({required this.codPregunta, this.pregunta, this.activo = true, this.igual = false});

  factory TcpeDuplicadoPreguntaModel.fromJson(Map<String, dynamic> json) => TcpeDuplicadoPreguntaModel(
    codPregunta: tcpeBigInt(json['codPregunta']) ?? BigInt.zero,
    pregunta: tcpeTexto(json['pregunta']),
    activo: tcpeBool(json['activo']) ?? true,
    igual: tcpeBool(json['igual']) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'codPregunta': codPregunta.toInt(),
    'pregunta': pregunta,
    'activo': activo,
    'igual': igual,
  };

  TcpeDuplicadoPreguntaEntity toEntity() =>
      TcpeDuplicadoPreguntaEntity(codPregunta: codPregunta, pregunta: pregunta, activo: activo, igual: igual);

  factory TcpeDuplicadoPreguntaModel.fromEntity(TcpeDuplicadoPreguntaEntity e) =>
      TcpeDuplicadoPreguntaModel(codPregunta: e.codPregunta, pregunta: e.pregunta, activo: e.activo, igual: e.igual);
}
