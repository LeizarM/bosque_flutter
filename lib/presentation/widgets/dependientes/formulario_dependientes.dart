import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/banner_personalizado.dart';
import 'package:bosque_flutter/domain/entities/empleado_entity.dart';

import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_persona.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';

import 'package:bosque_flutter/core/utils/validators.dart';

class DependienteForm extends ConsumerStatefulWidget {
  final String title;
  final DependienteEntity? dependiente;
  final PersonaEntity? persona;
  final int codEmpleado;
  final Future<void> Function(DependienteEntity, PersonaEntity) onSave;
  final VoidCallback onCancel;
  final bool isEditing;

  const DependienteForm({
    super.key,
    required this.title,
    this.dependiente,
    this.persona,
    required this.codEmpleado,
    required this.onSave,
    required this.onCancel,
    this.isEditing = false,
  });

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

  final MapController _mapController = MapController();

  String? _internalErrorMessage;
  @override
  void initState() {
    super.initState();

    _initSelections();
    // Inicializar las coordenadas
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
                    children: [_buildParentescoField(), _buildActivoField()],
                  ),
                  const SizedBox(height: 8),
                  FormularioPersona(
                    key: _personaKey,
                    title: 'Datos de la Persona',
                    persona: widget.persona,
                    codPersona: widget.persona?.codPersona ?? 0,
                    isEditing: widget.isEditing,
                    showActions: false,
                    onSave: (persona) {},
                    onCancel: () {},
                  ),
                  if (_internalErrorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: BannerCustom(
                        // USAMOS TU WIDGET PERSONALIZADO
                        message: _internalErrorMessage!,
                        color: Colors.red.shade600, // Color para error
                        icon: Icons.error_outline,
                        onClose:
                            () => setState(() => _internalErrorMessage = null),
                        maxLines: 5,
                      ),
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
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
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
              data:
                  (parentescos) =>
                      parentescos
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
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
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
        TextButton(onPressed: widget.onCancel, child: const Text('Cancelar')),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _handleSubmit, // Botón normal con validación
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _handleSubmit() async {
    // -----------------------------------------------------------
    // 0. VALIDACIÓN INICIAL Y PREPARACIÓN
    // -----------------------------------------------------------
    final personaState = _personaKey.currentState;
    final isDependienteValid = _formKey.currentState?.validate() ?? false;
    final isPersonaValid = personaState?.validate() ?? false;

    if (!isDependienteValid || !isPersonaValid) {
      return;
    }

    setState(() {
      _internalErrorMessage = null;
    });

    final personaFormulario = await personaState!.getPersona();

    // --------------------------------------------------------------------------------------
    // 1. VALIDACIÓN: CI VS. EMPLEADO (Mantenido sin cambios)
    // --------------------------------------------------------------------------------------
    EmpleadoEntity empleado;
    try {
      empleado = await ref.read(
        empObtenerDatosEmpleado(widget.codEmpleado).future,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _internalErrorMessage =
              '❌ ERROR: No se pudieron obtener los datos del empleado: ${e.toString()}';
        });
      }
      return;
    }

    final empleadoCI = empleado.persona.ciNumero;
    final dependienteCI = personaFormulario.ciNumero;

    if (empleadoCI == dependienteCI) {
      if (mounted) {
        setState(() {
          _internalErrorMessage =
              '❌ ERROR: No puede registrarse a sí mismo (C.I. $empleadoCI) como su propio dependiente.';
        });
      }
      return;
    }

