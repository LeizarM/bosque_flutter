import 'package:bosque_flutter/presentation/widgets/permisos-vacaciones/solicitud_permiso_vacacion.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/domain/entities/tipo_permiso_vacacion_entity.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class MisSolicitudesWidget extends ConsumerWidget {
  final int codEmpleado;

  const MisSolicitudesWidget({super.key, required this.codEmpleado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSolicitudes = ref.watch(misSolicitudesProvider(codEmpleado));
    final fmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');

    final currentUser = ref.watch(userProvider);
    final Set<int> reportAllowedEmployees = {
      2, // ejemplo: gerente
      218,
      21,
      50,
      47,
    };

    final bool canRequest =
        currentUser != null &&
        (currentUser.codEmpleado == codEmpleado ||
            currentUser.tipoUsuario.toUpperCase() == 'ROLE_ADM' ||
            currentUser.tipoUsuario.toUpperCase() == 'ADM' ||
            reportAllowedEmployees.contains(currentUser.codEmpleado));

    final theme = Theme.of(context);
    final hPad = ResponsiveUtilsBosque.getHorizontalPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canRequest)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: 8.0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_calendar, color: Colors.white),
                label: Text(
                  'Solicitar Permiso / Vacación',
                  style: TextStyle(
                    fontSize: ResponsiveUtilsBosque.getResponsiveValue(
                      context: context,
                      defaultValue: 15.0,
                      mobile: 14.0,
                      desktop: 16.0,
                    ),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final relaciones =
                      ref.read(relacionLaboralProvider(codEmpleado)).value;
                  int codRelReal = 0;
                  if (relaciones != null && relaciones.isNotEmpty) {
                    final activa = relaciones.firstWhere(
                      (r) => r.esActivo == 1,
                      orElse: () => relaciones.first,
                    );
                    codRelReal = activa.codRelEmplEmpr;
                  }
                  SolicitudPermisoForm.mostrar(
                    context,
                    codEmpleado: codEmpleado,
                    codRelEmplEmpr: codRelReal,
                    audUsuarioI: currentUser.codUsuario,
                  );
                },
              ),
            ),
          ),

        asyncSolicitudes.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (lista) {
            if (lista.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No tienes solicitudes registradas.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final sol = lista[index];
                bool esEditable =
                    (sol.estado == 1 &&
                        sol.pasoActual == 'Enviado (Sin revisión)') &&
                    canRequest;
                final bool esPorHoras = sol.cantidadDias < 1.0;
                final String textoFechas =
                    esPorHoras
                        ? "${fmt.format(sol.desde)} (${timeFmt.format(sol.desde)} a ${timeFmt.format(sol.hasta)})"
                        : "${fmt.format(sol.desde)} al ${fmt.format(sol.hasta)}";
                final String textoDias =
                    esPorHoras
                        ? "${(sol.cantidadDias * 8).toStringAsFixed(1)} hrs"
                        : "${sol.cantidadDias.toStringAsFixed(1)} días";

                final isDark = Theme.of(context).brightness == Brightness.dark;

                Color estadoColor;
                IconData estadoIcon;
                if (sol.estado == 2) {
                  estadoColor = Colors.green;
                  estadoIcon = Icons.check_circle_outline;
                } else if (sol.estado == 3) {
                  estadoColor = Colors.red;
                  estadoIcon = Icons.cancel_outlined;
                } else {
                  estadoColor = Colors.orange;
                  estadoIcon = Icons.schedule;
                }

                return Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_note_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      DisplayValue<TipoPermisoVacacionEntity>(
                                        code: sol.tipoPermiso,
                                        provider: tiposPermisoProvider,
                                        getCode: (e) => e.codTipos,
                                        getDescription: (e) => e.nombre,
                                        fallback: sol.tipoPermiso,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          textoDias,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    textoFechas,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (esEditable)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () {
                                  SolicitudPermisoForm.mostrar(
                                    context,
                                    codEmpleado: codEmpleado,
                                    codRelEmplEmpr: sol.codRelEmplEmpr,
                                    audUsuarioI: currentUser.codUsuario,
                                    solicitudAEditar: sol,
                                  );
                                },
                              )
                            else
                              const Icon(
                                Icons.lock_outline,
                                color: Colors.grey,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (sol.motivo.trim().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.withValues(
                                  alpha: isDark ? 0.1 : 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.notes_rounded,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    sol.motivo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isDark
                                              ? Colors.white70
                                              : Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? estadoColor.withValues(alpha: 0.15)
                                    : estadoColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: estadoColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(estadoIcon, size: 14, color: estadoColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Estado: ${sol.pasoActual}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: estadoColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (sol.estado == 2 && sol.codPermiso != null)
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () async {
                                      try {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Generando reporte...',
                                            ),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                        final bytes = await ref.read(
                                          rptPermisoVacacionProvider(
                                            sol.codPermiso!,
                                          ).future,
                                        );
                                        await Printing.layoutPdf(
                                          onLayout: (_) async => bytes,
                                          name:
                                              'RptPermisoVacacion_${sol.codPermiso}',
                                        );
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error al generar reporte: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.picture_as_pdf,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'PDF',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (sol.estado == 2 && sol.codPermiso != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Recuerda imprimir y firmar tu boleta de permiso/vacación.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          isDark
                                              ? Colors.blue[300]
                                              : Colors.blue[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (sol.estado == 3 &&
                            sol.motivoRechazo != null &&
                            sol.motivoRechazo!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.red.withValues(alpha: 0.15)
                                      : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 14,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Motivo rechazo: ${sol.motivoRechazo}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
