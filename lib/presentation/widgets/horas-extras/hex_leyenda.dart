/// Leyenda de códigos del módulo Horas Extras: tramos y comidas vigentes hoy,
/// con su ícono y color. A la vista desde [hexAnchoTabla]; por debajo, una
/// fila que abre una hoja. Cada código también se explica solo al tocarlo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_reporte_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_comida_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_leyenda_codigos_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_planilla_anexo_entity.dart';
import 'package:bosque_flutter/domain/entities/hex_tramo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_colores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_escrituras.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_formatos.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_piezas.dart';

/// Qué significa cada código de la planilla, para ponerla al pie de una
/// pantalla. Lee `hexLeyendaCodigosProvider` también en el angosto: al abrir
/// la hoja la leyenda ya está lista.
class LeyendaHex extends ConsumerWidget {
  const LeyendaHex({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hexLeyendaCodigosProvider);
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < hexAnchoTabla) return const _FilaLeyendaHex();
        return DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Esquina.media),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: const Padding(
            padding: EdgeInsets.all(Esp.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TituloLeyendaHex(),
                SizedBox(height: Esp.m),
                _ContenidoLeyendaHex(enColumnas: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// En el angosto: una sola fila de alto fijo que abre la hoja con todo.
class _FilaLeyendaHex extends StatelessWidget {
  const _FilaLeyendaHex();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      shape: contornoSuperficie(cs),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => abrirLeyendaHex(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.l,
              vertical: Esp.s,
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, size: 20, color: cs.primary),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: Text(
                    'Leyenda de códigos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.tituloSeccion(),
                  ),
                ),
                Icon(Icons.expand_less, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La leyenda completa en una hoja desplazable (también desde el encabezado:
/// «¿Qué significan los códigos?»).
Future<void> abrirLeyendaHex(BuildContext context) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder:
        (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 1,
          builder:
              (context, control) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.s),
                    child: _TituloLeyendaHex(),
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: control,
                      child: ListView(
                        controller: control,
                        padding: EdgeInsets.fromLTRB(
                          Esp.l,
                          0,
                          Esp.l,
                          Esp.xl + MediaQuery.viewPaddingOf(context).bottom,
                        ),
                        children: const [
                          _ContenidoLeyendaHex(enColumnas: false),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
        ),
  );
}

class _TituloLeyendaHex extends StatelessWidget {
  const _TituloLeyendaHex();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Esp.s,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Icon(
        Icons.menu_book_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
      Text('Leyenda de códigos', style: context.tituloSeccion()),
      Text('vigente hoy', style: context.apagado()),
    ],
  );
}

/// La espera, el error con reintento o los tramos y comidas.
class _ContenidoLeyendaHex extends ConsumerWidget {
  const _ContenidoLeyendaHex({required this.enColumnas});

  final bool enColumnas;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(hexLeyendaCodigosProvider)
      .when(
        skipLoadingOnReload: true,
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error:
            (e, _) => NotaDelDato(
              texto: textoErrorHex(e),
              tono: TonoNota.error,
              accion: TextButton(
                onPressed: () => ref.invalidate(hexLeyendaCodigosProvider),
                child: const Text('Reintentar'),
              ),
            ),
        data:
            (l) =>
                (l == null || (l.tramos.isEmpty && l.comidas.isEmpty))
                    ? const NotaDelDato(
                      texto: 'No hay tramos ni comidas vigentes hoy.',
                    )
                    : _CuerpoLeyendaHex(leyenda: l, enColumnas: enColumnas),
      );
}

class _CuerpoLeyendaHex extends StatelessWidget {
  const _CuerpoLeyendaHex({required this.leyenda, required this.enColumnas});

  final HexLeyendaCodigosEntity leyenda;
  final bool enColumnas;

  @override
  Widget build(BuildContext context) {
    final tramos = _TramosLeyendaHex(tramos: leyenda.tramos);
    final comidas = _ComidasLeyendaHex(comidas: leyenda.comidas);
    if (!enColumnas) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [tramos, const SizedBox(height: Esp.l), comidas],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: tramos),
        const SizedBox(width: Esp.xl),
        Expanded(child: comidas),
      ],
    );
  }
}

class _TramosLeyendaHex extends StatelessWidget {
  const _TramosLeyendaHex({required this.tramos});

  final List<HexTramoEntity> tramos;

  @override
  Widget build(BuildContext context) {
    final porDia = <String, List<HexTramoEntity>>{};
    for (final t in tramos) {
      porDia.putIfAbsent(t.tipoDia, () => []).add(t);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSeccionHex('Horas extra', icono: Icons.schedule),
        for (final MapEntry(key: dia, value: lista) in porDia.entries) ...[
          const SizedBox(height: Esp.s),
          Text(
            tipoDiaHex(dia),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          for (final t in lista)
            _EntradaLeyendaHex(
              codigo: t.codigo,
              titulo: oGuionHex(t.leyenda),
              detalle: _detalleTramoHex(t),
              familia: FamiliaCodigoHex.tramo,
              multiplicador: t.multiplicador,
            ),
        ],
      ],
    );
  }
}

