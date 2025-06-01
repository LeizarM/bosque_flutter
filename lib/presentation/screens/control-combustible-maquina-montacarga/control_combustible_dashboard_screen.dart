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
              // Solo movimientos recientes
              _buildRecentMovements(state, colorScheme),
            ],
          ),
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
            Text(
              'Movimientos Recientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
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
