import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/notifiers/dependientes_notifier.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/descargar_reportes_jasper.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/Ciudad_entity.dart';
import 'package:bosque_flutter/domain/entities/persona_entity.dart';
import 'package:bosque_flutter/domain/entities/ciExpedido_entity.dart';
import 'package:bosque_flutter/domain/entities/dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/estado_civil_entity.dart';
import 'package:bosque_flutter/domain/entities/pais_entity.dart';
import 'package:bosque_flutter/domain/entities/parentesco_entity.dart';
import 'package:bosque_flutter/domain/entities/sexo_entity.dart';
import 'package:bosque_flutter/domain/entities/telefono_entity.dart';
import 'package:bosque_flutter/domain/entities/zona_entity.dart';
import 'package:bosque_flutter/presentation/screens/ficha-trabajador/controllers/dependientes_controller.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_dependientes.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/formulario_telefono.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/garante_referencia_seccion.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/map_viewer.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/speed_dial.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
//checkpoint
class DependienteScreen extends ConsumerStatefulWidget {
  final int codEmpleado;
  const DependienteScreen({Key? key, required this.codEmpleado})
    : super(key: key);

  @override
  ConsumerState<DependienteScreen> createState() => _DependienteScreenState();
}

class _DependienteScreenState extends ConsumerState<DependienteScreen> {
  final MapController _viewMapController = MapController();

  bool _habilitarEdicion = false;
  bool _permisosVerificados = false;
  int? _expandedIndex;

  late int _codEmpleado;
  String _vistaSeleccionada = 'dependientes'; // o 'garantes'
// Para el estado expandido y operación seleccionada de garantes/referencias
Map<String, bool> _estadoExpandidoGarante = {};
Map<String, String?> _selectedOperationGarante = {
  'garanteReferencia': null,
};
  //mostrar operaciones seleccionadas por seccion
  // Agregar a las variables de estado
  Map<String, String?> selectedOperation = {
    'dependiente': null,
    'telefono': null,
  };
  MapController _getMapController(int codPersona) {
  return _mapControllers.putIfAbsent(codPersona, () => MapController());
}

  List<DependienteEntity> _dependientes = [];
  List<ParentescoEntity> _parentescos = [];
  List<CiExpedidoEntity> listCiExpedido = [];
  List<EstadoCivilEntity> listEstCivil = [];
  List<PaisEntity> listPaises = [];
  List<CiudadEntity> listCiudades = [];
  List<ZonaEntity> listZonas = [];
  List<SexoEntity> listGeneros = [];

  Map<int, PersonaEntity?> personasEdit = {};
  List<bool> _editingStates = [];
  String _datoPersona = '';
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, bool> estadoExpandido = {
    'empleado': true,
    'persona': true,
    'telefono': true,
    'correo': true,
    'formacionExp': true,
    'expLaboral': true,
    'garanteReferenciaExp': true,
    'relEmpExp': true,
    'foto': true,
  };

  // controlador de mapa
  final Map<int, MapController> _mapControllers = {};
  @override
  void initState() {
    super.initState();
    _codEmpleado = widget.codEmpleado;
WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ResponsiveUtilsBosque.isDesktop(context)) {
      setState(() {
        _expandedIndex = 0;
      });
    }
 
  });
    _verificarPermisosEdicion();
    _initAllLoad();
    // Invalida los providers relevantes al entrar a la pantalla
  Future.microtask(() {
    ref.invalidate(dependientesProvider(_codEmpleado));
    ref.invalidate(empleadosDependientesProvider);
    ref.invalidate(parentescosProvider);
    // Agrega aquí otros providers que quieras refrescar automáticamente
  });
  }
  @override
