import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'form_telefono.dart';

class DetalleTelefono extends ConsumerStatefulWidget {
  final int codPersona;
  final String mode;

  const DetalleTelefono({
    Key? key,
    required this.codPersona,
    this.mode = 'nuevo',
  }) : super(key: key);

  @override
  ConsumerState<DetalleTelefono> createState() => _DetalleTelefonoState();
}

class _DetalleTelefonoState extends ConsumerState<DetalleTelefono> {
  int _editingIndex = -1;
  bool _isAddingNew = false;
  late int _audUsuario;

  @override
void didUpdateWidget(covariant DetalleTelefono oldWidget) {
  super.didUpdateWidget(oldWidget);

  // ✅ AGREGAR: Invalidar cuando cambia codPersona o modo
  if (widget.mode == 'nuevo' && oldWidget.codPersona != widget.codPersona) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(tempTelefonoListProvider.notifier).state = [];
      ref.invalidate(telefonoProvider(oldWidget.codPersona)); // ✅ NUEVO
      ref.invalidate(telefonoProvider(widget.codPersona));    // ✅ NUEVO
      _resetFormState();
    });
  }
  
  // ✅ AGREGAR: Si pasamos de "nuevo" a "edicion" (después de registro)
  if (oldWidget.mode == 'nuevo' && widget.mode == 'edicion') {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(tempTelefonoListProvider);
      ref.invalidate(telefonoProvider(widget.codPersona));
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
    final listaTelefonos = ref.watch(tempTelefonoListProvider);

    // Si tempTelefonoListProvider está vacío, cargar del servidor
    if (listaTelefonos.isEmpty) {
      final telefonosDelServidorAsync =
          ref.watch(telefonoProvider(widget.codPersona));

      return telefonosDelServidorAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (telefonosDelServidor) {
          // IMPORTANTE: Cargar en tempTelefonoListProvider SOLO una vez
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(tempTelefonoListProvider).isEmpty &&
                telefonosDelServidor.isNotEmpty) {
              ref.read(tempTelefonoListProvider.notifier).state =
                  telefonosDelServidor;
            }
          });
          return _buildUI(context, telefonosDelServidor, isEdition: false);
        },
      );
    }

    // Si ya hay datos en temporal, mostrarlos
    return _buildUI(context, listaTelefonos, isEdition: false);
  }

  // ============================================================================
  // MODO EDICION: Carga desde servidor
  // ============================================================================

  Widget _buildEdicionMode(BuildContext context) {
    final telefonosAsync = ref.watch(telefonoProvider(widget.codPersona));

    return telefonosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (listaTelefonos) =>
          _buildUI(context, listaTelefonos, isEdition: true),
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(BuildContext context, List<TelefonoEntity> lista,
      {required bool isEdition}) {
    final tiposAsync = ref.watch(tipoTelefonoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        tiposAsync.when(
          loading: () =>
              const LinearProgressIndicator(minHeight: 2),
          error: (err, _) => Center(
            child: Text('Error cargando tipos: $err'),
          ),
          data: (tiposDisponibles) {
            return Column(
              children: [
                // Lista de teléfonos
                ...List.generate(
                  lista.length,
                  (idx) => _editingIndex == idx
                      ? _buildEditForm(
                          context, idx, lista, tiposDisponibles, isEdition)
                      : _buildTelefonoCard(
                          context, idx, lista[idx], isEdition),
                ),
                // Formulario nuevo si está activo
                if (_isAddingNew)
                  _buildNewForm(context, tiposDisponibles, isEdition),
                // Botón agregar
                if (!_isAddingNew) _buildAddButton(context),
                // Estado vacío
                if (lista.isEmpty && !_isAddingNew)
                  _buildEmptyState(context),
              ],
            );
          },
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
            Icons.phone,
            size: context.smallIconSize,
            color: Colors.grey,
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            'Teléfonos',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE TELÉFONO (LECTURA)
  // ============================================================================

  Widget _buildTelefonoCard(BuildContext context, int index,
      TelefonoEntity telefono, bool isEdition) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: ListTile(
        contentPadding:
            EdgeInsets.symmetric(
              horizontal: context.spacing,
              vertical: context.smallSpacing,
            ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            Icons.phone,
            size: context.smallIconSize,
            color: Colors.blue.shade700,
          ),
        ),
        title: _buildTitle(context, telefono),
        subtitle: _buildSubtitle(context, telefono),
        trailing: _buildActions(context, index, telefono, isEdition),
      ),
    );
  }

 Widget _buildTitle(BuildContext context, TelefonoEntity telefono) {
  return Text(
    telefono.telefono,
    style: context.bodyStyle.copyWith(
      fontWeight: FontWeight.bold,
    ),
    overflow: TextOverflow.ellipsis,
  );
}

  Widget _buildSubtitle(BuildContext context, TelefonoEntity telefono) {
    return Text(
      'Tipo: ${telefono.tipo ?? 'Desconocido'}',
      style: context.bodyLightStyle.copyWith(
        fontSize: context.smallFontSize,
      ),
    );
  }

  Widget _buildActions(BuildContext context, int index,
      TelefonoEntity telefono, bool isEdition) {
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
              ? _deleteFromServer(telefono.codTelefono)
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
      List<TelefonoEntity> lista, List<TipoTelefonoEntity> tipos,
      bool isEdition) {
    return FormTelefono(
      key: ValueKey('edit_telefono_${lista[index].codTelefono}'),
      telefonoInicial: lista[index],
      tiposDisponibles: tipos,
      codPersona: widget.codPersona,
      audUsuario: _audUsuario,
      onSave: (telefono) => isEdition
          ? _saveToServer(telefono)
          : _updateInList(telefono, index),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _editingIndex = -1);
      },
    );
  }

  Widget _buildNewForm(BuildContext context, List<TipoTelefonoEntity> tipos,
      bool isEdition) {
    return FormTelefono(
      key: ValueKey('new_telefono_${DateTime.now().millisecondsSinceEpoch}'),
      telefonoInicial: null,
      tiposDisponibles: tipos,
      codPersona: widget.codPersona,
      audUsuario: _audUsuario,
      onSave: (telefono) =>
          isEdition ? _saveToServer(telefono) : _addToList(telefono),
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
        label: const Text('Agregar teléfono'),
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
          'No hay teléfonos registrados',
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

  void _addToList(TelefonoEntity telefono) {
  final list = List<TelefonoEntity>.from(ref.read(tempTelefonoListProvider));
  list.add(telefono);
  ref.read(tempTelefonoListProvider.notifier).state = list;
  setState(() => _isAddingNew = false);
  showSuccessMessage(context, 'Teléfono agregado');  // ✅ Directo
}

void _updateInList(TelefonoEntity telefono, int index) {
  final list = List<TelefonoEntity>.from(ref.read(tempTelefonoListProvider));
  list[index] = telefono;
  ref.read(tempTelefonoListProvider.notifier).state = list;
  setState(() => _editingIndex = -1);
  showSuccessMessage(context, 'Teléfono actualizado');  // ✅ Directo
}

void _deleteFromList(int index) {
  final list = List<TelefonoEntity>.from(ref.read(tempTelefonoListProvider));
  list.removeAt(index);
  ref.read(tempTelefonoListProvider.notifier).state = list;
  _resetFormState();
  showSuccessMessage(context, 'Teléfono eliminado');  // ✅ Directo
}

  // ============================================================================
  // ACCIONES - MODO EDICION (SERVIDOR)
  // ============================================================================

  Future<void> _saveToServer(TelefonoEntity telefono) async {
    await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(registrarTelefonoProvider(telefono).future),
      providersToInvalidate: [telefonoProvider(widget.codPersona)],
      successMessage: 'Teléfono guardado',
    );

    if (mounted) {
      _resetFormState();
    }
  }

  Future<void> _deleteFromServer(int codTelefono) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(eliminarTelefonoProvider(codTelefono).future),
      providersToInvalidate: [telefonoProvider(widget.codPersona)],
      successMessage: 'Teléfono eliminado correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Teléfono',
      confirmationMessage:
          '¿Está seguro de eliminar este teléfono? No se puede deshacer.',
    );

    if (success && mounted) {
      setState(() => _editingIndex = -1);
    }
  }
}