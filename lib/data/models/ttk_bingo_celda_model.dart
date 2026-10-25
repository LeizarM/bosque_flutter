import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';

/// Columnas de `p_list_ttk_BingoCelda` C, E, M y P (solo lectura).
class TtkBingoCeldaModel {
  const TtkBingoCeldaModel(this.entidad);

  final TtkBingoCeldaEntity entidad;

  factory TtkBingoCeldaModel.fromJson(Map<String, dynamic> j) =>
      TtkBingoCeldaModel(
        TtkBingoCeldaEntity(
          codCarton: ttkBigInt(j['codCarton']),
          codBingo: ttkBigInt(j['codBingo']),
          nroCarton: ttkInt(j['nroCarton']),
          codEmpleado: ttkBigInt(j['codEmpleado']),
          nombreEmpleado: ttkTextoN(j['nombreEmpleado']),
          nroJuego: ttkInt(j['nroJuego']),
          nombreJuego: ttkTexto(j['nombreJuego']),
          posicion: ttkInt(j['posicion']),
          fila: ttkInt(j['fila']),
          columna: ttkInt(j['columna']),
          numero: ttkInt(j['numero']),
          esComodin: ttkBool(j['esComodin']),
          enFigura: ttkBool(j['enFigura']),
          marcado: ttkBool(j['marcado']),
        ),
      );

  factory TtkBingoCeldaModel.fromEntity(TtkBingoCeldaEntity e) =>
      TtkBingoCeldaModel(e);

  TtkBingoCeldaEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codCarton': entidad.codCarton,
    'codBingo': entidad.codBingo,
    'nroCarton': entidad.nroCarton,
    'codEmpleado': entidad.codEmpleado,
    'nombreEmpleado': entidad.nombreEmpleado,
    'nroJuego': entidad.nroJuego,
    'nombreJuego': entidad.nombreJuego,
    'posicion': entidad.posicion,
    'fila': entidad.fila,
    'columna': entidad.columna,
    'numero': entidad.numero,
    'esComodin': ttkBandera(entidad.esComodin),
    'enFigura': ttkBandera(entidad.enFigura),
    'marcado': ttkBandera(entidad.marcado),
  });
}
