import 'package:bosque_flutter/domain/entities/garantia_cbr_entity.dart';

/// Una garantia con lo que el backend calcula o resuelve por JOIN
/// (GarantiaDto de `/garantias/listar` y `/garantias/obtener`).
///
/// Envuelve a [GarantiaCbrEntity] en vez de repetir sus campos: la fila de la
/// tabla sigue siendo una sola, y lo que se edita y se manda de vuelta es
/// siempre [garantia].
class GarantiaVistaEntity {
  static const String vigente = 'VIGENTE';
  static const String caducado = 'CADUCADO';
  static const String cerrado = 'CERRADO';

  final GarantiaCbrEntity garantia;

  /// Nombre del cliente en SAP.
  final String datoCliente;

  /// VIGENTE / CADUCADO / CERRADO. Calculado: no se guarda en ninguna tabla.
  final String datoEstado;

  /// Dias hasta la fecha de expiracion; negativo si ya vencio.
  final int? diasParaVencer;

  /// Linea de credito en SAP, sumada entre las empresas del cliente.
  final double creditLine;

  /// Saldo en SAP, sumado entre las empresas del cliente.
  final double balance;

  /// Ya tiene su accion TRASP. Sin traspaso no se puede cerrar ni extender.
  final bool traspasada;

  final int cantDetalles;

  /// Tipos de sus detalles, en texto (por ejemplo «PAGARE, INMUEBLE»).
  final String? tiposGarantia;

  /// Fecha y observacion de la accion REG, que es el registro original.
  final DateTime? fechaRegistro;
  final String? observacionRegistro;

  /// Quien la registro.
  final String? realizoEmp;

  const GarantiaVistaEntity({
    required this.garantia,
    required this.datoCliente,
    required this.datoEstado,
    required this.diasParaVencer,
    required this.creditLine,
    required this.balance,
    required this.traspasada,
    required this.cantDetalles,
    required this.tiposGarantia,
    required this.fechaRegistro,
    required this.observacionRegistro,
    required this.realizoEmp,
  });

  BigInt get codGarantia => garantia.codGarantia;

  bool get estaCerrada => datoEstado == cerrado;
  bool get estaVigente => datoEstado == vigente;
  bool get estaCaducada => datoEstado == caducado;

  /// Se puede escribir sobre ella. El legacy ocultaba todos los botones de
  /// escritura de una garantia cerrada, y el backend ahora tambien lo valida.
  bool get admiteCambios => !estaCerrada;

  /// Vigente y a 30 dias o menos de vencer: el aviso que daba el legacy.
  bool get porVencer =>
      estaVigente && diasParaVencer != null && diasParaVencer! <= 30;

  /// La linea aprobada contra la garantia no coincide con la de SAP.
  bool get difiereDeSap => (garantia.montoCredito - creditLine).abs() >= 0.005;

  /// Cuanto del plazo ya paso, de 0 a 1. Null si faltan fechas.
  double? get fraccionTranscurrida {
    final ini = garantia.fechaInicio;
    final fin = garantia.fechaExpiracion;
    if (ini == null || fin == null) return null;
    final total = fin.difference(ini).inDays;
    if (total <= 0) return 1;
    final hoy = DateTime.now();
    final pasados =
        DateTime(hoy.year, hoy.month, hoy.day).difference(ini).inDays;
    return (pasados / total).clamp(0.0, 1.0);
  }

  /// Texto para buscar en la lista del cliente.
  bool coincideCon(String texto) {
    final t = texto.trim().toLowerCase();
    if (t.isEmpty) return true;
    return codGarantia.toString().contains(t) ||
        (tiposGarantia ?? '').toLowerCase().contains(t) ||
        (garantia.recFirmas ?? '').toLowerCase().contains(t) ||
        (garantia.nroProtesta ?? '').toLowerCase().contains(t) ||
        datoEstado.toLowerCase().contains(t);
  }
}
