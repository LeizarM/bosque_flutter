import 'dart:async';

import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/detalle_solicitud_entity.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/proveedor_empresa_entity.dart';
import 'package:bosque_flutter/presentation/widgets/pagos-extranjeros/tpex_estado_ui.dart';
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
    final user = ref.watch(userProvider);

    // Mostrar mensajes de éxito/error tras el rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.mensajeExito != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.mensajeExito!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2E7D32),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        notifier.limpiarMensajes();
        notifier.resetState();
      } else if (state.mensajeError != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.mensajeError!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Cerrar',
                textColor: Colors.white,
                onPressed: () {},
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
              : Badge(
                isLabelVisible: state.proveedores.isNotEmpty,
                label: Text('${state.proveedores.length}'),
                child: FloatingActionButton.extended(
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
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // Barra de progreso sutil
          LinearProgressIndicator(
            value: _calcularProgreso(state),
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
            minHeight: 3,
          ),
          Expanded(
            child:
                state.cargando
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(
                              strokeWidth: 5,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Guardando solicitud...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor espere',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                    : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: SingleChildScrollView(
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
          ),
        ],
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
              _WorkflowStepsCard(state: state, colorScheme: colorScheme),
              SizedBox(height: vPad),
              _SectionCard(
                title: 'Datos Generales de la Solicitud',
                icon: Icons.description_rounded,
                stepNumber: 1,
                isComplete: state.empresaSeleccionada != null,
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
                stepNumber: 2,
                isComplete:
                    state.proveedores.isNotEmpty &&
                    state.proveedores.every((p) => p.detalles.isNotEmpty),
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
                          hint:
                              'Use el botón "Agregar Proveedor" para comenzar.',
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
        _WorkflowStepsCard(state: state, colorScheme: colorScheme),
        SizedBox(height: vPad),

        // ── Sección 1: Datos generales ──────────────────
        _SectionCard(
          title: 'Datos Generales de la Solicitud',
          icon: Icons.description_rounded,
          stepNumber: 1,
          isComplete: state.empresaSeleccionada != null,
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
          stepNumber: 2,
          isComplete:
              state.proveedores.isNotEmpty &&
              state.proveedores.every((p) => p.detalles.isNotEmpty),
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
                  ? const _EmptyState(
                    message: 'No hay proveedores agregados.',
                    hint:
                        'Primero seleccione una empresa, luego agregue proveedores.',
                  )
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

  double _calcularProgreso(PagosExtranjerosState state) {
    int pasos = 0;
    if (state.empresaSeleccionada != null) pasos++;
    if (state.proveedores.isNotEmpty) pasos++;
    if (state.proveedores.isNotEmpty &&
        state.proveedores.every((p) => p.detalles.isNotEmpty)) {
      pasos++;
    }
    return pasos / 3.0;
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
// Widget: Banner de progreso por pasos
// ─────────────────────────────────────────────────────────────────────────────
class _WorkflowStepsCard extends StatelessWidget {
  final PagosExtranjerosState state;
  final ColorScheme colorScheme;
  const _WorkflowStepsCard({required this.state, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final step1 = state.empresaSeleccionada != null;
    final step2 = state.proveedores.isNotEmpty;
    final step3 =
        step2 && state.proveedores.every((p) => p.detalles.isNotEmpty);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          _StepDot(label: 'Empresa', done: step1, colorScheme: colorScheme),
          _StepConnector(done: step1, colorScheme: colorScheme),
          _StepDot(label: 'Proveedores', done: step2, colorScheme: colorScheme),
          _StepConnector(done: step2, colorScheme: colorScheme),
          _StepDot(label: 'Facturas', done: step3, colorScheme: colorScheme),
          _StepConnector(done: step3, colorScheme: colorScheme),
          _StepDot(
            label: 'Listo',
            done: step3,
            last: true,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final bool done;
  final bool last;
  final ColorScheme colorScheme;
  const _StepDot({
    required this.label,
    required this.done,
    this.last = false,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    const doneColor = Color(0xFF2E7D32);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? doneColor : colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: done ? doneColor : colorScheme.outline,
              width: 2,
            ),
          ),
          child:
              done
                  ? const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  )
                  : Icon(
                    Icons.circle_outlined,
                    color: colorScheme.outline,
                    size: 12,
                  ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: done ? FontWeight.w600 : FontWeight.normal,
            color: done ? doneColor : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool done;
  final ColorScheme colorScheme;
  const _StepConnector({required this.done, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 2,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF2E7D32) : colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
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
    // Campo "Proyecto SAP" oculto a pedido (se conserva el código por si se reactiva).
    // final projectField = _buildProjectField(context, colorScheme);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          empresaDropdown,
          const SizedBox(height: 16),
          fechaField,
          // const SizedBox(height: 16),
          // projectField,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: empresaDropdown),
            const SizedBox(width: 16),
            Expanded(child: fechaField),
          ],
        ),
        // const SizedBox(height: 16),
        // projectField,
      ],
    );
  }

  // ignore: unused_element
  Widget _buildProjectField(BuildContext context, ColorScheme colorScheme) {
    return TextFormField(
      initialValue: state.project,
      decoration: InputDecoration(
        labelText: 'Proyecto SAP',
        hintText: 'Código del proyecto (opcional)',
        helperText:
            'Una solicitud agrupa pagos de un mismo proyecto. Déjelo vacío si no aplica.',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.work_outline),
        suffixIcon:
            state.project.isNotEmpty
                ? const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                )
                : null,
      ),
      onChanged: (val) => notifier.setProject(val.trim()),
    );
  }

  Widget _buildEmpresaDropdown(BuildContext context, ColorScheme colorScheme) {
    if (state.cargandoEmpresas) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Empresa *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.business_outlined),
        ),
        child: const SizedBox(height: 20, child: LinearProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<EmpresaEntity>(
          value: state.empresaSeleccionada,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Empresa *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.business_outlined),
            suffixIcon:
                state.empresaSeleccionada != null
                    ? const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                    )
                    : null,
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
        ),
        if (state.empresaSeleccionada != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 4),
                Text(
                  'Los proveedores se filtran por esta empresa',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
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
    final hasFacturas = proveedor.detalles.isNotEmpty;
    final statusColor =
        hasFacturas ? const Color(0xFF2E7D32) : Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              hasFacturas
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
                  : Colors.orange.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proveedor.cardCode.isEmpty
                        ? 'Proveedor ${index + 1}'
                        : proveedor.cardCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    proveedor.cardName.isEmpty
                        ? 'Sin nombre'
                        : proveedor.cardName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasFacturas
                          ? Icons.receipt_long_rounded
                          : Icons.warning_amber_rounded,
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasFacturas
                          ? '${proveedor.detalles.length} factura${proveedor.detalles.length == 1 ? '' : 's'}'
                          : 'Sin facturas',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile && proveedor.detalles.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'USD ${_numberFormat.format(proveedor.totalAPagarUsd)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar proveedor',
              icon: Icon(
                Icons.edit_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
              ),
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
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Eliminar proveedor',
              icon: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: 20,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer.withValues(
                  alpha: 0.4,
                ),
              ),
              onPressed: () => _confirmarEliminar(context),
            ),
          ],
        ),
        children: [
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen de montos en tarjetas horizontales
                if (proveedor.detalles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _MiniStatCard(
                          label: 'Facturas',
                          value:
                              'USD ${_numberFormat.format(proveedor.totalFacturasUsd)}',
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        _MiniStatCard(
                          label: 'Amortizado',
                          value:
                              'USD ${_numberFormat.format(proveedor.totalAmortizadoUsd)}',
                          color: colorScheme.tertiaryContainer,
                          textColor: colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 8),
                        _MiniStatCard(
                          label: 'A Pagar',
                          value:
                              'USD ${_numberFormat.format(proveedor.totalAPagarUsd)}',
                          color: colorScheme.primaryContainer,
                          textColor: colorScheme.onPrimaryContainer,
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                // Info adicional
                if (proveedor.obs.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                          Icons.notes_outlined,
                          size: 15,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            proveedor.obs,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                const SizedBox(height: 8),
                OutlinedButton.icon(
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
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Agregar Factura'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final bool bold;
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
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
        child: _EmptyState(
          message: 'Sin facturas registradas.',
          hint:
              'Use "Agregar Factura" para añadir documentos a este proveedor.',
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
      fontFeatures: tpexTabularFigures,
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
  final int? stepNumber;
  final bool isComplete;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.stepNumber,
    this.isComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final pad = isDesktop ? 24.0 : 16.0;
    final completedColor = const Color(0xFF2E7D32);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isComplete
                  ? completedColor.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isComplete ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Step number or complete check
                if (stepNumber != null)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child:
                        isComplete
                            ? Container(
                              key: const ValueKey('check'),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: completedColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                            : Container(
                              key: const ValueKey('step'),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$stepNumber',
                                  style: TextStyle(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                  )
                else
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isDesktop ? 17 : 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (isComplete)
                        Text(
                          'Completado',
                          style: TextStyle(
                            fontSize: 11,
                            color: completedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              color:
                  isComplete
                      ? completedColor.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant,
              height: 1,
            ),
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
  final String? hint;
  const _EmptyState({required this.message, this.hint});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 36,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                style: TextStyle(
                  color: colorScheme.outline,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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

  // Búsqueda por proyecto (debounce: cada consulta dispara OPENQUERY a SAP)
  final _proyectoCtrl = TextEditingController();
  Timer? _proyectoDebounce;
  String _proyectoQuery = '';
  static const _proyectoMinChars = 3;

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
    _proyectoDebounce?.cancel();
    _proyectoCtrl.dispose();
    super.dispose();
  }

  void _onProyectoChanged(String value) {
    _proyectoDebounce?.cancel();
    _proyectoDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final q = value.trim();
      setState(() {
        _proyectoQuery = q.length >= _proyectoMinChars ? q : '';
      });
    });
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
      // DocTotal del documento SAP (lo trae el picker). Antes no se copiaba y
      // quedaba en 0; ahora se persiste para reflejar el total real del doc.
      montoTotalDocumento: _selectedFacturaSap?.montoTotalDocumento ?? 0.0,
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

    // Con búsqueda por proyecto activa se consulta SAP (ACCION C);
    // sin búsqueda, la lista completa por empresa (ACCION A).
    final buscandoPorProyecto = _proyectoQuery.isNotEmpty;
    final facturasAsync =
        buscandoPorProyecto
            ? ref.watch(
              facProvYOrdCompraProyectoProvider((
                codEmpresa: widget.codEmpresa,
                project: _proyectoQuery,
              )),
            )
            : ref.watch(facProvYOrdCompraProvider(widget.codEmpresa));
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
                      // ── Buscador por proyecto (debounce 500ms, consulta SAP) ──
                      TextField(
                        controller: _proyectoCtrl,
                        onChanged: _onProyectoChanged,
                        decoration: InputDecoration(
                          labelText: 'Buscar por proyecto',
                          hintText:
                              'Código de proyecto SAP (mín. $_proyectoMinChars caracteres)',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon:
                              _proyectoCtrl.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _proyectoDebounce?.cancel();
                                      _proyectoCtrl.clear();
                                      setState(() => _proyectoQuery = '');
                                    },
                                  )
                                  : null,
                          helperText:
                              buscandoPorProyecto
                                  ? '${facturas.length} documento(s) del proyecto "$_proyectoQuery"'
                                  : 'Filtra facturas/OC por proyecto SAP',
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Fila 1: Factura Prov. SAP (buscable) + Nro. Documento Proveedor ──
                      _buildRow(
                        widget.isMobile,
                        isLoadingFacturas
                            ? const _FieldLoading(label: 'Factura Prov. SAP')
                            : errorFacturas != null
                            ? _FieldError(
                              label: 'Factura Prov. SAP',
                              error: errorFacturas,
                              onRetry:
                                  () =>
                                      buscandoPorProyecto
                                          ? ref.invalidate(
                                            facProvYOrdCompraProyectoProvider((
                                              codEmpresa: widget.codEmpresa,
                                              project: _proyectoQuery,
                                            )),
                                          )
                                          : ref.invalidate(
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
                                    // FIX: auto-poblar la factura desde el
                                    // documento SAP elegido. Antes solo se
                                    // copiaba el tipo de documento, dejando que el
                                    // usuario re-tecleara Nro/Monto/fechas que SAP
                                    // ya conoce (y Tipo es read-only → si no se
                                    // sembraba quedaba imposible de completar).
                                    if (item != null) {
                                      _selectedTipoDoc = item.tipoDocumento;
                                      _nroDocCtrl.text =
                                          item.numeroDocumento.isNotEmpty
                                              ? item.numeroDocumento
                                              : item.facturaProvSap.toString();
                                      _codImportCtrl.text =
                                          item.codigoImportacion;
                                      final montoDoc =
                                          item.montoFacturaUsd > 0
                                              ? item.montoFacturaUsd
                                              : item.montoTotalDocumento;
                                      if (montoDoc > 0) {
                                        _montoFacturaCtrl.text = montoDoc
                                            .toStringAsFixed(2);
                                      }
                                      _montoAmortCtrl.text =
                                          item.montoAmortizadoUsd > 0
                                              ? item.montoAmortizadoUsd
                                                  .toStringAsFixed(2)
                                              : '';
                                      if (item.concepto.isNotEmpty) {
                                        _conceptoCtrl.text = item.concepto;
                                      }
                                      if (item.fechaFactura.year > 2000) {
                                        _fechaFactura = item.fechaFactura;
                                      }
                                      if (item.fechaVencimiento.year > 2000) {
                                        _fechaVencimiento =
                                            item.fechaVencimiento;
                                      }
                                      _calcularMontoPagar();
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
                          controller: _nroDocCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nro. Documento Proveedor *',
                            hintText: 'Nro. de factura u OC (alfanumérico)',
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
                      // ── Fila 2: Tipo Documento (solo lectura, derivado del doc SAP) + Cód. Importación ──
                      _buildRow(
                        widget.isMobile,
                        TextFormField(
                          key: ValueKey('tipoDoc-${_selectedTipoDoc ?? ''}'),
                          initialValue: _selectedTipoDoc ?? '',
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Tipo Documento *',
                            hintText:
                                'Se completa al elegir la Factura Prov. SAP',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            suffixIcon: const Icon(
                              Icons.lock_outline,
                              size: 16,
                            ),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty
                                      ? 'Seleccione la Factura Prov. SAP'
                                      : null,
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
