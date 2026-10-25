import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_publico_entity.dart';

/// Columnas de `p_list_ttk_Bingo` P (estado público, sin ganadores).
class TtkBingoPublicoModel {
  const TtkBingoPublicoModel(this.entidad);

  final TtkBingoPublicoEntity entidad;

  factory TtkBingoPublicoModel.fromJson(Map<String, dynamic> j) =>
      TtkBingoPublicoModel(
        TtkBingoPublicoEntity(
          codBingo: ttkBigInt(j['codBingo']),
          nombreEvento: ttkTexto(j['nombreEvento']),
          estado: ttkTexto(j['estado']),
          estadoTexto: ttkTexto(j['estadoTexto']),
          nroBolillos: ttkInt(j['nroBolillos']),
          filas: ttkInt(j['filas']),
          columnas: ttkInt(j['columnas']),
          letras: ttkTextoN(j['letras']),
          conComodin: ttkBool(j['conComodin']),
          nroJuegos: ttkInt(j['nroJuegos']),
          nroJuego: ttkIntN(j['nroJuego']),
          nombreJuego: ttkTextoN(j['nombreJuego']),
          figura: ttkTextoN(j['figura']),
          estadoJuego: ttkTextoN(j['estadoJuego']),
          totalMarcados: ttkInt(j['totalMarcados']),
          ultimoBolillo: ttkIntN(j['ultimoBolillo']),
          hayGanador: ttkBool(j['hayGanador']),
          puedeAvisar: ttkBool(j['puedeAvisar']),
          mensaje: ttkTexto(j['mensaje']),
        ),
      );

  factory TtkBingoPublicoModel.fromEntity(TtkBingoPublicoEntity e) =>
      TtkBingoPublicoModel(e);

  TtkBingoPublicoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codBingo': entidad.codBingo,
    'nombreEvento': entidad.nombreEvento,
    'estado': entidad.estado,
    'estadoTexto': entidad.estadoTexto,
    'nroBolillos': entidad.nroBolillos,
    'filas': entidad.filas,
    'columnas': entidad.columnas,
    'letras': entidad.letras,
    'conComodin': ttkBandera(entidad.conComodin),
    'nroJuegos': entidad.nroJuegos,
    'nroJuego': entidad.nroJuego,
    'nombreJuego': entidad.nombreJuego,
    'figura': entidad.figura,
    'estadoJuego': entidad.estadoJuego,
    'totalMarcados': entidad.totalMarcados,
    'ultimoBolillo': entidad.ultimoBolillo,
    'hayGanador': ttkBandera(entidad.hayGanador),
    'puedeAvisar': ttkBandera(entidad.puedeAvisar),
    'mensaje': entidad.mensaje,
  });
}
