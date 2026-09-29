import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/formato_comision.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';

/// Detalle por ítem de lo que YA se pagó, con foco en lo EXCLUIDO (la mayoría:
/// 15 de cada 19 líneas medidas). Nunca muestra un cero pelado: el corte
/// (`tcom_pagadoItemCorte`, campo `lectura`) distingue «no había nada» de «nunca
/// se congeló»; si no se pudo leer, se dice eso y no que la base no congeló nada.
class DialogoItemsPagados extends ConsumerStatefulWidget {
  const DialogoItemsPagados({super.key, required this.filtro, this.subtitulo});

  /// Período y alcance. SP: `@mes`, `@anio`, `@esInterno` y opcionales
  /// `@idPagado` (null = período entero), `@docNum` y `@origen`, que aplican en
  /// las ramas 'L' (listado) y 'R' (resumen). Elegir una nota manda `@docNum` +
  /// `@origen` a las DOS ramas; `@origen` siempre viaja: `docNum` se repite entre
  /// empresas (198 casos por período) y solo `@origen` separa ESPPAPEL de las
  /// otras tres (`esInterno = 1`). «Solo lo excluido» NO va al SP: es filtro local.
  final FiltroItemsPagados filtro;

  /// Contexto de quien abre: «ejecutado el 12/08/2026», por ejemplo. Va debajo
  /// del título para que el diálogo se entienda sin volver a la pantalla.
  final String? subtitulo;

  @override
  ConsumerState<DialogoItemsPagados> createState() =>
      _DialogoItemsPagadosState();
}

/// Una nota del período: el par (origen, docNum), no el número solo, porque
/// `docNum` se repite entre empresas (198 casos en el mismo período) y un
/// selector por número mezclaría dos notas. Lleva == y hashCode: es el `value`
/// de un DropdownButton, que compara por igualdad.
@immutable
class _NotaPagada {
  const _NotaPagada({required this.docNum, this.origen});

  final int docNum;
  final String? origen;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NotaPagada && other.docNum == docNum && other.origen == origen;

  @override
  int get hashCode => Object.hash(docNum, origen);
}

class _DialogoItemsPagadosState extends ConsumerState<DialogoItemsPagados> {
  /// Arranca en TRUE: lo excluido es la mayoría y era lo que no existía en
  /// ningún lado (lo que descontó ya se veía en el reporte).
  bool _soloExcluidos = true;

  /// Nota elegida, o null para todo el período.
  _NotaPagada? _nota;

  @override
  Widget build(BuildContext context) {
    final esMovil = ResponsiveUtilsBosque.isMobile(context);

    // El período tal como lo pidió quien abre. Se observa SIEMPRE: de esta lista
    // salen las notas del selector y, al ser autoDispose, dejar de observarla
    // haría bajar el mes otra vez al volver a «Todas las notas».
    final periodo = widget.filtro;
    final indice = ref.watch(itemsPagadosProvider(periodo));

    final nota = _nota;
    final filtro =
        nota == null
            ? periodo
            : periodo.copyWith(docNum: nota.docNum, origen: nota.origen);

    // Sin nota elegida el filtro ES el del período, así que `datos` e `indice`
    // son la misma entrada del cache y no hay una segunda llamada.
    final datos =
        nota == null ? indice : ref.watch(itemsPagadosProvider(filtro));

    // El resumen va con la MISMA clave que el listado: si iba clavado al período,
    // con una nota elegida el titular seguía contando el mes entero.
    final resumen = ref.watch(resumenItemsPagadosProvider(filtro));

    // El corte es por período (ni la nota ni el filtro lo cambian): clave propia,
    // para no pedirlo de nuevo al tocar un filtro del listado.
    final clave = ClavePeriodo(
      mes: widget.filtro.mes,
      anio: widget.filtro.anio,
      esInterno: widget.filtro.esInterno,
    );
    final corte = ref.watch(corteItemsPagadosProvider(clave));

    // El tope de ComisionesTema.anchoTabla dejaba tres columnas afuera y el
    // scroll horizontal no dibuja barra en web (inalcanzables). Con el ancho de
    // pantalla menos el margen entran las nueve en un monitor común.
    final pantalla = MediaQuery.sizeOf(context);
    final margen = esMovil ? 12.0 : 40.0;

    return Dialog(
      insetPadding: EdgeInsets.all(margen),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: pantalla.width - margen * 2,
          maxHeight: pantalla.height - margen * 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Encabezado(
              filtro: widget.filtro,
              subtitulo: widget.subtitulo,
              esMovil: esMovil,
            ),
            const Divider(height: 1),
            Flexible(
              child: datos.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.all(ComisionesTema.esp4),
                      child: EsqueletoTabla(columnas: 5, filas: 5),
                    ),
                error:
                    (e, _) => EstadoVista.error(
                      context,
                      error: e,
                      alReintentar:
                          () => ref.invalidate(itemsPagadosProvider(filtro)),
                    ),
                data:
                    (items) => _Cuerpo(
                      items: items,
                      notas: _notasDe(indice.valueOrNull ?? items),
                      notaElegida: nota,
                      resumen: resumen,
                      corte: corte,
                      soloExcluidos: _soloExcluidos,
                      esMovil: esMovil,
                      alCambiarExcluidos:
                          (v) => setState(() => _soloExcluidos = v),
                      alCambiarNota: (v) => setState(() => _nota = v),
                      alReintentarResumen:
                          () => ref.invalidate(
                            resumenItemsPagadosProvider(filtro),
                          ),
                      alReintentarCorte:
                          () =>
                              ref.invalidate(corteItemsPagadosProvider(clave)),
                    ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las notas que hay para elegir, en el mismo orden en que las devuelve el SP
/// (`ORDER BY origen, docNum`).
List<_NotaPagada> _notasDe(List<PagadoItemEntity> items) {
  final vistas = <_NotaPagada>{};
  for (final i in items) {
    final d = i.docNum;
    if (d != null) vistas.add(_NotaPagada(docNum: d, origen: i.origen));
  }
  return vistas.toList()..sort((a, b) {
    final porOrigen = (a.origen ?? '').compareTo(b.origen ?? '');
    return porOrigen != 0 ? porOrigen : a.docNum.compareTo(b.docNum);
  });
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.filtro,
    required this.subtitulo,
    required this.esMovil,
  });

  final FiltroItemsPagados filtro;
  final String? subtitulo;
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, esMovil ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalle congelado del pago',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo ??
                'Lo que quedó escrito al ejecutar el período, ítem por ítem.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: ComisionesTema.esp2,
            runSpacing: ComisionesTema.esp2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ChipEstado(texto: _periodo(filtro)),
              ChipEstado(
                texto: filtro.esInterno == 1 ? 'Internos' : 'Externos',
              ),
              if (filtro.idPagado != null)
                ChipEstado(texto: 'Pago ${filtro.idPagado}'),
            ],
          ),
        ],
      ),
    );
  }
}

