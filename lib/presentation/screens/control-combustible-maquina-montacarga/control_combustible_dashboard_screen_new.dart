import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/movimiento_entity.dart';

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
    // Cargar datos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSaldosActuales();
    });
  }

  void _cargarSaldosActuales() {
    ref
        .read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .cargarSaldosActuales();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      controlCombustibleMaquinaMontacargaNotifierProvider,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Dashboard - Saldos Actuales',
          style: ResponsiveUtilsBosque.getTitleStyle(context),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _cargarSaldosActuales,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _cargarSaldosActuales();
        },
        child: _buildBody(context, state, colorScheme, isDesktop),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RegistroState state,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    if (state.saldosStatus == FetchStatus.loading) {
      return _buildLoadingWidget();
    }

    if (state.saldosStatus == FetchStatus.error) {
      return _buildErrorWidget(colorScheme);
    }

    final saldos = state.saldosActuales;

    if (saldos.isEmpty) {
      return _buildEmptyWidget(colorScheme);
    }

    return _buildDashboardContent(saldos, colorScheme, isDesktop);
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando saldos actuales...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar los datos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta actualizar nuevamente',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarSaldosActuales,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos de saldos disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Actualiza para cargar la información',
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarSaldosActuales,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    List<MovimientoEntity> saldos,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    // Agrupar por sucursal
    final saldosPorSucursal = <String, List<MovimientoEntity>>{};
    for (final saldo in saldos) {
      final sucursal = saldo.nombreSucursal;
      if (!saldosPorSucursal.containsKey(sucursal)) {
        saldosPorSucursal[sucursal] = [];
      }
      saldosPorSucursal[sucursal]!.add(saldo);
    }

    return Column(
      children: [
        // Header con estadísticas generales
        _buildStatsHeader(saldos, saldosPorSucursal, colorScheme, isDesktop),

        // Contenido principal
        Expanded(
          child:
              isDesktop
                  ? _buildDesktopLayout(saldosPorSucursal, colorScheme)
                  : _buildMobileLayout(saldosPorSucursal, colorScheme),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(
    List<MovimientoEntity> saldos,
    Map<String, List<MovimientoEntity>> saldosPorSucursal,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    final totalSucursales = saldosPorSucursal.keys.length;
    final totalTipos = saldos.map((s) => s.tipo).toSet().length;
    final totalSaldo = saldos.fold<double>(0, (sum, s) => sum + s.valorSaldo);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          isDesktop
              ? Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Sucursales',
                      totalSucursales.toString(),
                      Icons.location_on,
                      colorScheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Tipos de Combustible',
                      totalTipos.toString(),
                      Icons.local_gas_station,
                      colorScheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Saldo Total',
                      '${totalSaldo.toStringAsFixed(1)} L',
                      Icons.inventory,
                      colorScheme,
                    ),
                  ),
                ],
              )
              : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Sucursales',
                          totalSucursales.toString(),
                          Icons.location_on,
                          colorScheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Tipos',
                          totalTipos.toString(),
                          Icons.local_gas_station,
                          colorScheme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Saldo Total',
                    '${totalSaldo.toStringAsFixed(1)} L',
                    Icons.inventory,
                    colorScheme,
                  ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    Map<String, List<MovimientoEntity>> saldosPorSucursal,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: saldosPorSucursal.keys.length,
        itemBuilder: (context, index) {
          final sucursal = saldosPorSucursal.keys.elementAt(index);
          final saldos = saldosPorSucursal[sucursal]!;
          return _buildSucursalCard(sucursal, saldos, colorScheme, true);
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    Map<String, List<MovimientoEntity>> saldosPorSucursal,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: saldosPorSucursal.keys.length,
      itemBuilder: (context, index) {
        final sucursal = saldosPorSucursal.keys.elementAt(index);
        final saldos = saldosPorSucursal[sucursal]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildSucursalCard(sucursal, saldos, colorScheme, false),
        );
      },
    );
  }

  Widget _buildSucursalCard(
    String sucursal,
    List<MovimientoEntity> saldos,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    final totalSaldo = saldos.fold<double>(0, (sum, s) => sum + s.valorSaldo);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la sucursal
            Row(
              children: [
                Icon(Icons.location_on, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sucursal,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${totalSaldo.toStringAsFixed(1)} L',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lista de combustibles
            ...saldos.map((saldo) => _buildCombustibleItem(saldo, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildCombustibleItem(
    MovimientoEntity saldo,
    ColorScheme colorScheme,
  ) {
    final icon = _getCombustibleIcon(saldo.tipo);
    final color = _getCombustibleColor(saldo.tipo);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saldo.tipo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (saldo.fechaMovimientoString.isNotEmpty)
                  Text(
                    'Último mov: ${saldo.fechaMovimientoString}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${saldo.valorSaldo.toStringAsFixed(1)} L',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getSaldoColor(saldo.valorSaldo, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCombustibleIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'gasolina':
        return Icons.local_gas_station;
      case 'diesel':
        return Icons.oil_barrel;
      case 'garrafa':
        return Icons.propane_tank;
      default:
        return Icons.inventory_2;
    }
  }

  Color _getCombustibleColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'gasolina':
        return Colors.green;
      case 'diesel':
        return Colors.blue;
      case 'garrafa':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getSaldoColor(double saldo, ColorScheme colorScheme) {
    if (saldo <= 0) {
      return Colors.red;
    } else if (saldo < 20) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
