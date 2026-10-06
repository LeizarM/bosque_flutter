import 'package:bosque_flutter/core/utils/formato_moneda.dart';

/// Lo que la pantalla «Verificar Cheques» muestra del **cheque** de cada fila,
/// tanto en la lista de verificaciones como en la de cheques pendientes. Lo trae
/// el backend resuelto por JOIN (`p_list_VerificacionDeposito`); no es una tabla.
///
/// Lo que el procedimiento no trae es la moneda: la completa el servicio para
/// las filas de la pagina. Si no la encuentra, [moneda] y [descMoneda] son null
/// y el importe se muestra sin unidad, como en el legacy.
class DatosChequeVerificacionEntity {
  final BigInt codCheque;

  /// Texto, no numero: hay cheques con `?` o guion en el numero.
  final String nroCheque;

  final double? montoCheque;

  /// El banco del cheque (no el de la verificacion).
  final String datoBancoCheque;

  /// «PENDIENTE» o «CERRADO», tal como lo escribe el procedimiento.
  final String datoEstadoCheque;

  /// La fecha de cobranza del cheque.
  final DateTime? fechaCobrarCheque;

  /// El cheque esta cerrado: no se puede registrar una verificacion nueva.
  final bool chequeCerrado;

  /// `BS` o `SUS`; null si el servidor no la pudo completar.
  final String? moneda;

  /// «Bs» o «$us»; null igual que [moneda].
  final String? descMoneda;

  const DatosChequeVerificacionEntity({
    required this.codCheque,
    required this.nroCheque,
    required this.montoCheque,
    required this.datoBancoCheque,
    required this.datoEstadoCheque,
    required this.fechaCobrarCheque,
    required this.chequeCerrado,
    required this.moneda,
    required this.descMoneda,
  });

  /// «Bs», «$us», el codigo tal cual si es otra, o vacio si no se conoce.
  String get unidadMoneda {
    final desc = (descMoneda ?? '').trim();
    return FormatoMoneda.unidad(desc.isNotEmpty ? desc : moneda);
  }
}
