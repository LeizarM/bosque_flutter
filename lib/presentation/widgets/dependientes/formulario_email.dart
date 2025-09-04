import 'dart:ui';

import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/email_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioEmail extends ConsumerStatefulWidget {
  final String title;
  final EmailEntity? email;
  final int codPersona;
  final bool isEditing;
  final Function(EmailEntity) onSave;
  final VoidCallback onCancel;

  const FormularioEmail({
    Key? key,
    required this.title,
    this.email,
    required this.codPersona,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  FormularioEmailState createState() => FormularioEmailState();
}
class FormularioEmailState extends ConsumerState<FormularioEmail> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
 

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.email != null) {
      _emailController.text = widget.email!.email;
      
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final email = widget.isEditing && widget.email != null
            ? widget.email!.copyWith(
                codEmail: widget.email!.codEmail,
                codPersona: widget.codPersona,
                email: _emailController.text,
                audUsuario: await getCodUsuario(),
                
              )
            : EmailEntity(
                codEmail: 0, // Asignar un valor por defecto o manejarlo según tu lógica
                codPersona: widget.codPersona,
                email: _emailController.text,
                audUsuario: await getCodUsuario(),
              );

        widget.onSave(email);
         // Usar los nuevos SnackBars personalizados
      if (context.mounted) {
        if (widget.isEditing) {
          AppSnackbarCustom.showEdit(
            context, 
            'Email actualizado correctamente'
          );
        } else {
          AppSnackbarCustom.showAdd(
            context, 
            'Email agregado correctamente'
          );
        }
        Navigator.of(context).pop();
      }

        
      } catch (e) {
        // Mostrar SnackBar de error
      if (context.mounted) {
        AppSnackbar.showError(
          context, 
          'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} el email'
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

    return Container(
      width: isDesktop 
          ? screenWidth * 0.4  // 40% del ancho en desktop
          : screenWidth * 0.9, // 90% del ancho en móvil
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          SizedBox(height: verticalPadding),
          _buildEmailForm(context),
          SizedBox(height: verticalPadding),
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

  Widget _buildEmailForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
            vertical: 16,
          ),
        ),
        validator: validarEmail,
        inputFormatters: bloquearTodosLosEspacios,
        // Aumentar tamaño de fuente en desktop
        style: TextStyle(
          fontSize: ResponsiveUtilsBosque.getResponsiveValue<double>(
            context: context,
            defaultValue: 16,
            mobile: 14,
            desktop: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
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
            minimumSize: Size(
              isDesktop ? 120 : 100,
              isDesktop ? 48 : 40,
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
            minimumSize: Size(
              isDesktop ? 120 : 100,
              isDesktop ? 48 : 40,
            ),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}