String _periodo(FiltroItemsPagados f) =>
    '${f.mes.toString().padLeft(2, '0')}/${f.anio}';

/// Cuánto del alto del cuerpo puede ocupar el resumen antes de desplazarse. El
/// máximo real son CINCO filas (DESCONTO y cuatro motivos de exclusión) y miden
/// más que un teléfono: suelto en el Column desbordaba (360x640: 29px con tres
/// filas, 139px con cinco; 320x568 con cinco: 324px). Algo MENOS de la mitad:
/// debajo aún deben entrar la barra de filtros y algo de lista.
const double _fraccionResumen = 0.4;

class _Cuerpo extends StatefulWidget {
  const _Cuerpo({
    required this.items,
    required this.notas,
    required this.notaElegida,
    required this.resumen,
    required this.corte,
    required this.soloExcluidos,
    required this.esMovil,
    required this.alCambiarExcluidos,
    required this.alCambiarNota,
    required this.alReintentarResumen,
    required this.alReintentarCorte,
  });

  /// Lo que trajo el SP con el filtro vigente, SIN recortar por exclusión.
  final List<PagadoItemEntity> items;

  /// Las notas del período entero: son las que alimentan el selector.
  final List<_NotaPagada> notas;
  final _NotaPagada? notaElegida;

  /// Viajan como AsyncValue y no como valor pelado: `null` no distingue «no
  /// llegó» de «falló», y un error de red se mostraba como acusación sobre la base.
  final AsyncValue<List<PagadoItemResumenEntity>> resumen;
  final AsyncValue<PagadoItemCorteEntity?> corte;

  final bool soloExcluidos;
  final bool esMovil;
  final ValueChanged<bool> alCambiarExcluidos;
  final ValueChanged<_NotaPagada?> alCambiarNota;
  final VoidCallback alReintentarResumen;
  final VoidCallback alReintentarCorte;

  @override
  State<_Cuerpo> createState() => _CuerpoState();
}

class _CuerpoState extends State<_Cuerpo> {
  /// Controller propio del resumen: sin uno explícito, el desplazamiento interno
  /// quedaría colgado del PrimaryScrollController, que también reclaman la lista
  /// y el vacío.
  final _resumen = ScrollController();

