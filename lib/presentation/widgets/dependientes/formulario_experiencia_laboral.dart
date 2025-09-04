import 'dart:ui';

import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/experiencia_laboral_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioExperienciaLaboral extends ConsumerStatefulWidget{
  final String title;
  final ExperienciaLaboralEntity? experienciaLaboral;
  final int codEmpleado;
  final bool isEditing;
  final Function(ExperienciaLaboralEntity) onSave;
  final VoidCallback onCancel;

  const FormularioExperienciaLaboral({
    Key? key,
    required this.title,
    this.experienciaLaboral,
    required this.codEmpleado,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  FormularioExperienciaLaboralState createState() => FormularioExperienciaLaboralState();
}
class FormularioExperienciaLaboralState extends ConsumerState<FormularioExperienciaLaboral> {
  final _formKey = GlobalKey<FormState>();
  final _empresaController = TextEditingController();
  final _cargoController = TextEditingController();
  final _fechaInicioController = TextEditingController();
  final _fechaFinController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _nroReferenciaController = TextEditingController();

@override
void initState(){
  super.initState();
  if (widget.isEditing && widget.experienciaLaboral != null) {
    _empresaController.text = widget.experienciaLaboral!.nombreEmpresa;
    _cargoController.text = widget.experienciaLaboral!.cargo;
    _fechaInicioController.text = FormatearFecha.formatearFecha(
        widget.experienciaLaboral!.fechaInicio,
      );
    _fechaFinController.text = FormatearFecha.formatearFecha(
        widget.experienciaLaboral!.fechaFin,
      );
    _descripcionController.text = widget.experienciaLaboral!.descripcion;
    _nroReferenciaController.text = widget.experienciaLaboral!.nroReferencia;
  }
}
@override
void dispose() {
  _empresaController.dispose();
  _cargoController.dispose();
  _fechaInicioController.dispose();
  _fechaFinController.dispose();
  _descripcionController.dispose();
  _nroReferenciaController.dispose();
  super.dispose();
}
Future<int> getCodUsuario() async {
  return await ref.read(userProvider.notifier).getCodUsuario();
}
void _handleSubmit() async {
  if (_formKey.currentState?.validate() ?? false) {
    try {
      final experienciaLaboral = widget.isEditing && widget.experienciaLaboral != null
          ? widget.experienciaLaboral!.copyWith(
              codExperienciaLaboral: widget.experienciaLaboral!.codExperienciaLaboral,
              codEmpleado: widget.codEmpleado,
              nombreEmpresa: _empresaController.text,
              cargo: _cargoController.text,
              fechaInicio: FormatearFecha.parseFecha(_fechaInicioController.text),
              fechaFin: FormatearFecha.parseFecha(_fechaFinController.text),
              descripcion: _descripcionController.text,
              nroReferencia: _nroReferenciaController.text,
              audUsuario: await getCodUsuario(),
            )
          : ExperienciaLaboralEntity(
              codExperienciaLaboral: 0, // Asignar un valor por defecto si es nuevo
              codEmpleado: widget.codEmpleado,
              nombreEmpresa: _empresaController.text,
              cargo: _cargoController.text,
              fechaInicio: FormatearFecha.parseFecha(_fechaInicioController.text),
              fechaFin: FormatearFecha.parseFecha(_fechaFinController.text),
              descripcion: _descripcionController.text,
              nroReferencia: _nroReferenciaController.text,
              audUsuario: await getCodUsuario(),
            );

      widget.onSave(experienciaLaboral);
      // Usar los nuevos SnackBars personalizados
      if (context.mounted) {
        if (widget.isEditing) {
          AppSnackbarCustom.showEdit(
            context, 
            'Experiencia Laboral actualizada correctamente'
          );
        } else {
          AppSnackbarCustom.showAdd(
            context, 
            'Experiencia Laboral agregada correctamente'
          );
        }
        Navigator.of(context).pop();
      }

        
      } catch (e) {
        // Mostrar SnackBar de error
      if (context.mounted) {
        AppSnackbar.showError(
          context, 
          'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} la Experiencia Laboral'
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
            maxWidth: 800,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildInputFields(context),
          const SizedBox(height: 24),
          _buildButtons(context),
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

  Widget _buildInputFields(BuildContext context) {
    final spacing = ResponsiveUtilsBosque.getVerticalPadding(context) / 2;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Wrap(
      runSpacing: spacing,
      children: [
        if (isDesktop) 
          Row(
            children: [
              Expanded(child: _buildTextField(_empresaController, 'EMPRESA')),
              SizedBox(width: spacing),
              Expanded(child: _buildTextField(_cargoController, 'CARGO')),
            ],
          )
        else ...[
          _buildTextField(_empresaController, 'EMPRESA'),
          SizedBox(height: spacing),
          _buildTextField(_cargoController, 'CARGO'),
        ],
        SizedBox(height: spacing),
        if (isDesktop)
          Row(
            children: [
              Expanded(
                child: DatePickerField(
                  controller: _fechaInicioController,
                  labelText: 'FECHA DE INICIO',
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: DatePickerField(
                  controller: _fechaFinController,
                  labelText: 'FECHA DE FINALIZACIÓN',
                ),
              ),
            ],
          )
        else ...[
          DatePickerField(
            controller: _fechaInicioController,
            labelText: 'FECHA DE INICIO',
          ),
          SizedBox(height: spacing),
          DatePickerField(
            controller: _fechaFinController,
            labelText: 'FECHA DE FINALIZACIÓN',
          ),
        ],
        SizedBox(height: spacing),
        _buildTextField(
          _descripcionController, 
          'DESCRIPCIÓN',
          maxLines: 2,
          validator: (value) => validarTextoMixto(value, esObligatorio: false),
        ),
        SizedBox(height: spacing),
        _buildTextField(
          _nroReferenciaController, 
          'NÚMERO DE REFERENCIA',
          validator: (value) => validarSoloNumeros(value, esObligatorio: false),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context) / 2,
        ),
      ),
      maxLines: maxLines ?? 1,
      validator: validator ?? (value) => validarTextoMixto(value, esObligatorio: true),
      inputFormatters: bloquearEspacios,
      style: TextStyle(
        fontSize: ResponsiveUtilsBosque.getResponsiveValue<double>(
          context: context,
          defaultValue: 16,
          mobile: 14,
          tablet: 15,
          desktop: 16,
        ),
      ),
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