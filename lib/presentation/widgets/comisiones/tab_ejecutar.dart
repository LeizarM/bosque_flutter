import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/utils/formato_comision.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/estado_periodo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/reportes_pagadas.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/dialogo_items_pagados.dart';

/// Carga y ejecución del período de comisiones.
///
/// Son dos pasos deliberadamente separados. Cargar prepara las notas y se puede
/// repetir; ejecutar hace el corte y no tiene vuelta atrás desde la aplicación.
/// En Bosque v2 los dos botones vivían en el mismo wizard y el único freno era
/// una bandera de pantalla que se perdía al refrescar.
class TabEjecutar extends ConsumerWidget {
  const TabEjecutar({super.key});

  static const _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodo = ref.watch(periodoEjecucionProvider);
    final estado = ref.watch(estadoPeriodoProvider(periodo));
    final padding = ResponsiveUtilsBosque.getHorizontalPadding(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
      children: [
        _SelectorPeriodo(periodo: periodo),
        const SizedBox(height: 20),
        // Los reportes de lo ya pagado, incluido el de importacion, que en el
        // ERP viejo vivian en esta misma pestania. AlcanceReportes.todos y no
        // `pagadas`: `pagadas` es el recorte que usa Preliminar, donde el de
        // importacion no corresponde -esas notas no llevan comision por
        // familia-. Aca corresponde, y es el unico lugar de la app desde donde
        // se llega.
        //
        // Sin permiso propio a proposito: la pestania ya esta detras de
        // TabEjecutar, y el XHTML tampoco ponia candado a los botones de
        // adentro de un panel ya protegido.
        BarraReportesPagadas(
          padding: 0,
          alcance: AlcanceReportes.todos,
          mesInicial: periodo.mes,
          anioInicial: periodo.anio,
          periodoPropio: false,
        ),
        const Divider(height: 24),
        estado.when(
          loading:
              () =>
                  EstadoVista.cargando(context, mensaje: 'Consultando período'),
          error:
              (e, _) => EstadoVista.error(
                context,
                error: e,
                alReintentar:
                    () => ref.invalidate(estadoPeriodoProvider(periodo)),
              ),
          data: (est) => _Contenido(periodo: periodo, estado: est),
        ),
      ],
    );
  }
}

// ── Selector de período ───────────────────────────────────────────────

class _SelectorPeriodo extends ConsumerWidget {
  const _SelectorPeriodo({required this.periodo});

  final ClavePeriodo periodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(periodoEjecucionProvider.notifier);
    final anioActual = DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('Vendedores internos')),
            ButtonSegment(value: 0, label: Text('Vendedores externos')),
          ],
          selected: {periodo.esInterno},
          showSelectedIcon: false,
          onSelectionChanged:
              (s) => notifier.state = periodo.copyWith(esInterno: s.first),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<int>(
                value: periodo.mes,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Mes',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var i = 1; i <= 12; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(TabEjecutar._meses[i - 1]),
                    ),
                ],
                onChanged:
                    (v) =>
                        v == null
                            ? null
                            : notifier.state = periodo.copyWith(mes: v),
              ),
            ),
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<int>(
                value: periodo.anio,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Año',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var a = anioActual - 6; a <= anioActual + 1; a++)
                    DropdownMenuItem(value: a, child: Text('$a')),
                ],
                onChanged:
                    (v) =>
                        v == null
                            ? null
                            : notifier.state = periodo.copyWith(anio: v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Contenido según el estado ─────────────────────────────────────────

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.periodo, required this.estado});

  final ClavePeriodo periodo;
  final EstadoPeriodoEntity? estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (estado != null && estado!.yaEjecutado) {
      return _PeriodoCerrado(estado: estado!);
    }
    return _PeriodoAbierto(periodo: periodo);
  }
}

/// Período ya pagado: solo lectura.
class _PeriodoCerrado extends StatelessWidget {
  const _PeriodoCerrado({required this.estado});

