import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_seleccion_preguntas_entity.dart';

/// `tcpe_seleccionPreguntas`: Pregunta del banco sorteada para un examen.
/// Columnas de `p_list_tcpe_SeleccionPreguntas` (sin `password2`) más `nombreUsuario`.
class TcpeSeleccionPreguntasModel {
  final BigInt codSeleccionPreguntas;
  final BigInt? codExamen;
  final BigInt? codPregunta;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeSeleccionPreguntasModel({
    required this.codSeleccionPreguntas,
    this.codExamen,
    this.codPregunta,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeSeleccionPreguntasModel.fromJson(Map<String, dynamic> json) => TcpeSeleccionPreguntasModel(
    codSeleccionPreguntas: tcpeBigInt(json['codSeleccionPreguntas']) ?? BigInt.zero,
    codExamen: tcpeBigInt(json['codExamen']),
    codPregunta: tcpeBigInt(json['codPregunta']),
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codSeleccionPreguntas': codSeleccionPreguntas.toInt(),
    'codExamen': codExamen?.toInt(),
    'codPregunta': codPregunta?.toInt(),
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeSeleccionPreguntasEntity toEntity() => TcpeSeleccionPreguntasEntity(
    codSeleccionPreguntas: codSeleccionPreguntas,
    codExamen: codExamen,
    codPregunta: codPregunta,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeSeleccionPreguntasModel.fromEntity(TcpeSeleccionPreguntasEntity e) => TcpeSeleccionPreguntasModel(
    codSeleccionPreguntas: e.codSeleccionPreguntas,
    codExamen: e.codExamen,
    codPregunta: e.codPregunta,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
