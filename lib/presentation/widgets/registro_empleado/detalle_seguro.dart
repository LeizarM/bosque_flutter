// lib/presentation/widgets/registro_empleado/detalle_seguro.dart

import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/seguro_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/form_seguro.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DetalleSeguro extends ConsumerStatefulWidget {
  const DetalleSeguro({Key? key}) : super(key: key);

  @override
  ConsumerState<DetalleSeguro> createState() => _DetalleSeguroState();
}

class _DetalleSeguroState extends ConsumerState<DetalleSeguro> {
  late int _audUsuario;
  bool _isEditing = false;
  SeguroEntity? _seguroEnEdicion;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _audUsuario = user?.codUsuario ?? 0;

    console('🔍 DetalleSeguro');

    final segurosAsync = ref.watch(obtenerSeguros);

    return segurosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) {
        console('❌ Error al cargar seguros: $err');
        return Center(
          child: Text('Error al cargar seguros: $err'),
        );
      },
      data: (seguros) {
        return _buildUI(context, seguros);
      },
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(BuildContext context, List<SeguroEntity> seguros) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        if (seguros.isEmpty && !_isEditing)
          _buildEmptyState(context)
        else if (seguros.isNotEmpty && !_isEditing)
          _buildSegurosList(context, seguros)
        else
          _buildForm(context),
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
            'Gestión de Seguros',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // LISTA DE SEGUROS
  // ============================================================================

  Widget _buildSegurosList(
    BuildContext context,
    List<SeguroEntity> seguros,
  ) {
    return Column(
      children: [
        _buildAddButton(context),
        SizedBox(height: context.spacing),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: seguros.length,
          separatorBuilder: (_, __) => SizedBox(height: context.spacing),
          itemBuilder: (_, index) {
            final seguro = seguros[index];
            return _buildSeguroCard(context, seguro);
          },
        ),
      ],
    );
  }

  // ============================================================================
  // TARJETA DE SEGURO (LECTURA)
  // ============================================================================

  Widget _buildSeguroCard(BuildContext context, SeguroEntity seguro) {
    return Card(
      margin: EdgeInsets.zero,
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
            // Nombre - Regional
            _buildDetailRow(
              context,
              'Nombre:',
              '${seguro.nombre} - ${seguro.regional}',
            ),
            SizedBox(height: context.spacing),

            // Número
            _buildDetailRow(
              context,
              'Número:',
              seguro.numero ,
            ),
            SizedBox(height: context.spacing),

            // Nombre Corto
            _buildDetailRow(
              context,
              'Nombre Corto:',
              seguro.nombreCorto,
            ),
            SizedBox(height: context.spacing),

            // Descripción
            _buildDetailRow(
              context,
              'Descripción:',
              seguro.descripcion,
            ),
            SizedBox(height: context.spacing),

            // Botones de acción
            _buildActionButtons(context, seguro),
          ],
        ),
      ),
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
          width: context.isMobile ? 100 : 120,
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
    SeguroEntity seguro,
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
            console('🔧 Btn editar seguro presionado');
            setState(() {
              _isEditing = true;
              _seguroEnEdicion = seguro;
            });
          },
          tooltip: 'Editar',
        ),
        PermissionWidget(
        buttonName: 'btnEliminarSeguro',
        placeholder: SizedBox(
          width: 48, // Mantener el espacio del botón
          height: 48,
        ),child: IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: context.smallIconSize,
            color: Colors.redAccent,
          ),
          onPressed: () => _eliminarSeguro(context, seguro.codSeguro),
          tooltip: 'Eliminar',
        ),
      ),
      ],
    );
  }

  // ============================================================================
  // ESTADO VACÍO
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        _buildAddButton(context),
        Padding(
          padding: EdgeInsets.all(context.spacing),
          child: Center(
            child: Text(
              'No hay seguros registrados',
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
        label: const Text('Agregar Seguro'),
        onPressed: () {
          console('➕ Btn agregar seguro presionado');
          setState(() {
            _isEditing = true;
            _seguroEnEdicion = null;
          });
        },
      ),
    );
  }

  // ============================================================================
  // FORMULARIO (PLACEHOLDER - Se creará después)
  // ============================================================================

  Widget _buildForm(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(context.spacing),
        child: FormSeguro(
          seguroInicial: _seguroEnEdicion,
          audUsuario: _audUsuario,
          onSave: (seguro) {
            console('✅ Seguro guardado: ${seguro.nombre}');
            setState(() {
              _isEditing = false;
              _seguroEnEdicion = null;
            });
          },
          onCancel: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() {
              _isEditing = false;
              _seguroEnEdicion = null;
            });
          },
        ),
      ),
    );
  }

  // ============================================================================
  // ACCIONES - ABM
  // ============================================================================

  Future<void> _eliminarSeguro(
    BuildContext context,
    int codSeguro,
  ) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(eliminarSeguro(codSeguro).future),
      providersToInvalidate: [
        obtenerSeguros,
      ],
      successMessage: '✅ Seguro eliminado correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Seguro',
      confirmationMessage:
          '¿Está seguro de eliminar este seguro?',
    );

    if (success && mounted) {
      setState(() => _isEditing = false);
    }
  }
}