// Destino final: lib/presentation/widgets/tareas-rutinarias/dependiente_cargo_tile.dart
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/domain/entities/dependiente_cargo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Una fila seleccionable de la lista de dependientes. El color de fondo del
/// número de nivel se atenúa con la profundidad (más lejos del jefe = más
/// tenue), para que "cerca de mí" se lea de un vistazo sin tener que leer
/// el número.
class DependienteCargoTile extends StatelessWidget {
  final DependienteCargoEntity dependiente;
  final bool seleccionado;
  final VoidCallback onTap;

  const DependienteCargoTile({
    super.key,
    required this.dependiente,
    required this.seleccionado,
    required this.onTap,
  });

  /// Un solo haptic por selección/deselección, en el frame del toque — nunca
  /// en un listener de animación.
  void _alTocar() {
    HapticFeedback.selectionClick();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      // Decora el cambio de selección, nunca lo reemplaza: el estado
      // seleccionado/no-seleccionado es idéntico con o sin esta animación.
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: seleccionado ? scheme.primary : scheme.outlineVariant,
          width: seleccionado ? 1.6 : 1,
        ),
        color:
            seleccionado
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : scheme.surface,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _alTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Checkbox(value: seleccionado, onChanged: (_) => _alTocar()),
                const SizedBox(width: 4),
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TareasColors.profundidad(
                      context,
                      dependiente.profundidadNivel,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'N${dependiente.codNivel}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dependiente.descripcionCargo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          // Flexible, no un Text suelto: en un teléfono angosto
                          // un nombre de sucursal largo puede desbordar la fila
                          // antes de llegar al nombre del empleado.
                          Flexible(
                            child: Text(
                              dependiente.nombreSucursal,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                          if (dependiente.nombreEmpleadoActual != null) ...[
                            const SizedBox(width: 10),
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dependiente.nombreEmpleadoActual!,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                'Cargo vacante',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
