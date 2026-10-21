import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_pregunta_semana_entity.dart';

/// El tipo de una pregunta de la semana: `E` (escala) o, si no, `A` (abierta).
String tcpeTipoSemana(Object? v) => (tcpeTexto(v) ?? '').trim().toUpperCase() == 'E' ? 'E' : 'A';

/// `tcpe_preguntaSemana` (v12/v13). Lee las columnas de `p_list_tcpe_PreguntaSemana`
/// L; [toJson] manda solo las de la tabla (lo de la gestión es de solo lectura).
class TcpePreguntaSemanaModel {
  final BigInt codPreguntaSemana;
  final String? titulo;
  final String? pregunta;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activo;
  final String tipo;
  final int? escalaMin;
  final int? escalaMax;
  final String? etiquetaMin;
  final String? etiquetaMax;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;
  final String? tituloMostrado;
  final String? tipoMostrado;
  final String? estado;
  final int respuestas;
  final double? promedio;

  const TcpePreguntaSemanaModel({
    required this.codPreguntaSemana,
    this.titulo,
    this.pregunta,
    this.fechaInicio,
    this.fechaFin,
    this.activo = true,
    this.tipo = 'A',
    this.escalaMin,
    this.escalaMax,
    this.etiquetaMin,
    this.etiquetaMax,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
    this.tituloMostrado,
    this.tipoMostrado,
    this.estado,
    this.respuestas = 0,
    this.promedio,
  });

  factory TcpePreguntaSemanaModel.fromJson(Map<String, dynamic> json) => TcpePreguntaSemanaModel(
    codPreguntaSemana: tcpeBigInt(json['codPreguntaSemana']) ?? BigInt.zero,
    titulo: tcpeTexto(json['titulo']),
    pregunta: tcpeTexto(json['pregunta']),
    fechaInicio: tcpeFecha(json['fechaInicio']),
    fechaFin: tcpeFecha(json['fechaFin']),
    activo: tcpeBool(json['activo']) ?? true,
    tipo: tcpeTipoSemana(json['tipo']),
    escalaMin: tcpeInt(json['escalaMin']),
    escalaMax: tcpeInt(json['escalaMax']),
    etiquetaMin: tcpeTexto(json['etiquetaMin']),
    etiquetaMax: tcpeTexto(json['etiquetaMax']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
    tituloMostrado: tcpeTexto(json['tituloMostrado']),
    tipoMostrado: tcpeTexto(json['tipoMostrado']),
    estado: tcpeTexto(json['estado']),
    respuestas: tcpeInt(json['respuestas']) ?? 0,
    promedio: tcpeDouble(json['promedio']),
  );

  /// Las columnas de la tabla, para el CRUD genérico.
  Map<String, dynamic> toJson() => {
    'codPreguntaSemana': codPreguntaSemana.toInt(),
    'titulo': titulo,
    'pregunta': pregunta,
    'fechaInicio': tcpeFechaJson(fechaInicio),
    'fechaFin': tcpeFechaJson(fechaFin),
    'activo': activo,
    'tipo': tipo,
    'escalaMin': escalaMin,
    'escalaMax': escalaMax,
    'etiquetaMin': etiquetaMin,
    'etiquetaMax': etiquetaMax,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  /// El cuerpo de `/examenes/pregunta-semana/guardar`: sin PK es un alta. Una
  /// abierta no manda escala ni etiquetas; las reglas las aplica el SP.
  Map<String, dynamic> toGuardarJson() {
    String? limpio(String? s) => (s ?? '').trim().isEmpty ? null : s!.trim();
    final escala = tipo == 'E';
    return {
      if (codPreguntaSemana > BigInt.zero) 'codPreguntaSemana': codPreguntaSemana.toInt(),
      'titulo': limpio(titulo),
      'pregunta': limpio(pregunta),
      'tipo': escala ? 'E' : 'A',
      if (escala) ...{
        'escalaMin': escalaMin,
        'escalaMax': escalaMax,
        'etiquetaMin': limpio(etiquetaMin),
        'etiquetaMax': limpio(etiquetaMax),
      },
      'fechaInicio': tcpeFechaJson(fechaInicio),
      'fechaFin': tcpeFechaJson(fechaFin),
    };
  }

  TcpePreguntaSemanaEntity toEntity() => TcpePreguntaSemanaEntity(
    codPreguntaSemana: codPreguntaSemana,
    titulo: titulo,
    pregunta: pregunta,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    activo: activo,
    tipo: tipo,
    escalaMin: escalaMin,
    escalaMax: escalaMax,
    etiquetaMin: etiquetaMin,
    etiquetaMax: etiquetaMax,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
    tituloMostrado: tituloMostrado,
    tipoMostrado: tipoMostrado,
    estado: estado,
    respuestas: respuestas,
    promedio: promedio,
  );

  factory TcpePreguntaSemanaModel.fromEntity(TcpePreguntaSemanaEntity e) => TcpePreguntaSemanaModel(
    codPreguntaSemana: e.codPreguntaSemana,
    titulo: e.titulo,
    pregunta: e.pregunta,
    fechaInicio: e.fechaInicio,
    fechaFin: e.fechaFin,
    activo: e.activo,
    tipo: e.esEscala ? 'E' : 'A',
    escalaMin: e.escalaMin,
    escalaMax: e.escalaMax,
    etiquetaMin: e.etiquetaMin,
    etiquetaMax: e.etiquetaMax,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
    tituloMostrado: e.tituloMostrado,
    tipoMostrado: e.tipoMostrado,
    estado: e.estado,
    respuestas: e.respuestas,
    promedio: e.promedio,
  );
}
