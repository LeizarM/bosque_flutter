/// El marco de las pantallas públicas del postulante: sin menú ni datos del
/// empleado, solo una franja con el nombre del sistema y el contenido.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';

class MarcoPublicoExamen extends StatelessWidget {
  const MarcoPublicoExamen({super.key, required this.child, this.acciones = const [], this.centrado = true});

  final Widget child;
  final List<Widget> acciones;

  /// Contenido angosto y centrado (formularios) o a todo el ancho (rendición).
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: Esp.l),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: cs.primary),
                  const SizedBox(width: Esp.s),
                  Text(
                    'Evaluaciones',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: Peso.titulo),
                  ),
                  const Spacer(),
                  ...acciones,
                ],
              ),
            ),
            Expanded(
              child:
                  centrado
                      ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(Esp.l),
                          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: child),
                        ),
                      )
                      : child,
            ),
          ],
        ),
      ),
    );
  }
}

/// La tarjeta de un formulario público.
class TarjetaPublica extends StatelessWidget {
  const TarjetaPublica({super.key, required this.children, this.icono});

  final List<Widget> children;

  /// El sello arriba del contenido, en el color del tema.
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // La franja de color arriba, como el encabezado impreso de una hoja de examen.
    return Card(
      elevation: 0,
      color: cs.surface,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 6, color: cs.primary),
          Padding(
            padding: const EdgeInsets.all(Esp.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[
                  Align(alignment: Alignment.centerLeft, child: SelloExamen(icono: icono!, tamanio: 48)),
                  const SizedBox(height: Esp.l),
                ],
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
