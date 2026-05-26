import 'package:bosque_flutter/core/state/multa_provider.dart';
import 'package:bosque_flutter/domain/entities/multa_entity.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_constants.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultasDesktopView extends StatefulWidget {
  final MultaState st;
  final MultaNotifier ntf;
  final int uid;

  const MultasDesktopView({
    super.key,
    required this.st,
    required this.ntf,
    required this.uid,
  });

  @override
  State<MultasDesktopView> createState() => _MultasDesktopViewState();
}

class _MultasDesktopViewState extends State<MultasDesktopView> {
  final Map<int, TextEditingController> _ctrl = {};
  final Map<int, double> _pendingDiasMulta = {}; // sobrevive a búsquedas
  final Map<int, MultaEntity> _itemCache = {};

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant MultasDesktopView old) {
    super.didUpdateWidget(old);
    if (old.st.items != widget.st.items) {
      // Solo limpiar pendientes si fue un guardado exitoso
      final didSave =
          widget.st.mensajeExito != null &&
          old.st.mensajeExito != widget.st.mensajeExito;
      setState(() {
        if (didSave) _pendingDiasMulta.clear();
        _sync();
      });
    }
  }

  void _sync() {
    final cur = {for (final e in widget.st.items) e.codMulta: e};
    // Actualizar caché con items actuales
    for (final e in widget.st.items) _itemCache[e.codMulta] = e;
    // Dispose controladores de items que ya no están en la vista
    _ctrl.keys.where((k) => !cur.containsKey(k)).toList().forEach((k) {
      _ctrl[k]!.dispose();
      _ctrl.remove(k);
    });
    // Crear/actualizar controladores
    for (final e in widget.st.items) {
      final k = e.codMulta;
      final pending = _pendingDiasMulta.containsKey(k);
      final val = pending ? '${_pendingDiasMulta[k]}' : '${e.diasMulta ?? 0}';
      if (!_ctrl.containsKey(k)) {
        _ctrl[k] = TextEditingController(text: val);
      } else if (!pending) {
        final serverVal = '${e.diasMulta ?? 0}';
        if (_ctrl[k]!.text != serverVal) _ctrl[k]!.text = serverVal;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) c.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    final toSave =
        _pendingDiasMulta.entries
            .map((entry) {
              final base = _itemCache[entry.key];
              if (base == null) return null;
              return base.copyWith(diasMulta: entry.value);
            })
            .whereType<MultaEntity>()
            .toList();

    setState(() => _pendingDiasMulta.clear());
    await widget.ntf.editarTodasMultas(toSave);
  }

  @override
  Widget build(BuildContext ctx) {
    if (widget.st.cargando && widget.st.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.st.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron multas\ncon los filtros actuales',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
            ),
          ],
        ),
      );
    }

    final cs = Theme.of(ctx).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Barra de acciones (visible solo con cambios pendientes) ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child:
                _pendingDiasMulta.isNotEmpty
                    ? Padding(
                      key: const ValueKey('bar'),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_pendingDiasMulta.length} registro(s) con cambios pendientes',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed:
                                () => setState(() {
                                  _pendingDiasMulta.clear();
                                  _sync();
                                }),
                            icon: const Icon(Icons.undo_rounded, size: 15),
                            label: const Text(
                              'Descartar',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: widget.st.cargando ? null : _saveAll,
                            icon: const Icon(Icons.save_rounded, size: 15),
                            label: const Text(
                              'Guardar Cambios',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          // ── Encabezado ──
          _TableHeader(cs: cs),
          const SizedBox(height: 4),
          // ── Filas ──
          Expanded(
            child: ListView.separated(
              itemCount: widget.st.items.length,
              separatorBuilder:
                  (_, __) => Divider(
                    height: 1,
                    color: cs.outline.withValues(alpha: 0.08),
                  ),
              itemBuilder: (_, i) {
                final item = widget.st.items[i];
                return _TableRow(
                  item: item,
                  ctrl: _ctrl[item.codMulta],
                  isDirty: _pendingDiasMulta.containsKey(item.codMulta),
                  isEven: i.isEven,
                  cs: cs,
                  onChanged:
                      (k, val) => setState(
                        () => _pendingDiasMulta[k] = double.tryParse(val) ?? 0,
                      ),
                );
              },
            ),
          ),
          MultasPaginationBar(st: widget.st, ntf: widget.ntf),
        ],
      ),
    );
  }
}

// ── Encabezado de tabla ────────────────────────────────────────────────────
class _TableHeader extends StatelessWidget {
  final ColorScheme cs;
  const _TableHeader({required this.cs});

  @override
  Widget build(BuildContext ctx) => Container(
    decoration: BoxDecoration(
      color: cs.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: Row(
      children: [
        _h('#', wN),
        _h('Empleado', wEmp, flex: 3),
        _h('Seguro', wSeg, flex: 2),
        _h('Haber Básico', wMonto, right: true),
        _h('Días Trab.', wDias, center: true),
        _h('Días Multa', wDias, center: true),
        _h('Monto Multa', wMonto, right: true),
      ],
    ),
  );

  // REEMPLAZAR el método _h completo:
  // REEMPLAZAR (cambia bool flex por int flex para soporte de proporciones):
  Widget _h(
    String t,
    double w, {
    bool right = false,
    bool center = false,
    int flex = 0,
  }) {
    final txt = Text(
      t.toUpperCase(),
      textAlign:
          right
              ? TextAlign.right
              : center
              ? TextAlign.center
              : TextAlign.left,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
    return flex > 0
        ? Expanded(flex: flex, child: txt)
        : SizedBox(width: w, child: txt);
  }
}

// ── Fila de tabla ──────────────────────────────────────────────────────────
class _TableRow extends StatelessWidget {
  final MultaEntity item;
  final TextEditingController? ctrl;
  final bool isDirty;
  final bool isEven;
  final ColorScheme cs;
  final void Function(int codMulta, String val) onChanged;

  const _TableRow({
    required this.item,
    required this.ctrl,
    required this.isDirty,
    required this.isEven,
    required this.cs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext ctx) {
    final orange = Colors.orange.shade700;
    return Container(
      color:
          isDirty
              ? Colors.orange.withValues(alpha: 0.05)
              : isEven
              ? cs.surface
              : cs.surfaceContainerHighest.withValues(alpha: 0.25),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          // #
          SizedBox(
            width: wN,
            child: Text(
              '${item.fila ?? 0}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          // Empleado
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                item.nombreCompleto,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Seguro
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                item.seguroNombre.isNotEmpty ? item.seguroNombre : '—',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.65),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Haber Básico
          SizedBox(
            width: wMonto,
            child: Text(
              fmtMonto.format(item.haberBasico),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          // Días Trabajados (solo lectura, calculado por servidor)
          SizedBox(
            width: wDias,
            child: Text(
              '${item.diasTrabajados ?? 0}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          // Días Multa (editable)
          SizedBox(
            width: wDias,
            child:
                ctrl != null
                    ? SizedBox(
                      height: 30,
                      child: TextField(
                        controller: ctrl,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        onChanged: (val) => onChanged(item.codMulta, val),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: cs.outline.withValues(alpha: 0.25),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: cs.outline.withValues(alpha: 0.35),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: orange, width: 1.5),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: orange,
                        ),
                      ),
                    )
                    : const SizedBox(),
          ),
          // Monto (solo lectura, calculado por servidor)
          SizedBox(
            width: wMonto,
            child: Text(
              fmtMonto.format(item.monto),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
