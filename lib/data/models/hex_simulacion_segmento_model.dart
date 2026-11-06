import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_simulacion_segmento_entity.dart';

/// Columnas de `p_list_thex_Simulacion` S. Solo lectura.
class HexSimulacionSegmentoModel {
  const HexSimulacionSegmentoModel(this.entidad);

  final HexSimulacionSegmentoEntity entidad;

  factory HexSimulacionSegmentoModel.fromJson(Map<String, dynamic> j) =>
      HexSimulacionSegmentoModel(
        HexSimulacionSegmentoEntity(
          orden: hexInt(j['orden']),
          desde: hexFecha(j['desde']),
          hasta: hexFecha(j['hasta']),
          horaDesde: hexTexto(j['horaDesde']),
          horaHasta: hexTexto(j['horaHasta']),
          minutos: hexInt(j['minutos']),
          duracionTexto: hexTexto(j['duracionTexto']),
          clase: hexTexto(j['clase']),
          codigo: hexTextoN(j['codigo']),
          leyenda: hexTextoN(j['leyenda']),
          multiplicador: hexDecimalN(j['multiplicador']),
          monto: hexDecimal(j['monto']),
          textoPago: hexTexto(j['textoPago']),
          resumen: hexTextoN(j['resumen']),
        ),
      );

  factory HexSimulacionSegmentoModel.fromEntity(
    HexSimulacionSegmentoEntity e,
  ) => HexSimulacionSegmentoModel(e);

  HexSimulacionSegmentoEntity toEntity() => entidad;
}
