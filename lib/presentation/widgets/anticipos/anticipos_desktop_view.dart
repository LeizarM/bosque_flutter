import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_accion_cell.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_estado_chip.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════════════════════════
// VISTA DESKTOP — tabla con cabecera fija y paginación
// ══════════════════════════════════════════════════════════════════════════════
class AnticiposDesktopView extends StatelessWidget {
  final AnticipoState st;
  final AnticipoNotifier ntf;
  final void Function(AnticipoEntity) onAsignar;
  final void Function(AnticipoEntity) onVerDetalle;
  final int uid;

  const AnticiposDesktopView({
    super.key,
    required this.st,
    required this.ntf,
    required this.onAsignar,
    required this.onVerDetalle,
    required this.uid,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final hPad = ResponsiveUtilsBosque.getHorizontalPadding(ctx);

    return Column(
      children: [
        // Cabecera de tabla
        Container(
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withOpacity(0.5),
            border: Border(
              bottom: BorderSide(color: cs.outline.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              AnticiposTH('N°', wN, Alignment.center),
              AnticiposTH(
                'ASIENTO / CONCEPTO',
                0,
                Alignment.centerLeft,
                flex: true,
              ),
              AnticiposTH('NRO. DOCUMENTO', wRef, Alignment.center),
              AnticiposTH('FECHA', wFec, Alignment.center),
              AnticiposTH('MONTO', wMon, Alignment.centerRight),
              AnticiposTH('ESTADO', wEst, Alignment.center),
              AnticiposTH('ACCIÓN', wAcc, Alignment.center),
            ],
          ),
        ),

        // Cuerpo
        Expanded(
          child:
              st.cargando
                  ? const Center(child: CircularProgressIndicator())
                  : st.items.isEmpty
                  ? AnticiposEmptyTable()
                  : ListView.builder(
                    itemCount: st.items.length,
                    itemBuilder:
                        (c, i) => AnticiposDesktopRow(
                          item: st.items[i],
                          index: i,
                          onAsignar: () => onAsignar(st.items[i]),
                          onVerDetalle: () => onVerDetalle(st.items[i]),
                          uid: uid,
                          hPad: hPad,
                        ),
                  ),
        ),

        // Paginación
        AnticiposPaginationBar(st: st, ntf: ntf),
      ],
    );
  }
}

/// Celda de cabecera de tabla
class AnticiposTH extends StatelessWidget {
  final String label;
  final double width;
  final Alignment align;
  final bool flex;
  const AnticiposTH(
    this.label,
    this.width,
    this.align, {
    super.key,
    this.flex = false,
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
    if (flex) return Expanded(child: Align(alignment: align, child: cell));
    return SizedBox(width: width, child: Align(alignment: align, child: cell));
  }
}

/// Fila de datos con efecto hover
class AnticiposDesktopRow extends StatefulWidget {
  final AnticipoEntity item;
  final int index;
  final VoidCallback onAsignar;
  final VoidCallback onVerDetalle;
  final int uid;
  final double hPad;

  const AnticiposDesktopRow({
    super.key,
    required this.item,
    required this.index,
    required this.onAsignar,
    required this.onVerDetalle,
    required this.uid,
    required this.hPad,
  });

  @override
  State<AnticiposDesktopRow> createState() => _AnticiposDesktopRowState();
}

class _AnticiposDesktopRowState extends State<AnticiposDesktopRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final e = widget.item;

    final bg =
        _hover
            ? cs.primary.withOpacity(0.06)
            : widget.index.isOdd
            ? cs.surfaceVariant.withOpacity(isDark ? 0.12 : 0.25)
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
                      color: cs.onSurface.withOpacity(0.4),
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
                        if (e.db.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(3),
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      e.concepto,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.55),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Nro Documento (Referencia)
              SizedBox(
                width: wRef,
                child: Center(
                  child: InkWell(
                    onTap: () {
                      if (e.referencia.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: e.referencia));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Nro. de documento copiado'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Text(
                      e.referencia.isNotEmpty ? e.referencia : '—',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
              // Fecha
              SizedBox(
                width: wFec,
                child: Center(
                  child: Text(
                    fmtFechaAnticipo.format(e.fechaAsiento),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.65),
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
                          fontSize: 9,
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                      ),
                      Text(
                        fmtAnticipo.format(e.debe),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? Colors.greenAccent.shade200
                                  : const Color(0xFF1B5E20),
                        ),
                      ),
                      // ── HABER — descomentar para activar (muestra en rojo cuando hay valor) ──
                      if (e.haber > 0)
                        Text(
                          '- Bs. ${fmtAnticipo.format(e.haber)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Estado
              SizedBox(
                width: wEst,
                child: Center(child: AnticiposEstadoChip(estado: e.estado)),
              ),
              // Acción
              SizedBox(
                width: wAcc,
                child: Center(
                  child: AnticiposAccionCell(
                    anticipo: e,
                    onAsignar: widget.onAsignar,
                    onVerDetalle: widget.onVerDetalle,
                    uid: widget.uid,
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
class AnticiposEmptyTable extends StatelessWidget {
  const AnticiposEmptyTable({super.key});

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
            color: cs.outline.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin anticipos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajusta los filtros o actualiza la lista.',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withOpacity(0.35),
            ),
          ),
        ],
      ),
    );
  }
}
