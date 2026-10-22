import 'package:bosque_flutter/presentation/widgets/indemnizacion/indemnizacion_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/indemnizacion/indemnizacion_prevision_table.dart';
import 'package:bosque_flutter/presentation/widgets/indemnizacion/indemnizacion_historial_table.dart';
import 'package:bosque_flutter/core/state/indemnizacion_provider.dart';
import 'package:bosque_flutter/core/state/retroactivo_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/presentation/widgets/indemnizacion/indemnizacion_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/indemnizacion/indemnizacion_pagination_bar.dart';
import 'package:bosque_flutter/presentation/widgets/indemnizacion/indemnizacion_reportes_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IndemnizacionScreen extends ConsumerWidget {
  const IndemnizacionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codEmpresa = ref.watch(codEmpresaIndemnizacionProvider);
    final state = ref.watch(indemnizacionProvider(codEmpresa));
    final notifier = ref.read(indemnizacionProvider(codEmpresa).notifier);

    final historialState = ref.watch(
      historialIndemnizacionProvider(codEmpresa),
    );
    final historialNotifier = ref.read(
      historialIndemnizacionProvider(codEmpresa).notifier,
    );

    final userState = ref.watch(userProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen<IndemnizacionState>(indemnizacionProvider(codEmpresa), (
      previous,
      next,
    ) {
      if (next.mensajeExito != null &&
          next.mensajeExito != previous?.mensajeExito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.mensajeExito!),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (next.mensajeError != null &&
          next.mensajeError != previous?.mensajeError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.mensajeError!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    ref.listen<IndemnizacionState>(historialIndemnizacionProvider(codEmpresa), (
      previous,
      next,
    ) {
      if (next.mensajeExito != null &&
          next.mensajeExito != previous?.mensajeExito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.mensajeExito!),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (next.mensajeError != null &&
          next.mensajeError != previous?.mensajeError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.mensajeError!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cs.surfaceVariant.withOpacity(0.15),
        appBar: AppBar(
          title: const Text(
            'Gestión de Indemnizaciones',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Actualizar datos',
              onPressed: () {
                notifier.cargar();
                historialNotifier.cargar();
                //ref.read(retroactivoProvider.notifier).cargar();
              },
            ),
            IconButton(
              icon: const Icon(Icons.print_rounded),
              tooltip: 'Reportes de Previsión / Indemnización',
              onPressed: () {
                showIndemnizacionReportesDialog(
                  context,
                  fechaCorte: state.fechaActual,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface.withOpacity(0.6),
            indicatorColor: cs.primary,
            tabs: const [
              Tab(text: 'PREVISION'),
              Tab(text: 'INDEMNIZACIONES'),
              // Tab(text: 'RETROACTIVOS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Provisiones
            Column(
              children: [
                // ── BARRA DE FILTROS ─────────────────────────
                IndemnizacionFilterBar(
                  state: state,
                  notifier: notifier,
                  codEmpresa: codEmpresa,
                ),

                // ── TABLA DE DATOS ─────────────────────────
                Expanded(
                  child:
                      state.cargando
                          ? const Center(child: CircularProgressIndicator())
                          : state.items.isEmpty
                          ? Center(
                            child: Text(
                              'No hay registros para los filtros seleccionados.',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                            ),
                          )
                          : IndemnizacionPrevisionTable(
                            items: state.items,
                            cs: cs,
                            fechaCorte: state.fechaActual,
                          ),
                ),

                // ── PAGINACIÓN ─────────────────────────
                IndemnizacionPaginationBar(st: state, ntf: notifier),
              ],
            ),

            // Tab 2: Indemnizaciones
            Column(
              children: [
                IndemnizacionFilterBar(
                  state: historialState,
                  notifier: historialNotifier,
                  codEmpresa: codEmpresa,
                  showAreaFilter: false,
                  useDropdownSearch: true,
                  showFechaCorte: false,
                  actionButton: PermissionWidget(
                    buttonName: 'btnRegistrarIndemnizacion',
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => IndemnizacionDialog(
                                audUsuarioI: userState?.codUsuario ?? 0,
                              ),
                        ).then((_) {
                          historialNotifier.cargar();
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Nueva Indemnizacion',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child:
                      historialState.cargando
                          ? const Center(child: CircularProgressIndicator())
                          : historialState.items.isEmpty
                          ? Center(
                            child: Text(
                              'No hay registros para los filtros seleccionados.',
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                            ),
                          )
                          : IndemnizacionHistorialTable(
                            items: historialState.items,
                            cs: cs,
                            onEdit: (item) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => IndemnizacionDialog(
                                      audUsuarioI: userState?.codUsuario ?? 0,
                                      indemnizacion: item,
                                    ),
                              ).then((_) => historialNotifier.cargar());
                            },
                            onDelete: (item) {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Eliminar Registro'),
                                      content: const Text(
                                        '¿Está seguro que desea eliminar este registro?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            historialNotifier.eliminar(
                                              item,
                                              userState?.codUsuario ?? 0,
                                            );
                                          },
                                          child: const Text(
                                            'Eliminar',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                ),
                IndemnizacionPaginationBar(
                  st: historialState,
                  ntf: historialNotifier,
                ),
              ],
            ),

            // Tab 3: Retroactivos
            // const RetroactivoTab(),
          ],
        ),
      ),
    );
  }
}
