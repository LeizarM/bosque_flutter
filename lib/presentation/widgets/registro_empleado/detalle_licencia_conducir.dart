// lib/presentation/widgets/registro_empleado/detalle_licencia_conducir.dart

import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/licencia_conducir_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_licencia_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'form_licencia_conducir.dart';

// ============================================================================
// MAIN WIDGET
// ============================================================================

class DetalleLicenciaConducir extends ConsumerStatefulWidget {
  final int codPersona;

  const DetalleLicenciaConducir({
    Key? key,
    required this.codPersona,
  }) : super(key: key);

  @override
  ConsumerState<DetalleLicenciaConducir> createState() =>
      _DetalleLicenciaConducirState();
}

class _DetalleLicenciaConducirState
    extends ConsumerState<DetalleLicenciaConducir> {
  int _editingIndex = -1;
  bool _isAddingNew = false;
  late int _audUsuario;

  void _resetFormState() {
    setState(() {
      _editingIndex = -1;
      _isAddingNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _audUsuario = user?.codUsuario ?? 0;

    final licenciasAsync =
        ref.watch(obtenerLicenciasConducirProvider(widget.codPersona));

    return licenciasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (listaLicencias) => _buildUI(context, listaLicencias),
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(BuildContext context, List<LicenciaConducirEntity> lista) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: context.smallSpacing),
          ...List.generate(
            lista.length,
            (idx) => _editingIndex == idx
                ? _buildEditForm(context, idx, lista)
                : _buildLicenciaCard(context, idx, lista[idx]),
          ),
          if (_isAddingNew) _buildNewForm(context),
          if (!_isAddingNew) _buildAddButton(context),
          if (lista.isEmpty && !_isAddingNew)
              _buildEmptyState(context),
        ],
      ),
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
            Icons.card_giftcard,
            size: context.smallIconSize,
            color: Colors.grey.shade600,
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            'Licencias de Conducir',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE LICENCIA
  // ============================================================================

  Widget _buildLicenciaCard(BuildContext context, int index,
      LicenciaConducirEntity licencia) {
    final estaVencida =
        licencia.fechaCaducidad.isBefore(DateTime.now());

    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: estaVencida
              ? Colors.red.shade300
              : Colors.grey.shade300,
        ),
        borderRadius: context.borderRadius,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing,
          vertical: context.smallSpacing,
        ),
        leading: CircleAvatar(
          backgroundColor:
              estaVencida ? Colors.red.shade50 : Colors.blue.shade50,
          child: Icon(
            Icons.card_giftcard,
            size: context.smallIconSize,
            color: estaVencida
                ? Colors.red.shade700
                : Colors.blue.shade700,
          ),
        ),
        title: _buildTitle(context, licencia, estaVencida),
        subtitle: _buildSubtitle(context, licencia, estaVencida),
        trailing: _buildActions(context, index, licencia),
      ),
    );
  }

  Widget _buildTitle(
    BuildContext context,
    LicenciaConducirEntity licencia,
    bool estaVencida,
  ) {
    return Row(
      children: [
        Flexible(
          child: DisplayValue<TipoLicenciaEntity>(
            code: licencia.categoria,
            provider: obtenerTipoLicenciaConducirProvider,
            getCode: (tipo) => tipo.codTipos,
            getDescription: (tipo) => tipo.nombre,
            fallback: licencia.categoria,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (estaVencida)
          Padding(
            padding: EdgeInsets.only(left: context.smallSpacing),
            child: Chip(
              label: const Text(
                'Vencida',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.redAccent,
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
    LicenciaConducirEntity licencia,
    bool estaVencida,
  ) {
    return Text(
      'Vence: ${FechaUtils.formatDate(licencia.fechaCaducidad)}',
      style: context.bodyLightStyle.copyWith(
        color: estaVencida
            ? Colors.red.shade600
            : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    int index,
    LicenciaConducirEntity licencia,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            size: context.iconSize,
            color: Colors.blueGrey,
          ),
          onPressed: () => _startEditing(index),
          tooltip: 'Editar',
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: context.iconSize,
            color: Colors.redAccent,
          ),
          onPressed: () =>
              _deleteFromServer(licencia.codLicencia),
          tooltip: 'Eliminar',
        ),
      ],
    );
  }

  // ============================================================================
  // FORMULARIO EDICIÓN
  // ============================================================================

  void _startEditing(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = index;
      _isAddingNew = false;
    });
  }

  Widget _buildEditForm(
    BuildContext context,
    int index,
    List<LicenciaConducirEntity> lista,
  ) {
    return FormLicenciaConducir(
      key: ValueKey('edit_licencia_${lista[index].codLicencia}'),
      licenciaInicial: lista[index],
      codPersona: widget.codPersona,
      audUsuario: _audUsuario,
      onSave: (licencia) => _saveToServer(licencia),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _editingIndex = -1);
      },
    );
  }

  // ============================================================================
  // FORMULARIO NUEVO
  // ============================================================================

  Widget _buildNewForm(BuildContext context) {
    return FormLicenciaConducir(
      key: ValueKey('new_licencia_${DateTime.now().millisecondsSinceEpoch}'),
      licenciaInicial: null,
      codPersona: widget.codPersona,
      audUsuario: _audUsuario,
      onSave: (licencia) => _saveToServer(licencia),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _isAddingNew = false);
      },
    );
  }

  // ============================================================================
  // BOTÓN AGREGAR
  // ============================================================================

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallSpacing),
      child: TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Agregar licencia'),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _isAddingNew = true);
        },
      ),
    );
  }

  // ============================================================================
  // ESTADO VACÍO
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing),
      child: Center(
        child: Text(
          'No hay licencias de conducir registradas',
          style: context.bodyLightStyle,
        ),
      ),
    );
  }

  // ============================================================================
  // OPERACIONES CRUD
  // ============================================================================

  Future<void> _saveToServer(LicenciaConducirEntity licencia) async {
    await executeABM(
      ref: ref,
      context: context,
      operation: () => ref.read(
        registrarLicenciaConducirProvider(licencia).future,
      ),
      providersToInvalidate: [
        obtenerLicenciasConducirProvider(widget.codPersona),
      ],
      successMessage: licencia.codLicencia == 0
          ? 'Licencia registrada correctamente'
          : 'Licencia actualizada correctamente',
    );

    if (mounted) {
      _resetFormState();
    }
  }

  Future<void> _deleteFromServer(int codLicencia) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () => ref.read(
        eliminarLicenciaConducirProvider(codLicencia).future,
      ),
      providersToInvalidate: [
        obtenerLicenciasConducirProvider(widget.codPersona),
      ],
      successMessage: 'Licencia eliminada correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Licencia de Conducir',
      confirmationMessage:
          '¿Está seguro de eliminar esta licencia? No se puede deshacer.',
    );

    if (success && mounted) {
      setState(() => _editingIndex = -1);
    }
  }
}