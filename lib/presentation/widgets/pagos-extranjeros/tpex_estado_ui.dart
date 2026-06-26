import 'package:flutter/material.dart';

/// Cifras tabulares + cero con barra: importes y números del módulo se leen
/// como un libro mayor (columnas que cuadran visualmente). Aplicar en el
/// `fontFeatures` de cualquier TextStyle que muestre dinero o cantidades.
const List<FontFeature> tpexTabularFigures = [
  FontFeature.tabularFigures(),
  FontFeature.slashedZero(),
];

/// ════════════════════════════════════════════════════════════════════════
/// Paleta y semántica ÚNICA de estados del módulo TPEX (pagos al exterior).
/// Todas las pantallas (lista, detalle, transacciones, cobranzas, gerencia,
/// timeline) delegan aquí para mantener colores e íconos consistentes.
///
///   Pendiente / Vigente  → naranja  (esperando)
///   Aprobada  / Aceptada → verde    (aprobado)
///   Procesado            → azul     (en curso)
///   Confirmado / Pagada  → teal     (finalizado)
///   Rechazada / Cancelada→ rojo     (negativo)
/// ════════════════════════════════════════════════════════════════════════

Color tpexEstadoColor(String estado) {
  switch (estado.toUpperCase().trim()) {
    case 'APROBADA':
    case 'APROBADO':
    case 'ACEPTADA':
    case 'ACEPTADO':
    case '1': // log de cuota: esAprobado = 1
      return Colors.green;
    // Aprobación parcial del proveedor: ámbar (entre pendiente y aprobado total).
    case 'APROBADO_PARCIAL':
    case 'APROBADO PARCIAL':
      return Colors.amber.shade800;
    case 'PROCESADO':
    case 'PROCESADA':
      return Colors.blue;
    case 'CONFIRMADO':
    case 'CONFIRMADA':
    case 'PAGADA':
    case 'PAGADO':
      return Colors.teal;
    case 'RECHAZADA':
    case 'RECHAZADO':
    case 'CANCELADO':
    case 'CANCELADA':
    case 'ANULADO':
    case 'ANULADA':
    case 'ERROR':
      return Colors.red;
    case 'ENVIADA':
    case 'ENVIADO':
      return Colors.indigo;
    case 'PENDIENTE':
    case 'VIGENTE':
    case '0': // log de cuota: esAprobado = 0 (no aprobada)
      return Colors.orange;
    default:
      return Colors.blueGrey;
  }
}

/// Etiqueta legible para un estado. Traduce los códigos crudos del log de
/// cuotas (`0`/`1`) y normaliza APROBADO_PARCIAL a texto con espacio. Para el
/// resto devuelve el estado en mayúsculas tal cual.
String tpexEstadoLabel(String estado) {
  switch (estado.toUpperCase().trim()) {
    case '0':
      return 'NO APROBADA';
    case '1':
      return 'APROBADA';
    case 'APROBADO_PARCIAL':
      return 'APROBADO PARCIAL';
    default:
      return estado.toUpperCase().trim();
  }
}

IconData tpexEstadoIcon(String estado) {
  switch (estado.toUpperCase().trim()) {
    case 'APROBADA':
    case 'APROBADO':
    case 'ACEPTADA':
    case 'ACEPTADO':
    case '1':
      return Icons.check_circle_rounded;
    case 'APROBADO_PARCIAL':
    case 'APROBADO PARCIAL':
      return Icons.donut_large_rounded; // anillo parcial = aprobación parcial
    case 'PROCESADO':
    case 'PROCESADA':
      return Icons.sync_rounded;
    case 'CONFIRMADO':
    case 'CONFIRMADA':
      return Icons.verified_rounded;
    case 'PAGADA':
    case 'PAGADO':
      return Icons.paid_rounded;
    case 'RECHAZADA':
    case 'RECHAZADO':
    case 'CANCELADO':
    case 'CANCELADA':
    case 'ANULADO':
    case 'ANULADA':
      return Icons.cancel_rounded;
    case 'PENDIENTE':
    case 'VIGENTE':
      return Icons.schedule_rounded;
    default:
      return Icons.label_outline_rounded;
  }
}

/// Badge de estado estándar (pill con ícono + texto). Estilo consistente para
/// todo el módulo. Si solo se necesita el color/ícono, usar las funciones.
class TpexEstadoBadge extends StatelessWidget {
  final String estado;
  final double fontSize;
  final bool dense;
  const TpexEstadoBadge({
    super.key,
    required this.estado,
    this.fontSize = 11,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = tpexEstadoColor(estado);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tpexEstadoIcon(estado), size: fontSize + 1, color: color),
          const SizedBox(width: 4),
          Text(
            tpexEstadoLabel(estado),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