void dispose() {
  for (final controller in _mapControllers.values) {
    controller.dispose();
  }
  super.dispose();
}
 

  Future<int> getCodEmpleado() async {
    return await ref.read(userProvider.notifier).getCodEmpleado();
  }
   void toggleSeccion(String seccion) {
    setState(() {
      estadoExpandido[seccion] = !estadoExpandido[seccion]!;
    });
  }

  Future<void> _initAllLoad() async {
    try {
      setState(() => _isLoading = true);

      // Cargar empleado actual
      final empleadosAsync = await ref.read(
        empleadosDependientesProvider(_codEmpleado).future,
      );
      final empleadoActual = empleadosAsync.firstWhere(
        (emp) => emp.codEmpleado == _codEmpleado,
        orElse: () => throw Exception('Empleado no encontrado'),
      );

      // Cargar datos iniciales usando los providers
      final dependientes = await ref.read(
        dependientesProvider(_codEmpleado).future,
      );
      final parentescos = await ref.read(parentescosProvider.future);

      if (!mounted) return;

      setState(() {
        _datoPersona = empleadoActual.persona.datoPersona ?? '';
        _dependientes = dependientes;
        _parentescos = parentescos;
        _editingStates = List.filled(dependientes.length, false);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }



  Future<void> _verificarPermisosEdicion() async {
  try {
    final permissionService = ref.read(permissionServiceProvider);
    final hasPermission = await permissionService.verificarPermisosEdicion(
      widget.codEmpleado,
    );

    if (mounted) {
      setState(() {
        _habilitarEdicion = hasPermission;
        _permisosVerificados = true;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _errorMessage = e.toString();
        _habilitarEdicion = false;
        _permisosVerificados = true;
      });
    }
  }
}
String _getParentesco(WidgetRef ref, DependienteEntity dependiente) {
  final parentesco = ref.watch(parentescosProvider);
  return parentesco.when(
    data: (tipos) {
      final tipo = tipos.firstWhere(
        (t) => t.codTipos == dependiente.parentesco,
        orElse: () => ParentescoEntity(
          codTipos: '',
          nombre: 'NO DEFINIDO',
          codGrupo: 0,
          listTipos: [],
        ),
      );
      return tipo.nombre.toUpperCase(); 
    },
    loading: () => 'cargando...',
    error: (_, __) => 'error',
  );
}

  @override
  Widget build(BuildContext context) {
    
    final dependientesAsync = ref.watch(
      dependientesProvider(widget.codEmpleado),
    );

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (!_permisosVerificados) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
  title: Text(isDesktop ? 'Referencias de: $_datoPersona' : 'Lista de referencias personales'),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      tooltip: 'Refrescar',
      onPressed: () {
        ref.invalidate(dependientesProvider(widget.codEmpleado));
        ref.invalidate(empleadosDependientesProvider);
        ref.invalidate(telefonoProvider);
        ref.invalidate(parentescosProvider);
      },
    ),
    _buildReportesDropdown(context, ref)
    
    
  ],
),
      body: Column(
  children: [
    // --- Filtro de vista ---
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('Ver por:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          DropdownButton<String>(
  value: _vistaSeleccionada,
  items: const [
    DropdownMenuItem(value: 'dependientes', child: Text('Referencias Personales')),
    DropdownMenuItem(value: 'garantes', child: Text('Garantes')),
    DropdownMenuItem(value: 'referencias', child: Text('Referencias Laborales')),
  ],
  onChanged: (value) {
    if (value != null) {
      setState(() {
        _vistaSeleccionada = value;
      });
    }
  },
),
        ],
      ),
    ),
    // --- Contenido principal según filtro ---
    Expanded(
      child: _vistaSeleccionada == 'dependientes'
        ? Consumer(
            builder: (context, ref, _) {
              final dependientesAsync = ref.watch(dependientesProvider(widget.codEmpleado));
              final isDesktop = MediaQuery.of(context).size.width >= 900;

              return dependientesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (dependientes) {
                  if (_editingStates.length != dependientes.length) {
                    _editingStates = List.filled(dependientes.length, false);
                  }

                  if (isDesktop) {
                    return _buildDependientesWebView(
                      context,
                      ref,
                      dependientes,
                      _habilitarEdicion,
                      _expandedIndex,
                      (panelIndex, isExpanded) {
                        setState(() {
                          _expandedIndex = isExpanded ? null : panelIndex;
                        });
                      },
                      _agregarDependiente,
                      (context, dep) => _editarDependiente(context: context, dependiente: dep),
                      (context, ref, dep, codEmpleado) =>
                        DependienteController.eliminarDependiente(
                          context: context,
                          ref: ref,
                          dependiente: dep,
                          codEmpleado: codEmpleado,
                        ),
                      selectedOperation,
                      (op) {
                        setState(() {
                          selectedOperation['telefono'] = op;
                        });
                      },
                      _getMapController,
                      widget.codEmpleado,
                      _mostrarDialogoAgregarTelefono,
                      _mostrarDialogoEditarTelefono,
                    );
                  }

                  // DISEÑO MÓVIL
                  final theme = Theme.of(context);
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Referencias de:',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _datoPersona,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                fontFamily: 'Montserrat',
                                letterSpacing: 0.1,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, right: 8.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: CustomSpeedDial(
                            visible: _habilitarEdicion,
                            nombreSeccion: 'dependiente',
                            onAgregar: () => _agregarDependiente(context),
                            updateOperation: (String? op) {
                              setState(() {
                                selectedOperation['dependiente'] = op;
                              });
                            },
                            selectedOperation: selectedOperation,
                            operacionHabilitada: dependientes.isEmpty
                                ? ['agregar']
                                : ['agregar', 'editar', 'eliminar'],
                          ),
                        ),
                      ),
                      Expanded(
                        child: dependientes.isEmpty
                            ? const Center(child: Text("El empleado no tiene dependientes"))
                            : RefreshIndicator(
                                onRefresh: () async {
                                  ref.invalidate(dependientesProvider(widget.codEmpleado));
                                  await Future.delayed(const Duration(milliseconds: 500));
                                },
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  itemCount: dependientes.length,
                                  itemBuilder: (context, index) {
                                    final dependiente = dependientes[index];
                                    return _buildDependienteCardMobile(
                                      context,
                                      ref,
                                      dependiente,
                                      _habilitarEdicion,
                                      _getMapController(dependiente.codPersona),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                },
              );
            },
          )
        : GaranteReferenciaSeccion(
  codEmpleado: widget.codEmpleado,
  habilitarEdicion: _habilitarEdicion,
  estadoExpandido: _estadoExpandidoGarante,
  selectedOperation: _selectedOperationGarante,
  onToggleSeccion: toggleSeccion,
  onUpdateOperation: (String? op) {
    setState(() {
      _selectedOperationGarante['garanteReferencia'] = op;
    });
  },
  onEditar: () {
    // Aquí puedes mostrar el diálogo de edición, por ejemplo:
    // _mostrarDialogoEditarGaranteReferencia(context, ref, garanteReferencia);
    // O puedes dejarlo vacío si el propio widget maneja el diálogo.
  },
  onAgregar: () {
    // Aquí puedes mostrar el diálogo de agregar, por ejemplo:
    // _mostrarDialogoAgregarGaranteReferencia(context, ref);
    // O puedes dejarlo vacío si el propio widget maneja el diálogo.
  },
  onEliminar: () {
    // Aquí puedes mostrar el diálogo de confirmación/eliminación.
    // O puedes dejarlo vacío si el propio widget maneja el diálogo.
  },
  filtroTipo: _vistaSeleccionada == 'garantes'
            ? 'gar'
            : _vistaSeleccionada == 'referencias'
                ? 'ref'
                : 'todos',
)
    ),
  ],
),
    );
  }

  void _editarDependiente({
    required BuildContext context,
    required DependienteEntity dependiente,
  }) async {
    try {
      // Cargar los datos de la persona asociada al dependiente
      final personaAsync = await ref.read(
        obtenerPersonaProvider(dependiente.codPersona).future,
      );

      if (!mounted) return;

      // Mostrar el formulario de edición en un diálogo
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: DependienteForm(
                  title: 'Editar Dependiente',
                  dependiente: dependiente,
                  persona: personaAsync,
                  codEmpleado: widget.codEmpleado,
                  isEditing: true,
                  onSave: (updatedDependiente, updatedPersona) async {
                    try {
                      // Registrar primero la persona actualizada
                      await ref.read(
                        registrarPersonaProvider(updatedPersona).future,
                      );
                      // await ref.read(dependientesNotifierProvider.notifier).editarDependiente(updatedDependiente);
                      await ref.read(
                        editarDepProvider(updatedDependiente).future,
                      );

                      if (!mounted) return;

                      // Invalidar el cache del provider de dependientes
                      ref.invalidate(dependientesProvider(widget.codEmpleado));
                      ref.invalidate(
                        obtenerPersonaProvider(updatedDependiente.codPersona),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      AppSnackbar.showError(
                        context,
                        'Error al actualizar: ${e.toString()}',
                      );
                    }
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
              ),
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar los datos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // En tu pantalla donde quieras agregar un nuevo dependiente
  void _agregarDependiente(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DependienteForm(
                title: 'Nuevo Dependiente',
                codEmpleado: widget.codEmpleado,
                isEditing: false,
                dependiente: null,
                persona: null,
                onSave: (newDependiente, newPersona) async {
                  try {
                    final personaRegistrada = await ref.read(
                      registrarPersonaProvider(newPersona).future,
                    );
                    final dependienteConPersona = newDependiente.copyWith(
                      codPersona: personaRegistrada.codPersona,
                    );
                    await ref.read(
                      editarDepProvider(dependienteConPersona).future,
                    );
                    ref.invalidate(dependientesProvider(widget.codEmpleado));
                    ref.invalidate(empleadosDependientesProvider);
                    //Navigator.of(context).pop();
                  } catch (e) {
                    AppSnackbar.showError(
                      context,
                      'Error al registrar: ${e.toString()}',
                    );
                  }
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
            
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _mostrarDialogoAgregarTelefono(DependienteEntity dependiente) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            child: FormularioTelefono(
              title: 'Agregar Teléfono',
              codPersona: dependiente.codPersona,
              isEditing: false,
              onSave: (telefono) async {
                try {
                  await ref.read(registrarTelefonoProvider(telefono).future);
                  // Invalidar después de registrar
                  ref.invalidate(telefonoProvider(dependiente.codPersona));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                  rethrow; // Propagar el error para que el formulario lo maneje
                }
              },
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
    );
  }

  void _mostrarDialogoEditarTelefono(TelefonoEntity telefono) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            child: FormularioTelefono(
              title: 'Editar Teléfono',
              telefono: telefono,
              codPersona: telefono.codPersona,
              isEditing: true,
              onSave: (telefonoActualizado) async {
                try {
                  await ref.read(
                    registrarTelefonoProvider(telefonoActualizado).future,
                  );
                  // Invalidar el provider para forzar la actualización
                  ref.invalidate(telefonoProvider(telefono.codPersona));
                  
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              onCancel: () => Navigator.of(context).pop(),
            ),
          ),
    );
  }
 Widget _buildDependienteCardMobile(
  BuildContext context,
  WidgetRef ref,
  DependienteEntity dependiente,
  bool habilitarEdicion,
  MapController mapController,
) {
  return FutureBuilder<PersonaEntity>(
    future: ref.read(obtenerPersonaProvider(dependiente.codPersona).future),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final persona = snapshot.data!;
      final colorScheme = Theme.of(context).colorScheme;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre y acciones
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      dependiente.nombreCompleto.isNotEmpty
                          ? dependiente.nombreCompleto[0].toUpperCase()
                          : "?",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dependiente.nombreCompleto,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.cake, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "Edad: ${dependiente.edad}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.family_restroom, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "Parentesco: ${_getParentesco(ref, dependiente)}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.verified_user, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "Activo: ${dependiente.esActivo}",
                              style: TextStyle(
                                fontSize: 13,
                                color: dependiente.esActivo == 'SI'
                                    ? Colors.teal
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                ],
              ),
              // Acciones dependiente según operación
              Row(
                children: [
                  if (habilitarEdicion &&
                      selectedOperation['dependiente'] == 'editar' &&
                      (dependiente.codEmpleado == null || dependiente.codEmpleado == 0))
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal),
                      tooltip: 'Editar',
                      onPressed: () => _editarDependiente(
                        context: context,
                        dependiente: dependiente,
                      ),
                    ),
                  if (habilitarEdicion && selectedOperation['dependiente'] == 'eliminar')
                    PermissionWidget(
  buttonName: 'btnEliminarReferencia', // Usa el nombre exacto de tu BD
  child: IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    tooltip: 'Eliminar',
    onPressed: () => DependienteController.eliminarDependiente(
      context: context,
      ref: ref,
      dependiente: dependiente,
      codEmpleado: _codEmpleado,
    ),
  ),
),
                ],
              ),
              const Divider(height: 18),
              // --- Sección Teléfonos ---
              Row(
                children: [
                  Icon(Icons.phone_android, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Teléfonos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (habilitarEdicion)
                    CustomSpeedDial(
                      visible: habilitarEdicion,
                      nombreSeccion: 'telefono',
                      operacionHabilitada: ['agregar', 'editar', 'eliminar'],
                      showLabels: false,
                      direction: SpeedDialDirection.left,
                      buttonSize: const Size(32, 32),
                      childrenButtonSize: const Size(28, 28),
                      mainIcon: Icons.more_vert,
                      onAgregar: () => _mostrarDialogoAgregarTelefono(dependiente),
                      updateOperation: (String? op) {
                        (context as Element).markNeedsBuild();
                        // Si usas StatefulWidget, mejor usa setState:
                        // setState(() { selectedOperation['telefono'] = op; });
                        selectedOperation['telefono'] = op;
                      },
                      selectedOperation: selectedOperation,
                    ),
                ],
              ),
              Consumer(
  builder: (context, ref, child) {
    final telefonosAsync = ref.watch(telefonoProvider(dependiente.codPersona));
    final ScrollController telefonoScrollController = ScrollController();
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return telefonosAsync.when(
      data: (telefonos) {
        if (telefonos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No hay teléfonos registrados'),
          );
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 180), // Altura máxima para scroll
          child: Scrollbar(
            controller: telefonoScrollController,
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(8),
            child: ListView.separated(
              controller: telefonoScrollController,
              shrinkWrap: true,
              itemCount: telefonos.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
  final telefono = telefonos[idx];
  return ListTile(
    dense: true,
    leading: Icon(Icons.phone, color: colorScheme.primary),
    title: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final numero = telefono.telefono.replaceAll(RegExp(r'\D'), '');
        final uri = Uri(scheme: 'tel', path: numero);
        
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        
      },
      child: Text(
        telefono.telefono,
        style: const TextStyle(
          color: Colors.teal,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    subtitle: Text(telefono.tipo ?? ''),
    trailing: habilitarEdicion
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copiar',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: telefono.telefono));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teléfono copiado')),
                  );
                },
              ),
              IconButton(
                icon: Image.asset(
                  'assets/icon/whatsapp.png',
                  width: 22,
                  height: 22,
                ),
                tooltip: 'WhatsApp',
                onPressed: () async {
                  final url = Uri.parse('https://wa.me/${telefono.telefono}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              if (selectedOperation['telefono'] == 'editar')
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _mostrarDialogoEditarTelefono(telefono),
                ),
              if (selectedOperation['telefono'] == 'eliminar')
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => ConfirmDialog.showConfirmDelete(
                    context: context,
                    title: 'Eliminar Teléfono',
                    content: '¿Está seguro que desea eliminar este teléfono?',
                    onConfirm: () async {
                      await ref.read(
                        eliminarTelefonoProvider(telefono.codTelefono),
                      );
                      ref.invalidate(
                        telefonoProvider(dependiente.codPersona),
                      );
                    },
                  ),
                ),
            ],
          )
        : null,
  );
},
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Text('Error: $error'),
    );
  },
),
              const SizedBox(height: 12),
              // --- Sección Mapa ---
              Row(
                children: [
                  Icon(Icons.location_on, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Ubicación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MapViewer(
                    mapController: mapController,
                    latitude: persona.lat ?? -16.5,
                    longitude: persona.lng ?? -68.1,
                    isInteractive: true,
                    canChangeLocation: false,
                  ),
                ),
              ),
              if (persona.lat != null && persona.lng != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text('Ver en Google Maps'),
                    onPressed: () async {
                      final Uri uri = Uri.parse(
                        '${AppConstants.googleMapsSearchBaseUrl}=${persona.lat},${persona.lng}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
Widget _buildDependientesWebView(
  BuildContext context,
  WidgetRef ref,
  List<DependienteEntity> dependientes,
  bool habilitarEdicion,
  int? expandedIndex,
  void Function(int?, bool) onExpansionChanged,
  void Function(BuildContext) onAgregarDependiente,
  void Function(BuildContext context, DependienteEntity dependiente) onEditarDependiente,
  void Function(BuildContext context, WidgetRef ref, DependienteEntity dependiente, int codEmpleado) onEliminarDependiente,
  Map<String, String?> selectedOperation,
  void Function(String? op) onTelefonoOperation,
  MapController Function(int) getMapController,
  int codEmpleado,
  void Function(DependienteEntity dependiente) mostrarDialogoAgregarTelefono,
  void Function(TelefonoEntity telefono) mostrarDialogoEditarTelefono,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDesktop = MediaQuery.of(context).size.width >= 900;

  return Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lista de referencias personales',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (habilitarEdicion)
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  onPressed: () => onAgregarDependiente(context),
                ),
            ],
          ),
          const SizedBox(height: 24),
          dependientes.isEmpty
              ? const Center(child: Text('No hay referencias registradas.'))
              : Expanded(
                  child: SingleChildScrollView(
                    child: ExpansionPanelList.radio(
                      expandedHeaderPadding: EdgeInsets.zero,
                      elevation: 2,
                      animationDuration: const Duration(milliseconds: 250),
                      initialOpenPanelValue: expandedIndex,
                      expansionCallback: onExpansionChanged,
                      children: dependientes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final dep = entry.value;
                        return ExpansionPanelRadio(
                          value: index,
                          canTapOnHeader: true,
                          headerBuilder: (context, isExpanded) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  dep.nombreCompleto.isNotEmpty
                                      ? dep.nombreCompleto[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(dep.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Row(
                                children: [
                                  Text('Parentesco: ${ref.read(parentescosProvider).maybeWhen(
                                    data: (tipos) {
                                      final tipo = tipos.firstWhere(
                                        (t) => t.codTipos == dep.parentesco,
                                        orElse: () => ParentescoEntity(
                                          codTipos: '',
                                          nombre: 'NO DEFINIDO',
                                          codGrupo: 0,
                                          listTipos: [],
                                        ),
                                      );
                                      return tipo.nombre.toUpperCase();
                                    },
                                    orElse: () => 'cargando...',
                                  )}'),
                                  const SizedBox(width: 16),
                                  Text('Edad: ${dep.edad}'),
                                  const SizedBox(width: 16),
                                  Text('Activo: ${dep.esActivo}',
                                    style: TextStyle(
                                      color: dep.esActivo == 'SI' ? Colors.teal : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (habilitarEdicion && (dep.codEmpleado == null || dep.codEmpleado == 0))
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.teal),
                                      tooltip: 'Editar',
                                      onPressed: () => onEditarDependiente(context, dep),
                                    ),
                                  //if (habilitarEdicion)
                                    PermissionWidget(
  buttonName: 'btnEliminarReferencia', // Usa el nombre exacto que tienes en tu BD
  child: IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    tooltip: 'Eliminar',
    onPressed: () => onEliminarDependiente(context, ref, dep, codEmpleado),
  ),
),
                                ],
                              ),
                              onTap: () {
                                onExpansionChanged(index, expandedIndex == index);
                              },
                            );
                          },
                          body: FutureBuilder<PersonaEntity>(
                            future: ref.read(obtenerPersonaProvider(dep.codPersona).future),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final persona = snapshot.data!;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Teléfonos
                                    Expanded(
                                      flex: 2,
                                      child: Card(
                                        elevation: 1,
                                        margin: const EdgeInsets.only(right: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.phone_android, color: colorScheme.primary),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Teléfonos',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: colorScheme.primary,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  if (habilitarEdicion)
                                                    CustomSpeedDial(
                                                      visible: habilitarEdicion,
                                                      nombreSeccion: 'telefono',
                                                      operacionHabilitada: ['agregar', 'editar', 'eliminar'],
                                                      showLabels: false,
                                                      direction: SpeedDialDirection.left,
                                                      buttonSize: const Size(32, 32),
                                                      childrenButtonSize: const Size(28, 28),
                                                      mainIcon: Icons.more_vert,
                                                      onAgregar: () => mostrarDialogoAgregarTelefono(dep),
                                                      updateOperation: (String? op) => onTelefonoOperation(op),
                                                      selectedOperation: selectedOperation,
                                                    ),
                                                ],
                                              ),
                                              const Divider(),
                                              Container(
                                                constraints: const BoxConstraints(maxHeight: 200),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Consumer(
                                                  builder: (context, ref, child) {
                                                    final ScrollController telefonoScrollController = ScrollController();
                                                    final telefonosAsync = ref.watch(telefonoProvider(dep.codPersona));
                                                    return telefonosAsync.when(
                                                      data: (telefonos) {
                                                        if (telefonos.isEmpty) {
                                                          return Center(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(16),
                                                              child: Text(
                                                                'No hay teléfonos registrados',
                                                                style: TextStyle(color: colorScheme.onSurface),
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                        return Scrollbar(
                                                          controller: telefonoScrollController,
                                                          thumbVisibility: true,
                                                          thickness: 6,
                                                          radius: const Radius.circular(8),
                                                          child: ListView.separated(
                                                            controller: telefonoScrollController,
                                                            padding: const EdgeInsets.all(8),
                                                            itemCount: telefonos.length,
                                                            separatorBuilder: (_, __) => Divider(
                                                              color: colorScheme.outlineVariant,
                                                              height: 1,
                                                            ),
                                                            itemBuilder: (context, idx) {
                                                              final telefono = telefonos[idx];
                                                              return ListTile(
                                                                dense: true,
                                                                visualDensity: VisualDensity.compact,
                                                                leading: Icon(Icons.phone, color: colorScheme.primary),
                                                                title: Text(
                                                                  telefono.telefono,
                                                                  style: TextStyle(
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.w500,
                                                                    color: colorScheme.onSurface,
                                                                  ),
                                                                ),
                                                                subtitle: Text(
                                                                  telefono.tipo ?? '',
                                                                  style: TextStyle(
                                                                    fontSize: 13,
                                                                    color: colorScheme.onSurfaceVariant,
                                                                  ),
                                                                ),
                                                                trailing: habilitarEdicion
                                                                    ? Row(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          IconButton(
                                                                            icon: const Icon(Icons.copy, size: 18),
                                                                            tooltip: 'Copiar',
                                                                            onPressed: () async {
                                                                              await Clipboard.setData(ClipboardData(text: telefono.telefono));
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                const SnackBar(content: Text('Teléfono copiado')),
                                                                              );
                                                                            },
                                                                          ),
                                                                          IconButton(
                                                                            icon: Image.asset(
                                                                              'assets/icon/whatsapp.png',
                                                                              width: 22,
                                                                              height: 22,
                                                                            ),
                                                                            tooltip: 'WhatsApp',
                                                                            onPressed: () async {
                                                                              final url = Uri.parse('https://wa.me/${telefono.telefono}');
                                                                              if (await canLaunchUrl(url)) {
                                                                                await launchUrl(url, mode: LaunchMode.externalApplication);
                                                                              }
                                                                            },
                                                                          ),
                                                                          /*IconButton(
                                                                            icon: const Icon(Icons.phone_forwarded, size: 18, color: Colors.teal),
                                                                            tooltip: 'Llamar',
                                                                            onPressed: () async {
                                                                              final url = Uri.parse('tel:${telefono.telefono}');
                                                                              if (await canLaunchUrl(url)) {
                                                                                await launchUrl(url);
                                                                              }
                                                                            },
                                                                          ),*/
                                                                          if (selectedOperation['telefono'] == 'editar')
                                                                            IconButton(
                                                                              icon: const Icon(Icons.edit, size: 20),
                                                                              color: colorScheme.primary,
                                                                              onPressed: () => mostrarDialogoEditarTelefono(telefono),
                                                                            ),
                                                                          if (selectedOperation['telefono'] == 'eliminar')
                                                                            IconButton(
                                                                              icon: const Icon(Icons.delete, size: 20),
                                                                              color: colorScheme.error,
                                                                              onPressed: () => ConfirmDialog.showConfirmDelete(
                                                                                context: context,
                                                                                title: 'Eliminar Teléfono',
                                                                                content: '¿Está seguro que desea eliminar este teléfono?',
                                                                                onConfirm: () async {
                                                                                  await ref.read(
                                                                                    eliminarTelefonoProvider(telefono.codTelefono),
                                                                                  );
                                                                                  ref.invalidate(
                                                                                    telefonoProvider(dep.codPersona),
                                                                                  );
                                                                                },
                                                                              ),
                                                                            ),
                                                                        ],
                                                                      )
                                                                    : null,
                                                              );
                                                            },
                                                          ),
                                                        );
                                                      },
                                                      loading: () => const Center(child: CircularProgressIndicator()),
                                                      error: (error, _) => Text(
                                                        'Error: $error',
                                                        style: TextStyle(color: colorScheme.error),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Mapa
                                    Expanded(
                                      flex: 3,
                                      child: Card(
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.location_on, color: colorScheme.primary),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Ubicación',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: colorScheme.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  height: 220,
                                                  child: MapViewer(
                                                    mapController: getMapController(persona.codPersona),
                                                    latitude: persona.lat ?? -16.5,
                                                    longitude: persona.lng ?? -68.1,
                                                    isInteractive: true,
                                                    canChangeLocation: false,
                                                  ),
                                                ),
                                              ),
                                              if (persona.lat != null && persona.lng != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 12),
                                                  child: Center(
                                                    child: OutlinedButton.icon(
                                                      icon: Icon(Icons.map, color: colorScheme.primary),
                                                      label: Text(
                                                        'Ver en Google Maps',
                                                        style: TextStyle(color: colorScheme.primary),
                                                      ),
                                                      onPressed: () async {
                                                        final Uri uri = Uri.parse(
                                                          '${AppConstants.googleMapsSearchBaseUrl}=${persona.lat},${persona.lng}',
                                                        );
                                                        if (await canLaunchUrl(uri)) {
                                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ],
      ),
    ),
  );
}
//boton para reportes
Widget _buildReporteDependientesXEdadBtn(BuildContext context, WidgetRef ref) {
    
    // 1. Define la función de descarga que encapsula la lógica de Riverpod
    Future<Uint8List> downloadFunction() async {
      // Invalida el provider para asegurar la nueva descarga
      ref.invalidate(jasperPdfDependientesXEdad); 
      
      // Lee y espera el resultado del provider
      return ref.read(jasperPdfDependientesXEdad.future);
    }
    
    // 2. RETORNA EL WIDGET DE PERMISOS que envuelve el botón
    return PermissionWidget(
      // Este nombre debe coincidir exactamente con el permiso en tu backend/provider
      buttonName: 'btnRptDepXEDAD', // Ejemplo, usa el nombre real
      
      // El 'child' es el IconButton que solo se mostrará si tiene permiso
      child: IconButton(
        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
        tooltip: 'Generar Reporte Dependientes por Edad',
        onPressed: () async {
          await mostrarReportePdf(
            context: context,
            downloadFunction: downloadFunction, 
            filename: 'RptDependientesPorEdad.pdf', 
          );
        },
      ),
      
      // Opcional: Define qué mostrar si NO tiene permiso (por defecto es SizedBox.shrink)
      // placeholder: const Opacity(opacity: 0.5, child: Icon(Icons.picture_as_pdf)), 
    );
  }
  //dropdown para seleccionar el tipo de reporte
    Widget _buildReportesDropdown(BuildContext context, WidgetRef ref) {
    
    // 1. Definir los datos de los reportes (usando _ReporteOption)
    final List<_ReporteOption> reportOptions = [
        _ReporteOption(
            title: 'Dependientes por Edad',
            filename: 'RptDependientesPorEdad.pdf',
            permissionName: 'btnRptDepXEDAD',
            provider: jasperPdfDependientesXEdad, 
        ),
        _ReporteOption(
            title: 'Dependientes hijos en general',
            filename: 'RptDependientesHijos.pdf',
            permissionName: 'btnRptDepXEDAD',
            provider: jasperPdfDependientesHijos, 
        ),
        // ¡Agrega más reportes aquí!
    ];

    // 2. Filtrar las opciones por permiso
    // (Asume que PermissionWidget.build regresa !SizedBox si hay permiso)
    final allowedOptions = reportOptions.where((option) {
        return PermissionWidget(
            buttonName: option.permissionName,
            child: const Text(''), 
        ).build(context, ref) is! SizedBox; 
    }).toList();

    // 3. Manejo de caso: 0 o 1 opción permitida
    if (allowedOptions.length <= 1) {
        if (allowedOptions.isEmpty) {
            return const SizedBox.shrink();
        }
        final option = allowedOptions.first;
        // Retorna un IconButton simple
        return _buildSingleReportButton(context, ref, option); 
    }

    // 4. Si hay más de una opción, mostramos el botón de menú (PopupMenuButton)
    return PermissionWidget(
        buttonName: 'btnRptDepXEDAD', // Permiso para ver el grupo
        
        // El PopupMenuButton encapsula la funcionalidad del menú
        child: PopupMenuButton<_ReporteOption>(
            
            // EL CHILD es el botón completo (TextButton.icon con texto e ícono)
            offset: const Offset(0, 40), 

            // Construcción de los elementos del menú
            itemBuilder: (BuildContext context) {
                return allowedOptions.map((option) {
                    return PopupMenuItem<_ReporteOption>(
                        value: option, 
                        child: Text(option.title),
                    );
                }).toList();
            },
            
            // Acción al seleccionar un reporte del menú
            onSelected: (_ReporteOption selectedOption) {
                _executeReportDownload(context, ref, selectedOption);
            },
            
            // EL CHILD es el botón completo (TextButton.icon con texto e ícono)
            child: TextButton.icon(
                // Estilo (cambia foregroundColor a Colors.blue o al color de tu tema)
                style: TextButton.styleFrom(
                    foregroundColor: Colors.black, // Color del texto e ícono
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                // CRUCIAL: 'onPressed: null' permite que el toque se propague al PopupMenuButton padre
                onPressed: null, 
                
                // Icono y Texto (propiedades de contenido, deben ir después de las propiedades de estilo/comportamiento)
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red), 
                label: const Text(
                    'Reportes', 
                    style: TextStyle(fontWeight: FontWeight.bold)
                ), 
            ),
        ),
    );
}
// --- Métodos Auxiliares para Reutilización ---

// Método que ejecuta la descarga (simplifica el onPressed)
void _executeReportDownload(BuildContext context, WidgetRef ref, _ReporteOption option) async {
  Future<Uint8List> downloadFunction() async {
    ref.invalidate(option.provider); 
    return ref.read(option.provider.future);
  }
  
  await mostrarReportePdf(
    context: context,
    downloadFunction: downloadFunction, 
    filename: option.filename, 
  );
}

// Método para mostrar el botón individual si solo queda uno
Widget _buildSingleReportButton(BuildContext context, WidgetRef ref, _ReporteOption option) {
  return PermissionWidget(
    buttonName: option.permissionName,
    child: IconButton(
      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
      tooltip: 'Generar ${option.title}',
      onPressed: () => _executeReportDownload(context, ref, option),
    ),
  );
} 

}
class _ReporteOption {
  // Eliminamos la propiedad 'type' que dependía del Enum
  final String title;
  final String filename;
  final String permissionName;
  final FutureProvider<Uint8List> provider;

  _ReporteOption({
    required this.title,
    required this.filename,
    required this.permissionName,
    required this.provider,
  });
}