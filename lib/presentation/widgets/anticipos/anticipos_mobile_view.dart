import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_accion_cell.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_desktop_view.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_estado_chip.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════════════════════════
// VISTA MÓVIL — lista de cards
// ══════════════════════════════════════════════════════════════════════════════
class AnticiposMobileView extends StatelessWidget {
  final AnticipoState st;
  final AnticipoNotifier ntf;
  final void Function(AnticipoEntity) onAsignar;
  final void Function(AnticipoEntity) onVerDetalle;
  final int uid;

  const AnticiposMobileView({
    super.key,
    required this.st,
    required this.ntf,
    required this.onAsignar,
    required this.onVerDetalle,
    required this.uid,
  });

  @override
  Widget build(BuildContext ctx) => Column(
    children: [
      Expanded(
        child:
            st.cargando
                ? const Center(child: CircularProgressIndicator())
                : st.items.isEmpty
                ? AnticiposEmptyTable()
                : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: st.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder:
                      (c, i) => AnticiposMobileCard(
                        item: st.items[i],
                        onAsignar: () => onAsignar(st.items[i]),
                        onVerDetalle: () => onVerDetalle(st.items[i]),
                        uid: uid,
                      ),
                ),
      ),
      AnticiposPaginationBar(st: st, ntf: ntf),
    ],
  );
}

class AnticiposMobileCard extends StatelessWidget {
  final AnticipoEntity item;
  final VoidCallback onAsignar;
  final VoidCallback onVerDetalle;
  final int uid;

  const AnticiposMobileCard({
    super.key,
    required this.item,
    required this.onAsignar,
    required this.onVerDetalle,
    required this.uid,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final e = item;
    final cfg = eCfg(e.estado, isDark);

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
                                  color: cs.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: cs.primary.withOpacity(0.25),
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          e.concepto,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withOpacity(0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (e.referencia.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: e.referencia),
                                  );
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Nro. de documento copiado',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Nro. Documento: ${e.referencia}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
                      // ── HABER — descomentar para activar ──────────────────
                      // if (e.haber > 0)
                      //   Text(
                      //     '- Bs. ${fmtAnticipo.format(e.haber)}',
                      //     style: const TextStyle(
                      //       fontSize: 10,
                      //       fontWeight: FontWeight.w600,
                      //       color: Colors.red,
                      //     ),
                      //   ),
                      const SizedBox(height: 4),
                      Text(
                        fmtFechaAnticipo.format(e.fechaAsiento),
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  AnticiposEstadoChip(estado: e.estado),
                  const Spacer(),
                  AnticiposAccionCell(
                    anticipo: e,
                    onAsignar: onAsignar,
                    onVerDetalle: onVerDetalle,
                    uid: uid,
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