  @override
  void dispose() {
    _resumen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    // «Solo lo excluido» se resuelve aquí y no en el SP: es un where sobre un
    // campo que ya viene en cada fila. Con el filtro en la clave del provider
    // (autoDispose), tildar el chip destruía el cache y destildar bajaba el mes.
    final visibles =
        widget.soloExcluidos
            ? items.where((i) => i.excluido).toList(growable: false)
            : items;

    // Si la nota elegida ya no está entre las del período (el índice se recargó)
    // se cae a «todas» al dibujar; cambiar el estado en el build es un bucle.
    final notaValida =
        widget.notaElegida != null && widget.notas.contains(widget.notaElegida)
            ? widget.notaElegida
            : null;

    return LayoutBuilder(
      builder: (context, limites) {
        final tope =
            limites.maxHeight.isFinite
                ? limites.maxHeight * _fraccionResumen
                : double.infinity;

        // Alto mínimo para que la lista tenga sentido: por debajo, el cuerpo
        // entero se desplaza en vez de apretar hasta desbordar. Con la barra de
        // filtros rígida, en un teléfono ACOSTADO (640x360, 800x360, 568x320) el
        // Flexible de la lista se encogía a cero y el Column reventaba, incluso
        // con el resumen vacío.
        const minimoUtil = 260.0;
        final apretado =
            limites.maxHeight.isFinite && limites.maxHeight < minimoUtil;

        final cuerpo = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // El resumen va ARRIBA: la pregunta que trae a alguien es «¿cuánto
            // quedó afuera y por qué?», y se responde con el reparto por motivo.
            _ZonaResumen(
              resumen: widget.resumen,
              esMovil: widget.esMovil,
              tope: tope,
              controlador: _resumen,
              alReintentar: widget.alReintentarResumen,
            ),
            // La barra depende de que HAYA líneas y de nada más: si dependía del
            // resumen y la rama 'R' fallaba, el vacío seguía diciendo «Quite Solo lo
            // excluido» sobre un control ausente.
            if (items.isNotEmpty) ...[
              _BarraFiltros(
                cantidad: visibles.length,
                soloExcluidos: widget.soloExcluidos,
                notas: widget.notas,
                notaElegida: notaValida,
                alCambiarExcluidos: widget.alCambiarExcluidos,
                alCambiarNota: widget.alCambiarNota,
              ),
              const Divider(height: 1),
            ],
            Flexible(
              child:
                  visibles.isEmpty
                      ? _SinItems(
                        corte: widget.corte,
                        soloExcluidos: widget.soloExcluidos,
                        itemsDelPeriodo: items.length,
                        notaElegida: notaValida,
                        alReintentar: widget.alReintentarCorte,
                        alVolverAlPeriodo:
                            notaValida == null
                                ? null
                                : () => widget.alCambiarNota(null),
                      )
                      : (widget.esMovil
                          ? _ListaTarjetas(items: visibles)
                          : _TablaItems(items: visibles)),
            ),
          ],
        );

        // Sin scroll cuando entra: un SingleChildScrollView permanente le quita
        // el alto acotado al Flexible de la lista y ésta pierde su propio scroll.
        if (!apretado) return cuerpo;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minimoUtil),
            child: cuerpo,
          ),
        );
      },
    );
  }
}

/// Los tres estados del resumen: todavía no llegó, no llegó nunca, o el período
/// no tiene nada que repartir. El del medio hay que decirlo: si no, la única
/// señal de que la rama 'R' falló es un bloque que falta.
class _ZonaResumen extends StatelessWidget {
  const _ZonaResumen({
    required this.resumen,
    required this.esMovil,
    required this.tope,
    required this.controlador,
    required this.alReintentar,
  });

  final AsyncValue<List<PagadoItemResumenEntity>> resumen;
  final bool esMovil;

  /// Tope de alto. Lo que no entra se desplaza adentro en vez de desbordar.
  final double tope;
  final ScrollController controlador;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final filas = resumen.valueOrNull;

    final Widget? contenido;
    if (resumen.hasError && filas == null) {
      contenido = _ResumenFallido(alReintentar: alReintentar);
    } else if (filas == null || filas.isEmpty) {
      // Cargando, o período sin nada que repartir: habla lo de abajo (esqueleto o
      // lectura del corte) y un bloque a medias solo agrega ruido.
      contenido = null;
    } else {
      contenido = _ResumenPorMotivo(resumen: filas, esMovil: esMovil);
    }

    if (contenido == null) return const SizedBox.shrink();

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: tope),
      child: Scrollbar(
        controller: controlador,
        child: SingleChildScrollView(controller: controlador, child: contenido),
      ),
    );
  }
}

