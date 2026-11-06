import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/data/models/hex_simulacion_aviso_model.dart';
import 'package:bosque_flutter/data/models/hex_simulacion_jornada_model.dart';
import 'package:bosque_flutter/data/models/hex_simulacion_segmento_model.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_entity.dart';

/// Objeto de `/horas-extras/simulador/jornada`: `jornada`, `segmentos` y
/// `avisos`. Solo lectura.
class HexSimulacionModel {
  const HexSimulacionModel(this.entidad);

  final HexSimulacionEntity entidad;

  factory HexSimulacionModel.fromJson(Map<String, dynamic> j) {
    final jornada = j['jornada'];
    return HexSimulacionModel(
      HexSimulacionEntity(
        jornada:
            jornada is Map
                ? HexSimulacionJornadaModel.fromJson(
                  Map<String, dynamic>.from(jornada),
                ).toEntity()
                : null,
        segmentos: [
          for (final f in hexFilas(j['segmentos']))
            HexSimulacionSegmentoModel.fromJson(f).toEntity(),
        ],
        avisos: [
          for (final f in hexFilas(j['avisos']))
            HexSimulacionAvisoModel.fromJson(f).toEntity(),
        ],
      ),
    );
  }

  factory HexSimulacionModel.fromEntity(HexSimulacionEntity e) =>
      HexSimulacionModel(e);

  HexSimulacionEntity toEntity() => entidad;
}
