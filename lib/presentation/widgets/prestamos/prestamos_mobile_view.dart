import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_pagination_bar.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_controller.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/tipo_prestamo_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// VISTA MÓVIL — tarjetas agrupadas
// ══════════════════════════════════════════════════════════════════════════════
class PrestamosMobileView extends ConsumerWidget {
  final PrestamoState st;
  final PrestamoNotifier ntf;
  final void Function(PrestamoEntity) onAsignar;
  final void Function(PrestamoEntity) onVerDetalle;
  final void Function(PrestamoEntity) onEditar;
  final void Function(PrestamoEntity) onAnular;
  final int uid;

  const PrestamosMobileView({
    super.key,
    required this.st,
    required this.ntf,
    required this.onAsignar,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onAnular,
    required this.uid,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {

    if (st.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (st.items.isEmpty) {
      return const PrestamosEmptyMobile();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: st.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder:
                (c, i) => PrestamosMobileCard(
                  item: st.items[i],
                  onAsignar: () => onAsignar(st.items[i]),
                  onVerDetalle: () => onVerDetalle(st.items[i]),
                  onEditar: () => onEditar(st.items[i]),
                  onAnular: () => onAnular(st.items[i]),
                  uid: uid,
                ),
          ),
        ),
        // Paginación
        PrestamosPaginationBar(st: st, ntf: ntf),
      ],
    );
  }
}

/// Tarjeta optimizada para pantallas pequeñas (estilo compacto)
class PrestamosMobileCard extends ConsumerWidget {
  final PrestamoEntity item;
  final VoidCallback onAsignar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;
  final VoidCallback onAnular;
  final int uid;

  const PrestamosMobileCard({
    super.key,
    required this.item,
    required this.onAsignar,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onAnular,
    required this.uid,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final estadosAsync = ref.watch(estadosPrestamoProvider);
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final e = item;
    final cfg = eCfg(e.estadoAsignacion, isDark);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onVerDetalle,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: cfg.fg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (e.db.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  e.db,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: cs.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                e.numAsiento,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: cs.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.concepto,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Asignado: ${e.nombreEmpleadoAsignado?.isNotEmpty == true ? e.nombreEmpleadoAsignado! : 'Sin asignar'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.primary.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        estadosAsync.when(
                          data: (estados) {
                            final estadoFound = estados.firstWhere(
                              (t) => t.codTipos == e.estadoPrestamo,
                              orElse:
                                  () => TipoPrestamoEntity(
                                    codTipos: '',
                                    nombre: 'DESCONOCIDO',
                                    codGrupo: 26,
                                  ),
                            );

                            if (estadoFound.codTipos == 'CAN' ||
                                estadoFound.codTipos == 'ANU') {
                              final isAnulado = estadoFound.codTipos == 'ANU';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isAnulado
                                              ? Colors.red.withValues(alpha: 0.2)
                                              : Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color:
                                            isAnulado
                                                ? Colors.red.withValues(alpha: 0.5)
                                                : Colors.green.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      estadoFound.nombre,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isAnulado
                                                ? Colors.red
                                                : Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        e.estadoPrestamo == 'ANU'
                            ? 'Bs. ---'
                            : 'Bs. ${fmtPrestamo.format(e.debe)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          decoration:
                              e.estadoPrestamo == 'ANU'
                                  ? TextDecoration.lineThrough
                                  : null,
                          color:
                              e.estadoPrestamo == 'ANU'
                                  ? cs.onSurface.withValues(alpha: 0.3)
                                  : (isDark
                                      ? Colors.greenAccent.shade200
                                      : const Color(0xFF1B5E20)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmtFechaPrestamo.format(e.fechaAsiento),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.1)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (e.estadoAsignacion != 'ASIGNADO')
                    PermissionWidget(
                      buttonName: 'btnAsignarPrestamo',
                      child: TextButton.icon(
                        onPressed: () {
                          showPrestamoAsignacionDialog(
                            ctx,
                            modo: PrestamoDialogModo.asignacionSap,
                            audUsuarioI: uid,
                            cabecera: e,
                          ).then((v) {
                            if (v == true) {
                              final activeFiltro = ref.read(
                                codEmpresaPrestamosProvider,
                              );
                              ref
                                  .read(prestamoProvider(activeFiltro).notifier)
                                  .cargar();
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 16,
                        ),
                        label: const Text('Asignar'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                  if (e.estadoAsignacion == 'ASIGNADO' &&
                      e.estadoPrestamo != 'ANU' &&
                      e.estadoPrestamo != 'CAN')
                    PermissionWidget(
                      buttonName: 'btnEditarPrestamo',
                      child: IconButton(
                        onPressed: () {
                          showPrestamoAsignacionDialog(
                            ctx,
                            modo: PrestamoDialogModo.edicionSap,
                            audUsuarioI: uid,
                            cabecera: e,
                          ).then((v) {
                            if (v == true) {
                              final activeFiltro = ref.read(
                                codEmpresaPrestamosProvider,
                              );
                              ref
                                  .read(prestamoProvider(activeFiltro).notifier)
                                  .cargar();
                            }
                          });
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        tooltip: 'Editar Préstamo',
                        color: cs.primary,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  if (e.estadoAsignacion == 'ASIGNADO')
                    IconButton(
                      onPressed: onVerDetalle,
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                      tooltip: 'Ver Detalle',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  if (e.estadoAsignacion == 'ASIGNADO' &&
                      e.estadoPrestamo == 'PEN')
                    PermissionWidget(
                      buttonName: 'btnAnularPrestamo',
                      child: IconButton(
                        onPressed: onAnular,
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        tooltip: 'Anular Préstamo',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrestamosEmptyMobile extends StatelessWidget {
  const PrestamosEmptyMobile({super.key});

  @override
  Widget build(BuildContext ctx) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No se encontraron préstamos',
          style: TextStyle(
            color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
