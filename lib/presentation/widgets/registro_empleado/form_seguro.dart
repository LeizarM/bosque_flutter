// lib/presentation/widgets/registro_empleado/form_seguro.dart

import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/seguro_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_seguro_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/validadores.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormSeguro extends ConsumerStatefulWidget {
  final SeguroEntity? seguroInicial;
  final int audUsuario;
  final Function(SeguroEntity) onSave;
  final VoidCallback onCancel;

  const FormSeguro({
    Key? key,
    this.seguroInicial,
    required this.audUsuario,
    required this.onSave,
    required this.onCancel,
  }) : super(key: key);

  @override
  ConsumerState<FormSeguro> createState() => _FormSeguroState();
}

class _FormSeguroState extends ConsumerState<FormSeguro> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _nombreCtrl;
  late TextEditingController _nombreCortoCtrl;
  late TextEditingController _numeroCtrl;
  late TextEditingController _regionalCtrl;
  String? _selectedTipo;
    int? _selectedCiudadId; // ✅ CAMBIAR: En lugar de _regionalCtrl
  CiudadEntity? _selectedCiudad; // ✅ Para guardar la ciudad seleccionada

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nombreCtrl =
        TextEditingController(text: widget.seguroInicial?.nombre ?? '');
    _nombreCortoCtrl =
        TextEditingController(text: widget.seguroInicial?.nombreCorto ?? '');
    _numeroCtrl =
        TextEditingController(text: widget.seguroInicial?.numero ?? '');
    _regionalCtrl =
        TextEditingController(text: widget.seguroInicial?.regional ?? '');
    _selectedTipo = widget.seguroInicial?.tipo.isNotEmpty == true
        ? widget.seguroInicial!.tipo
        : null;
            _selectedCiudadId = widget.seguroInicial?.codCiudad != 0
        ? widget.seguroInicial?.codCiudad
        : null; // ✅ CAMBIAR
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _nombreCortoCtrl.dispose();
    _numeroCtrl.dispose();
   // _regionalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiposAsync = ref.watch(obtenerTipoSeguro);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing),
            child: Text(
              widget.seguroInicial == null ? 'Nuevo Seguro' : 'Editar Seguro',
              style: context.subtitleStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: context.spacing),

          // GRUPO 1: Nombre (Full Width)
          _buildNombreField(),
          SizedBox(height: context.largeSpacing),

          // GRUPO 2: Nombre Corto y Número (Responsive)
          context.isMobile
              ? _buildMobileLayout1(tiposAsync)
              : _buildWebLayout1(tiposAsync),

          SizedBox(height: context.largeSpacing),

          // GRUPO 3: Regional (Dropdown) - CAMBIAR
          _buildRegionalDropdown(),

          SizedBox(height: context.largeSpacing),

          // Botones
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // ============================================================================
  // LAYOUTS RESPONSIVE
  // ============================================================================

  Widget _buildMobileLayout1(AsyncValue<List<TipoSeguroEntity>> tiposAsync) {
    return Column(
      children: [
        _buildNombreCortoField(),
        SizedBox(height: context.largeSpacing),
        _buildNumeroField(),
        SizedBox(height: context.largeSpacing),
        _buildTipoDropdown(tiposAsync),
      ],
    );
  }

  Widget _buildWebLayout1(AsyncValue<List<TipoSeguroEntity>> tiposAsync) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildNombreCortoField(),
            ),
            SizedBox(width: context.spacing),
            Expanded(
              child: _buildNumeroField(),
            ),
          ],
        ),
        SizedBox(height: context.largeSpacing),
        _buildTipoDropdown(tiposAsync),
      ],
    );
  }

  // ============================================================================
  // CAMPOS DEL FORMULARIO
  // ============================================================================

  Widget _buildNombreField() {
    return TextFormField(
      controller: _nombreCtrl,
      decoration: InputDecoration(
        labelText: 'Nombre *',
        hintText: 'Ingrese el nombre del seguro',
        border: OutlineInputBorder(
          borderRadius: context.borderRadius,
        ),
        prefixIcon: const Icon(Icons.shield),
      ),
      validator: validarNombreSeguro,
    );
  }

  Widget _buildNombreCortoField() {
    return TextFormField(
      controller: _nombreCortoCtrl,
      decoration: InputDecoration(
        labelText: 'Nombre Corto *',
        hintText: 'Ej: CCCS',
        border: OutlineInputBorder(
          borderRadius: context.borderRadius,
        ),
        prefixIcon: const Icon(Icons.badge),
      ),
      maxLength: 15,
      validator: validarNombreCortoSeguro,
    );
  }

  Widget _buildNumeroField() {
    return TextFormField(
      controller: _numeroCtrl,
      decoration: InputDecoration(
        labelText: 'Número *',
        hintText: 'Ej: 001',
        border: OutlineInputBorder(
          borderRadius: context.borderRadius,
        ),
        prefixIcon: const Icon(Icons.numbers),
      ),
      validator: validarNumeroSeguro,
    );
  }

