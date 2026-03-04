import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/email_entity.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'form_email.dart';

class DetalleEmail extends ConsumerStatefulWidget {
  final int codPersona;
  final String mode;

  const DetalleEmail({
    Key? key,
    required this.codPersona,
    this.mode = 'nuevo',
  }) : super(key: key);

  @override
  ConsumerState<DetalleEmail> createState() => _DetalleEmailState();
}

class _DetalleEmailState extends ConsumerState<DetalleEmail> {
  int _editingIndex = -1;
  bool _isAddingNew = false;
  late int _audUsuario;

 @override
void didUpdateWidget(covariant DetalleEmail oldWidget) {
  super.didUpdateWidget(oldWidget);

  // ✅ AGREGAR: Invalidar cuando cambia codPersona o modo
  if (widget.mode == 'nuevo' && oldWidget.codPersona != widget.codPersona) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tempEmailListProvider.notifier).state = [];
      ref.invalidate(emailProvider(oldWidget.codPersona)); // ✅ NUEVO
      ref.invalidate(emailProvider(widget.codPersona));    // ✅ NUEVO
      _resetFormState();
    });
  }
  
  // ✅ AGREGAR: Si pasamos de "nuevo" a "edicion"
  if (oldWidget.mode == 'nuevo' && widget.mode == 'edicion') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(tempEmailListProvider);
      ref.invalidate(emailProvider(widget.codPersona));
      _resetFormState();
    });
  }
}

  void _resetFormState() {
    setState(() {
      _editingIndex = -1;
      _isAddingNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _audUsuario = user?.codUsuario ?? 0;

    return widget.mode == 'nuevo'
        ? _buildNuevoMode(context)
        : _buildEdicionMode(context);
  }

  // ============================================================================
  // MODO NUEVO: Carga desde temporal
  // ============================================================================

  Widget _buildNuevoMode(BuildContext context) {
    final listaEmails = ref.watch(tempEmailListProvider);

    // Si tempEmailListProvider está vacío, cargar del servidor
    if (listaEmails.isEmpty) {
      final emailsDelServidorAsync =
          ref.watch(emailProvider(widget.codPersona));

      return emailsDelServidorAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (emailsDelServidor) {
          // IMPORTANTE: Cargar en tempEmailListProvider SOLO una vez
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(tempEmailListProvider).isEmpty &&
                emailsDelServidor.isNotEmpty) {
              ref.read(tempEmailListProvider.notifier).state =
                  emailsDelServidor;
            }
          });
          return _buildUI(context, emailsDelServidor, isEdition: false);
        },
      );
    }

    // Si ya hay datos en temporal, mostrarlos
    return _buildUI(context, listaEmails, isEdition: false);
  }

  // ============================================================================
  // MODO EDICION: Carga desde servidor
  // ============================================================================

  Widget _buildEdicionMode(BuildContext context) {
    final emailsAsync = ref.watch(emailProvider(widget.codPersona));

    return emailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (listaEmails) =>
          _buildUI(context, listaEmails, isEdition: true),
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(BuildContext context, List<EmailEntity> lista,
      {required bool isEdition}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        Column(
          children: [
            // Lista de emails
            ...List.generate(
              lista.length,
              (idx) => _editingIndex == idx
                  ? _buildEditForm(context, idx, lista, isEdition)
                  : _buildEmailCard(context, idx, lista[idx], isEdition),
            ),
            // Formulario nuevo si está activo
            if (_isAddingNew) _buildNewForm(context, isEdition),
            // Botón agregar
            if (!_isAddingNew) _buildAddButton(context),
            // Estado vacío
            if (lista.isEmpty && !_isAddingNew)
              _buildEmptyState(context),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // HEADER
  // ============================================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.smallSpacing),
      child: Row(
        children: [
          Icon(
            Icons.email,
            size: context.smallIconSize,
            color: Colors.grey,
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            'Correos Electrónicos',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE EMAIL (LECTURA)
  // ============================================================================

  Widget _buildEmailCard(BuildContext context, int index,
      EmailEntity email, bool isEdition) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing,
          vertical: context.smallSpacing,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade50,
          child: Icon(
            Icons.mail_outline,
            size: context.smallIconSize,
            color: Colors.red.shade700,
          ),
        ),
        title: _buildTitle(context, email),
        trailing: _buildActions(context, index, email, isEdition),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, EmailEntity email) {
    return Text(
      email.email,
      style: context.bodyStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActions(BuildContext context, int index,
      EmailEntity email, bool isEdition) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit_outlined,
            size: context.smallIconSize,
            color: Colors.blueGrey,
          ),
          onPressed: () => _startEditing(index),
          tooltip: 'Editar',
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: context.smallIconSize,
            color: Colors.redAccent,
          ),
          onPressed: () => isEdition
              ? _deleteFromServer(email.codEmail)
              : _deleteFromList(index),
          tooltip: 'Eliminar',
        ),
      ],
    );
  }

  // ============================================================================
  // FORMULARIOS
  // ============================================================================

  Widget _buildEditForm(BuildContext context, int index,
      List<EmailEntity> lista, bool isEdition) {
    return FormEmail(
      key: ValueKey('edit_email_${lista[index].codEmail}'),
      emailInicial: lista[index],
      codPersona: widget.codPersona,
      audUsuario: _audUsuario,
      onSave: (email) => isEdition
          ? _saveToServer(email)
          : _updateInList(email, index),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _editingIndex = -1);
      },
    );
  }

  Widget _buildNewForm(BuildContext context, bool isEdition) {
    return FormEmail(
      key: ValueKey('new_email_${DateTime.now().millisecondsSinceEpoch}'),
      emailInicial: null,
      codPersona: widget.codPersona,
      audUsuario: _audUsuario,
      onSave: (email) =>
          isEdition ? _saveToServer(email) : _addToList(email),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _isAddingNew = false);
      },
    );
  }

  // ============================================================================
  // BOTONES Y ESTADOS
  // ============================================================================

  Widget _buildAddButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Agregar correo electrónico'),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _isAddingNew = true);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing),
      child: Center(
        child: Text(
          'No hay correos electrónicos registrados',
          style: context.bodyLightStyle,
        ),
      ),
    );
  }

  // ============================================================================
  // ACCIONES - MODO NUEVO (TEMPORAL)
  // ============================================================================

  void _startEditing(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = index;
      _isAddingNew = false;
    });
  }

  void _addToList(EmailEntity email) {
    final list = List<EmailEntity>.from(
        ref.read(tempEmailListProvider));
    list.add(email);
    ref.read(tempEmailListProvider.notifier).state = list;
    setState(() => _isAddingNew = false);
    showSuccessMessage(context, 'Correo agregado');
  }

  void _updateInList(EmailEntity email, int index) {
    final list = List<EmailEntity>.from(
        ref.read(tempEmailListProvider));
    list[index] = email;
    ref.read(tempEmailListProvider.notifier).state = list;
    setState(() => _editingIndex = -1);
    showSuccessMessage(context, 'Correo actualizado');
  }

  void _deleteFromList(int index) {
    final list = List<EmailEntity>.from(
        ref.read(tempEmailListProvider));
    list.removeAt(index);
    ref.read(tempEmailListProvider.notifier).state = list;
    _resetFormState();
    showSuccessMessage(context, 'Correo eliminado');
  }

  // ============================================================================
  // ACCIONES - MODO EDICION (SERVIDOR)
  // ============================================================================

  Future<void> _saveToServer(EmailEntity email) async {
    await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(registrarEmailProvider(email).future),
      providersToInvalidate: [emailProvider(widget.codPersona)],
      successMessage: '✅ Correo guardado: ${email.email}',
    );

    if (mounted) {
      _resetFormState();
    }
  }

  Future<void> _deleteFromServer(int codEmail) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(eliminarEmailProvider(codEmail).future),
      providersToInvalidate: [emailProvider(widget.codPersona)],
      successMessage: 'Correo eliminado correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Correo Electrónico',
      confirmationMessage:
          '¿Está seguro de eliminar este correo? No se puede deshacer.',
    );

    if (success && mounted) {
      setState(() => _editingIndex = -1);
    }
  }
}