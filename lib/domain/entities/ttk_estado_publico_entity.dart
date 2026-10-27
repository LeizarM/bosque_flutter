import 'package:bosque_flutter/domain/entities/ttk_bingo_ganador_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';

/// Lo común a los estados en vivo: el cliente solo reemplaza el suyo cuando
/// llega uno con `version` mayor.
abstract interface class TtkEstadoVivo {
  int get version;
  TtkBingoPublicoEntity? get publico;
  List<TtkBingoSorteoEntity> get tablero;
}

/// Estado que ven los participantes: tablero, juego actual y los ganadores ya
/// confirmados (nombre y codEmpleado para la foto), sin ranking.
class TtkEstadoPublicoEntity implements TtkEstadoVivo {
  @override
  final int version;
  @override
  final TtkBingoPublicoEntity? publico;
  @override
  final List<TtkBingoSorteoEntity> tablero;
  final List<TtkBingoGanadorEntity> ganadores;

  const TtkEstadoPublicoEntity({
    this.version = 0,
    this.publico,
    this.tablero = const [],
    this.ganadores = const [],
  });
}
