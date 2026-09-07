// Destino final: lib/presentation/screens/tareas-rutinarias/arqueo_caja_screen.dart
import 'package:bosque_flutter/core/state/arqueo_caja_provider.dart';
import 'package:bosque_flutter/core/state/corte_provider.dart';
import 'package:bosque_flutter/core/state/documentacion_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/vale_arqueo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reemplaza dlgArqCaja del legacy. El total/diferencia se recalculan en
/// vivo mientras se edita (igual que calcularTotalYDiferencia() del legacy)
/// y de nuevo en el servidor al guardar — acá solo es para mostrar, el
/// servidor nunca confía en este número. Cerrar con descuadre está
/// permitido a propósito (comportamiento legacy real, no un bug) — solo se
/// avisa antes de confirmar.
///
/// saldoMovSap/tc NO son manuales en el legacy (confirmado leyendo
/// OBJECT_DEFINITION real de p_list_sucXMovCaja/p_list_arqueoCajaSucursales,
/// 2026-09-03): se autocompletan del desglose SAP por caja y del tipo de
/// cambio del día — ver [ArqueoCajaNotifier.cargarContexto]. Siguen siendo
/// editables (el usuario puede corregir si el efectivo real no cuadra con
/// lo que muestra el sistema), por eso el widget pasó a Stateful: necesita
/// controladores para poder autocompletar sin pisar lo que el usuario ya
/// haya tocado.
class ArqueoCajaScreen extends ConsumerStatefulWidget {
  final int idTarRuti;
  final int idBitTarea;
  final String nombreTarea;

  const ArqueoCajaScreen({
    super.key,
    required this.idTarRuti,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  @override
  ConsumerState<ArqueoCajaScreen> createState() => _ArqueoCajaScreenState();
}

class _ArqueoCajaScreenState extends ConsumerState<ArqueoCajaScreen> {
  final _saldoSapCtrl = TextEditingController();
  final _tcCtrl = TextEditingController(text: '1');
  bool _contextoAplicado = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(arqueoCajaProvider.notifier)
          .cargarContexto(widget.idBitTarea),
    );
  }

  @override
  void dispose() {
    _saldoSapCtrl.dispose();
    _tcCtrl.dispose();
    super.dispose();
  }

