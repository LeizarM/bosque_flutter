import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/domain/entities/anticipo_detalle_entity.dart';
import 'package:bosque_flutter/domain/entities/anticipo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_shared_sheet_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// SHEET TIGO
// ══════════════════════════════════════════════════════════════════════════════
class AsignacionTigoSheet extends ConsumerStatefulWidget {
  final AnticipoEntity cabecera;
  final int audUsuarioI;
  const AsignacionTigoSheet({
    super.key,
    required this.cabecera,
    required this.audUsuarioI,
  });
  @override
  ConsumerState<AsignacionTigoSheet> createState() =>
      _AsignacionTigoSheetState();
}

class _AsignacionTigoSheetState extends ConsumerState<AsignacionTigoSheet> {
  final Set<int> _sel = {};
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double _montoSel(List<AnticipoDetalleEntity> items) => items
      .where((i) => _sel.contains(i.codAntDetalle))
      .fold(0.0, (s, i) => s + i.monto);

  void _toggleTodos(List<AnticipoDetalleEntity> items, bool sel) =>
      setState(() {
        if (sel)
          _sel.addAll(items.map((i) => i.codAntDetalle));
        else
          _sel.clear();
      });

  @override
  Widget build(BuildContext ctx) {
    final cab = widget.cabecera;
    final cs = Theme.of(ctx).colorScheme;
    final st = ref.watch(asignacionAnticipoProvider(cab.codEmpresa));
    final ntf = ref.read(asignacionAnticipoProvider(cab.codEmpresa).notifier);

    ref.listen<AsignacionAnticipoState>(
      asignacionAnticipoProvider(cab.codEmpresa),
      (prev, next) {
        if (!context.mounted) return;
        if (next.mensajeExito != null &&
            prev?.mensajeExito != next.mensajeExito) {
          final m = ScaffoldMessenger.of(context);
          Navigator.of(context).pop();
          m.showSnackBar(
            SnackBar(
              content: Text(next.mensajeExito!),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
        if (next.mensajeError != null &&
            prev?.mensajeError != next.mensajeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.mensajeError!),
              backgroundColor: cs.error,
            ),
          );
        }
      },
    );

    final items = st.items;
    final montoSel = _montoSel(items);
    final hayDif = (cab.debe - montoSel).abs() > 0.005;
    final sinSel = _sel.isEmpty;
    final todosSel =
        items.isNotEmpty && items.every((i) => _sel.contains(i.codAntDetalle));
    final labelBtn =
        st.asignando
            ? 'Asignando…'
            : sinSel
            ? 'Selecciona al menos un anticipo'
            : hayDif
            ? 'El monto no coincide'
            : 'Confirmar asignación (${_sel.length})';

    return AnticipoBaseSheet(
      builder:
          (_, ctrl) => Column(
            children: [
              const AnticipoSheetHandle(),
              AnticipoSheetCabecera(
                cabecera: cab,
                titulo: 'Asignación desde módulo Tigo',
                icon: Icons.phone_android_rounded,
              ),
              AnticipoMontoProgress(
                montoTotal: cab.debe,
                montoAsignado: montoSel,
                cargando: false,
                hayItems: _sel.isNotEmpty,
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AnticipoSheetSearchField(
                        controller: _searchCtrl,
                        hint: 'Buscar empleado…',
                        onChanged: ntf.buscar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnticipoSelectAllButton(
                      allSelected: todosSel,
                      enabled: items.isNotEmpty,
                      onTap: () => _toggleTodos(items, !todosSel),
                    ),
                  ],
                ),
              ),
              if (!st.cargando && items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_sel.length} de ${items.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child:
                    st.cargando
                        ? const Center(child: CircularProgressIndicator())
                        : items.isEmpty
                        ? const AnticipoEmptyState(
                          mensaje:
                              'No hay anticipos Tigo\nsin asignar para esta empresa.',
                        )
                        : ListView.separated(
                          controller: ctrl,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final d = items[i];
                            final sel = _sel.contains(d.codAntDetalle);
                            return CheckboxListTile(
                              dense: true,
                              value: sel,
                              activeColor: cs.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onChanged:
                                  (_) => setState(() {
                                    if (sel)
                                      _sel.remove(d.codAntDetalle);
                                    else
                                      _sel.add(d.codAntDetalle);
                                  }),
                              title: Text(
                                d.nombreCompleto,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      sel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.descripcion,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface.withOpacity(0.55),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 9,
                                        color: cs.onSurface.withOpacity(0.4),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        fmtFechaAnticipo.format(
                                          d.fechaAnticipo,
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: cs.onSurface.withOpacity(0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              secondary: Text(
                                'Bs. ${fmtAnticipo.format(d.monto)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color:
                                      sel
                                          ? (Theme.of(ctx).brightness ==
                                                  Brightness.dark
                                              ? Colors.greenAccent.shade200
                                              : const Color(0xFF1B5E20))
                                          : cs.onSurface.withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        ),
              ),
              AnticipoConfirmButton(
                enabled: !sinSel && !hayDif,
                loading: st.asignando,
                label: labelBtn,
                onPressed:
                    () => ntf.confirmarAsignacion(
                      cabecera: cab,
                      codAntDetalles: Set.from(_sel),
                      audUsuarioI: widget.audUsuarioI,
                    ),
              ),
            ],
          ),
    );
  }
}
