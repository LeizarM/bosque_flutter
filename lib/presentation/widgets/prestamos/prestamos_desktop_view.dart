import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/prestamo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_estado_chip.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_pagination_bar.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/tipo_prestamo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_controller.dart';

// ══════════════════════════════════════════════════════════════════════════════
// VISTA DESKTOP — tabla con cabecera fija y paginación
// ══════════════════════════════════════════════════════════════════════════════
class PrestamosDesktopView extends ConsumerWidget {
  final PrestamoState st;
  final PrestamoNotifier ntf;
  final void Function(PrestamoEntity) onAsignar;
  final void Function(PrestamoEntity) onVerDetalle;
  final void Function(PrestamoEntity) onEditar;
  final void Function(PrestamoEntity) onAnular;
  final int uid;

  const PrestamosDesktopView({
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
    final cs = Theme.of(ctx).colorScheme;
    final hPad = ResponsiveUtilsBosque.getHorizontalPadding(ctx);

    return Column(
      children: [
        // Cabecera de tabla
        Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            children: [
              PrestamosTH('N°', wN, Alignment.center),
              PrestamosTH(
                'ASIENTO / CONCEPTO',
                0,
                Alignment.centerLeft,
                flex: true,
              ),
              PrestamosTH('ASIGNADO A', wTrans, Alignment.centerLeft),
              PrestamosTH('FECHA', wFec, Alignment.center),
              PrestamosTH('MONTO', wMon, Alignment.centerRight),
              PrestamosTH('ESTADO', wEst, Alignment.center),
              PrestamosTH('ACCIÓN', wAcc, Alignment.center),
            ],
          ),
        ),

        // Cuerpo
        Expanded(
          child:
              st.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : st.items.isEmpty
                  ? const PrestamosEmptyTable()
                  : ListView.builder(
                    itemCount: st.items.length,
                    itemBuilder:
                        (c, i) => PrestamosDesktopRow(
                          item: st.items[i],
                          index: i,
                          onAsignar: () => onAsignar(st.items[i]),
                          onVerDetalle: () => onVerDetalle(st.items[i]),
                          onEditar: () => onEditar(st.items[i]),
                          onAnular: () => onAnular(st.items[i]),
                          uid: uid,
                          hPad: hPad,
                        ),
                  ),
        ),

        // Paginación
        PrestamosPaginationBar(st: st, ntf: ntf),
      ],
    );
  }
}

/// Celda de cabecera de tabla
class PrestamosTH extends StatelessWidget {
  final String label;
  final double width;
  final Alignment align;
  final bool flex;
  final int flexFactor;
  const PrestamosTH(
    this.label,
    this.width,
    this.align, {
    super.key,
    this.flex = false,
    this.flexFactor = 1,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final cell = Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: cs.primary,
        letterSpacing: 0.5,
      ),
    );
    if (flex) {
      return Expanded(
        flex: flexFactor,
        child: Align(alignment: align, child: cell),
      );
    }
    return SizedBox(width: width, child: Align(alignment: align, child: cell));
  }
}

/// Fila de datos con efecto hover
class PrestamosDesktopRow extends ConsumerStatefulWidget {
  final PrestamoEntity item;
  final int index;
  final VoidCallback onAsignar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;
  final VoidCallback onAnular;
  final int uid;
  final double hPad;

  const PrestamosDesktopRow({
    super.key,
    required this.item,
    required this.index,
    required this.onAsignar,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onAnular,
    required this.uid,
    required this.hPad,
  });

  @override
  ConsumerState<PrestamosDesktopRow> createState() =>
      _PrestamosDesktopRowState();
}

class _PrestamosDesktopRowState extends ConsumerState<PrestamosDesktopRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext ctx) {
    final estadosAsync = ref.watch(estadosPrestamoProvider);
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final e = widget.item;

