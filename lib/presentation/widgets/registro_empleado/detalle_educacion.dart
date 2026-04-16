import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/educacion_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_educacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_educacion.dart';

// ============================================================================
// MAIN WIDGET
// ============================================================================

class DetalleEducacion extends ConsumerStatefulWidget {
  final int codEmpleado;
  final String mode;

  const DetalleEducacion({
    Key? key,
    required this.codEmpleado,
    this.mode = 'nuevo',
  }) : super(key: key);

  @override
  ConsumerState<DetalleEducacion> createState() => _DetalleEducacionState();
}

class _DetalleEducacionState extends ConsumerState<DetalleEducacion> {
  int _editingIndex = -1;
  bool _isAddingNew = false;
  late int _audUsuario;

  @override
  void didUpdateWidget(covariant DetalleEducacion oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mode == 'nuevo' && oldWidget.codEmpleado != widget.codEmpleado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tempEducacionListProvider.notifier).state = [];
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
    final listaEducacion = ref.watch(tempEducacionListProvider);

    // Si tempEducacionListProvider está vacío, cargar del servidor SOLO UNA VEZ
    if (listaEducacion.isEmpty) {
      final educacionDelServidorAsync = ref.watch(
        educacionProvider(widget.codEmpleado),
      );

      return educacionDelServidorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (educacionDelServidor) {
          // IMPORTANTE: Cargar en tempEducacionListProvider SOLO una vez
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(tempEducacionListProvider).isEmpty &&
                educacionDelServidor.isNotEmpty) {
              ref.read(tempEducacionListProvider.notifier).state =
                  educacionDelServidor;
            }
          });
          return _buildUI(context, educacionDelServidor, isEdition: false);
        },
      );
    }

    // Si ya hay datos en temporal, mostrar esos
    return _buildUI(context, listaEducacion, isEdition: false);
  }

  // ============================================================================
  // MODO EDICION: Carga desde servidor
  // ============================================================================

  Widget _buildEdicionMode(BuildContext context) {
    final educacionAsync = ref.watch(educacionProvider(widget.codEmpleado));

    return educacionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data:
          (listaEducacion) =>
              _buildUI(context, listaEducacion, isEdition: true),
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(
    BuildContext context,
    List<EducacionEntity> lista, {
    required bool isEdition,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        Column(
          children: [
            // Lista de educación
            ...List.generate(
              lista.length,
              (idx) =>
                  _editingIndex == idx
                      ? _buildEditForm(context, idx, lista, isEdition)
                      : _buildEducacionCard(
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
          Icon(Icons.school, size: context.smallIconSize, color: Colors.grey),
          SizedBox(width: context.smallSpacing),
          Text(
            'Historial Educativo',
            style: context.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE EDUCACIÓN (LECTURA)
  // ============================================================================

  Widget _buildEducacionCard(
    BuildContext context,
    int index,
    EducacionEntity edu,
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
              backgroundColor: Colors.lightGreen.shade50,
              child: Icon(
                Icons.book,
                size: context.smallIconSize,
                color: Colors.lightGreen.shade700,
              ),
            ),
            SizedBox(width: context.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tipo Educación
                  _buildDetailRow(
                    label: 'Tipo Educación:',
                    child: DisplayValue<TipoEducacionEntity>(
                      code: edu.tipoEducacion,
                      provider: obtenerTipoEducacion,
                      getCode: (tipo) => tipo.codTipos,
                      getDescription: (tipo) => tipo.nombre,
                      fallback: edu.tipoEducacion,
                      style: context.bodyStyle.copyWith(fontSize: 13),
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Descripción
                  _buildDetailRow(
                    label: 'Descripción:',
                    child: Text(
                      edu.descripcion.isNotEmpty
                          ? edu.descripcion
                          : 'Sin registrar',
                      style: context.bodyStyle.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Fecha
                  _buildDetailRow(
                    label: 'Fecha de finalización:',
                    child: Text(
                      FechaUtils.formatDate(edu.fecha),
                      style: context.bodyLightStyle.copyWith(fontSize: 13),
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Botones alineados abajo a la derecha
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
                                    ? _deleteFromServer(edu.codEducacion)
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

  // Helper para filas de detalle (consistente con detalle_formacion)
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

  // Reemplazamos el subtitle original (ya no se usa por el nuevo card)
  // ============================================================================
  // FORMULARIOS
  // ============================================================================

  Widget _buildEditForm(
    BuildContext context,
    int index,
    List<EducacionEntity> lista,
    bool isEdition,
  ) {
    return FormEducacion(
      key: ValueKey('edit_educacion_${lista[index].codEducacion}'),
      educacionInicial: lista[index],
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave:
          (edu) => isEdition ? _saveToServer(edu) : _updateInList(edu, index),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _editingIndex = -1);
      },
    );
  }

  Widget _buildNewForm(BuildContext context, bool isEdition) {
    return FormEducacion(
      key: ValueKey('new_educacion_${DateTime.now().millisecondsSinceEpoch}'),
      educacionInicial: EducacionEntity(
        codEducacion: 0,
        codEmpleado: widget.codEmpleado,
        tipoEducacion: '',
        descripcion: '',
        fecha: DateTime.now(),
        audUsuario: _audUsuario,
      ),
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave: (edu) => isEdition ? _saveToServer(edu) : _addToList(edu),
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
        label: const Text('Agregar educación'),
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
          'No hay educación registrada',
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

  void _addToList(EducacionEntity edu) {
    final list = List<EducacionEntity>.from(
      ref.read(tempEducacionListProvider),
    );
    list.add(edu);
    ref.read(tempEducacionListProvider.notifier).state = list;
    setState(() => _isAddingNew = false);
    showSuccessMessage(context, 'Educación agregada');
  }

  void _updateInList(EducacionEntity edu, int index) {
    final list = List<EducacionEntity>.from(
      ref.read(tempEducacionListProvider),
    );
    list[index] = edu;
    ref.read(tempEducacionListProvider.notifier).state = list;
    setState(() => _editingIndex = -1);
    showSuccessMessage(context, 'Educación actualizada');
  }

  void _deleteFromList(int index) {
    final list = List<EducacionEntity>.from(
      ref.read(tempEducacionListProvider),
    );
    list.removeAt(index);
    ref.read(tempEducacionListProvider.notifier).state = list;
    _resetFormState();
    showSuccessMessage(context, 'Educación eliminada');
  }

  // ============================================================================
  // ACCIONES - MODO EDICION (SERVIDOR)
  // ============================================================================

  Future<void> _saveToServer(EducacionEntity edu) async {
    await executeABM(
      ref: ref,
      context: context,
      operation: () => ref.read(registrarEducacionProvider(edu).future),
      providersToInvalidate: [educacionProvider(widget.codEmpleado)],
      successMessage: '✅ Educación guardada: ${edu.descripcion}',
    );

    if (mounted) {
      _resetFormState();
    }
  }

  Future<void> _deleteFromServer(int codEducacion) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () => ref.read(eliminarEducacionProvider(codEducacion).future),
      providersToInvalidate: [educacionProvider(widget.codEmpleado)],
      successMessage: 'Educación eliminada correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Educación',
      confirmationMessage:
          '¿Está seguro de eliminar este registro? No se puede deshacer.',
    );

    if (success && mounted) {
      setState(() => _editingIndex = -1);
    }
  }
}
