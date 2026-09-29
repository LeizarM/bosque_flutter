import 'package:bosque_flutter/domain/entities/cbr_detalle_entity.dart';

/// Lo que se manda a `/garantias/registrar` (GarantiaRegistro del contrato).
///
/// Con [codGarantia] en cero es un ALTA: crea la garantia, su accion REG con
/// [observacion] y los [detalles], en una sola transaccion.
///
/// Con [codGarantia] mayor a cero es la EDICION del legacy: solo cambian
/// [recFirmas] y [nroProtesta] y se agregan los [detalles] nuevos. Montos,
/// fechas y cliente no cambian por aca (eso es la edicion administrativa).
class GarantiaRegistroEntity {
  final BigInt codGarantia;
  final String codClienteSAP;
  final double montoGarantia;
  final double montoCredito;
  final int tiempoPago;
  final DateTime? fechaInicio;
  final DateTime? fechaExpiracion;
  final String? recFirmas;
  final String? nroProtesta;
  final String? observacion;
  final List<CbrDetalleEntity> detalles;

  const GarantiaRegistroEntity({
    required this.codGarantia,
    required this.codClienteSAP,
    required this.montoGarantia,
    required this.montoCredito,
    required this.tiempoPago,
    required this.fechaInicio,
    required this.fechaExpiracion,
    required this.recFirmas,
    required this.nroProtesta,
    required this.observacion,
    required this.detalles,
  });

  bool get esAlta => codGarantia == BigInt.zero;

  double get sumaDetalles => detalles.fold(0.0, (s, d) => s + d.monto);
}
