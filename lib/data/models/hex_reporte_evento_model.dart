import 'package:bosque_flutter/data/models/hex_json.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_evento_entity.dart';

/// Columnas de `p_list_thex_ReporteEvento` L. Solo lectura.
class HexReporteEventoModel {
  const HexReporteEventoModel(this.entidad);

  final HexReporteEventoEntity entidad;

  factory HexReporteEventoModel.fromJson(Map<String, dynamic> j) =>
      HexReporteEventoModel(
        HexReporteEventoEntity(
          idEvento: hexBigInt(j['idEvento']),
          tipo: hexTexto(j['tipo']),
          tipoTexto: hexTexto(j['tipoTexto']),
          codEmpleadoActor: hexBigInt(j['codEmpleadoActor']),
          nombreActor: hexTextoN(j['nombreActor']),
          valorAnterior: hexTextoN(j['valorAnterior']),
          valorNuevo: hexTextoN(j['valorNuevo']),
          observacion: hexTextoN(j['observacion']),
          fecha: hexFecha(j['fecha']),
        ),
      );

  factory HexReporteEventoModel.fromEntity(HexReporteEventoEntity e) =>
      HexReporteEventoModel(e);

  HexReporteEventoEntity toEntity() => entidad;
}
