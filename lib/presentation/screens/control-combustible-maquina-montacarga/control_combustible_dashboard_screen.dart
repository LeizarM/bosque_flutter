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
  bool _isStatsExpanded = true; // Estado para expandir/colapsar estadísticas

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
    // Agrupar y sumar por tipo de combustible
    final saldosPorTipo = <String, double>{};
    for (final saldo in saldos) {
      final tipo = saldo.tipo;
      saldosPorTipo[tipo] = (saldosPorTipo[tipo] ?? 0) + saldo.valorSaldo;
    }

    // Ordenar por cantidad descendente
    final tiposOrdenados =
        saldosPorTipo.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón de expandir/colapsar
          InkWell(
            onTap: () {
              setState(() {
                _isStatsExpanded = !_isStatsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Totales por Tipo de Combustible',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isStatsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          // Contenido expandible
          if (_isStatsExpanded) ...[
            const SizedBox(height: 12),
            isDesktop
                ? Row(
                  children:
                      tiposOrdenados
                          .map(
                            (entry) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: 8,
                                ), // Reducido de 16 a 8
                                child: _buildTipoStatCard(
                                  entry.key,
                                  '${entry.value.toStringAsFixed(1)} ${_getUnidadMedida(entry.key)}',
                                  _getCombustibleIcon(entry.key),
                                  _getCombustibleColor(entry.key),
                                  colorScheme,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                )
                : Column(
                  children:
                      tiposOrdenados
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildTipoStatCard(
                                entry.key,
                                '${entry.value.toStringAsFixed(1)} ${_getUnidadMedida(entry.key)}',
                                _getCombustibleIcon(entry.key),
                                _getCombustibleColor(entry.key),
                                colorScheme,
                              ),
                            ),
                          )
                          .toList(),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoStatCard(
    String tipo,
    String value,
    IconData icon,
    Color iconColor,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10), // Reducido de 12 a 10
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5), // Reducido de 6 a 5
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5), // Reducido de 6 a 5
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18, // Reducido de 20 a 18
                  ),
                ),
                const SizedBox(width: 6), // Reducido de 8 a 6
                Expanded(
                  child: Text(
                    tipo,
                    style: TextStyle(
                      fontSize: 13, // Aumentado de 12 a 13
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Reducido de 8 a 6
            Text(
              value,
              style: TextStyle(
                fontSize: 18, // Aumentado de 16 a 18
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
          crossAxisCount: 4, // Aumentado de 3 a 4 para cards más pequeños
          crossAxisSpacing: 8, // Reducido de 12 a 8
          mainAxisSpacing: 8, // Reducido de 12 a 8
          childAspectRatio:
              1.1, // Reducido de 1.3 a 1.1 para cards más compactos
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
    // Agrupar saldos por tipo para evitar sumar unidades incompatibles
    final saldosPorTipo = <String, double>{};
    for (final saldo in saldos) {
      final tipo = saldo.tipo;
      saldosPorTipo[tipo] = (saldosPorTipo[tipo] ?? 0) + saldo.valorSaldo;
    }

    // Crear texto de resumen para mostrar en lugar de total incorrecto
    final resumenTexto = saldosPorTipo.entries
        .map(
          (entry) =>
              '${entry.value.toStringAsFixed(1)} ${_getUnidadMedida(entry.key)} ${entry.key}',
        )
        .join(' • ');

    return Card(
      elevation: isDesktop ? 2 : 3, // Menor elevación en desktop
      child: Padding(
        padding: EdgeInsets.all(
          isDesktop ? 8 : 16,
        ), // Reducido de 12 a 8 en desktop para cards más pequeños
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la sucursal
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: colorScheme.primary,
                  size: isDesktop ? 16 : 20,
                ),
                SizedBox(width: isDesktop ? 4 : 8),
                Expanded(
                  child: Text(
                    sucursal,
                    style: TextStyle(
                      fontSize:
                          isDesktop
                              ? 16
                              : 16, // Aumentado de 14 a 16 en desktop
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 4 : 8,
                      vertical: isDesktop ? 1 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      resumenTexto.isNotEmpty ? resumenTexto : 'Sin saldos',
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 9
                                : 12, // Ligeramente reducido para que quepa
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isDesktop ? 6 : 12),

            // Lista de combustibles
            ...saldos.map(
              (saldo) => _buildCombustibleItem(saldo, colorScheme, isDesktop),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombustibleItem(
    MovimientoEntity saldo,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    final icon = _getCombustibleIcon(saldo.tipo);
    final color = _getCombustibleColor(saldo.tipo);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 3 : 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 4 : 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isDesktop ? 4 : 8),
            ),
            child: Icon(icon, color: color, size: isDesktop ? 12 : 16),
          ),
          SizedBox(width: isDesktop ? 6 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saldo.tipo,
                  style: TextStyle(
                    fontSize:
                        isDesktop ? 14 : 14, // Aumentado de 12 a 14 en desktop
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (saldo.fechaMovimientoString.isNotEmpty)
                  Text(
                    'Último mov: ${saldo.fechaMovimientoString}',
                    style: TextStyle(
                      fontSize:
                          isDesktop ? 10 : 11, // Aumentado de 9 a 10 en desktop
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${saldo.valorSaldo.toStringAsFixed(1)} ${_getUnidadMedida(saldo.tipo)}',
            style: TextStyle(
              fontSize: isDesktop ? 14 : 14, // Aumentado de 12 a 14 en desktop
              fontWeight: FontWeight.bold,
              color: _getSaldoColor(saldo.valorSaldo, colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  String _getUnidadMedida(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'garrafa':
        return 'U';
      default:
        return 'L';
    }
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
