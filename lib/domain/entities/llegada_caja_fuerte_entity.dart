// Destino final: lib/domain/entities/llegada_caja_fuerte_entity.dart

/// Una fila del formulario "Reportar dinero para caja fuerte" (idATR=4).
/// Puramente local hasta el submit — no se lista desde el backend, se arma
/// en la pantalla y se manda entera de una.
class LlegadaCajaFuerteEntity {
  final String id; // clave local (UniqueKey.toString()), no de la BD
  final String cliente;
  final String moneda; // 'BS' | 'USD'
  final double? importe;
  // 'chq' | 'efect' — EXACTAMENTE los valores reales del legacy (Tareas.xhtml),
  // no 'CHEQUE'/'EFECTIVO': ambos sistemas escriben la misma columna
  // tac_llegada.tipo, así que un valor distinto sería un dato inconsistente
  // para cualquier reporte/consulta legacy que filtre por tipo. Obligatorio
  // para poder enviar.
  final String? tipo;
  final String destino;
  final String obs;

  const LlegadaCajaFuerteEntity({
    required this.id,
    this.cliente = '',
    this.moneda = 'BS',
    this.importe,
    this.tipo,
    this.destino = '',
    this.obs = '',
  });

  bool get esValida => cliente.trim().isNotEmpty && (importe ?? 0) > 0 && tipo != null;

  LlegadaCajaFuerteEntity copyWith({
    String? cliente,
    String? moneda,
    double? importe,
    String? tipo,
    String? destino,
    String? obs,
  }) {
    return LlegadaCajaFuerteEntity(
      id: id,
      cliente: cliente ?? this.cliente,
      moneda: moneda ?? this.moneda,
      importe: importe ?? this.importe,
      tipo: tipo ?? this.tipo,
      destino: destino ?? this.destino,
      obs: obs ?? this.obs,
    );
  }
}
