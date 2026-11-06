/// Detalle de un reporte de horas extra: dónde está (pasos o motivo del
/// rechazo), la jornada con el origen de cada hora, los montos del SP, dónde
/// marcó, los tramos, el desglose y el historial, según lo que deje ver el SP
/// (D38), en el panel ([mostrarPanelHex]).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_linea_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_reporte_tramo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_donde_marco.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_tramos_reporte.dart';

/// Abre el detalle del reporte [idReporte] en el panel del módulo: hoja en el
/// teléfono, diálogo en el ancho.
Future<void> mostrarDetalleReporteHex(BuildContext context, BigInt idReporte) =>
    mostrarPanelHex(
      context,
      panel:
          (control) =>
              _DetalleReporteHex(idReporte: idReporte, control: control),
    );

/// El contenido, igual en la hoja y en el diálogo ([PanelHex]).
class _DetalleReporteHex extends ConsumerWidget {
  const _DetalleReporteHex({required this.idReporte, required this.control});

  final BigInt idReporte;
  final ScrollController? control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final secciones = ref
        .watch(hexDetalleReporteProvider(idReporte))
        .when(
          skipLoadingOnReload: true,
          loading: () => const [_CargandoHex('Cargando el reporte…')],
          error:
              (e, _) => [
                SizedBox(
                  height: hexAltoEstado,
                  child: vistaErrorHex(
                    e,
                    reintentar:
                        () => ref.invalidate(
                          hexDetalleReporteProvider(idReporte),
                        ),
                  ),
                ),
              ],
          data:
              (r) =>
                  r == null
                      ? const [
                        SizedBox(
                          height: hexAltoEstado,
                          child: MensajeVacio(
                            icono: Icons.search_off,
                            titulo: 'No se encontró el reporte',
                            detalle: 'Ya no existe o no tienes acceso a él.',
                          ),
                        ),
                      ]
                      : _secciones(context, r),
        );
    return PanelHex(
      control: control,
      cabecera: Text('Detalle del reporte', style: context.tituloSeccion()),
      hijos: secciones,
    );
  }

  List<Widget> _secciones(BuildContext context, HexReporteEntity r) {
    final motivo = r.motivo?.trim() ?? '';
    final cerrado = reporteCerradoHex(r.estado);
    final avanza = pasosHechosHex(r.estado) != null;
    return [
      // Rechazado o anulado: el motivo va primero, antes que todo.
      if (cerrado) ...[AvisoRechazoHex(r), const SizedBox(height: Esp.l)],
      // Adenda D37: sin salida marcada, el aviso del SP va arriba.
      if (AvisoSalidaHex.hay(r)) ...[
        AvisoSalidaHex(r),
        const SizedBox(height: Esp.l),
      ],
      _CabeceraHex(r),
      if (avanza) ...[const SizedBox(height: Esp.l), AvanceReporteHex(r)],
      const SizedBox(height: Esp.l),
      _JornadaHex(r),
      if (r.avisoBiometrico)
        const NotaDelDato(
          texto: 'El biométrico registra otra hora; revisa antes de pagar.',
          tono: TonoNota.aviso,
          icono: Icons.fingerprint,
        ),
      // D38: sin `verMontos` el dinero llega nulo y no se dibuja.
      if (r.verMontos) ...[const SizedBox(height: Esp.l), _MontosHex(r)],
      if (motivo.isNotEmpty) ...[
        const SizedBox(height: Esp.l),
        const TituloSeccionHex('Motivo', icono: Icons.notes_outlined),
        const SizedBox(height: Esp.xs),
        Text(motivo),
      ],
      // D30: solo si el detalle trae al menos un par lat/lon de la app.
      if (r.tieneUbicacion) ...[
        const SizedBox(height: Esp.xl),
        DondeMarcoHex(r),
      ],
      // D38: sin la bandera no se piden (el SP respondería 400 o 403).
      if (r.puedeVerDetalle) ...[
        const SizedBox(height: Esp.xl),
        _TramosHex(idReporte),
        const SizedBox(height: Esp.xl),
        _LineasHex(idReporte),
      ],
      if (r.verHistorial) ...[
        const SizedBox(height: Esp.xl),
        _HistorialHex(idReporte),
      ],
    ];
  }
}

