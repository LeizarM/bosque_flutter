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

class FormularioZona extends ConsumerStatefulWidget{
  final String title;
  final ZonaEntity? zona;
  final int codPersona;
  final int codCiudad; 
  final bool isEditing;
  final Function(ZonaEntity) onSave;
  final VoidCallback onCancel;

  const FormularioZona({
    Key? key,
    required this.title,
    this.zona,
    required this.codCiudad,
    required this.codPersona,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  FormularioZonaState createState() => FormularioZonaState();
}
class FormularioZonaState extends ConsumerState<FormularioZona> {
final _formKey = GlobalKey<FormState>();
  final _zonaController = TextEditingController();
  int? _ciudadSeleccionada;
  int? _paisSeleccionado;
 @override
void initState() {
  super.initState();
  if (widget.isEditing && widget.zona != null) {
    _zonaController.text = widget.zona!.zona;
    _ciudadSeleccionada = widget.zona!.codCiudad;
  } else {
    _ciudadSeleccionada = widget.codCiudad; // valor inicial al agregar

    // Buscar el país correspondiente a la ciudad seleccionada
    Future.microtask(() async {
      // Buscar en todos los países
      final paises = await ref.read(paisProvider.future);
      // Buscar la ciudad en todos los países
      for (final pais in paises) {
  final ciudades = await ref.read(ciudadProvider(pais.codPais).future);
  CiudadEntity? ciudad;
  try {
    ciudad = ciudades.firstWhere((c) => c.codCiudad == widget.codCiudad);
  } catch (_) {
    ciudad = null;
  }
  if (ciudad != null) {
    if (mounted) {
      setState(() {
        _paisSeleccionado = pais.codPais;
      });
    }
    break;
  }
}
    });
  }
}

  @override
  void dispose() {
    _zonaController.dispose();
    super.dispose();
  }
  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_ciudadSeleccionada == null) {
        AppSnackbar.showError(context, 'Debe seleccionar una ciudad');
        return;
      }
      try {
        final zona = widget.isEditing && widget.zona != null
            ? widget.zona!.copyWith(
                codZona: widget.zona!.codZona,
                codCiudad: _ciudadSeleccionada!,
                zona: _zonaController.text,
                audUsuario: await getCodUsuario(),
              )
            : ZonaEntity(
                codZona: 0,
                codCiudad: _ciudadSeleccionada!,
                zona: _zonaController.text,
                audUsuario: await getCodUsuario(), 
              );

        // Verificar si el widget sigue montado antes de continuar
        if (!mounted) return;

        // Llamar a onSave y esperar a que termine
        await widget.onSave(zona);

        // Mostrar SnackBar de éxito
      // Usar los nuevos SnackBars personalizados
      if (context.mounted) {
        if (widget.isEditing) {
          AppSnackbarCustom.showEdit(
            context, 
            'Zona actualizada correctamente'
          );
        } else {
          AppSnackbarCustom.showAdd(
            context, 
            'Zona agregado correctamente'
          );
        }
        Navigator.of(context).pop();
      }

        
      } catch (e) {
        // Mostrar SnackBar de error
      if (context.mounted) {
        AppSnackbar.showError(
          context, 
          'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} la zona'
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
        _buildCiudadDropdown(),
        SizedBox(height: spacing),
        _buildZonaInput(),
        SizedBox(height: spacing),
      ],
    ),
  );
}
  Widget _buildZonaInput() {
    return TextFormField(
      controller: _zonaController,
      decoration: InputDecoration(
        labelText: 'Zona',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
          vertical: 16,
        ),
      ),
      validator: (value) => validarTextoMixto(value, esObligatorio: true),
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
          _ciudadSeleccionada = null; // Limpiar ciudad al cambiar país
        });
      },
      validator: (value) => value == null ? 'Seleccione un país' : null,
    ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => Text('Error: $error'),
  );
}
Widget _buildCiudadDropdown() {
  if (_paisSeleccionado == null) {
    return const SizedBox(); // O un mensaje: "Seleccione un país primero"
  }
  final ciudadesAsync = ref.watch(ciudadProvider(_paisSeleccionado!));

  return ciudadesAsync.when(
    data: (ciudades) => DropdownButtonFormField<int>(
      value: _ciudadSeleccionada,
      decoration: const InputDecoration(
        labelText: 'Ciudad',
        border: OutlineInputBorder(),
      ),
      items: ciudades.map((ciudad) => DropdownMenuItem(
        value: ciudad.codCiudad,
        child: Text(ciudad.ciudad),
      )).toList(),
      onChanged: (value) => setState(() => _ciudadSeleccionada = value),
      validator: (value) => value == null ? 'Seleccione una ciudad' : null,
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