  final EstadoPeriodoEntity estado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: ComisionesTema.brContenedor,
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(
                  'Período ${estado.periodo} ya ejecutado',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Las comisiones de este período ya se pagaron. No se pueden volver '
              'a cargar ni a ejecutar.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 32,
              runSpacing: 12,
              children: [
                _Metrica(
                  etiqueta: 'Notas pagadas',
                  valor: '${estado.cantidadPagados}',
                ),
                _Metrica(
                  etiqueta: 'Total comisión',
                  valor: FormatoComision.monto.format(estado.totalComision),
                ),
                if (estado.fechaEjecucion != null)
                  _Metrica(
                    etiqueta: 'Ejecutado el',
                    valor: FormatoComision.fecha.format(estado.fechaEjecucion!),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            // La entrada al detalle congelado vive aca porque esta es la unica
            // pantalla del modulo que tiene los tres datos que el SP exige
            // -mes, anio y esInterno- ya resueltos y en la misma fila. Y es la
            // que corresponde: el congelado se escribe al ejecutar, asi que su
            // detalle es el comprobante de lo que se acaba de hacer.
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed:
                    () => showDialog<void>(
                      context: context,
                      builder:
                          (_) => DialogoItemsPagados(
                            filtro: FiltroItemsPagados(
                              mes: estado.mes,
                              anio: estado.anio,
                              esInterno: estado.esInterno,
                            ),
                            subtitulo:
                                'Período ${estado.periodo}'
                                '${estado.fechaEjecucion == null ? '' : ', ejecutado el ${FormatoComision.fecha.format(estado.fechaEjecucion!)}'}',
                          ),
                    ),
                icon: const Icon(Icons.rule_folder_outlined, size: 18),
                // El rotulo nombra lo EXCLUIDO y no «ver detalle»: es lo que
                // no se podia consultar en ningun lado, y es la pregunta que
                // trae a alguien a esta pantalla.
                label: const Text('Ver qué quedó fuera del descuento'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Período pendiente: los dos pasos.
class _PeriodoAbierto extends ConsumerWidget {
  const _PeriodoAbierto({required this.periodo});

  final ClavePeriodo periodo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accion = ref.watch(comisionesAccionesProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Paso(
          numero: '1',
          titulo: 'Cargar notas',
          detalle:
              'Separa las notas abiertas de las cerradas y prepara el período. '
              'No mueve dinero, así que se puede repetir.',
          textoBoton: 'Cargar notas',
          icono: Icons.download_outlined,
          enProceso: accion.enProceso,
          alPulsar: () => _cargar(context, ref),
        ),
        const SizedBox(height: 14),
        _Paso(
          numero: '2',
          titulo: 'Ejecutar pago',
          detalle:
              'Marca las notas como pagadas y las pasa al histórico. '
              'Esta acción no se puede deshacer desde la aplicación.',
          textoBoton: 'Ejecutar pago',
          icono: Icons.payments_outlined,
          destructivo: true,
          enProceso: accion.enProceso,
          alPulsar: () => _ejecutar(context, ref),
        ),
        if (accion.huboError) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: ComisionesTema.brControl,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 20, color: cs.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    accion.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String get _tipo =>
      periodo.esInterno == 1 ? 'vendedores internos' : 'vendedores externos';

  String get _periodoTexto =>
      '${periodo.mes.toString().padLeft(2, '0')}/${periodo.anio}';

  Future<void> _cargar(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .cargarNotas(
          mes: periodo.mes,
          anio: periodo.anio,
          esInterno: periodo.esInterno,
          audUsuario: uid,
        );

    if (!context.mounted) return;
    final estado = ref.read(comisionesAccionesProvider);
    if (ok) {
      mostrarAviso(
        context,
        'Notas cargadas: ${estado.idGenerado ?? 0}. '
        'Revise el preliminar antes de ejecutar.',
        tono: TonoAviso.aviso,
      );
    }
  }

  Future<void> _ejecutar(BuildContext context, WidgetRef ref) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.warning_amber_outlined, color: cs.error, size: 32),
          title: const Text('Ejecutar el pago del período'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Va a ejecutar las comisiones de $_tipo del período '
                '$_periodoTexto.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Las notas quedan marcadas como pagadas y pasan al histórico. '
                'La aplicación no puede revertirlo: deshacerlo requiere '
                'intervención directa sobre la base de datos.',
                style: Theme.of(
                  ctx,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirme que revisó el preliminar de este período.',
                style: Theme.of(
                  ctx,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.error,
                foregroundColor: cs.onError,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, ejecutar el pago'),
            ),
          ],
        );
      },
    );

    if (confirmado != true || !context.mounted) return;

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .ejecutarPago(
          mes: periodo.mes,
          anio: periodo.anio,
          esInterno: periodo.esInterno,
          audUsuario: uid,
        );

    if (!context.mounted) return;
    final estado = ref.read(comisionesAccionesProvider);
    if (ok) {
      avisar(
        context,
        'Período $_periodoTexto ejecutado. '
        'Registros generados: ${estado.idGenerado ?? 0}.',
      );
    }
  }
}

// ── Piezas ────────────────────────────────────────────────────────────

class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.titulo,
    required this.detalle,
    required this.textoBoton,
    required this.icono,
    required this.enProceso,
    required this.alPulsar,
    this.destructivo = false,
  });

  final String numero;
  final String titulo;
  final String detalle;
  final String textoBoton;
  final IconData icono;
  final bool enProceso;
  final bool destructivo;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: ComisionesTema.brContenedor,
        side: BorderSide(color: destructivo ? cs.error : cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor:
                  destructivo ? cs.errorContainer : cs.primaryContainer,
              child: Text(
                numero,
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      destructivo ? cs.onErrorContainer : cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detalle,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child:
                        destructivo
                            ? FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.error,
                                foregroundColor: cs.onError,
                              ),
                              onPressed: enProceso ? null : alPulsar,
                              icon:
                                  enProceso
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Icon(icono, size: 18),
                              label: Text(textoBoton),
                            )
                            : FilledButton.tonalIcon(
                              onPressed: enProceso ? null : alPulsar,
                              icon:
                                  enProceso
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Icon(icono, size: 18),
                              label: Text(textoBoton),
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

class _Metrica extends StatelessWidget {
  const _Metrica({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(valor, style: ComisionesTema.numeroTotal(context)),
      ],
    );
  }
}
