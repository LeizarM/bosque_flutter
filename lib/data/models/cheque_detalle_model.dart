import 'package:bosque_flutter/data/models/accion_cheque_model.dart';
import 'package:bosque_flutter/data/models/botones_cheque_model.dart';
import 'package:bosque_flutter/data/models/cheque_fila_model.dart';
import 'package:bosque_flutter/domain/entities/botones_cheque_entity.dart';
import 'package:bosque_flutter/domain/entities/cheque_detalle_entity.dart';

/// ChequeDetalleDto del backend: `{ cheque, acciones, botones }`.
class ChequeDetalleModel {
  final ChequeFilaModel cheque;
  final List<AccionChequeModel> acciones;

  /// Null si el backend no lo manda; la entidad lo vuelve «todo deshabilitado».
  final BotonesChequeModel? botones;

  const ChequeDetalleModel({
    required this.cheque,
    required this.acciones,
    required this.botones,
  });

  factory ChequeDetalleModel.fromJson(Map<String, dynamic> json) =>
      ChequeDetalleModel(
        cheque: ChequeFilaModel.fromJson(
          json['cheque'] as Map<String, dynamic>,
        ),
        acciones: [
          for (final a in (json['acciones'] as List<dynamic>?) ?? const [])
            AccionChequeModel.fromJson(a as Map<String, dynamic>),
        ],
        botones:
            json['botones'] == null
                ? null
                : BotonesChequeModel.fromJson(
                  json['botones'] as Map<String, dynamic>,
                ),
      );

  Map<String, dynamic> toJson() => {
    'cheque': cheque.toJson(),
    'acciones': [for (final a in acciones) a.toJson()],
    'botones': botones?.toJson(),
  };

  ChequeDetalleEntity toEntity() => ChequeDetalleEntity(
    cheque: cheque.toEntity(),
    acciones: [for (final a in acciones) a.toEntity()],
    botones: botones?.toEntity() ?? BotonesChequeEntity.ninguno,
  );

  factory ChequeDetalleModel.fromEntity(ChequeDetalleEntity e) =>
      ChequeDetalleModel(
        cheque: ChequeFilaModel.fromEntity(e.cheque),
        acciones: [for (final a in e.acciones) AccionChequeModel.fromEntity(a)],
        botones: BotonesChequeModel.fromEntity(e.botones),
      );
}
