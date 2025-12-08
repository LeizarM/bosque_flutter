import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/prestamo_vehiculos_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/presentation/widgets/prestamo_vehiculos/entrega_prestamo_dialog.dart';
import 'package:bosque_flutter/presentation/widgets/prestamo_vehiculos/recepcion_prestamo_dialog.dart';

class PrestamoViewScreen extends ConsumerStatefulWidget {
  const PrestamoViewScreen({super.key});

  @override
  ConsumerState<PrestamoViewScreen> createState() => _PrestamoViewScreenState();
}

class _PrestamoViewScreenState extends ConsumerState<PrestamoViewScreen> {
  String _estadoFiltro = 'TODOS';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSolicitudesPrestamos();
    });
  }

  void _cargarSolicitudesPrestamos() async {
    final user = ref.read(userProvider);
    if (user != null) {
      ref
          .read(solicitudesPrestamosNotifierProvider.notifier)
          .cargarSolicitudesPrestamos(user.codSucursal, user.codEmpleado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(solicitudesPrestamosNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Gestión de Préstamos de Vehículos',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: ResponsiveUtilsBosque.isDesktop(context) ? 2 : 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarSolicitudesPrestamos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(colorScheme),
          Expanded(child: _buildContent(state, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildFiltros(ColorScheme colorScheme) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Card(
      margin: EdgeInsets.all(
        ResponsiveUtilsBosque.getHorizontalPadding(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            isDesktop
                ? _buildDesktopFiltros(colorScheme)
                : _buildMobileFiltros(colorScheme),
      ),
    );
  }

  Widget _buildDesktopFiltros(ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(Icons.filter_list, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          'Filtrar por estado:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildDropdownField(colorScheme)),
      ],
    );
  }

  Widget _buildMobileFiltros(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_list, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Filtrar por estado',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDropdownField(colorScheme),
      ],
    );
  }

  Widget _buildDropdownField(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      value: _estadoFiltro,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        isDense: true,
      ),
      isExpanded: true,
      menuMaxHeight: 300,
      items: [
        const DropdownMenuItem(
          value: 'TODOS',
          child: Text('Todos', overflow: TextOverflow.ellipsis),
        ),
        const DropdownMenuItem(
          value: 'Disponible - Pendiente Aprobación',
          child: Text('Pendiente Aprobación', overflow: TextOverflow.ellipsis),
        ),
        const DropdownMenuItem(
          value: 'Aprobado - Pendiente Entrega',
          child: Text(
            'Aprobado - Pendiente Entrega',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const DropdownMenuItem(
          value: 'Aprobado - En Uso - Pendiente Devolución',
          child: Text(
            'En Uso - Pendiente Devolución',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _estadoFiltro = value!;
        });
      },
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: ResponsiveUtilsBosque.isDesktop(context) ? 14 : 13,
      ),
      dropdownColor: colorScheme.surface,
    );
  }

  Widget _buildContent(
    SolicitudesPrestamosState state,
    ColorScheme colorScheme,
  ) {
    // Debug: Agregar logs para verificar el estado
    print('🔍 PrestamoViewScreen - Estado: ${state.status}');
    print(
      '🔍 PrestamoViewScreen - Solicitudes count: ${state.solicitudesPrestamos.length}',
    );

    if (state.status == FetchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == FetchStatus.error) {
      print('❌ Error: ${state.errorMessage}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar solicitudes',
              style: TextStyle(fontSize: 18, color: colorScheme.error),
            ),
            const SizedBox(height: 8),
            Text(
              state.errorMessage ?? 'Error desconocido',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarSolicitudesPrestamos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );
    }

    final solicitudesFiltradas = _filtrarSolicitudes(
      state.solicitudesPrestamos,
    );
    print('🔍 Solicitudes filtradas count: ${solicitudesFiltradas.length}');
    print('🔍 Filtro actual: $_estadoFiltro');

    if (solicitudesFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _estadoFiltro == 'TODOS'
                  ? 'No hay solicitudes de préstamos'
                  : 'Sin solicitudes para: $_estadoFiltro',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                _estadoFiltro == 'TODOS'
                    ? 'Actualmente no hay solicitudes de préstamos de vehículos pendientes de gestión. Las nuevas solicitudes aparecerán aquí automáticamente.'
                    : 'No se encontraron solicitudes con el estado seleccionado. Intente cambiar el filtro para ver otras solicitudes.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _cargarSolicitudesPrestamos,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
                if (_estadoFiltro != 'TODOS') ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _estadoFiltro = 'TODOS';
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Ver Todas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    print('🔍 Es Desktop: $isDesktop');

    return isDesktop
        ? _buildDesktopTable(solicitudesFiltradas, colorScheme)
        : _buildMobileList(solicitudesFiltradas, colorScheme);
  }

  // Métodos de acción para los botones
  void _aprobarSolicitud(dynamic solicitud) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Aprobación'),
            content: Text(
              '¿Está seguro que desea aprobar la solicitud #${solicitud.idSolicitud}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Aprobar'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      final success = await ref
          .read(solicitudesPrestamosNotifierProvider.notifier)
          .aprobarSolicitud(solicitud.idSolicitud);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitud #${solicitud.idSolicitud} aprobada exitosamente',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        // Recargar la lista
        _cargarSolicitudesPrestamos();
      } else {
        final state = ref.read(solicitudesPrestamosNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al aprobar solicitud: ${state.errorMessage ?? "Error desconocido"}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _rechazarSolicitud(dynamic solicitud) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Rechazo'),
            content: Text(
              '¿Está seguro que desea rechazar la solicitud #${solicitud.idSolicitud}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rechazar'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      final success = await ref
          .read(solicitudesPrestamosNotifierProvider.notifier)
          .rechazarSolicitud(solicitud.idSolicitud);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solicitud #${solicitud.idSolicitud} rechazada exitosamente',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        // Recargar la lista
        _cargarSolicitudesPrestamos();
      } else {
        final state = ref.read(solicitudesPrestamosNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al rechazar solicitud: ${state.errorMessage ?? "Error desconocido"}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _entregarVehiculo(dynamic solicitud) async {
    // Si requiere chofer, cargar la lista de choferes primero
    if (solicitud.requiereChofer == 1) {
      await ref
          .read(solicitudesPrestamosNotifierProvider.notifier)
          .cargarChoferes();
    }

    // Mostrar el diálogo y esperar los datos de entrega
    final entrega = await showDialog(
      context: context,
      builder: (context) => EntregaPrestamoDialog(solicitud: solicitud),
    );

    if (entrega != null) {
      // Registrar la entrega usando el método del provider
      final success = await ref
          .read(solicitudesPrestamosNotifierProvider.notifier)
          .registrarEntregaPrestamo(entrega);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Entrega registrada exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        // Recargar la lista
        _cargarSolicitudesPrestamos();
      } else {
        final state = ref.read(solicitudesPrestamosNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al registrar entrega: ${state.errorMessage ?? "Error desconocido"}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _recibirVehiculo(dynamic solicitud) async {
    // Mostrar el diálogo y esperar los datos de recepción
    final recepcion = await showDialog(
      context: context,
      builder: (context) => RecepcionPrestamoDialog(solicitud: solicitud),
    );

    if (recepcion != null) {
      // Registrar la recepción usando el método del provider
      final success = await ref
          .read(solicitudesPrestamosNotifierProvider.notifier)
          .registrarRecepcionPrestamo(recepcion);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Recepción registrada exitosamente'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        // Recargar la lista
        _cargarSolicitudesPrestamos();
      } else {
        final state = ref.read(solicitudesPrestamosNotifierProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al registrar recepción: ${state.errorMessage ?? "Error desconocido"}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  List<dynamic> _filtrarSolicitudes(List<dynamic> solicitudes) {
    if (_estadoFiltro == 'TODOS') {
      return solicitudes;
    }
    return solicitudes
        .where((s) => s.estadoDisponibilidad == _estadoFiltro)
        .toList();
  }

  Widget _buildDesktopTable(
    List<dynamic> solicitudes,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: EdgeInsets.all(
        ResponsiveUtilsBosque.getHorizontalPadding(context),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Solicitudes de Préstamos de Vehículos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${solicitudes.length} solicitudes',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tabla
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  colorScheme.primaryContainer,
                ),
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Fecha Solicitud')),
                  DataColumn(label: Text('Solicitante')),
                  DataColumn(label: Text('Motivo')),
                  DataColumn(label: Text('Vehículo')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Chofer')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows:
                    solicitudes.map((solicitud) {
                      return DataRow(
                        cells: [
                          DataCell(Text('#${solicitud.idSolicitud}')),
                          DataCell(
                            Text(
                              DateFormat('dd/MM/yyyy').format(
                                DateTime.parse(solicitud.fechaSolicitud),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message:
                                  '${solicitud.solicitante} - ${solicitud.cargo}',
                              child: SizedBox(
                                width: 150,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      solicitud.solicitante,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      solicitud.cargo,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: solicitud.motivo,
                              child: SizedBox(
                                width: 120,
                                child: Text(
                                  solicitud.motivo,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Tooltip(
                              message: solicitud.coche,
                              child: SizedBox(
                                width: 150,
                                child: Text(
                                  solicitud.coche,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            _buildEstadoChip(
                              solicitud.estadoDisponibilidad,
                              colorScheme,
                            ),
                          ),
                          DataCell(
                            Icon(
                              solicitud.requiereChofer == 1
                                  ? Icons.person
                                  : Icons.person_off,
                              color:
                                  solicitud.requiereChofer == 1
                                      ? Colors.blue
                                      : Colors.grey,
                              size: 20,
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (solicitud.estadoDisponibilidad ==
                                    'Disponible - Pendiente Aprobación') ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed:
                                        () => _aprobarSolicitud(solicitud),
                                    tooltip: 'Aprobar',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _rechazarSolicitud(solicitud),
                                    tooltip: 'Rechazar',
                                  ),
                                ] else if (solicitud.estadoDisponibilidad ==
                                    'Aprobado - Pendiente Entrega')
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delivery_dining,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        () => _entregarVehiculo(solicitud),
                                    tooltip: 'Entregar Vehículo',
                                  )
                                else if (solicitud.estadoDisponibilidad ==
                                    'Aprobado - En Uso - Pendiente Devolución')
                                  IconButton(
                                    icon: const Icon(
                                      Icons.assignment_return,
                                      color: Colors.orange,
                                    ),
                                    onPressed:
                                        () => _recibirVehiculo(solicitud),
                                    tooltip: 'Recibir Vehículo',
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<dynamic> solicitudes, ColorScheme colorScheme) {
    print('🔍 BuildMobileList - Solicitudes: ${solicitudes.length}');

    return Column(
      children: [
        // Header para móvil simplificado
        Container(
          width: double.infinity,
          margin: EdgeInsets.all(
            ResponsiveUtilsBosque.getHorizontalPadding(context),
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Préstamos de Vehículos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${solicitudes.length}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Lista con scroll
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
            ),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = solicitudes[index];
              print('🔍 Construyendo item $index: ${solicitud.idSolicitud}');

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header de la tarjeta
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Solicitud #${solicitud.idSolicitud}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildMobileEstadoChip(
                              solicitud.estadoDisponibilidad,
                              colorScheme,
                            ),
                          ],
                        ),

                        const Divider(height: 20),

                        // Información básica
                        _buildSimpleInfoRow(
                          'Fecha:',
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.parse(solicitud.fechaSolicitud)),
                        ),
                        const SizedBox(height: 4),
                        _buildSimpleInfoRow(
                          'Solicitante:',
                          solicitud.solicitante ?? 'N/A',
                        ),
                        const SizedBox(height: 4),
                        _buildSimpleInfoRow('Cargo:', solicitud.cargo ?? 'N/A'),
                        const SizedBox(height: 4),
                        _buildSimpleInfoRow(
                          'Motivo:',
                          solicitud.motivo ?? 'N/A',
                        ),
                        const SizedBox(height: 4),
                        _buildSimpleInfoRow(
                          'Vehículo:',
                          solicitud.coche ?? 'N/A',
                        ),
                        const SizedBox(height: 4),

                        // Chofer
                        Row(
                          children: [
                            const Text(
                              'Requiere Chofer: ',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Icon(
                              solicitud.requiereChofer == 1
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color:
                                  solicitud.requiereChofer == 1
                                      ? Colors.green
                                      : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              solicitud.requiereChofer == 1 ? 'Sí' : 'No',
                              style: TextStyle(
                                color:
                                    solicitud.requiereChofer == 1
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                          ],
                        ),

                        // Botones de acción
                        const SizedBox(height: 12),
                        _buildSimpleActionButtons(solicitud, colorScheme),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileEstadoChip(String estado, ColorScheme colorScheme) {
    Color chipColor;

    switch (estado) {
      case 'Disponible - Pendiente Aprobación':
        chipColor = Colors.orange;
        break;
      case 'Aprobado - Pendiente Entrega':
        chipColor = Colors.blue;
        break;
      case 'Entregado':
        chipColor = Colors.green;
        break;
      case 'Devuelto':
        chipColor = Colors.grey;
        break;
      case 'Aprobado - En Uso - Pendiente Devolución':
        chipColor = Colors.red;
        break;
      default:
        chipColor = colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        estado,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSimpleActionButtons(dynamic solicitud, ColorScheme colorScheme) {
    if (solicitud.estadoDisponibilidad == 'Disponible - Pendiente Aprobación') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _aprobarSolicitud(solicitud),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Aprobar', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _rechazarSolicitud(solicitud),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('Rechazar', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    } else if (solicitud.estadoDisponibilidad ==
        'Aprobado - Pendiente Entrega') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _entregarVehiculo(solicitud),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Entregar Vehículo'),
        ),
      );
    } else if (solicitud.estadoDisponibilidad ==
        'Aprobado - En Uso - Pendiente Devolución') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _recibirVehiculo(solicitud),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Recibir Vehículo'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Sin acciones disponibles',
        style: TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEstadoChip(String estado, ColorScheme colorScheme) {
    Color chipColor;
    IconData icon;

    switch (estado) {
      case 'Disponible - Pendiente Aprobación':
        chipColor = Colors.orange;
        icon = Icons.pending;
        break;
      case 'Aprobado - Pendiente Entrega':
        chipColor = Colors.blue;
        icon = Icons.check_circle;
        break;
      case 'Entregado':
        chipColor = Colors.green;
        icon = Icons.delivery_dining;
        break;
      case 'Devuelto':
        chipColor = Colors.grey;
        icon = Icons.assignment_return;
        break;
      case 'Aprobado - En Uso - Pendiente Devolución':
        chipColor = Colors.red;
        icon = Icons.assignment_late;
        break;
      default:
        chipColor = colorScheme.primary;
        icon = Icons.help_outline;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Chip(
        avatar: Icon(icon, color: Colors.white, size: 12),
        label: Text(
          estado,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        backgroundColor: chipColor,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
