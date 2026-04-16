import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/experiencia_laboral_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_exp_laboral.dart';

// ============================================================================
// MAIN WIDGET
// ============================================================================

class DetalleExperienciaLaboral extends ConsumerStatefulWidget {
  final int codEmpleado;
  final String mode;

  const DetalleExperienciaLaboral({
    Key? key,
    required this.codEmpleado,
    this.mode = 'nuevo',
  }) : super(key: key);

  @override
  ConsumerState<DetalleExperienciaLaboral> createState() =>
      _DetalleExperienciaLaboralState();
}

class _DetalleExperienciaLaboralState
    extends ConsumerState<DetalleExperienciaLaboral> {
  int _editingIndex = -1;
  bool _isAddingNew = false;
  late int _audUsuario;

  @override
  void didUpdateWidget(covariant DetalleExperienciaLaboral oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mode == 'nuevo' && oldWidget.codEmpleado != widget.codEmpleado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tempExperienciaListProvider.notifier).state = [];
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
    final listaExperiencia = ref.watch(tempExperienciaListProvider);

    // Si tempExperienciaListProvider está vacío, cargar del servidor SOLO UNA VEZ
    if (listaExperiencia.isEmpty) {
      final experienciaDelServidorAsync = ref.watch(
        experienciaLaboralProvider(widget.codEmpleado),
      );

      return experienciaDelServidorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (experienciaDelServidor) {
          // IMPORTANTE: Cargar en tempExperienciaListProvider SOLO una vez
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(tempExperienciaListProvider).isEmpty &&
                experienciaDelServidor.isNotEmpty) {
              ref.read(tempExperienciaListProvider.notifier).state =
                  experienciaDelServidor;
            }
          });
          return _buildUI(context, experienciaDelServidor, isEdition: false);
        },
      );
    }

    // Si ya hay datos en temporal, mostrar esos
    return _buildUI(context, listaExperiencia, isEdition: false);
  }

  // ============================================================================
  // MODO EDICION: Carga desde servidor
  // ============================================================================

  Widget _buildEdicionMode(BuildContext context) {
    final experienciaAsync = ref.watch(
      experienciaLaboralProvider(widget.codEmpleado),
    );

    return experienciaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data:
          (listaExperiencia) =>
              _buildUI(context, listaExperiencia, isEdition: true),
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

  Widget _buildUI(
    BuildContext context,
    List<ExperienciaLaboralEntity> lista, {
    required bool isEdition,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        Column(
          children: [
            // Lista de experiencia
            ...List.generate(
              lista.length,
              (idx) =>
                  _editingIndex == idx
                      ? _buildEditForm(context, idx, lista, isEdition)
                      : _buildExperienciaCard(
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
          Icon(Icons.work, size: context.smallIconSize, color: Colors.grey),
          SizedBox(width: context.smallSpacing),
          Text(
            'Experiencia Laboral',
            style: context.subtitleStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE EXPERIENCIA (LECTURA)
  // ============================================================================

  Widget _buildExperienciaCard(
    BuildContext context,
    int index,
    ExperienciaLaboralEntity experiencia,
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
              backgroundColor: Colors.teal.shade50,
              child: Icon(
                Icons.business_center,
                size: context.smallIconSize,
                color: Colors.teal.shade700,
              ),
            ),
            SizedBox(width: context.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cargo
                  _buildDetailRow(
                    label: 'Cargo:',
                    child: Text(
                      experiencia.cargo.isNotEmpty
                          ? experiencia.cargo
                          : 'Sin registrar',
                      style: context.bodyStyle.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Empresa
                  _buildDetailRow(
                    label: 'Empresa:',
                    child: Text(
                      experiencia.nombreEmpresa.isNotEmpty
                          ? experiencia.nombreEmpresa
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
                      experiencia.descripcion.isNotEmpty
                          ? experiencia.descripcion
                          : 'Sin registrar',
                      style: context.bodyStyle.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: context.smallSpacing),
                  // Fechas
                  _buildDetailRow(
                    label: 'Período:',
                    child: Text(
                      '${FechaUtils.formatDate(experiencia.fechaInicio)} - ${FechaUtils.formatDate(experiencia.fechaFin)}',
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
                                    ? _deleteFromServer(
                                      experiencia.codExperienciaLaboral,
                                    )
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

  // Reemplazamos el subtitle original por compatibilidad (ya no se usa en la nueva tarjeta)
  // ============================================================================
  // FORMULARIOS
  // ============================================================================

  Widget _buildEditForm(
    BuildContext context,
    int index,
    List<ExperienciaLaboralEntity> lista,
    bool isEdition,
  ) {
    return FormExperienciaLaboral(
      key: ValueKey('edit_exp_${lista[index].codExperienciaLaboral}'),
      experienciaInicial: lista[index],
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave:
          (exp) => isEdition ? _saveToServer(exp) : _updateInList(exp, index),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _editingIndex = -1);
      },
    );
  }

  Widget _buildNewForm(BuildContext context, bool isEdition) {
    return FormExperienciaLaboral(
      key: ValueKey('new_exp_${DateTime.now().millisecondsSinceEpoch}'),
      experienciaInicial: ExperienciaLaboralEntity(
        codExperienciaLaboral: 0,
        codEmpleado: widget.codEmpleado,
        nombreEmpresa: '',
        cargo: '',
        descripcion: '',
        fechaInicio: DateTime.now(),
        fechaFin: DateTime.now(),
        nroReferencia: '',
        audUsuario: _audUsuario,
      ),
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave: (exp) => isEdition ? _saveToServer(exp) : _addToList(exp),
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
        label: const Text('Agregar experiencia'),
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
          'No hay experiencia laboral registrada',
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

  void _addToList(ExperienciaLaboralEntity exp) {
    final list = List<ExperienciaLaboralEntity>.from(
      ref.read(tempExperienciaListProvider),
    );
    list.add(exp);
    ref.read(tempExperienciaListProvider.notifier).state = list;
    setState(() => _isAddingNew = false);
    showSuccessMessage(context, 'Experiencia agregada');
  }

  void _updateInList(ExperienciaLaboralEntity exp, int index) {
    final list = List<ExperienciaLaboralEntity>.from(
      ref.read(tempExperienciaListProvider),
    );
    list[index] = exp;
    ref.read(tempExperienciaListProvider.notifier).state = list;
    setState(() => _editingIndex = -1);
    showSuccessMessage(context, 'Experiencia actualizada');
  }

  void _deleteFromList(int index) {
    final list = List<ExperienciaLaboralEntity>.from(
      ref.read(tempExperienciaListProvider),
    );
    list.removeAt(index);
    ref.read(tempExperienciaListProvider.notifier).state = list;
    _resetFormState();
    showSuccessMessage(context, 'Experiencia eliminada');
  }

  // ============================================================================
  // ACCIONES - MODO EDICION (SERVIDOR)
  // ============================================================================

  Future<void> _saveToServer(ExperienciaLaboralEntity exp) async {
    await executeABM(
      ref: ref,
      context: context,
      operation:
          () => ref.read(registrarExperienciaLaboralProvider(exp).future),
      providersToInvalidate: [experienciaLaboralProvider(widget.codEmpleado)],
      successMessage: '✅ Experiencia guardada: ${exp.cargo}',
    );

    if (mounted) {
      _resetFormState();
    }
  }

  Future<void> _deleteFromServer(int codExperienciaLaboral) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation:
          () => ref.read(
            eliminarExperienciaLaboralProvider(codExperienciaLaboral).future,
          ),
      providersToInvalidate: [experienciaLaboralProvider(widget.codEmpleado)],
      successMessage: 'Experiencia eliminada correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Experiencia',
      confirmationMessage:
          '¿Está seguro de eliminar este registro? No se puede deshacer.',
    );

    if (success && mounted) {
      setState(() => _editingIndex = -1);
    }
  }
}
