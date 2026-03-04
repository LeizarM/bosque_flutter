import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/nro_cuenta_bancaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_informacion_bancaria.dart';

// ============================================================================
// MAIN WIDGET
// ============================================================================

class DetalleInformacionBancaria extends ConsumerStatefulWidget {
  final int codEmpleado;
  final String mode;

  const DetalleInformacionBancaria({
    Key? key,
    required this.codEmpleado,
    this.mode = 'nuevo',
  }) : super(key: key);

  @override
  ConsumerState<DetalleInformacionBancaria> createState() =>
      _DetalleInformacionBancariaState();
}

class _DetalleInformacionBancariaState
    extends ConsumerState<DetalleInformacionBancaria> {
  int _editingIndex = -1;
  bool _isAddingNew = false;
  late int _audUsuario;

  @override
  void didUpdateWidget(covariant DetalleInformacionBancaria oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mode == 'nuevo' && oldWidget.codEmpleado != widget.codEmpleado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tempCuentasBancariasProvider.notifier).state = [];
        _resetFormState();
      });
    }
  }

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

    return widget.mode == 'nuevo'
        ? _buildNuevoMode(context)
        : _buildEdicionMode(context);
  }

  // ============================================================================
  // MODO NUEVO: Carga desde temporal
  // ============================================================================

  Widget _buildNuevoMode(BuildContext context) {
    final listaCuentas = ref.watch(tempCuentasBancariasProvider);

    // Si tempCuentasBancariasProvider está vacío, cargar del servidor SOLO UNA VEZ
    if (listaCuentas.isEmpty) {
      final cuentasDelServidorAsync =
          ref.watch(cuentaBancariaEmpleadoProvider(widget.codEmpleado));

      return cuentasDelServidorAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (cuentasDelServidor) {
          // IMPORTANTE: Cargar en tempCuentasBancariasProvider SOLO una vez
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(tempCuentasBancariasProvider).isEmpty &&
                cuentasDelServidor.isNotEmpty) {
              ref.read(tempCuentasBancariasProvider.notifier).state =
                  cuentasDelServidor;
            }
          });
          return _buildUI(context, cuentasDelServidor, isEdition: false);
        },
      );
    }

    // Si ya hay datos en temporal, mostrar esos
    return _buildUI(context, listaCuentas, isEdition: false);
  }

  // ============================================================================
  // MODO EDICION: Carga desde servidor
  // ============================================================================

  Widget _buildEdicionMode(BuildContext context) {
    final cuentasAsync =
        ref.watch(cuentaBancariaEmpleadoProvider(widget.codEmpleado));

    return cuentasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (listaCuentas) =>
          _buildUI(context, listaCuentas, isEdition: true),
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(BuildContext context, List<NroCuentaBancariaEntity> lista,
      {required bool isEdition}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        Column(
          children: [
            // Lista de cuentas
            if (lista.isEmpty && !_isAddingNew)
              _buildEmptyState(context)
            else
              ...List.generate(
                lista.length,
                (idx) => _editingIndex == idx
                    ? _buildEditForm(context, idx, lista, isEdition)
                    : _buildCuentaCard(context, idx, lista[idx], isEdition),
              ),
            // Formulario nuevo si está activo
            if (_isAddingNew) _buildNewForm(context, isEdition),
            // Botón agregar
            if (!_isAddingNew && lista.isNotEmpty) _buildAddButton(context),
          ],
        ),
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
            Icons.account_balance,
            size: context.smallIconSize,
            color: Colors.grey,
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            'Información Bancaria',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ESTADO VACÍO
  // ============================================================================

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.spacing * 1.5,
          horizontal: context.spacing,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                size: context.largeIconSize,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: context.spacing),
              Text(
                'No hay cuentas bancarias registradas',
                style: context.bodyLightStyle.copyWith(
                  fontSize: context.bodyFontSize,
                ),
              ),
              SizedBox(height: context.spacing),
              ElevatedButton.icon(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  setState(() => _isAddingNew = true);
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar Cuenta Bancaria'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TARJETA DE CUENTA (LECTURA)
  // ============================================================================

  Widget _buildCuentaCard(BuildContext context, int index,
      NroCuentaBancariaEntity cuenta, bool isEdition) {
    final bancosAsync = ref.watch(obtenerBancos);

    return bancosAsync.when(
      data: (bancos) {
        final banco = bancos.firstWhere(
          (b) => b.codBanco == cuenta.codBanco,
          orElse: () => BancoEntity(
            codBanco: 0,
            nombre: 'Banco desconocido',
            audUsuario: 0,
            fila: 0,
          ),
        );

        final estado = cuenta.estado == 1 ? 'Activa' : 'Inactiva';
        final estadoColor = cuenta.estado == 1 ? Colors.green : Colors.orange;

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
                _buildDataRowBancaria(context, 'Banco:', banco.nombre),
                SizedBox(height: context.spacing),
                _buildDataRowBancaria(
                    context, 'Nro. Cuenta:', cuenta.nroCuentaBancaria),
                SizedBox(height: context.spacing),
                _buildEstadoBadge(context, estado, estadoColor),
                SizedBox(height: context.spacing),
                _buildActionsBancaria(context, index, cuenta, isEdition),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, _) => Text('Error: $err'),
    );
  }

  Widget _buildDataRowBancaria(
      BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.isMobile ? 100 : 130,
          child: Text(
            label,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoBadge(
      BuildContext context, String estado, Color estadoColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.isMobile ? 100 : 130,
          child: Text(
            'Estado:',
            style: context.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.smallSpacing,
            vertical: context.smallSpacing / 2,
          ),
          decoration: BoxDecoration(
            color: estadoColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: estadoColor.withOpacity(0.5)),
          ),
          child: Text(
            estado,
            style: TextStyle(
              fontSize: context.smallFontSize,
              fontWeight: FontWeight.w600,
              color: estadoColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsBancaria(BuildContext context, int index,
      NroCuentaBancariaEntity cuenta, bool isEdition) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            size: context.smallIconSize,
            color: Colors.blueGrey,
          ),
          onPressed: () => _startEditing(index),
          tooltip: 'Editar',
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: context.smallIconSize,
            color: Colors.redAccent,
          ),
          onPressed: () => isEdition
              ? _deleteFromServer(cuenta.codCuenta)
              : _deleteFromList(index),
          tooltip: 'Eliminar',
        ),
      ],
    );
  }

  // ============================================================================
  // FORMULARIOS
  // ============================================================================

  Widget _buildEditForm(BuildContext context, int index,
      List<NroCuentaBancariaEntity> lista, bool isEdition) {
    return FormInformacionBancaria(
      key: ValueKey('edit_cuenta_${lista[index].codCuenta}'),
      dataInicial: lista[index],
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave: (cuenta) =>
          isEdition ? _saveToServer(cuenta) : _updateInList(cuenta, index),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _editingIndex = -1);
      },
    );
  }

  Widget _buildNewForm(BuildContext context, bool isEdition) {
    return FormInformacionBancaria(
      key: ValueKey('new_cuenta_${DateTime.now().millisecondsSinceEpoch}'),
      dataInicial: NroCuentaBancariaEntity(
        codCuenta: 0,
        codEmpleado: widget.codEmpleado,
        codBanco: 0,
        nroCuentaBancaria: '',
        estado: 1,
        audUsuarioI: _audUsuario,
      ),
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave: (cuenta) => isEdition ? _saveToServer(cuenta) : _addToList(cuenta),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _isAddingNew = false);
      },
    );
  }

  // ============================================================================
  // BOTONES Y ESTADOS
  // ============================================================================

  Widget _buildAddButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Agregar cuenta bancaria'),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _isAddingNew = true);
        },
      ),
    );
  }

  // ============================================================================
  // ACCIONES - MODO NUEVO (TEMPORAL - sin servidor)
  // ============================================================================

  void _startEditing(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = index;
      _isAddingNew = false;
    });
  }

  void _addToList(NroCuentaBancariaEntity cuenta) {
    final list = List<NroCuentaBancariaEntity>.from(
        ref.read(tempCuentasBancariasProvider));
    list.add(cuenta);
    ref.read(tempCuentasBancariasProvider.notifier).state = list;
    setState(() => _isAddingNew = false);
    showSuccessMessage(context, 'Cuenta bancaria agregada');
  }

  void _updateInList(NroCuentaBancariaEntity cuenta, int index) {
    final list = List<NroCuentaBancariaEntity>.from(
        ref.read(tempCuentasBancariasProvider));
    list[index] = cuenta;
    ref.read(tempCuentasBancariasProvider.notifier).state = list;
    setState(() => _editingIndex = -1);
    showSuccessMessage(context, 'Cuenta bancaria actualizada');
  }

  void _deleteFromList(int index) {
    final list = List<NroCuentaBancariaEntity>.from(
        ref.read(tempCuentasBancariasProvider));
    list.removeAt(index);
    ref.read(tempCuentasBancariasProvider.notifier).state = list;
    _resetFormState();
    showSuccessMessage(context, 'Cuenta bancaria eliminada');
  }

  // ============================================================================
  // ACCIONES - MODO EDICION (SERVIDOR)
  // ============================================================================

  Future<void> _saveToServer(NroCuentaBancariaEntity cuenta) async {
    await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(registroCuentaBancaria(cuenta).future),
      providersToInvalidate: [
        cuentaBancariaEmpleadoProvider(widget.codEmpleado),
        detalleEmpleadoProvider(widget.codEmpleado),
      ],
      successMessage: '✅ Cuenta bancaria guardada',
    );

    if (mounted) {
      _resetFormState();
    }
  }

  Future<void> _deleteFromServer(int codCuenta) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(eliminarCuentaBancaria(codCuenta).future),
      providersToInvalidate: [
        cuentaBancariaEmpleadoProvider(widget.codEmpleado),
      ],
      successMessage: 'Cuenta bancaria eliminada correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Cuenta Bancaria',
      confirmationMessage:
          '¿Está seguro de eliminar esta cuenta? No se puede deshacer.',
    );

    if (success && mounted) {
      setState(() => _editingIndex = -1);
    }
  }
}