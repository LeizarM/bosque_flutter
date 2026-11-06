import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_linea_entity.dart';

/// Columnas de `p_list_thex_Reporte` K. Solo lectura.
class HexReporteLineaModel {
  const HexReporteLineaModel(this.entidad);

  final HexReporteLineaEntity entidad;

  factory HexReporteLineaModel.fromJson(Map<String, dynamic> j) =>
      HexReporteLineaModel(
        HexReporteLineaEntity(
          idReporte: hexBigInt(j['idReporte']),
          concepto: hexTexto(j['concepto']),
          codigo: hexTexto(j['codigo']),
          leyenda: hexTexto(j['leyenda']),
          minutos: hexIntN(j['minutos']),
          cantidad: hexDecimal(j['cantidad']),
          multiplicador: hexDecimalN(j['multiplicador']),
          valorUnitario: hexDecimalN(j['valorUnitario']),
          monto: hexDecimalN(j['monto']),
        ),
      );

  factory HexReporteLineaModel.fromEntity(HexReporteLineaEntity e) =>
      HexReporteLineaModel(e);

  HexReporteLineaEntity toEntity() => entidad;
}
