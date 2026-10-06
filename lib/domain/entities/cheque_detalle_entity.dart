import 'package:bosque_flutter/domain/entities/accion_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_fila_entity.dart';

/// «Completar»: el cheque, su historial y las cuatro acciones habilitadas, del
/// mismo instante (`/cheque/detalle`).
class ChequeDetalleEntity {
  final ChequeFilaEntity cheque;

  /// Historial en el orden del backend (por fecha), numerado con `nro`.
  final List<AccionChequeEntity> acciones;

  final BotonesChequeEntity botones;

  const ChequeDetalleEntity({
    required this.cheque,
    required this.acciones,
    required this.botones,
  });
}
