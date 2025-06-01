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
    final fechaInicio = DateTime.now().subtract(const Duration(days: 7));
    final fechaFin = DateTime.now();
    
    ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .cargarReporteMovimientos(fechaInicio, fechaFin);
    ref.read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .cargarMaquinasMontacargas();
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
              // Header con saludo personalizado
              _buildWelcomeCard(user, colorScheme),
              const SizedBox(height: 24),
              
              // Cards de estadísticas
              _buildStatsGrid(state, colorScheme),
              const SizedBox(height: 24),
              
              // Últimos movimientos
              _buildRecentMovements(state, colorScheme),
              const SizedBox(height: 24),
              
              // Resumen por tipo de transacción
              _buildTransactionSummary(state, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, ColorScheme colorScheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_gas_station,
                  color: colorScheme.onPrimary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Bienvenido!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        user?.nombreCompleto ?? 'Usuario',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onPrimary.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Sistema de Control de Combustible para Máquinas y Vehículos',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(RegistroState state, ColorScheme colorScheme) {
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final movimientos = state.reporteMovimientos;
    
    // Calcular estadísticas
    final totalMovimientos = movimientos.length;
    final totalLitrosIngreso = movimientos.fold<double>(0, (sum, item) => sum + item.litrosIngreso);
    final totalLitrosSalida = movimientos.fold<double>(0, (sum, item) => sum + item.litrosSalida);
    final totalMaquinas = state.maquinasMontacarga.length;

    final stats = [
      {
        'title': 'Total Movimientos',
        'value': totalMovimientos.toString(),
        'subtitle': 'Últimos 7 días',
        'icon': Icons.swap_horiz,
        'color': Colors.blue,
      },
      {
        'title': 'Litros Ingreso',
        'value': '${totalLitrosIngreso.toStringAsFixed(1)}L',
        'subtitle': 'Combustible agregado',
        'icon': Icons.add_circle,
        'color': Colors.green,
      },
      {
        'title': 'Litros Salida',
        'value': '${totalLitrosSalida.toStringAsFixed(1)}L',
        'subtitle': 'Combustible usado',
        'icon': Icons.remove_circle,
        'color': Colors.orange,
      },
      {
        'title': 'Máquinas Activas',
        'value': totalMaquinas.toString(),
        'subtitle': 'En el sistema',
        'icon': Icons.precision_manufacturing,
        'color': Colors.purple,
      },
    ];

    if (isDesktop) {
      return Row(
        children: stats.map((stat) => 
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildStatCard(stat, colorScheme),
            ),
          ),
        ).toList(),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) => _buildStatCard(stats[index], colorScheme),
      );
    }
  }

  Widget _buildStatCard(Map<String, dynamic> stat, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  stat['icon'],
                  color: stat['color'],
                  size: 24,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat['icon'],
                    color: stat['color'],
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stat['value'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              stat['title'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              stat['subtitle'],
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMovements(RegistroState state, ColorScheme colorScheme) {
    final movimientos = state.reporteMovimientos.take(5).toList();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movimientos Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navegar a la pantalla completa de reportes
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.reporteStatus == FetchStatus.loading)
              const Center(child: CircularProgressIndicator())
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
                      DateFormat('dd/MM/yyyy HH:mm').format(movimiento.fecha),
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

  Widget _buildTransactionSummary(RegistroState state, ColorScheme colorScheme) {
    final movimientos = state.reporteMovimientos;
    
    // Agrupar por tipo de transacción
    final Map<String, int> tipoCount = {};
    final Map<String, double> tipoLitros = {};
    
    for (final mov in movimientos) {
      tipoCount[mov.tipoTransaccion] = (tipoCount[mov.tipoTransaccion] ?? 0) + 1;
      tipoLitros[mov.tipoTransaccion] = (tipoLitros[mov.tipoTransaccion] ?? 0) + mov.litrosIngreso;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen por Tipo de Transacción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (tipoCount.isEmpty)
              Center(
                child: Text(
                  'No hay datos disponibles',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              ...tipoCount.entries.map((entry) {
                final tipo = entry.key;
                final count = entry.value;
                final litros = tipoLitros[tipo] ?? 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      _buildTipoIcon(tipo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tipo,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '$count movimientos',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${litros.toStringAsFixed(1)}L',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getTipoColor(tipo),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