class _ComidasLeyendaHex extends StatelessWidget {
  const _ComidasLeyendaHex({required this.comidas});

  final List<HexComidaEntity> comidas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TituloSeccionHex('Comidas', icono: Icons.restaurant_outlined),
        const SizedBox(height: Esp.xs),
        for (final c in comidas) ...[
          _EntradaLeyendaHex(
            codigo: c.codigo,
            titulo: _nombreComidaHex(c.leyenda, c.activo),
            detalle: _detalleComidaHex(c),
            inactiva: !c.activo,
            familia: FamiliaCodigoHex.comida,
          ),
          _EntradaLeyendaHex(
            codigo: c.codigoDoble,
            titulo: _nombreComidaHex(c.leyendaDoble, c.activo),
            detalle: _detalleDobleHex(c),
            // D40: sin doble en esta vigencia, la doble va apagada.
            inactiva: !c.activo || !c.conDoble,
            familia: FamiliaCodigoHex.comida,
          ),
        ],
      ],
    );
  }
}

/// La leyenda congelada de una planilla ejecutada (`planilla/leyenda`): cada
/// código con el multiplicador o el valor con que se pagó. Horas y comidas en
/// dos columnas desde [hexAnchoTabla]; por debajo, una sobre la otra.
class LeyendaPlanillaHex extends StatelessWidget {
  const LeyendaPlanillaHex(this.codigos, {super.key});

  final List<HexCodigoLeyendaEntity> codigos;

  /// `×1,5` de un tramo, `Bs 15,00` de una comida: lo que mandó el SP.
  static String _valor(HexCodigoLeyendaEntity c) => [
    if (c.multiplicador != null) '×${decimalHex(c.multiplicador)}',
    if (c.valorUnitario != null) bsHex(c.valorUnitario),
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget bloque(String titulo, Iterable<HexCodigoLeyendaEntity> lista) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: context.tituloSeccion()),
            const SizedBox(height: Esp.xs),
            for (final c in lista)
              _EntradaLeyendaHex(
                codigo: c.codigo,
                titulo: oGuionHex(c.leyenda),
                detalle: oGuionHex(_valor(c)),
                familia: switch (c.concepto) {
                  'TRAMO' => FamiliaCodigoHex.tramo,
                  'COMIDA' => FamiliaCodigoHex.comida,
                  _ => null,
                },
                multiplicador: c.multiplicador,
              ),
          ],
        );
    final horas = codigos.where((c) => c.concepto == 'TRAMO');
    final comidas = codigos.where((c) => c.concepto == 'COMIDA');
    final otros = codigos.where(
      (c) => c.concepto != 'TRAMO' && c.concepto != 'COMIDA',
    );
    final bloques = [
      if (horas.isNotEmpty) bloque('Horas extra', horas),
      if (comidas.isNotEmpty) bloque('Comidas', comidas),
      if (otros.isNotEmpty) bloque('Otros', otros),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: LayoutBuilder(
          builder:
              (context, c) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: Esp.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 18,
                        color: cs.primary,
                      ),
                      Text(
                        'Leyenda de códigos',
                        style: context.tituloSeccion(),
                      ),
                      Text(
                        'como se pagó en esta planilla',
                        style: context.apagado(),
                      ),
                    ],
                  ),
                  const SizedBox(height: Esp.m),
                  if (bloques.isEmpty)
                    const Text('La planilla no tiene códigos registrados.')
                  else if (c.maxWidth >= hexAnchoTabla - 2 * Esp.l)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < bloques.length; i++) ...[
                          if (i > 0) const SizedBox(width: Esp.xl),
                          Expanded(child: bloques[i]),
                        ],
                      ],
                    )
                  else
                    for (var i = 0; i < bloques.length; i++) ...[
                      if (i > 0) const SizedBox(height: Esp.l),
                      bloques[i],
                    ],
                ],
              ),
        ),
      ),
    );
  }
}

class _EntradaLeyendaHex extends StatelessWidget {
  const _EntradaLeyendaHex({
    required this.codigo,
    required this.titulo,
    required this.detalle,
    this.inactiva = false,
    this.familia,
    this.multiplicador,
  });

  final String codigo;
  final String titulo;
  final String detalle;
  final FamiliaCodigoHex? familia;
  final double? multiplicador;

  /// Una comida inactiva no se paga: va en el tono secundario del tema.
  final bool inactiva;

