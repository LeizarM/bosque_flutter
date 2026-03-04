import 'package:bosque_flutter/presentation/widgets/registro_empleado/validadores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class FormTelefono extends ConsumerStatefulWidget {
  final TelefonoEntity? telefonoInicial;
  final List<TipoTelefonoEntity> tiposDisponibles;
  final Function(TelefonoEntity) onSave;
  final VoidCallback onCancel;
  final int codPersona;
  final int audUsuario;

  const FormTelefono({
    Key? key,
    this.telefonoInicial,
    required this.tiposDisponibles,
    required this.onSave,
    required this.onCancel,
    required this.codPersona,
    required this.audUsuario,
  }) : super(key: key);

  @override
  ConsumerState<FormTelefono> createState() => _FormTelefonoState();
}

class _FormTelefonoState extends ConsumerState<FormTelefono> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _numeroController;
  int? _selectedCodTipo;
    String _codigoPais = 'BO';
  String _telefonoSoloNumero = '';
  String _telefonoCompleto = '';

@override
void initState() {
  super.initState();

  _numeroController = TextEditingController(
    text: widget.telefonoInicial?.telefono ?? '',
  );

  _selectedCodTipo = widget.telefonoInicial?.codTipoTel;
  if ((_selectedCodTipo == null || _selectedCodTipo == 0) &&
      widget.tiposDisponibles.isNotEmpty) {
    _selectedCodTipo = widget.tiposDisponibles.first.codTipoTel;
  }

  // Parse initial phone if editing
  if (widget.telefonoInicial != null) {
    _parsePhoneNumber(widget.telefonoInicial!.telefono);
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
    _numeroController.dispose();
    super.dispose();
  }

void _handleSave() async {
  if (_formKey.currentState!.validate() && _selectedCodTipo != null) {
    FocusManager.instance.primaryFocus?.unfocus();

    // Obtener el nombre del tipo seleccionado
    final tipoNombre = widget.tiposDisponibles
        .firstWhere((element) => element.codTipoTel == _selectedCodTipo)
        .tipo;

    final nuevoTelefono = TelefonoEntity(
      codTelefono: widget.telefonoInicial?.codTelefono ?? 0,
      codPersona: widget.codPersona,
      codTipoTel: _selectedCodTipo!,
      telefono: _telefonoCompleto,
      tipo: tipoNombre,
      audUsuario: widget.audUsuario,
    );

    // ✅ VALIDACIÓN DE DUPLICIDAD (consulta BD)
    try {
      await validarTelefonoNoDuplicado(
        numeroTelefono: _telefonoCompleto,
        codTipoTel: _selectedCodTipo!,
        ref: ref,
        codPersona: widget.codPersona,
        codTelefonoEdicion: widget.telefonoInicial?.codTelefono,
      );
    } catch (e) {
      // Mostrar error de duplicidad
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    widget.onSave(nuevoTelefono);
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
          color: Colors.blue.withOpacity(0.02),
          borderRadius: context.borderRadius,
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
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
        _buildDropdownTipo(context),
        SizedBox(height: context.spacing),
        _buildInputNumero(context),
        SizedBox(height: context.spacing),
        _buildActionButtons(context),
      ],
    );
  }

  // ============================================================================
  // LAYOUT WEB: Formulario en fila
  // ============================================================================
Widget _buildWebLayout(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Fila 1: Tipo de teléfono
      Row(
        children: [
          Text(
            'Tipo:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(width: context.spacing),
          Expanded(
            flex: 2,
            child: _buildDropdownTipo(context),
          ),
        ],
      ),
      SizedBox(height: context.spacing * 1.5),
      
      // Fila 2: Número de teléfono
      Row(
        children: [
          Text(
            'Número:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(width: context.spacing),
          Expanded(
            flex: 3,
            child: _buildInputNumero(context),
          ),
        ],
      ),
      SizedBox(height: context.spacing * 2),
      
      // Fila 3: Acciones (alineadas a la derecha)
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildActionButtons(context),
        ],
      ),
    ],
  );
}

  // ============================================================================
  // COMPONENTES
  // ============================================================================

  Widget _buildDropdownTipo(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: _selectedCodTipo,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Tipo',
        labelStyle: TextStyle(fontSize: context.bodyFontSize),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.smallSpacing,
          vertical: context.spacing,
        ),
        isDense: true,
      ),
      items: widget.tiposDisponibles.map((tipo) {
        return DropdownMenuItem<int>(
          value: tipo.codTipoTel,
          child: Text(
            tipo.tipo,
            style: context.bodyStyle,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedCodTipo = val),
      validator: (val) => val == null ? 'Requerido' : null,
    );
  }

Widget _buildInputNumero(BuildContext context) {
  return IntlPhoneField(
    initialValue: _telefonoSoloNumero.isEmpty ? null : _telefonoSoloNumero,
    initialCountryCode: _codigoPais.isEmpty ? 'BO' : _codigoPais,
    decoration: InputDecoration(
      labelText: 'Número',
      labelStyle: TextStyle(fontSize: context.bodyFontSize),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.smallSpacing,
        vertical: context.spacing,
      ),
      isDense: true,
    ),
    disableLengthCheck: false,
    showDropdownIcon: true,
    dropdownIconPosition: IconPosition.trailing,
    validator: (value) {
      if (value == null || value.number.isEmpty) return 'Requerido';
      if (value.number.length < 7) return 'Número muy corto';
      return null;
    },
    onChanged: (phone) {
      setState(() {
        _codigoPais = phone.countryISOCode;
        _telefonoSoloNumero = phone.number;
        _telefonoCompleto = phone.completeNumber;
      });
    },
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
              icon: const Icon(Icons.check),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
            ),
          ),
        ],
      );
    } else {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: _handleSave,
          icon: const Icon(Icons.check),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
          ),
        ),
        SizedBox(width: context.spacing),
        OutlinedButton.icon(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancelar'),
        ),
      ],
    );
    }
  }
}