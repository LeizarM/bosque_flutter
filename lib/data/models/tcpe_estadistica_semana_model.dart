import 'package:bosque_flutter/data/models/tcpe_json.dart';
import 'package:bosque_flutter/domain/entities/tcpe_estadistica_semana_entity.dart';

/// Cuántos eligieron cada opción de una pregunta de la semana
/// (`p_list_tcpe_PreguntaSemana` E).
class TcpeEstadisticaSemanaModel {
  final BigInt codRsptaOp;
  final String? opcionRspta;
  final bool esValido;
  final int veces;
  final double porcentaje;

  const TcpeEstadisticaSemanaModel({
    required this.codRsptaOp,
    this.opcionRspta,
    this.esValido = false,
    this.veces = 0,
    this.porcentaje = 0,
  });

  factory TcpeEstadisticaSemanaModel.fromJson(Map<String, dynamic> json) => TcpeEstadisticaSemanaModel(
    codRsptaOp: tcpeBigInt(json['codRsptaOp']) ?? BigInt.zero,
    opcionRspta: tcpeTexto(json['opcionRspta']),
    esValido: tcpeBool(json['esValido']) ?? false,
    veces: tcpeInt(json['veces']) ?? 0,
    porcentaje: tcpeDouble(json['porcentaje']) ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'codRsptaOp': codRsptaOp.toInt(),
    'opcionRspta': opcionRspta,
    'esValido': esValido,
    'veces': veces,
    'porcentaje': porcentaje,
  };

  TcpeEstadisticaSemanaEntity toEntity() => TcpeEstadisticaSemanaEntity(
    codRsptaOp: codRsptaOp,
    opcionRspta: opcionRspta,
    esValido: esValido,
    veces: veces,
    porcentaje: porcentaje,
  );

  factory TcpeEstadisticaSemanaModel.fromEntity(TcpeEstadisticaSemanaEntity e) => TcpeEstadisticaSemanaModel(
    codRsptaOp: e.codRsptaOp,
    opcionRspta: e.opcionRspta,
    esValido: e.esValido,
    veces: e.veces,
    porcentaje: e.porcentaje,
  );
}
