import 'package:bosque_flutter/data/models/ttk_bingo_publico_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_sorteo_model.dart';
import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';

/// `EstadoPublico { version, publico, tablero }` del POST y del tópico público.
class TtkEstadoPublicoModel {
  const TtkEstadoPublicoModel(this.entidad);

  final TtkEstadoPublicoEntity entidad;

  factory TtkEstadoPublicoModel.fromJson(Map<String, dynamic> j) {
    final publico = j['publico'];
    return TtkEstadoPublicoModel(
      TtkEstadoPublicoEntity(
        version: ttkInt(j['version']),
        publico:
            publico is Map
                ? TtkBingoPublicoModel.fromJson(
                  Map<String, dynamic>.from(publico),
                ).toEntity()
                : null,
        tablero: [
          for (final f in ttkFilas(j['tablero']))
            TtkBingoSorteoModel.fromJson(f).toEntity(),
        ],
      ),
    );
  }

  factory TtkEstadoPublicoModel.fromEntity(TtkEstadoPublicoEntity e) =>
      TtkEstadoPublicoModel(e);

  TtkEstadoPublicoEntity toEntity() => entidad;

  Map<String, dynamic> toJson() => ttkCuerpo({
    'version': entidad.version,
    'publico':
        entidad.publico == null
            ? null
            : TtkBingoPublicoModel.fromEntity(entidad.publico!).toJson(),
    'tablero': [
      for (final t in entidad.tablero)
        TtkBingoSorteoModel.fromEntity(t).toJsonCompleto(),
    ],
  });
}
