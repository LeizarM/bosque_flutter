import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';

/// Columnas de `p_list_ttk_BingoSorteo` L y T. `toJson` es el cuerpo de
/// `/bingo/sorteo/marcar` y `/bingo/sorteo/quitar`.
class TtkBingoSorteoModel {
  const TtkBingoSorteoModel(this.entidad);

  final TtkBingoSorteoEntity entidad;

  factory TtkBingoSorteoModel.fromJson(Map<String, dynamic> j) =>
      TtkBingoSorteoModel(
        TtkBingoSorteoEntity(
          codSorteo: ttkBigInt(j['codSorteo']),
          codBingo: ttkBigInt(j['codBingo']),
          nroJuego: ttkIntN(j['nroJuego']),
          nroBolillo: ttkInt(j['nroBolillo']),
          columna: ttkInt(j['columna']),
          letra: ttkTexto(j['letra']),
          etiqueta: ttkTexto(j['etiqueta']),
          marcado: ttkBool(j['marcado']),
          orden: ttkIntN(j['orden']),
          audFecha: ttkFecha(j['audFecha']),
        ),
      );

  factory TtkBingoSorteoModel.fromEntity(TtkBingoSorteoEntity e) =>
      TtkBingoSorteoModel(e);

  TtkBingoSorteoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codBingo': entidad.codBingo,
    'nroBolillo': entidad.nroBolillo,
  });

  /// La fila entera, como viaja dentro del `tablero` del estado en vivo.
  Map<String, dynamic> toJsonCompleto() => ttkCuerpo({
    'codSorteo': entidad.codSorteo,
    'codBingo': entidad.codBingo,
    'nroJuego': entidad.nroJuego,
    'nroBolillo': entidad.nroBolillo,
    'columna': entidad.columna,
    'letra': entidad.letra,
    'etiqueta': entidad.etiqueta,
    'marcado': ttkBandera(entidad.marcado),
    'orden': entidad.orden,
    'audFecha': ttkFechaJson(entidad.audFecha),
  });
}
