import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/data/models/cbr_detalle_model.dart';
import 'package:bosque_flutter/domain/entities/garantia_registro_entity.dart';

/// Cuerpo de `/garantias/registrar`. Solo de ida: el backend responde el id.
///
/// montoGarantiaCalc no viaja: lo calcula el backend sumando los detalles.
class GarantiaRegistroModel {
  final GarantiaRegistroEntity registro;

  const GarantiaRegistroModel._(this.registro);

  factory GarantiaRegistroModel.fromEntity(GarantiaRegistroEntity e) =>
      GarantiaRegistroModel._(e);

  Map<String, dynamic> toJson() {
    final r = registro;
    return {
      'codGarantia': r.codGarantia.toInt(),
      'codClienteSAP': r.codClienteSAP,
      'montoGarantia': r.montoGarantia,
      'montoCredito': r.montoCredito,
      'tiempoPago': r.tiempoPago,
      'fechaInicio':
          r.fechaInicio == null ? null : fechaParaSql(r.fechaInicio!),
      'fechaExpiracion':
          r.fechaExpiracion == null ? null : fechaParaSql(r.fechaExpiracion!),
      'recFirmas': _vacioANull(r.recFirmas),
      'nroProtesta': _vacioANull(r.nroProtesta),
      'observacion': _vacioANull(r.observacion),
      'detalles':
          r.detalles
              .map((d) => CbrDetalleModel.fromEntity(d).toJson())
              .toList(),
    };
  }

  static String? _vacioANull(String? t) =>
      (t == null || t.trim().isEmpty) ? null : t.trim();
}
