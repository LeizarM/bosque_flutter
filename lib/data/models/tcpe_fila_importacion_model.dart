import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_fila_importacion_entity.dart';

/// Una fila de la validación de la carga en lote (`p_list_tcpe_BancoLote` V).
class TcpeFilaImportacionModel {
  final int fila;
  final String? pregunta;
  final bool esCerrada;
  final int cantOpciones;
  final int cantValidas;
  final String? estado;
  final String? mensaje;
  final BigInt? codPreguntaExistente;

  const TcpeFilaImportacionModel({
    required this.fila,
    this.pregunta,
    this.esCerrada = false,
    this.cantOpciones = 0,
    this.cantValidas = 0,
    this.estado,
    this.mensaje,
    this.codPreguntaExistente,
  });

  factory TcpeFilaImportacionModel.fromJson(Map<String, dynamic> json) => TcpeFilaImportacionModel(
    fila: tcpeInt(json['fila']) ?? 0,
    pregunta: tcpeTexto(json['pregunta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    cantOpciones: tcpeInt(json['cantOpciones']) ?? 0,
    cantValidas: tcpeInt(json['cantValidas']) ?? 0,
    estado: tcpeTexto(json['estado']),
    mensaje: tcpeTexto(json['mensaje']),
    codPreguntaExistente: tcpeBigInt(json['codPreguntaExistente']),
  );

  Map<String, dynamic> toJson() => {
    'fila': fila,
    'pregunta': pregunta,
    'esCerrada': esCerrada,
    'cantOpciones': cantOpciones,
    'cantValidas': cantValidas,
    'estado': estado,
    'mensaje': mensaje,
    'codPreguntaExistente': codPreguntaExistente?.toInt(),
  };

  TcpeFilaImportacionEntity toEntity() => TcpeFilaImportacionEntity(
    fila: fila,
    pregunta: pregunta,
    esCerrada: esCerrada,
    cantOpciones: cantOpciones,
    cantValidas: cantValidas,
    estado: EstadoFilaImportacion.desde(estado),
    mensaje: mensaje,
    codPreguntaExistente: codPreguntaExistente,
  );

  factory TcpeFilaImportacionModel.fromEntity(TcpeFilaImportacionEntity e) => TcpeFilaImportacionModel(
    fila: e.fila,
    pregunta: e.pregunta,
    esCerrada: e.esCerrada,
    cantOpciones: e.cantOpciones,
    cantValidas: e.cantValidas,
    estado: e.estado.codigo,
    mensaje: e.mensaje,
    codPreguntaExistente: e.codPreguntaExistente,
  );
}
