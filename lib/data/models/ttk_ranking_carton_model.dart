import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_ranking_carton_entity.dart';

/// Columnas de `p_list_ttk_BingoCarton` R y V.
class TtkRankingCartonModel {
  const TtkRankingCartonModel(this.entidad);

  final TtkRankingCartonEntity entidad;

  factory TtkRankingCartonModel.fromJson(Map<String, dynamic> j) =>
      TtkRankingCartonModel(
        TtkRankingCartonEntity(
          codCarton: ttkBigInt(j['codCarton']),
          nroCarton: ttkInt(j['nroCarton']),
          codEmpleado: ttkBigInt(j['codEmpleado']),
          nombreEmpleado: ttkTextoN(j['nombreEmpleado']),
          nroJuego: ttkIntN(j['nroJuego']),
          aciertos: ttkInt(j['aciertos']),
          totalFigura: ttkInt(j['totalFigura']),
          faltantes: ttkInt(j['faltantes']),
          esBingo: ttkBool(j['esBingo']),
          ordenBingo: ttkIntN(j['ordenBingo']),
          bolilloBingo: ttkIntN(j['bolilloBingo']),
          esNuevo: ttkBool(j['esNuevo']),
          esGanadorConfirmado: ttkBool(j['esGanadorConfirmado']),
          puesto: ttkInt(j['puesto']),
          impreso: ttkBool(j['impreso']),
          mensaje: ttkTexto(j['mensaje']),
        ),
      );

  factory TtkRankingCartonModel.fromEntity(TtkRankingCartonEntity e) =>
      TtkRankingCartonModel(e);

  TtkRankingCartonEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codCarton': entidad.codCarton,
    'nroCarton': entidad.nroCarton,
    'codEmpleado': entidad.codEmpleado,
    'nombreEmpleado': entidad.nombreEmpleado,
    'nroJuego': entidad.nroJuego,
    'aciertos': entidad.aciertos,
    'totalFigura': entidad.totalFigura,
    'faltantes': entidad.faltantes,
    'esBingo': ttkBandera(entidad.esBingo),
    'ordenBingo': entidad.ordenBingo,
    'bolilloBingo': entidad.bolilloBingo,
    'esNuevo': ttkBandera(entidad.esNuevo),
    'esGanadorConfirmado': ttkBandera(entidad.esGanadorConfirmado),
    'puesto': entidad.puesto,
    'impreso': ttkBandera(entidad.impreso),
    'mensaje': entidad.mensaje,
  });
}
