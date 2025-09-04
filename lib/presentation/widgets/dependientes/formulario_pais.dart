import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioPais extends ConsumerStatefulWidget{
  final String title;
  final PaisEntity? pais;

  final bool isEditing;
  final Function(PaisEntity) onSave;
  final VoidCallback onCancel;

  const FormularioPais({
    Key? key,
    required this.title,
    this.pais,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  FormularioPaisState createState() => FormularioPaisState();
}
class FormularioPaisState extends ConsumerState<FormularioPais> {
final _formKey = GlobalKey<FormState>();
  final _paisController = TextEditingController();

  @override
void initState() {
  super.initState();
  if (widget.isEditing && widget.pais != null) {
    _paisController.text = widget.pais!.pais;
  }
}

  @override
  void dispose() {
    _paisController.dispose();
    super.dispose();
  }
  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      
      try {
        final pais = widget.isEditing && widget.pais != null
            ? widget.pais!.copyWith(
                codPais: widget.pais!.codPais,
                pais: _paisController.text,
                audUsuario: await getCodUsuario(),
              )
            : PaisEntity(
                codPais: 0,
                pais: _paisController.text,
                audUsuario: await getCodUsuario(),
              );

        // Verificar si el widget sigue montado antes de continuar
        if (!mounted) return;

        // Llamar a onSave y esperar a que termine
        await widget.onSave(pais);

        // Mostrar SnackBar de éxito
      // Usar los nuevos SnackBars personalizados
      if (context.mounted) {
        if (widget.isEditing) {
          AppSnackbarCustom.showEdit(
            context, 
            'País actualizado correctamente'
          );
        } else {
          AppSnackbarCustom.showAdd(
            context, 
            'País agregado correctamente'
          );
        }
        Navigator.of(context).pop();
      }

    } catch (e) {
      // Mostrar SnackBar de error
      if (context.mounted) {
        AppSnackbar.showError(
          context, 
          'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} el país'
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
          _buildForm(context),
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
  Widget _buildForm(BuildContext context) {
  final spacing = ResponsiveUtilsBosque.getVerticalPadding(context);

  return Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPaisInput(),
        SizedBox(height: spacing),
      ],
    ),
  );
}
  Widget _buildPaisInput() {
    return TextFormField(
      controller: _paisController,
      decoration: InputDecoration(
        labelText: 'País',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
          vertical: 16,
        ),
      ),
      validator: (value) => validarTextoOpcional(value, esObligatorio: true),
    );
  }
  

  Widget _buildButtons(BuildContext context) {
  final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: widget.onCancel,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context) / 2,
            vertical: 12,
          ),
        ),
        child: const Text('Cancelar'),
      ),
      SizedBox(width: ResponsiveUtilsBosque.getHorizontalPadding(context) / 2),
      ElevatedButton(
        onPressed: _handleSubmit,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context) / 2,
            vertical: 12,
          ),
        ),
        child: const Text('Guardar'),
      ),
    ],
  );
}
  
}