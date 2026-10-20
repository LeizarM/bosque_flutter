import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_pregunta_entity.dart';

/// Pregunta del banco con su categoría, área y respuesta (`p_list_tcpe_Banco` L).
class TcpeBancoPreguntaModel {
  final BigInt codPregunta;
  final BigInt? codClasificacion;
  final String? nombreClasificacion;
  final BigInt? codArea;
  final String? nombreArea;
  final String? pregunta;
  final int? prioridad;
  final bool activo;
  final BigInt? codRespuesta;
  final bool esCerrada;
  final String? respuesta;
  final int cantOpciones;
  final int cantValidas;
  final int usadaEnExamenes;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeBancoPreguntaModel({
    required this.codPregunta,
    this.codClasificacion,
    this.nombreClasificacion,
    this.codArea,
    this.nombreArea,
    this.pregunta,
    this.prioridad,
    this.activo = true,
    this.codRespuesta,
    this.esCerrada = false,
    this.respuesta,
    this.cantOpciones = 0,
    this.cantValidas = 0,
    this.usadaEnExamenes = 0,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeBancoPreguntaModel.fromJson(Map<String, dynamic> json) => TcpeBancoPreguntaModel(
    codPregunta: tcpeBigInt(json['codPregunta']) ?? BigInt.zero,
    codClasificacion: tcpeBigInt(json['codClasificacion']),
    nombreClasificacion: tcpeTexto(json['nombreClasificacion']),
    codArea: tcpeBigInt(json['codArea']),
    nombreArea: tcpeTexto(json['nombreArea']),
    pregunta: tcpeTexto(json['pregunta']),
    prioridad: tcpeInt(json['prioridad']),
    activo: tcpeBool(json['activo']) ?? true,
    codRespuesta: tcpeBigInt(json['codRespuesta']),
    esCerrada: tcpeBool(json['esCerrada']) ?? false,
    respuesta: tcpeTexto(json['respuesta']),
    cantOpciones: tcpeInt(json['cantOpciones']) ?? 0,
    cantValidas: tcpeInt(json['cantValidas']) ?? 0,
    usadaEnExamenes: tcpeInt(json['usadaEnExamenes']) ?? 0,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codPregunta': codPregunta.toInt(),
    'codClasificacion': codClasificacion?.toInt(),
    'nombreClasificacion': nombreClasificacion,
    'codArea': codArea?.toInt(),
    'nombreArea': nombreArea,
    'pregunta': pregunta,
    'prioridad': prioridad,
    'activo': activo,
    'codRespuesta': codRespuesta?.toInt(),
    'esCerrada': esCerrada,
    'respuesta': respuesta,
    'cantOpciones': cantOpciones,
    'cantValidas': cantValidas,
    'usadaEnExamenes': usadaEnExamenes,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  /// Solo lo que recibe el endpoint de escritura.
  Map<String, dynamic> toGuardarJson() => {
    'codPregunta': codPregunta.toInt(),
    'codClasificacion': codClasificacion?.toInt(),
    'pregunta': pregunta,
    'prioridad': prioridad,
    'activo': activo,
    'esCerrada': esCerrada,
    'respuesta': respuesta,
  };

  TcpeBancoPreguntaEntity toEntity() => TcpeBancoPreguntaEntity(
    codPregunta: codPregunta,
    codClasificacion: codClasificacion,
    nombreClasificacion: nombreClasificacion,
    codArea: codArea,
    nombreArea: nombreArea,
    pregunta: pregunta,
    prioridad: prioridad,
    activo: activo,
    codRespuesta: codRespuesta,
    esCerrada: esCerrada,
    respuesta: respuesta,
    cantOpciones: cantOpciones,
    cantValidas: cantValidas,
    usadaEnExamenes: usadaEnExamenes,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeBancoPreguntaModel.fromEntity(TcpeBancoPreguntaEntity e) => TcpeBancoPreguntaModel(
    codPregunta: e.codPregunta,
    codClasificacion: e.codClasificacion,
    nombreClasificacion: e.nombreClasificacion,
    codArea: e.codArea,
    nombreArea: e.nombreArea,
    pregunta: e.pregunta,
    prioridad: e.prioridad,
    activo: e.activo,
    codRespuesta: e.codRespuesta,
    esCerrada: e.esCerrada,
    respuesta: e.respuesta,
    cantOpciones: e.cantOpciones,
    cantValidas: e.cantValidas,
    usadaEnExamenes: e.usadaEnExamenes,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
