import 'package:bosque_flutter/domain/entities/tipo_relacion_laboral_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';

class FormRelacionLaboral extends ConsumerStatefulWidget {
  final RelacionLaboralEntity? relacionInicial;
  final Function(RelacionLaboralEntity) onSave;
  final VoidCallback onCancel;
  final int codEmpleado;
  final int audUsuario;
  final VoidCallback? onSaved;
  final bool forceInactivo;

  const FormRelacionLaboral({
    Key? key,
    this.relacionInicial,
    required this.onSave,
    required this.onCancel,
    required this.codEmpleado,
    required this.audUsuario,
    this.onSaved,
    this.forceInactivo = false,
  }) : super(key: key);

  @override
  ConsumerState<FormRelacionLaboral> createState() =>
      _FormRelacionLaboralState();
}

class _FormRelacionLaboralState extends ConsumerState<FormRelacionLaboral> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fechaInicioController;
  late TextEditingController _fechaFinController;
  late TextEditingController _motivoFinController;

  String? _selectedTipoRelacion;
  bool _esActivo = true;

  @override
  void initState() {
    super.initState();

    _selectedTipoRelacion = widget.relacionInicial?.tipoRel.isNotEmpty == true
        ? widget.relacionInicial!.tipoRel
        : null;

    _esActivo = (widget.relacionInicial?.esActivo ?? 1) == 1;

    final initialDateIni = widget.relacionInicial?.fechaIni ?? DateTime.now();
    _fechaInicioController = TextEditingController(
      text: FechaUtils.formatDate(initialDateIni),
    );

    final initialDateFin = widget.relacionInicial?.fechaFin ?? DateTime.now();
    _fechaFinController = TextEditingController(
      text: !_esActivo ? FechaUtils.formatDate(initialDateFin) : '',
    );

    _motivoFinController = TextEditingController(
      text: widget.relacionInicial?.motivoFin ?? '',
    );
  }

  @override
  void dispose() {
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    _motivoFinController.dispose();
    super.dispose();
  }

  String? _validateFechaFin(String? value) {
    if (!_esActivo && (value == null || value.isEmpty)) {
      return 'Requerido';
    }
    if (_esActivo) return null;

    final fechaIni = FechaUtils.parseDate(_fechaInicioController.text);
    final fechaFin = value != null ? FechaUtils.parseDate(value) : null;

    if (fechaFin == null) return 'Fecha inválida';

    if (fechaIni != null) {
      if (fechaFin.isBefore(fechaIni)) {
        return 'La fecha de fin debe ser mayor a la fecha de inicio';
      }
      if (fechaFin.isAtSameMomentAs(fechaIni)) {
        return 'La fecha de fin no puede ser igual a la fecha de inicio';
      }
    }

    return null;
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      final fechaIni = FechaUtils.parseDate(_fechaInicioController.text) ?? DateTime.now();
      final fechaFin = !_esActivo
          ? FechaUtils.parseDate(_fechaFinController.text)
          : null;

      final relacionGuardada = RelacionLaboralEntity(
        codRelEmplEmpr: widget.relacionInicial?.codRelEmplEmpr ?? 0,
        codEmpleado: widget.codEmpleado,
        esActivo: _esActivo ? 1 : 0,
        tipoRel: _selectedTipoRelacion!,
        nombreFileContrato: widget.relacionInicial?.nombreFileContrato ?? '',
        fechaIni: fechaIni,
        fechaFin: fechaFin,
        motivoFin: _motivoFinController.text.trim(),
        audUsuario: widget.audUsuario,
        fechaInicioBeneficio: widget.relacionInicial?.fechaInicioBeneficio,
        fechaInicioPlanilla: widget.relacionInicial?.fechaInicioPlanilla,
        datoFechasBeneficio: widget.relacionInicial?.datoFechasBeneficio,
        cargo: widget.relacionInicial?.cargo ?? '',
        sucursal: widget.relacionInicial?.sucursal ?? '',
        empresaFiscal: widget.relacionInicial?.empresaFiscal ?? '',
        empresaInterna: widget.relacionInicial?.empresaInterna ?? '',
      );

      widget.onSave(relacionGuardada);
    }
  }

  @override
  Widget build(BuildContext context) {
    return context.isMobile
        ? _buildMobileView(context)
        : _buildWebView(context);
  }

  Widget _buildMobileView(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing),
      child: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(context.spacing),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.05),
            borderRadius: context.borderRadius,
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBasicaSection(context),
              SizedBox(height: context.largeSpacing),
              if (!_esActivo) ...[
                const Divider(height: 24),
                _buildTerminoSection(context),
                SizedBox(height: context.largeSpacing),
              ],
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebView(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(context.spacing),
      child: Form(
        key: _formKey,
        child: Container(
          padding: EdgeInsets.all(context.spacing),
          decoration: BoxDecoration(
            color: Colors.lightBlue.withOpacity(0.05),
            borderRadius: context.borderRadius,
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoBasicaSection(context),
              SizedBox(height: context.largeSpacing),
              if (!_esActivo) ...[
                const Divider(height: 24),
                _buildTerminoSection(context),
                SizedBox(height: context.largeSpacing),
              ],
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBasicaSection(BuildContext context) {
    final tiposRelacionAsync = ref.watch(getTipoRelacionLaboral);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Información Básica'),
        SizedBox(height: context.spacing),
        CustomDropdown<TipoRelacionLaboralEntity>(
          asyncValue: tiposRelacionAsync,
          label: 'Tipo de Relación *',
          currentValue: _selectedTipoRelacion,
          onChanged: (newValue) {
            setState(() => _selectedTipoRelacion = newValue);
          },
          getName: (e) => e.nombre,
          getCode: (e) => e.codTipos,
        ),
        SizedBox(height: context.spacing),
        _buildFechaAndEstadoRow(context),
      ],
    );
  }

  Widget _buildFechaAndEstadoRow(BuildContext context) {
    if (context.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomDatePicker(
            controller: _fechaInicioController,
            label: 'Fecha de Inicio *',
            validator: (val) =>
                (val == null || val.isEmpty) ? 'Requerido' : null,
            lastDate: DateTime(2050),
            firstDate: DateTime(1900),
          ),
          SizedBox(height: context.spacing),
          _buildEstadoSwitch(context),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: CustomDatePicker(
            controller: _fechaInicioController,
            label: 'Fecha de Inicio *',
            validator: (val) =>
                (val == null || val.isEmpty) ? 'Requerido' : null,
            lastDate: DateTime(2050),
            firstDate: DateTime(1900),
          ),
        ),
        SizedBox(width: context.spacing),
        Expanded(
          flex: 1,
          child: _buildEstadoSwitch(context),
        ),
      ],
    );
  }

  Widget _buildEstadoSwitch(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado',
          style: context.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: context.smallSpacing),
        Container(
          padding: EdgeInsets.symmetric(horizontal: context.smallSpacing),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _esActivo ? 'Activo' : 'Inactivo',
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _esActivo,
                onChanged: widget.forceInactivo
                    ? null
                    : (value) {
                        setState(() {
                          _esActivo = value;
                          if (_esActivo) {
                            _fechaFinController.clear();
                            _motivoFinController.clear();
                          }
                        });
                      },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTerminoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Información de Término'),
        SizedBox(height: context.spacing),
        CustomDatePicker(
          controller: _fechaFinController,
          label: 'Fecha de Fin *',
          validator: _validateFechaFin,
          lastDate: DateTime(2050),
          firstDate: DateTime(1900),
        ),
        SizedBox(height: context.spacing),
        TextFormField(
          controller: _motivoFinController,
          keyboardType: TextInputType.multiline,
          minLines: 4,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: 'Motivo del Término *',
            hintText:
                'Describa el motivo por el cual finaliza la relación laboral',
            border: const OutlineInputBorder(),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.all(context.smallSpacing),
          ),
          style: context.bodyStyle,
          validator: (val) {
            if (!_esActivo && (val == null || val.isEmpty)) {
              return 'Requerido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (context.isMobile) {
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
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancelar'),
        ),
        SizedBox(width: context.spacing),
        ElevatedButton.icon(
          onPressed: _handleSave,
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: context.smallSpacing),
        Text(
          title,
          style: context.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}