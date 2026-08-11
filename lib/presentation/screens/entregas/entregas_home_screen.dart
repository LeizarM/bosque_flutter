import 'package:bosque_flutter/presentation/screens/entregas/controllers/entregas_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/entregas_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/entregas_entity.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/observaciones_dialog.dart';

import 'package:bosque_flutter/presentation/widgets/entregas/entregas_location_banner.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_ui.dart';
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

  /// Cuándo se trajeron los datos por última vez. El chofer necesita saber si
  /// lo que ve es de hace diez segundos o de hace una hora; sin esta marca, una
  /// lista vacía y una lista desactualizada se ven exactamente igual.
  DateTime? _ultimaActualizacion;
  bool _refrescando = false;
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

  /// Arranque de la pantalla.
  ///
  /// <h3>Por qué la ubicación no se espera</h3>
  /// Antes esto era una fila india: primero `checkLocationPermission()`, después
  /// `getCodEmpleado()` y recién al final `cargarEntregas()`. El permiso de ubicación es lo
  /// más lento de los tres —puede abrir el diálogo del sistema, y en web `requestPermission()`
  /// es un `getCurrentPosition()` que espera a que el GPS fije posición— así que el chofer
  /// miraba un spinner sin datos por algo que no hace falta para VER la lista. La ubicación
  /// solo se necesita para *iniciar la ruta* y para *marcar*, no para leer.
  ///
  /// Ahora la ubicación arranca en paralelo y no bloquea: la lista se muestra apenas llega, y
  /// cuando el permiso se resuelve se actualiza el banner y el botón de iniciar ruta. Si el
  /// GPS tarda diez segundos, la lista igual estuvo en pantalla desde el primer segundo.
  Future<void> _inicializarPantalla() async {
    // Se dispara y NO se espera todavía.
    final futuroUbicacion = _controller.checkLocationPermission();

    final codEmpleado = await _controller.getCodEmpleado();
    await _controller.cargarEntregas(codEmpleado);

    if (mounted) {
      setState(() {
        _codEmpleado = codEmpleado;
        _isInitializing = false;
        _ultimaActualizacion = DateTime.now();
      });
    }

    // La ubicación llega cuando llega. Un fallo acá deja el banner de "ubicación desactivada",
    // que es exactamente lo que corresponde mostrar.
    bool ubicacion = false;
    try {
      ubicacion = await futuroUbicacion;
    } catch (_) {
      ubicacion = false;
    }
    if (mounted) {
      setState(() => _isLocationEnabled = ubicacion);
    }
  }

  Future<void> _iniciarRuta() async {
    if (!_isLocationEnabled) {
      _controller.mostrarMensajeError(
        'Debe activar los servicios de ubicación para iniciar entregas',
      );
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
        _controller.mostrarMensajeError(
          'Error al iniciar ruta: ${e.toString()}',
        );
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
      _controller.mostrarMensajeError(
        'Debe activar los servicios de ubicación para finalizar entregas',
      );
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
        _controller.mostrarMensajeError(
          'Error al finalizar ruta: ${e.toString()}',
        );
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
      _controller.mostrarMensajeError(
        'Debe activar los servicios de ubicación para marcar entregas',
      );
      return;
    }
    final state = ref.read(entregasNotifierProvider);
    if (!state.rutaIniciada) {
      _controller.mostrarMensajeError(
        'Debe iniciar la ruta antes de marcar entregas',
      );
      return;
    }
    final resultado = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => ObservacionesDialog(
            direccion: entrega.direccionEntrega ?? entrega.addressEntregaMat,
          ),
    );
    if (resultado != null && resultado['observaciones'] != null) {
      setState(() {
        _isProcesingAction = true;
      });
      try {
        await _controller.marcarEntregaCompletada(
          entrega,
          resultado['observaciones'],
        );
        if (mounted) {
          _controller.mostrarMensajeExito('Entrega marcada correctamente');
        }
      } catch (e) {
        if (mounted) {
          _controller.mostrarMensajeError(
            'Error al marcar la entrega: ${e.toString()}',
          );
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

  /// Vuelve a pedir la lista al backend.
  ///
  /// Reemplaza al IconButton que estaba condicionado a `!state.rutaIniciada`:
  /// el refresh desaparecía justo cuando más se usa, que es con la ruta en
  /// curso y el chofer esperando que aparezca una factura recién asignada.
  Future<void> _refrescar() async {
    if (_refrescando) return;
    setState(() => _refrescando = true);
    try {
      await _controller.cargarEntregas(_codEmpleado);
      if (mounted) setState(() => _ultimaActualizacion = DateTime.now());
    } finally {
      if (mounted) setState(() => _refrescando = false);
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
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final horizontalPadding = ResponsiveUtilsBosque.getHorizontalPadding(
      context,
    );

    if (_isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final entregasAgrupadas = EntregasFilterUtils.agruparEntregas(
      state.entregas,
    );
    final listaEntregasAgrupadas = entregasAgrupadas.entries.toList();
    final filteredEntregas = EntregasFilterUtils.getFilteredAndSortedEntregas(
      listaEntregasAgrupadas,
      _searchText,
      _sortColumnIndex,
      _sortAscending,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Entregas',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        actions: [
          if (_ultimaActualizacion != null && !isMobile)
            Padding(
              padding: const EdgeInsets.only(right: EntregasUI.s2),
              child: Center(
                child: Text(
                  'Actualizado '
                  '${_ultimaActualizacion!.hour.toString().padLeft(2, '0')}:'
                  '${_ultimaActualizacion!.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: EntregasUI.muted(colorScheme),
                  ),
                ),
              ),
            ),
          // Siempre disponible: antes estaba detrás de `!state.rutaIniciada` y
          // se escondía justo cuando el chofer más lo necesita.
          IconButton(
            tooltip: 'Actualizar lista',
            onPressed: _refrescando ? null : _refrescar,
            icon: _refrescando
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EntregasUI.muted(colorScheme),
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: EntregasUI.s2),
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
                isProcessing:
                    state.sincronizacionEnProceso || _isProcesingAction,
                entregasVacias: state.entregas.isEmpty,
                onIniciarRuta: _iniciarRuta,
                onFinalizarRuta: _finalizarRuta,
              ),

              // Resumen + buscador, en una sola banda. Antes eran dos franjas
              // apiladas de colores distintos (lila y luego el TextField suelto),
              // lo que partia la pantalla en bandas horizontales sin jerarquia.
              if (state.entregas.isNotEmpty)
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: EntregasUI.maxContentWidth,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        EntregasUI.padH(context),
                        EntregasUI.s5,
                        EntregasUI.padH(context),
                        EntregasUI.s3,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          EntregasStat(
                            valor: '${filteredEntregas.length}',
                            etiqueta: filteredEntregas.length == 1
                                ? 'FACTURA'
                                : 'FACTURAS',
                          ),
                          const SizedBox(width: EntregasUI.s6),
                          EntregasStat(
                            valor: '${state.entregas.length}',
                            etiqueta: 'PRODUCTOS',
                          ),
                          const Spacer(),
                          if (isDesktop)
                            SizedBox(
                              width: 320,
                              child: TextField(
                                onChanged: (v) =>
                                    setState(() => _searchText = v),
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Buscar cliente, factura o dirección',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: EntregasUI.muted(colorScheme),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    size: 18,
                                    color: EntregasUI.muted(colorScheme),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 38,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: EntregasUI.s3,
                                    horizontal: EntregasUI.s3,
                                  ),
                                  filled: true,
                                  fillColor:
                                      EntregasUI.raised(colorScheme),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      EntregasUI.rInner,
                                    ),
                                    borderSide: BorderSide(
                                      color: EntregasUI.hairline(colorScheme),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(
                                      EntregasUI.rInner,
                                    ),
                                    borderSide: BorderSide(
                                      color: EntregasUI.hairline(colorScheme),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Contenido principal responsivo
              Expanded(
                child:
                    state.isLoading
                        ? const Padding(
                          padding: EdgeInsets.only(top: EntregasUI.s5),
                          child: EntregasSkeleton(),
                        )
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
                                  onPressed:
                                      () => _controller.cargarEntregas(
                                        _codEmpleado,
                                      ),
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
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 40,
                                color: EntregasUI.muted(colorScheme),
                              ),
                              const SizedBox(height: EntregasUI.s4),
                              Text(
                                'No hay entregas para hoy',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: EntregasUI.s1),
                              Text(
                                'Cuando se asignen facturas a tu ruta van a aparecer acá.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EntregasUI.muted(colorScheme),
                                ),
                              ),
                              const SizedBox(height: EntregasUI.s5),
                              OutlinedButton.icon(
                                onPressed: () => _controller.cargarEntregas(
                                  _codEmpleado,
                                ),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Actualizar'),
                              ),
                            ],
                          ),
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
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding / 2,
                          ),
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio:
                                      1.0, // Ajusta si quieres más alto o más ancho
                                ),
                            itemCount: filteredEntregas.length,
                            itemBuilder: (context, index) {
                              final facturaData = filteredEntregas[index];
                              final cliente = facturaData.key;
                              final entregas = facturaData.value;
                              // Usa el mismo widget de tarjeta que en móvil
                              return EntregasMobileView(
                                entregasAgrupadas: [
                                  MapEntry(cliente, entregas),
                                ],
                                rutaIniciada: state.rutaIniciada,
                                onMarcarEntrega: _mostrarDialogoDireccion,
                              );
                            },
                          ),
                        )
                        // En el celular el gesto esperado es tirar hacia abajo,
                        // no buscar un icono en la barra. El boton del AppBar
                        // sigue estando para quien lo prefiera.
                        : RefreshIndicator(
                          onRefresh: _refrescar,
                          child: EntregasMobileView(
                            entregasAgrupadas: filteredEntregas,
                            rutaIniciada: state.rutaIniciada,
                            onMarcarEntrega: _mostrarDialogoDireccion,
                          ),
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
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
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
