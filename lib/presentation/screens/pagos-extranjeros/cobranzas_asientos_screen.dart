import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/data/repositories/pagos_extranjeros_impl.dart';
import 'package:bosque_flutter/domain/entities/asiento_entity.dart';
import 'package:bosque_flutter/domain/entities/transacciones_entity.dart';
import 'package:bosque_flutter/presentation/widgets/pagos-extranjeros/dialogo_operacion_tesoreria.dart';
import 'package:bosque_flutter/presentation/widgets/pagos-extranjeros/tpex_estado_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _nf = NumberFormat('#,##0.00', 'es_BO');
final _df = DateFormat('dd/MM/yyyy');

// Etiqueta de la "fuente": banco real, o "Tesorería" si la txn no tiene banco
// (operaciones USDT/Mercury/Devolución sin proveedor → codBanco NULL/0).
String _fuenteLabel(TransaccionesEntity t) => t.banco.isNotEmpty
    ? t.banco
    : (t.codBanco > 0 ? 'Banco #${t.codBanco}' : 'Tesorería');

// ═══════════════════════════════════════════════════════════════════════════
// Screen principal
// ═══════════════════════════════════════════════════════════════════════════

class CobranzasAsientosScreen extends ConsumerStatefulWidget {
  const CobranzasAsientosScreen({super.key});

  @override
  ConsumerState<CobranzasAsientosScreen> createState() =>
      _CobranzasAsientosScreenState();
}

