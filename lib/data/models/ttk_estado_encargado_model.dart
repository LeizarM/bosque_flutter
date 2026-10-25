import 'package:bosque_flutter/data/models/ttk_bingo_aviso_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_publico_model.dart';
import 'package:bosque_flutter/data/models/ttk_bingo_sorteo_model.dart';
import 'package:bosque_flutter/data/models/ttk_json.dart';
import 'package:bosque_flutter/data/models/ttk_ranking_carton_model.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_encargado_entity.dart';

/// `EstadoEncargado { version, publico, tablero, ranking, aviso, avisos }` del
/// POST y del tópico del encargado.
class TtkEstadoEncargadoModel {
  const TtkEstadoEncargadoModel(this.entidad);

  final TtkEstadoEncargadoEntity entidad;

  factory TtkEstadoEncargadoModel.fromJson(Map<String, dynamic> j) {
    final publico = j['publico'];
    return TtkEstadoEncargadoModel(
      TtkEstadoEncargadoEntity(
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
        ranking: [
          for (final f in ttkFilas(j['ranking']))
            TtkRankingCartonModel.fromJson(f).toEntity(),
        ],
        aviso: ttkTextoN(j['aviso']),
        avisos: [
          for (final f in ttkFilas(j['avisos']))
            TtkBingoAvisoModel.fromJson(f).toEntity(),
        ],
      ),
    );
  }

  factory TtkEstadoEncargadoModel.fromEntity(TtkEstadoEncargadoEntity e) =>
      TtkEstadoEncargadoModel(e);

  TtkEstadoEncargadoEntity toEntity() => entidad;

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
    'ranking': [
      for (final r in entidad.ranking)
        TtkRankingCartonModel.fromEntity(r).toJson(),
    ],
    'aviso': entidad.aviso,
    'avisos': [
      for (final a in entidad.avisos)
        TtkBingoAvisoModel.fromEntity(a).toJson(),
    ],
  });
}