Widget _buildRegionalDropdown() {
  final ciudadesAsync = ref.watch(ciudadProvider(1));

  return CustomDropdown<CiudadEntity>(
    asyncValue: ciudadesAsync,
    label: 'Regional *',
    currentValue: _selectedCiudadId?.toString(), // ✅ Convertir int a String para el dropdown
    getName: (e) => e.ciudad,
    getCode: (e) => e.codCiudad.toString(), // ✅ Convertir int a String
    onChanged: (val) {
      // ❌ ELIMINAR int.tryParse
      final codCiudad = int.parse(val ?? '0'); // ✅ O directamente int.parse si siempre es válido
      
      ciudadesAsync.whenData((lista) {
        final ciudadSeleccionada = lista.firstWhere(
          (c) => c.codCiudad == codCiudad, // ✅ Comparar int con int
          orElse: () => lista.isNotEmpty ? lista.first : CiudadEntity.vacio(),
        );
        setState(() {
          _selectedCiudadId = codCiudad; // ✅ Guardar int directamente
          _selectedCiudad = ciudadSeleccionada;
        });
      });
    },
    validator: (v) =>
        (v?.isEmpty ?? true) ? 'La regional es obligatoria' : null,
  );
}

  // ============================================================================
  // DROPDOWN TIPO SEGURO
  // ============================================================================

  Widget _buildTipoDropdown(AsyncValue<List<TipoSeguroEntity>> tiposAsync) {
    return CustomDropdown<TipoSeguroEntity>(
      asyncValue: tiposAsync,
      label: 'Tipo de Seguro *',
      currentValue: _selectedTipo,
      onChanged: (newValue) {
        setState(() => _selectedTipo = newValue);
      },
      getName: (e) => e.nombre,
      getCode: (e) => e.codTipos,
      validator: (v) => (v?.isEmpty ?? true) ? 'El tipo es obligatorio' : null,
    );
  }

  // ============================================================================
  // BOTONES DE ACCIÓN
  // ============================================================================

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancelar'),
        ),
        SizedBox(width: context.spacing),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Guardar'),
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // LÓGICA DE GUARDADO
  // ============================================================================

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      showErrorMessage(context, 'Por favor complete los campos obligatorios');
      return;
    }

    if (_selectedTipo == null || _selectedTipo!.isEmpty) {
      showErrorMessage(context, 'El tipo de seguro es obligatorio');
      return;
    }

    final seguro = SeguroEntity(
      codSeguro: widget.seguroInicial?.codSeguro ?? 0,
      codCiudad: _selectedCiudadId!,
      nombre: _nombreCtrl.text.trim(),
      nombreCorto: _nombreCortoCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      regional:_selectedCiudad?.ciudad ?? '',
      tipo: _selectedTipo!,
      descripcion: widget.seguroInicial?.descripcion ?? '',
      audUsuarioI: widget.audUsuario,
    );

    final success = await executeABM(
      ref: ref,
      context: context,
      operation: () => ref.read(registrarSeguro(seguro).future),
      providersToInvalidate: [
        obtenerSeguros,
      ],
      successMessage: widget.seguroInicial == null
          ? '✅ Seguro creado correctamente'
          : '✅ Seguro actualizado correctamente',
    );

    if (success && mounted) {
      console('📝 Guardando seguro: ${seguro.nombre}');
      widget.onSave(seguro);
    }
  }
}