class _CobranzasAsientosScreenState
    extends ConsumerState<CobranzasAsientosScreen> {
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  TransaccionesEntity? _seleccionada;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fechaInicio = DateTime(now.year, now.month, 1);
    _fechaFin = now;
  }

  ({DateTime fechaInicio, DateTime fechaFin, int codEmpresa}) get _params => (
    fechaInicio: _fechaInicio,
    fechaFin: _fechaFin,
    codEmpresa: ref.read(userProvider)?.codEmpresa ?? 0,
  );

  Future<void> _pickDate(BuildContext context, bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = picked;
        if (_fechaInicio.isAfter(_fechaFin)) _fechaFin = picked;
      } else {
        _fechaFin = picked;
        if (_fechaFin.isBefore(_fechaInicio)) _fechaInicio = picked;
      }
      _seleccionada = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);
    final asyncTxns = ref.watch(reporteTransaccionesFechasProvider(_params));

    final lista = _buildLista(cs, asyncTxns, isDesktop);

    if (isDesktop && _seleccionada != null) {
      return Row(
        children: [
          SizedBox(width: 440, child: lista),
          const VerticalDivider(width: 1),
          Expanded(
            child: _TransaccionAsientosPanel(
              txn: _seleccionada!,
              onClose: () => setState(() => _seleccionada = null),
              onConfirmada: () {
                // Quitar de la lista (invalidar provider)
                ref.invalidate(reporteTransaccionesFechasProvider(_params));
                setState(() => _seleccionada = null);
              },
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        lista,
        if (!isDesktop && _seleccionada != null)
          Expanded(
            child: _TransaccionAsientosPanel(
              txn: _seleccionada!,
              onClose: () => setState(() => _seleccionada = null),
              onConfirmada: () {
                ref.invalidate(reporteTransaccionesFechasProvider(_params));
                setState(() => _seleccionada = null);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildLista(
    ColorScheme cs,
    AsyncValue<List<TransaccionesEntity>> asyncTxns,
    bool isDesktop,
  ) {
    final headerAndList = Column(
      mainAxisSize: isDesktop ? MainAxisSize.max : MainAxisSize.min,
      children: [
        // Header + filtros de fecha
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          color: cs.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: cs.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cobranzas — Asientos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  // OPCIÓN B — alta de operaciones de tesorería (USDT/Mercury/
                  // Devolución) sin pasar por solicitud/cotización de proveedor.
                  FilledButton.tonalIcon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => DialogoOperacionTesoreria(
                        onGuardado: () => ref.invalidate(
                          reporteTransaccionesFechasProvider(_params),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tesorería'),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Actualizar',
                    onPressed: () {
                      ref.invalidate(
                        reporteTransaccionesFechasProvider(_params),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Filtros de fecha
              Row(
                children: [
                  Expanded(
                    child: _DateChip(
                      label: 'Desde',
                      fecha: _fechaInicio,
                      onTap: () => _pickDate(context, true),
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateChip(
                      label: 'Hasta',
                      fecha: _fechaFin,
                      onTap: () => _pickDate(context, false),
                      cs: cs,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Lista
        Expanded(
          child: asyncTxns.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Error: $e',
                      style: TextStyle(color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            data: (txns) {
              if (txns.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 64,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin transacciones en el período seleccionado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: txns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder:
                    (context, i) => _TxnCobranzaCard(
                      txn: txns[i],
                      cs: cs,
                      seleccionada:
                          _seleccionada?.idTransaccion == txns[i].idTransaccion,
                      onTap: () => setState(() => _seleccionada = txns[i]),
                    ),
              );
            },
          ),
        ),
      ],
    );

    if (isDesktop) return Expanded(child: headerAndList);
    return headerAndList;
  }
}

// ── Chip de fecha ─────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final DateTime fecha;
  final VoidCallback onTap;
  final ColorScheme cs;
  const _DateChip({
    required this.label,
    required this.fecha,
    required this.onTap,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    _df.format(fecha),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
}

// ── Card de transacción en lista ──────────────────────────────────────────

class _TxnCobranzaCard extends StatelessWidget {
  final TransaccionesEntity txn;
  final ColorScheme cs;
  final bool seleccionada;
  final VoidCallback onTap;
  const _TxnCobranzaCard({
    required this.txn,
    required this.cs,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color:
          seleccionada
              ? cs.primaryContainer.withValues(alpha: 0.3)
              : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color:
              seleccionada
                  ? cs.primary.withValues(alpha: 0.6)
                  : cs.outlineVariant.withValues(alpha: 0.4),
          width: seleccionada ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 18,
                  color: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Txn #${txn.idTransaccion}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      txn.idTransaccionOrigen != null
                          ? '↩ Devolución de Txn #${txn.idTransaccionOrigen}'
                          : (txn.proveedor.isNotEmpty
                              ? txn.proveedor
                              : (txn.cardCode.isNotEmpty
                                  ? txn.cardCode
                                  : 'Operación de tesorería')),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_fuenteLabel(txn)}  ·  ${_df.format(txn.fechaTransaccion)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _nf.format(txn.montoOrigen),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFeatures: tpexTabularFigures,
                    ),
                  ),
                  _EstadoBadgeCob(estado: txn.estado),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Panel de detalle: transacción + asientos + confirmar
// ═══════════════════════════════════════════════════════════════════════════

class _TransaccionAsientosPanel extends ConsumerWidget {
  final TransaccionesEntity txn;
  final VoidCallback onClose;
  final VoidCallback onConfirmada;

  const _TransaccionAsientosPanel({
    required this.txn,
    required this.onClose,
    required this.onConfirmada,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final asyncAsientos = ref.watch(
      asientosTransaccionProvider(txn.idTransaccion),
    );
    final asyncCuadre = ref.watch(cuadreAsientosProvider(txn.idTransaccion));

    return Column(
      children: [
        // Header del panel
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          color: cs.surface,
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Txn #${txn.idTransaccion}  ·  ${_fuenteLabel(txn)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (txn.idTransaccionOrigen != null)
                      Text(
                        '↩ Devolución de Txn #${txn.idTransaccionOrigen}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Resumen de transacción
        _TxnResumen(txn: txn, cs: cs),
        const Divider(height: 1),

        // Asientos
        Expanded(
          child: asyncAsientos.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, _) => Center(
                  child: Text('Error: $e', style: TextStyle(color: cs.error)),
                ),
            data:
                (asientos) => _AsientosBody(
                  txn: txn,
                  asientos: asientos,
                  asyncCuadre: asyncCuadre,
                  cs: cs,
                  onConfirmada: onConfirmada,
                ),
          ),
        ),
      ],
    );
  }
}

// ── Resumen de transacción (readonly) ─────────────────────────────────────

class _TxnResumen extends StatelessWidget {
  final TransaccionesEntity txn;
  final ColorScheme cs;
  const _TxnResumen({required this.txn, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          _InfoChip(
            label: 'Monto Origen',
            value: _nf.format(txn.montoOrigen),
            cs: cs,
          ),
          _InfoChip(
            label: 'TC Aplicado',
            value: txn.tipoCambioAplicado.toStringAsFixed(4),
            cs: cs,
          ),
          _InfoChip(
            label: 'Convertido',
            value: _nf.format(txn.montoConvertido),
            cs: cs,
          ),
          _InfoChip(
            label: 'Total Final',
            value: _nf.format(txn.totalFinal),
            cs: cs,
            bold: true,
          ),
          _InfoChip(
            label: 'Fecha',
            value: _df.format(txn.fechaTransaccion),
            cs: cs,
          ),
          if (txn.proveedor.isNotEmpty)
            _InfoChip(label: 'Proveedor', value: txn.proveedor, cs: cs),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool bold;
  const _InfoChip({
    required this.label,
    required this.value,
    required this.cs,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: bold ? cs.primary : cs.onSurface,
              fontFeatures: tpexTabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cuerpo de asientos ───────────────────────────────────────────────────

class _AsientosBody extends ConsumerWidget {
  final TransaccionesEntity txn;
  final List<AsientoEntity> asientos;
  final AsyncValue<AsientoEntity?> asyncCuadre;
  final ColorScheme cs;
  final VoidCallback onConfirmada;

  const _AsientosBody({
    required this.txn,
    required this.asientos,
    required this.asyncCuadre,
    required this.cs,
    required this.onConfirmada,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuadre = asyncCuadre.valueOrNull;
    final cuadrado =
        cuadre != null && cuadre.estadoCuadre.toUpperCase() == 'CUADRADO';
    // El botón Confirmar solo aplica si la transacción todavía puede pasar a
    // CONFIRMADO. Si ya está CONFIRMADO (o CANCELADO) no se muestra, para no
    // disparar el error "No se puede modificar una transacción en estado
    // CONFIRMADO". Los asientos sí se pueden seguir editando (lo permite el SP).
    final estadoTxn = txn.estado.toUpperCase();
    final puedeConfirmar =
        cuadrado && estadoTxn != 'CONFIRMADO' && estadoTxn != 'CANCELADO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sub-header asientos
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(
            children: [
              Text(
                'Asientos contables',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Agregar'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _abrirDialogo(context, ref),
              ),
            ],
          ),
        ),

        // Lista de asientos
        Expanded(
          child:
              asientos.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.table_rows_rounded,
                          size: 48,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sin asientos registrados',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    children:
                        asientos
                            .map(
                              (a) => _AsientoFilaCob(
                                asiento: a,
                                txn: txn,
                                cs: cs,
                                onEditar:
                                    () =>
                                        _abrirDialogo(context, ref, editar: a),
                              ),
                            )
                            .toList(),
                  ),
        ),

        // Cuadre
        asyncCuadre.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (cuadre) {
            if (cuadre == null || cuadre.estadoCuadre.isEmpty) {
              return const SizedBox.shrink();
            }
            final ok = cuadre.estadoCuadre.toUpperCase() == 'CUADRADO';
            final color = ok ? Colors.green : Colors.red;
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        ok ? Icons.check_circle_rounded : Icons.warning_rounded,
                        color: color,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cuadre.estadoCuadre,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      _CuadrePair(
                        'Débito Bs',
                        _nf.format(cuadre.totalDebitoBs),
                      ),
                      _CuadrePair(
                        'Crédito Bs',
                        _nf.format(cuadre.totalCreditoBs),
                      ),
                      _CuadrePair(
                        'Diferencia Bs',
                        _nf.format(cuadre.diferenciaBs),
                        bold: !ok,
                        color: !ok ? Colors.red : null,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        // Cobranzas = SOLO registro contable. El pago NO se confirma aquí: el
        // N° de transacción bancaria y el voucher se cargan en
        // "Gestión de Solicitudes" → botón Transacción → "Confirmar Pago".
        if (cuadrado && estadoTxn == 'CONFIRMADO')
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: Colors.teal.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Pago confirmado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          )
        else if (puedeConfirmar)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.22)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade900,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Asientos cuadrados. ',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text:
                                'Esto es solo el registro contable. El pago '
                                '(N° de transacción bancaria y voucher) se confirma '
                                'en "Gestión de Solicitudes" → botón ',
                          ),
                          TextSpan(
                            text: 'Transacción',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 4),
      ],
    );
  }

  void _abrirDialogo(
    BuildContext context,
    WidgetRef ref, {
    AsientoEntity? editar,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (_) => _DialogoAsientoCob(
            txn: txn,
            numero: editar?.numero ?? asientos.length + 1,
            audUsuario: ref.read(userProvider)?.codUsuario ?? 0,
            editar: editar,
          ),
    );
  }
}

class _CuadrePair extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _CuadrePair(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? cs.onSurface,
            fontFeatures: tpexTabularFigures,
          ),
        ),
      ],
    );
  }
}

// ── Fila de asiento ───────────────────────────────────────────────────────

class _AsientoFilaCob extends ConsumerStatefulWidget {
  final AsientoEntity asiento;
  final TransaccionesEntity txn;
  final ColorScheme cs;
  final VoidCallback onEditar;
  const _AsientoFilaCob({
    required this.asiento,
    required this.txn,
    required this.cs,
    required this.onEditar,
  });

  @override
  ConsumerState<_AsientoFilaCob> createState() => _AsientoFilaCobState();
}

class _AsientoFilaCobState extends ConsumerState<_AsientoFilaCob> {
  bool _eliminando = false;

  Color _tipoColor(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'PR':
        return Colors.blue;
      case 'PE':
        return Colors.orange;
      case 'MP':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Eliminar asiento'),
            content: Text(
              '¿Confirma eliminar el asiento #${widget.asiento.numero}?\n'
              'El asiento se ocultará pero queda guardado (borrado lógico).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;

    setState(() => _eliminando = true);
    try {
      final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
      final repo = PagosExtranjerosImpl();
      await repo.eliminarAsiento({
        'idAsiento': widget.asiento.idAsiento.toInt(),
        'idTransaccion': widget.txn.idTransaccion.toInt(),
        'audUsuario': audUsuario,
      });
      if (!mounted) return;
      ref.invalidate(asientosTransaccionProvider(widget.txn.idTransaccion));
      ref.invalidate(cuadreAsientosProvider(widget.txn.idTransaccion));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Asiento eliminado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _eliminando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asiento = widget.asiento;
    final cs = widget.cs;
    final c = _tipoColor(asiento.tipoAsiento);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila principal
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 4),
            child: Row(
              children: [
                // Número
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${asiento.numero}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Tipo badge (PR/PE) con tooltip explicativo
                Tooltip(
                  message:
                      asiento.tipoAsiento == 'PR'
                          ? 'PR — Pago Recibido'
                          : asiento.tipoAsiento == 'PE'
                          ? 'PE — Pago Efectuado'
                          : asiento.tipoAsiento,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: c.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      asiento.tipoAsiento,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: c,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Cuentas + desc
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (asiento.cuentaDebe.isNotEmpty)
                        Text(
                          'Debe: ${asiento.cuentaDebe}',
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (asiento.cuentaHaber.isNotEmpty)
                        Text(
                          'Haber: ${asiento.cuentaHaber}',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (asiento.descripcion.isNotEmpty)
                        Text(
                          asiento.descripcion,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.primary.withValues(alpha: 0.75),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Montos
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (asiento.debitoBs > 0)
                      Text(
                        'Débito Bs ${_nf.format(asiento.debitoBs)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFeatures: tpexTabularFigures,
                        ),
                      ),
                    if (asiento.creditoBs > 0)
                      Text(
                        'Crédito Bs ${_nf.format(asiento.creditoBs)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                          fontFeatures: tpexTabularFigures,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Botones editar / eliminar
          if (_eliminando)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 13),
                  label: const Text('Editar', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                  onPressed: widget.onEditar,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, size: 13),
                  label: const Text('Eliminar', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                  ),
                  onPressed: _eliminar,
                ),
                const SizedBox(width: 4),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Diálogo agregar asiento (Cobranzas) ──────────────────────────────────

class _DialogoAsientoCob extends ConsumerStatefulWidget {
  final TransaccionesEntity txn;
  final int numero;
  final int audUsuario;
  final AsientoEntity? editar;
  const _DialogoAsientoCob({
    required this.txn,
    required this.numero,
    required this.audUsuario,
    this.editar,
  });

  @override
  ConsumerState<_DialogoAsientoCob> createState() => _DialogoAsientoCobState();
}

class _DialogoAsientoCobState extends ConsumerState<_DialogoAsientoCob> {
  final _formKey = GlobalKey<FormState>();
  late String _tipoAsiento;
  final _cuentaDebeCtrl = TextEditingController();
  final _cuentaHaberCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  late bool _esDebito;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editar;
    if (e != null) {
      _tipoAsiento = e.tipoAsiento;
      _cuentaDebeCtrl.text = e.cuentaDebe;
      _cuentaHaberCtrl.text = e.cuentaHaber;
      _descripcionCtrl.text = e.descripcion;
      _esDebito = e.debitoBs > 0;
      _montoCtrl.text = (_esDebito ? e.debitoBs : e.creditoBs).toStringAsFixed(
        2,
      );
    } else {
      _tipoAsiento = 'PR';
      _esDebito = true;
    }
  }

  @override
  void dispose() {
    _cuentaDebeCtrl.dispose();
    _cuentaHaberCtrl.dispose();
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  double get _tc => widget.txn.tipoCambioAplicado;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final montoUs = _tc > 0 ? monto / _tc : 0.0;

    final payload = <String, dynamic>{
      'idAsiento': widget.editar?.idAsiento.toInt() ?? 0,
      'idTransaccion': widget.txn.idTransaccion.toInt(),
      'numero': widget.numero,
      'codBancoRef': widget.txn.codBanco,
      'tipoAsiento': _tipoAsiento,
      'cuentaDebe': _cuentaDebeCtrl.text.trim(),
      'cuentaHaber': _cuentaHaberCtrl.text.trim(),
      'descripcion': _descripcionCtrl.text.trim(),
      'debitoBs': _esDebito ? monto : 0.0,
      'creditoBs': _esDebito ? 0.0 : monto,
      'debitoUs': _esDebito ? montoUs : 0.0,
      'creditoUs': _esDebito ? 0.0 : montoUs,
      'tcAplicado': _tc,
      'audUsuario': widget.audUsuario,
    };

    try {
      final repo = PagosExtranjerosImpl();
      await repo.registrarAsiento(payload);
      if (!mounted) return;
      ref.invalidate(asientosTransaccionProvider(widget.txn.idTransaccion));
      ref.invalidate(cuadreAsientosProvider(widget.txn.idTransaccion));
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asiento guardado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nf = NumberFormat('#,##0.00', 'es_BO');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.editar != null
                  ? 'Editar asiento #${widget.editar!.numero}'
                  : 'Nuevo asiento',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            // TC BCB referencia
            ref
                .watch(
                  tcVigenteRefProvider((
                    codBanco: null,
                    idMonedaOrigen: 3,
                    idMonedaDestino: 4,
                  )),
                )
                .when(
                  data:
                      (tc) =>
                          tc == null
                              ? const SizedBox.shrink()
                              : Align(
                                alignment: Alignment.centerLeft,
                                child: Chip(
                                  visualDensity: VisualDensity.compact,
                                  avatar: const Icon(
                                    Icons.currency_exchange,
                                    size: 14,
                                  ),
                                  label: Text(
                                    'TC BCB ref: ${_nf.format(tc.tasaVenta)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: cs.primaryContainer
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                  loading:
                      () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
            const SizedBox(height: 10),
            // Tipo
            DropdownButtonFormField<String>(
              value: _tipoAsiento,
              decoration: const InputDecoration(
                labelText: 'Medio de Pago',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'PR',
                  child: Text('PR — Pago Recibido'),
                ),
                DropdownMenuItem(
                  value: 'PE',
                  child: Text('PE — Pago Efectuado'),
                ),
              ],
              onChanged: (v) => setState(() => _tipoAsiento = v ?? 'PR'),
            ),
            const SizedBox(height: 10),
            // Cuenta Debe
            TextFormField(
              controller: _cuentaDebeCtrl,
              decoration: const InputDecoration(
                labelText: 'Cuenta Debe',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator:
                  (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 10),
            // Cuenta Haber
            TextFormField(
              controller: _cuentaHaberCtrl,
              decoration: const InputDecoration(
                labelText: 'Cuenta Haber',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator:
                  (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 10),
            // Glosa
            TextFormField(
              controller: _descripcionCtrl,
              decoration: const InputDecoration(
                labelText: 'Glosa',
                hintText: 'Ej: Mercury - Transf SOL Compra USD',
                border: OutlineInputBorder(),
                isDense: true,
                helperText: 'Descripción del movimiento contable',
              ),
              maxLines: 2,
              validator:
                  (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'La glosa es obligatoria'
                          : null,
            ),
            const SizedBox(height: 10),
            // Débito / Crédito selector
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Débito Bs')),
                ButtonSegment(value: false, label: Text('Crédito Bs')),
              ],
              selected: {_esDebito},
              onSelectionChanged: (s) => setState(() => _esDebito = s.first),
            ),
            const SizedBox(height: 10),
            // Monto
            TextFormField(
              controller: _montoCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _esDebito ? 'Débito Bs' : 'Crédito Bs',
                border: const OutlineInputBorder(),
                isDense: true,
                suffixText: _tc > 0 ? 'TC ${_tc.toStringAsFixed(4)}' : null,
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Requerido';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Monto inválido';
                return null;
              },
            ),
            if (_tc > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Equivalente US: ~${nf.format((double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0) / _tc)}',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 18),
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _cargando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _cargando ? null : _guardar,
                    child:
                        _cargando
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge de estado dinámico ─────────────────────────────────────────────────

class _EstadoBadgeCob extends StatelessWidget {
  final String estado;
  const _EstadoBadgeCob({required this.estado});

  @override
  Widget build(BuildContext context) {
    final e = estado.toUpperCase();
    final color = tpexEstadoColor(e);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        e,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
