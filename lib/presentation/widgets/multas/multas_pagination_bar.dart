import 'package:bosque_flutter/core/state/multa_provider.dart';
import 'package:flutter/material.dart';

class MultasPaginationBar extends StatelessWidget {
  final MultaState st;
  final MultaNotifier ntf;
  const MultasPaginationBar({
    super.key,
    required this.st,
    required this.ntf,
  });

  List<Widget> _pageButtons(ColorScheme cs) {
    final pages = st.totalPaginas;
    final cur = st.pagina;
    if (pages <= 1) return [];

    final btns = <Widget>[];
    final show = <int>{};
    show.add(1);
    show.add(pages);
    for (int p = cur - 1; p <= cur + 1; p++) {
      if (p > 0 && p <= pages) show.add(p);
    }
    final sorted = show.toList()..sort();
    int prev = 0;
    for (final p in sorted) {
      if (prev > 0 && p - prev > 1) {
        btns.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '…',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
            ),
          ),
        );
      }
      final isCur = p == cur;
      btns.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: isCur ? null : () => ntf.cambiarPagina(p),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCur ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCur ? cs.primary : cs.outline.withValues(alpha: 0.25),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$p',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCur ? cs.onPrimary : cs.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
      prev = p;
    }
    return btns;
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final first = st.items.isEmpty ? 0 : (st.pagina - 1) * st.tamanoPagina + 1;
    final last =
        st.items.isEmpty
            ? 0
            : (st.pagina - 1) * st.tamanoPagina + st.items.length;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              st.items.isEmpty
                  ? 'Sin resultados'
                  : '$first–$last de ${st.totalRegistros}',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
            iconSize: 18,
            icon: Icon(
              Icons.chevron_left_rounded,
              color:
                  st.pagina > 1 ? cs.primary : cs.onSurface.withValues(alpha: 0.25),
            ),
            onPressed:
                st.pagina > 1 ? () => ntf.cambiarPagina(st.pagina - 1) : null,
          ),
          ..._pageButtons(cs),
          IconButton(
            iconSize: 18,
            icon: Icon(
              Icons.chevron_right_rounded,
              color:
                  st.pagina < st.totalPaginas
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.25),
            ),
            onPressed:
                st.pagina < st.totalPaginas
                    ? () => ntf.cambiarPagina(st.pagina + 1)
                    : null,
          ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: st.tamanoPagina,
                  isDense: true,
                  style: TextStyle(fontSize: 12, color: cs.onSurface),
                  items:
                      [10, 15, 20, 50]
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text('$s / pág'),
                            ),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) ntf.cambiarTamano(v);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
