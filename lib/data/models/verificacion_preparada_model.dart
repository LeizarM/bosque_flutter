import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/cheque_pendiente_verificacion_model.dart';
import 'package:bosque_flutter/domain/entities/verificacion_preparada_entity.dart';

/// `data` de `/cheque/verificacion/preparar`: `{ cheque, fechaBanco }`.
class VerificacionPreparadaModel {
  final ChequePendienteVerificacionModel cheque;
  final DateTime fechaBanco;

  const VerificacionPreparadaModel({
    required this.cheque,
    required this.fechaBanco,
  });

  factory VerificacionPreparadaModel.fromJson(Map<String, dynamic> json) {
    final hoy = DateTime.now();
    return VerificacionPreparadaModel(
      cheque: ChequePendienteVerificacionModel.fromJson(
        (json['cheque'] as Map<String, dynamic>?) ?? const {},
      ),
      // Si por algun motivo no llega, se propone el dia del dispositivo: el
      // servidor igual valida la fecha al guardar.
      fechaBanco:
          soloFecha(json['fechaBanco']) ??
          DateTime(hoy.year, hoy.month, hoy.day),
    );
  }

  Map<String, dynamic> toJson() => {
    'cheque': cheque.toJson(),
    'fechaBanco': fechaParaSql(fechaBanco),
  };

  VerificacionPreparadaEntity toEntity() => VerificacionPreparadaEntity(
    cheque: cheque.toEntity(),
    fechaBanco: fechaBanco,
  );

  factory VerificacionPreparadaModel.fromEntity(
    VerificacionPreparadaEntity e,
  ) => VerificacionPreparadaModel(
    cheque: ChequePendienteVerificacionModel.fromEntity(e.cheque),
    fechaBanco: e.fechaBanco,
  );
}