class _ResumenFallido extends StatelessWidget {
  const _ResumenFallido({required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(ComisionesTema.esp3),
      decoration: ComisionesTema.franja(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, size: 18, color: cs.error),
          const SizedBox(width: ComisionesTema.esp2),
          Expanded(
            child: Text(
              'No se pudo leer el reparto por motivo. Las líneas de abajo son '
              'las que sí llegaron; el total de lo que quedó afuera, no.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: ComisionesTema.esp2),
          TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

/// El reparto de lo pagado entre lo que descontó y lo que no. Lleva barra
/// proporcional además de números: «15 de 19» y «79 %» se leen distinto.
class _ResumenPorMotivo extends StatelessWidget {
  const _ResumenPorMotivo({required this.resumen, required this.esMovil});

  final List<PagadoItemResumenEntity> resumen;
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Lo que descontó primero y el resto por monto: el orden cuenta la
    // historia de arriba hacia abajo.
    final filas = [...resumen]..sort((a, b) {
      if (a.descuenta != b.descuenta) return a.descuenta ? -1 : 1;
      return b.montoBs.compareTo(a.montoBs);
    });

    final total = filas.fold<int>(0, (s, r) => s + r.items);
    final excluidos = filas
        .where((r) => !r.descuenta)
        .fold<int>(0, (s, r) => s + r.items);
    final montoExcluido = filas
        .where((r) => !r.descuenta)
        .fold<double>(0, (s, r) => s + r.montoBs);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(ComisionesTema.esp3),
      decoration: ComisionesTema.franja(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // El titular es el dato, no el rótulo: sin esto hay que sumar cuatro
          // filas para saber cuánto quedó afuera. Sin exclusiones se da vuelta en
          // vez de «0 de 1 ítems no descontaron» (un cero junto a un uno parece
          // un problema).
          Text(
            _titular(total, excluidos),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          // La línea del monto solo cuando hay monto: «0.00 Bs quedaron fuera del
          // descuento» sería otro cero pelado.
          if (excluidos > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${FormatoComision.monto.format(montoExcluido)} Bs quedaron '
              'fuera del descuento por familia.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (total > 0) ...[
            const SizedBox(height: ComisionesTema.esp3),
            _BarraProporcion(filas: filas, total: total),
            const SizedBox(height: ComisionesTema.esp3),
          ],
          for (final r in filas)
            Padding(
              padding: const EdgeInsets.only(bottom: ComisionesTema.esp1),
              child: _FilaResumen(resumen: r, esMovil: esMovil),
            ),
        ],
      ),
    );
  }
}

String _titular(int total, int excluidos) {
  if (total == 0) return 'Sin ítems congelados';
  if (excluidos == 0) {
    return total == 1
        ? 'La única línea congelada descontó'
        : 'Las ${FormatoComision.entero.format(total)} líneas congeladas '
            'descontaron';
  }
  return '$excluidos de $total ítems no descontaron';
}

/// Barra apilada: descontó a la izquierda, cada motivo de exclusión después.
class _BarraProporcion extends StatelessWidget {
  const _BarraProporcion({required this.filas, required this.total});

  final List<PagadoItemResumenEntity> filas;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: ComisionesTema.brChip,
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final r in filas)
              if (r.items > 0)
                Expanded(
                  flex: r.items,
                  child: Container(
                    // Sin colores sueltos: lo descontado lleva el acento del tema
                    // y lo excluido, tonos del canal de error (único par que se
                    // distingue en las nueve semillas y en los dos modos).
                    color:
                        r.descuenta ? cs.primary : _tonoExclusion(cs, filas, r),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Los motivos de exclusión se separan por opacidad sobre el mismo canal, no por
/// matices: cuatro matices inventados dejarían de funcionar al cambiar el acento.
Color _tonoExclusion(
  ColorScheme cs,
  List<PagadoItemResumenEntity> filas,
  PagadoItemResumenEntity r,
) {
  final exclusiones = filas.where((f) => !f.descuenta).toList();
  final i = exclusiones.indexOf(r);
  final paso = exclusiones.length <= 1 ? 0.0 : i / (exclusiones.length - 1);
  return cs.error.withValues(alpha: 1.0 - paso * 0.55);
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({required this.resumen, required this.esMovil});

  final PagadoItemResumenEntity resumen;
  final bool esMovil;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final r = resumen;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: r.descuenta ? cs.primary : cs.error,
            borderRadius: ComisionesTema.brChip,
          ),
        ),
        const SizedBox(width: ComisionesTema.esp2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.etiqueta,
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              // En el teléfono la explicación se recorta a dos líneas; el
              // texto completo sigue estando en la ficha de cada ítem.
              Text(
                r.explicacion,
                maxLines: esMovil ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: ComisionesTema.esp2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${FormatoComision.entero.format(r.items)} ítem(s)',
              style: ComisionesTema.numeroApoyo(context, fuerte: true),
            ),
            Text(
              '${FormatoComision.monto.format(r.montoBs)} Bs',
              style: ComisionesTema.numeroApoyo(context),
            ),
            // El descuento por motivo lo trae la rama 'R' (antes se tiraba). En
            // las filas de exclusión es cero y no se pinta; en la de DESCONTO es el
            // único número que dice cuánto se descontó: el de arriba es la base.
            if (r.descuentoBs > 0)
              Text(
                '-${FormatoComision.monto.format(r.descuentoBs)} Bs',
                style: ComisionesTema.numeroApoyo(
                  context,
                )?.copyWith(color: cs.error),
              ),
          ],
        ),
      ],
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  const _BarraFiltros({
    required this.cantidad,
    required this.soloExcluidos,
    required this.notas,
    required this.notaElegida,
    required this.alCambiarExcluidos,
    required this.alCambiarNota,
  });

  final int cantidad;
  final bool soloExcluidos;
  final List<_NotaPagada> notas;
  final _NotaPagada? notaElegida;
  final ValueChanged<bool> alCambiarExcluidos;
  final ValueChanged<_NotaPagada?> alCambiarNota;

  /// Tope del selector. Con `isExpanded` el rótulo se recorta aquí adentro en
  /// vez de estirar el desplegable hasta sacarlo de un teléfono de 320.
  static const double _anchoSelector = 240;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // El origen solo se nombra cuando hace falta: si un mismo docNum aparece con
    // dos empresas hay que distinguirlas (198 casos en un período); si no,
    // «Nota 262220421» alcanza y entra en un teléfono.
    final vistos = <int>{};
    final repetidos = <int>{};
    for (final n in notas) {
      if (!vistos.add(n.docNum)) repetidos.add(n.docNum);
    }
    String rotulo(_NotaPagada n) =>
        repetidos.contains(n.docNum) && n.origen != null
            ? 'Nota ${n.docNum} · ${n.origen}'
            : 'Nota ${n.docNum}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Wrap(
        spacing: ComisionesTema.esp3,
        runSpacing: ComisionesTema.esp2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Sin contador en cero: con la lista vacía habla el estado de abajo, que
          // dice POR QUÉ; un «0 líneas» aquí lo contradiría.
          if (cantidad > 0)
            Text(
              '$cantidad ${cantidad == 1 ? 'línea' : 'líneas'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          if (notas.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _anchoSelector),
              child: DropdownButton<_NotaPagada?>(
                value: notaElegida,
                underline: const SizedBox.shrink(),
                isDense: true,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<_NotaPagada?>(
                    value: null,
                    child: Text(
                      'Todas las notas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final n in notas)
                    DropdownMenuItem<_NotaPagada?>(
                      value: n,
                      child: Text(
                        rotulo(n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: alCambiarNota,
              ),
            ),
          // Interruptor y no dos pestañas: el estado por defecto es «solo lo
          // excluido» y hay que poder ver que está puesto sin leer dos rótulos.
          FilterChip(
            selected: soloExcluidos,
            onSelected: alCambiarExcluidos,
            label: const Text('Solo lo excluido'),
            showCheckmark: true,
          ),
        ],
      ),
    );
  }
}

/// Qué se muestra cuando no hay ítems: NUNCA un contador en cero. Un período sin
/// ítems puede estar perfecto (ninguna nota cayó en la vigencia) o roto (el
/// congelado no corrió), y en la tabla se ven igual: el corte las separa con la
/// explicación del SP en `lectura`. Las ramas resuelven primero lo que ya está en
/// memoria y después el corte, para no acusar a la base de no haber congelado
/// nada solo porque el corte no se pudo leer.
class _SinItems extends StatelessWidget {
  const _SinItems({
    required this.corte,
    required this.soloExcluidos,
    required this.itemsDelPeriodo,
    required this.notaElegida,
    required this.alReintentar,
    this.alVolverAlPeriodo,
  });

  final AsyncValue<PagadoItemCorteEntity?> corte;
  final bool soloExcluidos;

  /// Vuelve al período completo desde el propio estado vacío: con la lista vacía
  /// la barra de filtros no se dibuja y el desplegable de notas era la única salida.
  final VoidCallback? alVolverAlPeriodo;

  /// Líneas que trajo la consulta ANTES del filtro de exclusión: distingue «el
  /// filtro vació la lista» de «el período está vacío» sin depender del corte.
  final int itemsDelPeriodo;

  final _NotaPagada? notaElegida;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) =>
      _Desplazable(child: _contenido(context));

  Widget _contenido(BuildContext context) {
    final c = corte.valueOrNull;

    // (1) La lista la vacía el FILTRO, no el período, y eso se sabe sin el corte
    //     (las líneas están en memoria): exigir `corte.items > 0` dejaba a un
    //     período CON líneas en «no tiene corte» si el corte caía.
    if (soloExcluidos && itemsDelPeriodo > 0) {
      // Con una nota elegida el corte NO sirve (es del período entero): daba «Las
      // 40 líneas congeladas de la nota 262211852 descontaron» sobre una nota de
      // dos líneas. `itemsDelPeriodo` ya viene filtrado por nota.
      final cuantas =
          notaElegida != null
              ? itemsDelPeriodo
              : (c?.itemsQueDescuentan ?? itemsDelPeriodo);
      final donde =
          notaElegida != null
              ? 'de la nota ${notaElegida!.docNum}'
              : (c == null ? 'del período' : 'de ${c.periodo}');
      return EstadoVista.vacio(
        context,
        icono: Icons.verified_outlined,
        titulo: 'Ninguna línea quedó excluida',
        indicacion:
            'Las ${FormatoComision.entero.format(cuantas)} líneas congeladas '
            '$donde descontaron. Quite «Solo lo excluido» para verlas.',
      );
    }

    // (2) Con una nota elegida y sin líneas, el que está vacío es el filtro de
    //     nota. El corte es del período entero y no explica esto.
    if (notaElegida != null) {
      // El botón va aquí: con la lista vacía la barra de filtros no se dibuja,
      // así que el desplegable no está en pantalla y habría que cerrar y reabrir
      // el diálogo.
      return EstadoVista.vacio(
        context,
        icono: Icons.search_off_outlined,
        titulo: 'La nota ${notaElegida!.docNum} no trajo líneas',
        indicacion:
            'El detalle congelado de esta nota'
            '${notaElegida!.origen == null ? '' : ' de ${notaElegida!.origen}'}'
            ' no devolvió ítems.',
        textoAccion:
            alVolverAlPeriodo == null ? null : 'Ver el período completo',
        alPulsarAccion: alVolverAlPeriodo,
      );
    }

    // (3) De aquí en adelante la lista está vacía porque el período no trajo
    //     nada, y el único que puede explicarlo es el corte.

    // Un error de red NO es una respuesta de la base: se dice, con reintento, en
    // vez de «no quedó registro de que el detalle se haya congelado» (el mismo
    // fallo que este diálogo corrige, dado vuelta).
    if (corte.hasError && !corte.hasValue) {
      return EstadoVista.error(
        context,
        error: corte.error ?? 'No se pudo leer el corte del período',
        alReintentar: alReintentar,
      );
    }

    // Mientras el corte viaja no se dice nada: afirmar «no hay nada» antes de
    // saber por qué es exactamente el cero pelado que hay que evitar.
    if (!corte.hasValue) {
      return EstadoVista.cargando(context, mensaje: 'Leyendo el corte');
    }

    // El corte no existe: el período nunca se congeló (el caso «roto», que sin
    // esta tabla pasaba por «no había nada»).
    if (c == null) {
      return EstadoVista.vacio(
        context,
        icono: Icons.report_problem_outlined,
        titulo: 'Este período no tiene corte',
        indicacion:
            'No quedó registro de que el detalle por ítem se haya congelado '
            'aquí. Puede ser un período pagado antes de que existiera el '
            'congelado, o una ejecución en la que ese paso falló. No es lo '
            'mismo que «no había nada que congelar».',
      );
    }

    return _DetalleCorte(corte: c);
  }
}

/// Lo que el corte registró, cuando el corte existe.
class _DetalleCorte extends StatelessWidget {
  const _DetalleCorte({required this.corte});

