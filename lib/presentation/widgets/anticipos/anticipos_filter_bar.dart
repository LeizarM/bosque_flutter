import 'package:bosque_flutter/core/state/anticipo_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ══════════════════════════════════════════════════════════════════════════════
// BARRA DE FILTROS
// ══════════════════════════════════════════════════════════════════════════════
class AnticiposFilterBar extends ConsumerWidget {
  final AnticipoState st;
  final AnticipoNotifier ntf;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final List<String> anios;

  const AnticiposFilterBar({
    super.key,
    required this.st,
    required this.ntf,
    required this.searchCtrl,
    required this.onSearch,
    required this.anios,
  });

  @override
  Widget build(BuildContext ctx, WidgetRef ref) {
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // ── Búsqueda ──
            SizedBox(
              width: 210,
              height: 36,
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearch,
                style: TextStyle(fontSize: 13, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Buscar concepto...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withOpacity(0.45),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: cs.primary,
                  ),
                  suffixIcon:
                      searchCtrl.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.close, size: 15),
                            onPressed: () {
                              searchCtrl.clear();
                              onSearch('');
                            },
                          )
                          : null,
                  isDense: true,
                  filled: true,
                  fillColor: cs.primary.withOpacity(isDark ? 0.1 : 0.06),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnticiposFilterDivider(),
            const SizedBox(width: 8),

            // ── Empresa ──
            AnticiposFilterChip(
              label: 'EMPRESA',
              active: true, // ← siempre visible
              child: _buildEmpresaDropdown(ctx, ref, cs),
            ),
            const SizedBox(width: 8),

            // ── Estado ──
            AnticiposFilterChip(
              label: 'ESTADO',
              active: true,
              child: BosqueFiltroDropdown<String?>(
                value: st.estadoFiltro,
                items: [
                  const DropdownMenuItem(value: null, child: Text('TODOS')),
                  ...estados.map(
                    (e) => DropdownMenuItem<String?>(value: e, child: Text(e)),
                  ),
                ],
                onChanged: (v) => ntf.cambiarFiltrado(estado: v),
              ),
            ),
            const SizedBox(width: 8),

            // ── Mes ──
            AnticiposFilterChip(
              label: 'MES',
              active: true,
              child: BosqueFiltroDropdown<String>(
                value: st.mes,
                items:
                    meses
                        .map(
                          (m) => DropdownMenuItem<String>(
                            value: m['v'],
                            child: Text(m['l']!),
                          ),
                        )
                        .toList(),
                onChanged: (v) => ntf.setFechaFiltro(mes: v),
              ),
            ),
            const SizedBox(width: 8),

            // ── Año ──
            AnticiposFilterChip(
              label: 'AÑO',
              active: true,
              child: BosqueFiltroDropdown<String>(
                value: st.anio,
                items:
                    anios
                        .map(
                          (a) => DropdownMenuItem<String>(
                            value: a,
                            child: Text(a),
                          ),
                        )
                        .toList(),
                onChanged: (v) => ntf.setFechaFiltro(anio: v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpresaDropdown(
    BuildContext ctx,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    final selected = ref.watch(codEmpresaAnticiposProvider);
    return ref
        .watch(empresasProvider)
        .when(
          loading:
              () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          error:
              (_, __) => const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 18,
              ),
          data: (todasEmpresas) {
            // Filtramos empresas excluidas
            final empresas =
                todasEmpresas
                    .where((e) => !codEmpresasExcluidas.contains(e.codEmpresa))
                    .toList();
            if (empresas.isEmpty) return const SizedBox.shrink();

            // Lista para items Y selectedItemBuilder (deben tener el mismo tamaño)
            // Índice 0 = TODAS, índice 1..n = empresas filtradas
            return BosqueFiltroDropdown<int>(
              value: selected,
              accentColor: cs.primary,
              selectedItemBuilder:
                  (c) => [
                    // trigger para value=0 (TODAS)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.all_inclusive_rounded,
                          size: 14,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'TODAS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // trigger para cada empresa
                    ...empresas.map(
                      (e) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 110),
                            child: Text(
                              e.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              items: [
                // Opción TODAS
                DropdownMenuItem<int>(
                  value: 0,
                  child: Row(
                    children: [
                      Icon(
                        Icons.all_inclusive_rounded,
                        size: 15,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'TODAS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Empresas filtradas
                ...empresas.map(
                  (e) => DropdownMenuItem<int>(
                    value: e.codEmpresa,
                    child: Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 15,
                          color:
                              e.codEmpresa == selected
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.nombre,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                e.codEmpresa == selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        if (e.codEmpresa == selected) ...[
                          const Spacer(),
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              onChanged:
                  (v) =>
                      ref.read(codEmpresaAnticiposProvider.notifier).state =
                          v ?? 0,
            );
          },
        );
  }
}

/// Divisor vertical en la barra de filtros
class AnticiposFilterDivider extends StatelessWidget {
  const AnticiposFilterDivider({super.key});

  @override
  Widget build(BuildContext ctx) => Container(
    height: 24,
    width: 1,
    color: Theme.of(ctx).colorScheme.outline.withOpacity(0.3),
  );
}

/// Wrapper visual para cada filtro con label flotante
class AnticiposFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Widget child;
  const AnticiposFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (active)
          Positioned(
            top: -5,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET REUTILIZABLE — BosqueFiltroDropdown
// ══════════════════════════════════════════════════════════════════════════════
class BosqueFiltroDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final Color? accentColor;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  const BosqueFiltroDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.accentColor,
    this.selectedItemBuilder,
  });

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final isAccented = accentColor != null;
    final color = accentColor ?? cs.onSurface;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isAccented ? 5 : 0,
      ),
      decoration: BoxDecoration(
        color:
            isAccented
                ? color.withOpacity(0.08)
                : Theme.of(ctx).brightness == Brightness.dark
                ? cs.surfaceVariant.withOpacity(0.4)
                : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isAccented ? color.withOpacity(0.3) : cs.outline.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: cs.surface,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
          style: TextStyle(
            fontSize: 12,
            color: isAccented ? color : cs.onSurface,
            fontWeight: isAccented ? FontWeight.w600 : FontWeight.normal,
          ),
          selectedItemBuilder: selectedItemBuilder,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
