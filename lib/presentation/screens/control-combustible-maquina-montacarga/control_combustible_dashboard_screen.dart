import 'package:bosque_flutter/domain/entities/control_combustible_maquina_montacarga_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:intl/intl.dart';

class ControlCombustibleDashboardScreen extends ConsumerStatefulWidget {
  const ControlCombustibleDashboardScreen({super.key});

  @override
  ConsumerState<ControlCombustibleDashboardScreen> createState() =>
      _ControlCombustibleDashboardScreenState();
}

class _ControlCombustibleDashboardScreenState
    extends ConsumerState<ControlCombustibleDashboardScreen> {

  @override
  void initState() {
    super.initState();
    // Cargar datos del dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosDashboard();
    });
  }

  void _cargarDatosDashboard() {
    ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .cargarBidonesPorSucursal();
    ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .cargarUltimosMovimientos();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(controlCombustibleMaquinaMontacargaNotifierProvider);
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Dashboard Control Combustible',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: ResponsiveUtilsBosque.isDesktop(context) ? 2 : 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosDashboard,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _cargarDatosDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saldos por sucursal
              _buildSaldosBidonesPorSucursal(state, colorScheme),
              const SizedBox(height: 24),
              
              // Solo movimientos recientes
              _buildRecentMovements(state, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaldosBidonesPorSucursal(RegistroState state, ColorScheme colorScheme) {
    final bidonesSucursal = state.bidonesSucursal;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_gas_station,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Saldo Bidones por Sucursal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.bidonesSucursalStatus == FetchStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.bidonesSucursalStatus == FetchStatus.error)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error al cargar saldos',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ),
              )
            else if (bidonesSucursal.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hay datos de saldos disponibles',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ResponsiveUtilsBosque.isDesktop(context)
                  ? _buildSaldosDesktopGrid(bidonesSucursal, colorScheme)
                  : _buildSaldosMobileList(bidonesSucursal, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSaldosDesktopGrid(List<ControlCombustibleMaquinaMontacargaEntity> bidonesSucursal, ColorScheme colorScheme) {
    // Ajustar para pantallas grandes y evitar overflow
    final screenWidth = MediaQuery.of(context).size.width;
    final maxCardWidth = 300.0;
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context) * 2 + 32; // Card padding
    final availableWidth = screenWidth - padding;
    
    int crossAxisCount = (availableWidth / maxCardWidth).floor();
    if (crossAxisCount < 2) crossAxisCount = 2;
    if (crossAxisCount > bidonesSucursal.length) crossAxisCount = bidonesSucursal.length;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2, // Reducido para evitar overflow
      ),
      itemCount: bidonesSucursal.length,
      itemBuilder: (context, index) {
        final bidon = bidonesSucursal[index];
        return _buildSaldoCard(bidon, colorScheme);
      },
    );
  }

  Widget _buildSaldosMobileList(List<ControlCombustibleMaquinaMontacargaEntity> bidonesSucursal, ColorScheme colorScheme) {
    return Column(
      children: bidonesSucursal.map((bidon) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSaldoCard(bidon, colorScheme),
        ),
      ).toList(),
    );
  }

  Widget _buildSaldoCard(ControlCombustibleMaquinaMontacargaEntity bidon, ColorScheme colorScheme) {
    final saldo = bidon.saldoLitros;
    final isNegative = saldo < 0;
    final isZero = saldo == 0;
    
    Color saldoColor;
    IconData saldoIcon;
    
    if (isNegative) {
      saldoColor = Colors.red;
      saldoIcon = Icons.trending_down;
    } else if (isZero) {
      saldoColor = Colors.orange;
      saldoIcon = Icons.remove_circle_outline;
    } else {
      saldoColor = Colors.green;
      saldoIcon = Icons.trending_up;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: saldoColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header con nombre de sucursal e icono
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  bidon.nombreSucursal,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: saldoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  saldoIcon,
                  color: saldoColor,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Información compacta de litros ingresados y fecha
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Total Litros Ingresados
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_gas_station,
                          color: Colors.blue,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Total Litros Ingresados:',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${bidon.litrosIngreso.toStringAsFixed(1)}L',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Fecha Última Carga
                if (bidon.fecha.year > 1900)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time,
                        color: colorScheme.onSurfaceVariant,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fecha Última Carga: ${DateFormat('dd/MM/yy').format(bidon.fecha)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Existencia actual (saldo)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Existencia',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${saldo.toStringAsFixed(1)}L',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: saldoColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: saldoColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: saldoColor.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  isNegative ? 'DÉFICIT' : isZero ? 'VACÍO' : 'OK',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMovements(RegistroState state, ColorScheme colorScheme) {
    final movimientos = state.ultimosMovimientos.take(5).toList();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Últimos Movimientos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (state.ultimosMovimientosStatus == FetchStatus.loading)
              const Center(child: CircularProgressIndicator())
            else if (state.ultimosMovimientosStatus == FetchStatus.error)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error al cargar movimientos',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ],
                ),
              )
            else if (movimientos.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No hay movimientos recientes',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: movimientos.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final movimiento = movimientos[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _buildTipoIcon(movimiento.tipoTransaccion),
                    title: Text(
                      '${movimiento.codigoOrigen} → ${movimiento.codigoDestino.isNotEmpty ? movimiento.codigoDestino : 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(movimiento.fecha),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${movimiento.litrosIngreso.toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          movimiento.tipoTransaccion,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getTipoColor(movimiento.tipoTransaccion),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoIcon(String tipo) {
    IconData icon;
    Color color;
    
    switch (tipo) {
      case 'INGRESO':
        icon = Icons.add_circle;
        color = Colors.green;
        break;
      case 'SALIDA':
        icon = Icons.remove_circle;
        color = Colors.orange;
        break;
      case 'TRASPASO':
        icon = Icons.swap_horiz;
        color = Colors.blue;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'INGRESO':
        return Colors.green;
      case 'SALIDA':
        return Colors.orange;
      case 'TRASPASO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
