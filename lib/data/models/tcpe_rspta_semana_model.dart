import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_rspta_semana_entity.dart';

/// `tcpe_rsptaSemana` (v11): columnas de `p_list_tcpe_RsptaSemana` L más
/// `nombreUsuario`.
class TcpeRsptaSemanaModel {
  final BigInt codRsptaSemana;
  final BigInt? codPreguntaSemana;
  final BigInt? codUsuario;
  final BigInt? codRsptaOp;
  final bool esCorrecta;
  final BigInt? audUsuario;
  final DateTime? audFecha;
  final String? nombreUsuario;

  const TcpeRsptaSemanaModel({
    required this.codRsptaSemana,
    this.codPreguntaSemana,
    this.codUsuario,
    this.codRsptaOp,
    this.esCorrecta = false,
    this.audUsuario,
    this.audFecha,
    this.nombreUsuario,
  });

  factory TcpeRsptaSemanaModel.fromJson(Map<String, dynamic> json) => TcpeRsptaSemanaModel(
    codRsptaSemana: tcpeBigInt(json['codRsptaSemana']) ?? BigInt.zero,
    codPreguntaSemana: tcpeBigInt(json['codPreguntaSemana']),
    codUsuario: tcpeBigInt(json['codUsuario']),
    codRsptaOp: tcpeBigInt(json['codRsptaOp']),
    esCorrecta: tcpeBool(json['esCorrecta']) ?? false,
    audUsuario: tcpeBigInt(json['audUsuario']),
    audFecha: tcpeFecha(json['audFecha']),
    nombreUsuario: tcpeTexto(json['nombreUsuario']),
  );

  Map<String, dynamic> toJson() => {
    'codRsptaSemana': codRsptaSemana.toInt(),
    'codPreguntaSemana': codPreguntaSemana?.toInt(),
    'codUsuario': codUsuario?.toInt(),
    'codRsptaOp': codRsptaOp?.toInt(),
    'esCorrecta': esCorrecta,
    'audUsuario': audUsuario?.toInt(),
    'audFecha': tcpeFechaHoraJson(audFecha),
    'nombreUsuario': nombreUsuario,
  };

  TcpeRsptaSemanaEntity toEntity() => TcpeRsptaSemanaEntity(
    codRsptaSemana: codRsptaSemana,
    codPreguntaSemana: codPreguntaSemana,
    codUsuario: codUsuario,
    codRsptaOp: codRsptaOp,
    esCorrecta: esCorrecta,
    audUsuario: audUsuario,
    audFecha: audFecha,
    nombreUsuario: nombreUsuario,
  );

  factory TcpeRsptaSemanaModel.fromEntity(TcpeRsptaSemanaEntity e) => TcpeRsptaSemanaModel(
    codRsptaSemana: e.codRsptaSemana,
    codPreguntaSemana: e.codPreguntaSemana,
    codUsuario: e.codUsuario,
    codRsptaOp: e.codRsptaOp,
    esCorrecta: e.esCorrecta,
    audUsuario: e.audUsuario,
    audFecha: e.audFecha,
    nombreUsuario: e.nombreUsuario,
  );
}
