import 'package:bosque_flutter/domain/entities/solicitud_permiso_entity.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-vacaciones/solicitud_permiso_vacacion.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/permisos_vacacion_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-vacaciones/solicitud_permiso_card.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

class MisSolicitudesWidget extends ConsumerWidget {
  final int codEmpleado;

  const MisSolicitudesWidget({super.key, required this.codEmpleado});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    final asyncSolicitudes = ref.watch(misSolicitudesProvider(codEmpleado));

    final hPad = ResponsiveUtilsBosque.getHorizontalPadding(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canRequest)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8.0),
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
                    audUsuarioI: currentUser?.codUsuario ?? 0,
                    actorCodEmpleado: currentUser?.codEmpleado ?? 0,
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
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lista.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sol = lista[index];
                bool esEditable =
                    (sol.estado == 1 &&
                        sol.pasoActual == 'Enviado (Sin revisión)') &&
                    canRequest;

                final isDark = Theme.of(context).brightness == Brightness.dark;

                Color estadoColor;
                IconData estadoIcon;
                if (sol.estado == 2) {
                  estadoColor = Colors.green;
                  estadoIcon = Icons.check_circle_outline;
                } else if (sol.estado == 3) {
                  estadoColor = Colors.red;
                  estadoIcon = Icons.cancel_outlined;
                } else if (sol.estado == 4) {
                  estadoColor = Colors.grey;
                  estadoIcon = Icons.remove_circle_outline;
                } else {
                  estadoColor = Colors.orange;
                  estadoIcon = Icons.schedule;
                }

                return SolicitudPermisoCard(
                  item: sol,
                  showEmployeeInfo: false,
                  actionButtons:
                      sol.estado == 2
                          ? PermissionWidget(
                            buttonName: 'btnAnularVacacion',
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'Anular',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                elevation: 0,
                              ),
                              onPressed:
                                  () => _mostrarDialogoAnulacion(
                                    context,
                                    ref,
                                    sol,
                                  ),
                            ),
                          )
                          : null,
                  topTrailingWidget:
                      esEditable
                          ? IconButton(
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
                                  audUsuarioI: currentUser!.codUsuario,
                                  actorCodEmpleado: currentUser!.codEmpleado,
                                  solicitudAEditar: sol,
                                );
                            },
                          )
                          : const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                            size: 20,
                          ),
                  statusWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                          content: Text('Generando reporte...'),
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
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.print_rounded,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PDF',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.primary,
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
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _mostrarDialogoAnulacion(
    BuildContext context,
    WidgetRef ref,
    SolicitudPermisoEntity sol,
  ) {
    final TextEditingController motivoCtrl = TextEditingController();
    final currentUser = ref.read(userProvider);
    if (currentUser == null) return;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Anular Solicitud', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '¿Está seguro de anular esta solicitud aprobada?',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: motivoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de anulación (Obligatorio)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed:
                      isLoading
                          ? null
                          : () {
                            final motivo = motivoCtrl.text.trim();
                            if (motivo.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Debe ingresar un motivo'),
                                ),
                              );
                              return;
                            }
                            setState(() => isLoading = true);
                            ref
                                .read(accionSolicitudProvider.notifier)
                                .anular(
                                  codSolicitud: sol.codSolicitud!,
                                  audUsuarioI: currentUser.codUsuario,
                                  motivo: motivo,
                                    onSuccess: (msg) {
                                      Navigator.pop(ctx);
                                      ref.invalidate(misSolicitudesProvider);
                                      ref.invalidate(solicitudesPendientesProvider);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(msg),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  onError: (err) {
                                    setState(() => isLoading = false);
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(err),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  },
                                );
                          },
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Confirmar Anulación',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
