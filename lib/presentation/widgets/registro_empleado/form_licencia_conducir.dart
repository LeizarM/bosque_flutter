// lib/presentation/widgets/registro_empleado/form_licencia_conducir.dart

import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/domain/entities/licencia_conducir_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_licencia_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// MAIN WIDGET
// ============================================================================

class FormLicenciaConducir extends ConsumerStatefulWidget {
  final LicenciaConducirEntity? licenciaInicial;
  final Function(LicenciaConducirEntity) onSave;
  final VoidCallback onCancel;
  final int codPersona;
  final int audUsuario;

  const FormLicenciaConducir({
    Key? key,
    this.licenciaInicial,
    required this.onSave,
    required this.onCancel,
    required this.codPersona,
    required this.audUsuario,
  }) : super(key: key);

  @override
  ConsumerState<FormLicenciaConducir> createState() =>
      _FormLicenciaConducirState();
}

class _FormLicenciaConducirState
    extends ConsumerState<FormLicenciaConducir> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fechaCaducidadController;
  String? _selectedCategoria;
  DateTime? _selectedFechaCaducidad;

  @override
  void initState() {
    super.initState();

    _selectedCategoria = widget.licenciaInicial?.categoria;

    _selectedFechaCaducidad = widget.licenciaInicial?.fechaCaducidad;
    _fechaCaducidadController = TextEditingController(
      text: _selectedFechaCaducidad != null
          ? FechaUtils.formatDate(_selectedFechaCaducidad!)
          : '',
    );
  }

  @override
  void dispose() {
    _fechaCaducidadController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate() &&
        _selectedFechaCaducidad != null &&
        _selectedCategoria != null &&
        _selectedCategoria!.isNotEmpty) {
      FocusManager.instance.primaryFocus?.unfocus();

      final nuevaLicencia = LicenciaConducirEntity(
        codLicencia: widget.licenciaInicial?.codLicencia ?? 0,
        codPersona: widget.codPersona,
        categoria: _selectedCategoria!.trim(),
        fechaCaducidad: _selectedFechaCaducidad!,
        audUsuario: widget.audUsuario,
      );

      widget.onSave(nuevaLicencia);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiposLicenciaAsync =
        ref.watch(obtenerTipoLicenciaConducirProvider);

    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.only(bottom: context.smallSpacing),
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.02),
          borderRadius: context.borderRadius,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: context.isMobile
            ? _buildMobileLayout(context, tiposLicenciaAsync)
            : _buildWebLayout(context, tiposLicenciaAsync),
      ),
    );
  }

  // ============================================================================
  // LAYOUT MÓVIL: Formulario apilado verticalmente
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    AsyncValue<List<TipoLicenciaEntity>> tiposLicenciaAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldCategoria(context, tiposLicenciaAsync),
        SizedBox(height: context.spacing),
        _buildFieldFechaCaducidad(context),
        SizedBox(height: context.spacing),
        _buildActionButtons(context),
      ],
    );
  }

  // ============================================================================
  // LAYOUT WEB: Formulario en fila
  // ============================================================================

  Widget _buildWebLayout(
    BuildContext context,
    AsyncValue<List<TipoLicenciaEntity>> tiposLicenciaAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildFieldCategoria(context, tiposLicenciaAsync),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              flex: 1,
              child: _buildFieldFechaCaducidad(context),
            ),
          ],
        ),
        SizedBox(height: context.spacing),
        Align(
          alignment: Alignment.centerRight,
          child: _buildActionButtons(context),
        ),
      ],
    );
  }

  // ============================================================================
  // CAMPOS DEL FORMULARIO
  // ============================================================================

  Widget _buildFieldCategoria(
    BuildContext context,
    AsyncValue<List<TipoLicenciaEntity>> tiposLicenciaAsync,
  ) {
    return CustomDropdown<TipoLicenciaEntity>(
      asyncValue: tiposLicenciaAsync,
      label: 'Categoría *',
      currentValue: _selectedCategoria,
      onChanged: (newValue) {
        setState(() => _selectedCategoria = newValue);
      },
      getName: (e) => e.nombre,
      getCode: (e) => e.codTipos,
      validator: (val) =>
          (val == null || val.isEmpty) ? 'Requerido' : null,
    );
  }

  Widget _buildFieldFechaCaducidad(BuildContext context) {
    return CustomDatePicker(
      controller: _fechaCaducidadController,
      label: 'Fecha de Caducidad *',
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      onDateSelected: (date) {
        setState(() {
          _selectedFechaCaducidad = date;
        });
      },
      validator: (val) {
        if (val == null || val.isEmpty) return 'Requerido';
        if (_selectedFechaCaducidad == null) {
          return 'Seleccione una fecha válida';
        }
        return null;
      },
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN RESPONSIVOS
  // ============================================================================

  Widget _buildActionButtons(BuildContext context) {
    if (context.isMobile) {
      // En móvil: botones expandidos verticalmente
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
              onPressed: widget.onCancel,
            ),
          ),
          SizedBox(width: context.spacing),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              onPressed: _handleSave,
            ),
          ),
        ],
      );
    } else {
      // En web: botones alineados a la derecha
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Cancelar'),
            onPressed: widget.onCancel,
          ),
          SizedBox(width: context.spacing),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            onPressed: _handleSave,
          ),
        ],
      );
    }
  }
}