import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget informativo que muestra el total de días de vacaciones disponibles para un empleado.
/// Sigue el diseño estético del módulo Ficha del Trabajador.
class VacacionResumenWidget extends ConsumerWidget {
  final int codEmpleado;

  const VacacionResumenWidget({super.key, required this.codEmpleado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(vacacionResumenProvider(codEmpleado));
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: isDesktop ? 16 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la sección
          Row(
            children: [
              Icon(
                Icons.beach_access_rounded,
                color:
                    isDark ? theme.colorScheme.primary : Colors.teal.shade700,
                size: isDesktop ? 22 : 18,
              ),
              const SizedBox(width: 8),
              Text(
                isDesktop
                    ? 'DIAS DE VACACION DISPONIBLES'
                    : 'Días de Vacación Disponibles',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontFamily: 'Montserrat',
                  color: isDark ? Colors.white : Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Colors.black12),

          resumenAsync.when(
            data: (resumen) {
              if (resumen == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No se encontró información de vacaciones',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.teal.shade50.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.teal.shade100,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Etiqueta y descripción
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DIAS ACUMULADOS HASTA LA FECHA.',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Badge con el valor
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDark
                                ? theme.colorScheme.primary
                                : Colors.teal.shade700,
                            isDark
                                ? theme.colorScheme.secondary
                                : Colors.teal.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? theme.colorScheme.primary
                                    : Colors.teal)
                                .withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${resumen.cantidadDiasTotal}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            error:
                (err, _) => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Información no disponible',
                      style: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
