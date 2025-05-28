import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/presentation/widgets/prestamo_vehiculos/estado_vehiculos_screen.dart';
import 'package:bosque_flutter/presentation/widgets/prestamo_vehiculos/solicitud_vehiculos_screen.dart';
import 'package:bosque_flutter/core/state/prestamo_vehiculos_provider.dart' as prestamo;
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';

class PrestamoDashboardScreen extends ConsumerStatefulWidget {
  const PrestamoDashboardScreen({super.key});

  @override
  ConsumerState<PrestamoDashboardScreen> createState() => _PrestamoDashboardScreenState();
}

class _PrestamoDashboardScreenState extends ConsumerState<PrestamoDashboardScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const EstadoVehiculosScreen(),
    const SolicitudVehiculosScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _mostrarFormularioSolicitud() {
    showDialog(
      context: context,
      builder: (BuildContext context) => const NuevaSolicitudDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Vehículos'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh action
              ref.refresh(prestamo.tipoSolicitudesProvider);
              ref.refresh(prestamo.cochesDisponiblesProvider);
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Estado de Vehículos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Mis Solicitudes',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioSolicitud,
        backgroundColor: colors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Nueva Solicitud Dialog Widget
class NuevaSolicitudDialog extends ConsumerStatefulWidget {
  const NuevaSolicitudDialog({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<NuevaSolicitudDialog> createState() => _NuevaSolicitudDialogState();
}

class _NuevaSolicitudDialogState extends ConsumerState<NuevaSolicitudDialog> {
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  DateTime _fechaSolicitud = DateTime.now();
  bool _requiereChofer = false;
  int? _tipoSolicitudSeleccionado;
  int? _cocheSeleccionado;
  String? _cocheDescripcion;
  int _caracteresMotivo = 0;
  
  // User data
  String _cargo = '';
  int _codEmpleado = 0;
  int _codUsuario = 0;
  int _codSucursal = 0;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _motivoController.addListener(() {
      setState(() {
        _caracteresMotivo = _motivoController.text.length;
      });
    });
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userNotifier = ref.read(userProvider.notifier);
    
    try {
      // Get values from user provider
      final cargo = await userNotifier.getCargo();
      final codEmpleado = await userNotifier.getCodEmpleado();
      final codUsuario = await userNotifier.getCodUsuario();
      final codSucursal = await userNotifier.getCodSucursal();
      
      if (mounted) {
        setState(() {
          // Use the cargo value from provider, not hardcoded
          _cargo = cargo.isEmpty ? 'Sin cargo asignado' : cargo;
          _codEmpleado = codEmpleado;
          _codUsuario = codUsuario;
          _codSucursal = codSucursal;
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
          _cargo = "ERROR AL CARGAR CARGO";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos del usuario: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tipoSolicitudes = ref.watch(prestamo.tipoSolicitudesProvider);
    final coches = ref.watch(prestamo.cochesDisponiblesProvider);
    final registroState = ref.watch(prestamo.registroSolicitudProvider);
    
    // Get theme colors
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nueva Solicitud', 
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold
                  )
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.onSurface),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (_isLoadingUserData)
              const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Fecha de Solicitud', 
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurfaceVariant
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_fechaSolicitud.day}/${_fechaSolicitud.month}/${_fechaSolicitud.year}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        
                        tipoSolicitudes.when(
                          data: (tipos) => DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Tipo de Solicitud',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: colors.surface,
                            ),
                            value: _tipoSolicitudSeleccionado,
                            items: tipos.map((tipo) {
                              return DropdownMenuItem(
                                value: tipo.idES,
                                child: Text(tipo.descripcion),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _tipoSolicitudSeleccionado = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Seleccione un tipo de solicitud';
                              }
                              return null;
                            },
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Text('Error: $error'),
                        ),
                        
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _motivoController,
                          decoration: InputDecoration(
                            labelText: 'Motivo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: colors.surface,
                            alignLabelWithHint: true,
                            counterText: '$_caracteresMotivo/500',
                          ),
                          maxLines: 3,
                          maxLength: 500,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el motivo';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        coches.when(
                          data: (cochesData) => DropdownButtonFormField<int>(
                            isExpanded: true, // Make dropdown use full width
                            menuMaxHeight: 300, // Limit menu height to prevent overflow
                            decoration: InputDecoration(
                              labelText: 'Coche para solicitar',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: colors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            value: _cocheSeleccionado,
                            items: cochesData.map((coche) {
                              return DropdownMenuItem<int>(
                                value: coche.idCocheSol,
                                child: Text(
                                  coche.coche,
                                  overflow: TextOverflow.ellipsis, // Handle text overflow
                                  maxLines: 1, // Ensure single line
                                  style: theme.textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _cocheSeleccionado = value;
                                _cocheDescripcion = cochesData.firstWhere(
                                  (coche) => coche.idCocheSol == value
                                ).coche;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Seleccione un coche';
                              }
                              return null;
                            },
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, _) => Text('Error: $error'),
                        ),
                        
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('¿Requiere chofer?', 
                              style: theme.textTheme.bodyLarge
                            ),
                            Switch(
                              value: _requiereChofer,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                setState(() {
                                  _requiereChofer = value;
                                });
                              },
                            ),
                          ],
                        ),
                        
                        // Cargo field - updated with more visible styling
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: colors.surface,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cargo', 
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                )
                              ),
                              const SizedBox(height: 8),
                              Text(
                                // Add default text if cargo is empty
                                _cargo.isEmpty ? 'Cargando...' : _cargo,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,  // Using green as shown in the image
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: (registroState.isLoading || _isLoadingUserData)
                                ? null
                                : () async {
                                    if (_formKey.currentState?.validate() ?? false) {
                                      if (_tipoSolicitudSeleccionado != null && _cocheSeleccionado != null) {
                                        // Create a properly formatted solicitud object
                                        final solicitud = SolicitudChoferEntity(
                                          idSolicitud: 0, 
                                          fechaSolicitud: _fechaSolicitud,
                                          motivo: _motivoController.text,
                                          codEmpSoli: _codEmpleado,
                                          cargo: _cargo,
                                          estado: 1,
                                          idCocheSol: _cocheSeleccionado!,
                                          idES: _tipoSolicitudSeleccionado!,
                                          requiereChofer: _requiereChofer ? 1 : 0,
                                          audUsuario: _codUsuario,
                                          fechaSolicitudCad: '${_fechaSolicitud.day}/${_fechaSolicitud.month}/${_fechaSolicitud.year}',
                                          estadoCad: 'PENDIENTE',
                                          codSucursal: _codSucursal,
                                          coche: _cocheDescripcion ?? '',
                                        );
                                        
                                        final result = await ref.read(prestamo.registroSolicitudProvider.notifier)
                                          .registrarSolicitud(solicitud);
                                          
                                        if (result && mounted) {
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Solicitud guardada con éxito')),
                                          );
                                          // Refresh the lists after successful submission
                                          ref.refresh(prestamo.cochesDisponiblesProvider);
                                        }
                                      }
                                    }
                                  },
                            child: registroState.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Guardar Solicitud',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
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
      ),
    );
  }
}