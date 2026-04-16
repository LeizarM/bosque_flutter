import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_duracion_formacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_formacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_formacion.dart';

// ============================================================================
// MAIN WIDGET
// ============================================================================

class DetalleFormacion extends ConsumerStatefulWidget {
  final int codEmpleado;
  final String mode;

  const DetalleFormacion({
    Key? key,
    required this.codEmpleado,
    this.mode = 'nuevo',
  }) : super(key: key);

  @override
  ConsumerState<DetalleFormacion> createState() => _DetalleFormacionState();
}

class _DetalleFormacionState extends ConsumerState<DetalleFormacion> {
  int _editingIndex = -1;
  bool _isAddingNew = false;
  late int _audUsuario;

  @override
  void didUpdateWidget(covariant DetalleFormacion oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mode == 'nuevo' && oldWidget.codEmpleado != widget.codEmpleado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tempFormacionListProvider.notifier).state = [];
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
    final listaFormacion = ref.watch(tempFormacionListProvider);

    // Si tempFormacionListProvider está vacío, cargar del servidor SOLO UNA VEZ
    if (listaFormacion.isEmpty) {
      final formacionDelServidorAsync = ref.watch(
        formacionProvider(widget.codEmpleado),
      );

      return formacionDelServidorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (formacionDelServidor) {
          // IMPORTANTE: Cargar en tempFormacionListProvider SOLO una vez
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(tempFormacionListProvider).isEmpty &&
                formacionDelServidor.isNotEmpty) {
              ref.read(tempFormacionListProvider.notifier).state =
                  formacionDelServidor;
            }
          });
          return _buildUI(context, formacionDelServidor, isEdition: false);
        },
      );
    }

    // Si ya hay datos en temporal, mostrar esos
    return _buildUI(context, listaFormacion, isEdition: false);
  }

  // ============================================================================
  // MODO EDICION: Carga desde servidor
  // ============================================================================

  Widget _buildEdicionMode(BuildContext context) {
    final formacionAsync = ref.watch(formacionProvider(widget.codEmpleado));

    return formacionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data:
          (listaFormacion) =>
              _buildUI(context, listaFormacion, isEdition: true),
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(
    BuildContext context,
    List<FormacionEntity> lista, {
    required bool isEdition,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        Column(
          children: [
            // Lista de formación
            ...List.generate(
              lista.length,
              (idx) =>
                  _editingIndex == idx
                      ? _buildEditForm(context, idx, lista, isEdition)
                      : _buildFormacionCard(
                        context,
                        idx,
                        lista[idx],
                        isEdition,
                      ),
            ),
            // Formulario nuevo si está activo
            if (_isAddingNew) _buildNewForm(context, isEdition),
            // Botón agregar
            if (!_isAddingNew) _buildAddButton(context),
            // Estado vacío
            if (lista.isEmpty && !_isAddingNew) _buildEmptyState(context),
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
          Icon(Icons.class_, size: context.smallIconSize, color: Colors.grey),
          SizedBox(width: context.smallSpacing),
          Text(
            'Formación / Cursos',
            style: context.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE FORMACIÓN (LECTURA)
  // ============================================================================

  Widget _buildFormacionCard(
    BuildContext context,
    int index,
    FormacionEntity formacion,
    bool isEdition,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: context.smallSpacing),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: context.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing,
          vertical: context.smallSpacing,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.lightBlue.shade50,
              child: Icon(
                Icons.menu_book,
                size: context.smallIconSize,
                color: Colors.lightBlue.shade700,
              ),
            ),
            SizedBox(width: context.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo Formación
                  _buildDetailRow(
                    label: 'Tipo Formación:',
                    child: DisplayValue<TipoFormacionEntity>(
                      code: formacion.tipoFormacion,
                      provider: obtenerTipoFormacionProvider,
                      getCode: (tipo) => tipo.codTipos,
                      getDescription: (tipo) => tipo.nombre,
                      fallback: formacion.tipoFormacion,
                      style: context.bodyStyle.copyWith(fontSize: 13),
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Institución
                  _buildDetailRow(
                    label: 'Institución:',
                    child: Text(
                      formacion.institucion.isNotEmpty
                          ? formacion.institucion
                          : 'Sin registrar',
                      style: context.bodyStyle.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Descripción
                  _buildDetailRow(
                    label: 'Descripción:',
                    child: Text(
                      formacion.descripcion.isNotEmpty
                          ? formacion.descripcion
                          : 'Sin registrar',
                      style: context.bodyStyle.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Duración + Tipo (concatenados)
                  _buildDetailRow(
                    label: 'Duración:',
                    child: Row(
                      children: [
                        Text(
                          '${formacion.duracion} ',
                          style: context.bodyLightStyle.copyWith(fontSize: 13),
                        ),
                        Flexible(
                          child: DisplayValue<TipoDuracionFormacionEntity>(
                            code: formacion.tipoDuracion,
                            provider: obtenerTipoDuracionFormacionProvider,
                            getCode: (tipo) => tipo.codTipos,
                            getDescription: (tipo) => tipo.nombre,
                            fallback: formacion.tipoDuracion,
                            style: context.bodyLightStyle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Fecha Finalización
                  _buildDetailRow(
                    label: 'Fecha Finalización:',
                    child: Text(
                      FechaUtils.formatDate(formacion.fechaFormacion),
                      style: context.bodyLightStyle.copyWith(fontSize: 13),
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Botones alineados abajo a la derecha (como en otros detalles)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                        onPressed:
                            () =>
                                isEdition
                                    ? _deleteFromServer(formacion.codFormacion)
                                    : _deleteFromList(index),
                        tooltip: 'Eliminar',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  // ============================================================================
  // FORMULARIOS
  // ============================================================================

  Widget _buildEditForm(
    BuildContext context,
    int index,
    List<FormacionEntity> lista,
    bool isEdition,
  ) {
    return FormFormacion(
      key: ValueKey('edit_formacion_${lista[index].codFormacion}'),
      formacionInicial: lista[index],
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave:
          (formacion) =>
              isEdition
                  ? _saveToServer(formacion)
                  : _updateInList(formacion, index),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _editingIndex = -1);
      },
    );
  }

  Widget _buildNewForm(BuildContext context, bool isEdition) {
    return FormFormacion(
      key: ValueKey('new_formacion_${DateTime.now().millisecondsSinceEpoch}'),
      formacionInicial: FormacionEntity(
        codFormacion: 0,
        codEmpleado: widget.codEmpleado,
        tipoFormacion: '',
        descripcion: '',
        institucion: '', // ✅ AGREGAR
        duracion: 0,
        tipoDuracion: '',
        fechaFormacion: DateTime.now(),
        audUsuario: _audUsuario,
      ),
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave:
          (formacion) =>
              isEdition ? _saveToServer(formacion) : _addToList(formacion),
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
        label: const Text('Agregar formación'),
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
          'No hay formación registrada',
          style: context.bodyLightStyle,
        ),
      ),
    );
  }

  // ============================================================================
  // ACCIONES - MODO NUEVO (TEMPORAL - sin servidor)
  // ============================================================================

  void _startEditing(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = index;
      _isAddingNew = false;
    });
  }

  void _addToList(FormacionEntity formacion) {
    final list = List<FormacionEntity>.from(
      ref.read(tempFormacionListProvider),
    );
    list.add(formacion);
    ref.read(tempFormacionListProvider.notifier).state = list;
    setState(() => _isAddingNew = false);
    showSuccessMessage(context, 'Formación agregada');
  }

  void _updateInList(FormacionEntity formacion, int index) {
    final list = List<FormacionEntity>.from(
      ref.read(tempFormacionListProvider),
    );
    list[index] = formacion;
    ref.read(tempFormacionListProvider.notifier).state = list;
    setState(() => _editingIndex = -1);
    showSuccessMessage(context, 'Formación actualizada');
  }

  void _deleteFromList(int index) {
    final list = List<FormacionEntity>.from(
      ref.read(tempFormacionListProvider),
    );
    list.removeAt(index);
    ref.read(tempFormacionListProvider.notifier).state = list;
    _resetFormState();
    showSuccessMessage(context, 'Formación eliminada');
  }

  // ============================================================================
  // ACCIONES - MODO EDICION (SERVIDOR)
  // ============================================================================

  Future<void> _saveToServer(FormacionEntity formacion) async {
    await executeABM(
      ref: ref,
      context: context,
      operation: () => ref.read(registrarFormacionProvider(formacion).future),
      providersToInvalidate: [formacionProvider(widget.codEmpleado)],
      successMessage: '✅ Formación guardada: ${formacion.descripcion}',
    );

    if (mounted) {
      _resetFormState();
    }
  }

  Future<void> _deleteFromServer(int codFormacion) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () => ref.read(eliminarFormacionProvider(codFormacion).future),
      providersToInvalidate: [formacionProvider(widget.codEmpleado)],
      successMessage: 'Formación eliminada correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Formación',
      confirmationMessage:
          '¿Está seguro de eliminar este registro? No se puede deshacer.',
    );

    if (success && mounted) {
      setState(() => _editingIndex = -1);
    }
  }
}
