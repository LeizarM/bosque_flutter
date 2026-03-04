import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/domain/entities/relacion_laboral_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_relacion_laboral_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_relacion_laboral.dart';

// ============================================================================
// MAIN WIDGET
// ============================================================================

class DetalleRelacionLaboral extends ConsumerStatefulWidget {
  final int codEmpleado;
  final String mode;

  const DetalleRelacionLaboral({
    Key? key,
    required this.codEmpleado,
    this.mode = 'nuevo',
  }) : super(key: key);

  @override
  ConsumerState<DetalleRelacionLaboral> createState() =>
      _DetalleRelacionLaboralState();
}

class _DetalleRelacionLaboralState extends ConsumerState<DetalleRelacionLaboral> {
  int _editingIndex = -1;
  bool _isAddingNew = false;
  late int _audUsuario;

  @override
  void didUpdateWidget(covariant DetalleRelacionLaboral oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mode == 'nuevo' && oldWidget.codEmpleado != widget.codEmpleado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tempRelacionLaboralListProvider.notifier).state = [];
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
    final listaRelacionLaboral = ref.watch(tempRelacionLaboralListProvider);

    // Si tempRelacionLaboralListProvider está vacío, cargar del servidor SOLO UNA VEZ
    if (listaRelacionLaboral.isEmpty) {
      final relacionDelServidorAsync =
          ref.watch(relacionLaboralProvider(widget.codEmpleado));

      return relacionDelServidorAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (relacionDelServidor) {
          // IMPORTANTE: Cargar en tempRelacionLaboralListProvider SOLO una vez
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(tempRelacionLaboralListProvider).isEmpty &&
                relacionDelServidor.isNotEmpty) {
              ref.read(tempRelacionLaboralListProvider.notifier).state =
                  relacionDelServidor;
            }
          });
          return _buildUI(context, relacionDelServidor, isEdition: false);
        },
      );
    }

    // Si ya hay datos en temporal, mostrar esos
    return _buildUI(context, listaRelacionLaboral, isEdition: false);
  }

  // ============================================================================
  // MODO EDICION: Carga desde servidor
  // ============================================================================

  Widget _buildEdicionMode(BuildContext context) {
    final relacionAsync =
        ref.watch(relacionLaboralProvider(widget.codEmpleado));

    return relacionAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (listaRelacionLaboral) =>
          _buildUI(context, listaRelacionLaboral, isEdition: true),
    );
  }

  // ============================================================================
  // UI PRINCIPAL
  // ============================================================================

 /* Widget _buildUI(BuildContext context, List<RelacionLaboralEntity> lista,
      {required bool isEdition}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        Column(
          children: [
            // Lista de relación laboral
            ...List.generate(
              lista.length,
              (idx) => _editingIndex == idx
                  ? _buildEditForm(context, idx, lista, isEdition)
                  : _buildRelacionCard(context, idx, lista[idx], isEdition),
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
  }*/
  Widget _buildUI(BuildContext context, List<RelacionLaboralEntity> lista,
    {required bool isEdition}) {
  // ✅ LIMITAR A 1 RELACIÓN EN MODO NUEVO
  final tieneRelacion = lista.isNotEmpty;
  final puedeAgregar = !isEdition && !tieneRelacion; // Solo en modo nuevo SIN relación

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildHeader(context),
      Column(
        children: [
          // Lista de relación laboral
          ...List.generate(
            lista.length,
            (idx) => _editingIndex == idx
                ? _buildEditForm(context, idx, lista, isEdition)
                : _buildRelacionCard(context, idx, lista[idx], isEdition),
          ),
          // Formulario nuevo si está activo
          if (_isAddingNew) _buildNewForm(context, isEdition),
          // Botón agregar - ✅ SOLO si no hay relación y estamos en modo nuevo
          if (!_isAddingNew && puedeAgregar) _buildAddButton(context),
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
          Icon(
            Icons.work,
            size: context.smallIconSize,
            color: Colors.grey,
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            'Relación Laboral',
            style: context.subtitleStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TARJETA DE RELACIÓN LABORAL (LECTURA)
  // ============================================================================

  Widget _buildRelacionCard(BuildContext context, int index,
      RelacionLaboralEntity relacion, bool isEdition) {
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
          backgroundColor: Colors.teal.shade50,
          child: Icon(
            Icons.business,
            size: context.smallIconSize,
            color: Colors.teal.shade700,
          ),
        ),
        title: _buildTitle(context, relacion),
        subtitle: _buildSubtitle(context, relacion),
        trailing: _buildActions(context, index, relacion, isEdition),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, RelacionLaboralEntity relacion) {
    return DisplayValue<TipoRelacionLaboralEntity>(
      code: relacion.tipoRel,
      provider: getTipoRelacionLaboral,
      getCode: (tipo) => tipo.codTipos,
      getDescription: (tipo) => tipo.nombre,
      fallback: relacion.tipoRel,
      style: context.bodyStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, RelacionLaboralEntity relacion) {
    return Padding(
      padding: EdgeInsets.only(top: context.smallSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataRow(
            context,
            'Desde:',
            FechaUtils.formatDate(relacion.fechaIni ?? DateTime.now()),
          ),
         /* _buildDataRow(
            context,
            'Hasta:',
            FechaUtils.formatDate(relacion.fechaFin ?? DateTime.now()),
          ),*/
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.smallSpacing / 2),
      child: Row(
        children: [
          Text(
            label,
            style: context.bodyLightStyle.copyWith(
              fontSize: context.smallFontSize,
            ),
          ),
          SizedBox(width: context.smallSpacing),
          Text(
            value,
            style: context.bodyStyle.copyWith(
              fontSize: context.smallFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, int index,
      RelacionLaboralEntity relacion, bool isEdition) {
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
              ? _deleteFromServer(relacion.codRelEmplEmpr)
              : _deleteFromList(index),
          tooltip: 'Eliminar',
        ),
      ],
    );
  }

  void _startEditing(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingIndex = index;
      _isAddingNew = false;
    });
  }

  // ============================================================================
  // FORMULARIOS
  // ============================================================================

  Widget _buildEditForm(BuildContext context,
      int index, List<RelacionLaboralEntity> lista, bool isEdition) {
    return FormRelacionLaboral(
      relacionInicial: lista[index],
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave: (relacion) =>
          isEdition ? _saveToServer(relacion) : _updateInList(relacion, index),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _editingIndex = -1);
      },
    );
  }

  Widget _buildNewForm(BuildContext context, bool isEdition) {
    return FormRelacionLaboral(
      relacionInicial: RelacionLaboralEntity(
        codRelEmplEmpr: 0,
        codEmpleado: widget.codEmpleado,
        esActivo: 1,
        tipoRel: '',
        nombreFileContrato: '',
        fechaIni: DateTime.now(),
        fechaFin: DateTime.now(),
        motivoFin: '',
        audUsuario: _audUsuario,
        fechaInicioBeneficio: null,
        fechaInicioPlanilla: null,
        datoFechasBeneficio: null,
        cargo: '',
        sucursal: '',
        empresaFiscal: '',
        empresaInterna: '',
      ),
      codEmpleado: widget.codEmpleado,
      audUsuario: _audUsuario,
      onSave: (relacion) =>
          isEdition ? _saveToServer(relacion) : _addToList(relacion),
      onCancel: () {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _isAddingNew = false);
      },
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Agregar relación laboral'),
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
          'No hay relación laboral registrada',
          style: context.bodyLightStyle,
        ),
      ),
    );
  }

  // ============================================================================
  // OPERACIONES: MODO NUEVO (TEMPORAL)
  // ============================================================================

  /*void _addToList(RelacionLaboralEntity relacion) {
    final list = List<RelacionLaboralEntity>.from(
        ref.read(tempRelacionLaboralListProvider));
    list.add(relacion);
    ref.read(tempRelacionLaboralListProvider.notifier).state = list;
    setState(() => _isAddingNew = false);
    showSuccessMessage(context, 'Relación laboral agregada');
  }*/
  void _addToList(RelacionLaboralEntity relacion) {
  // ✅ REEMPLAZAR en lugar de agregar (máximo 1)
  ref.read(tempRelacionLaboralListProvider.notifier).state = [relacion];
  setState(() => _isAddingNew = false);
  showSuccessMessage(context, 'Relación laboral agregada');
}

  void _updateInList(RelacionLaboralEntity relacion, int index) {
    final list = List<RelacionLaboralEntity>.from(
        ref.read(tempRelacionLaboralListProvider));
    list[index] = relacion;
    ref.read(tempRelacionLaboralListProvider.notifier).state = list;
    setState(() => _editingIndex = -1);
    showSuccessMessage(context, 'Relación laboral actualizada');
  }

  void _deleteFromList(int index) {
    final list = List<RelacionLaboralEntity>.from(
        ref.read(tempRelacionLaboralListProvider));
    list.removeAt(index);
    ref.read(tempRelacionLaboralListProvider.notifier).state = list;
    _resetFormState();
    showSuccessMessage(context, 'Relación laboral eliminada');
  }

  // ============================================================================
  // OPERACIONES: MODO EDICION (SERVIDOR)
  // ============================================================================

  Future<void> _saveToServer(RelacionLaboralEntity relacion) async {
    await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(registrarRelacionLaboral(relacion).future),
      providersToInvalidate: [relacionLaboralProvider(widget.codEmpleado)],
      successMessage:
          '✅ Relación laboral guardada: ${relacion.tipoRel}',
    );

    if (mounted) {
      _resetFormState();
    }
  }

  Future<void> _deleteFromServer(int codRelEmplEmpr) async {
    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () =>
          ref.read(eliminarRelacionLaboral(codRelEmplEmpr).future),
      providersToInvalidate: [relacionLaboralProvider(widget.codEmpleado)],
      successMessage: 'Relación laboral eliminada correctamente',
      requireConfirmation: true,
      confirmationTitle: 'Eliminar Relación Laboral',
      confirmationMessage:
          '¿Está seguro de eliminar este registro? No se puede deshacer.',
    );

    if (success && mounted) {
      setState(() => _editingIndex = -1);
    }
  }
}