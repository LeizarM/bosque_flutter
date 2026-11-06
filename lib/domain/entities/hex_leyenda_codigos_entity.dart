import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';

/// Tramos y comidas vigentes hoy: la leyenda de códigos que se muestra en
/// pantalla junto a los reportes.
class HexLeyendaCodigosEntity {
  final List<HexTramoEntity> tramos;
  final List<HexComidaEntity> comidas;

  const HexLeyendaCodigosEntity({
    this.tramos = const [],
    this.comidas = const [],
  });
}
