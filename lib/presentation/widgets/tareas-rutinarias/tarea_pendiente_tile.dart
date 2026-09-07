// Destino final: lib/presentation/widgets/tareas-rutinarias/tarea_pendiente_tile.dart
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/domain/entities/bit_tarea_ruti_entity.dart';
import 'package:flutter/material.dart';

/// Traduce `idATR` a lo que la persona realmente ve: un ícono y una etiqueta
/// de acción, no el número interno. `fueRealizado` (12=pendiente,
/// 13=realizado, 14=no aplica) decide el color de estado — mismo semáforo
/// en toda la pantalla, para que "esto ya está" se lea sin leer el texto.
class TareaPendienteTile extends StatelessWidget {
  final BitTareaRutiEntity tarea;
  final VoidCallback onTap;

  const TareaPendienteTile({super.key, required this.tarea, required this.onTap});

  // null cuando la tarea no tiene un flujo especial — el caso más común
  // (confirmación simple SI/NO/N-A). Antes esto caía en un "Confirmar" con
  // ícono de tilde, que en una lista donde la mayoría de las tareas son de
  // este tipo repetía la misma etiqueta en cada fila (puro ruido) y encima
  // el tilde se leía como "ya está hecho", chocando con una etiqueta
  // "Vencida" al lado. Ahora el tipo solo se muestra cuando es información
  // real — un flujo especial — y el caso simple no ocupa un renglón.
  ({IconData icono, String etiqueta})? _tipoDeAccion() {
    switch (tarea.idATR) {
      case 2:
        return (icono: Icons.point_of_sale, etiqueta: 'Arqueo de caja');
      case 3:
        return (icono: Icons.fact_check_outlined, etiqueta: 'Cierre de operaciones');
      case 4:
        return (icono: Icons.lock_outlined, etiqueta: 'Kardex caja fuerte');
      case 5:
        return (icono: Icons.rule_folder_outlined, etiqueta: 'Verificar cierre');
      case 6:
        return (icono: Icons.directions_car_filled_outlined, etiqueta: 'Registrar coches');
      case 7:
        return (icono: Icons.savings_outlined, etiqueta: 'Caja chica');
      case 11:
        return (icono: Icons.currency_exchange, etiqueta: 'Traspaso de efectivo');
      default:
        return null;
    }
  }

  ({Color fondo, Color texto, String etiqueta}) _estado(BuildContext context) {
    switch (tarea.fueRealizado) {
      case 13:
        return (
          fondo: TareasColors.realizado(context),
          texto: TareasColors.realizadoTexto(context),
          etiqueta: 'Realizado',
        );
      case 14:
        return (
          fondo: TareasColors.noAplica(context),
          texto: TareasColors.noAplicaTexto(context),
          etiqueta: 'No aplica',
        );
      default:
        final vencida = tarea.fechaPresentacion != null &&
            tarea.fechaPresentacion!.isBefore(DateTime.now());
        return vencida
            ? (
                fondo: TareasColors.vencido(context),
                texto: TareasColors.vencidoTexto(context),
                etiqueta: 'Vencida',
              )
            : (
                fondo: TareasColors.pendiente(context),
                texto: TareasColors.pendienteTexto(context),
                etiqueta: 'Pendiente',
              );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tipo = _tipoDeAccion();
    final estado = _estado(context);
    final completada = tarea.fueRealizado == 13;

    // Ícono neutral (portapapeles) para la confirmación simple — no implica
    // "ya hecho" como el tilde anterior, y el color de estado ya se lee en
    // la franja izquierda y en la píldora, así que el ícono no necesita
    // cargar también ese significado.
    final icono = tipo?.icono ?? Icons.assignment_outlined;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Franja de estado: lo primero que el ojo agarra bajando por
              // la lista, antes incluso de leer la píldora de texto. Usa el
              // tono de TEXTO (más saturado que el fondo) para que la franja
              // se note incluso siendo angosta.
              Container(width: 4, color: estado.texto),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icono, color: scheme.onSecondaryContainer, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tarea.nombreTareaRutinaria ?? 'Tarea rutinaria',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: completada ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (tipo != null) ...[
                                  Icon(Icons.category_outlined, size: 13, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      tipo.etiqueta,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                if (tarea.fechaPresentacion != null) ...[
                                  Icon(Icons.event_outlined, size: 13, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${tarea.fechaPresentacion!.day.toString().padLeft(2, '0')}/'
                                    '${tarea.fechaPresentacion!.month.toString().padLeft(2, '0')}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: estado.fondo,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          estado.etiqueta,
                          style: TextStyle(color: estado.texto, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!completada) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: scheme.outline),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
