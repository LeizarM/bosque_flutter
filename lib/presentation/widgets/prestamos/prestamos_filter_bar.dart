import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_constants.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_filter_bar.dart'
    show BosqueFiltroDropdown;

// ══════════════════════════════════════════════════════════════════════════════
// BARRA DE FILTROS
// ══════════════════════════════════════════════════════════════════════════════
class PrestamosFilterBar extends ConsumerWidget {
  final PrestamoState st;
  final PrestamoNotifier ntf;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;

  const PrestamosFilterBar({
    super.key,
    required this.st,
    required this.ntf,
    required this.searchCtrl,
    required this.onSearch,
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
            // ── Búsqueda ──
            SizedBox(
              width: 230,
              height: 36,
              child: TextField(
                controller: searchCtrl,
                onChanged: onSearch,
                style: TextStyle(fontSize: 13, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Buscar concepto o empleado...',
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
            const PrestamosFilterDivider(),
            const SizedBox(width: 8),

            PrestamosFilterChip(
              label: 'EMPRESA',
              active: true, // ← siempre visible
              child: _buildEmpresaDropdown(ctx, ref, cs),
            ),
            const SizedBox(width: 8),

            PrestamosFilterChip(
              label: 'ESTADO',
              active: true,
              child: _buildEstadoDropdown(ctx, ref, cs),
            ),
            const SizedBox(width: 8),

            // ── Separador y Botón Nuevo ──
            const SizedBox(width: 16),
            PermissionWidget(
              buttonName: 'btnCrearPrestamoManual',
              child: FilledButton.icon(
                onPressed: () {
                  final uid = ref.read(userProvider)?.codUsuario ?? 0;
                  final emp = ref.read(codEmpresaPrestamosProvider);
                  showPrestamoAsignacionDialog(
                    ctx,
                    modo: PrestamoDialogModo.manual,
                    audUsuarioI: uid,
                  ).then((v) {
                    if (v == true) {
                      ref.read(prestamoProvider(emp).notifier).cargar();
                    }
                  });
                },
                //icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Préstamos Bosque 1',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoDropdown(BuildContext ctx, WidgetRef ref, ColorScheme cs) {
    final selectedEmpresa = ref.watch(codEmpresaPrestamosProvider);
    final estadoActual =
        ref.watch(prestamoProvider(selectedEmpresa)).estadoFiltro;
    final opciones = [
      'TODOS',
      'ASIGNADOS',
      'NO ASIGNADOS',
      'CON SALDO PENDIENTE',
    ];

    return BosqueFiltroDropdown<String>(
      value: estadoActual,
      accentColor: cs.primary,
      selectedItemBuilder:
          (c) =>
              opciones.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (e == 'CON SALDO PENDIENTE')
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: cs.primary,
                      )
                    else if (e != 'TODOS')
                      Icon(
                        Icons.label_outline_rounded,
                        size: 14,
                        color: cs.primary,
                      )
                    else
                      Icon(
                        Icons.all_inclusive_rounded,
                        size: 14,
                        color: cs.primary,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      e,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                );
              }).toList(),
      items:
          opciones.map((e) {
            return DropdownMenuItem<String>(
              value: e,
              child: Row(
                children: [
                  if (e == 'CON SALDO PENDIENTE')
                    const Icon(Icons.warning_amber_rounded, size: 16)
                  else if (e != 'TODOS')
                    const Icon(Icons.label_outline_rounded, size: 16)
                  else
                    const Icon(Icons.all_inclusive_rounded, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    e,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      onChanged: (val) {
        if (val != null) {
          ref
              .read(prestamoProvider(selectedEmpresa).notifier)
              .filtrarEstado(val);
        }
      },
    );
  }

  Widget _buildEmpresaDropdown(
    BuildContext ctx,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    final selected = ref.watch(codEmpresaPrestamosProvider);
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
                      ref.read(codEmpresaPrestamosProvider.notifier).state =
                          v ?? 0,
            );
          },
        );
  }
}

/// Divisor vertical en la barra de filtros
class PrestamosFilterDivider extends StatelessWidget {
  const PrestamosFilterDivider({super.key});

  @override
  Widget build(BuildContext ctx) => Container(
    height: 24,
    width: 1,
    color: Theme.of(ctx).colorScheme.outline.withValues(alpha: 0.3),
  );
}

/// Wrapper visual para cada filtro con label flotante
class PrestamosFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Widget child;
  const PrestamosFilterChip({
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
