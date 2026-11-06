import 'package:bosque_flutter/domain/entities/hex_simulacion_aviso_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_jornada_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_segmento_entity.dart';

/// El simulador de una jornada: la jornada, cómo se reparte en tramos y
/// comidas, y los avisos. No guarda nada.
class HexSimulacionEntity {
  /// Nula si el servidor no devolvió la jornada (204).
  final HexSimulacionJornadaEntity? jornada;
  final List<HexSimulacionSegmentoEntity> segmentos;
  final List<HexSimulacionAvisoEntity> avisos;

  const HexSimulacionEntity({
    this.jornada,
    this.segmentos = const [],
    this.avisos = const [],
  });
}
