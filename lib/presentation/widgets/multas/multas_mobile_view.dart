import 'package:bosque_flutter/core/state/multa_provider.dart';
import 'package:bosque_flutter/domain/entities/multa_entity.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_constants.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MultasMobileView extends StatelessWidget {
  final MultaState st;
  final MultaNotifier ntf;
  final int uid;

  const MultasMobileView({
    super.key,
    required this.st,
    required this.ntf,
    required this.uid,
  });

  @override
  Widget build(BuildContext ctx) {
    if (st.cargando && st.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (st.items.isEmpty) {
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

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: st.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder:
                (context, i) => _MultaCard(e: st.items[i], uid: uid, ntf: ntf),
          ),
        ),
        MultasPaginationBar(st: st, ntf: ntf),
      ],
    );
  }
}

class _MultaCard extends StatefulWidget {
  final MultaEntity e;
  final int uid;
  final MultaNotifier ntf;

  const _MultaCard({required this.e, required this.uid, required this.ntf});

  @override
  State<_MultaCard> createState() => _MultaCardState();
}

class _MultaCardState extends State<_MultaCard> {
  bool _isEditing = false;
  late TextEditingController _diasMultaCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _diasMultaCtrl = TextEditingController(text: '${widget.e.diasMulta ?? 0}');
  }

  @override
  void didUpdateWidget(covariant _MultaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.e != widget.e) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _diasMultaCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final m = widget.e.copyWith(
      diasMulta: double.tryParse(_diasMultaCtrl.text) ?? 0.0,
    );
    widget.ntf.editarMulta(m);
    setState(() => _isEditing = false);
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final e = widget.e;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: cs.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: avatar + nombre + seguro (sin estado) ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primary.withValues(alpha: 0.1),
                      child: Text(
                        _getInitials(e.nombreCompleto),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          '#${e.fila ?? 0}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.nombreCompleto,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.health_and_safety_rounded,
                            size: 12,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              e.seguroNombre.isNotEmpty
                                  ? e.seguroNombre
                                  : 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Días Trabajados | Días Multa ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: cs.outline.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDataCol('Trabajados', '${e.diasTrabajados ?? 0}', cs),
                _buildMultaField(cs),
              ],
            ),
          ),
          // ── Haber Básico | Monto Total ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HABER BÁSICO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fmtMonto.format(e.haberBasico),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'MONTO TOTAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fmtMonto.format(e.monto),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.1)),
          // ── Botones editar / guardar ──
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        () => setState(() {
                          _initControllers();
                          _isEditing = false;
                        }),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Guardar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: () => setState(() => _isEditing = true),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        'EDITAR MULTA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Campo directo para días multa (sin dropdown)
  Widget _buildMultaField(ColorScheme cs) {
    final orange = Colors.orange.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_isEditing)
          SizedBox(
            width: 72,
            height: 34,
            child: TextField(
              controller: _diasMultaCtrl,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: orange, width: 1.5),
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: orange,
              ),
            ),
          )
        else
          Text(
            '${widget.e.diasMulta ?? 0}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: orange,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          'MULTA',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: orange.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCol(
    String label,
    String value,
    ColorScheme cs, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color ?? cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: (color ?? cs.onSurface).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
