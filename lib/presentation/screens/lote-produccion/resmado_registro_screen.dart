// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/core/state/resmado_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen principal
// ─────────────────────────────────────────────────────────────────────────────

class ResmadoRegistroScreen extends ConsumerStatefulWidget {
  const ResmadoRegistroScreen({super.key});

  @override
  ConsumerState<ResmadoRegistroScreen> createState() =>
      _ResmadoRegistroScreenState();
}

class _ResmadoRegistroScreenState extends ConsumerState<ResmadoRegistroScreen> {
  final _fmt = DateFormat('dd/MM/yyyy');

  int _audUsuario = 0;
  int _codEmpleado = 0;

  ResmadoParams get _params => (
    audUsuario: _audUsuario,
    codEmpleado: _codEmpleado,
  );

  // ── DatePicker ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final notifier = ref.read(resmadoRegistroProvider(_params).notifier);
    final st = ref.read(resmadoRegistroProvider(_params));
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: st.fecha,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) notifier.setFecha(picked);
  }

  // ── Validación + confirm ─────────────────────────────────────────────────

  void _intentarRegistrar() {
    final st = ref.read(resmadoRegistroProvider(_params));
    final errores = <String>[];

    if (st.codEmpresaSeleccionada == null)
      errores.add('• Seleccione una empresa.');
    if (st.ordenSeleccionada == null)
      errores.add('• Seleccione una orden de fabricación.');
    if (st.idGrupoSeleccionado == null) errores.add('• Seleccione un grupo.');
    if (!_horaValida(st.hraInicio))
      errores.add('• Ingrese Hora Inicio en formato HH:mm.');
    if (!_horaValida(st.hraFin))
      errores.add('• Ingrese Hora Fin en formato HH:mm.');
    if (st.detalles.isEmpty)
      errores.add('• Agregue al menos un artículo al detalle.');

    if (errores.isNotEmpty) {
      showDialog<void>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 40,
              ),
              title: const Text('Formulario incompleto'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Corrija los siguientes errores:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...errores.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(e, style: const TextStyle(height: 1.4)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ],
            ),
      );
      return;
    }

    _mostrarConfirmacion();
  }

  void _mostrarConfirmacion() {
    final st = ref.read(resmadoRegistroProvider(_params));
    final empresa = st.lstEmpresas.firstWhere(
      (e) => e.codEmpresa == st.codEmpresaSeleccionada,
    );
    final grupo = st.lstGrupos.firstWhere(
      (g) => g.idGrupo == st.idGrupoSeleccionado,
    );

    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.task_alt, color: Colors.green),
                SizedBox(width: 8),
                Text('Confirmar Registro'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoRow('Empresa', empresa.nombre),
                  _infoRow(
                    'Orden Fab.',
                    '${st.ordenSeleccionada!.docNumOrdFab}',
                  ),
                  _infoRow('Grupo', grupo.grupo),
                  _infoRow('Fecha', _fmt.format(st.fecha)),
                  _infoRow('Hora Inicio', st.hraInicio),
                  _infoRow('Hora Fin', st.hraFin),
                  _infoRow('Total Resmas', '${st.total}'),
                  _infoRow('Items en Detalle', '${st.detalles.length}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _registrar();
                },
                icon: const Icon(Icons.save),
                label: const Text('Registrar'),
              ),
            ],
          ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Future<void> _registrar() async {
    final notifier = ref.read(resmadoRegistroProvider(_params).notifier);
    final ok = await notifier.registrar();
    if (!mounted) return;
    final st = ref.read(resmadoRegistroProvider(_params));
    final mensaje =
        ok
            ? (st.successMessage ?? 'Registrado correctamente')
            : (st.errorMessage ?? 'Error al registrar');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: ok ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
    if (ok) notifier.resetState();
  }

  // ── Diálogo artículos ────────────────────────────────────────────────────

  Future<void> _abrirSelectorArticulos() async {
    final st = ref.read(resmadoRegistroProvider(_params));
    final seleccionados = await showDialog<List<LoteProduccionEntity>>(
      context: context,
      builder: (ctx) => _ArticuloPickerDialog(articulos: st.lstArticulos),
    );
    if (seleccionados == null || seleccionados.isEmpty) return;

    final notifier = ref.read(resmadoRegistroProvider(_params).notifier);
    final duplicados = notifier.agregarArticulos(seleccionados);

    if (!mounted) return;
    if (duplicados.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Los siguientes artículos ya existen en el detalle: ${duplicados.join(', ')}',
          ),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _horaValida(String h) {
    if (h.length < 5) return false;
    final regex = RegExp(r'^\d{2}:\d{2}$');
    return regex.hasMatch(h);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _audUsuario = user?.codUsuario ?? 0;
    _codEmpleado = user?.codEmpleado ?? 0;

    final st = ref.watch(resmadoRegistroProvider(_params));
    final isMobile = ResponsiveUtilsBosque.isMobile(context);
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final hPad = ResponsiveUtilsBosque.getHorizontalPadding(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Resmado'),
        centerTitle: false,
        actions: [
          if (st.isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _intentarRegistrar,
                icon: const Icon(Icons.save),
                label: const Text('Registrar'),
              ),
            ),
        ],
      ),
      body:
          st.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
                child:
                    isDesktop
                        ? _bodyDesktop(st, colorScheme)
                        : _bodyMobile(st, colorScheme, isMobile),
              ),
    );
  }

  // ── Layout Desktop (2 columnas) ────────────────────────────────────────────

  Widget _bodyDesktop(ResmadoRegistroState st, ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: Formulario cabecera
        Expanded(
          flex: 4,
          child: _CabeceraCard(
            st: st,
            fmt: _fmt,
            onPickDate: _pickDate,
            params: _params,
          ),
        ),
        const SizedBox(width: 16),
        // Columna derecha: Tabla de detalle
        Expanded(
          flex: 6,
          child: _DetalleCard(
            st: st,
            params: _params,
            onAgregarArticulos: _abrirSelectorArticulos,
          ),
        ),
      ],
    );
  }

  // ── Layout Mobile / Tablet (1 columna) ────────────────────────────────────

  Widget _bodyMobile(ResmadoRegistroState st, ColorScheme cs, bool isMobile) {
    return Column(
      children: [
        _CabeceraCard(
          st: st,
          fmt: _fmt,
          onPickDate: _pickDate,
          params: _params,
        ),
        const SizedBox(height: 16),
        _DetalleCard(
          st: st,
          params: _params,
          onAgregarArticulos: _abrirSelectorArticulos,
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Cabecera
// ─────────────────────────────────────────────────────────────────────────────

class _CabeceraCard extends ConsumerWidget {
  final ResmadoRegistroState st;
  final DateFormat fmt;
  final VoidCallback onPickDate;
  final ResmadoParams params;

  const _CabeceraCard({
    required this.st,
    required this.fmt,
    required this.onPickDate,
    required this.params,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(resmadoRegistroProvider(params).notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Datos del Resmado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Fecha
            _LabelField(
              label: 'Fecha *',
              child: InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  child: Text(fmt.format(st.fecha)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Empresa
            _LabelField(
              label: 'Empresa *',
              child: DropdownButtonFormField<int>(
                value: st.codEmpresaSeleccionada,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Seleccione empresa',
                ),
                items:
                    st.lstEmpresas
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.codEmpresa,
                            child: Text(
                              e.nombre,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => notifier.setEmpresa(v),
              ),
            ),
            const SizedBox(height: 16),

            // DocNum
            _LabelField(
              label: 'Orden de Fabricación *',
              child: DropdownButtonFormField<int>(
                value: st.ordenSeleccionada?.docNumOrdFab,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText:
                      st.codEmpresaSeleccionada == null
                          ? 'Seleccione empresa primero'
                          : (st.lstDocNums.isEmpty
                              ? 'Sin órdenes disponibles'
                              : 'Seleccione orden'),
                ),
                items:
                    st.lstDocNums
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.docNumOrdFab,
                            child: Text(
                              'Ord. ${d.docNumOrdFab}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged:
                    st.codEmpresaSeleccionada == null
                        ? null
                        : (v) {
                          if (v == null) return;
                          final orden = st.lstDocNums.firstWhere(
                            (d) => d.docNumOrdFab == v,
                          );
                          notifier.setOrden(orden);
                        },
              ),
            ),
            const SizedBox(height: 16),

            // Grupo
            _LabelField(
              label: 'Grupo *',
              child: DropdownButtonFormField<int>(
                value: st.idGrupoSeleccionado,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Seleccione grupo',
                ),
                items:
                    st.lstGrupos
                        .map(
                          (g) => DropdownMenuItem(
                            value: g.idGrupo,
                            child: Text(
                              g.grupo,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => notifier.setGrupo(v),
              ),
            ),
            const SizedBox(height: 16),

            // Horas
            Row(
              children: [
                Expanded(
                  child: _LabelField(
                    label: 'Hora Inicio *',
                    child: _HoraField(
                      initial: st.hraInicio,
                      onChanged: notifier.setHraInicio,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LabelField(
                    label: 'Hora Fin *',
                    child: _HoraField(
                      initial: st.hraFin,
                      onChanged: notifier.setHraFin,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Total (solo lectura)
            _LabelField(
              label: 'Total Resmas',
              child: InputDecorator(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  '${st.total}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Tabla de Detalle
// ─────────────────────────────────────────────────────────────────────────────

class _DetalleCard extends ConsumerWidget {
  final ResmadoRegistroState st;
  final ResmadoParams params;
  final VoidCallback onAgregarArticulos;

  const _DetalleCard({
    required this.st,
    required this.params,
    required this.onAgregarArticulos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(resmadoRegistroProvider(params).notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado + botón agregar
            Row(
              children: [
                Icon(Icons.list_alt_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detalle de Artículos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAgregarArticulos,
                  icon: const Icon(Icons.add),
                  label:
                      isMobile
                          ? const Text('Agregar')
                          : const Text('Agregar Artículos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Tabla / lista
            if (st.detalles.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 56,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin artículos aún',
                        style: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Presione "Agregar Artículos" para comenzar',
                        style: TextStyle(
                          color: colorScheme.outline,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              isMobile
                  ? _listaMovil(st, notifier, colorScheme)
                  : _tablaDesktop(st, notifier, colorScheme, context),

            // Footer: Total
            if (st.detalles.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL RESMAS:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Chip(
                    label: Text(
                      '${st.total}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                        fontSize: 16,
                      ),
                    ),
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Desktop: DataTable
  Widget _tablaDesktop(
    ResmadoRegistroState st,
    ResmadoRegistroNotifier notifier,
    ColorScheme cs,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(
          cs.primaryContainer.withOpacity(0.4),
        ),
        columns: const [
          DataColumn(label: Text('Cód. Artículo')),
          DataColumn(label: Text('Descripción')),
          DataColumn(label: Text('Cant. Resma'), numeric: true),
          DataColumn(label: Text('')),
        ],
        rows: List.generate(st.detalles.length, (i) {
          final det = st.detalles[i];
          return DataRow(
            cells: [
              DataCell(
                Text(
                  det.codArticulo,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(det.descripcion, overflow: TextOverflow.ellipsis),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 80,
                  child: _CantidadField(
                    value: det.cantResma,
                    onChanged: (v) => notifier.actualizarCantidad(i, v),
                  ),
                ),
              ),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Eliminar',
                  onPressed: () => notifier.eliminarDetalle(i),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Mobile: Lista de tarjetas
  Widget _listaMovil(
    ResmadoRegistroState st,
    ResmadoRegistroNotifier notifier,
    ColorScheme cs,
  ) {
    return Column(
      children: List.generate(st.detalles.length, (i) {
        final det = st.detalles[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: cs.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        det.codArticulo,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        det.descripcion,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: _CantidadField(
                    value: det.cantResma,
                    onChanged: (v) => notifier.actualizarCantidad(i, v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => notifier.eliminarDetalle(i),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget: Diálogo Selector de Artículos
// ─────────────────────────────────────────────────────────────────────────────

class _ArticuloPickerDialog extends StatefulWidget {
  final List<LoteProduccionEntity> articulos;
  const _ArticuloPickerDialog({required this.articulos});

  @override
  State<_ArticuloPickerDialog> createState() => _ArticuloPickerDialogState();
}

class _ArticuloPickerDialogState extends State<_ArticuloPickerDialog> {
  final _searchCtrl = TextEditingController();
  final _selected = <LoteProduccionEntity>[];
  List<LoteProduccionEntity> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _filtrados = widget.articulos;
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados =
          widget.articulos
              .where(
                (a) =>
                    a.codArticulo.toLowerCase().contains(q) ||
                    a.articulo.toLowerCase().contains(q) ||
                    a.datoArt.toLowerCase().contains(q),
              )
              .toList();
    });
  }

  void _toggle(LoteProduccionEntity art) {
    setState(() {
      if (_selected.any((s) => s.codArticulo == art.codArticulo)) {
        _selected.removeWhere((s) => s.codArticulo == art.codArticulo);
      } else {
        _selected.add(art);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenW = MediaQuery.of(context).size.width;
    final dialogW = screenW > 700 ? 620.0 : screenW * 0.95;

    return Dialog(
      child: SizedBox(
        width: dialogW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: colorScheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seleccionar Artículos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    Chip(
                      label: Text(
                        '${_selected.length} sel.',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: colorScheme.primary,
                    ),
                ],
              ),
            ),

            // Buscador
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por código o descripción…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                  suffixIcon:
                      _searchCtrl.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              _filtrar();
                            },
                          )
                          : null,
                ),
              ),
            ),

            // Lista
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child:
                  _filtrados.isEmpty
                      ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('Sin resultados'),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) {
                          final art = _filtrados[i];
                          final isSelected = _selected.any(
                            (s) => s.codArticulo == art.codArticulo,
                          );
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => _toggle(art),
                            title: Text(
                              art.codArticulo,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                            subtitle: Text(
                              art.datoArt.isNotEmpty
                                  ? art.datoArt
                                  : art.articulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            dense: true,
                            activeColor: colorScheme.primary,
                          );
                        },
                      ),
            ),

            // Acciones
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed:
                        _selected.isEmpty
                            ? null
                            : () => Navigator.pop(context, _selected),
                    icon: const Icon(Icons.check),
                    label: Text('Agregar (${_selected.length})'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de apoyo
// ─────────────────────────────────────────────────────────────────────────────

class _LabelField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabelField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Campo de texto para hora con formato HH:mm automático.
class _HoraField extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onChanged;
  const _HoraField({required this.initial, required this.onChanged});

  @override
  State<_HoraField> createState() => _HoraFieldState();
}

class _HoraFieldState extends State<_HoraField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(_HoraField old) {
    super.didUpdateWidget(old);
    if (old.initial != widget.initial && widget.initial != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.initial,
        selection: TextSelection.collapsed(offset: widget.initial.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _HoraFormatter(),
      ],
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'HH:mm',
        suffixIcon: Icon(Icons.access_time),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Formatter que agrega ":" automáticamente (p.ej. "0800" → "08:00").
class _HoraFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(':', '');
    if (digits.length > 4) {
      return oldValue;
    }
    String result = digits;
    if (digits.length >= 3) {
      result = '${digits.substring(0, 2)}:${digits.substring(2)}';
    }
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// Campo numérico para cantResma.
class _CantidadField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _CantidadField({required this.value, required this.onChanged});

  @override
  State<_CantidadField> createState() => _CantidadFieldState();
}

class _CantidadFieldState extends State<_CantidadField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(_CantidadField old) {
    super.didUpdateWidget(old);
    final valStr = '${widget.value}';
    if (old.value != widget.value && _ctrl.text != valStr) {
      _ctrl.value = TextEditingValue(
        text: valStr,
        selection: TextSelection.collapsed(offset: valStr.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      ),
      onChanged: (v) {
        final n = int.tryParse(v) ?? 1;
        widget.onChanged(n);
      },
    );
  }
}
