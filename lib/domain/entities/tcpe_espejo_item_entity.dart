import 'package:bosque_flutter/domain/entities/tcpe_devolucion_item_entity.dart';

/// Una fila del espejo de un examen en curso (`p_list_tcpe_Monitor` E): la pregunta actual, una fila por opción.
class TcpeEspejoItemEntity {
  final BigInt codExamen;
  final String? nombreCompleto;
  final String? estado;
  final int segundosRestantes;
  final String? conexion;
  final int totalPreguntas;
  final int respondidas;
  final int? ordenActual;
  final BigInt? codPreguntaH;
  final String? pregunta;
  final bool esCerrada;
  final String? respuestaU;
  final BigInt? codRsptaOpH;
  final String? opcionRspta;
  final bool marcada;
  /// El evaluador sí ve cuáles son las válidas.
  final bool? esValido;

  const TcpeEspejoItemEntity({
    required this.codExamen,
    this.nombreCompleto,
    this.estado,
    this.segundosRestantes = 0,
    this.conexion,
    this.totalPreguntas = 0,
    this.respondidas = 0,
    this.ordenActual,
    this.codPreguntaH,
    this.pregunta,
    this.esCerrada = false,
    this.respuestaU,
    this.codRsptaOpH,
    this.opcionRspta,
    this.marcada = false,
    this.esValido,
  });

  TcpeEspejoItemEntity copyWith({
    BigInt? codExamen,
    String? nombreCompleto,
    String? estado,
    int? segundosRestantes,
    String? conexion,
    int? totalPreguntas,
    int? respondidas,
    int? ordenActual,
    BigInt? codPreguntaH,
    String? pregunta,
    bool? esCerrada,
    String? respuestaU,
    BigInt? codRsptaOpH,
    String? opcionRspta,
    bool? marcada,
    bool? esValido,
  }) => TcpeEspejoItemEntity(
    codExamen: codExamen ?? this.codExamen,
    nombreCompleto: nombreCompleto ?? this.nombreCompleto,
    estado: estado ?? this.estado,
    segundosRestantes: segundosRestantes ?? this.segundosRestantes,
    conexion: conexion ?? this.conexion,
    totalPreguntas: totalPreguntas ?? this.totalPreguntas,
    respondidas: respondidas ?? this.respondidas,
    ordenActual: ordenActual ?? this.ordenActual,
    codPreguntaH: codPreguntaH ?? this.codPreguntaH,
    pregunta: pregunta ?? this.pregunta,
    esCerrada: esCerrada ?? this.esCerrada,
    respuestaU: respuestaU ?? this.respuestaU,
    codRsptaOpH: codRsptaOpH ?? this.codRsptaOpH,
    opcionRspta: opcionRspta ?? this.opcionRspta,
    marcada: marcada ?? this.marcada,
    esValido: esValido ?? this.esValido,
  );

  /// La pregunta que tiene delante, armada desde las filas (una por opción),
  /// como la muestra la devolución. Null si todavía no abrió ninguna.
  static TcpeDevolucionPreguntaEntity? preguntaActualDe(List<TcpeEspejoItemEntity> filas) {
    final conPregunta = [
      for (final f in filas)
        if (f.codPreguntaH != null) f,
    ];
    if (conPregunta.isEmpty) return null;
    final grupos = TcpeDevolucionPreguntaEntity.agrupar([
      for (final f in conPregunta)
        TcpeDevolucionItemEntity(
          codPreguntaH: f.codPreguntaH!,
          orden: f.ordenActual ?? 0,
          pregunta: f.pregunta,
          esCerrada: f.esCerrada,
          respuestaU: f.respuestaU,
          codRsptaOpH: f.codRsptaOpH,
          opcionRspta: f.opcionRspta,
          marcada: f.marcada,
          esValido: f.esValido,
        ),
    ]);
    return grupos.first;
  }
}
