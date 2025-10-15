import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';

import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_persona.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/map_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';

import 'package:bosque_flutter/core/utils/validators.dart';
import 'package:latlong2/latlong.dart';

class DependienteForm extends ConsumerStatefulWidget {
  
  final String title;
  final DependienteEntity? dependiente;
  final PersonaEntity? persona;
  final int codEmpleado; 
  final Future<void> Function(DependienteEntity, PersonaEntity) onSave;
  final VoidCallback onCancel;
  final bool isEditing;

  const DependienteForm({
    Key? key,
    required this.title,
     this.dependiente,
     this.persona,
    required this.codEmpleado,
    required this.onSave,
    required this.onCancel,
    this.isEditing = false,
  }) : super(key: key);

  @override
  ConsumerState<DependienteForm> createState() => _DependienteFormState();
}

class _DependienteFormState extends ConsumerState<DependienteForm> {
  final _formKey = GlobalKey<FormState>();
 // late Map<String, TextEditingController> _controllers;
final _personaKey = GlobalKey<FormularioPersonaState>();
  // Variables para los dropdowns
  String? _parentescoSeleccionado;
  String? _esActivoSeleccionado;
 
  PersonaEntity? _personaTemp;
final MapController _mapController = MapController();
double? _currentLat;
  double? _currentLng;
  @override
  void initState() {
    super.initState();
    
    _initSelections();
    // Inicializar las coordenadas
    _currentLat = widget.persona?.lat ?? -16.5;
    _currentLng = widget.persona?.lng ?? -68.1;
    _personaTemp = widget.persona;
  }

  void _initSelections() {
    _parentescoSeleccionado = widget.dependiente?.parentesco;
    _esActivoSeleccionado = widget.dependiente?.esActivo;
   
    
  }

  
  Future<int> getCodUsuario() async {
    return await ref.read(userProvider.notifier).getCodUsuario();
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Center(
      child: Container(
        width: isLargeScreen ? 600 : null,
        margin: EdgeInsets.symmetric(
          vertical: 24,
          horizontal: isLargeScreen ? 16 : 0,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 16.0 : 8.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Datos del Dependiente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildParentescoField(),
                      _buildActivoField(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FormularioPersona(
                    key: _personaKey,
                    title: 'Datos de la Persona',
                    persona: widget.persona,
                    codPersona: widget.persona?.codPersona ?? 0,
                    isEditing: widget.isEditing,
                    showActions: false,
                    onSave: (persona) {
                      _personaTemp = persona;
                    },
                    onCancel: () {},
                  ),
                  
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParentescoField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 300,
      ),
      child: DropdownButtonFormField<String>(
        value: _parentescoSeleccionado,
        decoration: InputDecoration(
          labelText: 'Parentesco',
          border: const OutlineInputBorder(),
          // El color del label y del fondo se adaptan automáticamente al tema
        ),
        items: ref
            .watch(parentescosProvider)
            .when(
              data: (parentescos) => parentescos
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.codTipos,
                      child: Text(p.nombre),
                    ),
                  )
                  .toList(),
              loading: () => [],
              error: (_, __) => [],
            ),
        onChanged: (value) => setState(() => _parentescoSeleccionado = value),
        validator: (value) => validarDropdown(value, 'Seleccione parentesco'),
      ),
    );
  }

  Widget _buildActivoField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 300,
      ),
      child: DropdownButtonFormField<String>(
        value: _esActivoSeleccionado,
        decoration: InputDecoration(
          labelText: 'Activo',
          border: const OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: "SI", child: Text("SI")),
          DropdownMenuItem(value: "NO", child: Text("NO")),
        ],
        onChanged: (value) => setState(() => _esActivoSeleccionado = value),
        validator: (value) => validarDropdown(value, 'Seleccione estado'),
      ),
    );
  }

  Widget _buildActionButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      TextButton(
        onPressed: widget.onCancel,
        child: const Text('Cancelar'),
      ),
      const SizedBox(width: 16),
      ElevatedButton(
        onPressed: _handleSubmit, // Botón normal con validación
        child: const Text('Guardar'),
      ),
      
    ],
  );
}

void _handleSubmit() async {
  final personaState = _personaKey.currentState;
  final isDependienteValid = _formKey.currentState?.validate() ?? false;
  final isPersonaValid = personaState?.validate() ?? false;

  if (!isDependienteValid || !isPersonaValid) {
    // No hagas nada más, los errores ya se muestran en los campos
    return;
  }

  // Si ambos formularios son válidos, continúa con el guardado
  final persona = await personaState!.getPersona();
// Confirmación antes de guardar
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirmar registro'),
      content: const Text(
        '¿Está seguro de agregar este dependiente?\n\n'
        'Una vez registrado, no podrá eliminarlo desde la aplicación.\n'
        'Si necesita eliminar este dependiente en el futuro, deberá contactar con un administrador.',
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        ElevatedButton(
          child: const Text('Agregar'),
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );

  if (confirmed != true) return;
  try {
    /*final personaGuardada = await ref.read(
      registrarPersonaProvider(persona).future,
    );*/

   // final nombreCompleto =
       // '${personaGuardada.nombres} ${personaGuardada.apPaterno} ${personaGuardada.apMaterno}'.trim();

    final dependiente = widget.isEditing
        ? widget.dependiente!.copyWith(
            codEmpleado: widget.codEmpleado,
            codPersona: persona.codPersona,
            parentesco: _parentescoSeleccionado ?? widget.dependiente!.parentesco,
            esActivo: _esActivoSeleccionado ?? widget.dependiente!.esActivo,
            nombreCompleto: '',
          )
        : DependienteEntity(
            codEmpleado: widget.codEmpleado,
            codDependiente: 0,
            codPersona: persona.codPersona,
            parentesco: _parentescoSeleccionado!,
            esActivo: _esActivoSeleccionado!,
            nombreCompleto: '',
            audUsuario: await getCodUsuario(),
            descripcion: '',
            edad: 0,
          );

    await widget.onSave(dependiente, persona);

    if (mounted) {
      AppSnackbarCustom.showSuccess(
        context,
        widget.isEditing
            ? 'Dependiente actualizado correctamente'
            : 'Dependiente registrado correctamente',
      );
      Navigator.of(context).pop();
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}

  @override
  void dispose() {
    _mapController.dispose();
    
    super.dispose();
  }
  // Agregar después de la sección de género en _buildDatosAdicionalesSection
Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ubicación',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        MapViewer(
        mapController: _mapController,
        latitude: _currentLat!,
        longitude: _currentLng!,
        height: 200,
        isInteractive: true,
        canChangeLocation: true,
        onTap: (LatLng point) {
          setState(() {
            _currentLat = point.latitude;
            _currentLng = point.longitude;
          });
        },
      ),
      ],
    );
  }
}
