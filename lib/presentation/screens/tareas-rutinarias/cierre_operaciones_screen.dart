// Destino final: lib/presentation/screens/tareas-rutinarias/cierre_operaciones_screen.dart
import 'package:bosque_flutter/core/state/cierre_operaciones_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reemplaza el panel plMovCaja de dlgRevArqueo (idATR=3, el paso "doer" de
/// la cadena Cierre→Verificar). Los traspasos NO los crea quien usa esta
/// pantalla — ya están sincronizados desde afuera; acá solo se revisan y se
/// confirman para el día. Un día sin traspasos es válido, igual se puede
/// cerrar la tarea.
///
/// El legacy deja elegir CUALQUIER fecha (`<p:calendar>` + "Desplegar",
/// default hoy) y guarda un flag "¿Fue Verificado?" POR FILA junto con la
/// confirmación (`guardarTraspasos()`, un UPDATE por traspaso) — antes acá
/// solo se reclamaba el día completo en bloque, sin ese dato ni selector de
/// fecha.
class CierreOperacionesScreen extends ConsumerWidget {
  final int idBitTarea;
  final String nombreTarea;

  const CierreOperacionesScreen({
    super.key,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  String _dateFmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _elegirFecha(BuildContext context, WidgetRef ref, DateTime actual) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (elegida == null) return;
    HapticFeedback.selectionClick();
    await ref.read(cierreOperacionesProvider.notifier).cambiarFecha(elegida);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cierreOperacionesProvider);
    final notifier = ref.read(cierreOperacionesProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    ref.listen(cierreOperacionesProvider, (previo, actual) {
      if (actual.traspasosConfirmados != null &&
          actual.traspasosConfirmados != previo?.traspasosConfirmados) {
        HapticFeedback.mediumImpact();
        mostrarAviso(
          context,
          actual.traspasosConfirmados! > 0
              ? '${actual.traspasosConfirmados} traspaso(s) confirmado(s) — tarea completada.'
              : 'Sin traspasos para esa fecha — tarea completada igual.',
        );
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

    // Un solo switch entre las 3 formas de la pantalla (cargando/vacío/con
    // datos), con transición suave entre ellas — nunca se reemplaza contenido
    // ya cargado con un spinner en blanco.
    final Widget cuerpo;
    if (state.cargando && state.traspasos.isEmpty) {
      cuerpo = const Center(
        key: ValueKey('cargando'),
        child: CircularProgressIndicator(),
      );
    } else if (state.traspasos.isEmpty) {
      cuerpo = ListView(
        key: const ValueKey('vacio'),
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay traspasos de movimiento de caja sincronizados para el ${_dateFmt(state.fechaEfectiva)}.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Es un día válido: puedes confirmar igual para cerrar la tarea.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      cuerpo = ListView.builder(
        key: const ValueKey('lista'),
        padding: const EdgeInsets.all(12),
        itemCount: state.traspasos.length,
        itemBuilder: (context, i) {
          final t = state.traspasos[i];
          return _FilaTraspaso(
            traspaso: t,
            fueVerificado: (state.fueVerificadoPorFila[t.idTrasp] ?? 0) == 1,
            onToggle: () {
              HapticFeedback.selectionClick();
              notifier.toggleVerificado(t.idTrasp);
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(nombreTarea, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton.icon(
            onPressed: () => _elegirFecha(context, ref, state.fechaEfectiva),
            icon: const Icon(Icons.event_outlined),
            label: Text(_dateFmt(state.fechaEfectiva)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.cargar,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: anchoMaximo),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: cuerpo,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed:
                state.confirmando ? null : () => notifier.confirmar(idBitTarea),
            icon:
                state.confirmando
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                    : const Icon(Icons.check),
            label: Text(
              state.confirmando ? 'Confirmando…' : 'Confirmar y cerrar',
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaTraspaso extends StatelessWidget {
  final TraspasoMovCajaEntity traspaso;
  final bool fueVerificado;
  final VoidCallback onToggle;

  const _FilaTraspaso({
    required this.traspaso,
    required this.fueVerificado,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.sync_alt),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    traspaso.acctName ?? traspaso.account ?? 'Traspaso',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${traspaso.bd ?? ''} · ${traspaso.tipoTransaccion ?? ''} · cuenta ${traspaso.account ?? '—'} → ${traspaso.contraAct ?? '—'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if ((traspaso.bs ?? 0) != 0 || (traspaso.dolares ?? 0) != 0)
                    Text(
                      [
                        if ((traspaso.bs ?? 0) != 0) 'Bs ${traspaso.bs!.toStringAsFixed(2)}',
                        if ((traspaso.dolares ?? 0) != 0) '\$us ${traspaso.dolares!.toStringAsFixed(2)}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('¿Verificado?', style: Theme.of(context).textTheme.labelSmall),
                Switch(value: fueVerificado, onChanged: (_) => onToggle()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
