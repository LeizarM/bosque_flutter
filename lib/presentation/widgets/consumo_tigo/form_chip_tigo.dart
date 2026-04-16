import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/domain/entities/tipo_renovacion_chip_tigo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:bosque_flutter/domain/entities/cambio_tigo_entity.dart';
import 'package:bosque_flutter/domain/entities/chip_tigo_entity.dart';
import 'package:bosque_flutter/core/state/consumo_tigo_provider.dart';

class FormChipTigo extends ConsumerStatefulWidget {
  final ChipTigoEntity? entity;
  const FormChipTigo({super.key, this.entity});

  @override
  ConsumerState<FormChipTigo> createState() => _FormChipTigoState();
}

class _FormChipTigoState extends ConsumerState<FormChipTigo> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _telController;
  late TextEditingController _nombreController;
  late TextEditingController _fechaController;
  late TextEditingController _codigoController;

  // CORRECCIÓN: Variable de estado para el objeto seleccionado
  CambiosTigoEntity? _selectedEmployee;
  int? _seleccionadoCodEmpleado;
  String? _seleccionadoMotivo;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.entity != null;

    _telController = TextEditingController(text: widget.entity?.telefono ?? '');
    _nombreController = TextEditingController(
      text: widget.entity?.nombreCompleto ?? '',
    );

    final fechaInicial = widget.entity?.fechaSolicitud ?? DateTime.now();
    _fechaController = TextEditingController(
      text: FechaUtils.formatDate(fechaInicial),
    );
    _codigoController = TextEditingController(
      text: widget.entity?.codigo ?? '',
    );

    _seleccionadoCodEmpleado = widget.entity?.codEmpleado;
    _seleccionadoMotivo = widget.entity?.descripcion;

    // Si es edición, inicializamos el objeto para que el DropdownSearch lo reconozca
    if (isEdit) {
      _selectedEmployee = CambiosTigoEntity(
        codEmpleado: widget.entity!.codEmpleado,
        nombreCompleto: widget.entity!.nombreCompleto,
        telefono: widget.entity!.telefono,
      );
    }
  }

  @override
  void dispose() {
    _telController.dispose();
    _nombreController.dispose();
    _fechaController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.entity != null;
    final guardando = ref.watch(chipTigoProvider).guardando;
    final bool isWeb = MediaQuery.of(context).size.width > 600;
    //listener global para mostrar SnackBar de éxito o error basado en el estado del provider
    //ref.listenMessages(chipTigoProvider, context);
    return AlertDialog(
      title: Text(isEdit ? 'Editar Registro' : 'Nuevo Registro de Chip'),
      content: SizedBox(
        width: isWeb ? 650 : MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CORRECCIÓN: Ahora usa _selectedEmployee para permitir cambios en edición
                DropdownSearch<CambiosTigoEntity>(
                  selectedItem: _selectedEmployee,
                  asyncItems:
                      (String filter) => ref
                          .read(consumoTigoRepositoryProvider)
                          .listarNumerosAsignados(
                            CambiosTigoEntity(
                              search:
                                  filter.trim().isEmpty ? null : filter.trim(),
                              pagina: 1,
                              tamanoPagina: 30,
                            ),
                          ),
                  itemAsString: (s) => "${s.nombreCompleto} - ${s.telefono}",
                  onChanged: (s) {
                    if (s != null) {
                      setState(() {
                        _selectedEmployee =
                            s; // Actualiza el objeto seleccionado
                        _seleccionadoCodEmpleado = s.codEmpleado;
                        _telController.text = s.telefono;
                        _nombreController.text = s.nombreCompleto;
                      });
                    }
                  },
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    isFilterOnline: true,
                  ),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Buscar Empleado o Línea",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                if (isWeb) ...[
                  Row(
                    children: [
                      Expanded(child: _buildDatePicker()),
                      const SizedBox(width: 15),
                      Expanded(child: _buildMotivoDropdown()),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _nombreController,
                          'Nombre Completo',
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildTextField(_telController, 'Teléfono'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildCodigoField(),
                ] else ...[
                  _buildDatePicker(),
                  const SizedBox(height: 15),
                  _buildMotivoDropdown(),
                  const SizedBox(height: 15),
                  _buildTextField(_nombreController, 'Nombre Completo'),
                  const SizedBox(height: 15),
                  _buildTextField(_telController, 'Teléfono'),
                  const SizedBox(height: 15),
                  _buildCodigoField(),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: guardando ? null : _procesarGuardado,
          icon:
              guardando
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save),
          label: Text(isEdit ? 'Actualizar' : 'Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() => CustomDatePicker(
    controller: _fechaController,
    label: "Fecha de Solicitud",
    validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
  );

  Widget _buildMotivoDropdown() => CustomDropdown<TipoRenovacionChipTigoEntity>(
    asyncValue: ref.watch(obtenerTipoRenovacionChip),
    label: "Descripción",
    currentValue: _seleccionadoMotivo,
    onChanged: (val) => setState(() => _seleccionadoMotivo = val),
    getName: (e) => e.nombre,
    getCode: (e) => e.codTipos,
  );

  Widget _buildTextField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: const OutlineInputBorder(),
        ),
      );
  Widget _buildCodigoField() => TextFormField(
    controller: _codigoController,
    decoration: InputDecoration(
      labelText: 'Código',
      hintText: 'Solo números y letras',
      filled: true,
      fillColor: Colors.grey[100],
      border: const OutlineInputBorder(),
      isDense: true,
    ),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
    ],
    validator: (value) {
      if (value != null && value.isNotEmpty) {
        if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
          return 'Solo se permiten números y letras';
        }
      }
      return null;
    },
  );

  void _procesarGuardado() async {
    if (!_formKey.currentState!.validate() ||
        _seleccionadoCodEmpleado == null ||
        _seleccionadoMotivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complete todos los campos y seleccione un empleado"),
        ),
      );
      return;
    }

    final fechaSeleccionada =
        FechaUtils.parseDate(_fechaController.text) ?? DateTime.now();

    final chip = ChipTigoEntity(
      codLinea: widget.entity?.codLinea ?? 0,
      codEmpleado: _seleccionadoCodEmpleado!,
      telefono: _telController.text,
      nombreCompleto: _nombreController.text,
      descripcion: _seleccionadoMotivo!, // Se envía el código (ej: 'PERD')
      codigo: _codigoController.text.trim(),
      fechaSolicitud: fechaSeleccionada,
      audUsuarioI: widget.entity?.audUsuarioI ?? 0,
      audFechaI: widget.entity?.audFechaI ?? DateTime.now(),
    );

    final audUsuario = await ref.read(userProvider.notifier).getCodUsuario();
    final exito = await ref
        .read(chipTigoProvider.notifier)
        .registrarChip(chip, audUsuario);
    if (exito && mounted) Navigator.pop(context);
  }
}