  String _dateFmt(dynamic raw) {
    final d = raw is String ? DateTime.tryParse(raw) : null;
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _confirmarYGuardar(
    BuildContext context,
    WidgetRef ref,
    double diferencia,
  ) async {
    if (diferencia.abs() > 0.01) {
      final continuar = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Hay una diferencia'),
              content: Text(
                'El arqueo tiene un descuadre de ${diferencia.toStringAsFixed(2)}. '
                '¿Seguro que quieres cerrar el arqueo así, sin ajustar?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Revisar de nuevo'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Cerrar igual'),
                ),
              ],
            ),
      );
      if (continuar != true) return;
    }
    if (!context.mounted) return;
    await ref
        .read(arqueoCajaProvider.notifier)
        .registrar(idTarRuti: widget.idTarRuti, idBitTarea: widget.idBitTarea);
  }

  @override
  Widget build(BuildContext context) {
    final cortesState = ref.watch(corteProvider);
    final docsState = ref.watch(documentacionProvider);
    final state = ref.watch(arqueoCajaProvider);
    final notifier = ref.read(arqueoCajaProvider.notifier);

    final cortesActivos = cortesState.items;
    final total = state.totalCon(cortesActivos);
    final diferencia = state.diferenciaCon(cortesActivos);
    final cuadrado = diferencia.abs() <= 0.01;

    // Autocompleta los controladores UNA sola vez, apenas llega el contexto
    // real del servidor — después el usuario puede seguir editando sin que
    // se le pise lo que ya escribió.
    if (!_contextoAplicado &&
        !state.cargandoContexto &&
        (state.desgloseSap.isNotEmpty || state.tc != 1)) {
      _contextoAplicado = true;
      _saldoSapCtrl.text = state.saldoMovSap.toStringAsFixed(2);
      _tcCtrl.text = state.tc.toStringAsFixed(4);
    }

    ref.listen(arqueoCajaProvider, (previo, actual) {
      if (actual.completado && previo?.completado != true) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, 'Arqueo registrado — tarea completada.');
        Navigator.of(context).pop(true);
      }
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final anchoMaximo = anchoDisponible >= 900 ? 700.0 : double.infinity;
    final usuario = ref.watch(userProvider);
    final hoy = DateTime.now();
    final fechaHoy =
        '${hoy.day.toString().padLeft(2, '0')}/${hoy.month.toString().padLeft(2, '0')}/${hoy.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nombreTarea, overflow: TextOverflow.ellipsis),
      ),
      body:
          (cortesState.cargando || docsState.cargando) && cortesActivos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: anchoMaximo),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    children: [
                      // Contexto de quién/dónde/cuándo — el legacy lo muestra
                      // como panel de solo-lectura arriba del formulario
                      // (Encargado/Cargo/Sucursal/Fecha), resuelto del propio
                      // usuario logueado: en Arqueo quien llena el form ES el
                      // encargado (confirmado contra WizardTareas — distinto
                      // del caso Coches/CajaFuerte/CajaChica, donde la
                      // ocurrencia puede pertenecer a otra persona).
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 8,
                            children: [
                              _DatoContexto(
                                icono: Icons.badge_outlined,
                                etiqueta: 'Encargado',
                                valor: usuario?.nombreCompleto ?? '—',
                              ),
                              _DatoContexto(
                                icono: Icons.work_outline,
                                etiqueta: 'Cargo',
                                valor: usuario?.cargo ?? '—',
                              ),
                              _DatoContexto(
                                icono: Icons.store_outlined,
                                etiqueta: 'Sucursal',
                                valor: usuario?.nombreSucursal ?? '—',
                              ),
                              _DatoContexto(
                                icono: Icons.event_outlined,
                                etiqueta: 'Fecha',
                                valor: fechaHoy,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Arqueo anterior — contexto/comparación, no bloquea nada.
                      if (state.anterior != null)
                        _ArqueoAnteriorCard(
                          anterior: state.anterior!,
                          dateFmt: _dateFmt,
                        ),
                      if (state.anterior != null) const SizedBox(height: 12),
                      _Seccion(
                        titulo: 'Datos generales',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.cargandoContexto)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: LinearProgressIndicator(),
                              ),
                            // Desglose SAP por caja — el legacy lo muestra como
                            // tabla, no como un solo número tipeado a mano.
                            if (state.desgloseSap.isNotEmpty) ...[
                              Text(
                                'Movimiento de caja SAP',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 6),
                              ...state.desgloseSap.map(
                                (fila) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          (fila['bd'] as String?) ?? '',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ),
                                      Text(
                                        ((fila['monto'] as num?)?.toDouble() ??
                                                0)
                                            .toStringAsFixed(2),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 16),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _saldoSapCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Saldo según sistema (SAP)',
                                      helperText:
                                          state.desgloseSap.isNotEmpty
                                              ? 'Autocompletado — puedes corregirlo'
                                              : null,
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged:
                                        (v) => notifier.setSaldoMovSap(
                                          double.tryParse(v) ?? 0,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _tcCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Tipo de cambio',
                                      helperText:
                                          state.tcAyer != null
                                              ? 'Ayer: ${state.tcAyer!.toStringAsFixed(4)}'
                                              : null,
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged:
                                        (v) => notifier.setTc(
                                          double.tryParse(v) ?? 1,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Observación (opcional)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: notifier.setObs,
                            ),
                          ],
                        ),
                      ),
                      _Seccion(
                        titulo: 'Cortes (billetes y monedas)',
                        child: Column(
                          children: [
                            ...cortesActivos.map((c) {
                              final cantidad =
                                  state.cantidadPorCorte[c.idCorte] ?? 0;
                              final valorUnitario = c.corte ?? 0;
                              final esDolares = c.tipoCorte == 'DOLARES';
                              final subtotalBs =
                                  cantidad *
                                  valorUnitario *
                                  (esDolares ? state.tc : 1);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '${c.descripcion ?? ''} (${esDolares ? '\$' : 'Bs'} ${valorUnitario.toStringAsFixed(2)})',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          labelText: 'Cantidad',
                                          isDense: true,
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged:
                                            (v) => notifier.setCantidadCorte(
                                              c.idCorte,
                                              int.tryParse(v) ?? 0,
                                            ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 84,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        child: Text(
                                          key: ValueKey(subtotalBs),
                                          cantidad > 0
                                              ? subtotalBs.toStringAsFixed(2)
                                              : '—',
                                          textAlign: TextAlign.end,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                            fontWeight:
                                                cantidad > 0
                                                    ? FontWeight.w700
                                                    : FontWeight.normal,
                                            color:
                                                cantidad > 0
                                                    ? Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface
                                                    : Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Subtotal cortes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  child: Text(
                                    key: ValueKey(state.cantidadPorCorte),
                                    'Bs ${cortesActivos.fold<double>(0, (a, c) {
                                      final cant = state.cantidadPorCorte[c.idCorte] ?? 0;
                                      final factor = c.tipoCorte == 'DOLARES' ? state.tc : 1;
                                      return a + cant * (c.corte ?? 0) * factor;
                                    }).toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _Seccion(
                        titulo: 'Documentación',
                        child: Column(
                          children:
                              docsState.items
                                  .map(
                                    (d) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              d.nombre,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              decoration: const InputDecoration(
                                                labelText: 'Monto',
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                              ),
                                              keyboardType:
                                                  const TextInputType.numberWithOptions(
                                                    decimal: true,
                                                  ),
                                              onChanged:
                                                  (v) => notifier.setMontoDoc(
                                                    d.idDoc,
                                                    double.tryParse(v) ?? 0,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      _Seccion(
                        titulo: 'Vales',
                        child: Column(
                          children: [
                            ...state.vales.map(
                              (v) => _FilaVale(
                                key: ValueKey(v.id),
                                vale: v,
                                onCambio:
                                    (actualizar) => notifier.actualizarVale(
                                      v.id,
                                      actualizar,
                                    ),
                                onQuitar: () => notifier.quitarVale(v.id),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: notifier.agregarVale,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar vale'),
                            ),
                          ],
                        ),
                      ),
                      // El resumen (total/diferencia) vive en la barra
                      // inferior, siempre visible — antes estaba acá, al
                      // final del scroll, y había que bajar todo el
                      // formulario para verlo mientras se llenaba.
                    ],
                  ),
                ),
              ),
      // El color cambia de "cuadrado" a "descuadrado" en vivo mientras se
      // edita — AnimatedContainer lo hace sentir como un cambio de estado
      // real, no un repintado brusco. Siempre visible (pegado abajo, arriba
      // del botón), no al final del scroll: es la respuesta a "por qué
      // cerrar" y necesita estar a la vista mientras se llena el formulario,
      // no solo al terminar.
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      cuadrado
                          ? TareasColors.cuadrado(context)
                          : TareasColors.descuadrado(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      cuadrado
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 18,
                      color:
                          cuadrado
                              ? TareasColors.cuadradoTexto(context)
                              : TareasColors.descuadradoTexto(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          'Total contado: ${total.toStringAsFixed(2)}',
                          key: ValueKey(total.toStringAsFixed(2)),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color:
                                cuadrado
                                    ? TareasColors.cuadradoTexto(context)
                                    : TareasColors.descuadradoTexto(context),
                          ),
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        cuadrado
                            ? 'Cuadra'
                            : 'Dif: ${diferencia.toStringAsFixed(2)}',
                        key: ValueKey(
                          cuadrado ? 'cuadrado' : diferencia.toStringAsFixed(2),
                        ),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              cuadrado
                                  ? TareasColors.cuadradoTexto(context)
                                  : TareasColors.descuadradoTexto(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed:
                      state.guardando
                          ? null
                          : () => _confirmarYGuardar(context, ref, diferencia),
                  icon:
                      state.guardando
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                          : const Icon(Icons.check),
                  label: Text(state.guardando ? 'Guardando…' : 'Cerrar arqueo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatoContexto extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _DatoContexto({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
            ),
            Text(
              valor,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

/// Arqueo anterior de esta sucursal — contexto/comparación, no bloquea
/// nada. No existe en el diálogo de CREAR del legacy (esa lógica es del
/// panel de supervisor, ya migrado como Verificar Cierre) — acá es un uso
/// nuevo del mismo dato real, pedido explícitamente por Marcelo.
class _ArqueoAnteriorCard extends StatelessWidget {
  final Map<String, dynamic> anterior;
  final String Function(dynamic) dateFmt;

  const _ArqueoAnteriorCard({required this.anterior, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final diferencia = (anterior['diferencia'] as num?)?.toDouble() ?? 0;
    final cuadrado = diferencia.abs() <= 0.01;
    final revisado = (anterior['fueRevisado'] as num?)?.toInt() == 1;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.history, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Arqueo anterior · ${dateFmt(anterior['fecha'])}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total: ${((anterior['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} · '
                    '${cuadrado ? 'Cuadró' : 'Diferencia: ${diferencia.toStringAsFixed(2)}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              revisado ? Icons.verified_outlined : Icons.hourglass_empty,
              size: 16,
              color:
                  revisado
                      ? TareasColors.realizadoTexto(context)
                      : scheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _FilaVale extends StatelessWidget {
  final ValeArqueoEntity vale;
  final void Function(ValeArqueoEntity Function(ValeArqueoEntity)) onCambio;
  final VoidCallback onQuitar;

  const _FilaVale({
    super.key,
    required this.vale,
    required this.onCambio,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: vale.nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onCambio((f) => f.copyWith(nombre: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: vale.monto?.toString(),
              decoration: const InputDecoration(
                labelText: 'Monto',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged:
                  (v) => onCambio((f) => f.copyWith(monto: double.tryParse(v))),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Quitar vale',
            onPressed: onQuitar,
          ),
        ],
      ),
    );
  }
}