    final bg =
        _hover
            ? cs.primary.withValues(alpha: 0.06)
            : widget.index.isOdd
            ? cs.surfaceContainerHighest.withValues(alpha: isDark ? 0.12 : 0.25)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onVerDetalle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: bg,
          height: 54,
          padding: EdgeInsets.symmetric(horizontal: widget.hPad),
          child: Row(
            children: [
              // N°
              SizedBox(
                width: wN,
                child: Center(
                  child: Text(
                    e.fila != null && e.fila! > 0 ? '${e.fila}' : '—',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              // Asiento / Concepto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: e.numAsiento),
                              );
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Asiento copiado'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.teal.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    e.db,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isDark
                                              ? Colors.tealAccent
                                              : Colors.teal.shade800,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    e.numAsiento,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: cs.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      e.concepto,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Empleado Asignado
              SizedBox(
                width: wTrans,
                child: Center(
                  child: Text(
                    e.nombreEmpleadoAsignado?.isNotEmpty == true
                        ? e.nombreEmpleadoAsignado!
                        : '—',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
              // Fecha
              SizedBox(
                width: wFec,
                child: Center(
                  child: Text(
                    fmtFechaPrestamo.format(e.fechaAsiento),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
              // Monto
              SizedBox(
                width: wMon,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Bs.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      Text(
                        fmtPrestamo.format(e.debe),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? Colors.greenAccent.shade200
                                  : const Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Estado
              SizedBox(
                width: wEst,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Chip dinámico basado en estadosPrestamoProvider
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
                            children: [
                              if (e.estadoPrestamo == 'PEN' || e.estadoPrestamo == null) ...[
                                PrestamosEstadoChip(estado: e.estadoAsignacion),
                                const SizedBox(height: 4),
                              ],
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
                                        isAnulado ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return PrestamosEstadoChip(
                            estado: e.estadoAsignacion,
                          );
                        }
                      },
                      loading:
                          () => const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      error:
                          (_, __) => const Text(
                            'Error',
                            style: TextStyle(fontSize: 10, color: Colors.red),
                          ),
                    ),
                  ],
                ),
              ),
              // Acción
              SizedBox(
                width: wAcc,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (e.estadoAsignacion != 'ASIGNADO')
                        PermissionWidget(
                          buttonName: 'btnAsignarPrestamo',
                          child: IconButton(
                            icon: Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            tooltip: 'Asignar préstamo',
                            onPressed: () {
                              showPrestamoAsignacionDialog(
                                context,
                                modo: PrestamoDialogModo.asignacionSap,
                                audUsuarioI: widget.uid,
                                cabecera: e,
                              ).then((v) {
                                if (v == true) {
                                  final activeFiltro = ref.read(
                                    codEmpresaPrestamosProvider,
                                  );
                                  ref
                                      .read(
                                        prestamoProvider(activeFiltro).notifier,
                                      )
                                      .cargar();
                                }
                              });
                            },
                          ),
                        ),
                      if (e.estadoAsignacion == 'ASIGNADO' &&
                          e.estadoPrestamo != 'ANU' &&
                          e.estadoPrestamo != 'CAN')
                        PermissionWidget(
                          buttonName: 'btnEditarPrestamo',
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            tooltip: 'Editar Préstamo',
                            onPressed: () {
                              showPrestamoAsignacionDialog(
                                context,
                                modo: PrestamoDialogModo.edicionSap,
                                audUsuarioI: widget.uid,
                                cabecera: e,
                              ).then((v) {
                                if (v == true) {
                                  final activeFiltro = ref.read(
                                    codEmpresaPrestamosProvider,
                                  );
                                  ref
                                      .read(
                                        prestamoProvider(activeFiltro).notifier,
                                      )
                                      .cargar();
                                }
                              });
                            },
                          ),
                        ),
                      if (e.estadoAsignacion == 'ASIGNADO')
                        IconButton(
                          icon: const Icon(
                            Icons.remove_red_eye_rounded,
                            size: 18,
                          ),
                          tooltip: 'Ver Detalle',
                          onPressed: () => widget.onVerDetalle(),
                        ),
                      if (e.estadoAsignacion == 'ASIGNADO' &&
                          e.estadoPrestamo == 'PEN')
                        PermissionWidget(
                          buttonName: 'btnAnularPrestamo',
                          child: IconButton(
                            icon: const Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: Colors.red,
                            ),
                            tooltip: 'Anular Préstamo',
                            onPressed: () => widget.onAnular(),
                          ),
                        ),
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

/// Estado vacío de tabla
class PrestamosEmptyTable extends StatelessWidget {
  const PrestamosEmptyTable({super.key});

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: cs.outline.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin préstamos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajusta los filtros o actualiza la lista.',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
