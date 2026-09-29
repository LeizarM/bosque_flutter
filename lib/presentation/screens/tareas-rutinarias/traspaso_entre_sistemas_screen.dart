// Destino final: lib/presentation/screens/tareas-rutinarias/traspaso_entre_sistemas_screen.dart
import 'package:bosque_flutter/core/constants/tareas_breakpoints.dart';
import 'package:bosque_flutter/core/state/traspaso_entre_sistemas_provider.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/traspaso_mov_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/motivo_no_cuadra.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tarea 295 — "Verificar traspaso Caja AXA contra movimiento de caja"
/// (idATR 12).
///
/// **No confundir con el idATR 11**, "Traspaso De Efectivo Entre Sistemas".
/// Ese es TesBase (`ttes_TesBase`, tesorería) y no tiene ninguna relación
/// con `tac_traspasoMovCaja`. Los nombres se parecen tanto que ya causaron
/// un enredo: ver el archivo SQL 51.
///
/// El cajero compara el formulario manual de Caja AXA contra el movimiento de
/// caja del sistema, fila por fila, y marca si cuadra. Si no cuadra tiene que
/// escribir qué fue lo que no cuadró.
///
/// **Por qué existe el botón "Sin novedad".** Hasta hoy la fila de
/// `tac_traspasoMovCaja` se escribía sólo cuando alguien verificaba, así que
/// un día sin traspasos no dejaba ningún rastro: no había forma de distinguir
/// "nadie miró" de "miró y no había nada". Con la grilla vacía, ese botón es
/// la única manera de dejar constancia de lo segundo.
///
/// Hasta este despliegue la verificación colgaba de Cierre de Operaciones,
/// que además reclamaba en bloque todos los traspasos del día. El archivo
/// SQL 50 se lo saca; el 51 crea esta tarea y la asigna a CAJERO.
class TraspasoEntreSistemasScreen extends ConsumerStatefulWidget {
  final int idBitTarea;
  final String nombreTarea;
  final DateTime fecha;

  const TraspasoEntreSistemasScreen({
    super.key,
    required this.idBitTarea,
    required this.nombreTarea,
    required this.fecha,
  });

  @override
  ConsumerState<TraspasoEntreSistemasScreen> createState() =>
      _TraspasoEntreSistemasScreenState();
}

class _TraspasoEntreSistemasScreenState
    extends ConsumerState<TraspasoEntreSistemasScreen> {
  @override
  Widget build(BuildContext context) {
    final prov = traspasoEntreSistemasProvider(widget.fecha);
    final state = ref.watch(prov);

    ref.listen(prov, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        mostrarAviso(context, actual.error!, tono: TonoAviso.error);
      }
      if (actual.aviso != null && actual.aviso != previo?.aviso) {
        mostrarAviso(context, actual.aviso!, tono: TonoAviso.exito);
      }
    });

    final ancho = MediaQuery.sizeOf(context).width;
    final enTabla = ancho >= TareasBreakpoints.wideMax;

    return TareasScope(
      child: Scaffold(
      appBar: AppBarTareas(
        titulo: widget.nombreTarea,
        subtitulo: _subtitulo(state),
        insignia: InsigniaTarea.deTipo(context, 12),
        acciones: [
          IconButton(
            tooltip: 'Cambiar fecha',
            icon: const Icon(Icons.event_outlined),
            onPressed: state.cargando ? null : () => _elegirFecha(context, ref),
          ),
          IconButton(
            tooltip: 'Volver a consultar el sistema',
            icon: const Icon(Icons.refresh),
            onPressed:
                state.cargando
                    ? null
                    : () => ref.read(prov.notifier).cargar(),
          ),
        ],
      ),
      body: SafeArea(
        child: MargenPaginaTareas(
        child:
            !state.cargado
                // Sin una lectura buena no se muestra ni la grilla ni "no
                // hubo traspasos": lo segundo habilitaría "Sin novedad".
                ? (state.cargando
                    ? const Center(child: CircularProgressIndicator())
                    : EstadoTareas.error(
                      titulo: 'No se pudo consultar los traspasos del sistema.',
                      detalle:
                          'Hasta leerlos no se puede marcar ni cerrar el día '
                          'como sin novedad.',
                      onReintentar: () => ref.read(prov.notifier).cargar(),
                    ))
                : state.diaVacio
                ? _SinTraspasos(
                  fecha: state.fecha,
                  onSinNovedad: () => _cerrarSinNovedad(context, ref),
                )
                : _Grilla(
                  filas: state.filas,
                  enTabla: enTabla,
                  guardando: state.guardando,
                  onMarcar: (fila, cuadra) => _marcar(context, ref, fila, cuadra),
                ),
        ),
      ),
      bottomNavigationBar:
          !state.cargado || state.diaVacio
              ? null
              : _BarraPie(pendientes: state.sinResponder),
    ),
    );
  }

  /// La fecha y, cuando ya se leyó, cuántos faltan: lo que se busca con la
  /// mirada al entrar.
  String _subtitulo(TraspasoEntreSistemasState s) {
    final base = FormatearFecha.formatearFecha(s.fecha);
    if (!s.cargado || s.filas.isEmpty) return base;
    final n = s.sinResponder;
    if (n == 0) return '$base · todo revisado';
    return '$base · ${n == 1 ? 'falta 1' : 'faltan $n'} por revisar';
  }

  Future<void> _elegirFecha(BuildContext context, WidgetRef ref) async {
    final prov = traspasoEntreSistemasProvider(widget.fecha);
    final elegida = await showDatePicker(
      context: context,
      initialDate: ref.read(prov).fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (elegida == null) return;
    HapticFeedback.selectionClick();
    await ref.read(prov.notifier).cambiarFecha(elegida);
  }

  Future<void> _marcar(
    BuildContext context,
    WidgetRef ref,
    TraspasoMovCajaEntity fila,
    bool cuadra,
  ) async {
    String? obs;
    if (!cuadra) {
      obs = await _pedirMotivo(context, fila.obs);
      // Cancelar el diálogo no marca nada. Es distinto de escribir vacío:
      // quien se arrepiente a mitad de camino no debería dejar la fila
      // marcada como que no cuadra.
      if (obs == null) return;
    }
    await ref
        .read(traspasoEntreSistemasProvider(widget.fecha).notifier)
        .verificar(
          idBitTarea: widget.idBitTarea,
          fila: fila,
          cuadra: cuadra,
          obs: obs,
        );
  }

  /// El mismo diálogo que usa la revisión de Cierre de Operaciones: las dos
  /// pantallas marcan los mismos traspasos y tienen que pedir lo mismo.
  Future<String?> _pedirMotivo(BuildContext context, String? inicial) =>
      pedirMotivoNoCuadra(context, inicial);

  Future<void> _cerrarSinNovedad(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cerrar sin novedad'),
            content: const Text(
              'Se va a dejar constancia de que revisaste y no hubo ningún '
              'traspaso en esta fecha.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sin novedad'),
              ),
            ],
          ),
    );
    if (confirmado != true) return;

    final ok = await ref
        .read(traspasoEntreSistemasProvider(widget.fecha).notifier)
        .sinNovedad(widget.idBitTarea);
    if (ok && context.mounted) cerrarRuta(context, true);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

