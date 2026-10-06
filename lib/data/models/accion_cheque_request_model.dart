import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/accion_cheque_request_entity.dart';

/// Cuerpo de las acciones del detalle. Solo de ida: el backend responde el
/// `codAccion`.
///
/// Las fechas van como `yyyy-MM-dd`: el servidor completa la hora. El campo es
/// `nroSap` (el de la tabla, `nroSAP`, es otro objeto).
class AccionChequeRequestModel {
  final AccionChequeRequestEntity accion;

  const AccionChequeRequestModel._(this.accion);

  factory AccionChequeRequestModel.fromEntity(AccionChequeRequestEntity e) =>
      AccionChequeRequestModel._(e);

  Map<String, dynamic> toJson() {
    final a = accion;
    final m = <String, dynamic>{
      'codCheque': a.codCheque.toInt(),
      'fecha': a.fecha == null ? null : fechaParaSql(a.fecha!),
      'estado': _texto(a.estado),
      'nroSap': _texto(a.nroSap),
      'observacion': _texto(a.observacion),
      'conVerificacion': a.conVerificacion,
      'nuevaFechaCobro':
          a.nuevaFechaCobro == null ? null : fechaParaSql(a.nuevaFechaCobro!),
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }

  static String? _texto(String? t) =>
      (t == null || t.trim().isEmpty) ? null : t.trim();
}
