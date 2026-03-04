import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/domain/entities/formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_duracion_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_formacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormFormacion extends ConsumerStatefulWidget {
  final FormacionEntity? formacionInicial;
  final Function(FormacionEntity) onSave;
  final VoidCallback onCancel;
  final int codEmpleado;
  final int audUsuario;

  const FormFormacion({
    Key? key,
    this.formacionInicial,
    required this.onSave,
    required this.onCancel,
    required this.codEmpleado,
    required this.audUsuario,
  }) : super(key: key);

  @override
  ConsumerState<FormFormacion> createState() => _FormFormacionState();
}

class _FormFormacionState extends ConsumerState<FormFormacion> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descripcionController;
  late TextEditingController _duracionController;
  late TextEditingController _fechaController;
    late TextEditingController _institucionController; // ✅ AGREGAR

  String? _selectedTipoFormacion;
  String? _selectedTipoDuracion;

  @override
  void initState() {
    super.initState();
    final initial = widget.formacionInicial;
    // ✅ AGREGAR
    _institucionController = TextEditingController(
      text: initial?.institucion ?? '',
    );

    _descripcionController = TextEditingController(
      text: initial?.descripcion ?? '',
    );

    _duracionController = TextEditingController(
      text: (initial?.duracion ?? 0) > 0 ? initial!.duracion.toString() : '',
    );

    _selectedTipoFormacion = initial?.tipoFormacion.isNotEmpty == true
        ? initial!.tipoFormacion
        : null;

    _selectedTipoDuracion = initial?.tipoDuracion.isNotEmpty == true
        ? initial!.tipoDuracion
        : null;

    final initialDate = initial?.fechaFormacion ?? DateTime.now();
    _fechaController = TextEditingController(
      text: FechaUtils.formatDate(initialDate),
    );
  }

  @override
  void dispose() {
        _institucionController.dispose(); // ✅ AGREGAR
    _descripcionController.dispose();
    _duracionController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      final fechaSeleccionada =
          FechaUtils.parseDate(_fechaController.text) ?? DateTime.now();

      final formacionGuardada = FormacionEntity(
        codFormacion: widget.formacionInicial?.codFormacion ?? 0,
        codEmpleado: widget.codEmpleado,
        tipoFormacion: _selectedTipoFormacion!,
        descripcion: _descripcionController.text.trim(),
        institucion: _institucionController.text.trim(), // ✅ AGREGAR
        duracion: int.tryParse(_duracionController.text) ?? 0,
        tipoDuracion: _selectedTipoDuracion!,
        fechaFormacion: fechaSeleccionada,
        audUsuario: widget.audUsuario,
      );

      widget.onSave(formacionGuardada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipoFormacionAsync = ref.watch(obtenerTipoFormacionProvider);
    final tipoDuracionAsync = ref.watch(obtenerTipoDuracionFormacionProvider);

    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.only(bottom: context.smallSpacing),
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: Colors.lightBlue.withOpacity(0.05),
          borderRadius: context.borderRadius,
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: context.isMobile
            ? _buildMobileLayout(context, tipoFormacionAsync, tipoDuracionAsync)
            : _buildWebLayout(context, tipoFormacionAsync, tipoDuracionAsync),
      ),
    );
  }

  // ============================================================================
  // LAYOUT MÓVIL: Formulario apilado verticalmente
  // ============================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    AsyncValue<List<TipoFormacionEntity>> tipoFormacionAsync,
    AsyncValue<List<TipoDuracionFormacionEntity>> tipoDuracionAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDropdownTipoFormacion(context, tipoFormacionAsync),
        SizedBox(height: context.spacing),
        _buildInputInstitucion(context), // ✅ AGREGAR
        SizedBox(height: context.spacing),
        _buildInputDescripcion(context),
        SizedBox(height: context.spacing),
        // Fila: Duración y Tipo de Duración en dos columnas
        Row(
          children: [
            Expanded(
              child: _buildInputDuracion(context),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildDropdownTipoDuracion(context, tipoDuracionAsync),
            ),
          ],
        ),
        SizedBox(height: context.spacing),
        _buildDatePicker(context),
        SizedBox(height: context.spacing),
        _buildActionButtonsMobile(context),
      ],
    );
  }

  // ============================================================================
  // LAYOUT WEB: Formulario en filas
  // ============================================================================

  Widget _buildWebLayout(
    BuildContext context,
    AsyncValue<List<TipoFormacionEntity>> tipoFormacionAsync,
    AsyncValue<List<TipoDuracionFormacionEntity>> tipoDuracionAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Tipo
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildDropdownTipoFormacion(context, tipoFormacionAsync),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildInputDuracion(context),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              flex: 2,
              child: _buildDropdownTipoDuracion(context, tipoDuracionAsync),
            ),
            SizedBox(width: context.spacing),
            _buildActionButtonsWeb(context),
          ],
        ),
        SizedBox(height: context.spacing),
        // Fila 2: Institución
        _buildInputInstitucion(context), // ✅ AGREGAR
        SizedBox(height: context.spacing),
        // Fila 3: Descripción
        _buildInputDescripcion(context),
        SizedBox(height: context.spacing),
        // Fila 4: Fecha
        _buildDatePicker(context),
      ],
    );
  }

  // ============================================================================
  // COMPONENTES
  // ============================================================================

  Widget _buildDropdownTipoFormacion(
    BuildContext context,
    AsyncValue<List<TipoFormacionEntity>> tipoFormacionAsync,
  ) {
    return CustomDropdown<TipoFormacionEntity>(
      asyncValue: tipoFormacionAsync,
      label: 'Tipo de Formación',
      currentValue: _selectedTipoFormacion,
      onChanged: (newValue) {
        setState(() => _selectedTipoFormacion = newValue);
      },
      getName: (e) => e.nombre,
      getCode: (e) => e.codTipos,
      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
    );
  }
    // ✅ AGREGAR CAMPO INSTITUCIÓN
  Widget _buildInputInstitucion(BuildContext context) {
    return TextFormField(
      controller: _institucionController,
      keyboardType: TextInputType.text,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Institución *',
        labelStyle: TextStyle(fontSize: context.bodyFontSize),
        hintText: 'Ej: Universidad Mayor de San Andrés',
        hintStyle: context.bodyLightStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        prefixIcon: const Icon(Icons.business),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.smallSpacing,
          vertical: context.spacing,
        ),
        isDense: true,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'La institución es requerida';
        return null;
      },
    );
  }

  Widget _buildInputDuracion(BuildContext context) {
    return TextFormField(
      controller: _duracionController,
      keyboardType: TextInputType.number,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Duración *',
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
      validator: (val) {
        if (val == null || val.isEmpty) return 'Requerido';
        if (int.tryParse(val) == null) return 'Solo números';
        return null;
      },
    );
  }

  Widget _buildDropdownTipoDuracion(
    BuildContext context,
    AsyncValue<List<TipoDuracionFormacionEntity>> tipoDuracionAsync,
  ) {
    return CustomDropdown<TipoDuracionFormacionEntity>(
      asyncValue: tipoDuracionAsync,
      label: 'Tipo de Duración',
      currentValue: _selectedTipoDuracion,
      onChanged: (newValue) {
        setState(() => _selectedTipoDuracion = newValue);
      },
      getName: (e) => e.nombre,
      getCode: (e) => e.codTipos,
      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return CustomDatePicker(
      controller: _fechaController,
      label: 'Fecha de Finalización',
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
        labelText: 'Descripción / Nombre del Curso *',
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