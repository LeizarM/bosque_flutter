import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_shared_sheet_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SHEET DETALLE
// ══════════════════════════════════════════════════════════════════════════════
class AnticipoDetalleSheet extends ConsumerStatefulWidget {
  final AnticipoEntity anticipo;
  const AnticipoDetalleSheet({super.key, required this.anticipo});
  @override
  ConsumerState<AnticipoDetalleSheet> createState() => _AnticipoDetalleSheetState();
}

class _AnticipoDetalleSheetState extends ConsumerState<AnticipoDetalleSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted)
        ref.read(anticipoDetalleProvider.notifier).cargar(widget.anticipo.codAnticipo);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final st = ref.watch(anticipoDetalleProvider);
    final ntf = ref.read(anticipoDetalleProvider.notifier);
    final a = widget.anticipo;
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return AnticipoBaseSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      builder: (_, ctrl) => Column(
        children: [
          const AnticipoSheetHandle(),
          AnticipoSheetCabecera(cabecera: a, titulo: 'Detalle de asignación', icon: Icons.receipt_long_rounded),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnticipoSheetSearchField(
              controller: _searchCtrl,
              hint: 'Buscar empleado…',
              onChanged: (v) => ntf.buscar(v, a.codAnticipo),
            ),
          ),
          const Divider(height: 1),
          if (!st.cargando && st.totalRegistros > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${st.items.length} de ${st.totalRegistros} registros',
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600),
                ),
              ),
            ),
          Expanded(
            child: st.cargando
                ? const Center(child: CircularProgressIndicator())
                : st.items.isEmpty
                ? const Center(child: Text('Sin detalle de empleados.'))
                : ListView.separated(
                    controller: ctrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: st.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = st.items[i];
                      final cfg = eCfg(d.estadoAnticipo, isDark);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: cs.primary.withOpacity(0.1),
                          child: Text(
                            d.nombreCompleto.isNotEmpty ? d.nombreCompleto[0] : '?',
                            style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        title: Text(d.nombreCompleto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(d.descripcion, style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.55))),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 9, color: cs.onSurface.withOpacity(0.4)),
                                const SizedBox(width: 3),
                                Text(fmtFechaAnticipo.format(d.fechaAnticipo),
                                    style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.45))),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(color: cfg.bg, borderRadius: BorderRadius.circular(10)),
                                  child: Text(d.estadoAnticipo,
                                      style: TextStyle(fontSize: 9, color: cfg.fg, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Text(
                          'Bs. ${fmtAnticipo.format(d.monto)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13,
                            color: isDark ? Colors.greenAccent.shade200 : const Color(0xFF1B5E20),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