class _CargandoHex extends StatelessWidget {
  const _CargandoHex(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Esp.m),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: Esp.s),
        Text(texto, style: context.apagado()),
      ],
    ),
  );
}

/// Quién, qué jornada y en qué estado está.
class _CabeceraHex extends StatelessWidget {
  const _CabeceraHex(this.r);

  final HexReporteEntity r;

  @override
  Widget build(BuildContext context) {
    final apoyo = 'Jornada ${fechaHex(r.fechaJornada)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          oGuionHex(r.nombreEmpleado),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: Peso.titulo),
        ),
        const SizedBox(height: Esp.xs),
        Text(apoyo, style: context.apagado()),
        if ((r.nombreSucursal ?? '').trim().isNotEmpty)
          Text(oGuionHex(r.nombreSucursal), style: context.apagado()),
        const SizedBox(height: Esp.s),
        Wrap(
          spacing: Esp.xs,
          runSpacing: Esp.xs,
          children: [
            EtiquetaEstadoHex(r.estado, r.estadoTexto),
            if (r.tipo.isNotEmpty || r.tipoTexto.isNotEmpty)
              TipoReporteHex(r.tipo, r.tipoTexto),
            if (r.tipoDia.isNotEmpty || r.tipoDiaTexto.isNotEmpty)
              TipoDiaHex(r.tipoDia, r.tipoDiaTexto),
            if (r.esEditado) const EtiquetaEditadoHex(),
          ],
        ),
      ],
    );
  }
}

/// La jornada como una tarjeta de marcación: inicio y fin en cifras grandes
/// con su sello de origen. Debajo de la flecha va el resumen de tiempo del SP
/// (D36); si no viene, las horas pagables.
class _JornadaHex extends StatelessWidget {
  const _JornadaHex(this.r);

  final HexReporteEntity r;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resumen = r.resumenTiempo?.trim() ?? '';
    final extremos = _extremos(context, conHoras: resumen.isEmpty);
    return Container(
      padding: const EdgeInsets.all(Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child:
          resumen.isEmpty
              ? extremos
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  extremos,
                  const SizedBox(height: Esp.m),
                  Divider(height: 1, color: cs.outlineVariant),
                  const SizedBox(height: Esp.m),
                  Text(
                    resumen,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
    );
  }

  Widget _extremos(BuildContext context, {required bool conHoras}) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ExtremoHex(
            rotulo: 'Inicio',
            hora: r.inicio,
            origen: r.origenInicio,
            jornada: r.fechaJornada,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.s, Esp.l, Esp.s, 0),
          child: Column(
            children: [
              Icon(Icons.arrow_forward, size: 20, color: cs.onSurfaceVariant),
              if (conHoras) ...[
                const SizedBox(height: Esp.xs),
                Text(
                  horasHex(r.horasPagables),
                  style: estiloCifrasHex(
                    Theme.of(context).textTheme.labelMedium,
                  )?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _ExtremoHex(
            rotulo: 'Fin',
            hora: r.fin,
            origen: r.origenFin,
            jornada: r.fechaJornada,
            alFinal: true,
          ),
        ),
      ],
    );
  }
}

class _ExtremoHex extends StatelessWidget {
  const _ExtremoHex({
    required this.rotulo,
    required this.hora,
    required this.origen,
    required this.jornada,
    this.alFinal = false,
  });

