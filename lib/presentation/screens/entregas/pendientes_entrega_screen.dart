import 'package:bosque_flutter/core/state/pendientes_entrega_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/pendiente_entrega_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PendientesEntregaScreen extends ConsumerStatefulWidget {
  const PendientesEntregaScreen({super.key});

  @override
  ConsumerState<PendientesEntregaScreen> createState() =>
      _PendientesEntregaScreenState();
}

class _PendientesEntregaScreenState
    extends ConsumerState<PendientesEntregaScreen> {
  String _searchText = '';
  String? _empresaFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendientesEntregaProvider.notifier).cargarPendientes();
    });
  }

  List<PendienteEntregaEntity> _filtrar(
    List<PendienteEntregaEntity> pendientes,
  ) {
    var lista = pendientes;
    if (_empresaFiltro != null) {
      lista = lista.where((p) => p.empresa == _empresaFiltro).toList();
    }
    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      lista =
          lista
              .where(
                (p) =>
                    p.cardName.toLowerCase().contains(q) ||
                    p.docNum.toLowerCase().contains(q) ||
                    p.vendedor.toLowerCase().contains(q) ||
                    p.direccionEntrega.toLowerCase().contains(q),
              )
              .toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendientesEntregaProvider);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final isTablet = ResponsiveUtilsBosque.isTablet(context);

    final empresas =
        state.pendientes.map((p) => p.empresa).toSet().toList()..sort();
    final filtrados = _filtrar(state.pendientes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pendientes de Entrega'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon:
                state.isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.refresh),
            onPressed:
                state.isLoading
                    ? null
                    : () =>
                        ref
                            .read(pendientesEntregaProvider.notifier)
                            .cargarPendientes(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(context, empresas, filtrados, isDesktop || isTablet),
          Expanded(
            child:
                state.isLoading && state.pendientes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null && state.pendientes.isEmpty
                    ? _buildError(context, state.error!)
                    : filtrados.isEmpty
                    ? const Center(child: Text('No hay registros pendientes'))
                    : (isDesktop || isTablet)
                    ? _buildTable(context, filtrados)
                    : _buildList(context, filtrados),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    List<String> empresas,
    List<PendienteEntregaEntity> filtrados,
    bool isWide,
  ) {
    final state = ref.watch(pendientesEntregaProvider);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
        vertical: 8,
      ),
      child:
          isWide
              ? Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 12),
                  SizedBox(width: 180, child: _buildEmpresaFilter(empresas)),
                  const SizedBox(width: 16),
                  Text(
                    '${filtrados.length} de ${state.pendientes.length} registros',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildEmpresaFilter(empresas)),
                      const SizedBox(width: 12),
                      Text(
                        '${filtrados.length} / ${state.pendientes.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Buscar por cliente, doc, vendedor...',
        prefixIcon: Icon(Icons.search),
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => setState(() => _searchText = v),
    );
  }

  Widget _buildEmpresaFilter(List<String> empresas) {
    return DropdownButtonFormField<String>(
      value: _empresaFiltro,
      isDense: true,
      decoration: const InputDecoration(
        labelText: 'Empresa',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Todas')),
        ...empresas.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: (v) => setState(() => _empresaFiltro = v),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Error al cargar datos',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                () =>
                    ref
                        .read(pendientesEntregaProvider.notifier)
                        .cargarPendientes(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // ─── Vista tabla (desktop / tablet) ─────────────────────────────────────────

  // Definición de columnas: (encabezado, flex, alinear derecha)
  static const _cols = [
    ('Empresa', 1, false),
    ('Doc. N°', 2, false),
    ('Serie', 2, false),
    ('Cliente', 4, false),
    ('Fecha', 2, false),
    ('Hora', 1, false),
    ('Vendedor', 3, false),
    ('Peso (kg)', 2, true),
    ('Cantidad', 2, true),
    ('Dirección', 4, false),
    ('Comentarios', 4, false),
  ];

  Widget _buildTable(BuildContext context, List<PendienteEntregaEntity> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: colorScheme.primary,
      fontSize: 13,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
        vertical: 8,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Container(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              child: _flexRow(
                _cols
                    .map(
                      (c) => (
                        flex: c.$2,
                        child: Text(c.$1, style: headerStyle),
                        right: c.$3,
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            // Filas
            ...items.asMap().entries.map(
              (e) =>
                  _buildFlexDataRow(context, e.value, e.key.isOdd, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  /// Fila genérica con celdas flex proporcionales
  Widget _flexRow(
    List<({int flex, Widget child, bool right})> cells, {
    Color? background,
  }) {
    return Container(
      color: background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children:
            cells
                .map(
                  (c) => Expanded(
                    flex: c.flex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Align(
                        alignment:
                            c.right
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: c.child,
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildFlexDataRow(
    BuildContext context,
    PendienteEntregaEntity p,
    bool isOdd,
    ColorScheme colorScheme,
  ) {
    final fechaFmt = DateFormat('dd/MM/yyyy').format(p.docDate);
    final weightFmt = NumberFormat('#,##0.00').format(p.weight);
    final cantFmt = NumberFormat('#,##0.##').format(p.cantidad);
    final direccion = p.direccionEntrega.replaceAll('\r', ' ').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _flexRow(
          [
            (flex: 1, child: _empresaChip(p.empresa), right: false),
            (
              flex: 2,
              child: Text(
                p.docNum,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              right: false,
            ),
            (
              flex: 2,
              child: Text(p.seriesName, overflow: TextOverflow.ellipsis),
              right: false,
            ),
            (
              flex: 4,
              child: Tooltip(
                message: p.cardName,
                child: Text(p.cardName, overflow: TextOverflow.ellipsis),
              ),
              right: false,
            ),
            (flex: 2, child: Text(fechaFmt), right: false),
            (flex: 1, child: Text(p.horaCreacion), right: false),
            (
              flex: 3,
              child: Text(p.vendedor, overflow: TextOverflow.ellipsis),
              right: false,
            ),
            (flex: 2, child: Text(weightFmt), right: true),
            (flex: 2, child: Text(cantFmt), right: true),
            (
              flex: 4,
              child:
                  direccion.isEmpty
                      ? const SizedBox.shrink()
                      : Tooltip(
                        message: direccion,
                        child: Text(direccion, overflow: TextOverflow.ellipsis),
                      ),
              right: false,
            ),
            (
              flex: 4,
              child:
                  p.comments.isEmpty
                      ? const SizedBox.shrink()
                      : Tooltip(
                        message: p.comments,
                        preferBelow: true,
                        child: Text(
                          p.comments,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              right: false,
            ),
          ],
          background:
              isOdd ? colorScheme.surfaceContainerLow : colorScheme.surface,
        ),
        const Divider(height: 1, thickness: 0.5),
      ],
    );
  }

  // ─── Vista lista (móvil) ─────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, List<PendienteEntregaEntity> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildCard(context, items[index]),
    );
  }

  Widget _buildCard(BuildContext context, PendienteEntregaEntity p) {
    final fechaFmt = DateFormat('dd/MM/yyyy').format(p.docDate);
    final weightFmt = NumberFormat('#,##0.00').format(p.weight);
    final cantFmt = NumberFormat('#,##0.##').format(p.cantidad);
    final direccion = p.direccionEntrega.replaceAll('\r', ' ').trim();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _empresaChip(p.empresa),
                const Spacer(),
                Text(
                  p.docNum,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text(
                  p.seriesName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(p.cardName, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$fechaFmt  ${p.horaCreacion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(p.vendedor, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.scale, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$weightFmt kg',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                const Icon(Icons.inventory_2, size: 14),
                const SizedBox(width: 4),
                Text(
                  '$cantFmt uds',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (direccion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      direccion,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (p.comments.isNotEmpty) ...[
              const SizedBox(height: 6),
              Tooltip(
                message: p.comments,
                preferBelow: true,
                child: GestureDetector(
                  onLongPress:
                      () => _showFullTextDialog(
                        context,
                        title: 'Comentarios',
                        text: p.comments,
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.comments,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullTextDialog(
    BuildContext context, {
    required String title,
    required String text,
  }) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(child: Text(text)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _empresaChip(String empresa) {
    final colors = {
      'ESP': Colors.blue,
      'IPX': Colors.teal,
      'PRODPAP': Colors.orange,
    };
    final color = colors[empresa] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        empresa,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
