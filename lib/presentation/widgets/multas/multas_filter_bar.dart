import 'package:bosque_flutter/core/state/multa_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_filter_bar.dart';
import 'package:bosque_flutter/presentation/widgets/multas/multas_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MultasFilterBar extends ConsumerWidget {
  final MultaState st;
  final MultaNotifier ntf;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final List<String> anios;
  final int uid; // NUEVO

  const MultasFilterBar({
    super.key,
    required this.st,
    required this.ntf,
    required this.searchCtrl,
    required this.onSearch,
    required this.anios,
    required this.uid,
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
            color: cs.shadow.withValues(alpha: 0.06),
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
            _buildGenerarButton(ctx, cs),
            const SizedBox(width: 8),
            const AnticiposFilterDivider(),
            const SizedBox(width: 8),
            // ── Búsqueda ──
            SizedBox(
              width: 210,
              height: 36,
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearch,
                style: TextStyle(fontSize: 13, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Buscar empleado...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.45),
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
                  fillColor: cs.primary.withValues(alpha: isDark ? 0.1 : 0.06),
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
            const AnticiposFilterDivider(),
            const SizedBox(width: 8),

            // ── Empresa ──
            AnticiposFilterChip(
              label: 'EMPRESA',
              active: true,
              child: _buildEmpresaDropdown(ctx, ref, cs),
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
            // REEMPLAZAR el bloque completo POR:
            const SizedBox(width: 8),
            AnticiposFilterChip(
              label: 'MULTA',
              active: true,
              child: BosqueFiltroDropdown<bool>(
                value: st.soloConMulta,
                items: [
                  DropdownMenuItem<bool>(
                    value: false,
                    child: Text(
                      'TODAS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  DropdownMenuItem<bool>(
                    value: true,
                    child: Text(
                      'CON MULTA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null && v != st.soloConMulta) {
                    ntf.toggleSoloConMulta();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerarButton(BuildContext ctx, ColorScheme cs) {
    if (st.generando) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
          ),
          const SizedBox(width: 8),
          Text(
            'Generando...',
            style: TextStyle(
              fontSize: 12,
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return Tooltip(
      message: 'Generar multas masivas para el periodo seleccionado',
      child: ElevatedButton.icon(
        onPressed: () => _confirmarGeneracion(ctx),
        icon: const Icon(Icons.generating_tokens_rounded, size: 16),
        label: const Text(
          'Generar Multas',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(0, 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _confirmarGeneracion(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Generar Multas'),
            content: Text(
              '¿Deseas generar las multas masivas para el mes ${st.mes} del año ${st.anio}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ntf.generarMultas(uid);
                },
                child: const Text('Generar'),
              ),
            ],
          ),
    );
  }

  Widget _buildEmpresaDropdown(
    BuildContext ctx,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    final selected = ref.watch(codEmpresaMultasProvider);
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
            final empresas =
                todasEmpresas
                    .where((e) => !codEmpresasExcluidas.contains(e.codEmpresa))
                    .toList();
            if (empresas.isEmpty) return const SizedBox.shrink();

            return BosqueFiltroDropdown<int>(
              value: selected,
              accentColor: cs.primary,
              selectedItemBuilder:
                  (c) => [
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
                                  : cs.onSurface.withValues(alpha: 0.5),
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
                      ref.read(codEmpresaMultasProvider.notifier).state =
                          v ?? 0,
            );
          },
        );
  }
}