    // --------------------------------------------------------------------------------------
    // 2. VALIDACIÓN: Duplicidad de dependiente existente (solo modo NO edición)
    // --------------------------------------------------------------------------------------
    if (!widget.isEditing && personaFormulario.codPersona != 0) {
      final codPersonaExistente = personaFormulario.codPersona;
      final dependientesAsync = ref.read(
        dependientesProvider(widget.codEmpleado),
      );

      if (dependientesAsync.hasValue) {
        final isDuplicated = dependientesAsync.value!.any(
          (d) => d.codPersona == codPersonaExistente,
        );

        if (isDuplicated) {
          if (mounted) {
            setState(() {
              _internalErrorMessage =
                  '❌ ERROR: La persona con C.I. ${personaFormulario.ciNumero} ya está registrada como su dependiente. Use el botón "Editar" en la lista para modificar sus datos.';
            });
          }
          return;
        }
      }

      // Si la persona existe pero NO es dependiente, guardamos directamente.
      await _handleFinalSave(personaFormulario);
      return;
    }

    // --------------------------------------------------------------------------------------
    // 3. REGISTRO/EDICIÓN DE PERSONA (Punto Único de Registro y Control 409)
    // --------------------------------------------------------------------------------------
    PersonaEntity? personaFinal;
    bool isError409 = false; // 🚩 DECLARACIÓN DEL FLAG

    try {
      // 🛑 LLAMADA AL BACKEND: Intentará registrar/actualizar.
      // Esto se hace si es EDICIÓN, o si es un CI NUEVO (codPersona=0).
      // Si el CI es duplicado, el BE ahora lanza 409.
      if (widget.isEditing || personaFormulario.codPersona == 0) {
        personaFinal = await ref.read(
          registrarPersonaProvider(personaFormulario).future,
        );

        // Bloqueo de seguridad si el backend devuelve codPersona=0 en lugar de 409.
        if (personaFinal?.codPersona == 0) {
          throw Exception(
            '409: La persona con C.I. ${personaFormulario.ciNumero} ya se encuentra registrada. No se pudo registrar.',
          );
        }
      } else {
        // Caso de autocompletado exitoso.
        personaFinal = personaFormulario;
      }
    } catch (e) {
      // 4. MANEJO DE ERRORES CENTRALIZADO: Captura la excepción del proveedor.
      final errorString = e.toString();

      // 🚨 DETECCIÓN DE 409: Activa la bandera para mostrar el diálogo.
      if (errorString.contains('409:') ||
          errorString.contains('ya se encuentra registrada')) {
        isError409 = true; // ⬅️ ASIGNACIÓN DEL FLAG
      }
      // Manejo de errores que no son 409 (500, red, etc.).
      else {
        if (mounted) {
          setState(() {
            _internalErrorMessage =
                'Error en el proceso de registro: $errorString';
          });
        }
        return; // Detiene la ejecución para errores graves/inesperados.
      }
    }

