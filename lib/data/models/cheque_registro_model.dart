import 'package:bosque_flutter/core/utils/fecha_sql.dart';
import 'package:bosque_flutter/domain/entities/cheque_registro_entity.dart';

/// Cuerpo de `/cheque/registrar`. Solo de ida: el backend responde el id.
///
/// No manda `estado`, `nroRecibo`, `audUsuario` ni `audFecha`: los pone el
/// servidor. Las fechas van como `yyyy-MM-dd`. Las claves sin valor no viajan.
class ChequeRegistroModel {
  final ChequeRegistroEntity registro;

  const ChequeRegistroModel._(this.registro);

  factory ChequeRegistroModel.fromEntity(ChequeRegistroEntity e) =>
      ChequeRegistroModel._(e);

  Map<String, dynamic> toJson() {
    final r = registro;
    final m = <String, dynamic>{
      'codCheque': r.codCheque.toInt(),
      'modo': r.modo.codigo,
      'nrocheque': _texto(r.nrocheque),
      'codCliente': _texto(r.codCliente),
      'aOrdenDe': _texto(r.aOrdenDe),
      'fechaCheque':
          r.fechaCheque == null ? null : fechaParaSql(r.fechaCheque!),
      'fechaCobrar':
          r.fechaCobrar == null ? null : fechaParaSql(r.fechaCobrar!),
      'monto': r.monto,
      'moneda': _texto(r.moneda),
      'tipo': _texto(r.tipo),
      'codBanco': r.codBanco,
      'codEmpleado': r.codEmpleado,
      'reciboManual': _texto(r.reciboManual),
      'codSucursal': r.codSucursal,
      'nroTalonario': _texto(r.nroTalonario),
      'codEmpresa': r.codEmpresa,
      'observacion': _observacion(r),
    };
    m.removeWhere((_, v) => v == null);
    return m;
  }

  static String? _texto(String? t) =>
      (t == null || t.trim().isEmpty) ? null : t.trim();

  /// En una edicion la observacion vacia viaja como `""` para **borrarla**: el
  /// servidor conserva la anterior ante `null`. En el alta, vacia no viaja.
  static String? _observacion(ChequeRegistroEntity r) {
    final t = r.observacion?.trim();
    if (t == null) return null;
    if (t.isEmpty) return r.esAlta ? null : '';
    return t;
  }
}
