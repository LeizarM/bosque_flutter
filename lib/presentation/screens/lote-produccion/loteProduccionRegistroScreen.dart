import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bosque_flutter/core/state/lote_produccion_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/domain/entities/lote_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/maquina_produccion_entity.dart';
import 'package:bosque_flutter/domain/entities/material_ingreso_entity.dart';
import 'package:bosque_flutter/domain/entities/material_salida_entity.dart';
import 'package:bosque_flutter/domain/entities/merma_entity.dart';

class LoteProduccionRegistroScreen extends ConsumerStatefulWidget {
  const LoteProduccionRegistroScreen({super.key});

  @override
  ConsumerState<LoteProduccionRegistroScreen> createState() =>
      _LoteProduccionRegistroScreenState();
}

class _LoteProduccionRegistroScreenState
    extends ConsumerState<LoteProduccionRegistroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _obsCtrl = TextEditingController();

  final _fmt = DateFormat('dd/MM/yyyy');
  final _numFmt = NumberFormat('#,##0.00', 'es_BO');

  int _audUsuario = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  String _fmtNum(double v) => _numFmt.format(v);

  // â”€â”€ DatePicker sin locale (evita el error de MaterialLocalizations) â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _pickDate(BuildContext ctx) async {
    final notifier = ref.read(
      loteProduccionRegistroProvider(_audUsuario).notifier,
    );
    final st = ref.read(loteProduccionRegistroProvider(_audUsuario));
    final now = DateTime.now();
    final firstDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 30));
    final picked = await showDatePicker(
      context: ctx,
      initialDate: st.fecha,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null) notifier.setFecha(picked);
  }

  /// Valida el formulario y muestra el diálogo de vista previa.
  void _mostrarVistaPrevia() {
    final st = ref.read(loteProduccionRegistroProvider(_audUsuario));
    final errores = <String>[];

    // — Cabecera ——————————————————————————————————————————
    if (st.idMaSeleccionada == null) {
      errores.add('• Seleccione una máquina.');
    }
    if (st.codEmpresaSeleccionada == null) {
      errores.add('• Seleccione una empresa.');
    }
    if (st.numLote <= 0) {
      errores.add(
        '• El número de lote no fue asignado (seleccione la máquina).',
      );
    }
    if (st.hraInicioCorte.length < 4) {
      errores.add('• Ingrese la Hora Inicio Corte (formato HH:mm).');
    }
    if (st.hraInicio.length < 4) {
      errores.add('• Ingrese la Hora Inicio (formato HH:mm).');
    }
    if (st.hraFin.length < 4) {
      errores.add('• Ingrese la Hora Fin (formato HH:mm).');
    }

    // — Tablas ————————————————————————————————————————————
    final ing = st.filasIngresoIncompletas;
    if (ing.isNotEmpty) {
      errores.add(
        '• Tabla Ingreso: ${ing.length == 1 ? "la fila" : "las filas"} '
        '${ing.join(", ")} ${ing.length == 1 ? "está incompleta" : "están incompletas"} '
        '(Peso KG y Balanza son obligatorios).',
      );
    }
    final sal = st.filasSalidaIncompletas;
    if (sal.isNotEmpty) {
      errores.add(
        '• Tabla Salida: ${sal.length == 1 ? "la fila" : "las filas"} '
        '${sal.join(", ")} ${sal.length == 1 ? "está incompleta" : "están incompletas"} '
        '(Peso Resma, Peso Paleta y Cant. Resma son obligatorios).',
      );
    }
    final mer = st.filasMermaIncompletas;
    if (mer.isNotEmpty) {
      errores.add(
        '• Tabla Merma: ${mer.length == 1 ? "la fila" : "las filas"} '
        '${mer.join(", ")} ${mer.length == 1 ? "está incompleta" : "están incompletas"} '
        '(Artículo y Peso son obligatorios).',
      );
    }

    if (errores.isNotEmpty) {
      showDialog<void>(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
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
                      'Corrija los siguientes errores antes de continuar:',
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Entendido'),
                ),
              ],
            ),
      );
      return;
    }

    // — Mostrar vista previa ——————————————————————————————
    showDialog<void>(
      context: context,
      builder:
          (_) => _PreviewDialog(
            st: st,
            fmtNum: _fmtNum,
            fmt: _fmt,
            onGuardar: _guardar,
          ),
    );
  }

  Future<void> _guardar() async {
    final notifier = ref.read(
      loteProduccionRegistroProvider(_audUsuario).notifier,
    );
    final ok = await notifier.guardarTodo();
    if (!mounted) return;
    final st = ref.read(loteProduccionRegistroProvider(_audUsuario));
    final mensaje =
        ok
            ? (st.successMessage ?? 'Lote guardado correctamente')
            : (st.errorMessage ?? 'Error al guardar');
    if (ok) notifier.resetState();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: ok ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    _audUsuario = user?.codUsuario ?? 0;

    // Mostrar diálogo cuando el artículo de salida de la orden no existe en el sistema
    ref.listen<
      LoteProduccionRegistroState
    >(loteProduccionRegistroProvider(_audUsuario), (prev, next) {
      if (next.salidaArticuloErrorCodigo != null &&
          prev?.salidaArticuloErrorCodigo != next.salidaArticuloErrorCodigo) {
        final cod = next.salidaArticuloErrorCodigo!;
        final mensaje =
            cod.isEmpty
                ? 'La orden de fabricación seleccionada no tiene un artículo de salida registrado en el sistema.'
                : 'El artículo de salida con código "$cod" no existe registrado en el sistema.';
        showDialog<void>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                icon: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 40,
                ),
                title: const Text('Artículo de salida no encontrado'),
                content: Text(mensaje),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
        );
        // No llamamos clearSalidaError() para que el chip y el aviso
        // permanezcan visibles hasta que el usuario seleccione otra orden.
      }
    });

    final st = ref.watch(loteProduccionRegistroProvider(_audUsuario));
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    // Sincronizar controlador de observaciones
    if (_obsCtrl.text != st.obs) {
      _obsCtrl.value = TextEditingValue(
        text: st.obs,
        selection: TextSelection.collapsed(offset: st.obs.length),
      );
    }

    if (st.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Lote de Producción'),
        actions: [
          if (st.isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: _mostrarVistaPrevia,
              icon: const Icon(Icons.preview_rounded, size: 18),
              label: const Text('Vista Previa'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Limpiar formulario',
            icon: const Icon(Icons.refresh_rounded),
            onPressed:
                () =>
                    ref
                        .read(
                          loteProduccionRegistroProvider(_audUsuario).notifier,
                        )
                        .resetState(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final padding = isMobile ? 12.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCabecera(st, maxWidth),
                    const SizedBox(height: 16),
                    _buildTablas(st, isMobile),
                    const SizedBox(height: 16),
                    _buildTotales(st, isMobile),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCabecera(LoteProduccionRegistroState st, double maxWidth) {
    final notifier = ref.read(
      loteProduccionRegistroProvider(_audUsuario).notifier,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = maxWidth < 600;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título sección con paso
            _SectionHeader(
              step: 1,
              icon: Icons.assignment_rounded,
              label: 'Datos del Lote',
            ),
            const SizedBox(height: 12),

            // Fila 1: Máquina – Nro Lote – Año
            isMobile
                ? Column(
                  children: [
                    _dropdownMaquina(st, notifier),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _LoteInfoField(
                            label: 'Nro Lote',
                            value: st.numLote > 0 ? st.numLote.toString() : '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LoteInfoField(
                            label: 'Año',
                            value: st.anio > 0 ? st.anio.toString() : '',
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                : Row(
                  children: [
                    Expanded(flex: 3, child: _dropdownMaquina(st, notifier)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LoteInfoField(
                        label: 'Nro Lote',
                        value: st.numLote > 0 ? st.numLote.toString() : '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LoteInfoField(
                        label: 'Año',
                        value: st.anio > 0 ? st.anio.toString() : '',
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 12),

            // Fila 2: Empresa –   Orden
            isMobile
                ? Column(
                  children: [
                    _dropdownEmpresa(st, notifier),
                    const SizedBox(height: 12),
                    _dropdownOrden(st, notifier),
                  ],
                )
                : Row(
                  children: [
                    Expanded(child: _dropdownEmpresa(st, notifier)),
                    const SizedBox(width: 12),
                    Expanded(child: _dropdownOrden(st, notifier)),
                  ],
                ),
            const SizedBox(height: 12),

            // Fila 3: Fecha – Horas
            isMobile
                ? Column(
                  children: [
                    _datePicker(st),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _HoraField(
                            label: 'Hora Inicio Corte',
                            value: st.hraInicioCorte,
                            onChanged: notifier.setHraInicioCorte,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HoraField(
                            label: 'Hora Inicio',
                            value: st.hraInicio,
                            onChanged: notifier.setHraInicio,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _HoraField(
                      label: 'Hora Fin',
                      value: st.hraFin,
                      onChanged: notifier.setHraFin,
                    ),
                  ],
                )
                : Row(
                  children: [
                    SizedBox(width: 180, child: _datePicker(st)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HoraField(
                        label: 'Hora Inicio Corte',
                        value: st.hraInicioCorte,
                        onChanged: notifier.setHraInicioCorte,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HoraField(
                        label: 'Hora Inicio',
                        value: st.hraInicio,
                        onChanged: notifier.setHraInicio,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HoraField(
                        label: 'Hora Fin',
                        value: st.hraFin,
                        onChanged: notifier.setHraFin,
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 12),

            // Observaciones
            TextFormField(
              controller: _obsCtrl,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  Icons.notes_rounded,
                  color: colorScheme.primary,
                ),
              ),
              maxLines: isMobile ? 2 : 1,
              onChanged: notifier.setObs,
            ),

            // Chips de artículos seleccionados vía orden
            if (st.articuloIngreso != null || st.articuloSalida != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (st.articuloIngreso != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: _ArtChip(
                        tipo: 'Ingreso',
                        codArticulo: st.articuloIngreso!.codArticulo,
                        descripcion: st.articuloIngreso!.articulo,
                        color: colorScheme.primaryContainer,
                        iconColor: colorScheme.primary,
                      ),
                    ),
                  if (st.articuloSalida != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: _ArtChip(
                        tipo: 'Salida',
                        codArticulo: st.articuloSalida!.codArticulo,
                        descripcion: st.articuloSalida!.articulo,
                        color: colorScheme.secondaryContainer,
                        iconColor: colorScheme.secondary,
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

  // ── Helpers cabecera ───────────────────────────────────────────────────────

  Widget _dropdownMaquina(
    LoteProduccionRegistroState st,
    LoteProduccionRegistroNotifier notifier,
  ) {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Máquina *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.precision_manufacturing_rounded),
      ),
      value: st.idMaSeleccionada,
      isExpanded: true,
      items:
          st.lstMaquina
              .map(
                (m) => DropdownMenuItem(
                  value: m.idMa,
                  child: Text(
                    '${m.numero} - ${m.descripcion}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged: (v) {
        if (v != null) notifier.onMaquinaChange(v);
      },
    );
  }

  Widget _dropdownEmpresa(
    LoteProduccionRegistroState st,
    LoteProduccionRegistroNotifier notifier,
  ) {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Empresa *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business_rounded),
      ),
      value: st.codEmpresaSeleccionada,
      isExpanded: true,
      items:
          st.lstEmpresas
              .map(
                (e) => DropdownMenuItem(
                  value: e.codEmpresa,
                  child: Text(e.nombre, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged: (v) {
        if (v != null) notifier.onEmpresaChange(v);
      },
    );
  }

  Widget _dropdownOrden(
    LoteProduccionRegistroState st,
    LoteProduccionRegistroNotifier notifier,
  ) {
    return DropdownButtonFormField<LoteProduccionEntity>(
      decoration: const InputDecoration(
        labelText: 'Orden de Fabricación',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.receipt_long_rounded),
      ),
      value: st.ordenSeleccionada,
      isExpanded: true,
      items:
          st.lstDocNumOrdFab
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(
                    '${o.docNumOrdFab}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
      onChanged:
          st.lstDocNumOrdFab.isEmpty
              ? null
              : (v) {
                if (v != null) notifier.onDocNumChange(v);
              },
    );
  }

  Widget _LoteInfoField({required String label, required String value}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        suffixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
      child: Text(
        value.isEmpty ? '—' : value,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color:
              value.isEmpty
                  ? colorScheme.onSurfaceVariant.withOpacity(0.4)
                  : colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _datePicker(LoteProduccionRegistroState st) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _pickDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha *',
          border: const OutlineInputBorder(),
          prefixIcon: Icon(
            Icons.calendar_month_rounded,
            color: colorScheme.primary,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_fmt.format(st.fecha)),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Sección: Tablas ─────────────────────────────────────────────────────────

  Widget _buildTablas(LoteProduccionRegistroState st, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;
    final salidaError = st.salidaArticuloErrorCodigo != null;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Cabecera de la sección con paso
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _SectionHeader(
              step: 2,
              icon: Icons.inventory_2_rounded,
              label: 'Materiales de Producción',
            ),
          ),
          // Tab bar con colores de estado
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            tabs: [
              _buildTab(
                Icons.input_rounded,
                'Ingreso',
                st.lstIngreso.length,
                colorScheme.primaryContainer,
              ),
              _buildTab(
                Icons.output_rounded,
                'Salida',
                st.lstSalida.length,
                salidaError
                    ? colorScheme.errorContainer
                    : colorScheme.secondaryContainer,
                hasError: salidaError,
              ),
              _buildTab(
                Icons.delete_sweep_rounded,
                'Merma',
                st.lstMerma.length,
                colorScheme.errorContainer,
              ),
            ],
          ),
          const Divider(height: 1),
          SizedBox(
            height: isMobile ? 420 : 360,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTablaIngreso(st),
                _buildTablaSalida(st),
                _buildTablaMerma(st),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Tab _buildTab(
    IconData icon,
    String label,
    int count,
    Color badgeColor, {
    bool hasError = false,
  }) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                hasError
                    ? const Icon(Icons.warning_rounded, size: 13)
                    : Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // ── Tabla Ingreso ─────────────────────────────────────────────────────────

  Widget _buildTablaIngreso(LoteProduccionRegistroState st) {
    final notifier = ref.read(
      loteProduccionRegistroProvider(_audUsuario).notifier,
    );
    final disabled = !st.isTableIngresoEnabled;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: disabled,
        child: _TablaLayout(
          titulo:
              disabled
                  ? 'Artículo de ingreso definido por la Orden de Fabricación'
                  : 'Material de Ingreso  ·  ${st.articuloIngreso?.articulo ?? ""}',
          onAgregar: notifier.agregarFilaIngreso,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: st.lstIngreso.length,
            itemBuilder:
                (ctx, i) => _FilaIngreso(
                  key: ValueKey('ing_${st.lstIngreso[i].idMi}_$i'),
                  fila: st.lstIngreso[i],
                  index: i,
                  onUpdate: (u) => notifier.updateIngreso(i, u),
                  onDelete: () => notifier.eliminarFilaIngreso(i),
                ),
          ),
        ),
      ),
    );
  }

  // ── Tabla Salida ─────────────────────────────────────────────────────────

  Widget _buildTablaSalida(LoteProduccionRegistroState st) {
    final notifier = ref.read(
      loteProduccionRegistroProvider(_audUsuario).notifier,
    );
    final hasError = st.salidaArticuloErrorCodigo != null;
    final disabled = !st.isTableSalidaEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    // Estado de error: artículo no encontrado
    if (hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
            child: Row(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  color: colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item de Salida no Encontrado',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.error,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 52,
                      color: colorScheme.error.withOpacity(0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Item de Salida no Encontrado',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'El artículo de salida vinculado a esta orden no está '
                      'registrado en el sistema. Seleccione otra orden de fabricación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final titulo =
        disabled
            ? 'Artículo de salida definido por la Orden de Fabricación'
            : 'Material de Salida ·  ${st.articuloSalida?.articulo ?? ""}';

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header (mismo estilo que _TablaLayout) ─────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: notifier.agregarFilaSalida,
                    icon: const Icon(Icons.add_circle_rounded, size: 18),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            // ── Info: UTM · Cant. Estimada Resmas · Hojas/Resma editable ───
            if (!disabled) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          const TextSpan(
                            text: 'UTM: ',
                            style: TextStyle(fontSize: 13),
                          ),
                          TextSpan(
                            text: _fmtNum(st.articuloSalida?.utm ?? 0),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          const TextSpan(
                            text: 'Cant. Est. Resmas: ',
                            style: TextStyle(fontSize: 13),
                          ),
                          TextSpan(
                            text: _fmtNum(st.cantEstimadaResma),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: _CantHjsField(
                        value: st.cantHjs,
                        onChanged: notifier.setCantHjs,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 1),
            // ── Filas ───────────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: st.lstSalida.length,
                itemBuilder:
                    (ctx, i) => _FilaSalida(
                      key: ValueKey('sal_${st.lstSalida[i].idMs}_$i'),
                      fila: st.lstSalida[i],
                      index: i,
                      onUpdate: (u) => notifier.updateSalida(i, u),
                      onResmaChange: (c) => notifier.updateSalidaResma(i, c),
                      onDelete: () => notifier.eliminarFilaSalida(i),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tabla Merma ─────────────────────────────────────────────────────────

  Widget _buildTablaMerma(LoteProduccionRegistroState st) {
    final notifier = ref.read(
      loteProduccionRegistroProvider(_audUsuario).notifier,
    );
    // Filtrar solo artículos de merma
    final artMerma =
        st.lstArticulos
            .where(
              (a) =>
                  a.articulo.toLowerCase().contains('merma') ||
                  a.codArticulo.toLowerCase().contains('merma'),
            )
            .toList();

    return _TablaLayout(
      titulo: 'Merma',
      onAgregar: notifier.agregarFilaMerma,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        itemCount: st.lstMerma.length,
        itemBuilder:
            (ctx, i) => _FilaMerma(
              key: ValueKey('mer_${st.lstMerma[i].idMe}_$i'),
              fila: st.lstMerma[i],
              articulosMerma: artMerma,
              index: i,
              onUpdate: (u) => notifier.updateMerma(i, u),
              onSelectArticulo: (a) => notifier.seleccionarArticuloMerma(i, a),
              onDelete: () => notifier.eliminarFilaMerma(i),
            ),
      ),
    );
  }

  // ── Sección: Totales ───────────────────────────────────────────────────────

  Widget _buildTotales(LoteProduccionRegistroState st, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      color: colorScheme.surfaceVariant.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              step: 3,
              icon: Icons.summarize_rounded,
              label: 'Resumen de Producción',
            ),
            const SizedBox(height: 12),
            // Ingreso
            _TotalGroup(
              title: 'Ingreso',
              items: [
                _TotalData('Total KG Ingreso', _fmtNum(st.totalIngresosKilos)),
                _TotalData('Total Balanza', _fmtNum(st.totalBalanza)),
              ],
              isMobile: isMobile,
            ),
            const SizedBox(height: 16),
            // Salida
            _TotalGroup(
              title: 'Salida',
              items: [
                _TotalData('Peso Resma', _fmtNum(st.totalPesoResma)),
                _TotalData('Peso Paleta', _fmtNum(st.totalPesoPaleta)),
                _TotalData('Peso Material', _fmtNum(st.totalPesoMaterial)),
                _TotalData('Cant. Resmas', st.totalCantidadResma.toString()),
                _TotalData('Cant. Hojas', _fmtNum(st.totalCantidadHojas)),
                _TotalData('Cant. Est. Resmas', _fmtNum(st.cantEstimadaResma)),
              ],
              isMobile: isMobile,
            ),
            const SizedBox(height: 16),
            // Merma y diferencias
            _TotalGroup(
              title: 'Merma y Diferencias',
              items: [
                _TotalData('Total Merma (KG)', _fmtNum(st.totalMerma)),
                _TotalData(
                  'Dif. Producción',
                  _fmtNum(st.difProduccion),
                  highlight: st.difProduccion < 0,
                ),
                _TotalData(
                  'Dif. Prod. Resma',
                  _fmtNum(st.difProduccionResma),
                  highlight: st.difProduccionResma < 0,
                ),
              ],
              isMobile: isMobile,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets de apoyo reutilizables ──────────────────────────────────────────

/// Cabecera de cada tabla con botón agregar fila
class _TablaLayout extends StatelessWidget {
  final String titulo;
  final VoidCallback onAgregar;
  final Widget child;

  const _TablaLayout({
    required this.titulo,
    required this.onAgregar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: onAgregar,
                icon: const Icon(Icons.add_circle_rounded, size: 18),
                label: const Text('Agregar'),
                style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}

/// Chip visual para artículo seleccionado
class _ArtChip extends StatelessWidget {
  final String tipo;
  final String codArticulo;
  final String descripcion;
  final Color color;
  final Color iconColor;

  const _ArtChip({
    required this.tipo,
    required this.codArticulo,
    required this.descripcion,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  descripcion,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de error para artículo de salida no encontrado
class _ArtChipError extends StatefulWidget {
  final String tipo;
  final String mensaje;

  const _ArtChipError({required this.tipo, required this.mensaje});

  @override
  State<_ArtChipError> createState() => _ArtChipErrorState();
}

class _ArtChipErrorState extends State<_ArtChipError> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.error.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: colorScheme.error),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tipo,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.mensaje,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cabecera de sección numerada con icono, paso y divider
class _SectionHeader extends StatelessWidget {
  final int step;
  final IconData icon;
  final String label;

  const _SectionHeader({
    required this.step,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Número de paso
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                step.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: colorScheme.primary, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 10),
      ],
    );
  }
}

/// Grupo de totales agrupados con título
class _TotalGroup extends StatelessWidget {
  final String title;
  final List<_TotalData> items;
  final bool isMobile;

  const _TotalGroup({
    required this.title,
    required this.items,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: isMobile ? 16 : 32,
          runSpacing: 10,
          children:
              items
                  .map(
                    (d) => _TotalItem(
                      label: d.label,
                      value: d.value,
                      highlight: d.highlight,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _TotalData {
  final String label;
  final String value;
  final bool highlight;
  const _TotalData(this.label, this.value, {this.highlight = false});
}

class _TotalItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TotalItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: highlight ? colorScheme.error : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ── Fila de Ingreso ─────────────────────────────────────────────────────────

class _FilaIngreso extends StatefulWidget {
  final MaterialIngresoEntity fila;
  final int index;
  final ValueChanged<MaterialIngresoEntity> onUpdate;
  final VoidCallback onDelete;

  const _FilaIngreso({
    super.key,
    required this.fila,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_FilaIngreso> createState() => _FilaIngresoState();
}

class _FilaIngresoState extends State<_FilaIngreso> {
  late final TextEditingController _pesoCtrl;
  late final TextEditingController _balanzaCtrl;
  late final TextEditingController _impCtrl;

  @override
  void initState() {
    super.initState();
    _pesoCtrl = TextEditingController(
      text: widget.fila.pesoKilos > 0 ? widget.fila.pesoKilos.toString() : '',
    );
    _balanzaCtrl = TextEditingController(
      text: widget.fila.balanza > 0 ? widget.fila.balanza.toString() : '',
    );
    _impCtrl = TextEditingController(text: widget.fila.numImportacion);
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _balanzaCtrl.dispose();
    _impCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FilaIngreso oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers only when the external value differs from what the user
    // has typed (e.g. a full form reset). Avoids clobbering "1." → "1.0".
    if (oldWidget.fila.pesoKilos != widget.fila.pesoKilos &&
        (double.tryParse(_pesoCtrl.text) ?? 0) != widget.fila.pesoKilos) {
      final t =
          widget.fila.pesoKilos > 0 ? widget.fila.pesoKilos.toString() : '';
      _pesoCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
    if (oldWidget.fila.balanza != widget.fila.balanza &&
        (double.tryParse(_balanzaCtrl.text) ?? 0) != widget.fila.balanza) {
      final t = widget.fila.balanza > 0 ? widget.fila.balanza.toString() : '';
      _balanzaCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
    if (oldWidget.fila.numImportacion != widget.fila.numImportacion &&
        _impCtrl.text != widget.fila.numImportacion) {
      _impCtrl.value = TextEditingValue(
        text: widget.fila.numImportacion,
        selection: TextSelection.collapsed(
          offset: widget.fila.numImportacion.length,
        ),
      );
    }
  }

  void _emit() => widget.onUpdate(
    MaterialIngresoEntity(
      idMi: widget.fila.idMi,
      idLp: widget.fila.idLp,
      codArticulo: widget.fila.codArticulo,
      descripcion: widget.fila.descripcion,
      pesoKilos: double.tryParse(_pesoCtrl.text) ?? 0,
      balanza: double.tryParse(_balanzaCtrl.text) ?? 0,
      numImportacion: _impCtrl.text,
      audUsuario: widget.fila.audUsuario,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${widget.index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fila.descripcion.isEmpty
                        ? 'Bobina'
                        : widget.fila.descripcion,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Eliminar fila',
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (ctx, c) {
                final compact = c.maxWidth < 400;
                if (compact) {
                  return Column(
                    children: [
                      _NumField(
                        label: 'Peso (KG)',
                        controller: _pesoCtrl,
                        onChanged: (_) => _emit(),
                      ),
                      const SizedBox(height: 8),
                      _NumField(
                        label: 'Balanza',
                        controller: _balanzaCtrl,
                        onChanged: (_) => _emit(),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label: 'Peso (KG)',
                        controller: _pesoCtrl,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumField(
                        label: 'Balanza',
                        controller: _balanzaCtrl,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de Salida ─────────────────────────────────────────────────────────

class _FilaSalida extends StatefulWidget {
  final MaterialSalidaEntity fila;
  final int index;
  final ValueChanged<MaterialSalidaEntity> onUpdate;
  final ValueChanged<int> onResmaChange;
  final VoidCallback onDelete;

  const _FilaSalida({
    super.key,
    required this.fila,
    required this.index,
    required this.onUpdate,
    required this.onResmaChange,
    required this.onDelete,
  });

  @override
  State<_FilaSalida> createState() => _FilaSalidaState();
}

class _FilaSalidaState extends State<_FilaSalida> {
  late final TextEditingController _pesoResmaCtrl;
  late final TextEditingController _pesoPaletaCtrl;
  late final TextEditingController _cantResmaCtrl;
  late final TextEditingController _cantHojasCtrl;

  @override
  void initState() {
    super.initState();
    _pesoResmaCtrl = TextEditingController(
      text: widget.fila.pesoResma > 0 ? widget.fila.pesoResma.toString() : '',
    );
    _pesoPaletaCtrl = TextEditingController(
      text: widget.fila.pesoPaleta > 0 ? widget.fila.pesoPaleta.toString() : '',
    );
    _cantResmaCtrl = TextEditingController(
      text:
          widget.fila.cantidadResma > 0
              ? widget.fila.cantidadResma.toString()
              : '',
    );
    _cantHojasCtrl = TextEditingController(
      text:
          widget.fila.cantidadHojas > 0
              ? widget.fila.cantidadHojas.toString()
              : '',
    );
  }

  @override
  void dispose() {
    _pesoResmaCtrl.dispose();
    _pesoPaletaCtrl.dispose();
    _cantResmaCtrl.dispose();
    _cantHojasCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FilaSalida oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fila.pesoResma != widget.fila.pesoResma &&
        (double.tryParse(_pesoResmaCtrl.text) ?? 0) != widget.fila.pesoResma) {
      final t =
          widget.fila.pesoResma > 0 ? widget.fila.pesoResma.toString() : '';
      _pesoResmaCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
    if (oldWidget.fila.pesoPaleta != widget.fila.pesoPaleta &&
        (double.tryParse(_pesoPaletaCtrl.text) ?? 0) !=
            widget.fila.pesoPaleta) {
      final t =
          widget.fila.pesoPaleta > 0 ? widget.fila.pesoPaleta.toString() : '';
      _pesoPaletaCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
    if (oldWidget.fila.cantidadResma != widget.fila.cantidadResma &&
        (int.tryParse(_cantResmaCtrl.text) ?? 0) != widget.fila.cantidadResma) {
      final t =
          widget.fila.cantidadResma > 0
              ? widget.fila.cantidadResma.toString()
              : '';
      _cantResmaCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
    // Sync cantHojas when it's updated externally (e.g. auto-calc from cantResma change)
    if (oldWidget.fila.cantidadHojas != widget.fila.cantidadHojas &&
        (int.tryParse(_cantHojasCtrl.text) ?? 0) != widget.fila.cantidadHojas) {
      final t =
          widget.fila.cantidadHojas > 0
              ? widget.fila.cantidadHojas.toString()
              : '';
      _cantHojasCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
  }

  void _emit() => widget.onUpdate(
    MaterialSalidaEntity(
      idMs: widget.fila.idMs,
      idLp: widget.fila.idLp,
      codArticulo: widget.fila.codArticulo,
      descripcion: widget.fila.descripcion,
      nroPaleta: widget.fila.nroPaleta,
      pesoResma: double.tryParse(_pesoResmaCtrl.text) ?? 0,
      pesoPaleta: double.tryParse(_pesoPaletaCtrl.text) ?? 0,
      pesoMaterial: 0,
      cantidadResma: int.tryParse(_cantResmaCtrl.text) ?? 0,
      cantidadHojas: int.tryParse(_cantHojasCtrl.text) ?? 0,
      audUsuario: widget.fila.audUsuario,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pesoMat = widget.fila.pesoResma - widget.fila.pesoPaleta;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Paleta #${widget.fila.nroPaleta}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fila.descripcion,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Peso material calculado inline
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mat: ${pesoMat.toStringAsFixed(2)} KG',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Eliminar fila',
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (ctx, c) {
                final compact = c.maxWidth < 420;
                if (compact) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _NumField(
                              label: 'Peso Resma',
                              controller: _pesoResmaCtrl,
                              onChanged: (_) => _emit(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NumField(
                              label: 'Peso Paleta',
                              controller: _pesoPaletaCtrl,
                              onChanged: (_) => _emit(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _ReadOnlyField(
                        label: 'Peso Material',
                        value: pesoMat.toStringAsFixed(2),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _NumField(
                              label: 'Cant. Resma',
                              controller: _cantResmaCtrl,
                              isInt: true,
                              onChanged:
                                  (v) => widget.onResmaChange(
                                    int.tryParse(v) ?? 0,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _NumField(
                              label: 'Cant. Hojas',
                              controller: _cantHojasCtrl,
                              isInt: true,
                              onChanged: (_) => _emit(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _NumField(
                        label: 'Peso Resma',
                        controller: _pesoResmaCtrl,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumField(
                        label: 'Peso Paleta',
                        controller: _pesoPaletaCtrl,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReadOnlyField(
                        label: 'Peso Material',
                        value: pesoMat.toStringAsFixed(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumField(
                        label: 'Cant. Resma',
                        controller: _cantResmaCtrl,
                        isInt: true,
                        onChanged:
                            (v) => widget.onResmaChange(int.tryParse(v) ?? 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NumField(
                        label: 'Cant. Hojas',
                        controller: _cantHojasCtrl,
                        isInt: true,
                        onChanged: (_) => _emit(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de Merma ─────────────────────────────────────────────────────────

class _FilaMerma extends StatefulWidget {
  final MermaEntity fila;
  final List<LoteProduccionEntity> articulosMerma; // ya filtrados
  final int index;
  final ValueChanged<MermaEntity> onUpdate;
  final ValueChanged<LoteProduccionEntity> onSelectArticulo;
  final VoidCallback onDelete;

  const _FilaMerma({
    super.key,
    required this.fila,
    required this.articulosMerma,
    required this.index,
    required this.onUpdate,
    required this.onSelectArticulo,
    required this.onDelete,
  });

  @override
  State<_FilaMerma> createState() => _FilaMermaState();
}

class _FilaMermaState extends State<_FilaMerma> {
  late final TextEditingController _pesoCtrl;

  @override
  void initState() {
    super.initState();
    _pesoCtrl = TextEditingController(
      text: widget.fila.peso > 0 ? widget.fila.peso.toString() : '',
    );
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FilaMerma oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fila.peso != widget.fila.peso &&
        (double.tryParse(_pesoCtrl.text) ?? 0) != widget.fila.peso) {
      final t = widget.fila.peso > 0 ? widget.fila.peso.toString() : '';
      _pesoCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Autocomplete<LoteProduccionEntity>(
                displayStringForOption:
                    (a) => '${a.codArticulo} - ${a.articulo}',
                initialValue:
                    widget.fila.codArticulo.isNotEmpty
                        ? TextEditingValue(
                          text:
                              '${widget.fila.codArticulo} - ${widget.fila.descripcion}',
                        )
                        : null,
                optionsBuilder: (value) {
                  if (value.text.isEmpty) return widget.articulosMerma;
                  final q = value.text.toLowerCase();
                  return widget.articulosMerma.where(
                    (a) =>
                        a.codArticulo.toLowerCase().contains(q) ||
                        a.articulo.toLowerCase().contains(q),
                  );
                },
                onSelected: widget.onSelectArticulo,
                fieldViewBuilder:
                    (ctx, ctrl, fn, _) => TextFormField(
                      controller: ctrl,
                      focusNode: fn,
                      decoration: const InputDecoration(
                        labelText: 'Artículo de Merma',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.search_rounded, size: 18),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: _NumField(
                label: 'Peso (KG)',
                controller: _pesoCtrl,
                onChanged:
                    (v) => widget.onUpdate(
                      MermaEntity(
                        idMe: widget.fila.idMe,
                        idLp: widget.fila.idLp,
                        codArticulo: widget.fila.codArticulo,
                        descripcion: widget.fila.descripcion,
                        peso: double.tryParse(v) ?? 0,
                        audUsuario: widget.fila.audUsuario,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.delete_rounded,
                color: Colors.red,
                size: 20,
              ),
              onPressed: widget.onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Eliminar fila',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Campo numérico ─────────────────────────────────────────────────────────

class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool isInt;

  const _NumField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      inputFormatters: [_NumericInputFormatter(isInt: isInt)],
      onChanged: onChanged,
    );
  }
}

// ── Campo solo lectura ─────────────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Text(value, style: const TextStyle(fontSize: 14)),
    );
  }
}

// ── Formatter numérico seguro ──────────────────────────────────────────────

/// Validates the entire field value instead of filtering character-by-character,
/// which avoids the cursor-position issues caused by anchored regexes inside
/// FilteringTextInputFormatter.allow.
class _NumericInputFormatter extends TextInputFormatter {
  final bool isInt;
  const _NumericInputFormatter({this.isInt = false});

  static final _intRe = RegExp(r'^\d*$');
  static final _decimalRe = RegExp(r'^\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final valid = isInt ? _intRe.hasMatch(text) : _decimalRe.hasMatch(text);
    return valid ? newValue : oldValue;
  }
}

// ── Campo de Hora (StatefulWidget) ─────────────────────────────────────────

/// Manages its own TextEditingController so that the parent widget never
/// modifies a controller directly inside build() — the anti-pattern that
/// caused cursor jumps when unrelated state changes triggered rebuilds.
class _HoraField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _HoraField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_HoraField> createState() => _HoraFieldState();
}

class _HoraFieldState extends State<_HoraField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_HoraField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync only on external changes (e.g. form reset) without touching cursor.
    if (oldWidget.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
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
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        hintText: '__:__',
        prefixIcon: const Icon(Icons.access_time_rounded),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [_HoraInputFormatter()],
      onChanged: widget.onChanged,
    );
  }
}

// ── Formatter auto-colon para hora HH:mm ──────────────────────────────────

class _HoraInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Solo conservar dígitos
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    // Limitar a 4 dígitos (HHmm)
    final raw = digits.length > 4 ? digits.substring(0, 4) : digits;
    // Formatear como HH:mm
    final String formatted;
    if (raw.length <= 2) {
      formatted = raw;
    } else {
      formatted = '${raw.substring(0, 2)}:${raw.substring(2)}';
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Campo editable Hojas/Resma ─────────────────────────────────────────────

/// Editable "HJS NNN" field equivalent to Angular's p-inputNumber cantHjsSalida.
/// Manages its own controller and syncs on external value changes (e.g. article reset).
class _CantHjsField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _CantHjsField({required this.value, required this.onChanged});

  @override
  State<_CantHjsField> createState() => _CantHjsFieldState();
}

class _CantHjsFieldState extends State<_CantHjsField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value > 0 ? widget.value.toString() : '',
    );
  }

  @override
  void didUpdateWidget(_CantHjsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        (int.tryParse(_ctrl.text) ?? 0) != widget.value) {
      final t = widget.value > 0 ? widget.value.toString() : '';
      _ctrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
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
      decoration: const InputDecoration(
        labelText: 'Hojas/Resma',
        prefixText: 'HJS ',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [_NumericInputFormatter(isInt: true)],
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null && parsed > 0) widget.onChanged(parsed);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista Previa del Lote antes de guardar
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewDialog extends StatelessWidget {
  final LoteProduccionRegistroState st;
  final String Function(double) fmtNum;
  final DateFormat fmt;
  final Future<void> Function() onGuardar;

  const _PreviewDialog({
    required this.st,
    required this.fmtNum,
    required this.fmt,
    required this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maquina =
        st.lstMaquina.where((m) => m.idMa == st.idMaSeleccionada).firstOrNull;
    final empresa =
        st.lstEmpresas
            .where((e) => e.codEmpresa == st.codEmpresaSeleccionada)
            .firstOrNull;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.preview_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vista Previa — Lote ${st.numLote} / ${st.anio}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      context,
                      'Cabecera',
                      Icons.info_outline_rounded,
                    ),
                    _buildCabecera(context, maquina, empresa),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      context,
                      'Ingreso (${st.lstIngreso.length} filas)',
                      Icons.input_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _buildTablaIngreso(context),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      context,
                      'Salida (${st.lstSalida.length} filas)',
                      Icons.output_rounded,
                      color: Colors.teal.shade700,
                    ),
                    _buildTablaSalida(context),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      context,
                      'Merma (${st.lstMerma.length} filas)',
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    _buildTablaMerma(context),
                    const SizedBox(height: 16),
                    _buildResumen(context),
                  ],
                ),
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Corregir'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _confirmarGuardar(context),
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Guardar Lote'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de diseño ────────────────────────────────────────────────────

  Widget _sectionTitle(
    BuildContext context,
    String label,
    IconData icon, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: c.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            '$label:',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    ),
  );

  // ── Secciones de contenido ───────────────────────────────────────────────

  Widget _buildCabecera(
    BuildContext context,
    MaquinaProduccionEntity? maquina,
    EmpresaEntity? empresa,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Máquina', maquina?.descripcion ?? '—'),
            _infoRow('Empresa', empresa?.nombre ?? '—'),
            _infoRow(
              'Orden fabricación',
              st.ordenSeleccionada != null
                  ? '${st.ordenSeleccionada!.docNumOrdFab}'
                      '${st.ordenSeleccionada!.datoArt.trim().isNotEmpty ? '  ·  ${st.ordenSeleccionada!.datoArt.trim()}' : ''}'
                  : '—',
            ),
            _infoRow('Nro Lote / Año', '${st.numLote} / ${st.anio}'),
            if (st.numCorte > 0)
              _infoRow('Nro Corte / Año', '${st.numCorte} / ${st.anioCorte}'),
            _infoRow('Fecha', fmt.format(st.fecha)),
            _infoRow('Hora Inicio Corte', st.hraInicioCorte),
            _infoRow('Hora Inicio', st.hraInicio),
            _infoRow('Hora Fin', st.hraFin),
            if (st.obs.isNotEmpty) _infoRow('Observaciones', st.obs),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaIngreso(BuildContext context) {
    const textS = TextStyle(fontSize: 12);
    const hsWhite = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    const bd = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (st.articuloIngreso != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Artículo: ${st.articuloIngreso!.codArticulo} – ${st.articuloIngreso!.datoArt}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(30),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: colorScheme.primary),
                  children: [
                    _cell('#', hsWhite),
                    _cell('Descripción', hsWhite),
                    _cell('Peso KG', hsWhite, right: true),
                    _cell('Balanza', hsWhite, right: true),
                  ],
                ),
                ...st.lstIngreso.asMap().entries.map(
                  (e) => TableRow(
                    decoration:
                        e.key.isOdd
                            ? BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                            )
                            : null,
                    children: [
                      _cell('${e.key + 1}', textS),
                      _cell(e.value.descripcion, textS),
                      _cell(fmtNum(e.value.pesoKilos), textS, right: true),
                      _cell(fmtNum(e.value.balanza), textS, right: true),
                    ],
                  ),
                ),
                TableRow(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                  ),
                  children: [
                    _cell('', bd),
                    _cell('TOTAL', bd),
                    _cell(fmtNum(st.totalIngresosKilos), bd, right: true),
                    _cell(fmtNum(st.totalBalanza), bd, right: true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaSalida(BuildContext context) {
    const textS = TextStyle(fontSize: 12);
    const hsWhite = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    const bd = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
    final colorScheme = Theme.of(context).colorScheme;
    final utm = st.articuloSalida?.utm ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (st.articuloSalida != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Artículo: ${st.articuloSalida!.codArticulo} – ${st.articuloSalida!.datoArt}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Wrap(
                spacing: 20,
                children: [
                  Text('UTM: $utm', style: const TextStyle(fontSize: 12)),
                  Text(
                    'HJS/Resma: ${st.cantHjs}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Cant. Est. Resmas: ${fmtNum(st.cantEstimadaResma)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(26),
                1: FixedColumnWidth(36),
                2: FlexColumnWidth(1.4),
                3: FlexColumnWidth(1.4),
                4: FlexColumnWidth(1.4),
                5: FlexColumnWidth(1),
                6: FlexColumnWidth(1),
              },
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.teal.shade700),
                  children: [
                    _cell('#', hsWhite),
                    _cell('Pal.', hsWhite, right: true),
                    _cell('P. Resma', hsWhite, right: true),
                    _cell('P. Paleta', hsWhite, right: true),
                    _cell('P. Mat.', hsWhite, right: true),
                    _cell('C.Resma', hsWhite, right: true),
                    _cell('C.Hojas', hsWhite, right: true),
                  ],
                ),
                ...st.lstSalida.asMap().entries.map(
                  (e) => TableRow(
                    decoration:
                        e.key.isOdd
                            ? BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                            )
                            : null,
                    children: [
                      _cell('${e.key + 1}', textS),
                      _cell('${e.value.nroPaleta}', textS, right: true),
                      _cell(fmtNum(e.value.pesoResma), textS, right: true),
                      _cell(fmtNum(e.value.pesoPaleta), textS, right: true),
                      _cell(
                        fmtNum(e.value.pesoResma - e.value.pesoPaleta),
                        textS,
                        right: true,
                      ),
                      _cell('${e.value.cantidadResma}', textS, right: true),
                      _cell('${e.value.cantidadHojas}', textS, right: true),
                    ],
                  ),
                ),
                TableRow(
                  decoration: BoxDecoration(color: Colors.teal.shade50),
                  children: [
                    _cell('', bd),
                    _cell('', bd),
                    _cell(fmtNum(st.totalPesoResma), bd, right: true),
                    _cell(fmtNum(st.totalPesoPaleta), bd, right: true),
                    _cell(fmtNum(st.totalPesoMaterial), bd, right: true),
                    _cell('${st.totalCantidadResma}', bd, right: true),
                    _cell(fmtNum(st.totalCantidadHojas), bd, right: true),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaMerma(BuildContext context) {
    const textS = TextStyle(fontSize: 12);
    const hsWhite = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    const bd = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FixedColumnWidth(70),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.grey.shade300, width: 0.5),
          children: [
            TableRow(
              decoration: BoxDecoration(color: colorScheme.error),
              children: [
                _cell('#', hsWhite),
                _cell('Código', hsWhite),
                _cell('Descripción', hsWhite),
                _cell('Peso KG', hsWhite, right: true),
              ],
            ),
            ...st.lstMerma.asMap().entries.map(
              (e) => TableRow(
                decoration:
                    e.key.isOdd
                        ? BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                        )
                        : null,
                children: [
                  _cell('${e.key + 1}', textS),
                  _cell(e.value.codArticulo, textS),
                  _cell(e.value.descripcion, textS),
                  _cell(fmtNum(e.value.peso), textS, right: true),
                ],
              ),
            ),
            TableRow(
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.4),
              ),
              children: [
                _cell('', bd),
                _cell('', bd),
                _cell('TOTAL', bd),
                _cell(fmtNum(st.totalMerma), bd, right: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final difKg = st.difProduccion;
    final difKgGood = difKg.abs() <= 1.0;
    final difResma = st.difProduccionResma;
    final difResmaGood = difResma.abs() < 1;

    Widget metricTile(
      String label,
      String value, {
      Color? valueColor,
      Color? bgColor,
    }) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor ?? cs.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? cs.onSurface,
            ),
          ),
        ],
      ),
    );

    return Card(
      color: cs.surfaceContainerHighest.withOpacity(0.45),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_rounded, size: 15, color: cs.primary),
                const SizedBox(width: 5),
                Text(
                  'Resumen de producción',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                metricTile('Total Ingreso KG', fmtNum(st.totalIngresosKilos)),
                metricTile('Total Balanza KG', fmtNum(st.totalBalanza)),
                metricTile('Peso Material KG', fmtNum(st.totalPesoMaterial)),
                metricTile('Total Merma KG', fmtNum(st.totalMerma)),
                metricTile('Cant. Resmas', '${st.totalCantidadResma}'),
                metricTile('Cant. Hojas', fmtNum(st.totalCantidadHojas)),
                metricTile('Cant. Est. Resmas', fmtNum(st.cantEstimadaResma)),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                metricTile(
                  'Dif. Producción KG',
                  fmtNum(difKg),
                  valueColor:
                      difKgGood ? Colors.green[700] : Colors.orange[800],
                  bgColor:
                      difKgGood ? Colors.green.shade50 : Colors.orange.shade50,
                ),
                metricTile(
                  'Dif. Cant. Resma',
                  difResma.toStringAsFixed(2),
                  valueColor:
                      difResmaGood ? Colors.green[700] : Colors.orange[800],
                  bgColor:
                      difResmaGood
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, TextStyle style, {bool right = false}) => Padding(
    padding: const EdgeInsets.all(4),
    child: Text(
      text,
      style: style,
      textAlign: right ? TextAlign.right : TextAlign.left,
    ),
  );

  // ── Confirmación final ───────────────────────────────────────────────────

  Future<void> _confirmarGuardar(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            icon: const Icon(
              Icons.save_alt_rounded,
              color: Colors.blue,
              size: 40,
            ),
            title: const Text('¿Confirmar guardado?'),
            content: const Text(
              'Se registrará el lote de producción con los datos revisados. '
              'Esta acción no se puede deshacer fácilmente.',
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Sí, guardar'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      if (context.mounted) Navigator.pop(context); // cierra la vista previa
      await onGuardar();
    }
  }
}