  final String rotulo;
  final DateTime? hora;
  final String? origen;
  final DateTime? jornada;
  final bool alFinal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final h = hora;
    final otroDia = otroDiaHex(h, jornada);
    return Column(
      crossAxisAlignment:
          alFinal ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: t.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Esp.xs),
        Text(
          relojHex(h),
          style: estiloCifrasHex(t.headlineSmall, fuerte: true),
        ),
        if (otroDia) Text(fechaHex(h), style: context.apagado()),
        const SizedBox(height: Esp.xs),
        OrigenHoraHex(origen, detallado: true, alFinal: alFinal),
      ],
    );
  }
}

/// Los montos tal como los calculó el SP; la app no hace cuentas.
class _MontosHex extends StatelessWidget {
  const _MontosHex(this.r);

  final HexReporteEntity r;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Esp.xl,
    runSpacing: Esp.m,
    crossAxisAlignment: WrapCrossAlignment.end,
    children: [
      _CifraHex(rotulo: 'Por horas', valor: bsHex(r.montoHoras)),
      _CifraHex(rotulo: 'Por comidas', valor: bsHex(r.montoComidas)),
      _CifraHex(rotulo: 'Total', valor: bsHex(r.montoTotal), fuerte: true),
      if (r.esProvisional)
        const EtiquetaProvisionalHex(texto: 'Monto provisional'),
    ],
  );
}

class _CifraHex extends StatelessWidget {
  const _CifraHex({
    required this.rotulo,
    required this.valor,
    this.fuerte = false,
  });

  final String rotulo;
  final String valor;
  final bool fuerte;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rotulo, style: context.apagado()),
        Text(
          valor,
          style: estiloCifrasHex(
            fuerte ? t.titleMedium : t.bodyLarge,
            fuerte: fuerte,
          ),
        ),
      ],
    );
  }
}

/// Una lectura secundaria del detalle: su título, la espera, el error con
/// reintento y el contenido. No tapa lo demás si falla.
class _SeccionAsincronaHex<T> extends StatelessWidget {
  const _SeccionAsincronaHex({
    required this.titulo,
    required this.icono,
    required this.valor,
    required this.reintentar,
    required this.contenido,
  });

  final String titulo;
  final IconData icono;
  final AsyncValue<T> valor;
  final VoidCallback reintentar;
  final Widget Function(T datos) contenido;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TituloSeccionHex(titulo, icono: icono),
      const SizedBox(height: Esp.s),
      valor.when(
        skipLoadingOnReload: true,
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error:
            (e, _) => NotaDelDato(
              texto: textoErrorHex(e),
              tono: TonoNota.error,
              accion: TextButton(
                onPressed: reintentar,
                child: const Text('Reintentar'),
              ),
            ),
        data: contenido,
      ),
    ],
  );
}

/// El reporte por tramos de tiempo (D36): la barra y qué ganó cada tramo.
class _TramosHex extends ConsumerWidget {
  const _TramosHex(this.idReporte);

  final BigInt idReporte;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _SeccionAsincronaHex<List<HexReporteTramoEntity>>(
        titulo: 'Por tramos',
        icono: Icons.timeline,
        valor: ref.watch(hexTramosReporteProvider(idReporte)),
        reintentar: () => ref.invalidate(hexTramosReporteProvider(idReporte)),
        contenido:
            (tramos) =>
                tramos.isEmpty
                    ? Text(
                      'Todavía no hay tramos calculados.',
                      style: context.apagado(),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BarraTramosHex(tramos),
                        const SizedBox(height: Esp.m),
                        ListaTramosHex(tramos),
                      ],
                    ),
      );
}

/// El desglose por código: tramos y comidas con su cantidad y su monto.
class _LineasHex extends ConsumerWidget {
  const _LineasHex(this.idReporte);

