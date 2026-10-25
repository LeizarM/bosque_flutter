import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_aviso_entity.dart';

/// Columnas de `p_list_ttk_BingoAviso` L (llegan en `EstadoEncargado.avisos`).
class TtkBingoAvisoModel {
  const TtkBingoAvisoModel(this.entidad);

  final TtkBingoAvisoEntity entidad;

  factory TtkBingoAvisoModel.fromJson(Map<String, dynamic> j) =>
      TtkBingoAvisoModel(
        TtkBingoAvisoEntity(
          codAviso: ttkBigInt(j['codAviso']),
          codBingo: ttkBigInt(j['codBingo']),
          codJuego: ttkBigInt(j['codJuego']),
          nroJuego: ttkInt(j['nroJuego']),
          codCarton: ttkBigInt(j['codCarton']),
          nroCarton: ttkInt(j['nroCarton']),
          nombreEmpleado: ttkTextoN(j['nombreEmpleado']),
          impreso: ttkBool(j['impreso']),
          estado: ttkTextoN(j['estado']) ?? 'P',
          fechaAviso: ttkFecha(j['fechaAviso']),
          mensaje: ttkTexto(j['mensaje']),
          audUsuario: ttkBigInt(j['audUsuario']),
          audFecha: ttkFecha(j['audFecha']),
        ),
      );

  factory TtkBingoAvisoModel.fromEntity(TtkBingoAvisoEntity e) =>
      TtkBingoAvisoModel(e);

  TtkBingoAvisoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'codAviso': entidad.codAviso,
    'codBingo': entidad.codBingo,
    'codJuego': entidad.codJuego,
    'nroJuego': entidad.nroJuego,
    'codCarton': entidad.codCarton,
    'nroCarton': entidad.nroCarton,
    'nombreEmpleado': entidad.nombreEmpleado,
    'impreso': ttkBandera(entidad.impreso),
    'estado': entidad.estado,
    'fechaAviso': ttkFechaJson(entidad.fechaAviso),
    'mensaje': entidad.mensaje,
  });
}
