import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_tramo_entity.dart';

/// Columnas de `p_list_thex_Reporte` T (D36). Solo lectura.
class HexReporteTramoModel {
  const HexReporteTramoModel(this.entidad);

  final HexReporteTramoEntity entidad;

  factory HexReporteTramoModel.fromJson(Map<String, dynamic> j) =>
      HexReporteTramoModel(
        HexReporteTramoEntity(
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
          textoPago: hexTexto(j['textoPago']),
          resumen: hexTextoN(j['resumen']),
        ),
      );

  factory HexReporteTramoModel.fromEntity(HexReporteTramoEntity e) =>
      HexReporteTramoModel(e);

  HexReporteTramoEntity toEntity() => entidad;
}