  final BigInt idReporte;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _SeccionAsincronaHex<List<HexReporteLineaEntity>>(
        titulo: 'Desglose',
        icono: Icons.list_alt,
        valor: ref.watch(hexLineasReporteProvider(idReporte)),
        reintentar: () => ref.invalidate(hexLineasReporteProvider(idReporte)),
        contenido:
            (lineas) =>
                lineas.isEmpty
                    ? Text(
                      'Todavía no hay líneas calculadas.',
                      style: context.apagado(),
                    )
                    : Column(
                      children: [
                        for (var i = 0; i < lineas.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          _LineaHex(lineas[i]),
                        ],
                      ],
                    ),
      );
}

class _LineaHex extends StatelessWidget {
  const _LineaHex(this.l);

  final HexReporteLineaEntity l;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cantidad =
        l.concepto == 'TRAMO'
            ? horasHex(l.cantidad)
            : '× ${l.cantidad.round()}';
    // La vista del encargado trae la línea sin dinero (D38): no se dibuja.
    final apoyo = [
      if (l.multiplicador != null) '×${decimalHex(l.multiplicador)}',
      if (l.valorUnitario != null) '${bsHex(l.valorUnitario)} c/u',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: CodigoHex(
                l.codigo,
                familia: switch (l.concepto) {
                  'TRAMO' => FamiliaCodigoHex.tramo,
                  'COMIDA' => FamiliaCodigoHex.comida,
                  _ => null,
                },
                multiplicador: l.multiplicador,
                explicar: true,
              ),
            ),
          ),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(oGuionHex(l.leyenda), style: t.bodyMedium),
                if (apoyo.isNotEmpty)
                  Text(apoyo, style: estiloCifrasHex(context.apagado())),
              ],
            ),
          ),
          const SizedBox(width: Esp.s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (l.monto != null)
                Text(
                  bsHex(l.monto),
                  style: estiloCifrasHex(t.bodyMedium, fuerte: true),
                ),
              Text(cantidad, style: estiloCifrasHex(context.apagado())),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quién hizo qué y cuándo, como una línea de tiempo.
class _HistorialHex extends ConsumerWidget {
  const _HistorialHex(this.idReporte);

  final BigInt idReporte;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => _SeccionAsincronaHex<List<HexReporteEventoEntity>>(
    titulo: 'Historial',
    icono: Icons.history,
    valor: ref.watch(hexHistorialReporteProvider(idReporte)),
    reintentar: () => ref.invalidate(hexHistorialReporteProvider(idReporte)),
    contenido:
        (eventos) =>
            eventos.isEmpty
                ? Text('Sin movimientos todavía.', style: context.apagado())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < eventos.length; i++)
                      _EventoHex(eventos[i], ultimo: i == eventos.length - 1),
                  ],
                ),
  );
}

class _EventoHex extends StatelessWidget {
  const _EventoHex(this.e, {required this.ultimo});

  final HexReporteEventoEntity e;
  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final cambio = cambioHex(e.valorAnterior, e.valorNuevo);
    final observacion = e.observacion?.trim() ?? '';
    // El punto va sobre la línea: un Stack sin recorte deja que lo pise.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 5),
          padding: EdgeInsets.only(left: Esp.l, bottom: ultimo ? 0 : Esp.l),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: ultimo ? Colors.transparent : cs.outlineVariant,
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fechaHoraHex(e.fecha),
                style: estiloCifrasHex(context.apagado()),
              ),
              Text(
                e.tipoTexto.isEmpty ? e.tipo : e.tipoTexto,
                style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
              ),
              Text(oGuionHex(e.nombreActor), style: context.apagado()),
              if (cambio.isNotEmpty) ...[
                const SizedBox(height: Esp.xs),
                Text(cambio, style: estiloCifrasHex(t.bodySmall)),
              ],
              if (observacion.isNotEmpty) ...[
                const SizedBox(height: Esp.xs),
                Text(
                  observacion,
                  style: t.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 3,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: acentoTonoHex(context, tonoEventoHex(e.tipo)),
              shape: BoxShape.circle,
              border: Border.all(color: cs.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
