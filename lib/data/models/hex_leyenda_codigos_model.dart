import 'package:bosque_flutter/data/models/hex_comida_model.dart';
import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/data/models/hex_tramo_model.dart';
import 'package:bosque_flutter/domain/entities/hex_leyenda_codigos_entity.dart';

/// Objeto de `/horas-extras/leyenda-codigos`: tramos y comidas vigentes hoy.
/// Solo lectura.
class HexLeyendaCodigosModel {
  const HexLeyendaCodigosModel(this.entidad);

  final HexLeyendaCodigosEntity entidad;

  factory HexLeyendaCodigosModel.fromJson(Map<String, dynamic> j) =>
      HexLeyendaCodigosModel(
        HexLeyendaCodigosEntity(
          tramos: [
            for (final f in hexFilas(j['tramos']))
              HexTramoModel.fromJson(f).toEntity(),
          ],
          comidas: [
            for (final f in hexFilas(j['comidas']))
              HexComidaModel.fromJson(f).toEntity(),
          ],
        ),
      );

  factory HexLeyendaCodigosModel.fromEntity(HexLeyendaCodigosEntity e) =>
      HexLeyendaCodigosModel(e);

  HexLeyendaCodigosEntity toEntity() => entidad;
}
