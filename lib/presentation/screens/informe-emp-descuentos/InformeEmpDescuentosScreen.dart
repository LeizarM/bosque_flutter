import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/descuento_empleado_entity.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';

class InformeEmpDescuentosScreen extends ConsumerStatefulWidget {
  const InformeEmpDescuentosScreen({super.key});

  @override
  ConsumerState<InformeEmpDescuentosScreen> createState() =>
      _InformeEmpDescuentosScreenState();
}

class _InformeEmpDescuentosScreenState
    extends ConsumerState<InformeEmpDescuentosScreen> {
  // Filtros seleccionados
  EmpleadoEntity? _empleadoSeleccionado;
  int _mesSeleccionado = DateTime.now().month;
  int _anioSeleccionado = DateTime.now().year;

  // Meses
  static const List<Map<String, dynamic>> _meses = [
    {'num': 1, 'nombre': 'Enero'},
    {'num': 2, 'nombre': 'Febrero'},
    {'num': 3, 'nombre': 'Marzo'},
    {'num': 4, 'nombre': 'Abril'},
    {'num': 5, 'nombre': 'Mayo'},
    {'num': 6, 'nombre': 'Junio'},
    {'num': 7, 'nombre': 'Julio'},
    {'num': 8, 'nombre': 'Agosto'},
    {'num': 9, 'nombre': 'Septiembre'},
    {'num': 10, 'nombre': 'Octubre'},
    {'num': 11, 'nombre': 'Noviembre'},
    {'num': 12, 'nombre': 'Diciembre'},
  ];

  static final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'en_US');

  List<int> get _anios {
    final current = DateTime.now().year;
    return [current - 2, current - 1, current];
  }

  String _formatAmount(double value) {
    return _amountFormat.format(value);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Descuentos por Empleado'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFiltros(context, theme, colorScheme, isMobile),
          if (_empleadoSeleccionado != null)
            Expanded(child: _buildResultados(theme, colorScheme, isMobile))
          else
            Expanded(child: _buildEstadoVacio(theme, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildFiltros(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    return Container(
      color: colorScheme.surfaceContainerLow,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Row(
            children: [
              Icon(Icons.filter_list, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Seleccionar período y empleado',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fila de mes y año
          isMobile
              ? Column(
                children: [
                  _buildMesDropdown(theme, colorScheme),
                  const SizedBox(height: 10),
                  _buildAnioDropdown(theme, colorScheme),
                ],
              )
              : Row(
                children: [
                  Expanded(child: _buildMesDropdown(theme, colorScheme)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAnioDropdown(theme, colorScheme)),
                ],
              ),
          const SizedBox(height: 12),
          // Dropdown con buscador de empleados
          _buildEmpleadoDropdown(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMesDropdown(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<int>(
      value: _mesSeleccionado,
      decoration: InputDecoration(
        labelText: 'Mes',
        prefixIcon: Icon(Icons.calendar_today, color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        filled: true,
        fillColor: colorScheme.surface,
      ),
      items:
          _meses
              .map(
                (m) => DropdownMenuItem<int>(
                  value: m['num'] as int,
                  child: Text(m['nombre'] as String),
                ),
              )
              .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _mesSeleccionado = v);
      },
    );
  }

  Widget _buildAnioDropdown(ThemeData theme, ColorScheme colorScheme) {
    return DropdownButtonFormField<int>(
      value: _anioSeleccionado,
      decoration: InputDecoration(
        labelText: 'Año',
        prefixIcon: Icon(Icons.date_range, color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
        filled: true,
        fillColor: colorScheme.surface,
      ),
      items:
          _anios
              .map((a) => DropdownMenuItem<int>(value: a, child: Text('$a')))
              .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _anioSeleccionado = v);
      },
    );
  }

  Widget _buildEmpleadoDropdown(ThemeData theme, ColorScheme colorScheme) {
    String nombreEmpleado(EmpleadoEntity e) {
      // El nombre viene en el objeto persona anidado
      if (e.persona.datoPersona != null &&
          e.persona.datoPersona!.trim().isNotEmpty) {
        return e.persona.datoPersona!.trim();
      }
      final desdePersona =
          '${e.persona.nombres} ${e.persona.apPaterno} ${e.persona.apMaterno}'
              .trim();
      if (desdePersona.isNotEmpty) return desdePersona;
      // Fallback: campos de nivel superior
      if (e.datoPersona.trim().isNotEmpty) return e.datoPersona.trim();
      return '${e.nombres} ${e.apPaterno} ${e.apMaterno}'.trim();
    }

    return DropdownSearch<EmpleadoEntity>(
      selectedItem: _empleadoSeleccionado,
      asyncItems: (text) async {
        final items = await ref.read(
          getListaEmpleados((
            text.isEmpty ? null : text,
            1,
            1,
            200,
            null,
          )).future,
        );
        return items;
      },
      itemAsString: nombreEmpleado,
      compareFn: (a, b) => a.codEmpleado == b.codEmpleado,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Empleado',
          hintText: 'Buscar por nombre...',
          prefixIcon: Icon(Icons.person_search, color: colorScheme.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          filled: true,
          fillColor: colorScheme.surface,
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchDelay: const Duration(milliseconds: 300),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Escriba para buscar...',
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        ),
        itemBuilder: (context, emp, isSelected) {
          final nombre = nombreEmpleado(emp);
          final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
            title: Text(nombre, style: theme.textTheme.bodyMedium),
            selected: isSelected,
            selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
          );
        },
        constraints: const BoxConstraints(maxHeight: 280),
      ),
      onChanged: (emp) => setState(() => _empleadoSeleccionado = emp),
    );
  }

  Widget _buildResultados(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    final emp = _empleadoSeleccionado!;
    final params = (emp.codEmpleado, _mesSeleccionado, _anioSeleccionado);
    final descuentosAsync = ref.watch(descuentosEmpleadoProvider(params));

    return descuentosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 8),
                Text('Error: $e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  onPressed:
                      () => ref.invalidate(descuentosEmpleadoProvider(params)),
                ),
              ],
            ),
          ),
      data: (descuentos) {
        if (descuentos.isEmpty) {
          return _buildSinDescuentos(theme, colorScheme);
        }
        return _buildListaDescuentos(descuentos, theme, colorScheme, isMobile);
      },
    );
  }

  Widget _buildSinDescuentos(ThemeData theme, ColorScheme colorScheme) {
    final mesNombre =
        _meses.firstWhere(
          (m) => m['num'] == _mesSeleccionado,
          orElse: () => {'nombre': '$_mesSeleccionado'},
        )['nombre'];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin descuentos registrados',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No hay descuentos para $mesNombre $_anioSeleccionado',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVacio(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona un empleado',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elige el período y el empleado para ver sus descuentos',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaDescuentos(
    List<DescuentoEmpleadoEntity> descuentos,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    // Totales
    final totalDescuentos = descuentos.fold<double>(
      0,
      (sum, d) => sum + d.montoDescuento,
    );
    final totalMontoTotal = descuentos.fold<double>(
      0,
      (sum, d) => sum + d.montoTotal,
    );
    final totalSaldo = descuentos.fold<double>(
      0,
      (sum, d) => sum + d.saldoRestante,
    );

    return Column(
      children: [
        // Resumen
        _buildResumen(
          descuentos,
          totalDescuentos,
          totalMontoTotal,
          totalSaldo,
          theme,
          colorScheme,
          isMobile,
        ),
        // Lista de tarjetas
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 24,
              vertical: 12,
            ),
            itemCount: descuentos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder:
                (context, i) =>
                    _buildDescuentoCard(descuentos[i], theme, colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildResumen(
    List<DescuentoEmpleadoEntity> descuentos,
    double totalDescuentos,
    double totalMontoTotal,
    double totalSaldo,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isMobile,
  ) {
    final mesNombre =
        _meses.firstWhere(
          (m) => m['num'] == _mesSeleccionado,
          orElse: () => {'nombre': '$_mesSeleccionado'},
        )['nombre'];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.08),
            colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: colorScheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Resumen — $mesNombre $_anioSeleccionado',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${descuentos.length} descuentos',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isMobile
              ? Column(
                children: [
                  _buildResumenItem(
                    'Monto descontado',
                    'Bs ${_formatAmount(totalDescuentos)}',
                    Icons.money_off,
                    colorScheme.error,
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildResumenItem(
                    'Monto total',
                    'Bs ${_formatAmount(totalMontoTotal)}',
                    Icons.account_balance,
                    colorScheme.onSurfaceVariant,
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildResumenItem(
                    'Saldo pendiente',
                    'Bs ${_formatAmount(totalSaldo)}',
                    Icons.account_balance_wallet,
                    colorScheme.tertiary,
                    theme,
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: _buildResumenItem(
                      'Monto descontado',
                      'Bs ${_formatAmount(totalDescuentos)}',
                      Icons.money_off,
                      colorScheme.error,
                      theme,
                    ),
                  ),
                  Expanded(
                    child: _buildResumenItem(
                      'Monto total',
                      'Bs ${_formatAmount(totalMontoTotal)}',
                      Icons.account_balance,
                      colorScheme.onSurfaceVariant,
                      theme,
                    ),
                  ),
                  Expanded(
                    child: _buildResumenItem(
                      'Saldo pendiente',
                      'Bs ${_formatAmount(totalSaldo)}',
                      Icons.account_balance_wallet,
                      colorScheme.tertiary,
                      theme,
                    ),
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescuentoCard(
    DescuentoEmpleadoEntity d,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final bool tieneCuotas = d.totalCuotas > 0;
    final color = _colorPorTipo(d.tipoDescuento, colorScheme);
    final icon = _iconPorTipo(d.tipoDescuento);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: tipo + estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        d.tipoDescuento,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildEstadoBadge(d.estadoDescuento, theme, colorScheme),
              ],
            ),
            const SizedBox(height: 10),
            // Descripción
            Text(
              d.descripcion,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Montos
            Row(
              children: [
                Expanded(
                  child: _buildMontoItem(
                    'Monto descontado',
                    '${d.moneda} ${_formatAmount(d.montoDescuento)}',
                    colorScheme.error,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildMontoItem(
                    'Monto total',
                    '${d.moneda} ${_formatAmount(d.montoTotal)}',
                    colorScheme.onSurfaceVariant,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildMontoItem(
                    'Saldo restante',
                    '${d.moneda} ${_formatAmount(d.saldoRestante)}',
                    colorScheme.tertiary,
                    theme,
                  ),
                ),
              ],
            ),
            // Cuotas (solo si aplica)
            if (tieneCuotas) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Cuota ${d.primeraCuotaMes} de ${d.totalCuotas}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMontoItem(
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoBadge(
    String estado,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isEjecutado = estado.toLowerCase() == 'ejecutado';
    final color = isEjecutado ? Colors.green : colorScheme.tertiary;
    final icon = isEjecutado ? Icons.check_circle : Icons.schedule;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            estado,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorPorTipo(String tipo, ColorScheme colorScheme) {
    switch (tipo.toLowerCase()) {
      case 'prestamo - planilla':
        return Colors.indigo;
      case 'anticipo':
        return Colors.orange;
      case 'atrasos':
        return colorScheme.error;
      case 'multa':
        return Colors.red.shade700;
      default:
        return colorScheme.secondary;
    }
  }

  IconData _iconPorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'prestamo - planilla':
        return Icons.account_balance;
      case 'anticipo':
        return Icons.monetization_on;
      case 'atrasos':
        return Icons.alarm_off;
      case 'multa':
        return Icons.gavel;
      default:
        return Icons.receipt;
    }
  }
}
