import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_anexo_entity.dart';

/// Columnas de `p_list_thex_PlanillaDetalle` G. Solo lectura.
class HexCodigoLeyendaModel {
  const HexCodigoLeyendaModel(this.entidad);

  final HexCodigoLeyendaEntity entidad;

  factory HexCodigoLeyendaModel.fromJson(Map<String, dynamic> j) =>
      HexCodigoLeyendaModel(
        HexCodigoLeyendaEntity(
          concepto: hexTexto(j['concepto']),
          codigo: hexTexto(j['codigo']),
          leyenda: hexTexto(j['leyenda']),
          multiplicador: hexDecimalN(j['multiplicador']),
          valorUnitario: hexDecimalN(j['valorUnitario']),
        ),
      );

  factory HexCodigoLeyendaModel.fromEntity(HexCodigoLeyendaEntity e) =>
      HexCodigoLeyendaModel(e);

  HexCodigoLeyendaEntity toEntity() => entidad;
}
