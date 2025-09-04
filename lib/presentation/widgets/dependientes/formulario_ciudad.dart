import 'dart:ui';

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioCiudad extends ConsumerStatefulWidget{
  final String title;
  final CiudadEntity? ciudad;
  final int codPais; 
  final bool isEditing;
  final Function(CiudadEntity) onSave;
  final VoidCallback onCancel;

  const FormularioCiudad({
    Key? key,
    required this.title,
    this.ciudad,
    required this.codPais,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  FormularioCiudadState createState() => FormularioCiudadState();
}
class FormularioCiudadState extends ConsumerState<FormularioCiudad> {
final _formKey = GlobalKey<FormState>();
  final _ciudadController = TextEditingController();
  
  int? _paisSeleccionado;
  @override
void initState() {
  super.initState();
  if (widget.isEditing && widget.ciudad != null) {
    _ciudadController.text = widget.ciudad!.ciudad;
    _paisSeleccionado = widget.ciudad!.codPais;
  } else {
    _paisSeleccionado = widget.codPais;
  }
}

  @override
  void dispose() {
    _ciudadController.dispose();
    super.dispose();
  }
  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_paisSeleccionado == null) {
        AppSnackbar.showError(context, 'Debe seleccionar un país');
        return;
      }
      try {
        final ciudad = widget.isEditing && widget.ciudad != null
            ? widget.ciudad!.copyWith(
                codCiudad: widget.ciudad!.codCiudad,
                codPais: _paisSeleccionado!,
                ciudad: _ciudadController.text,
                audUsuario: await getCodUsuario(),
              )
            : CiudadEntity(
                codCiudad: 0,
                codPais: _paisSeleccionado!,
                ciudad: _ciudadController.text,
                audUsuario: await getCodUsuario(),
              );

        // Verificar si el widget sigue montado antes de continuar
        if (!mounted) return;

        // Llamar a onSave y esperar a que termine
        await widget.onSave(ciudad);

        // Mostrar SnackBar de éxito
      // Usar los nuevos SnackBars personalizados
      if (context.mounted) {
        if (widget.isEditing) {
          AppSnackbarCustom.showEdit(
            context, 
            'Ciudad actualizada correctamente'
          );
        } else {
          AppSnackbarCustom.showAdd(
            context, 
            'Ciudad agregada correctamente'
          );
        }
        Navigator.of(context).pop();
      }

    } catch (e) {
      // Mostrar SnackBar de error
      if (context.mounted) {
        AppSnackbar.showError(
          context, 
          'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} la ciudad'
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
        _buildPaisDropdown(),
        SizedBox(height: spacing),
        _buildCiudadInput(),
        SizedBox(height: spacing),
      ],
    ),
  );
}
  Widget _buildCiudadInput() {
    return TextFormField(
      controller: _ciudadController,
      decoration: InputDecoration(
        labelText: 'Ciudad',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
          vertical: 16,
        ),
      ),
      validator: (value) => validarTextoOpcional(value, esObligatorio: true),
    );
  }
  Widget _buildPaisDropdown() {
  final paisesAsync = ref.watch(paisProvider);

  return paisesAsync.when(
    data: (paises) => DropdownButtonFormField<int>(
      value: _paisSeleccionado,
      decoration: const InputDecoration(
        labelText: 'País',
        border: OutlineInputBorder(),
      ),
      items: paises.map((pais) => DropdownMenuItem(
        value: pais.codPais,
        child: Text(pais.pais),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _paisSeleccionado = value;
         // _ciudadSeleccionada = null; // Limpiar ciudad al cambiar país
        });
      },
      validator: (value) => value == null ? 'Seleccione un país' : null,
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Text('Error: $error'),
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