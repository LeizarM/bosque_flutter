import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/control_combustible_maquina_montacarga_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/movimiento_entity.dart';

/// Identidad visual de un tipo de combustible.
///
/// El color identifica al tipo (categórico) y es independiente del color de
/// estado del saldo (bueno / bajo / sin stock). Mezclar ambos roles hacía que
/// "verde" significara a la vez "Gasolina" y "saldo sano".
class _FuelVisual {
  const _FuelVisual({
    required this.light,
    required this.dark,
    required this.icon,
    required this.unidad,
  });

  final Color light;
  final Color dark;
  final IconData icon;
  final String unidad;

  Color color(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Estado del saldo. Nunca se comunica sólo con color: siempre lleva ícono +
/// etiqueta, porque los tonos de estado no alcanzan 3:1 sobre fondo claro.
enum _StockStatus { sinStock, bajo, normal }

class ControlCombustibleDashboardScreen extends ConsumerStatefulWidget {
  const ControlCombustibleDashboardScreen({super.key});

  @override
  ConsumerState<ControlCombustibleDashboardScreen> createState() =>
      _ControlCombustibleDashboardScreenState();
}

class _ControlCombustibleDashboardScreenState
    extends ConsumerState<ControlCombustibleDashboardScreen> {
  bool _isStatsExpanded = true;

  // ---------------------------------------------------------------------------
  // Paleta categórica (validada para daltonismo en modo claro y oscuro).
  // El orden de los slots es el mecanismo de seguridad CVD: no reordenar sin
  // volver a validar.
  // ---------------------------------------------------------------------------
  static const List<_FuelVisual> _slots = [
    _FuelVisual(
      light: Color(0xFF2A78D6),
      dark: Color(0xFF3987E5),
      icon: Icons.local_gas_station,
      unidad: 'L',
    ),
    _FuelVisual(
      light: Color(0xFFEB6834),
      dark: Color(0xFFD95926),
      icon: Icons.oil_barrel,
      unidad: 'L',
    ),
    _FuelVisual(
      light: Color(0xFF1BAF7A),
      dark: Color(0xFF199E70),
      icon: Icons.propane_tank,
      unidad: 'U',
    ),
    _FuelVisual(
      light: Color(0xFFEDA100),
      dark: Color(0xFFC98500),
      icon: Icons.local_gas_station_outlined,
      unidad: 'L',
    ),
  ];

  /// Registro explícito por nombre normalizado. Cualquier tipo nuevo dado de
  /// alta en `tgas_tipo` cae al fallback determinista de abajo en vez de
  /// quedar en gris.
  static const Map<String, int> _slotPorTipo = {
    'gasolina': 0,
    'diesel': 1,
    'garrafa': 2,
    'gasolina particular': 3,
  };

  // Umbrales de saldo bajo. Son reglas de negocio: ajustar acá, no disperso.
  static const double _umbralBajoLitros = 20;
  static const double _umbralBajoUnidades = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSaldosActuales();
    });
  }

  void _cargarSaldosActuales() {
    ref
        .read(controlCombustibleMaquinaMontacargaNotifierProvider.notifier)
        .cargarSaldosActuales();
  }

  // ---------------------------------------------------------------------------
  // Mapeo tipo -> identidad visual
  // ---------------------------------------------------------------------------

  _FuelVisual _visual(String tipo) {
    final key = tipo.trim().toLowerCase();

    final exacto = _slotPorTipo[key];
    if (exacto != null) return _slots[exacto];

    // Tipo nuevo todavía sin slot asignado: se resuelve de forma determinista
    // a partir del nombre, así el mismo tipo conserva siempre el mismo color.
    var hash = 0;
    for (final code in key.codeUnits) {
      hash = (hash * 31 + code) & 0x7FFFFFFF;
    }
    final base = _slots[hash % _slots.length];

    // La unidad sí se puede inferir con confianza por el nombre.
    return _FuelVisual(
      light: base.light,
      dark: base.dark,
      icon: key.contains('garrafa') ? Icons.propane_tank : Icons.inventory_2,
      unidad: key.contains('garrafa') ? 'U' : 'L',
    );
  }

  _StockStatus _status(double saldo, String unidad) {
    if (saldo <= 0) return _StockStatus.sinStock;
    final umbral = unidad == 'U' ? _umbralBajoUnidades : _umbralBajoLitros;
    return saldo < umbral ? _StockStatus.bajo : _StockStatus.normal;
  }

  // Paleta de estado: fija, nunca tematizada, distinta de la categórica.
  static const Color _statusCritical = Color(0xFFD03B3B);
  static const Color _statusWarning = Color(0xFFFAB219);

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
    final saldosPorSucursal = <String, List<MovimientoEntity>>{};
    for (final saldo in saldos) {
      saldosPorSucursal.putIfAbsent(saldo.nombreSucursal, () => []).add(saldo);
    }

    // Orden estable: sucursales alfabéticas, y dentro de cada una los tipos
    // por nombre. Sin esto el orden depende del retorno del SP y las tarjetas
    // "bailan" entre refrescos.
    final sucursales = saldosPorSucursal.keys.toList()..sort();
    for (final lista in saldosPorSucursal.values) {
      lista.sort((a, b) => a.tipo.compareTo(b.tipo));
    }

    return Column(
      children: [
        _buildStatsHeader(saldos, colorScheme, isDesktop),
        Expanded(
          child: _buildSucursalesLayout(
            sucursales,
            saldosPorSucursal,
            colorScheme,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Totales por tipo
  // ---------------------------------------------------------------------------

  Widget _buildStatsHeader(
    List<MovimientoEntity> saldos,
    ColorScheme colorScheme,
    bool isDesktop,
  ) {
    final saldosPorTipo = <String, double>{};
    for (final saldo in saldos) {
      saldosPorTipo[saldo.tipo] =
          (saldosPorTipo[saldo.tipo] ?? 0) + saldo.valorSaldo;
    }

    // Alfabético, no por magnitud: el color sigue a la entidad, así que el
    // orden no debe cambiar cuando cambian los valores.
    final tipos =
        saldosPorTipo.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isStatsExpanded = !_isStatsExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    'Totales por Tipo de Combustible',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${tipos.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
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
          if (_isStatsExpanded) ...[
            const SizedBox(height: 8),
            // Los tiles se reparten el ancho disponible en partes iguales, en
            // vez de quedarse en un ancho fijo y dejar la derecha vacía.
            LayoutBuilder(
              builder: (context, constraints) {
                const separacion = 12.0;
                const anchoMinimo = 210.0;

                var columnas =
                    ((constraints.maxWidth + separacion) /
                            (anchoMinimo + separacion))
                        .floor();
                columnas = columnas.clamp(1, tipos.length);
                final ancho =
                    (constraints.maxWidth - separacion * (columnas - 1)) /
                    columnas;

                return Wrap(
                  spacing: separacion,
                  runSpacing: separacion,
                  children: [
                    for (final entry in tipos)
                      SizedBox(
                        width: ancho,
                        child: _buildTipoStatCard(
                          entry.key,
                          entry.value,
                          colorScheme,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoStatCard(
    String tipo,
    double total,
    ColorScheme colorScheme,
  ) {
    final visual = _visual(tipo);
    final color = visual.color(Theme.of(context).brightness);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Barra de identidad: el color va en la marca, no en el texto.
            Container(
              width: 4,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Icon(visual.icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tipo,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${total.toStringAsFixed(1)} ${visual.unidad}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Grilla de sucursales
  // ---------------------------------------------------------------------------

  /// Cuántas columnas usar. Entran las que permita el ancho (máximo 4), pero
  /// entre las que caben se prefiere el reparto que deje la última fila lo más
  /// completa posible: con 6 sucursales, 3+3 se ve parejo y 4+2 no.
  int _columnas(double ancho, int total) {
    const anchoMinimo = 300.0;
    const separacion = 12.0;

    var maximo = ((ancho + separacion) / (anchoMinimo + separacion)).floor();
    if (maximo < 1) maximo = 1;
    if (maximo > 4) maximo = 4;
    if (maximo > total) maximo = total;
    if (maximo <= 1) return 1;

    var mejor = maximo;
    var menorSobrante = (maximo - total % maximo) % maximo;
    for (var c = maximo - 1; c >= 2; c--) {
      final sobrante = (c - total % c) % c;
      if (sobrante < menorSobrante) {
        menorSobrante = sobrante;
        mejor = c;
      }
    }
    return mejor;
  }

  /// Grilla de sucursales, pareja por filas.
  ///
  /// Cada fila usa `IntrinsicHeight` + `stretch`: todas sus tarjetas comparten
  /// el alto de la más alta de esa fila. Así la grilla queda alineada sin fijar
  /// un alto global —que sobraba en las sucursales de un solo tipo— ni dejar
  /// los bordes irregulares de un masonry. El número de columnas sale del
  /// ancho real, con lo que el mismo código va de móvil (1 columna) a 4K.
  Widget _buildSucursalesLayout(
    List<String> sucursales,
    Map<String, List<MovimientoEntity>> saldosPorSucursal,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const separacion = 12.0;
        final columnas = _columnas(constraints.maxWidth, sucursales.length);

        if (columnas <= 1) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: sucursales.length,
            separatorBuilder: (_, __) => const SizedBox(height: separacion),
            itemBuilder: (context, index) {
              final sucursal = sucursales[index];
              return _buildSucursalCard(
                sucursal,
                saldosPorSucursal[sucursal]!,
                colorScheme,
              );
            },
          );
        }

        final filas = <List<String>>[];
        for (var i = 0; i < sucursales.length; i += columnas) {
          final fin =
              i + columnas < sucursales.length
                  ? i + columnas
                  : sucursales.length;
          filas.add(sucursales.sublist(i, fin));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: [
              for (var f = 0; f < filas.length; f++) ...[
                if (f > 0) const SizedBox(height: separacion),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < columnas; c++) ...[
                        if (c > 0) const SizedBox(width: separacion),
                        Expanded(
                          // Los huecos de la última fila se rellenan vacíos
                          // para que las columnas mantengan el mismo ancho.
                          child:
                              c < filas[f].length
                                  ? _buildSucursalCard(
                                    filas[f][c],
                                    saldosPorSucursal[filas[f][c]]!,
                                    colorScheme,
                                  )
                                  : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSucursalCard(
    String sucursal,
    List<MovimientoEntity> saldos,
    ColorScheme colorScheme,
  ) {
    // Cuántos tipos de esta sucursal están sin stock: se resume en el
    // encabezado para poder escanear la grilla sin leer cada fila.
    final sinStock = saldos.where((s) => s.valorSaldo <= 0).length;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sucursal,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sinStock > 0)
                  _StatusChip(
                    label: sinStock == 1 ? 'Sin stock' : '$sinStock sin stock',
                    color: _statusCritical,
                    icon: Icons.error_outline,
                  ),
              ],
            ),
            const SizedBox(height: 8),
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
    final visual = _visual(saldo.tipo);
    final color = visual.color(Theme.of(context).brightness);
    final unidad = visual.unidad;
    final estado = _status(saldo.valorSaldo, unidad);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(visual.icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  saldo.tipo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (saldo.fechaMovimientoString.isNotEmpty &&
                    saldo.fechaMovimientoString != 'N/A')
                  Text(
                    saldo.fechaMovimientoString,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // El valor va en tinta normal. El estado se comunica aparte, con
          // ícono + etiqueta, nunca sólo con color.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${saldo.valorSaldo.toStringAsFixed(1)} $unidad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: colorScheme.onSurface,
                ),
              ),
              if (estado != _StockStatus.normal)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _StatusChip(
                    label:
                        estado == _StockStatus.sinStock ? 'Sin stock' : 'Bajo',
                    color:
                        estado == _StockStatus.sinStock
                            ? _statusCritical
                            : _statusWarning,
                    icon:
                        estado == _StockStatus.sinStock
                            ? Icons.error_outline
                            : Icons.warning_amber_rounded,
                    dense: true,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Indicador de estado: color + ícono + texto. El color nunca va solo.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 5 : 7,
        vertical: dense ? 1 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 10 : 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 9 : 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