const _anchos = <AnchoCol>[
  AnchoCol.fijo(90), // sistema (bd)
  AnchoCol.fijo(110), // cuenta
  AnchoCol.fijo(110), // contra cuenta
  AnchoCol.flexible(2), // nombre de la cuenta
  AnchoCol.fijo(130), // tipo
  AnchoCol.fijo(100), // dólares
  AnchoCol.fijo(110), // bolivianos
  AnchoCol.fijo(150), // verificado
];

class _Grilla extends StatelessWidget {
  final List<TraspasoMovCajaEntity> filas;
  final bool enTabla;
  final int? guardando;
  final void Function(TraspasoMovCajaEntity, bool) onMarcar;

  const _Grilla({
    required this.filas,
    required this.enTabla,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    if (!enTabla) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: Esp.m),
        itemCount: filas.length,
        itemBuilder:
            (_, i) => _TarjetaTraspaso(
              fila: filas[i],
              guardando: guardando == filas[i].idTrasp,
              onMarcar: onMarcar,
            ),
      );
    }

    return MarcoTabla(
      child: Column(
        children: [
          const EncabezadoTabla(
            anchos: _anchos,
            titulos: [
              'Sistema',
              'Cuenta',
              'Contra cuenta',
              'Nombre cuenta',
              'Tipo',
              'Dólares',
              'Bolivianos',
              '¿Cuadra?',
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filas.length,
              itemBuilder:
                  (_, i) => _FilaTraspaso(
                    fila: filas[i],
                    guardando: guardando == filas[i].idTrasp,
                    onMarcar: onMarcar,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaTraspaso extends StatelessWidget {
  final TraspasoMovCajaEntity fila;
  final bool guardando;
  final void Function(TraspasoMovCajaEntity, bool) onMarcar;

  const _FilaTraspaso({
    required this.fila,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilaTabla(
          anchos: _anchos,
          celdas: [
            _TextoSistema(fila: fila),
            Text(fila.account ?? '—'),
            Text(fila.contraAct ?? '—'),
            Text(fila.acctName ?? '—', overflow: TextOverflow.ellipsis),
            Text(fila.tipoTransaccion ?? '—', overflow: TextOverflow.ellipsis),
            _Importe(valor: fila.dolares, simbolo: r'$us'),
            _Importe(valor: fila.bs, simbolo: 'Bs'),
            _Marcador(fila: fila, guardando: guardando, onMarcar: onMarcar),
          ],
        ),
        if ((fila.obs ?? '').trim().isNotEmpty)
          _Observacion(texto: fila.obs!.trim()),
      ],
    );
  }
}

/// El nombre del sistema, con la marca de "SAP ya no lo devuelve".
class _TextoSistema extends StatelessWidget {
  final TraspasoMovCajaEntity fila;
  const _TextoSistema({required this.fila});

  @override
  Widget build(BuildContext context) {
    if (!fila.soloEnBosque) return Text(fila.bd ?? '—');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(fila.bd ?? '—', overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 4),
        Tooltip(
          message:
              'Está registrado en Bosque pero el sistema ya no lo devuelve. '
              'Revísalo: puede haberse anulado del otro lado.',
          child: Icon(
            Icons.report_problem_outlined,
            size: 16,
            color: TareasColors.pendienteTexto(context),
          ),
        ),
      ],
    );
  }
}

class _Importe extends StatelessWidget {
  final double? valor;
  final String simbolo;
  const _Importe({required this.valor, required this.simbolo});

  @override
  Widget build(BuildContext context) {
    final v = valor ?? 0;
    return Text(
      v == 0 ? '—' : '$simbolo ${FormatoMoneda.monto.format(v)}',
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Los dos botones. Sin `Checkbox`: "no cuadra" no es lo mismo que
/// "todavía no lo miré", y una casilla sin marcar no distingue esos dos.
class _Marcador extends StatelessWidget {
  final TraspasoMovCajaEntity fila;
  final bool guardando;
  final void Function(TraspasoMovCajaEntity, bool) onMarcar;

  const _Marcador({
    required this.fila,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    if (guardando) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final cuadra = fila.fueVerificado == 1;
    final noCuadra = fila.fueVerificado == 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Boton(
          icono: Icons.check_circle,
          etiqueta: 'Cuadra',
          activo: cuadra,
          color: TareasColors.realizadoTexto(context),
          onTap: () => onMarcar(fila, true),
        ),
        const SizedBox(width: 6),
        _Boton(
          icono: Icons.cancel,
          etiqueta: 'No cuadra',
          activo: noCuadra,
          color: TareasColors.eliminar(context),
          onTap: () => onMarcar(fila, false),
        ),
      ],
    );
  }
}

class _Boton extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final bool activo;
  final Color color;
  final VoidCallback onTap;

  const _Boton({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: etiqueta,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icono,
            size: 22,
            color:
                activo
                    ? color
                    : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _Observacion extends StatelessWidget {
  final String texto;
  const _Observacion({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.subdirectory_arrow_right,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TareasColors.eliminar(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaTraspaso extends StatelessWidget {
  final TraspasoMovCajaEntity fila;
  final bool guardando;
  final void Function(TraspasoMovCajaEntity, bool) onMarcar;

  const _TarjetaTraspaso({
    required this.fila,
    required this.guardando,
    required this.onMarcar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _TextoSistema(fila: fila)),
                _Marcador(
                  fila: fila,
                  guardando: guardando,
                  onMarcar: onMarcar,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              fila.acctName ?? '—',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              '${fila.account ?? '—'} → ${fila.contraAct ?? '—'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _Importe(valor: fila.dolares, simbolo: r'$us'),
                const SizedBox(width: 16),
                _Importe(valor: fila.bs, simbolo: 'Bs'),
              ],
            ),
            if ((fila.obs ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _Observacion(texto: fila.obs!.trim()),
            ],
          ],
        ),
      ),
    );
  }
}

/// Lo que se ve cuando SAP no devolvió nada para la fecha.
class _SinTraspasos extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onSinNovedad;

  const _SinTraspasos({required this.fecha, required this.onSinNovedad});

  @override
  Widget build(BuildContext context) {
    return EstadoTareas(
      icono: Icons.inbox_outlined,
      tono: TonoEstadoTareas.listo,
      titulo: 'No hubo traspasos el ${FormatearFecha.formatearFecha(fecha)}',
      detalle:
          'Aun así hay que dejar constancia de que revisaste. Sin eso, en el '
          'reporte este día se ve igual que uno que nadie miró.',
      accion: FilledButton.icon(
        onPressed: onSinNovedad,
        icon: const Icon(Icons.done_all),
        label: const Text('Sin novedad'),
      ),
    );
  }
}

class _BarraPie extends StatelessWidget {
  final int pendientes;
  const _BarraPie({required this.pendientes});

  @override
  Widget build(BuildContext context) {
    final listo = pendientes == 0;
    return Material(
      color: context.cs.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.cs.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.l,
              vertical: Esp.m,
            ),
            child: Row(
              children: [
                Icon(
                  listo ? Icons.check_circle_outline : Icons.pending_outlined,
                  size: 18,
                  color:
                      listo
                          ? TareasColors.realizadoTexto(context)
                          : TareasColors.pendienteTexto(context),
                ),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Text(
                    listo
                        ? 'Revisaste todos los traspasos del día.'
                        : pendientes == 1
                        ? 'Falta 1 por revisar.'
                        : 'Faltan $pendientes por revisar.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
