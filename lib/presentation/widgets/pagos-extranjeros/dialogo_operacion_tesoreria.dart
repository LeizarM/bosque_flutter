import 'package:bosque_flutter/core/state/pagos_extranjeros_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OPCIÓN B — Operación de TESORERÍA (sin solicitud ni cotización de proveedor).
/// Para USDT / Fondeo Mercury / Traspaso Mercury / Devolución. Reutiliza el
/// transaccionFormProvider y llama a guardarOperacionTesoreria (idSolicitud/
/// idCotizacion van NULL vía el NULLIF del SP). La "fuente" sale de tch_banco
/// (incluye los intermediarios dados de alta en la opción A) y es OPCIONAL.
class DialogoOperacionTesoreria extends ConsumerStatefulWidget {
  final VoidCallback? onGuardado;
  const DialogoOperacionTesoreria({super.key, this.onGuardado});

  @override
  ConsumerState<DialogoOperacionTesoreria> createState() =>
      _DialogoOperacionTesoreriaState();
}

class _DialogoOperacionTesoreriaState
    extends ConsumerState<DialogoOperacionTesoreria> {
  // codEmpresa -> nombre
  static const List<MapEntry<int, String>> _empresas = [
    MapEntry(1, 'IMPEXPAP'),
    MapEntry(5, 'ESPPAPEL'),
    MapEntry(6, 'GENERAL'),
    MapEntry(8, 'PRODUCTIVA PAPEL'),
  ];
  // Tipos de PAGO A PROVEEDOR (no son de tesorería): se excluyen del selector.
  static const Set<String> _tiposProveedor = {
    'TC_DIRECTO',
    'TC_NEGOCIADO',
    'FORWARD',
    'EXPORTADORA',
  };

  // idCanal -> nombre (tpex_CanalesPago). Default TRANSFERENCIA_LOCAL (8).
  static const List<MapEntry<int, String>> _canales = [
    MapEntry(8, 'TRANSFERENCIA_LOCAL'),
    MapEntry(6, 'SWIFT'),
    MapEntry(7, 'CARTA_CREDITO'),
    MapEntry(9, 'CHEQUE_GERENCIA'),
    MapEntry(10, 'EFECTIVO'),
  ];

  int? _codEmpresa;
  BigInt? _idTipo;
  String? _idTipoCodigo; // codigo del tipo elegido (para detectar DEVOLUCION)
  BigInt? _idTxnOrigen; // transacción que se devuelve (solo DEVOLUCION)
  int? _codBanco; // fuente (opcional)
  int _idCanal = 8; // TRANSFERENCIA_LOCAL por defecto (idCanal tiene FK NOT 0)
  int? _idMonOrigen;
  int? _idMonDestino;

  bool get _esDevolucion => _idTipoCodigo == 'DEVOLUCION';
  final _montoCtrl = TextEditingController();
  final _tcCtrl = TextEditingController();
  final _tcRefCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _guardando = false;

  static const _money = [FontFeature.tabularFigures(), FontFeature.slashedZero()];

  @override
  void dispose() {
    _montoCtrl.dispose();
    _tcCtrl.dispose();
    _tcRefCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  double get _monto => double.tryParse(_montoCtrl.text) ?? 0;
  double get _tc => double.tryParse(_tcCtrl.text) ?? 0;
  double get _tcRef => double.tryParse(_tcRefCtrl.text) ?? 0;
  double get _convertido => _monto * _tc;
  double get _equivUsd => _tcRef > 0 ? _convertido / _tcRef : 0;
  double get _difMas => _equivUsd > 0 ? _equivUsd - _monto : 0;

  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    final parts = s.split('.');
    final ent = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );
    return '$ent,${parts[1]}';
  }

  Future<void> _guardar() async {
    if (_codEmpresa == null ||
        _idTipo == null ||
        _idMonOrigen == null ||
        _idMonDestino == null ||
        _monto <= 0 ||
        _tc <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete empresa, tipo, monedas, monto y TC aplicado.'),
        ),
      );
      return;
    }
    if (_esDevolucion && _idTxnOrigen == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione la transacción a devolver.'),
        ),
      );
      return;
    }
    setState(() => _guardando = true);
    final notifier = ref.read(transaccionFormProvider.notifier);
    notifier.resetForm();
    notifier.setCodEmpresa(_codEmpresa!);
    notifier.setIdTipoTransaccion(_idTipo!);
    if (_codBanco != null) notifier.setCodBanco(_codBanco!);
    notifier.setIdCanal(_idCanal);
    notifier.setIdMonedaOrigen(_idMonOrigen!);
    notifier.setIdMonedaDestino(_idMonDestino!);
    notifier.setMontoOrigen(_monto);
    notifier.setTipoCambioAplicado(_tc);
    if (_tcRef > 0) notifier.setTipoCambioReferencia(_tcRef);
    if (_obsCtrl.text.trim().isNotEmpty) {
      notifier.setObservaciones(_obsCtrl.text.trim());
    }
    if (_esDevolucion && _idTxnOrigen != null) {
      notifier.setIdTransaccionOrigen(_idTxnOrigen);
    }
    notifier.setFechaTransaccion(DateTime.now());

    final audUsuario = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await notifier.guardarOperacionTesoreria(audUsuario);
    if (!mounted) return;
    setState(() => _guardando = false);
    final st = ref.read(transaccionFormProvider);
    if (ok) {
      widget.onGuardado?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(st.mensajeExito ?? 'Operación de tesorería registrada.'),
          backgroundColor: Colors.teal.shade700,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(st.mensajeError ?? 'No se pudo registrar la operación.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tiposAsync = ref.watch(tiposTransaccionProvider);
    final monedasAsync = ref.watch(monedasProvider);
    final bancosAsync = ref.watch(bancosTPEXProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: cs.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Operación de Tesorería',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Compra de USDT, Fondeo/Traspaso Mercury o Devolución — sin pasar '
                      'por solicitud ni cotización de proveedor.',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    // Empresa
                    DropdownButtonFormField<int>(
                      value: _codEmpresa,
                      decoration: _dec('Empresa *'),
                      items: _empresas
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _codEmpresa = v),
                    ),
                    const SizedBox(height: 12),
                    // Tipo de operación (solo tesorería)
                    tiposAsync.when(
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      error: (_, __) => const Text('Error al cargar tipos'),
                      data: (tipos) {
                        // Solo tipos de tesorería (se excluyen los de pago a
                        // proveedor). Devolución SÍ va aquí: pide su transacción
                        // origen en el selector de abajo.
                        final treso = tipos
                            .where((t) =>
                                t.activo == 1 &&
                                !_tiposProveedor.contains(t.codigo))
                            .toList();
                        return DropdownButtonFormField<BigInt>(
                          value: _idTipo,
                          isExpanded: true,
                          decoration: _dec('Tipo de operación *'),
                          items: treso
                              .map((t) => DropdownMenuItem(
                                    value: t.idTipoTransaccion,
                                    child: Text(t.nombre,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _idTipo = v;
                            final m =
                                treso.where((t) => t.idTipoTransaccion == v);
                            _idTipoCodigo = m.isNotEmpty ? m.first.codigo : null;
                            // Al cambiar a otro tipo, olvidar la txn origen.
                            if (!_esDevolucion) _idTxnOrigen = null;
                          }),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Transacción origen — solo para DEVOLUCION
                    if (_esDevolucion) ...[
                      _buildOrigenSelector(cs),
                      const SizedBox(height: 12),
                    ],
                    // Fuente (banco/intermediario) — opcional
                    bancosAsync.when(
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      error: (_, __) => const Text('Error al cargar fuentes'),
                      data: (bancos) => DropdownButtonFormField<int>(
                        value: _codBanco,
                        isExpanded: true,
                        decoration: _dec('Fuente / Banco (opcional)'),
                        items: bancos
                            .map((b) => DropdownMenuItem(
                                  value: b.codBanco,
                                  child: Text(b.nombre,
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _codBanco = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Canal (idCanal tiene FK → siempre se manda uno válido)
                    DropdownButtonFormField<int>(
                      value: _idCanal,
                      isExpanded: true,
                      decoration: _dec('Canal'),
                      items: _canales
                          .map((c) => DropdownMenuItem(
                                value: c.key,
                                child: Text(c.value),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _idCanal = v ?? 8),
                    ),
                    const SizedBox(height: 12),
                    // Monedas
                    monedasAsync.when(
                      loading: () =>
                          const LinearProgressIndicator(minHeight: 2),
                      error: (_, __) => const Text('Error al cargar monedas'),
                      data: (monedas) => Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _idMonOrigen,
                              isExpanded: true,
                              decoration: _dec('Moneda origen *'),
                              items: monedas
                                  .where((m) => m.activo == 1)
                                  .map((m) => DropdownMenuItem(
                                        value: m.idMoneda,
                                        child: Text(m.codigo),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _idMonOrigen = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _idMonDestino,
                              isExpanded: true,
                              decoration: _dec('Moneda destino *'),
                              items: monedas
                                  .where((m) => m.activo == 1)
                                  .map((m) => DropdownMenuItem(
                                        value: m.idMoneda,
                                        child: Text(m.codigo),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _idMonDestino = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Monto + TC aplicado
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _montoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'))
                            ],
                            decoration: _dec('Monto origen *'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _tcCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'))
                            ],
                            decoration: _dec('TC aplicado *'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // TC referencia (para diferencia de más)
                    TextField(
                      controller: _tcRefCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                      ],
                      decoration: _dec('TC referencia BCB (opcional)'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _obsCtrl,
                      decoration: _dec('Observaciones'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Resumen vivo
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _resumen('Monto convertido (Bs)', _fmt(_convertido)),
                          if (_tcRef > 0) ...[
                            const SizedBox(height: 6),
                            _resumen('Equivalente USD (a $_tcRef)',
                                _fmt(_equivUsd)),
                            const SizedBox(height: 6),
                            _resumen('Diferencia de más (USD)', _fmt(_difMas),
                                destacado: true),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Acciones
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _guardando
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(_guardando ? 'Guardando…' : 'Registrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  String _numStr(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// Selector de la transacción que se está devolviendo (solo DEVOLUCION).
  /// Lista las transacciones recientes (excepto otras devoluciones) y, al elegir
  /// una, pre-rellena monedas/monto/TC con los de la original (editable para
  /// devoluciones parciales).
  Widget _buildOrigenSelector(ColorScheme cs) {
    // Clave ESTABLE (solo fecha, sin hora): si incluyera DateTime.now() con hora
    // el provider .family se recrearía en cada build → refetch y flicker.
    final hoy = DateTime.now();
    final params = (
      fechaInicio: DateTime(hoy.year - 2, 1, 1),
      fechaFin: DateTime(hoy.year, hoy.month, hoy.day),
      codEmpresa: ref.read(userProvider)?.codEmpresa ?? 0,
    );
    final txnsAsync = ref.watch(reporteTransaccionesFechasProvider(params));
    return txnsAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, __) => Text('No se pudieron cargar las transacciones',
          style: TextStyle(fontSize: 12, color: cs.error)),
      data: (todas) {
        // No se devuelve una devolución (idTipoTransaccion 15 = DEVOLUCION).
        final txns = todas
            .where((t) => t.idTipoTransaccion != BigInt.from(15))
            .toList()
          ..sort((a, b) => b.idTransaccion.compareTo(a.idTransaccion));
        if (txns.isEmpty) {
          return Text('No hay transacciones para devolver.',
              style: TextStyle(fontSize: 12, color: cs.error));
        }
        return DropdownButtonFormField<BigInt>(
          value: _idTxnOrigen,
          isExpanded: true,
          decoration: _dec('Transacción a devolver *'),
          items: txns.map((t) {
            final party = t.proveedor.isNotEmpty
                ? t.proveedor
                : (t.banco.isNotEmpty ? t.banco : 'Tesorería');
            final mon = t.monedaOrigen.isNotEmpty ? '${t.monedaOrigen} ' : '';
            return DropdownMenuItem(
              value: t.idTransaccion,
              child: Text(
                'Txn #${t.idTransaccion} · $party · $mon${_fmt(t.montoOrigen)} · ${t.estado}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() {
            _idTxnOrigen = v;
            final sel = txns.where((t) => t.idTransaccion == v);
            if (sel.isEmpty) return;
            final o = sel.first;
            // El reporte trae el CÓDIGO de moneda en texto, pero idMonedaOrigen/
            // Destino pueden venir en 0 → mapear por código contra el catálogo
            // (si queda en 0 dispara "no item with value 0" en el Dropdown).
            final monedas = ref.read(monedasProvider).asData?.value ?? [];
            // Devuelve un idMoneda que EXISTA entre las activas (las que están en
            // el Dropdown); si no, null (evita el assert "no item with value X").
            int? monId(int id, String code) {
              final activos = monedas.where((x) => x.activo == 1).toList();
              if (id > 0 && activos.any((x) => x.idMoneda == id)) return id;
              final m = activos.where((x) => x.codigo == code);
              return m.isNotEmpty ? m.first.idMoneda : null;
            }
            // Espejo de la original; solo si el usuario no eligió ya algo.
            _idMonOrigen ??= monId(o.idMonedaOrigen, o.monedaOrigen);
            _idMonDestino ??= monId(o.idMonedaDestino, o.monedaDestino);
            if (_montoCtrl.text.isEmpty && o.montoOrigen > 0) {
              _montoCtrl.text = o.montoOrigen.toStringAsFixed(2);
            }
            if (_tcCtrl.text.isEmpty && o.tipoCambioAplicado > 0) {
              _tcCtrl.text = _numStr(o.tipoCambioAplicado);
            }
            if (_tcRefCtrl.text.isEmpty && o.tipoCambioReferencia > 0) {
              _tcRefCtrl.text = _numStr(o.tipoCambioReferencia);
            }
          }),
        );
      },
    );
  }

  Widget _resumen(String k, String v, {bool destacado = false}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        Text(
          v,
          style: TextStyle(
            fontSize: destacado ? 15 : 13,
            fontWeight: FontWeight.w700,
            color: destacado ? cs.primary : cs.onSurface,
            fontFeatures: _money,
          ),
        ),
      ],
    );
  }
}
