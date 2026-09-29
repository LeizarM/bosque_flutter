/// Una fila por cliente con garantias: la grilla principal del modulo
/// (GarantiaResumenClienteDto de `/garantias/resumen-clientes`).
///
/// Los montos suman SOLO las garantias vigentes; [cantGarantias] cuenta todas.
class GarantiaResumenClienteEntity {
  final String codClienteSAP;
  final String datoCliente;
  final int cantGarantias;
  final int cantVigentes;

  /// Suma de las garantias vigentes.
  final double montoGarantia;

  /// Suma de las lineas aprobadas de las garantias vigentes.
  final double montoCredito;

  /// Vencimiento mas cercano entre las vigentes. Null si no tiene vigentes.
  final DateTime? proximoVencimiento;
  final int? diasParaVencer;

  /// Linea de credito y saldo en SAP, sumados entre las empresas del cliente.
  final double creditLine;
  final double balance;

  const GarantiaResumenClienteEntity({
    required this.codClienteSAP,
    required this.datoCliente,
    required this.cantGarantias,
    required this.cantVigentes,
    required this.montoGarantia,
    required this.montoCredito,
    required this.proximoVencimiento,
    required this.diasParaVencer,
    required this.creditLine,
    required this.balance,
  });

  /// La linea aprobada por garantias no coincide con la linea de SAP. Es la
  /// fila que el legacy pintaba de rojo.
  bool get difiereDeSap => (montoCredito - creditLine).abs() >= 0.005;

  /// Su proxima garantia vence en 30 dias o menos.
  bool get porVencer => diasParaVencer != null && diasParaVencer! <= 30;

  bool get sinVigentes => cantVigentes == 0;

  bool coincideCon(String texto) {
    final t = texto.trim().toLowerCase();
    if (t.isEmpty) return true;
    return codClienteSAP.toLowerCase().contains(t) ||
        datoCliente.toLowerCase().contains(t);
  }
}
