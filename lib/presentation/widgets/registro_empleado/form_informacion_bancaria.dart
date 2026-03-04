import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/nro_cuenta_bancaria_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/validadores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormInformacionBancaria extends ConsumerStatefulWidget {
  final NroCuentaBancariaEntity? dataInicial;
  final Function(NroCuentaBancariaEntity) onSave;
  final VoidCallback onCancel;
  final int codEmpleado;
  final int audUsuario;

  const FormInformacionBancaria({
    Key? key,
    this.dataInicial,
    required this.onSave,
    required this.onCancel,
    required this.codEmpleado,
    required this.audUsuario,
  }) : super(key: key);

  @override
  ConsumerState<FormInformacionBancaria> createState() =>
      _FormInformacionBancariaState();
}

class _FormInformacionBancariaState
    extends ConsumerState<FormInformacionBancaria> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nroCuentaController;
  int? _selectedBancoId;
  int? _selectedEstado;

  @override
  void initState() {
    super.initState();
    _nroCuentaController = TextEditingController(
      text: widget.dataInicial?.nroCuentaBancaria ?? '',
    );
    _selectedBancoId = widget.dataInicial?.codBanco;
    _selectedEstado = widget.dataInicial?.estado;
  }

  @override
  void didUpdateWidget(covariant FormInformacionBancaria oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.dataInicial != oldWidget.dataInicial) {
      _nroCuentaController.text = widget.dataInicial?.nroCuentaBancaria ?? '';
      _selectedBancoId = widget.dataInicial?.codBanco;
      _selectedEstado = widget.dataInicial?.estado;
    }
  }

  @override
  void dispose() {
    _nroCuentaController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      final nroCuenta = _nroCuentaController.text.trim();

      if (_selectedBancoId == null) {
        showErrorMessage(context, 'Seleccione un banco');
        return;
      }

      if (_selectedEstado == null) {
        showErrorMessage(context, 'Seleccione el estado de la cuenta');
        return;
      }

      final cuenta = NroCuentaBancariaEntity(
        codCuenta: widget.dataInicial?.codCuenta ?? 0,
        codEmpleado: widget.codEmpleado,
        codBanco: _selectedBancoId!,
        nroCuentaBancaria: nroCuenta,
        estado: _selectedEstado!,
        audUsuarioI: widget.audUsuario,
      );

      widget.onSave(cuenta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bancosAsync = ref.watch(obtenerBancos);

    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.only(bottom: context.smallSpacing),
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.05),
          borderRadius: context.borderRadius,
          border: Border.all(
            color: Colors.teal.withOpacity(0.5),
          ),
        ),
        child: context.isMobile
            ? _buildMobileLayout(context, bancosAsync)
            : _buildWebLayout(context, bancosAsync),
      ),
    );
  }

  // ============================================================================
  // LAYOUT MÓVIL: Formulario apilado verticalmente
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    AsyncValue<List<BancoEntity>> bancosAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputNroCuenta(context),
        SizedBox(height: context.spacing),
        _buildDropdownBanco(context, bancosAsync),
        SizedBox(height: context.spacing),
        _buildDropdownEstado(context),
        SizedBox(height: context.spacing),
        _buildActionButtonsMobile(context),
      ],
    );
  }

  // ============================================================================
  // LAYOUT WEB: Formulario en fila
  // ============================================================================

  Widget _buildWebLayout(
    BuildContext context,
    AsyncValue<List<BancoEntity>> bancosAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Número de Cuenta, Banco, Botones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildInputNroCuenta(context),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              flex: 2,
              child: _buildDropdownBanco(context, bancosAsync),
            ),
            SizedBox(width: context.spacing),
            _buildActionButtonsWeb(context),
          ],
        ),
        SizedBox(height: context.spacing),
        // Fila 2: Estado
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildDropdownEstado(context),
            ),
            SizedBox(width: context.spacing * 2),
            SizedBox(width: 60), // Compensar botones
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // COMPONENTES: Campos del Formulario
  // ============================================================================

  Widget _buildInputNroCuenta(BuildContext context) {
    return TextFormField(
      controller: _nroCuentaController,
      keyboardType: TextInputType.number,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Número de Cuenta *',
        labelStyle: TextStyle(fontSize: context.bodyFontSize),
        hintStyle: context.bodyLightStyle,
        border: OutlineInputBorder(
          borderRadius: context.borderRadius,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.smallSpacing,
          vertical: context.spacing,
        ),
        isDense: true,
      ),
      validator: (val) =>validarNroCuenta(val) 
    );
  }

  Widget _buildDropdownBanco(
    BuildContext context,
    AsyncValue<List<BancoEntity>> bancosAsync,
  ) {
    return CustomDropdown<BancoEntity>(
      asyncValue: bancosAsync,
      label: 'Banco *',
      currentValue: _selectedBancoId?.toString(),
      onChanged: (newValue) {
        setState(() => _selectedBancoId = int.tryParse(newValue ?? ''));
      },
      getName: (banco) => banco.nombre,
      getCode: (banco) => banco.codBanco.toString(),
      validator: (v) => v?.isEmpty ?? true ? 'Seleccione un banco' : null,
    );
  }

  Widget _buildDropdownEstado(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: _selectedEstado,
      isExpanded: true,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Estado *',
        labelStyle: TextStyle(fontSize: context.bodyFontSize),
        hintStyle: context.bodyLightStyle,
        border: OutlineInputBorder(
          borderRadius: context.borderRadius,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.smallSpacing,
          vertical: context.spacing,
        ),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem<int>(
          value: 1,
          child: Text('Activa'),
        ),
        DropdownMenuItem<int>(
          value: 0,
          child: Text('Inactiva'),
        ),
      ],
      onChanged: (val) {
        setState(() => _selectedEstado = val);
      },
      validator: (val) => val == null ? 'Seleccione un estado' : null,
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN: Responsive
  // ============================================================================

  Widget _buildActionButtonsMobile(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
          ),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.check),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsWeb(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            Icons.check,
            color: Colors.green.shade600,
            size: context.smallIconSize,
          ),
          onPressed: _handleSave,
          tooltip: 'Guardar',
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: context.spacing * 3,
            minHeight: context.spacing * 3,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.grey,
            size: context.smallIconSize,
          ),
          onPressed: widget.onCancel,
          tooltip: 'Cancelar',
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: context.spacing * 3,
            minHeight: context.spacing * 3,
          ),
        ),
      ],
    );
  }
}