import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider local (scope aislado para que el estado se reinicie al entrar)
// ─────────────────────────────────────────────────────────────────────────────
final _pagosExtranjerosScreenProvider =
    StateNotifierProvider<PagosExtranjerosNotifier, PagosExtranjerosState>(
      (ref) => PagosExtranjerosNotifier(ref),
    );

final _numberFormat = NumberFormat('#,##0.00', 'es_BO');

// ─────────────────────────────────────────────────────────────────────────────
// Screen principal
// ─────────────────────────────────────────────────────────────────────────────
class PagosExtranjerosRegisterScreen extends ConsumerStatefulWidget {
  const PagosExtranjerosRegisterScreen({super.key});

  @override
  ConsumerState<PagosExtranjerosRegisterScreen> createState() =>
      _PagosExtranjerosRegisterScreenState();
}

class _PagosExtranjerosRegisterScreenState
    extends ConsumerState<PagosExtranjerosRegisterScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(_pagosExtranjerosScreenProvider);
    final notifier = ref.read(_pagosExtranjerosScreenProvider.notifier);
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final hPad = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final vPad = ResponsiveUtilsBosque.getVerticalPadding(context);
    final user = ref.read(userProvider);

    // Mostrar mensajes de éxito/error tras el rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mensajeExito != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: colorScheme.onPrimary),
                const SizedBox(width: 8),
                Expanded(child: Text(state.mensajeExito!)),
              ],
            ),
            backgroundColor: colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        notifier.limpiarMensajes();
        notifier.resetState();
      } else if (state.mensajeError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.onError),
                const SizedBox(width: 8),
                Expanded(child: Text(state.mensajeError!)),
              ],
            ),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        notifier.limpiarMensajes();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      // FAB solo en móvil/tablet; en desktop el botón vive en el sidebar
      floatingActionButton:
          isDesktop
              ? null
              : FloatingActionButton.extended(
                onPressed:
                    state.cargando
                        ? null
                        : () => _guardar(notifier, user?.codUsuario ?? 0),
                icon:
                    state.cargando
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        )
                        : const Icon(Icons.save_rounded),
                label: const Text('Guardar Solicitud'),
                backgroundColor:
                    state.cargando
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: const Text('Solicitud de Pago al Extranjero'),
        backgroundColor:
            isDesktop ? colorScheme.primaryContainer : colorScheme.surface,
        foregroundColor:
            isDesktop ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
        elevation: 0,
      ),
      body:
          state.cargando
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Guardando solicitud...',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
              : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: SingleChildScrollView(
                    // Padding inferior extra en móvil/tablet para que el FAB no tape contenido
                    padding: EdgeInsets.only(
                      left: hPad,
                      right: hPad,
                      top: vPad,
                      bottom: isDesktop ? vPad : vPad + 80,
                    ),
                    child:
                        isDesktop
                            ? _buildDesktopLayout(
                              context,
                              state,
                              notifier,
                              colorScheme,
                              vPad,
                              user?.codUsuario ?? 0,
                            )
                            : _buildMobileLayout(
                              context,
                              state,
                              notifier,
                              colorScheme,
                              isMobile,
                              vPad,
                              user?.codUsuario ?? 0,
                            ),
                  ),
                ),
              ),
    );
  }

  /// Layout de 2 columnas para desktop/web
  Widget _buildDesktopLayout(
    BuildContext context,
    PagosExtranjerosState state,
    PagosExtranjerosNotifier notifier,
    ColorScheme colorScheme,
    double vPad,
    int audUsuario,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: formulario
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _SectionCard(
                title: 'Datos Generales de la Solicitud',
                icon: Icons.description_rounded,
                child: _DatosGeneralesForm(
                  state: state,
                  notifier: notifier,
                  isMobile: false,
                ),
              ),
              SizedBox(height: vPad),
              _SectionCard(
                title: 'Proveedores y Facturas',
                icon: Icons.business_rounded,
                trailing: FilledButton.tonalIcon(
                  onPressed:
                      () => _mostrarDialogProveedor(
                        context,
                        notifier,
                        isMobile: false,
                        codEmpresa: state.empresaSeleccionada?.codEmpresa ?? 0,
                      ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar Proveedor'),
                ),
                child:
                    state.proveedores.isEmpty
                        ? const _EmptyState(
                          message: 'No hay proveedores agregados.',
                        )
                        : Column(
                          children: List.generate(
                            state.proveedores.length,
                            (i) => _ProveedorTile(
                              proveedor: state.proveedores[i],
                              index: i,
                              notifier: notifier,
                              colorScheme: colorScheme,
                              isMobile: false,
                              codEmpresa:
                                  state.empresaSeleccionada?.codEmpresa ?? 0,
                            ),
                          ),
                        ),
              ),
              SizedBox(height: vPad * 2),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Columna derecha: resumen + botón único de guardado
        SizedBox(
          width: 300,
          child: Column(
            children: [
              _ResumenMontos(
                state: state,
                colorScheme: colorScheme,
                showEvenEmpty: true,
              ),
              const SizedBox(height: 16),
              _GuardarButton(
                cargando: state.cargando,
                onPressed: () => _guardar(notifier, audUsuario),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Layout vertical para tablet/móvil
  Widget _buildMobileLayout(
    BuildContext context,
    PagosExtranjerosState state,
    PagosExtranjerosNotifier notifier,
    ColorScheme colorScheme,
    bool isMobile,
    double vPad,
    int audUsuario,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sección 1: Datos generales ──────────────────
        _SectionCard(
          title: 'Datos Generales de la Solicitud',
          icon: Icons.description_rounded,
          child: _DatosGeneralesForm(
            state: state,
            notifier: notifier,
            isMobile: isMobile,
          ),
        ),
        SizedBox(height: vPad),

        // ── Sección 2: Proveedores ──────────────────────
        _SectionCard(
          title: 'Proveedores y Facturas',
          icon: Icons.business_rounded,
          trailing: TextButton.icon(
            onPressed:
                () => _mostrarDialogProveedor(
                  context,
                  notifier,
                  isMobile: isMobile,
                  codEmpresa: state.empresaSeleccionada?.codEmpresa ?? 0,
                ),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Proveedor'),
          ),
          child:
              state.proveedores.isEmpty
                  ? const _EmptyState(message: 'No hay proveedores agregados.')
                  : Column(
                    children: List.generate(
                      state.proveedores.length,
                      (i) => _ProveedorTile(
                        proveedor: state.proveedores[i],
                        index: i,
                        notifier: notifier,
                        colorScheme: colorScheme,
                        isMobile: isMobile,
                        codEmpresa: state.empresaSeleccionada?.codEmpresa ?? 0,
                      ),
                    ),
                  ),
        ),
        SizedBox(height: vPad),

        // ── Resumen de montos ───────────────────────────
        if (state.proveedores.isNotEmpty)
          _ResumenMontos(
            state: state,
            colorScheme: colorScheme,
            showEvenEmpty: false,
          ),
        // El FAB del Scaffold cubre el guardado en móvil/tablet
        SizedBox(height: vPad * 2),
      ],
    );
  }

  void _guardar(PagosExtranjerosNotifier notifier, int audUsuario) {
    notifier.guardarSolicitud(audUsuario);
  }

  void _mostrarDialogProveedor(
    BuildContext context,
    PagosExtranjerosNotifier notifier, {
    required bool isMobile,
    required int codEmpresa,
    int? indexEditar,
    ProveedorFormItem? proveedorActual,
  }) {
    showDialog(
      context: context,
      builder:
          (ctx) => _ProveedorDialog(
            notifier: notifier,
            indexEditar: indexEditar,
            proveedorActual: proveedorActual,
            isMobile: isMobile,
            codEmpresa: codEmpresa,
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Datos generales del formulario
// ─────────────────────────────────────────────────────────────────────────────
class _DatosGeneralesForm extends StatelessWidget {
  final PagosExtranjerosState state;
  final PagosExtranjerosNotifier notifier;
  final bool isMobile;

  const _DatosGeneralesForm({
    required this.state,
    required this.notifier,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final empresaDropdown = _buildEmpresaDropdown(context, colorScheme);
    final fechaField = _buildFechaField(context, colorScheme);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [empresaDropdown, const SizedBox(height: 16), fechaField],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: empresaDropdown),
        const SizedBox(width: 16),
        Expanded(child: fechaField),
      ],
    );
  }

  Widget _buildEmpresaDropdown(BuildContext context, ColorScheme colorScheme) {
    if (state.cargandoEmpresas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    return DropdownButtonFormField<EmpresaEntity>(
      value: state.empresaSeleccionada,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Empresa *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business_outlined),
      ),
      hint: const Text('Seleccione empresa'),
      items:
          state.empresas
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: (empresa) {
        if (empresa != null) notifier.setEmpresa(empresa);
      },
    );
  }

  Widget _buildFechaField(BuildContext context, ColorScheme colorScheme) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(state.fechaSolicitud);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: state.fechaSolicitud,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) notifier.setFechaSolicitud(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de Solicitud',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(formattedDate),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Tile de un proveedor con sus detalles
// ─────────────────────────────────────────────────────────────────────────────
class _ProveedorTile extends StatelessWidget {
  final ProveedorFormItem proveedor;
  final int index;
  final PagosExtranjerosNotifier notifier;
  final ColorScheme colorScheme;
  final bool isMobile;
  final int codEmpresa;

  const _ProveedorTile({
    required this.proveedor,
    required this.index,
    required this.notifier,
    required this.colorScheme,
    required this.isMobile,
    required this.codEmpresa,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          proveedor.cardCode.isEmpty
              ? 'Proveedor ${index + 1}'
              : proveedor.cardCode,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          proveedor.cardName.isEmpty ? 'Sin nombre' : proveedor.cardName,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Total a pagar
            if (!isMobile)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text(
                    'USD ${_numberFormat.format(proveedor.totalAPagarUsd)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: colorScheme.secondaryContainer,
                ),
              ),
            IconButton(
              tooltip: 'Editar proveedor',
              icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => _ProveedorDialog(
                        notifier: notifier,
                        indexEditar: index,
                        proveedorActual: proveedor,
                        isMobile: isMobile,
                        codEmpresa: codEmpresa,
                      ),
                );
              },
            ),
            IconButton(
              tooltip: 'Eliminar proveedor',
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: () => _confirmarEliminar(context),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info adicional
                if (proveedor.obs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.notes_outlined, size: 16),
                        const SizedBox(width: 4),
                        Expanded(child: Text(proveedor.obs)),
                      ],
                    ),
                  ),
                // Totales móvil
                if (isMobile) _ResumenProveedorRow(proveedor: proveedor),

                // Lista de detalles
                _DetallesList(
                  proveedorIndex: index,
                  proveedor: proveedor,
                  notifier: notifier,
                  colorScheme: colorScheme,
                  isMobile: isMobile,
                  codEmpresa: codEmpresa,
                ),

                // Botón agregar factura
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => _DetalleDialog(
                              notifier: notifier,
                              proveedorIndex: index,
                              isMobile: isMobile,
                              codEmpresa: codEmpresa,
                            ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Factura'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar Proveedor'),
            content: Text(
              '¿Está seguro de eliminar al proveedor "${proveedor.cardName}"?\nSe eliminarán también sus ${proveedor.detalles.length} factura(s).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  notifier.eliminarProveedor(index);
                  Navigator.pop(ctx);
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Resumen de totales de un proveedor (para móvil)
// ─────────────────────────────────────────────────────────────────────────────
class _ResumenProveedorRow extends StatelessWidget {
  final ProveedorFormItem proveedor;
  const _ResumenProveedorRow({required this.proveedor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _MontoChip(label: 'Facturas', valor: proveedor.totalFacturasUsd),
          _MontoChip(label: 'Amortizado', valor: proveedor.totalAmortizadoUsd),
          _MontoChip(
            label: 'A Pagar',
            valor: proveedor.totalAPagarUsd,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _MontoChip extends StatelessWidget {
  final String label;
  final double valor;
  final bool highlight;
  const _MontoChip({
    required this.label,
    required this.valor,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(
        '$label: USD ${_numberFormat.format(valor)}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor:
          highlight
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Lista de detalles (facturas) de un proveedor
// ─────────────────────────────────────────────────────────────────────────────
class _DetallesList extends StatelessWidget {
  final int proveedorIndex;
  final ProveedorFormItem proveedor;
  final PagosExtranjerosNotifier notifier;
  final ColorScheme colorScheme;
  final bool isMobile;
  final int codEmpresa;

  const _DetallesList({
    required this.proveedorIndex,
    required this.proveedor,
    required this.notifier,
    required this.colorScheme,
    required this.isMobile,
    required this.codEmpresa,
  });

  @override
  Widget build(BuildContext context) {
    if (proveedor.detalles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Sin facturas. Use el botón "Agregar Factura".',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }
    return Column(
      children: [
        // Encabezado
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Facturas (${proveedor.detalles.length})',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...List.generate(proveedor.detalles.length, (di) {
          final det = proveedor.detalles[di];
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.secondaryContainer,
                child: Text(
                  '${di + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              title: Text(
                '${det.tipoDocumento} ${det.numeroDocumento}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'USD ${_numberFormat.format(det.montoAPagarUsd)}'
                '${det.concepto.isNotEmpty ? ' · ${det.concepto}' : ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Editar factura',
                    icon: Icon(
                      Icons.edit_note_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (_) => _DetalleDialog(
                              notifier: notifier,
                              proveedorIndex: proveedorIndex,
                              isMobile: isMobile,
                              indexEditar: di,
                              detalleActual: det,
                              codEmpresa: codEmpresa,
                            ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Eliminar factura',
                    icon: Icon(Icons.close, size: 20, color: colorScheme.error),
                    onPressed:
                        () => notifier.eliminarDetalle(proveedorIndex, di),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Resumen global de montos
// ─────────────────────────────────────────────────────────────────────────────
class _ResumenMontos extends StatelessWidget {
  final PagosExtranjerosState state;
  final ColorScheme colorScheme;

  /// Muestra el widget aunque no haya proveedores (útil en desktop como sidebar)
  final bool showEvenEmpty;

  const _ResumenMontos({
    required this.state,
    required this.colorScheme,
    this.showEvenEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalFacturas = state.proveedores.fold<double>(
      0,
      (s, p) => s + p.totalFacturasUsd,
    );
    final totalAmortizado = state.proveedores.fold<double>(
      0,
      (s, p) => s + p.totalAmortizadoUsd,
    );
    final sinDatos = state.proveedores.isEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resumen de la Solicitud',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            Divider(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
              height: 24,
            ),
            if (sinDatos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Agregue proveedores y facturas para ver el resumen.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 13,
                  ),
                ),
              )
            else ...[
              _ResumenRow(
                label: 'Proveedores',
                valor: state.proveedores.length.toDouble(),
                colorScheme: colorScheme,
                isCount: true,
              ),
              const SizedBox(height: 4),
              _ResumenRow(
                label: 'Total Facturas',
                valor: totalFacturas,
                colorScheme: colorScheme,
              ),
              _ResumenRow(
                label: 'Total Amortizado',
                valor: totalAmortizado,
                colorScheme: colorScheme,
              ),
              Divider(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                height: 20,
              ),
              _ResumenRow(
                label: 'Total a Pagar',
                valor: state.montoTotalSolicitud,
                colorScheme: colorScheme,
                bold: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResumenRow extends StatelessWidget {
  final String label;
  final double valor;
  final ColorScheme colorScheme;
  final bool bold;

  /// Si es true muestra como número entero (ej: cantidad de proveedores)
  final bool isCount;

  const _ResumenRow({
    required this.label,
    required this.valor,
    required this.colorScheme,
    this.bold = false,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 17 : 13,
      color: colorScheme.onPrimaryContainer,
    );
    final valorText =
        isCount
            ? valor.toInt().toString()
            : 'USD ${_numberFormat.format(valor)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(
            valorText,
            style: style.copyWith(
              color:
                  bold ? colorScheme.primary : colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Botón de guardado único (usado en sidebar desktop)
// ─────────────────────────────────────────────────────────────────────────────
class _GuardarButton extends StatelessWidget {
  final bool cargando;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  const _GuardarButton({
    required this.cargando,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: cargando ? null : onPressed,
        icon:
            cargando
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
                : const Icon(Icons.save_rounded),
        label: Text(cargando ? 'Guardando...' : 'Guardar Solicitud'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget auxiliar: tarjeta de sección
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final pad = isDesktop ? 24.0 : 16.0;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktop ? 17 : 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget auxiliar: estado vacío
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog: Agregar / Editar Proveedor
// ─────────────────────────────────────────────────────────────────────────────
class _ProveedorDialog extends ConsumerStatefulWidget {
  final PagosExtranjerosNotifier notifier;
  final int? indexEditar;
  final ProveedorFormItem? proveedorActual;
  final bool isMobile;
  final int codEmpresa;

  const _ProveedorDialog({
    required this.notifier,
    this.indexEditar,
    this.proveedorActual,
    required this.isMobile,
    required this.codEmpresa,
  });

  @override
  ConsumerState<_ProveedorDialog> createState() => _ProveedorDialogState();
}

class _ProveedorDialogState extends ConsumerState<_ProveedorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _obsCtrl;
  ProveedorEmpresaEntity? _proveedorSeleccionado;
  String? _duplicadoError;

  @override
  void initState() {
    super.initState();
    _obsCtrl = TextEditingController(text: widget.proveedorActual?.obs ?? '');
    // Pre-seleccionar proveedor en modo edición
    if (widget.proveedorActual != null &&
        widget.proveedorActual!.cardCode.isNotEmpty) {
      _proveedorSeleccionado = ProveedorEmpresaEntity(
        cardCode: widget.proveedorActual!.cardCode,
        cardName: widget.proveedorActual!.cardName,
      );
    }
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_proveedorSeleccionado == null) return;

    final proveedor = ProveedorFormItem(
      cardCode: _proveedorSeleccionado!.cardCode,
      cardName: _proveedorSeleccionado!.cardName,
      obs: _obsCtrl.text.trim(),
      detalles: widget.proveedorActual?.detalles ?? [],
    );

    bool ok;
    if (widget.indexEditar != null) {
      ok = widget.notifier.actualizarProveedor(widget.indexEditar!, proveedor);
    } else {
      ok = widget.notifier.agregarProveedor(proveedor);
    }

    if (!ok) {
      setState(() {
        _duplicadoError =
            'Este proveedor ya está en la lista. No se permiten duplicados.';
      });
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdicion = widget.indexEditar != null;
    final colorScheme = Theme.of(context).colorScheme;

    final proveedoresAsync = ref.watch(
      proveedoresXEmpresaProvider(widget.codEmpresa),
    );

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      title: Row(
        children: [
          Icon(
            isEdicion ? Icons.edit_outlined : Icons.business_outlined,
            color: colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(isEdicion ? 'Editar Proveedor' : 'Agregar Proveedor'),
        ],
      ),
      content: SizedBox(
        width: widget.isMobile ? double.maxFinite : 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Buscador de proveedor ────────────────────────────
              proveedoresAsync.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                error:
                    (_, __) => Text(
                      'Error al cargar proveedores',
                      style: TextStyle(color: colorScheme.error),
                    ),
                data:
                    (lista) => DropdownSearch<ProveedorEmpresaEntity>(
                      selectedItem: _proveedorSeleccionado,
                      items: lista,
                      itemAsString: (p) => '${p.cardCode} - ${p.cardName}',
                      onChanged:
                          (p) => setState(() {
                            _proveedorSeleccionado = p;
                            _duplicadoError = null; // limpiar error al cambiar
                          }),
                      validator:
                          (_) =>
                              _proveedorSeleccionado == null
                                  ? 'Seleccione un proveedor'
                                  : null,
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Proveedor *',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.business_outlined),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        fit: FlexFit.loose,
                        constraints: const BoxConstraints(maxHeight: 320),
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            labelText: 'Buscar por código o nombre',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                    ),
              ),
              // Error de proveedor duplicado
              if (_duplicadoError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _duplicadoError!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Observaciones',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: Text(isEdicion ? 'Actualizar' : 'Agregar'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog: Agregar / Editar Detalle (Factura)
// ─────────────────────────────────────────────────────────────────────────────
class _DetalleDialog extends ConsumerStatefulWidget {
  final PagosExtranjerosNotifier notifier;
  final int proveedorIndex;
  final int? indexEditar;
  final DetalleFormItem? detalleActual;
  final bool isMobile;
  final int codEmpresa;

  const _DetalleDialog({
    required this.notifier,
    required this.proveedorIndex,
    this.indexEditar,
    this.detalleActual,
    required this.isMobile,
    required this.codEmpresa,
  });

  @override
  ConsumerState<_DetalleDialog> createState() => _DetalleDialogState();
}

class _DetalleDialogState extends ConsumerState<_DetalleDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nroDocCtrl;
  late final TextEditingController _codImportCtrl;
  late final TextEditingController _montoFacturaCtrl;
  late final TextEditingController _montoAmortCtrl;
  late final TextEditingController _montoPagarCtrl;
  late final TextEditingController _conceptoCtrl;
  late final TextEditingController _obsCtrl;

  late DateTime _fechaFactura;
  late DateTime _fechaVencimiento;

  String? _selectedTipoDoc;
  DetalleSolicitudEntity? _selectedFacturaSap;
  bool _initialSelectionDone = false;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final d = widget.detalleActual;
    _selectedTipoDoc =
        d != null && d.tipoDocumento.isNotEmpty ? d.tipoDocumento : null;
    _nroDocCtrl = TextEditingController(text: d?.numeroDocumento ?? '');
    _codImportCtrl = TextEditingController(text: d?.codigoImportacion ?? '');
    _montoFacturaCtrl = TextEditingController(
      text: d != null ? d.montoFacturaUsd.toStringAsFixed(2) : '',
    );
    _montoAmortCtrl = TextEditingController(
      text: d != null ? d.montoAmortizadoUsd.toStringAsFixed(2) : '',
    );
    _montoPagarCtrl = TextEditingController(
      text: d != null ? d.montoAPagarUsd.toStringAsFixed(2) : '',
    );
    _conceptoCtrl = TextEditingController(text: d?.concepto ?? '');
    _obsCtrl = TextEditingController(text: d?.obs ?? '');
    _fechaFactura = d?.fechaFactura ?? DateTime.now();
    _fechaVencimiento = d?.fechaVencimiento ?? DateTime.now();
  }

  @override
  void dispose() {
    _nroDocCtrl.dispose();
    _codImportCtrl.dispose();
    _montoFacturaCtrl.dispose();
    _montoAmortCtrl.dispose();
    _montoPagarCtrl.dispose();
    _conceptoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context, {
    required bool esFechaFactura,
  }) async {
    final initial = esFechaFactura ? _fechaFactura : _fechaVencimiento;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (esFechaFactura) {
          _fechaFactura = picked;
        } else {
          _fechaVencimiento = picked;
        }
      });
    }
  }

  void _calcularMontoPagar() {
    final factura = double.tryParse(_montoFacturaCtrl.text) ?? 0.0;
    final amort = double.tryParse(_montoAmortCtrl.text) ?? 0.0;
    _montoPagarCtrl.text = (factura - amort).toStringAsFixed(2);
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTipoDoc == null || _selectedTipoDoc!.isEmpty) return;

    final detalle = DetalleFormItem(
      tipoDocumento: _selectedTipoDoc!,
      numeroDocumento: _nroDocCtrl.text.trim(),
      facturaProvSap: _selectedFacturaSap?.facturaProvSap ?? 0,
      codigoImportacion: _codImportCtrl.text.trim(),
      montoFacturaUsd: double.tryParse(_montoFacturaCtrl.text) ?? 0.0,
      montoAmortizadoUsd: double.tryParse(_montoAmortCtrl.text) ?? 0.0,
      montoAPagarUsd: double.tryParse(_montoPagarCtrl.text) ?? 0.0,
      fechaFactura: _fechaFactura,
      fechaVencimiento: _fechaVencimiento,
      concepto: _conceptoCtrl.text.trim(),
      obs: _obsCtrl.text.trim(),
    );

    if (widget.indexEditar != null) {
      widget.notifier.actualizarDetalle(
        widget.proveedorIndex,
        widget.indexEditar!,
        detalle,
      );
    } else {
      widget.notifier.agregarDetalle(widget.proveedorIndex, detalle);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdicion = widget.indexEditar != null;
    final colorScheme = Theme.of(context).colorScheme;

    final facturasAsync = ref.watch(
      facProvYOrdCompraProvider(widget.codEmpresa),
    );
    final facturas = facturasAsync.valueOrNull ?? [];
    final isLoadingFacturas = facturasAsync.isLoading;
    final errorFacturas =
        facturasAsync.hasError
            ? facturasAsync.error.toString().replaceFirst('Exception: ', '')
            : null;

    // Pre-selección en modo edición: una sola vez cuando la lista carga.
    if (!_initialSelectionDone && facturas.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          final sap = widget.detalleActual?.facturaProvSap ?? 0;
          if (sap != 0) {
            _selectedFacturaSap =
                facturas.where((e) => e.facturaProvSap == sap).firstOrNull;
          }
          _initialSelectionDone = true;
        });
      });
    } else if (!_initialSelectionDone && !isLoadingFacturas) {
      _initialSelectionDone = true;
    }

    // Valores únicos de tipo documento para el dropdown
    final tiposDoc =
        facturas.map((e) => e.tipoDocumento).toSet().toList()..sort();
    final tipoDocValue =
        tiposDoc.contains(_selectedTipoDoc) ? _selectedTipoDoc : null;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.isMobile ? double.maxFinite : 680,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdicion ? 'Editar Factura' : 'Agregar Factura',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Formulario
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Fila 1: Tipo Documento + Número de Documento ──
                      _buildRow(
                        widget.isMobile,
                        isLoadingFacturas
                            ? const _FieldLoading(label: 'Tipo Documento *')
                            : errorFacturas != null
                            ? _FieldError(
                              label: 'Tipo Documento *',
                              error: errorFacturas,
                              onRetry:
                                  () => ref.invalidate(
                                    facProvYOrdCompraProvider(
                                      widget.codEmpresa,
                                    ),
                                  ),
                            )
                            : DropdownButtonFormField<String>(
                              value: tipoDocValue,
                              decoration: const InputDecoration(
                                labelText: 'Tipo Documento *',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  tiposDoc
                                      .map(
                                        (t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _selectedTipoDoc = v),
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Requerido'
                                          : null,
                            ),
                        TextFormField(
                          controller: _nroDocCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Número de Documento *',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Requerido'
                                      : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Fila 2: Factura Prov. SAP (dropdown buscable) + Cód. Importación ──
                      _buildRow(
                        widget.isMobile,
                        isLoadingFacturas
                            ? const _FieldLoading(label: 'Factura Prov. SAP')
                            : errorFacturas != null
                            ? _FieldError(
                              label: 'Factura Prov. SAP',
                              error: errorFacturas,
                              onRetry:
                                  () => ref.invalidate(
                                    facProvYOrdCompraProvider(
                                      widget.codEmpresa,
                                    ),
                                  ),
                            )
                            : DropdownSearch<DetalleSolicitudEntity>(
                              items: facturas,
                              selectedItem: _selectedFacturaSap,
                              itemAsString: (e) => e.facturaProvSap.toString(),
                              filterFn:
                                  (item, filter) => item.facturaProvSap
                                      .toString()
                                      .contains(filter.trim()),
                              onChanged:
                                  (item) => setState(() {
                                    _selectedFacturaSap = item;
                                    // Sincroniza tipo doc automáticamente
                                    if (item != null) {
                                      _selectedTipoDoc = item.tipoDocumento;
                                    }
                                  }),
                              dropdownDecoratorProps:
                                  const DropDownDecoratorProps(
                                    dropdownSearchDecoration: InputDecoration(
                                      labelText: 'Factura Prov. SAP',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchFieldProps: const TextFieldProps(
                                  decoration: InputDecoration(
                                    hintText: 'Buscar número...',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.search),
                                    isDense: true,
                                  ),
                                ),
                                emptyBuilder:
                                    (_, __) => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('Sin resultados'),
                                      ),
                                    ),
                              ),
                            ),
                        TextFormField(
                          controller: _codImportCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cód. Importación',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Fila 3: Fechas ──
                      _buildRow(
                        widget.isMobile,
                        InkWell(
                          onTap: () => _pickDate(context, esFechaFactura: true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha Factura',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(_dateFormat.format(_fechaFactura)),
                          ),
                        ),
                        InkWell(
                          onTap:
                              () => _pickDate(context, esFechaFactura: false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha Vencimiento',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.event_outlined),
                            ),
                            child: Text(_dateFormat.format(_fechaVencimiento)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Monto factura ──
                      TextFormField(
                        controller: _montoFacturaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Monto Factura (USD) *',
                          border: OutlineInputBorder(),
                          prefixText: 'USD ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (_) => setState(() => _calcularMontoPagar()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(v) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      // ── Fila 4: Amortizado + A pagar ──
                      _buildRow(
                        widget.isMobile,
                        TextFormField(
                          controller: _montoAmortCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Monto Amortizado (USD)',
                            border: OutlineInputBorder(),
                            prefixText: 'USD ',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          onChanged:
                              (_) => setState(() => _calcularMontoPagar()),
                        ),
                        TextFormField(
                          controller: _montoPagarCtrl,
                          decoration: InputDecoration(
                            labelText: 'Monto a Pagar (USD)',
                            border: const OutlineInputBorder(),
                            prefixText: 'USD ',
                            filled: true,
                            fillColor: colorScheme.primaryContainer.withValues(
                              alpha: 0.35,
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Concepto ──
                      TextFormField(
                        controller: _conceptoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Concepto',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Observaciones ──
                      TextFormField(
                        controller: _obsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Acciones
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _guardar,
                    child: Text(isEdicion ? 'Actualizar' : 'Agregar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(bool isMobile, Widget left, Widget right) {
    if (isMobile) {
      return Column(children: [left, const SizedBox(height: 12), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: placeholder de carga para un campo
// ─────────────────────────────────────────────────────────────────────────────
class _FieldLoading extends StatelessWidget {
  final String label;
  const _FieldLoading({required this.label});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: const SizedBox(height: 18, child: LinearProgressIndicator()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: placeholder de error para un campo (con botón reintentar)
// ─────────────────────────────────────────────────────────────────────────────
class _FieldError extends StatelessWidget {
  final String label;
  final String error;
  final VoidCallback onRetry;
  const _FieldError({
    required this.label,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: error,
        suffixIcon: IconButton(
          tooltip: 'Reintentar',
          icon: Icon(Icons.refresh, color: colorScheme.error),
          onPressed: onRetry,
        ),
      ),
      child: const SizedBox(height: 18),
    );
  }
}
