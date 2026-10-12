import 'package:bosque_flutter/core/state/indemnizacion_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class IndemnizacionFilterBar extends ConsumerStatefulWidget {
  final IndemnizacionState state;
  final dynamic notifier;
  final int codEmpresa;
  final Widget? actionButton;
  final bool showAreaFilter;
  final bool useDropdownSearch;
  final bool showFechaCorte;

  const IndemnizacionFilterBar({
    Key? key,
    required this.state,
    required this.notifier,
    required this.codEmpresa,
    this.actionButton,
    this.showAreaFilter = true,
    this.useDropdownSearch = false,
    this.showFechaCorte = true,
  }) : super(key: key);

  @override
  ConsumerState<IndemnizacionFilterBar> createState() =>
      _IndemnizacionFilterBarState();
}

class _IndemnizacionFilterBarState
    extends ConsumerState<IndemnizacionFilterBar> {
  EmpleadoEntity? _empleadoSeleccionado;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.state.search;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatearFecha(String fechaStr) {
    try {
      final date = DateTime.parse(fechaStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return fechaStr;
    }
  }

  @override
  Widget build(BuildContext ctx) {
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
            if (widget.useDropdownSearch)
              SizedBox(
                width: ResponsiveUtilsBosque.isDesktop(ctx) ? 400 : 250,
                height: 38,
                child: DropdownSearch<EmpleadoEntity>(
                  selectedItem: _empleadoSeleccionado,
                  asyncItems: (text) async {
                    final list = <EmpleadoEntity>[];
                    try {
                      final codEmpresa = widget.codEmpresa;
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
                      _searchCtrl.text = val.persona.datoPersona ?? '';
                      widget.notifier.cargar(
                        search: '',
                        codEmpleado: val.codEmpleado,
                        clearCodEmpleado: false,
                        pagina: 1,
                      );
                    } else {
                      _searchCtrl.clear();
                      widget.notifier.cargar(
                        search: '',
                        codEmpleado: null,
                        clearCodEmpleado: true,
                        pagina: 1,
                      );
                    }
                  },
                  clearButtonProps: ClearButtonProps(
                    isVisible: _empleadoSeleccionado != null,
                    icon: const Icon(Icons.close, size: 16),
                  ),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      hintText: 'Buscar por empleado...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.45),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: cs.primary.withOpacity(isDark ? 0.1 : 0.06),
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
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              SizedBox(
                width: 250,
                height: 36,
                child: TextFormField(
                  initialValue: widget.state.search,
                  onChanged: (val) => widget.notifier.buscar(val),
                  style: TextStyle(fontSize: 13, color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Buscar empleado...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.45),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: cs.primary,
                    ),
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
            _IndemnizacionFilterDivider(),
            const SizedBox(width: 8),

            // ── Empresa ──
            _IndemnizacionFilterChip(
              label: 'EMPRESA',
              active: true,
              child: _buildEmpresaDropdown(ctx, ref, cs),
            ),
            const SizedBox(width: 8),

            // ── Área ──
            if (widget.showAreaFilter) ...[
              _IndemnizacionFilterChip(
                label: 'ÁREA',
                active: true,
                child: _buildAreaDropdown(ctx, ref, cs),
              ),
              const SizedBox(width: 8),
            ],

            if (widget.showFechaCorte) ...[
              // ── Fecha ──
              _IndemnizacionFilterChip(
                label: 'FECHA CORTE',
                active: true,
                child: InkWell(
                  onTap: () async {
                    final initDate =
                        DateTime.tryParse(widget.state.fechaActual) ??
                        DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: initDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      widget.notifier.setFecha(
                        picked.toIso8601String().split('T')[0],
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          widget.state.fechaActual.isNotEmpty
                              ? _formatearFecha(widget.state.fechaActual)
                              : 'Seleccionar...',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            if (widget.actionButton != null) ...[
              const SizedBox(width: 16),
              _IndemnizacionFilterDivider(),
              const SizedBox(width: 16),
              widget.actionButton!,
            ],
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
              (_, __) =>
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
          data: (empresas) {
            return _BosqueFiltroDropdown<int>(
              value: widget.codEmpresa,
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
                              e.codEmpresa == widget.codEmpresa
                                  ? cs.primary
                                  : cs.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.nombre,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                e.codEmpresa == widget.codEmpresa
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  if (widget.codEmpresa != v) widget.notifier.setArea(null);
                  ref.read(codEmpresaIndemnizacionProvider.notifier).state = v;
                }
              },
            );
          },
        );
  }

  Widget _buildAreaDropdown(BuildContext ctx, WidgetRef ref, ColorScheme cs) {
    return ref
        .watch(areasPorEmpresaProvider(widget.codEmpresa))
        .when(
          loading:
              () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          error:
              (_, __) =>
                  const Icon(Icons.warning_amber_rounded, color: Colors.red),
          data: (areas) {
            final isValid = areas.any((a) => a.codArea == widget.state.codArea);
            return _BosqueFiltroDropdown<int?>(
              value: isValid ? widget.state.codArea : null,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('TODAS LAS ÁREAS'),
                ),
                ...areas.map(
                  (a) => DropdownMenuItem(
                    value: a.codArea,
                    child: Text(a.nombreArea),
                  ),
                ),
              ],
              onChanged: (v) {
                widget.notifier.setArea(v);
              },
            );
          },
        );
  }
}

class _IndemnizacionFilterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext ctx) => Container(
    height: 24,
    width: 1,
    color: Theme.of(ctx).colorScheme.outline.withOpacity(0.3),
  );
}

class _IndemnizacionFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Widget child;

  const _IndemnizacionFilterChip({
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

class _BosqueFiltroDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final Color? accentColor;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;

  const _BosqueFiltroDropdown({
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
