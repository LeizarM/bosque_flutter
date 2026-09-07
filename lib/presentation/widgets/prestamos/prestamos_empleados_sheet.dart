import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_shared_sheet_widgets.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_detalle_sheet.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrestamosEmpleadosSheet extends ConsumerStatefulWidget {
  final PrestamoEntity prestamo;
  final Function(PrestamoEntity)? onEditar;
  final Function(PrestamoEntity)? onAnular;
  const PrestamosEmpleadosSheet({
    super.key,
    required this.prestamo,
    this.onEditar,
    this.onAnular,
  });
  @override
  ConsumerState<PrestamosEmpleadosSheet> createState() =>
      _PrestamosEmpleadosSheetState();
}

class _PrestamosEmpleadosSheetState
    extends ConsumerState<PrestamosEmpleadosSheet> {
  @override
  Widget build(BuildContext ctx) {
    final ({int codEmpresa, String db, int transIdSAP, int? codPrestamo}) args =
        (
          codEmpresa: widget.prestamo.codEmpresa,
          db: widget.prestamo.db,
          transIdSAP: int.tryParse(widget.prestamo.numAsiento) ?? 0,
          codPrestamo: widget.prestamo.codPrestamo,
        );

    final stAsync = ref.watch(prestamoEmpleadosAsignadosProvider(args));
    final p = widget.prestamo;
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return AnticipoBaseSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      builder:
          (_, ctrl) => Column(
            children: [
              const AnticipoSheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.people_alt_rounded, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.haber > 0
                                ? 'Préstamos Vinculados'
                                : 'Empleados Asignados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Asiento Nro: ${p.numAsiento}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Asignado',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          'Bs. ${fmtAnticipo.format(p.debe > 0 ? p.debe : p.haber)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? Colors.greenAccent.shade200
                                    : const Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: stAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('No hay empleados registrados.'),
                      );
                    }
                    return ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final e = items[i];
                        final nombreAsignado =
                            e.nombreEmpleadoAsignado ?? 'Desconocido';
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: cs.primary.withValues(alpha: 0.1),
                            child: Text(
                              nombreAsignado.isNotEmpty
                                  ? nombreAsignado[0]
                                  : '?',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            nombreAsignado,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // subtitle: Text(
                          //   'Préstamo Nro: ${e.codPrestamo}',
                          //   style: TextStyle(
                          //     fontSize: 11,
                          //     color: cs.onSurface.withValues(alpha: 0.55),
                          //   ),
                          // ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Bs. ${fmtAnticipo.format(e.debe)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color:
                                      isDark
                                          ? Colors.greenAccent.shade200
                                          : const Color(0xFF1B5E20),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // VER DETALLE
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                                tooltip: 'Ver Detalle',
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: ctx,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          ResponsiveUtilsBosque.isDesktop(ctx)
                                              ? 800
                                              : double.infinity,
                                    ),
                                    builder:
                                        (context) =>
                                            PrestamosDetalleSheet(prestamo: e),
                                  );
                                },
                              ),
                              if (widget.onEditar != null && e.estadoPrestamo != 'ANU' && e.estadoPrestamo != 'CAN' && e.haber == 0)
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, size: 18),
                                  tooltip: 'Editar Préstamo Individual',
                                  onPressed: () => widget.onEditar!(e),
                                ),
                              if (widget.onAnular != null && e.estadoPrestamo == 'PEN' && e.haber == 0)
                                IconButton(
                                  icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.red),
                                  tooltip: 'Anular Préstamo Individual',
                                  onPressed: () => widget.onAnular!(e),
                                ),
                            ],
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: ctx,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              constraints: BoxConstraints(
                                maxWidth: ResponsiveUtilsBosque.isDesktop(ctx)
                                    ? 800
                                    : double.infinity,
                              ),
                              builder: (context) =>
                                  PrestamosDetalleSheet(prestamo: e),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
