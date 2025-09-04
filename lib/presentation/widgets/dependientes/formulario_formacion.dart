import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/formacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioFormacion extends ConsumerStatefulWidget {
  final String title;
  final FormacionEntity? formacion;
  final int codEmpleado;
  final bool isEditing;
  final Function(FormacionEntity) onSave;
  final VoidCallback onCancel;

  const FormularioFormacion({
    Key? key,
    required this.title,
    this.formacion,
    required this.codEmpleado,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);
  @override
  FormularioFormacionState createState() => FormularioFormacionState();
}

class FormularioFormacionState extends ConsumerState<FormularioFormacion> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _duracionController = TextEditingController();
  final _tipoDuracionController = TextEditingController();
  final _tipoFormacionController = TextEditingController();
  final _fechaFinController = TextEditingController();
  String? _tipoFormacionSeleccionado;
  String? _tipoDuracionSeleccionado;
  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.formacion != null) {
      _descripcionController.text = widget.formacion!.descripcion;
      _duracionController.text = widget.formacion!.duracion.toString();
       // Asignar los valores seleccionados para los dropdowns
    _tipoFormacionSeleccionado = widget.formacion!.tipoFormacion;
    _tipoDuracionSeleccionado = widget.formacion!.tipoDuracion;
    // Los controllers de tipo también se mantienen para respaldo
      _tipoDuracionController.text = widget.formacion!.tipoDuracion;
      _tipoFormacionController.text = widget.formacion!.tipoFormacion;
      _fechaFinController.text = FormatearFecha.formatearFecha(
        widget.formacion!.fechaFormacion,
      );
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _duracionController.dispose();
    _tipoDuracionController.dispose();
    _tipoFormacionController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final formacion =
            widget.isEditing && widget.formacion != null
                ? widget.formacion!.copyWith(
                  codFormacion: widget.formacion!.codFormacion,
                  codEmpleado: widget.codEmpleado,
                  descripcion: _descripcionController.text,
                  duracion: int.parse(_duracionController.text),
                  tipoDuracion:
                      _tipoDuracionSeleccionado ?? _tipoDuracionController.text,
                  tipoFormacion:
                      _tipoFormacionSeleccionado ??
                      _tipoFormacionController.text,
                  fechaFormacion: FormatearFecha.parseFecha(_fechaFinController.text),
                  audUsuario: await getCodUsuario(),
                )
                : FormacionEntity(
                  codFormacion: 0, // Asignar un valor por defecto si es nuevo
                  codEmpleado: widget.codEmpleado,
                  descripcion: _descripcionController.text,
                  duracion: int.parse(_duracionController.text),
                  tipoDuracion:
                      _tipoDuracionSeleccionado ?? _tipoDuracionController.text,
                  tipoFormacion:
                      _tipoFormacionSeleccionado ??
                      _tipoFormacionController.text,
                  fechaFormacion: FormatearFecha.parseFecha(_fechaFinController.text),
                  audUsuario: await getCodUsuario(),
                );

        widget.onSave(formacion);
         // Usar los nuevos SnackBars personalizados
      if (context.mounted) {
        if (widget.isEditing) {
          AppSnackbarCustom.showEdit(
            context, 
            'Formación actualizada correctamente'
          );
        } else {
          AppSnackbarCustom.showAdd(
            context, 
            'Formación agregada correctamente'
          );
        }
        Navigator.of(context).pop();
      }

        
      } catch (e) {
        // Mostrar SnackBar de error
      if (context.mounted) {
        AppSnackbar.showError(
          context, 
          'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} la Formación'
        );
      }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: isDesktop 
              ? screenWidth * 0.5  // 50% del ancho en desktop
              : screenWidth * 0.9, // 90% del ancho en móvil
          constraints: BoxConstraints(
            maxWidth: 800, // Ancho máximo para evitar que sea demasiado ancho
            maxHeight: MediaQuery.of(context).size.height * 0.9, // 90% del alto de la pantalla
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: _buildFormContent(context),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
  final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

  return Form(
    key: _formKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildDescripcionField(),
              _buildTipoFormacionDropdown(),
              if (isDesktop) ...[
                Row(
                  children: [
                    Expanded(child: _buildTipoDuracionDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDuracionField()),
                  ],
                ),
              ] else ...[
                _buildTipoDuracionDropdown(),
                _buildDuracionField(),
              ],
              _buildFechaField(),
              _buildButtons(context),
            ].map((widget) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: widget,
            )).toList(),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
    return Text(
      widget.title,
      style: ResponsiveUtilsBosque.getTitleStyle(context),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescripcionField() {
    return TextFormField(
      controller: _descripcionController,
      decoration: InputDecoration(
        labelText: 'DESCRIPCIÓN DE LA FORMACIÓN',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
        ),
      ),
      maxLines: null, // Permite múltiples líneas
      validator: (value) => validarTextoMixto(value, esObligatorio: true),
      inputFormatters: bloquearEspacios,
    );
  }

  Widget _buildTipoFormacionDropdown() {
  return ref.watch(obtenerTipoFormacionProvider).when(
    data: (tipoFormacion) => DropdownButtonFormField<String>(
      value: tipoFormacion.any((tipo) => tipo.codTipos == (_tipoFormacionSeleccionado ?? _tipoFormacionController.text))
        ? (_tipoFormacionSeleccionado ?? _tipoFormacionController.text)
        : null,
      decoration: InputDecoration(
        labelText: 'TIPO DE FORMACIÓN',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
        ),
      ),
      isExpanded: true,
      items: tipoFormacion.map((tipo) => DropdownMenuItem(
        value: tipo.codTipos,
        child: Text(
          tipo.nombre,
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: (value) => setState(() => _tipoFormacionSeleccionado = value),
      validator: (value) => validarDropdown(value?.toString(), 'tipo de formación'),
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Text('Error: $error'),
  );
}

  Widget _buildTipoDuracionDropdown() {
  return ref.watch(obtenerTipoDuracionFormacionProvider).when(
    data: (tipoDuracion) => DropdownButtonFormField<String>(
      value: tipoDuracion.any((tipo) => tipo.codTipos == (_tipoDuracionSeleccionado ?? _tipoDuracionController.text))
        ? (_tipoDuracionSeleccionado ?? _tipoDuracionController.text)
        : null,
      decoration: InputDecoration(
        labelText: 'TIPO DE DURACIÓN',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
        ),
      ),
      isExpanded: true,
      items: tipoDuracion.map((tipo) => DropdownMenuItem(
        value: tipo.codTipos,
        child: Text(
          tipo.nombre,
          overflow: TextOverflow.ellipsis,
        ),
      )).toList(),
      onChanged: (value) => setState(() => _tipoDuracionSeleccionado = value),
      validator: (value) => validarDropdown(value?.toString(), 'tipo de duración'),
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Text('Error: $error'),
  );
}

  Widget _buildDuracionField() {
    return TextFormField(
      controller: _duracionController,
      decoration: InputDecoration(
        labelText: 'DURACIÓN DE LA FORMACIÓN',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: bloquearEspacios,
      validator: (value) => validarDuracion(
        value,
        _tipoDuracionSeleccionado ?? _tipoDuracionController.text,
        esObligatorio: true
      ),
    );
  }

  Widget _buildFechaField() {
    return DatePickerField(
      controller: _fechaFinController,
      labelText: 'FECHA DE FINALIZACIÓN',
    );
  }

  Widget _buildButtons(BuildContext context) {
    final buttonSpacing = ResponsiveUtilsBosque.getHorizontalPadding(context) / 2;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: buttonSpacing,
              vertical: 12,
            ),
          ),
          child: const Text('Cancelar'),
        ),
        SizedBox(width: buttonSpacing),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: buttonSpacing,
              vertical: 12,
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
