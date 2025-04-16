import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/observaciones_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entrega_item.dart';

class EntregasHomeScreen extends ConsumerStatefulWidget {
  const EntregasHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EntregasHomeScreen> createState() => _EntregasHomeScreenState();
}

class _EntregasHomeScreenState extends ConsumerState<EntregasHomeScreen> {
  bool _isLocationEnabled = false;
  int _codEmpleado = 0;
  bool _isInitializing = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _inicializarPantalla();
    });
  }
  
  Future<void> _inicializarPantalla() async {
    // Verificar permisos de ubicación
    final locationEnabled = await _checkLocationPermission();
    
    // Obtener código de empleado
    final codEmpleado = await ref.read(userProvider.notifier).getCodEmpleado();
    
    // Cargar las entregas desde el servidor
    await _cargarEntregas(codEmpleado);
    
    // Actualizar el estado local del widget
    if (mounted) {
      setState(() {
        _isLocationEnabled = locationEnabled;
        _codEmpleado = codEmpleado;
        _isInitializing = false;
      });
    }
  }

  // Verificar permisos de ubicación
  Future<bool> _checkLocationPermission() async {
    return await ref.read(entregasNotifierProvider.notifier).verificarServiciosLocalizacion();
  }

  // Cargar entregas del empleado
  Future<void> _cargarEntregas(int codEmpleado) async {
    await ref.read(entregasNotifierProvider.notifier).cargarEntregas(codEmpleado);
  }

  // Iniciar la ruta de entregas
  Future<void> _iniciarRuta() async {
    if (!_isLocationEnabled) {
      _mostrarMensajeError('Debe activar los servicios de ubicación para iniciar entregas');
      return;
    }

    await ref.read(entregasNotifierProvider.notifier).iniciarRuta();
    
    // Recargar los permisos de ubicación
    final locationEnabled = await _checkLocationPermission();
    if (mounted) {
      setState(() {
        _isLocationEnabled = locationEnabled;
      });
    }
  }

  // Finalizar la ruta de entregas
  Future<void> _finalizarRuta() async {
    if (!_isLocationEnabled) {
      _mostrarMensajeError('Debe activar los servicios de ubicación para finalizar entregas');
      return;
    }

    await ref.read(entregasNotifierProvider.notifier).finalizarRuta();
    
    // Recargar los permisos de ubicación
    final locationEnabled = await _checkLocationPermission();
    if (mounted) {
      setState(() {
        _isLocationEnabled = locationEnabled;
      });
    }
  }

  // Mostrar mensaje de error
  void _mostrarMensajeError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // Mostrar diálogo para capturar observaciones y confirmar entrega
  Future<void> _mostrarDialogoDireccion(EntregaEntity entrega) async {
    if (!_isLocationEnabled) {
      _mostrarMensajeError('Debe activar los servicios de ubicación para marcar entregas');
      return;
    }
    
    // Verificar si la ruta está iniciada
    final state = ref.read(entregasNotifierProvider);
    if (!state.rutaIniciada) {
      _mostrarMensajeError('Debe iniciar la ruta antes de marcar entregas');
      return;
    }

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false, // Usuario debe tomar una acción
      builder: (context) => ObservacionesDialog(
        direccion: entrega.direccionEntrega ?? entrega.addressEntregaMat,
      ),
    );

    if (resultado != null && resultado['observaciones'] != null) {
      try {
        await ref.read(entregasNotifierProvider.notifier).marcarEntregaCompletada(
          entrega.idEntrega,
          "", // Campo vacío ya que la dirección se obtendrá automáticamente
          observaciones: resultado['observaciones'],
        );
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Entrega marcada correctamente'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        // Mostrar mensaje de error
        if (mounted) {
          _mostrarMensajeError('Error al marcar la entrega: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entregasNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    
    // Mostrar pantalla de carga mientras se inicializa
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Agrupar entregas por número de documento
    final Map<int, List<EntregaEntity>> entregasAgrupadas = {};
    for (final entrega in state.entregas) {
      if (entregasAgrupadas.containsKey(entrega.docNum)) {
        entregasAgrupadas[entrega.docNum]!.add(entrega);
      } else {
        entregasAgrupadas[entrega.docNum] = [entrega];
      }
    }
    
    // Convertir a lista para la vista
    final listaEntregasAgrupadas = entregasAgrupadas.entries.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas'),
        actions: [
          // Botón de recarga solo si no hay una ruta en progreso
          if (!state.rutaIniciada)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _cargarEntregas(_codEmpleado),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de estado de la ruta
          Container(
            color: state.rutaIniciada 
                ? colorScheme.primaryContainer
                : colorScheme.surfaceTint.withAlpha(20),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.rutaIniciada
                            ? 'Ruta iniciada'
                            : 'Ruta no iniciada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: state.rutaIniciada 
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (state.fechaInicio != null)
                        Text(
                          'Iniciada: ${state.fechaInicio!.day.toString().padLeft(2, '0')}/${state.fechaInicio!.month.toString().padLeft(2, '0')}/${state.fechaInicio!.year} ${state.fechaInicio!.hour.toString().padLeft(2, '0')}:${state.fechaInicio!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: state.rutaIniciada 
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),
                if (state.sincronizacionEnProceso)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                else if (!state.rutaIniciada)
                  ElevatedButton(
                    onPressed: state.entregas.isEmpty || !_isLocationEnabled
                        ? null
                        : _iniciarRuta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      disabledBackgroundColor: colorScheme.surfaceTint.withAlpha(20),
                      foregroundColor: colorScheme.onPrimary,
                      disabledForegroundColor: colorScheme.onSurface.withAlpha(150),
                    ),
                    child: const Text('Iniciar entregas'),
                  )
                else
                  ElevatedButton(
                    onPressed: !_isLocationEnabled ? null : _finalizarRuta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      disabledBackgroundColor: colorScheme.surfaceTint.withAlpha(20),
                      foregroundColor: colorScheme.onError,
                      disabledForegroundColor: colorScheme.onSurface.withAlpha(150),
                    ),
                    child: const Text('Finalizar entregas'),
                  ),
              ],
            ),
          ),
          
          // Mensaje de información sobre entregas
          if (state.entregas.isEmpty && !state.isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: colorScheme.tertiaryContainer,
              child: Text(
                'No hay entregas pendientes para el día de hoy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            
          // Contador de entregas
          if (state.entregas.isNotEmpty)
            Container(
              color: colorScheme.secondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total de facturas: ${listaEntregasAgrupadas.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    'Productos: ${state.entregas.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          
          // Contenido principal - Cambia entre vista de tabla y vista de tarjetas según resolución
          Expanded(
            child: state.isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : state.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${state.error}',
                                style: TextStyle(color: colorScheme.error),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _cargarEntregas(_codEmpleado),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                ),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : state.entregas.isEmpty
                        ? const Center(
                            child: Text('No hay entregas pendientes'),
                          )
                        :  ListView.builder(
                                itemCount: listaEntregasAgrupadas.length,
                                itemBuilder: (context, index) {
                                  final entregas = listaEntregasAgrupadas[index].value;
                                  
                                  // Tomamos la primera entrega del grupo para los datos principales
                                  final entregaPrimaria = entregas.first;
                                  
                                  // La entrega se considera completada si todos los productos están entregados
                                  final todosEntregados = entregas.every((e) => e.fueEntregado == 1);
                                  final algunoEntregado = entregas.any((e) => e.fueEntregado == 1);
                                  
                                  return EntregaItem(
                                    entrega: entregaPrimaria,
                                    productosAdicionalesEntrega: entregas,
                                    rutaIniciada: state.rutaIniciada,
                                    onTap: () => _mostrarDialogoDireccion(entregaPrimaria),
                                    disabled: !state.rutaIniciada || todosEntregados,
                                    todosEntregados: todosEntregados,
                                    algunoEntregado: algunoEntregado,
                                  );
                                },
                              ),
          ),
          
          // Alerta para ubicación
          if (!_isLocationEnabled)
            Container(
              color: colorScheme.errorContainer,
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Column(
                children: [
                  Text(
                    '⚠️ La ubicación está desactivada',
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Active la ubicación para utilizar esta funcionalidad',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final enabled = await _checkLocationPermission();
                      if (mounted) {
                        setState(() {
                          _isLocationEnabled = enabled;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                    ),
                    child: const Text('Verificar permisos'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}