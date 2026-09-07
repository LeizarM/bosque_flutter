// Destino final: lib/presentation/screens/tareas-rutinarias/caja_fuerte_screen.dart
import 'package:bosque_flutter/core/state/caja_fuerte_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/llegada_caja_fuerte_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reemplaza dlgCajaFuerte del legacy ("REPORTAR DINERO PARA CAJA FUERTE").
/// El tipo (cheque/efectivo) es obligatorio en cada fila — el backend
/// rechaza el lote entero si falta en alguna, igual que
/// WizardTareas.guardarCajaFuerte(); acá se exige antes de poder tocar
/// "Guardar" en vez de dejar mandar y recién avisar.
class CajaFuerteScreen extends ConsumerWidget {
  final int idTarRuti;
  final int idBitTarea;
  final String nombreTarea;

  const CajaFuerteScreen({
    super.key,
    required this.idTarRuti,
    required this.idBitTarea,
    required this.nombreTarea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cajaFuerteProvider);
    final notifier = ref.read(cajaFuerteProvider.notifier);
    final anchoDisponible = MediaQuery.sizeOf(context).width;
    final esAncho = anchoDisponible >= 700;

    ref.listen(cajaFuerteProvider, (previo, actual) {
      if (actual.filasGuardadas != null && actual.filasGuardadas != previo?.filasGuardadas) {
        HapticFeedback.mediumImpact();
        mostrarAviso(context, '${actual.filasGuardadas} llegada(s) registrada(s) — tarea completada.');
        Navigator.of(context).pop(true);
      }
      if (actual.mensajeError != null && actual.mensajeError != previo?.mensajeError) {
        HapticFeedback.lightImpact();
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(nombreTarea, overflow: TextOverflow.ellipsis)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: esAncho ? 640 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ...state.filas.map(
                (fila) => _FilaAnimada(
                  key: ValueKey(fila.id),
                  child: _FilaLlegada(
                    fila: fila,
                    puedeQuitar: state.filas.length > 1,
                    onCambio: (actualizar) => notifier.actualizarFila(fila.id, actualizar),
                    onQuitar: () {
                      HapticFeedback.selectionClick();
                      notifier.quitarFila(fila.id);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  notifier.agregarFila();
                },
                icon: const Icon(Icons.add),
                label: const Text('Agregar otra llegada'),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: state.guardando
                    ? null
                    : () => notifier.registrar(
                          idTarRuti: idTarRuti,
                          idBitTarea: idBitTarea,
                        ),
                icon: state.guardando
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(state.guardando ? 'Guardando…' : 'Guardar y cerrar tarea'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entrada suave para una fila nueva — cero costo cuando ya está en pantalla
/// (el tween arranca y termina de una en el primer frame si no cambió).
class _FilaAnimada extends StatelessWidget {
  final Widget child;

  const _FilaAnimada({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, (1 - value) * 12), child: child),
      ),
      child: child,
    );
  }
}

class _FilaLlegada extends StatelessWidget {
  final LlegadaCajaFuerteEntity fila;
  final bool puedeQuitar;
  final void Function(LlegadaCajaFuerteEntity Function(LlegadaCajaFuerteEntity)) onCambio;
  final VoidCallback onQuitar;

  const _FilaLlegada({
    required this.fila,
    required this.puedeQuitar,
    required this.onCambio,
    required this.onQuitar,
  });

  /// "Tocada" = tiene algún dato cargado. Distingue de una fila recién
  /// agregada y todavía vacía, que no debe leerse como "incompleta" (mismo
  /// criterio que ya usa cajaFuerteProvider.registrar() para no bloquear por
  /// filas que el usuario ni empezó a llenar).
  bool get _tocada => fila.cliente.trim().isNotEmpty || (fila.importe ?? 0) > 0 || fila.tipo != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completa = fila.esValida;
    final incompleta = _tocada && !completa;

    final Color borde = incompleta
        ? TareasColors.vencido(context)
        : completa
            ? TareasColors.realizado(context)
            : scheme.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borde, width: incompleta || completa ? 1.4 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: completa
                      ? Icon(Icons.check_circle, key: const ValueKey('ok'), size: 18, color: TareasColors.realizadoTexto(context))
                      : incompleta
                          ? Icon(Icons.error_outline, key: const ValueKey('falta'), size: 18, color: TareasColors.vencidoTexto(context))
                          : const SizedBox(key: ValueKey('vacio'), width: 18, height: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    completa ? 'Lista' : (incompleta ? 'Falta completar' : 'Nueva llegada'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: incompleta
                              ? TareasColors.vencidoTexto(context)
                              : completa
                                  ? TareasColors.realizadoTexto(context)
                                  : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (puedeQuitar)
                  IconButton(
                    tooltip: 'Quitar esta llegada',
                    onPressed: onQuitar,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: fila.cliente,
              decoration: const InputDecoration(labelText: 'Cliente', isDense: true, border: OutlineInputBorder()),
              onChanged: (v) => onCambio((f) => f.copyWith(cliente: v)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: fila.moneda,
                    decoration: const InputDecoration(labelText: 'Moneda', isDense: true, border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'BS', child: Text('Bolivianos')),
                      DropdownMenuItem(value: 'USD', child: Text('Dólares')),
                    ],
                    onChanged: (v) => onCambio((f) => f.copyWith(moneda: v)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: fila.importe?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Importe', isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => onCambio((f) => f.copyWith(importe: double.tryParse(v))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: fila.tipo,
              decoration: InputDecoration(
                labelText: 'Tipo',
                isDense: true,
                border: const OutlineInputBorder(),
                helperText: fila.tipo == null ? 'Obligatorio para poder guardar' : null,
              ),
              // Valores 'chq'/'efect' — EXACTOS al legacy (Tareas.xhtml), no
              // 'CHEQUE'/'EFECTIVO': misma columna tac_llegada.tipo que
              // escribe el sistema anterior. Solo la etiqueta visible es
              // libre.
              items: const [
                DropdownMenuItem(value: 'chq', child: Text('Cheque')),
                DropdownMenuItem(value: 'efect', child: Text('Efectivo')),
              ],
              onChanged: (v) => onCambio((f) => f.copyWith(tipo: v)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: fila.destino,
              decoration: const InputDecoration(labelText: 'Destino (opcional)', isDense: true, border: OutlineInputBorder()),
              onChanged: (v) => onCambio((f) => f.copyWith(destino: v)),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: fila.obs,
              decoration: const InputDecoration(labelText: 'Observación (opcional)', isDense: true, border: OutlineInputBorder()),
              onChanged: (v) => onCambio((f) => f.copyWith(obs: v)),
            ),
          ],
        ),
      ),
    );
  }
}
