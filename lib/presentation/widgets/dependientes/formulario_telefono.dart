import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';


class FormularioTelefono extends ConsumerStatefulWidget {
  final String title;
  final TelefonoEntity? telefono;
  final int codPersona;
  final bool isEditing;
  final Function(TelefonoEntity) onSave;
  final VoidCallback onCancel;

  const FormularioTelefono({
    Key? key,
    required this.title,
    this.telefono,
    required this.codPersona,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  FormularioTelefonoState createState() => FormularioTelefonoState();
}

class FormularioTelefonoState extends ConsumerState<FormularioTelefono> {
  final _formKey = GlobalKey<FormState>();
  //final _telefonoController = TextEditingController();
  int? _tipoSeleccionado;

String _codigoPais = 'BO'; 
  String _telefonoSoloNumero = '';
  String _telefonoCompleto = '';
  

 @override
void initState() {
  super.initState();
  if (widget.isEditing && widget.telefono != null) {
    _parsePhoneNumber(widget.telefono!.telefono);
    _tipoSeleccionado = widget.telefono!.codTipoTel;
  }
}
 
Future<void> _parsePhoneNumber(String telefono) async {
  try {
    final phoneNumber = PhoneNumber.parse(telefono);
    setState(() {
      _codigoPais = phoneNumber.isoCode.name;
      _telefonoSoloNumero = phoneNumber.nsn;
      _telefonoCompleto = phoneNumber.international;
    });
  } catch (e) {
    setState(() {
      _codigoPais = 'BO';
      _telefonoSoloNumero = telefono;
      _telefonoCompleto = telefono;
    });
  }
}


  @override
  void dispose() {
    //_telefonoController.dispose();
    super.dispose();
  }
  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final telefono = widget.isEditing && widget.telefono != null
            ? widget.telefono!.copyWith(
                codTelefono: widget.telefono!.codTelefono,
                codPersona: widget.codPersona,
                telefono: _telefonoCompleto,
                codTipoTel: _tipoSeleccionado ?? widget.telefono!.codTipoTel,
                audUsuario: await getCodUsuario(),
              )
            : TelefonoEntity(
                codTelefono: 0,
                codPersona: widget.codPersona,
                telefono: _telefonoCompleto,
                codTipoTel: _tipoSeleccionado ??1 ,
                audUsuario: await getCodUsuario(), 
              );

        // Verificar si el widget sigue montado antes de continuar
        if (!mounted) return;

        // Llamar a onSave y esperar a que termine
        await widget.onSave(telefono);

        // Mostrar SnackBar de éxito
      // Usar los nuevos SnackBars personalizados
      if (context.mounted) {
        if (widget.isEditing) {
          AppSnackbarCustom.showEdit(
            context, 
            'Teléfono actualizado correctamente'
          );
        } else {
          AppSnackbarCustom.showAdd(
            context, 
            'Teléfono agregado correctamente'
          );
        }
        Navigator.of(context).pop();
      }

        
      } catch (e) {
        // Mostrar SnackBar de error
      if (context.mounted) {
        AppSnackbar.showError(
          context, 
          'Error al ${widget.isEditing ? 'actualizar' : 'agregar'} el teléfono'
        );
      }
      }
    }
  }
//check point
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
          // Contenido del formulario
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
          _buildPhoneInput(),
          SizedBox(height: spacing),
          _buildPhoneTypeDropdown(),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return IntlPhoneField(
      initialValue: _telefonoSoloNumero,
      initialCountryCode: _codigoPais, // Debe ser 'BO'
      decoration: InputDecoration(
        labelText: 'Número de teléfono',
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
          vertical: 16,
        ),
      ),
      validator: (value) => validarSoloNumeros(value?.number, esObligatorio: true),
      onChanged: (phone) {
        _codigoPais = phone.countryISOCode; // Ejemplo: 'BO'
        _telefonoSoloNumero = phone.number;
        _telefonoCompleto = phone.completeNumber;
      },
      disableLengthCheck: false,
      showDropdownIcon: true,
      dropdownIconPosition: IconPosition.trailing,
    );
  }

  Widget _buildPhoneTypeDropdown() {
    final tiposTelefonoAsync = ref.watch(tipoTelefonoProvider);
    
    return tiposTelefonoAsync.when(
      data: (tiposTelefono) => DropdownButtonFormField<int>(
        value: _tipoSeleccionado,
        decoration: InputDecoration(
          labelText: 'Tipo de teléfono',
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
            vertical: 16,
          ),
        ),
        items: tiposTelefono.map((tipo) => DropdownMenuItem(
          value: tipo.codTipoTel,
          child: Text(tipo.tipo),
        )).toList(),
        onChanged: (value) => setState(() => _tipoSeleccionado = value),
        validator: (value) => validarDropdown(value?.toString(), 'tipo de teléfono'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('Error: $error'),
    );
  }

  Widget _buildButtons(BuildContext context) {
   // final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    
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