  final PagadoItemCorteEntity corte;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = corte;

    // `vacioExplicado` separa el cero honesto (el corte corrió y no había nada que
    // congelar) de la incoherencia: el corte dice haber congelado N ítems y la
    // consulta no trajo ninguno.
    final coherente = c.vacioExplicado;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                coherente
                    ? Icons.inventory_2_outlined
                    : Icons.report_problem_outlined,
                size: 22,
                color: coherente ? cs.outline : cs.error,
              ),
              const SizedBox(width: ComisionesTema.esp3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coherente
                          ? 'Sin ítems congelados en ${c.periodo}'
                          : 'El corte de ${c.periodo} registra '
                              '${FormatoComision.entero.format(c.items)} ítems '
                              'que la consulta no trajo',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // La lectura la redacta el SP para que no la tenga que
                    // deducir cada pantalla. Se muestra tal cual llega.
                    Text(
                      c.lectura ??
                          'El corte existe, pero no trajo una lectura del '
                              'período.',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ComisionesTema.esp4),
          Text(
            'Lo que sí registró el corte',
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: ComisionesTema.esp2),
          Wrap(
            spacing: ComisionesTema.esp5,
            runSpacing: ComisionesTema.esp3,
            children: [
              _Dato(rotulo: 'Notas pagadas', valor: '${c.notasPagadas}'),
              _Dato(rotulo: 'Con detalle', valor: '${c.notasConItems}'),
              // El número a mirar: notas pagadas sin detalle. Si es alto y no lo
              // explica la vigencia, algo se perdió entre la captura y el pago.
              _Dato(
                rotulo: 'Sin detalle',
                valor: '${c.notasSinItems}',
                alerta: c.notasSinItems > 0,
              ),
              // Solo si el corte dice haber congelado algo: en el cero honesto
              // serían dos ceros más junto a la frase que explica el cero.
              if (c.items > 0) ...[
                _Dato(rotulo: 'Ítems congelados', valor: '${c.items}'),
                _Dato(
                  rotulo: 'De ellos, descontaron',
                  valor: '${c.itemsQueDescuentan}',
                ),
              ],
              _Dato(
                rotulo: 'Políticas activas',
                valor: '${c.politicasActivas}',
              ),
              if (c.politicaDesde != null)
                _Dato(
                  rotulo: 'Política desde',
                  valor: FormatoComision.fecha.format(c.politicaDesde!),
                ),
              if (c.audFecha != null)
                _Dato(
                  rotulo: 'Congelado el',
                  valor: FormatoComision.fecha.format(c.audFecha!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Contenedor de los estados vacíos que no puede desbordar: los tres estados de
/// EstadoVista miden 240px de alto fijo y el cuerpo del diálogo en un teléfono
/// acostado mide menos.
class _Desplazable extends StatelessWidget {
  const _Desplazable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder:
        (context, limites) => SingleChildScrollView(
          child: ConstrainedBox(
            // El minHeight es lo que mantiene el bloque centrado cuando SÍ
            // entra: sin él quedaría pegado arriba en un monitor.
            constraints: BoxConstraints(
              minHeight: limites.maxHeight.isFinite ? limites.maxHeight : 0.0,
            ),
            child: child,
          ),
        ),
  );
}

class _Dato extends StatelessWidget {
  const _Dato({required this.rotulo, required this.valor, this.alerta = false});

  final String rotulo;
  final String valor;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valor,
          style: ComisionesTema.numeroTotal(
            context,
          )?.copyWith(color: alerta ? cs.error : null),
        ),
        Text(
          rotulo,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Una columna de la tabla de escritorio. Se declaran UNA vez y de aquí salen el
/// encabezado, cada fila y el ancho mínimo, para que no se desincronicen.
class _Columna {
  const _Columna(
    this.rotulo,
    this.ancho, {
    this.numerica = false,
    this.elastica = false,
  });

  final String rotulo;

  /// Ancho fijo, o el mínimo de la columna elástica. Los importes van en
  /// JetBrains Mono a 13px (7.8px por carácter): «1,234,567.89» son doce
  /// caracteres, 94px, por eso Monto y Descuento miden 110.
  final double ancho;

  /// Alineada a la derecha, como los importes de todo el módulo.
  final bool numerica;

  /// La que se queda con el ancho sobrante: la descripción, la única que gana
  /// algo (las demás muestran un dato de largo conocido).
  final bool elastica;
}

const _columnas = <_Columna>[
  _Columna('Nota', 85),
  _Columna('Código', 150),
  _Columna('Descripción', 240, elastica: true),
  _Columna('Familia', 150),
  _Columna('Cantidad', 80, numerica: true),
  _Columna('Monto Bs', 110, numerica: true),
  _Columna('% pago', 70, numerica: true),
  _Columna('Descuento Bs', 110, numerica: true),
  // La más ancha de las fijas: lleva un chip con texto e icono («Familia sin
  // política») que no se puede recortar. 300 y no 200: con 200 el chip del motivo
  // más largo desbordaba 89px a la derecha en CUALQUIER ancho (celda SizedBox fija,
  // el chip no se achica); los tests no lo veían porque su fixture usa motivos cortos.
  _Columna('Motivo', 300),
];

/// El mismo `horizontalMargin` que el tema le da a las DataTable del módulo.
const double _margenTabla = ComisionesTema.esp4;

/// Ancho mínimo antes de que haga falta el scroll horizontal. Se calcula, no se
/// escribe: sumado a mano se desincroniza cuando cambia una columna.
final double _anchoMinimoTabla =
    _columnas.fold<double>(0, (s, c) => s + c.ancho) +
    ComisionesTema.separacionColumnas * (_columnas.length - 1) +
    _margenTabla * 2;

/// El esqueleto de una fila: encabezado y datos comparten este marco, que es
/// lo único que garantiza que las columnas no se corran entre sí.
Widget _marcoFila(List<Widget> celdas) {
  assert(celdas.length == _columnas.length);
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: _margenTabla),
    child: Row(
      children: [
        for (var k = 0; k < _columnas.length; k++) ...[
          if (k > 0) const SizedBox(width: ComisionesTema.separacionColumnas),
          if (_columnas[k].elastica)
            Expanded(child: _celda(k, celdas[k]))
          else
            SizedBox(width: _columnas[k].ancho, child: _celda(k, celdas[k])),
        ],
      ],
    ),
  );
}

Widget _celda(int k, Widget hijo) => Align(
  alignment:
      _columnas[k].numerica ? Alignment.centerRight : Alignment.centerLeft,
  child: hijo,
);

/// La tabla de escritorio, virtualizada: el alto de fila es fijo
/// (`ComisionesTema.altoFila`), así que la lista sabe cuánto mide sin construir
/// nada y solo instancia lo visible (un DataTable construía los miles de DataRow
/// de un mes grande, cada uno con su ChipEstado, aunque se vieran quince).
class _TablaItems extends StatefulWidget {
  const _TablaItems({required this.items});

  final List<PagadoItemEntity> items;

  @override
  State<_TablaItems> createState() => _TablaItemsState();
}

class _TablaItemsState extends State<_TablaItems> {
  /// Controller propio para el scroll horizontal: sin él, el Scrollbar y el
  /// SingleChildScrollView no comparten posición y la barra sería un adorno.
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // El ancho se mide FUERA del scroll horizontal: adentro maxWidth es
      // infinito y el minWidth reventaría el layout.
      builder: (context, limites) {
        final ancho =
            limites.maxWidth < _anchoMinimoTabla
                ? _anchoMinimoTabla
                : limites.maxWidth;

        // Con el alto de fila fijo el contenido se mide sin construir filas. El
        // tope deja que el diálogo siga encogiendo con pocas líneas: sin él, tres
        // líneas abrirían un diálogo de pantalla entera con aire abajo.
        final altoContenido = widget.items.length * ComisionesTema.altoFila;

        // El encabezado es un hijo rígido: si el cuerpo mide menos, el Column
        // desborda. Pasa de verdad (600x480 con el resumen puesto deja 28px para
        // la tabla), así que se encoge con lo que haya.
        final disponible =
            limites.maxHeight.isFinite
                ? limites.maxHeight - _padInferiorTabla
                : double.infinity;
        final altoEncabezado = disponible.clamp(
          0.0,
          ComisionesTema.altoEncabezado,
        );

        return Scrollbar(
          controller: _horizontal,
          // Siempre visible: en web el scroll horizontal no se descubre solo, y lo
          // que queda afuera es la columna del motivo.
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: _padInferiorTabla),
            child: SizedBox(
              width: ancho,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // El encabezado queda fijo y no se va con el scroll vertical: en
                  // una lista larga se perdía de vista a la tercera pantalla.
                  _EncabezadoTabla(alto: altoEncabezado),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: altoContenido),
                      child: ListView.builder(
                        primary: false,
                        itemExtent: ComisionesTema.altoFila,
                        itemCount: widget.items.length,
                        itemBuilder:
                            (context, k) => _FilaTabla(item: widget.items[k]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Alto que se reserva bajo la tabla para la barra de scroll horizontal.
const double _padInferiorTabla = 12;

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla({required this.alto});

  /// Normalmente `ComisionesTema.altoEncabezado`; menos cuando el cuerpo del
  /// diálogo no da ni para eso.
  final double alto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      height: alto,
      decoration: BoxDecoration(
        // Del tema, no un gris suelto: es el mismo fondo de encabezado que
        // usan las tablas del módulo.
        color: ComisionesTema.encabezadoTabla(context).resolve(<WidgetState>{}),
        border: Border(bottom: _divisor(tema)),
      ),
      child: DefaultTextStyle.merge(
        style: tema.dataTableTheme.headingTextStyle,
        child: _marcoFila([
          for (final c in _columnas)
            Text(c.rotulo, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

BorderSide _divisor(ThemeData tema) => BorderSide(
  color: tema.dividerTheme.color ?? tema.dividerColor,
  width: tema.dataTableTheme.dividerThickness ?? 1,
);

class _FilaTabla extends StatefulWidget {
  const _FilaTabla({required this.item});

  final PagadoItemEntity item;

  @override
  State<_FilaTabla> createState() => _FilaTablaState();
}

/// Con estado solo por el realce del cursor. Es una fila a la vez y solo
/// existen las visibles, así que el costo es el de la ventana, no el del mes.
class _FilaTablaState extends State<_FilaTabla> {
  bool _encima = false;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final i = widget.item;

    // El realce sale del dataRowColor del tema, no de un color suelto: es el
    // mismo que usan todas las tablas del módulo.
    final resaltado = tema.dataTableTheme.dataRowColor?.resolve(<WidgetState>{
      WidgetState.hovered,
    });
    // La línea excluida se marca con un lavado de error, no con texto rojo: es
    // la fila entera la que quedó afuera, no un dato suyo. Bajo el cursor gana el
    // resaltado.
    final fondo =
        _encima
            ? resaltado
            : (i.excluido ? cs.errorContainer.withValues(alpha: 0.18) : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _encima = true),
      onExit: (_) => setState(() => _encima = false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fondo,
          border: Border(bottom: _divisor(tema)),
        ),
        child: DefaultTextStyle.merge(
          style: tema.dataTableTheme.dataTextStyle,
          child: _marcoFila([
            Text(
              '${i.docNum ?? "—"}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              i.itemCode ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // La descripción más larga de la base mide 59 caracteres: sin
            // recorte estiraba la tabla hasta sacar los importes de pantalla.
            Text(i.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(i.grpFam ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              FormatoComision.monto.format(i.cantidad ?? 0),
              style: ComisionesTema.numeroCelda(context),
            ),
            Text(
              FormatoComision.monto.format(i.montoLineaBs ?? 0),
              style: ComisionesTema.numeroCelda(context),
            ),
            Text(
              // Guion y no «0 %» cuando no aplicó: un cero se lee como «se le
              // pagó cero», que es otra cosa.
              i.porcentajePago == null
                  ? '—'
                  : FormatoComision.porcentaje(i.porcentajePago!),
              style: ComisionesTema.numeroCelda(context),
            ),
            Text(
              i.descuentoBs == 0
                  ? '—'
                  : '-${FormatoComision.monto.format(i.descuentoBs)}',
              style: ComisionesTema.numeroCelda(
                context,
                fuerte: true,
              )?.copyWith(color: i.descuentoBs == 0 ? null : cs.error),
            ),
            i.excluido
                ? ChipEstado(
                  texto: MotivoItemPagado.etiqueta(i.motivoExclusion),
                  tono: TonoChip.alerta,
                )
                : ChipEstado(texto: MotivoItemPagado.etiqueta(null)),
          ]),
        ),
      ),
    );
  }
}

class _ListaTarjetas extends StatelessWidget {
  const _ListaTarjetas({required this.items});

  final List<PagadoItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // primary: false: el resumen de arriba puede desplazarse a la vez y dos
      // scrollables sobre el PrimaryScrollController fallan en un assert.
      primary: false,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: ComisionesTema.esp2),
      itemBuilder: (context, i) => _Tarjeta(item: items[i]),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.item});

  final PagadoItemEntity item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final i = item;

    return Container(
      padding: const EdgeInsets.all(ComisionesTema.esp3),
      decoration: BoxDecoration(
        // La tarjeta excluida se distingue por el borde, no por el relleno: si la
        // mayoría está excluida, rellenarlas todas tiñe la pantalla y nada destaca.
        border: Border.all(color: i.excluido ? cs.error : cs.outlineVariant),
        borderRadius: ComisionesTema.brControl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i.nombre,
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${i.itemCode ?? "—"}  ·  ${i.grpFam ?? "sin familia"}',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: ComisionesTema.esp2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monto',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    Text(
                      '${FormatoComision.monto.format(i.montoLineaBs ?? 0)} Bs',
                      style: ComisionesTema.numeroTotal(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ComisionesTema.esp2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Descuento',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  Text(
                    i.descuentoBs == 0
                        ? '—'
                        : '-${FormatoComision.monto.format(i.descuentoBs)} Bs',
                    style: ComisionesTema.numeroTotal(
                      context,
                    )?.copyWith(color: i.descuentoBs == 0 ? null : cs.error),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ComisionesTema.esp2),
          Wrap(
            spacing: ComisionesTema.esp1 + 2,
            runSpacing: ComisionesTema.esp1 + 2,
            children: [
              if (i.docNum != null) ChipEstado(texto: 'Nota ${i.docNum}'),
              if (i.origen != null) ChipEstado(texto: i.origen!),
              if (i.fechaDoc != null)
                ChipEstado(texto: FormatoComision.fecha.format(i.fechaDoc!)),
              if (i.cantidad != null)
                ChipEstado(
                  texto: '${FormatoComision.monto.format(i.cantidad)} un',
                ),
              if (i.porcentajePago != null)
                ChipEstado(
                  texto:
                      'paga ${FormatoComision.porcentaje(i.porcentajePago!)}',
                ),
              ChipEstado(
                texto: MotivoItemPagado.etiqueta(i.motivoExclusion),
                tono: i.excluido ? TonoChip.alerta : TonoChip.neutro,
              ),
            ],
          ),
          // El por qué va completo en la tarjeta y no solo en el chip: en teléfono
          // no hay tooltip, y «Fuera de vigencia» sin explicación no dice nada.
          if (i.excluido) ...[
            const SizedBox(height: ComisionesTema.esp2),
            Text(
              MotivoItemPagado.explicacion(i.motivoExclusion),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
