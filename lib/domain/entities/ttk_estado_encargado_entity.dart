import 'package:bosque_flutter/domain/entities/ttk_bingo_aviso_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_ranking_carton_entity.dart';

/// Estado del panel del encargado: lo público más el ranking, el aviso del
/// último cambio y los «¡Bingo!» pendientes de los participantes.
class TtkEstadoEncargadoEntity implements TtkEstadoVivo {
  @override
  final int version;
  @override
  final TtkBingoPublicoEntity? publico;
  @override
  final List<TtkBingoSorteoEntity> tablero;
  final List<TtkRankingCartonEntity> ranking;
  final String? aviso;
  final List<TtkBingoAvisoEntity> avisos;

  const TtkEstadoEncargadoEntity({
    this.version = 0,
    this.publico,
    this.tablero = const [],
    this.ranking = const [],
    this.aviso,
    this.avisos = const [],
  });

  /// Cartones que completaron la figura con el último bolillo.
  List<TtkRankingCartonEntity> get bingosNuevos =>
      ranking.where((r) => r.esNuevo).toList();
}
