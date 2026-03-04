import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/email_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';

class FormEmail extends ConsumerStatefulWidget {
  final EmailEntity? emailInicial;
  final Function(EmailEntity) onSave;
  final VoidCallback onCancel;
  final int codPersona;
  final int audUsuario;

  const FormEmail({
    Key? key,
    this.emailInicial,
    required this.onSave,
    required this.onCancel,
    required this.codPersona,
    required this.audUsuario,
  }) : super(key: key);

  @override
  ConsumerState<FormEmail> createState() => _FormEmailState();
}

class _FormEmailState extends ConsumerState<FormEmail> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.emailInicial?.email ?? '',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Requerido';
    }

    // Validación básica de email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Correo inválido';
    }

    return null;
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      final nuevoEmail = EmailEntity(
        codEmail: widget.emailInicial?.codEmail ?? 0,
        codPersona: widget.codPersona,
        email: _emailController.text.trim(),
        audUsuario: widget.audUsuario,
      );

      widget.onSave(nuevoEmail);
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
          color: Colors.red.withOpacity(0.02),
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
        _buildInputEmail(context),
        SizedBox(height: context.spacing),
        _buildActionButtons(context),
      ],
    );
  }

  // ============================================================================
  // LAYOUT WEB: Formulario en fila
  // ============================================================================
  Widget _buildWebLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInputEmail(context),
        ),
        SizedBox(width: context.spacing),
        _buildActionButtons(context),
      ],
    );
  }

  // ============================================================================
  // COMPONENTES
  // ============================================================================

  Widget _buildInputEmail(BuildContext context) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: context.bodyStyle,
      decoration: InputDecoration(
        labelText: 'Correo Electrónico *',
        labelStyle: TextStyle(fontSize: context.bodyFontSize),
        hintText: 'nombre@ejemplo.com',
        hintStyle: context.bodyLightStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.smallSpacing,
          vertical: context.spacing,
        ),
        isDense: true,
        prefixIcon: Icon(
          Icons.email_outlined,
          size: context.smallIconSize,
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: context.spacing * 3,
        ),
      ),
      validator: _validateEmail,
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
}