    // --------------------------------------------------------------------------------------
    // 5. MANEJO POST-TRY (Activa el diálogo si hubo 409)
    // --------------------------------------------------------------------------------------
    if (isError409) {
      if (!mounted) return;

      // 🚨 LÓGICA DE BIFURCACIÓN: Modo Edición vs. Modo Agregar.
      if (widget.isEditing) {
        // Caso Edición: NO se permite autocompletar. Se muestra error directo.
        setState(() {
          _internalErrorMessage =
              '❌ ERROR: El C.I. ingresado ya existe. No se puede actualizar a un C.I. que pertenece a otra persona.';
        });
        return; // Detiene la ejecución.
      }

      // --- Caso Agregar: Muestra el DIÁLOGO DE AUTOCOMPLETAR ---
      String errorMessage =
          '❌ ERROR: El C.I. ingresado ya existe. Por favor, corrija el C.I. o use la opción de Autocompletar.';

      final confirmedAutofill = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: const Text('C.I. Registrado'),
              content: Text(
                'La persona con C.I. ${personaFormulario.ciNumero} ya existe en el sistema. '
                '¿Desea autocompletar el formulario con sus datos? El código de persona existente se usará para el registro del dependiente.',
              ),
              actions: [
                TextButton(
                  child: const Text('No Autocompletar'),
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
                ElevatedButton(
                  child: const Text('Autocompletar'),
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
      );

      if (confirmedAutofill == true) {
        // Llama a la función para recargar los datos del formulario con la persona existente.
        await _handleAutofill(personaFormulario.ciNumero);
        return; // El usuario debe presionar Guardar de nuevo.
      }

      setState(() {
        _internalErrorMessage = errorMessage;
      });
      return; // Detiene la ejecución.
    }

    // --------------------------------------------------------------------------------------
    // 6. GUARDADO FINAL (Solo si el try tuvo éxito y personaFinal no es nulo)
    // --------------------------------------------------------------------------------------
    if (personaFinal != null) {
      await _handleFinalSave(personaFinal);
    }
  }

  // --------------------------------------------------------------------------------------------------
  // --- FUNCIÓN AUXILIAR DE CONFIRMACIÓN Y REGISTRO (Extraída para modularidad, requerida por el flujo) ---
  // La he llamado _handleFinalSave para distinguirla de _handleSubmit.
  // Si deseas evitar este método a toda costa, su contenido debe ser INCLUIDO en los dos puntos
  // donde se llama dentro de _handleSubmit (uno en el IF, otro al final del TRY).
  // Por claridad y evitar código repetido, mantengo _handleFinalSave.
  // --------------------------------------------------------------------------------------------------

  Future<void> _handleFinalSave(PersonaEntity personaGuardada) async {
    // --- DIÁLOGO DE CONFIRMACIÓN DEL DEPENDIENTE ---
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
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

    // 2. CREAR Y ASIGNAR EL CODPERSONA
    final dependiente =
        widget.isEditing
            ? widget.dependiente!.copyWith(
              codEmpleado: widget.codEmpleado,
              codPersona: personaGuardada.codPersona, // ID VÁLIDO
              parentesco:
                  _parentescoSeleccionado ?? widget.dependiente!.parentesco,
              esActivo: _esActivoSeleccionado ?? widget.dependiente!.esActivo,
              nombreCompleto: '',
            )
            : DependienteEntity(
              codEmpleado: widget.codEmpleado,
              codDependiente: 0,
              codPersona: personaGuardada.codPersona, // ID VÁLIDO
              parentesco: _parentescoSeleccionado!,
              esActivo: _esActivoSeleccionado!,
              nombreCompleto: '',
              audUsuario: await getCodUsuario(),
              descripcion: '',
              edad: 0,
            );

    // 3. LLAMADA A widget.onSave
    try {
      await widget.onSave(dependiente, personaGuardada);

      // 4. Éxito
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
      // Manejo de error de registro de Dependiente (si falla la llamada a onSave/editarDepProvider)
      if (mounted) {
        setState(() {
          _internalErrorMessage =
              '❌ Error al registrar el dependiente: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _handleAutofill(String ciNumero) async {
    try {
      // 1. Cargar la Persona por C.I. usando tu provider
      final personaExistente = await ref.read(
        obtenerPersonaXCarnet(ciNumero).future,
      );

      // 2. Aplicar los datos al formularioPersona (llama al método que acabamos de crear)
      if (personaExistente.codPersona != 0) {
        _personaKey.currentState?.loadPersona(personaExistente);
      } else {
        // Si el backend no devuelve la persona, lanzamos un error
        throw Exception('Datos de persona no encontrados.');
      }

      // 3. Resetear el estado de error y mostrar éxito
      if (mounted) {
        setState(() {
          _internalErrorMessage = null;
        });
        AppSnackbarCustom.showSuccess(
          context,
          'Datos de C.I. $ciNumero cargados. Verifique el parentesco y presione Guardar.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _internalErrorMessage =
              '❌ Error al cargar los datos: ${e.toString()}';
        });
      }
      // No relanzamos aquí, solo mostramos el error en el banner.
    }
  }

  @override
  void dispose() {
    _mapController.dispose();

    super.dispose();
  }
  // Agregar después de la sección de género en _buildDatosAdicionalesSection
}
