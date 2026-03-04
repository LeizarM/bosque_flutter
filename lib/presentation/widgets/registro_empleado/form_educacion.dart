import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/domain/entities/educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_educacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormEducacion extends ConsumerStatefulWidget {
  final EducacionEntity? educacionInicial;
  final Function(EducacionEntity) onSave;
  final VoidCallback onCancel;
  final int codEmpleado;
  final int audUsuario;

  const FormEducacion({
    Key? key,
    this.educacionInicial,
    required this.onSave,
    required this.onCancel,
    required this.codEmpleado,
    required this.audUsuario,
  }) : super(key: key);

  @override
  ConsumerState<FormEducacion> createState() => _FormEducacionState();
}

class _FormEducacionState extends ConsumerState<FormEducacion> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descripcionController;
  late TextEditingController _fechaController;
  String? _selectedTipoEducacion;

  @override
  void initState() {
    super.initState();
    _descripcionController = TextEditingController(
      text: widget.educacionInicial?.descripcion ?? '',
    );

    _selectedTipoEducacion = widget.educacionInicial?.tipoEducacion.isNotEmpty == true
        ? widget.educacionInicial!.tipoEducacion
        : null;

    final initialDate = widget.educacionInicial?.fecha ?? DateTime.now();
    _fechaController = TextEditingController(
      text: FechaUtils.formatDate(initialDate),
    );
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      final fechaSeleccionada = FechaUtils.parseDate(_fechaController.text) ?? DateTime.now();

      final educacionGuardada = EducacionEntity(
        codEducacion: widget.educacionInicial?.codEducacion ?? 0,
        codEmpleado: widget.codEmpleado,
        tipoEducacion: _selectedTipoEducacion!,
        descripcion: _descripcionController.text.trim(),
        fecha: fechaSeleccionada,
        audUsuario: widget.audUsuario,
      );

      widget.onSave(educacionGuardada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiposEducacionAsync = ref.watch(obtenerTipoEducacion);

    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.only(bottom: context.smallSpacing),
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: Colors.lightGreen.withOpacity(0.05),
          borderRadius: context.borderRadius,
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
          ),
        ),
        child: context.isMobile
            ? _buildMobileLayout(context, tiposEducacionAsync)
            : _buildWebLayout(context, tiposEducacionAsync),
      ),
    );
  }

  // ============================================================================
  // LAYOUT MÓVIL: Formulario apilado verticalmente
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context, AsyncValue<List<TipoEducacionEntity>> tiposEducacionAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdownTipo(context, tiposEducacionAsync),
        SizedBox(height: context.spacing),
        _buildDatePicker(context),
        SizedBox(height: context.spacing),
        _buildInputDescripcion(context),
        SizedBox(height: context.spacing),
        _buildActionButtonsMobile(context),
      ],
    );
  }

  // ============================================================================
  // LAYOUT WEB: Formulario en fila
  // ============================================================================

  Widget _buildWebLayout(BuildContext context, AsyncValue<List<TipoEducacionEntity>> tiposEducacionAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Tipo, Fecha, Botones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildDropdownTipo(context, tiposEducacionAsync),
            ),
            SizedBox(width: context.spacing),
            SizedBox(
              width: 160,
              child: _buildDatePicker(context),
            ),
            SizedBox(width: context.spacing),
            _buildActionButtonsWeb(context),
          ],
        ),
        SizedBox(height: context.spacing),
        // Fila 2: Descripción
        _buildInputDescripcion(context),
      ],
    );
  }

  // ============================================================================
  // COMPONENTES
  // ============================================================================

  Widget _buildDropdownTipo(BuildContext context, AsyncValue<List<TipoEducacionEntity>> tiposEducacionAsync) {
    return CustomDropdown<TipoEducacionEntity>(
      asyncValue: tiposEducacionAsync,
      label: 'Tipo de Educación',
      currentValue: _selectedTipoEducacion,
      onChanged: (newValue) {
        setState(() => _selectedTipoEducacion = newValue);
      },
      getName: (e) => e.nombre,
      getCode: (e) => e.codTipos,
      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return CustomDatePicker(
      controller: _fechaController,
      label: 'Fecha',
      validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
      lastDate: DateTime.now(),
      firstDate: DateTime(1900),
    );
  }

  Widget _buildInputDescripcion(BuildContext context) {
    return TextFormField(
      controller: _descripcionController,
      keyboardType: TextInputType.multiline,
      minLines: 2,
      maxLines: 4,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Institución/Descripción *',
        labelStyle: TextStyle(fontSize: context.bodyFontSize),
        hintStyle: context.bodyLightStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.smallSpacing,
          vertical: context.spacing,
        ),
        isDense: true,
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
    );
  }

  // ============================================================================
  // BOTONES
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
            color: Colors.green,
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