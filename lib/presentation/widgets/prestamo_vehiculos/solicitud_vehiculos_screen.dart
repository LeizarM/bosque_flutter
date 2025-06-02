import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/prestamo_vehiculos_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';

class SolicitudVehiculosScreen extends ConsumerStatefulWidget {
  const SolicitudVehiculosScreen({super.key});

  @override
  ConsumerState<SolicitudVehiculosScreen> createState() => _SolicitudVehiculosScreenState();
}

class _SolicitudVehiculosScreenState extends ConsumerState<SolicitudVehiculosScreen> {
  
  @override
  void initState() {
    super.initState();
    // Cargar solicitudes cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSolicitudesEmpleado();
    });
  }

  Future<void> _cargarSolicitudesEmpleado() async {
    try {
      final userNotifier = ref.read(userProvider.notifier);
      final codEmpleado = await userNotifier.getCodEmpleado();
      
      ref.read(solicitudesNotifierProvider.notifier)
          .cargarSolicitudesEmpleado(codEmpleado);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener datos del usuario: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(solicitudesNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Mis Solicitudes de Vehículos',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _buildContent(state, colorScheme),
    );
  }

  Widget _buildContent(SolicitudesState state, ColorScheme colorScheme) {
    if (state.status == FetchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == FetchStatus.error) {
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
              onPressed: _cargarSolicitudesEmpleado,
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

    if (state.solicitudes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No tienes solicitudes registradas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Text(
                'Aún no has creado ninguna solicitud de vehículo. '
                'Cuando realices una solicitud, aparecerá aquí con su estado actual.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarSolicitudesEmpleado,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      );
    }

    return ResponsiveUtilsBosque.isDesktop(context)
        ? _buildDesktopTable(state.solicitudes, colorScheme)
        : _buildMobileList(state.solicitudes, colorScheme);
  }

  Widget _buildDesktopTable(List<SolicitudChoferEntity> solicitudes, ColorScheme colorScheme) {
    return Card(
      margin: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mis Solicitudes de Vehículos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          // Tabla con scroll horizontal y vertical mejorado
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width * 0.7, // Reducir de 0.9 a 0.7
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(colorScheme.primaryContainer),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 72,
                    horizontalMargin: 16,
                    columnSpacing: 20, // Reducir de 24 a 20
                    showCheckboxColumn: false,
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    dataTextStyle: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                    columns: const [
                      DataColumn(
                        label: SizedBox(
                          width: 60, // Reducir de 80 a 60
                          child: Text('ID'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 100, // Mantener 100
                          child: Text('Fecha'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 250, // Reducir de 300 a 250
                          child: Text('Motivo'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 100, // Mantener 100
                          child: Text('Estado'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120, // Mantener 120
                          child: Text('Requiere Chofer'),
                        ),
                      ),
                    ],
                    rows: solicitudes.map((solicitud) {
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 60,
                              child: Text(solicitud.idSolicitud.toString()),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: Text(solicitud.fechaSolicitudCad.isNotEmpty 
                                  ? solicitud.fechaSolicitudCad.split(' ')[0] 
                                  : 'N/A'),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 250), // Reducir de 300 a 250
                              child: Tooltip(
                                message: solicitud.motivo,
                                child: Text(
                                  solicitud.motivo,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              child: _buildEstadoChip(solicitud.estadoCad, colorScheme),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Text(
                                solicitud.requiereChofer == 1 ? 'Sí' : 'No',
                                style: TextStyle(
                                  color: solicitud.requiereChofer == 1 
                                      ? colorScheme.primary 
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: solicitud.requiereChofer == 1 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<SolicitudChoferEntity> solicitudes, ColorScheme colorScheme) {
    return Column(
      children: [
        // Header para móvil
        Container(
          margin: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Solicitudes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${solicitudes.length}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
            ),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final solicitud = solicitudes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Solicitud #${solicitud.idSolicitud}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          _buildEstadoChip(solicitud.estadoCad, colorScheme),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Fecha:', solicitud.fechaSolicitudCad.isNotEmpty 
                          ? solicitud.fechaSolicitudCad.split(' ')[0] 
                          : 'N/A'),
                      _buildInfoRow('Motivo:', solicitud.motivo),
                      _buildInfoRow('Cargo:', solicitud.cargo),
                      _buildInfoRow('Requiere Chofer:', solicitud.requiereChofer == 1 ? 'Sí' : 'No'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoChip(String estado, ColorScheme colorScheme) {
    Color chipColor;
    switch (estado.toLowerCase()) {
      case 'pendiente':
        chipColor = Colors.orange;
        break;
      case 'aprobado':
        chipColor = Colors.green;
        break;
      case 'rechazado':
        chipColor = Colors.red;
        break;
      default:
        chipColor = colorScheme.primary;
    }

    return Chip(
      label: Text(
        estado,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