  @override
  Widget build(BuildContext context) {
    final secundario = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: CodigoHex(
                codigo,
                apagado: inactiva,
                familia: familia,
                multiplicador: multiplicador,
              ),
            ),
          ),
          const SizedBox(width: Esp.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: inactiva ? secundario : null,
                  ),
                ),
                Text(detalle, style: estiloCifrasHex(context.apagado())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `×1,5 · 20:00–24:00`: el factor y el horario de un tramo.
String _detalleTramoHex(HexTramoEntity t) =>
    '×${decimalHex(t.multiplicador)} · '
    '${horaTramoHex(t.horaDesde)}–${horaTramoHex(t.horaHasta, esFin: true)}';

/// Detalle de la comida doble: su monto, o un texto si el servidor no lo manda (D38).
String _detalleDobleHex(HexComidaEntity c) =>
    c.montoDoble == null ? 'Segunda hora con comida' : bsHex(c.montoDoble);

/// `Bs 15,00 · 12:00–14:00`: el monto y la ventana de una comida simple y,
/// si el SP lo manda, cuánto dura y si hay doble (D40).
String _detalleComidaHex(HexComidaEntity c) {
  final ventana =
      c.horaDesde == null || c.horaHasta == null
          ? 'sin ventana'
          : '${horaTramoHex(c.horaDesde)}–${horaTramoHex(c.horaHasta, esFin: true)}';
  final duracion = c.textoDuracion?.trim() ?? '';
  return [
    // D38: a quien no ve dinero el servidor le manda el monto en null.
    if (c.monto != null) bsHex(c.monto),
    ventana,
    if (duracion.isNotEmpty) duracion,
  ].join(' · ');
}

String _nombreComidaHex(String leyenda, bool activo) =>
    activo ? leyenda : '$leyenda (inactiva)';

// ═══════════════════════════════════════════════════════════════════════════
// ¿QUÉ SIGNIFICA ESTE CÓDIGO?
// ═══════════════════════════════════════════════════════════════════════════

/// Hoja corta con lo que significa [codigo] hoy (tramo o comida), leído de
/// `hexLeyendaCodigosProvider`, y el paso a la leyenda completa.
Future<void> mostrarSignificadoCodigoHex(BuildContext context, String codigo) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder:
        (hoja) => _SignificadoCodigoHex(
          codigo: codigo,
          alVerTodos: () {
            Navigator.of(hoja).pop();
            if (context.mounted) abrirLeyendaHex(context);
          },
        ),
  );
}

class _SignificadoCodigoHex extends ConsumerWidget {
  const _SignificadoCodigoHex({required this.codigo, required this.alVerTodos});

  final String codigo;
  final VoidCallback alVerTodos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contenido = ref
        .watch(hexLeyendaCodigosProvider)
        .when(
          skipLoadingOnReload: true,
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error:
              (e, _) => NotaDelDato(
                texto: textoErrorHex(e),
                tono: TonoNota.error,
                accion: TextButton(
                  onPressed: () => ref.invalidate(hexLeyendaCodigosProvider),
                  child: const Text('Reintentar'),
                ),
              ),
          data: (l) => _CuerpoSignificadoHex(codigo: codigo, leyenda: l),
        );
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Esp.l,
        0,
        Esp.l,
        Esp.xl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const TituloSeccionHex(
            '¿Qué significa este código?',
            icono: Icons.help_outline,
          ),
          const SizedBox(height: Esp.m),
          contenido,
          const SizedBox(height: Esp.m),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: alVerTodos,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Ver todos los códigos'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Las filas de la leyenda que llevan [codigo]: un tramo por tipo de día, o
/// la comida simple o doble. Si hoy no está vigente, se dice.
class _CuerpoSignificadoHex extends StatelessWidget {
  const _CuerpoSignificadoHex({required this.codigo, required this.leyenda});

  final String codigo;
  final HexLeyendaCodigosEntity? leyenda;

  @override
  Widget build(BuildContext context) {
    final l = leyenda;
    final tramos = [
      for (final t in l?.tramos ?? const <HexTramoEntity>[])
        if (t.codigo == codigo) t,
    ];
    final comidas = [
      for (final c in l?.comidas ?? const <HexComidaEntity>[])
        if (c.codigo == codigo)
          _EntradaLeyendaHex(
            codigo: c.codigo,
            titulo: _nombreComidaHex(c.leyenda, c.activo),
            detalle: _detalleComidaHex(c),
            inactiva: !c.activo,
            familia: FamiliaCodigoHex.comida,
          )
        else if (c.codigoDoble == codigo)
          _EntradaLeyendaHex(
            codigo: c.codigoDoble,
            titulo: _nombreComidaHex(c.leyendaDoble, c.activo),
            detalle: _detalleDobleHex(c),
            inactiva: !c.activo,
            familia: FamiliaCodigoHex.comida,
          ),
    ];
    if (tramos.isEmpty && comidas.isEmpty) {
      return NotaDelDato(
        texto:
            'El código $codigo no está entre los vigentes hoy. Revisa la '
            'leyenda completa.',
      );
    }
    final rotulo = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (tramos.isNotEmpty) ...[
          Text('Horas extra', style: rotulo),
          for (final t in tramos)
            _EntradaLeyendaHex(
              codigo: t.codigo,
              titulo: oGuionHex(t.leyenda),
              detalle: '${tipoDiaHex(t.tipoDia)} · ${_detalleTramoHex(t)}',
              familia: FamiliaCodigoHex.tramo,
              multiplicador: t.multiplicador,
            ),
        ],
        if (comidas.isNotEmpty) ...[
          if (tramos.isNotEmpty) const SizedBox(height: Esp.s),
          Text('Comida', style: rotulo),
          ...comidas,
        ],
      ],
    );
  }
}
