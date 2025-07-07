import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/prestamo_vehiculos_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/solicitud_chofer_entity.dart';

class EstadoVehiculosScreen extends ConsumerStatefulWidget {
  const EstadoVehiculosScreen({super.key});

  @override
  ConsumerState<EstadoVehiculosScreen> createState() => _EstadoVehiculosScreenState();
}

class _EstadoVehiculosScreenState extends ConsumerState<EstadoVehiculosScreen> {
  String _filtroEstado = 'TODOS';
  String _filtroSucursal = 'TODAS';

  @override
  void initState() {
    super.initState();
    // Cargar vehículos cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarVehiculos();
    });
  }

  void _cargarVehiculos() {
    ref.refresh(cochesDisponiblesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cochesAsync = ref.watch(cochesDisponiblesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Estado de Vehículos',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: _cargarVehiculos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(colorScheme),
          Expanded(
            child: cochesAsync.when(
              data: (coches) => _buildContent(coches, colorScheme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildError(error.toString(), colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(ColorScheme colorScheme) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    
    return Card(
      margin: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isDesktop
            ? Row(
                children: [
                  Expanded(child: _buildFiltroEstado(colorScheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFiltroSucursal(colorScheme)),
                ],
              )
            : Column(
                children: [
                  _buildFiltroEstado(colorScheme),
                  const SizedBox(height: 16),
                  _buildFiltroSucursal(colorScheme),
                ],
              ),
      ),
    );
  }

  Widget _buildFiltroEstado(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      value: _filtroEstado,
      decoration: InputDecoration(
        labelText: 'Estado',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      items: const [
        DropdownMenuItem(value: 'TODOS', child: Text('TODOS')),
        DropdownMenuItem(value: 'Disponible', child: Text('DISPONIBLES')),
        DropdownMenuItem(value: 'Uso', child: Text('EN USO')),
        DropdownMenuItem(value: 'Mantenimiento', child: Text('MANTENIMIENTO')),
      ],
      onChanged: (value) {
        setState(() {
          _filtroEstado = value!;
        });
      },
    );
  }

  Widget _buildFiltroSucursal(ColorScheme colorScheme) {
    final cochesAsync = ref.watch(cochesDisponiblesProvider);
    
    return cochesAsync.when(
      data: (coches) {
        // Extraer sucursales únicas de los vehículos
        final sucursales = <String>{'TODAS'};
        for (final coche in coches) {
          if (coche.coche.isNotEmpty) {
            final parts = coche.coche.split(' - ');
            if (parts.isNotEmpty) {
              sucursales.add(parts[0]);
            }
          }
        }

        return DropdownButtonFormField<String>(
          value: _filtroSucursal,
          decoration: InputDecoration(
            labelText: 'Sucursal',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ),
          items: sucursales.map((sucursal) => 
            DropdownMenuItem(value: sucursal, child: Text(sucursal))
          ).toList(),
          onChanged: (value) {
            setState(() {
              _filtroSucursal = value!;
            });
          },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        value: _filtroSucursal,
        decoration: InputDecoration(
          labelText: 'Sucursal',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        items: const [
          DropdownMenuItem(value: 'TODAS', child: Text('TODAS')),
        ],
        onChanged: null,
      ),
      error: (_, __) => DropdownButtonFormField<String>(
        value: _filtroSucursal,
        decoration: InputDecoration(
          labelText: 'Sucursal',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        items: const [
          DropdownMenuItem(value: 'TODAS', child: Text('TODAS')),
        ],
        onChanged: null,
      ),
    );
  }

  Widget _buildContent(List<SolicitudChoferEntity> coches, ColorScheme colorScheme) {
    final vehiculosFiltrados = _filtrarVehiculos(coches);
    
    if (vehiculosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 80,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _filtroEstado == 'TODOS' 
                  ? 'No hay vehículos registrados'
                  : 'Sin vehículos para: $_filtroEstado',
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
                _filtroEstado == 'TODOS' 
                    ? 'No hay vehículos disponibles en el sistema. Contacte al administrador.'
                    : 'No se encontraron vehículos con el estado seleccionado. Intente cambiar el filtro.',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
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
                  onPressed: _cargarVehiculos,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                if (_filtroEstado != 'TODOS' || _filtroSucursal != 'TODAS') ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _filtroEstado = 'TODOS';
                        _filtroSucursal = 'TODAS';
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Limpiar Filtros'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return ResponsiveUtilsBosque.isDesktop(context)
        ? _buildDesktopTable(vehiculosFiltrados, colorScheme)
        : _buildMobileList(vehiculosFiltrados, colorScheme);
  }

  Widget _buildError(String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar vehículos',
            style: TextStyle(fontSize: 18, color: colorScheme.error),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarVehiculos,
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

  List<SolicitudChoferEntity> _filtrarVehiculos(List<SolicitudChoferEntity> coches) {
    return coches.where((coche) {
      // Filtrar por estado
      bool pasaFiltroEstado = true;
      if (_filtroEstado != 'TODOS') {
        final estado = _extraerEstado(coche.coche);
        pasaFiltroEstado = estado.toLowerCase().contains(_filtroEstado.toLowerCase());
      }

      // Filtrar por sucursal
      bool pasaFiltroSucursal = true;
      if (_filtroSucursal != 'TODAS') {
        final sucursal = _extraerSucursal(coche.coche);
        pasaFiltroSucursal = sucursal == _filtroSucursal;
      }

      return pasaFiltroEstado && pasaFiltroSucursal;
    }).toList();
  }

  String _extraerEstado(String coche) {
    // Formato: "SUCURSAL - Marca Tipo; PLACA (Estado)"
    final regex = RegExp(r'\(([^)]+)\)$');
    final match = regex.firstMatch(coche);
    return match?.group(1) ?? 'Desconocido';
  }

  String _extraerSucursal(String coche) {
    final parts = coche.split(' - ');
    return parts.isNotEmpty ? parts[0] : 'Desconocida';
  }

  String _extraerVehiculo(String coche) {
    // Extraer "Marca Tipo; PLACA" de "SUCURSAL - Marca Tipo; PLACA (Estado)"
    final regex = RegExp(r' - (.+) \([^)]+\)$');
    final match = regex.firstMatch(coche);
    return match?.group(1) ?? coche;
  }

  Widget _buildDesktopTable(List<SolicitudChoferEntity> vehiculos, ColorScheme colorScheme) {
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
                  'Estado de Vehículos',
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
                    '${vehiculos.length} vehículos',
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
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(colorScheme.primaryContainer),
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 72,
                    horizontalMargin: 16,
                    columnSpacing: 20,
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
                          width: 80,
                          child: Text('ID'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text('Sucursal'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 250,
                          child: Text('Vehículo'),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: 120,
                          child: Text('Estado'),
                        ),
                      ),
                    ],
                    rows: vehiculos.map((vehiculo) {
                      final estado = _extraerEstado(vehiculo.coche ?? '');
                      final sucursal = _extraerSucursal(vehiculo.coche ?? '');
                      final vehiculoInfo = _extraerVehiculo(vehiculo.coche ?? '');

                      return DataRow(
                        color: WidgetStateProperty.resolveWith<Color?>(
                          (Set<WidgetState> states) {
                            if (estado.toLowerCase().contains('uso')) {
                              return Colors.orange.withOpacity(0.1);
                            }
                            return null;
                          },
                        ),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 80,
                              child: Text(vehiculo.idCocheSol.toString()),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: Text(sucursal),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Tooltip(
                                message: vehiculoInfo,
                                child: Text(
                                  vehiculoInfo,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 120,
                              child: _buildEstadoChip(estado, colorScheme),
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

  Widget _buildMobileList(List<SolicitudChoferEntity> vehiculos, ColorScheme colorScheme) {
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
                'Vehículos',
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
                  '${vehiculos.length}',
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
            itemCount: vehiculos.length,
            itemBuilder: (context, index) {
              final vehiculo = vehiculos[index];
              final estado = _extraerEstado(vehiculo.coche ?? '');
              final sucursal = _extraerSucursal(vehiculo.coche ?? '');
              final vehiculoInfo = _extraerVehiculo(vehiculo.coche ?? '');
              final enUso = estado.toLowerCase().contains('uso');

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                color: enUso ? Colors.orange.withOpacity(0.1) : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vehículo #${vehiculo.idCocheSol}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          _buildEstadoChip(estado, colorScheme),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Sucursal:', sucursal),
                      _buildInfoRow('Vehículo:', vehiculoInfo),
                      if (enUso)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange[700], size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Vehículo actualmente en uso',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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
      case 'disponible':
        chipColor = Colors.green;
        break;
      case 'uso':
        chipColor = Colors.orange;
        break;
      case 'mantenimiento':
        chipColor = Colors.red;
        break;
      default:
        chipColor = colorScheme.primary;
    }

    return Chip(
      label: Text(
        estado.toUpperCase(),
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
            width: 80,
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
