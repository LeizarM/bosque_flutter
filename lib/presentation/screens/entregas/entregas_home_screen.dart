import 'package:bosque_flutter/presentation/screens/entregas/controllers/entregas_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/observaciones_dialog.dart';

import 'package:bosque_flutter/presentation/widgets/entregas/entregas_location_banner.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_route_status_bar.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_filter_utils.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_responsive_views.dart';

class EntregasHomeScreen extends ConsumerStatefulWidget {
  const EntregasHomeScreen({super.key});

  @override
  ConsumerState<EntregasHomeScreen> createState() => _EntregasHomeScreenState();
}

class _EntregasHomeScreenState extends ConsumerState<EntregasHomeScreen> {
  bool _isLocationEnabled = false;
  int _codEmpleado = 0;
  bool _isInitializing = true;
  bool _isProcesingAction = false;
  late EntregasController _controller;

  // Controladores para búsqueda y ordenamiento
  String _searchText = '';
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _controller = EntregasController(ref, context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _inicializarPantalla();
    });
  }

  Future<void> _inicializarPantalla() async {
    final locationEnabled = await _controller.checkLocationPermission();
    final codEmpleado = await _controller.getCodEmpleado();
    await _controller.cargarEntregas(codEmpleado);
    if (mounted) {
      setState(() {
        _isLocationEnabled = locationEnabled;
        _codEmpleado = codEmpleado;
        _isInitializing = false;
      });
    }
  }

  Future<void> _iniciarRuta() async {
    if (!_isLocationEnabled) {
      _controller.mostrarMensajeError('Debe activar los servicios de ubicación para iniciar entregas');
      return;
    }
    setState(() {
      _isProcesingAction = true;
    });
    try {
      await _controller.iniciarRuta();
      if (mounted) {
        _controller.mostrarMensajeExito('Ruta iniciada correctamente');
      }
    } catch (e) {
      if (mounted) {
        _controller.mostrarMensajeError('Error al iniciar ruta: ${e.toString()}');
      }
    } finally {
      final locationEnabled = await _controller.checkLocationPermission();
      if (mounted) {
        setState(() {
          _isLocationEnabled = locationEnabled;
          _isProcesingAction = false;
        });
      }
    }
  }

  Future<void> _finalizarRuta() async {
    if (!_isLocationEnabled) {
      _controller.mostrarMensajeError('Debe activar los servicios de ubicación para finalizar entregas');
      return;
    }
    setState(() {
      _isProcesingAction = true;
    });
    try {
      await _controller.finalizarRuta();
      if (mounted) {
        _controller.mostrarMensajeExito('Ruta finalizada correctamente');
      }
    } catch (e) {
      if (mounted) {
        _controller.mostrarMensajeError('Error al finalizar ruta: ${e.toString()}');
      }
    } finally {
      final locationEnabled = await _controller.checkLocationPermission();
      if (mounted) {
        setState(() {
          _isLocationEnabled = locationEnabled;
          _isProcesingAction = false;
        });
      }
    }
  }

  Future<void> _mostrarDialogoDireccion(EntregaEntity entrega) async {
    if (!_isLocationEnabled) {
      _controller.mostrarMensajeError('Debe activar los servicios de ubicación para marcar entregas');
      return;
    }
    final state = ref.read(entregasNotifierProvider);
    if (!state.rutaIniciada) {
      _controller.mostrarMensajeError('Debe iniciar la ruta antes de marcar entregas');
      return;
    }
    final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ObservacionesDialog(
        direccion: entrega.direccionEntrega ?? entrega.addressEntregaMat,
      ),
    );
    if (resultado != null && resultado['observaciones'] != null) {
      setState(() {
        _isProcesingAction = true;
      });
      try {
        await _controller.marcarEntregaCompletada(entrega, resultado['observaciones']);
        if (mounted) {
          _controller.mostrarMensajeExito('Entrega marcada correctamente');
        }
      } catch (e) {
        if (mounted) {
          _controller.mostrarMensajeError('Error al marcar la entrega: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcesingAction = false;
          });
        }
      }
    }
  }
  
  Future<void> _verificarPermisos() async {
    final enabled = await _controller.solicitarPermisosUbicacion();
    if (mounted) {
      setState(() {
        _isLocationEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entregasNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final verticalPadding = ResponsiveUtilsBosque.getVerticalPadding(context);

    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final entregasAgrupadas = EntregasFilterUtils.agruparEntregas(state.entregas);
    final listaEntregasAgrupadas = entregasAgrupadas.entries.toList();
    final filteredEntregas = EntregasFilterUtils.getFilteredAndSortedEntregas(
      listaEntregasAgrupadas,
      _searchText,
      _sortColumnIndex,
      _sortAscending
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Entregas',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        actions: [
          if (!state.rutaIniciada)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.cargarEntregas(_codEmpleado),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barra de estado de la ruta
              EntregasRouteStatusBar(
                rutaIniciada: state.rutaIniciada,
                fechaInicio: state.fechaInicio,
                isLocationEnabled: _isLocationEnabled,
                isProcessing: state.sincronizacionEnProceso || _isProcesingAction,
                entregasVacias: state.entregas.isEmpty,
                onIniciarRuta: _iniciarRuta,
                onFinalizarRuta: _finalizarRuta,
              ),

              if (state.entregas.isEmpty && !state.isLoading)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
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

              if (state.entregas.isNotEmpty)
                Container(
                  color: colorScheme.secondaryContainer,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding / 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total de facturas: ${filteredEntregas.length}',
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

              // Barra de búsqueda solo en desktop
              if (isDesktop)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por cliente, factura o dirección...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) => setState(() => _searchText = value),
                  ),
                ),

              // Contenido principal responsivo
              Expanded(
                child: state.isLoading
                    ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                    : state.error != null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(horizontalPadding),
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
                                    onPressed: () => _controller.cargarEntregas(_codEmpleado),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.surfaceBright,
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
                            : isDesktop
                                ? EntregasDesktopView(
                                    filteredEntregas: filteredEntregas,
                                    rutaIniciada: state.rutaIniciada,
                                    onMarcarEntrega: _mostrarDialogoDireccion,
                                    sortColumnIndex: _sortColumnIndex,
                                    sortAscending: _sortAscending,
                                    onSort: (columnIndex, ascending) {
                                      setState(() {
                                        _sortColumnIndex = columnIndex;
                                        _sortAscending = ascending;
                                      });
                                    },
                                  )
                                : isTablet
                                    ? Padding(
                                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                                        child: GridView.builder(
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 1.0, // Ajusta si quieres más alto o más ancho
                                          ),
                                          itemCount: filteredEntregas.length,
                                          itemBuilder: (context, index) {
                                            final facturaData = filteredEntregas[index];
                                            final cliente = facturaData.key;
                                            final entregas = facturaData.value;
                                            // Usa el mismo widget de tarjeta que en móvil
                                            return EntregasMobileView(
                                              entregasAgrupadas: [MapEntry(cliente, entregas)],
                                              rutaIniciada: state.rutaIniciada,
                                              onMarcarEntrega: _mostrarDialogoDireccion,
                                            );
                                          },
                                        ),
                                      )
                                    : EntregasMobileView(
                                        entregasAgrupadas: filteredEntregas,
                                        rutaIniciada: state.rutaIniciada,
                                        onMarcarEntrega: _mostrarDialogoDireccion,
                                      ),
              ),

              // Banner de ubicación
              EntregasLocationBanner(
                isLocationEnabled: _isLocationEnabled,
                onVerifyPermissions: _verificarPermisos,
              ),
            ],
          ),

          if (_isProcesingAction)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Procesando...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
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
  }
}