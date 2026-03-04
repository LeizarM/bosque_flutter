import 'package:bosque_flutter/domain/entities/experiencia_laboral_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormExperienciaLaboral extends ConsumerStatefulWidget {
  final ExperienciaLaboralEntity? experienciaInicial;
  final Function(ExperienciaLaboralEntity) onSave;
  final VoidCallback onCancel;
  final int codEmpleado;
  final int audUsuario;

  const FormExperienciaLaboral({
    Key? key,
    this.experienciaInicial,
    required this.onSave,
    required this.onCancel,
    required this.codEmpleado,
    required this.audUsuario,
  }) : super(key: key);

  @override
  ConsumerState<FormExperienciaLaboral> createState() =>
      _FormExperienciaLaboralState();
}

class _FormExperienciaLaboralState
    extends ConsumerState<FormExperienciaLaboral> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _empresaController;
  late TextEditingController _cargoController;
  late TextEditingController _descripcionController;
  late TextEditingController _fechaInicioController;
  late TextEditingController _fechaFinController;
  late TextEditingController _nroReferenciaController;

  @override
  void initState() {
    super.initState();
    final initial = widget.experienciaInicial;

    _empresaController =
        TextEditingController(text: initial?.nombreEmpresa ?? '');
    _cargoController = TextEditingController(text: initial?.cargo ?? '');
    _descripcionController =
        TextEditingController(text: initial?.descripcion ?? '');
    _nroReferenciaController =
        TextEditingController(text: initial?.nroReferencia ?? '');

    final initialDateIni = initial?.fechaInicio ?? DateTime.now();
    _fechaInicioController = TextEditingController(
      text: FechaUtils.formatDate(initialDateIni),
    );

    final initialDateFin = initial?.fechaFin ?? DateTime.now();
    _fechaFinController = TextEditingController(
      text: FechaUtils.formatDate(initialDateFin),
    );
  }

  @override
  void didUpdateWidget(covariant FormExperienciaLaboral oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.experienciaInicial != oldWidget.experienciaInicial) {
      final initial = widget.experienciaInicial;

      _empresaController.text = initial?.nombreEmpresa ?? '';
      _cargoController.text = initial?.cargo ?? '';
      _descripcionController.text = initial?.descripcion ?? '';
      _nroReferenciaController.text = initial?.nroReferencia ?? '';

      final initialDateIni = initial?.fechaInicio ?? DateTime.now();
      _fechaInicioController.text = FechaUtils.formatDate(initialDateIni);

      final initialDateFin = initial?.fechaFin ?? DateTime.now();
      _fechaFinController.text = FechaUtils.formatDate(initialDateFin);
    }
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _cargoController.dispose();
    _descripcionController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _nroReferenciaController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      final fechaInicioSeleccionada =
          FechaUtils.parseDate(_fechaInicioController.text) ?? DateTime.now();
      final fechaFinSeleccionada =
          FechaUtils.parseDate(_fechaFinController.text) ?? DateTime.now();

      final experienciaGuardada = ExperienciaLaboralEntity(
        codExperienciaLaboral:
            widget.experienciaInicial?.codExperienciaLaboral ?? 0,
        codEmpleado: widget.codEmpleado,
        nombreEmpresa: _empresaController.text.trim(),
        cargo: _cargoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        fechaInicio: fechaInicioSeleccionada,
        fechaFin: fechaFinSeleccionada,
        nroReferencia: _nroReferenciaController.text.trim(),
        audUsuario: widget.audUsuario,
      );

      widget.onSave(experienciaGuardada);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        margin: EdgeInsets.only(bottom: context.smallSpacing),
        padding: EdgeInsets.all(context.spacing),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.05),
          borderRadius: context.borderRadius,
          border: Border.all(color: Colors.teal.withOpacity(0.5)),
        ),
        child: context.isMobile
            ? _buildMobileLayout(context)
            : _buildWebLayout(context),
      ),
    );
  }

  // ============================================================================
  // LAYOUT MÓVIL: Formulario apilado verticalmente
  // ============================================================================

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputEmpresa(context),
        SizedBox(height: context.spacing),
        _buildInputCargo(context),
        SizedBox(height: context.spacing),
        _buildInputDescripcion(context),
        SizedBox(height: context.spacing),
        // Fila: Fechas en dos columnas
        Row(
          children: [
            Expanded(
              child: _buildDatePickerInicio(context),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildDatePickerFin(context),
            ),
          ],
        ),
        SizedBox(height: context.spacing),
        _buildInputNroReferencia(context),
        SizedBox(height: context.spacing),
        _buildActionButtonsMobile(context),
      ],
    );
  }

  // ============================================================================
  // LAYOUT WEB: Formulario en filas
  // ============================================================================

  Widget _buildWebLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fila 1: Empresa y Botones
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInputEmpresa(context),
            ),
            SizedBox(width: context.spacing),
            _buildActionButtonsWeb(context),
          ],
        ),
        SizedBox(height: context.spacing),
        // Fila 2: Cargo
        _buildInputCargo(context),
        SizedBox(height: context.spacing),
        // Fila 3: Descripción
        _buildInputDescripcion(context),
        SizedBox(height: context.spacing),
        // Fila 4: Fechas en dos columnas
        Row(
          children: [
            Expanded(
              child: _buildDatePickerInicio(context),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildDatePickerFin(context),
            ),
          ],
        ),
        SizedBox(height: context.spacing),
        // Fila 5: Nro. Referencia
        _buildInputNroReferencia(context),
      ],
    );
  }

  // ============================================================================
  // COMPONENTES
  // ============================================================================

  Widget _buildInputEmpresa(BuildContext context) {
    return TextFormField(
      controller: _empresaController,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Nombre de la Empresa *',
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

  Widget _buildInputCargo(BuildContext context) {
    return TextFormField(
      controller: _cargoController,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Cargo Desempeñado *',
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

  Widget _buildInputDescripcion(BuildContext context) {
    return TextFormField(
      controller: _descripcionController,
      keyboardType: TextInputType.multiline,
      minLines: 2,
      maxLines: 4,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Descripción de funciones / logros *',
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

  Widget _buildDatePickerInicio(BuildContext context) {
    return CustomDatePicker(
      controller: _fechaInicioController,
      label: 'Fecha de Inicio',
      validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
      lastDate: DateTime.now(),
      firstDate: DateTime(1900),
    );
  }

  Widget _buildDatePickerFin(BuildContext context) {
    return CustomDatePicker(
      controller: _fechaFinController,
      label: 'Fecha de Fin',
      validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
      lastDate: DateTime.now(),
      firstDate: DateTime(1900),
    );
  }

  Widget _buildInputNroReferencia(BuildContext context) {
    return TextFormField(
      controller: _nroReferenciaController,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Nro. Referencia (Opcional)',
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