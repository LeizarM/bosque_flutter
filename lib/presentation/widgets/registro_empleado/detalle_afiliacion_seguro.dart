// lib/presentation/widgets/registro_empleado/detalle_afiliacion_seguro.dart

import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/afiliacion_seguro_entity.dart';
import 'package:bosque_flutter/domain/entities/seguro_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/form_afiliacion_seguro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetalleAfiliacionSeguro extends ConsumerStatefulWidget {
  final int codEmpleado;

  const DetalleAfiliacionSeguro({
    Key? key,
    required this.codEmpleado,
  }) : super(key: key);

  @override
  ConsumerState<DetalleAfiliacionSeguro> createState() =>
      _DetalleAfiliacionSeguroState();
}

class _DetalleAfiliacionSeguroState
    extends ConsumerState<DetalleAfiliacionSeguro> {
  late int _audUsuario;
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _audUsuario = user?.codUsuario ?? 0;

    console('🔍 DetalleAfiliacionSeguro - codEmpleado: ${widget.codEmpleado}');

    final afiliacionAsync =
        ref.watch(obtenerAfiliacionSeguro(widget.codEmpleado));

    return afiliacionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        console('❌ Error al cargar afiliación: $err');
        return Center(
          child: Text('Error al cargar afiliación: $err'),
        );
      },
      data: (afiliacion) {
        return _buildUI(context, afiliacion);
      },
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

 Widget _buildUI(BuildContext context, AfiliacionSeguroEntity? afiliacion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        if (afiliacion == null && !_isEditing)
          _buildEmptyState(context),
        if (afiliacion == null && _isEditing)
          _buildNewForm(context),
        if (afiliacion != null && !_isEditing)
          _buildAfiliacionCard(context, afiliacion),
        if (afiliacion != null && _isEditing)
          _buildEditForm(context, afiliacion),
      ],
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.smallSpacing),
      child: Row(
        children: [
          Icon(
            Icons.shield,
            size: context.smallIconSize,
            color: Colors.grey,
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            'Afiliación al Seguro',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE AFILIACIÓN (LECTURA)
  // ============================================================================

  Widget _buildAfiliacionCard(
    BuildContext context,
    AfiliacionSeguroEntity afiliacion,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seguro
            _buildSeguroRow(context, afiliacion.seguro),
            SizedBox(height: context.spacing),

            // Número de Afiliación
            _buildDetailRow(
              context,
              'Número de Afiliación:',
              afiliacion.nroAfiliacion,
            ),
            SizedBox(height: context.spacing),

            // Fecha de Afiliación
            _buildDetailRow(
              context,
              'Fecha de Afiliación:',
              FechaUtils.formatDate(afiliacion.fechaAfiliacion),
            ),
            SizedBox(height: context.spacing),

            // Fecha de Baja (solo si tiene valor)
            if (afiliacion.fechaBaja != null) ...[
              _buildDetailRow(
                context,
                'Fecha de Baja:',
                FechaUtils.formatDate(afiliacion.fechaBaja!),
              ),
              SizedBox(height: context.spacing),
            ],

            // Botones de acción
            _buildActionButtons(context, afiliacion),
          ],
        ),
      ),
    );
  }

  Widget _buildSeguroRow(BuildContext context, SeguroEntity seguro) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.isMobile ? 120 : 160,
          child: Text(
            'Seguro:',
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: Text(
            '${seguro.nombre} - ${seguro.regional}',
            style: context.bodyStyle.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.isMobile ? 120 : 160,
          child: Text(
            label,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: Text(
            value,
            style: context.bodyStyle.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AfiliacionSeguroEntity afiliacion,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            size: context.smallIconSize,
            color: Colors.blueGrey,
          ),
          onPressed: () {
            console('🔧 Btn editar presionado');
            setState(() => _isEditing = true);
          },
          tooltip: 'Editar',
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: context.smallIconSize,
            color: Colors.redAccent,
          ),
          onPressed: () => _eliminarAfiliacion(context, afiliacion.codAfiliacion),
          tooltip: 'Eliminar',
        ),
      ],
    );
  }

  // ============================================================================
  // FORMULARIO EDICIÓN
  // ============================================================================

  Widget _buildEditForm(
    BuildContext context,
    AfiliacionSeguroEntity afiliacion,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: FormAfiliacionSeguro(
          key: ValueKey('edit_afiliacion_${afiliacion.codAfiliacion}'),
          codEmpleado: widget.codEmpleado,
          afiliacionInicial: afiliacion,
          audUsuario: _audUsuario,
          onSave: (afiliacionEditada) => _guardarAfiliacion(afiliacionEditada),
          onCancel: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _isEditing = false);
          },
        ),
      ),
    );
  }

  // ============================================================================
  // FORMULARIO NUEVA AFILIACIÓN
  // ============================================================================

  Widget _buildNewForm(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: FormAfiliacionSeguro(
          key: ValueKey('new_afiliacion_${DateTime.now().millisecondsSinceEpoch}'),
          codEmpleado: widget.codEmpleado,
          afiliacionInicial: null,
          audUsuario: _audUsuario,
          onSave: (afiliacion) => _guardarAfiliacion(afiliacion),
          onCancel: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _isEditing = false);
          },
        ),
      ),
    );
  }

  // ============================================================================
  // ESTADO VACÍO - SIN AFILIACIÓN
  // ============================================================================

 Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        _buildAddButton(context),
        Padding(
          padding: EdgeInsets.all(context.spacing),
          child: Center(
            child: Text(
              'No hay afiliación al seguro registrada',
              style: context.bodyLightStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Afiliar Empleado'),
        onPressed: () {
          console('➕ Btn afiliar empleado presionado');
          setState(() => _isEditing = true);
        },
      ),
    );
  }

  // ============================================================================
  // ACCIONES - ABM
  // ============================================================================

  Future<void> _guardarAfiliacion(AfiliacionSeguroEntity afiliacion) async {
    await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(registrarAfiliacionSeguro(afiliacion).future),
      providersToInvalidate: [
        obtenerAfiliacionSeguro(widget.codEmpleado),
      ],
      successMessage: '✅ Afiliación guardada correctamente',
    );

    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _eliminarAfiliacion(
    BuildContext context,
    int codAfiliacion,
  ) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(eliminarAfiliacionSeguro(codAfiliacion).future),
      providersToInvalidate: [
        obtenerAfiliacionSeguro(widget.codEmpleado),
      ],
      successMessage: '✅ Afiliación eliminada correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Afiliación',
      confirmationMessage:
          '¿Está seguro de eliminar esta afiliación al seguro?',
    );

    if (success && mounted) {
      setState(() => _isEditing = false);
    }
  }
}