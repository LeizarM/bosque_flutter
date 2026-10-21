import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_ranking_pregunta_entity.dart';

/// Una fila del ranking de preguntas más falladas (`p_list_tcpe_Resultado` P).
class TcpeRankingPreguntaModel {
  final int puesto;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  final String? nombreArea;
  final BigInt codPregunta;
  final String? pregunta;
  final bool esCerrada;
  final int veces;
  final int aciertos;
  final int fallos;
  final int sinResponder;
  final int incompletas;
  final double porcentajeFallo;
  final String? errorComun;
  final int vecesErrorComun;

  const TcpeRankingPreguntaModel({
    required this.puesto,
    this.codClasificacion,
    this.nombreClasificacion,
    this.nombreArea,
    required this.codPregunta,
    this.pregunta,
    this.esCerrada = true,
    this.veces = 0,
    this.aciertos = 0,
    this.fallos = 0,
    this.sinResponder = 0,
    this.incompletas = 0,
    this.porcentajeFallo = 0,
    this.errorComun,
    this.vecesErrorComun = 0,
  });

  factory TcpeRankingPreguntaModel.fromJson(Map<String, dynamic> json) => TcpeRankingPreguntaModel(
    puesto: tcpeInt(json['puesto']) ?? 0,
    codClasificacion: tcpeBigInt(json['codClasificacion']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    nombreArea: tcpeTexto(json['nombreArea']),
    codPregunta: tcpeBigInt(json['codPregunta']) ?? BigInt.zero,
    pregunta: tcpeTexto(json['pregunta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? true,
    veces: tcpeInt(json['veces']) ?? 0,
    aciertos: tcpeInt(json['aciertos']) ?? 0,
    fallos: tcpeInt(json['fallos']) ?? 0,
    sinResponder: tcpeInt(json['sinResponder']) ?? 0,
    incompletas: tcpeInt(json['incompletas']) ?? 0,
    porcentajeFallo: tcpeDouble(json['porcentajeFallo']) ?? 0,
    errorComun: tcpeTexto(json['errorComun']),
    vecesErrorComun: tcpeInt(json['vecesErrorComun']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'puesto': puesto,
    'codClasificacion': codClasificacion?.toInt(),
    'nombreClasificacion': nombreClasificacion,
    'nombreArea': nombreArea,
    'codPregunta': codPregunta.toInt(),
    'pregunta': pregunta,
    'esCerrada': esCerrada,
    'veces': veces,
    'aciertos': aciertos,
    'fallos': fallos,
    'sinResponder': sinResponder,
    'incompletas': incompletas,
    'porcentajeFallo': porcentajeFallo,
    'errorComun': errorComun,
    'vecesErrorComun': vecesErrorComun,
  };

  TcpeRankingPreguntaEntity toEntity() => TcpeRankingPreguntaEntity(
    puesto: puesto,
    codClasificacion: codClasificacion,
    nombreClasificacion: nombreClasificacion,
    nombreArea: nombreArea,
    codPregunta: codPregunta,
    pregunta: pregunta,
    esCerrada: esCerrada,
    veces: veces,
    aciertos: aciertos,
    fallos: fallos,
    sinResponder: sinResponder,
    incompletas: incompletas,
    porcentajeFallo: porcentajeFallo,
    errorComun: errorComun,
    vecesErrorComun: vecesErrorComun,
  );

  factory TcpeRankingPreguntaModel.fromEntity(TcpeRankingPreguntaEntity e) => TcpeRankingPreguntaModel(
    puesto: e.puesto,
    codClasificacion: e.codClasificacion,
    nombreClasificacion: e.nombreClasificacion,
    nombreArea: e.nombreArea,
    codPregunta: e.codPregunta,
    pregunta: e.pregunta,
    esCerrada: e.esCerrada,
    veces: e.veces,
    aciertos: e.aciertos,
    fallos: e.fallos,
    sinResponder: e.sinResponder,
    incompletas: e.incompletas,
    porcentajeFallo: e.porcentajeFallo,
    errorComun: e.errorComun,
    vecesErrorComun: e.vecesErrorComun,
  );
}
