import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_ganador_entity.dart';

/// Columnas de `p_list_ttk_BingoGanador` L. `toJson` es el cuerpo de
/// `/bingo/ganador/confirmar` (bingo y número de cartón).
class TtkBingoGanadorModel {
  const TtkBingoGanadorModel(this.entidad);

  final TtkBingoGanadorEntity entidad;

  factory TtkBingoGanadorModel.fromJson(Map<String, dynamic> j) =>
      TtkBingoGanadorModel(
        TtkBingoGanadorEntity(
          codGanador: ttkBigInt(j['codGanador']),
          codJuego: ttkBigInt(j['codJuego']),
          codBingo: ttkBigInt(j['codBingo']),
          nroJuego: ttkInt(j['nroJuego']),
          nombreJuego: ttkTexto(j['nombreJuego']),
          codCarton: ttkBigInt(j['codCarton']),
          nroCarton: ttkInt(j['nroCarton']),
          codEmpleado: ttkBigInt(j['codEmpleado']),
          nombreEmpleado: ttkTextoN(j['nombreEmpleado']),
          ordenBolillo: ttkIntN(j['ordenBolillo']),
          nroBolillo: ttkIntN(j['nroBolillo']),
          puedeAnular: ttkBool(j['puedeAnular']),
          audUsuario: ttkBigInt(j['audUsuario']),
          audFecha: ttkFecha(j['audFecha']),
        ),
      );

  factory TtkBingoGanadorModel.fromEntity(TtkBingoGanadorEntity e) =>
      TtkBingoGanadorModel(e);

  TtkBingoGanadorEntity toEntity() => entidad;

  Map<String, dynamic> toJson() =>
      ttkCuerpo({'codBingo': entidad.codBingo, 'nroCarton': entidad.nroCarton});
}
