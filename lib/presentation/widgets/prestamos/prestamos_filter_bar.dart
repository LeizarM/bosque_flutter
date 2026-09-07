import 'package:bosque_flutter/core/state/prestamo_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/tipo_prestamo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_constants.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/prestamos/prestamos_asignacion_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_constants.dart'
    show meses;
import 'package:bosque_flutter/presentation/widgets/anticipos/anticipos_filter_bar.dart'
    show BosqueFiltroDropdown;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';

// ══════════════════════════════════════════════════════════════════════════════
// BARRA DE FILTROS
// ══════════════════════════════════════════════════════════════════════════════
class PrestamosFilterBar extends ConsumerStatefulWidget {
  final PrestamoState st;
  final PrestamoNotifier ntf;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final bool isVigentesTab;

  const PrestamosFilterBar({
    super.key,
    required this.st,
    required this.ntf,
    required this.searchCtrl,
    required this.onSearch,
    this.isVigentesTab = false,
  });

  @override
  ConsumerState<PrestamosFilterBar> createState() => _PrestamosFilterBarState();
}

class _PrestamosFilterBarState extends ConsumerState<PrestamosFilterBar> {
  EmpleadoEntity? _empleadoSeleccionado;

  @override
  void didUpdateWidget(covariant PrestamosFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.st.codEmpleadoFiltro == null && _empleadoSeleccionado != null) {
      _empleadoSeleccionado = null;
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    String? fDesde;
    String? fHasta;
    if (widget.st.mes != null && widget.st.anio != null) {
      final mesStr = widget.st.mes!.padLeft(2, '0');
      final d = DateTime.tryParse('${widget.st.anio}-$mesStr-01');
      if (d != null) {
        fDesde = '${widget.st.anio}-$mesStr-01';
        final ultimoDia = DateTime(d.year, d.month + 1, 0).day;
        fHasta = '${widget.st.anio}-$mesStr-$ultimoDia';
      }
    }

    final int anioActual = DateTime.now().year;
    int anioInicio = anioActual - 5 + 1; // 5 = maxGestiones
    if (anioInicio < 2026) anioInicio = 2026; // 2026 = anioBase
    final int count = (anioActual - anioInicio + 1).clamp(1, 5);
    final anios = List.generate(count, (i) => (anioActual - i).toString());

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
              width: ResponsiveUtilsBosque.isDesktop(ctx) ? 400 : 250,
              height: 38,
              child: DropdownSearch<EmpleadoEntity>(
                selectedItem: _empleadoSeleccionado,
                asyncItems: (text) async {
                  final list = <EmpleadoEntity>[];
                  try {
                    final codEmpresa = ref.read(codEmpresaPrestamosProvider);
                    final empParam = codEmpresa == 0 ? null : codEmpresa;

                    final emps = await ref.read(
                      getListaEmpleados((
                        text.isEmpty ? null : text,
                        1, // esActivo = 1
                        1, // pageNumber = 1
                        200, // pageSize = 200
                        empParam, // codEmpresa
                      )).future,
                    );
                    list.addAll(emps);
                  } catch (e) {
                    debugPrint('Error fetch empleados: $e');
                  }
                  return list;
                },
                itemAsString: (item) => item.persona.datoPersona ?? '',
                compareFn: (a, b) => a.codEmpleado == b.codEmpleado,
                onChanged: (val) {
                  setState(() {
                    _empleadoSeleccionado = val;
                  });
                  if (val != null) {
                    widget.searchCtrl.text = val.persona.datoPersona ?? '';
                    widget.ntf.cargar(
                      search: '',
                      codEmpleado: val.codEmpleado,
                      clearCodEmpleado: false,
                      pagina: 1,
                    );
                  } else {
                    widget.searchCtrl.clear();
                    widget.ntf.cargar(
                      search: '',
                      codEmpleado: null,
                      clearCodEmpleado: true,
                      pagina: 1,
                    );
                  }
                },
                clearButtonProps: ClearButtonProps(
                  isVisible:
                      widget.st.search.isNotEmpty ||
                      widget.st.codEmpleadoFiltro != null,
                  icon: const Icon(Icons.close, size: 16),
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    hintText: 'Buscar por empleado...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: cs.primary.withValues(
                      alpha: isDark ? 0.1 : 0.06,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
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
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  isFilterOnline: true,
                  searchFieldProps: TextFieldProps(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Escribe para buscar...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  itemBuilder: (ctx, item, isSelected) {
                    return ListTile(
                      title: Text(
                        item.persona.datoPersona ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
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
            if (!widget.isVigentesTab) ...[
              // ── Mes ──
              PrestamosFilterChip(
                label: 'MES',
                active: true,
                child: BosqueFiltroDropdown<String>(
                  value: widget.st.mes,
                  items: [
                    ...meses.map(
                      (m) => DropdownMenuItem<String>(
                        value: m['v'],
                        child: Text(m['l']!),
                      ),
                    ),
                  ],
                  onChanged: (v) => widget.ntf.setFechaFiltro(mes: v),
                ),
              ),
              const SizedBox(width: 8),

              // ── Año ──
              PrestamosFilterChip(
                label: 'AÑO',
                active: true,
                child: BosqueFiltroDropdown<String>(
                  value: widget.st.anio,
                  items: [
                    ...anios.map(
                      (a) => DropdownMenuItem<String>(value: a, child: Text(a)),
                    ),
                  ],
                  onChanged: (v) => widget.ntf.setFechaFiltro(anio: v),
                ),
              ),
              const SizedBox(width: 16),
            ],

            if (widget.isVigentesTab) ...[
              const SizedBox(width: 4),

              // ── Monto Total ──
              TotalPrestamosWidget(fechaDesde: null, fechaHasta: null),
            ],

            // const SizedBox(width: 16),
            // PermissionWidget(
            //   buttonName: 'btnCrearPrestamoManual',
            //   child: FilledButton.icon(
            //     onPressed: () {
            //       final uid = ref.read(userProvider)?.codUsuario ?? 0;
            //       final emp = ref.read(codEmpresaPrestamosProvider);
            //       showPrestamoAsignacionDialog(
            //         ctx,
            //         modo: PrestamoDialogModo.manual,
            //         audUsuarioI: uid,
            //       ).then((v) {
            //         if (v == true) {
            //           ref.read(prestamoProvider(emp).notifier).cargar();
            //           ref.read(prestamoVigentesProvider(emp).notifier).cargar();
            //         }
            //       });
            //     },
            //     //icon: const Icon(Icons.add_rounded, size: 18),
            //     label: const Text(
            //       'Préstamos Bosque 1',
            //       style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            //     ),
            //     style: FilledButton.styleFrom(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 16,
            //         vertical: 8,
            //       ),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoDropdown(BuildContext ctx, WidgetRef ref, ColorScheme cs) {
    final estadoActual = widget.st.estadoFiltro;

    if (widget.isVigentesTab) {
      final estadosAsync = ref.watch(estadosPrestamoProvider);
      return estadosAsync.when(
        data: (estados) {
          final opciones = [
            TipoPrestamoEntity(codTipos: 'TODOS', nombre: 'TODOS', codGrupo: 0),
            ...estados,
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
                          Icon(
                            e.codTipos == 'TODOS'
                                ? Icons.all_inclusive_rounded
                                : Icons.label_outline_rounded,
                            size: 14,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            e.nombre,
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
                    value: e.codTipos,
                    child: Row(
                      children: [
                        Icon(
                          e.codTipos == 'TODOS'
                              ? Icons.all_inclusive_rounded
                              : Icons.label_outline_rounded,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          e.nombre,
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
              if (val != null) widget.ntf.filtrarEstado(val);
            },
          );
        },
        loading:
            () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        error:
            (err, stack) =>
                Text('Error', style: TextStyle(color: cs.error, fontSize: 12)),
      );
    }

    final opciones = ['TODOS', 'ASIGNADOS', 'NO ASIGNADOS'];

    return BosqueFiltroDropdown<String>(
      value: estadoActual,
      accentColor: cs.primary,
      selectedItemBuilder:
          (c) =>
              opciones.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (e != 'TODOS')
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
                  if (e != 'TODOS')
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
          widget.ntf.filtrarEstado(val);
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

class TotalPrestamosWidget extends ConsumerWidget {
  final String? fechaDesde;
  final String? fechaHasta;

  const TotalPrestamosWidget({
    super.key,
    required this.fechaDesde,
    required this.fechaHasta,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codEmpresa = ref.watch(codEmpresaPrestamosProvider);
    final args = (
      codEmpresa: codEmpresa,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
    final totalBosqueAsync = ref.watch(prestamosTotalProvider(args));
    final totalSAPAsync = ref.watch(prestamosTotalSAPProvider(args));
    final cs = Theme.of(context).colorScheme;

    final totalBosque = totalBosqueAsync.valueOrNull;
    final totalSAP = totalSAPAsync.valueOrNull;
    final diff =
        (totalBosque != null && totalSAP != null)
            ? (totalBosque - totalSAP)
            : null;
    final isCuadrado = diff != null && diff.abs() < 0.01;

    final diffColor = isCuadrado ? Colors.green.shade700 : Colors.red.shade700;
    final diffBgColor =
        isCuadrado
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.red.withValues(alpha: 0.12);
    final diffBorderColor =
        isCuadrado
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.red.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── TOTAL SALDO BOSQUE ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
            ),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TOTAL SALDO BOSQUE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              totalBosqueAsync.when(
                data:
                    (total) => Text(
                      'Bs. ${fmtPrestamo.format(total)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                loading:
                    () => const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                error:
                    (_, __) => const Text(
                      'Error',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
              ),
            ],
          ),
        ),

        // ── TOTAL SALDO SAP ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.3),
            border: Border(
              top: BorderSide(color: cs.secondary.withValues(alpha: 0.2)),
              bottom: BorderSide(color: cs.secondary.withValues(alpha: 0.2)),
              right: BorderSide(color: cs.secondary.withValues(alpha: 0.2)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TOTAL SALDO SAP',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              totalSAPAsync.when(
                data:
                    (total) => Text(
                      'Bs. ${fmtPrestamo.format(total)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: cs.secondary,
                      ),
                    ),
                loading:
                    () => const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                error:
                    (_, __) => const Text(
                      'Error',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
              ),
            ],
          ),
        ),

        // ── DIFERENCIA ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: diffBgColor,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(8),
            ),
            border: Border(
              top: BorderSide(color: diffBorderColor),
              bottom: BorderSide(color: diffBorderColor),
              right: BorderSide(color: diffBorderColor),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'DIFERENCIA',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (totalBosqueAsync.isLoading || totalSAPAsync.isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (totalBosqueAsync.hasError || totalSAPAsync.hasError)
                const Text(
                  'Error',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCuadrado
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      size: 14,
                      color: diffColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Bs. ${fmtPrestamo.format(diff ?? 0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: diffColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
