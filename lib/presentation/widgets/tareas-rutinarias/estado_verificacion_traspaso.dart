// Destino final: lib/presentation/widgets/tareas-rutinarias/estado_verificacion_traspaso.dart
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:flutter/material.dart';

/// Cómo quedó un traspaso de Caja AXA, de solo lectura.
///
/// Lo muestra la revisión de Cierre de Operaciones: ahí no se marca. Marcelo
/// (2026-09-11), señalando esa sección: "esta parte es otra tarea que hace otra
/// persona, así que solo sería como revisado" — el cajero los marca en su
/// propia tarea, "Verificar traspaso Caja AXA" (295), y quien revisa el cierre
/// mira cómo quedaron y da la sección por revisada.
///
/// Tres estados y no un interruptor: uno apagado no distingue "no cuadra" de
/// "todavía nadie lo miró", y esa diferencia es justo lo que quiere ver quien
/// revisa el día. "No cuadra" usa el color de descuadre del arqueo: es un
/// estado, no una acción.
class EstadoVerificacionTraspaso extends StatelessWidget {
  /// 1 cuadra, 0 no cuadra, null todavía sin revisar.
  final int? valor;

  const EstadoVerificacionTraspaso({super.key, required this.valor});

  @override
  Widget build(BuildContext context) {
    final (IconData icono, String texto, Color fondo, Color color) =
        switch (valor) {
          1 => (
            Icons.check_circle,
            'Cuadra',
            TareasColors.cuadrado(context),
            TareasColors.cuadradoTexto(context),
          ),
          0 => (
            Icons.cancel,
            'No cuadra',
            TareasColors.descuadrado(context),
            TareasColors.descuadradoTexto(context),
          ),
          _ => (
            Icons.schedule,
            'Sin revisar',
            TareasColors.pendiente(context),
            TareasColors.pendienteTexto(context),
          ),
        };

    return Tooltip(
      message: 'Lo marca el cajero en "Verificar traspaso Caja AXA".',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(Esquina.pastilla),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 14, color: color),
              const SizedBox(width: Esp.xs),
              Text(
                texto,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: Peso.titulo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
