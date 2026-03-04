import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/registro_empleado_utils.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:bosque_flutter/domain/entities/licencia_conducir_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_licencia_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FormularioLicenciaConducir extends ConsumerStatefulWidget {
  final String title;
  final LicenciaConducirEntity? licenciaInicial;
  final int codPersona;
  final int audUsuario;
  final bool isEditing;
  final Function(LicenciaConducirEntity) onSave;
  final VoidCallback onCancel;

  const FormularioLicenciaConducir({
    super.key,
    required this.title,
    this.licenciaInicial,
    required this.codPersona,
    required this.audUsuario,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
  });

  @override
  ConsumerState<FormularioLicenciaConducir> createState() =>
      _FormularioLicenciaConducirState();
}

class _FormularioLicenciaConducirState
    extends ConsumerState<FormularioLicenciaConducir> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fechaCaducidadController;
  String? _selectedCategoria;
  DateTime? _selectedFechaCaducidad;

  @override
  void initState() {
    super.initState();

    _selectedCategoria = widget.licenciaInicial?.categoria;
    _selectedFechaCaducidad = widget.licenciaInicial?.fechaCaducidad;
    _fechaCaducidadController = TextEditingController(
      text: _selectedFechaCaducidad != null
          ? FechaUtils.formatDate(_selectedFechaCaducidad!)
          : '',
    );
  }

  @override
  void dispose() {
    _fechaCaducidadController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate() &&
        _selectedFechaCaducidad != null &&
        _selectedCategoria != null &&
        _selectedCategoria!.isNotEmpty) {
      FocusManager.instance.primaryFocus?.unfocus();

      final nuevaLicencia = LicenciaConducirEntity(
        codLicencia: widget.licenciaInicial?.codLicencia ?? 0,
        codPersona: widget.codPersona,
        categoria: _selectedCategoria!.trim(),
        fechaCaducidad: _selectedFechaCaducidad!,
        audUsuario: widget.audUsuario,
      );

      widget.onSave(nuevaLicencia);
    }
  }

  void _handleCancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onCancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tiposLicenciaAsync =
        ref.watch(obtenerTipoLicenciaConducirProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _handleCancel,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Categoría
              tiposLicenciaAsync.when(
                data: (tipos) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CustomDropdown<TipoLicenciaEntity>(
                    asyncValue: AsyncValue.data(tipos),
                    label: 'Categoría *',
                    currentValue: _selectedCategoria,
                    onChanged: (newValue) {
                      setState(() => _selectedCategoria = newValue);
                    },
                    getName: (e) => e.nombre,
                    getCode: (e) => e.codTipos,
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Seleccione una categoría'
                        : null,
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('Error: $error'),
                ),
              ),

              // Fecha de Caducidad
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: CustomDatePicker(
                  controller: _fechaCaducidadController,
                  label: 'Fecha de Caducidad *',
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  onDateSelected: (date) {
                    setState(() {
                      _selectedFechaCaducidad = date;
                    });
                  },
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Requerido';
                    if (_selectedFechaCaducidad == null) {
                      return 'Seleccione una fecha válida';
                    }
                    return null;
                  },
                ),
              ),

              // Botones
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                      onPressed: _handleCancel,
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      onPressed: _handleSave,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}