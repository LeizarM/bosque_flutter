import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/utils/formato_comision.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/pagado_item_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/estado_vista.dart';

/// El detalle por ítem de lo que YA se pagó, con el foco en lo EXCLUIDO.
///
/// Por qué existe: hasta ahora, del detalle de una nota pagada solo sobrevivía
/// `tcom_pagado.detalleItems`, un varchar armado con FOR XML PATH. Alcanzaba
/// para imprimir un renglón y para nada más: no se podía agrupar por familia,
/// ni sumar lo excluido, ni cruzarlo con el maestro de artículos. Y lo excluido
/// es la mayoría —15 de cada 19 líneas medidas—, o sea que lo que no se podía
/// ver era justamente lo que más había.
///
/// Cómo se acota lo que se pide. El SP acepta `@mes`, `@anio`, `@esInterno` y,
/// opcionales, `@idPagado`, `@docNum` y `@origen`, y los tres últimos aplican
/// tanto en la rama 'L' (listado) como en la 'R' (resumen por motivo). El
/// diálogo abre con el período entero —ninguna pantalla conoce `idPagado`— y
/// desde ahí:
///
///   - elegir una nota manda `@docNum` + `@origen` a las DOS ramas, así el
///     titular de arriba y las líneas de abajo no pueden hablar de notas
///     distintas;
///   - `@origen` viaja siempre con `@docNum` porque el número solo no
///     identifica una nota: se repite entre empresas —198 casos medidos en un
///     mismo período— y además es lo único que separa ESPPAPEL de
///     IMPEXPAP/PAPIRUS/PRODUCTIVA PAPEL, que se congelan las cuatro con
///     `esInterno = 1`;
///   - «solo lo excluido» NO va al SP: es un `where` sobre `aplicaDescuento`,
///     que ya viene en cada fila. Pedirlo al backend obligaba a bajar el mes
///     dos veces para tildar y destildar un chip.
///
/// Por qué nunca muestra un cero pelado: un período puede tener CERO ítems y
/// estar perfecto —ninguna nota cayó dentro de la vigencia de la política—, o
/// puede tenerlos en cero porque el congelado nunca corrió. Son dos cosas
/// opuestas que se ven igual. El corte (`tcom_pagadoItemCorte`) las separa y
/// además redacta la explicación en su campo `lectura`, así que acá el vacío
/// muestra el corte y no un contador en cero. Y cuando el corte no se pudo
/// leer, se dice que no se pudo leer: acusar a la base de no haber congelado
/// nada por un error de red es el mismo fallo que este diálogo corrige, dado
/// vuelta.
class DialogoItemsPagados extends ConsumerStatefulWidget {
  const DialogoItemsPagados({super.key, required this.filtro, this.subtitulo});

  /// Período y alcance. `idPagado` viaja tal cual al SP; si es null —el caso
  /// normal— se pide el período entero.
  final FiltroItemsPagados filtro;

  /// Contexto de quien abre: «ejecutado el 12/08/2026», por ejemplo. Va debajo
  /// del título para que el diálogo se entienda sin volver a la pantalla.
  final String? subtitulo;

  @override
  ConsumerState<DialogoItemsPagados> createState() =>
      _DialogoItemsPagadosState();
}

/// Una nota del período: el par (origen, docNum), no el número solo.
///
/// `docNum` se repite entre empresas —198 casos medidos en el mismo período—,
/// así que un selector por número suelto mezclaría dos notas distintas en una
/// sola opción. Lleva == y hashCode porque es el `value` de un DropdownButton,
/// que compara por igualdad.
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
  /// Arranca en TRUE, y no es un capricho: lo excluido es la mayoría y es lo
  /// que no existía en ningún lado. Lo que descontó ya se veía en el reporte.
  bool _soloExcluidos = true;

  /// Nota elegida, o null para todo el período.
  _NotaPagada? _nota;

  @override
  Widget build(BuildContext context) {
    final esMovil = ResponsiveUtilsBosque.isMobile(context);

    // El período tal como lo pidió quien abre. Se observa SIEMPRE, aun con una
    // nota elegida: de esta lista salen las notas del selector, y como el
    // provider es autoDispose, dejar de observarla tiraría la entrada y volver
    // a «Todas las notas» costaría bajar el mes otra vez.
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

    // El resumen va con la MISMA clave que el listado. Antes iba clavado al
    // período: con una nota elegida la lista mostraba una línea y el titular
    // seguía contando el mes entero.
    final resumen = ref.watch(resumenItemsPagadosProvider(filtro));

    // El corte es por período: ni la nota ni el filtro de exclusión lo
    // cambian, así que va con su propia clave y no se vuelve a pedir al tocar
    // un filtro del listado.
    final clave = ClavePeriodo(
      mes: widget.filtro.mes,
      anio: widget.filtro.anio,
      esInterno: widget.filtro.esInterno,
    );
    final corte = ref.watch(corteItemsPagadosProvider(clave));

    // El tope de ComisionesTema.anchoTabla dejaba tres columnas afuera y el
    // scroll horizontal de la tabla no dibuja barra en web: quedaban
    // inalcanzables. Con el ancho de la pantalla menos el margen, en un
    // monitor común entran las nueve.
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

// ── Encabezado ───────────────────────────────────────────────────────────────

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
          // Wrap y no Row: en un teléfono de 320 los tres datos no entran en
          // una línea y un Row los recortaría sin avisar.
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

// ── Cuerpo ───────────────────────────────────────────────────────────────────

/// Cuánto del alto del cuerpo puede ocupar el resumen antes de desplazarse.
///
/// El resumen crece con la cantidad de motivos, y el máximo real son CINCO
/// filas —DESCONTO y los cuatro motivos de exclusión—, que con sus
/// explicaciones miden más que la pantalla de un teléfono. Suelto en el Column
/// eso desbordaba: medido, 360x640 se pasaba 29 px con tres filas y 139 px con
/// cinco; 320x568 con cinco, 324 px.
///
/// Algo MENOS de la mitad, y no la mitad justa, porque debajo del resumen
/// todavía tienen que entrar la barra de filtros —que en un teléfono ocupa dos
/// o tres renglones— y algo de lista. Con dos o tres motivos, que es el caso
/// normal, el resumen entra entero y esta cuenta no se nota.
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

  /// Los dos viajan como AsyncValue y no como valor pelado: `null` no
  /// distingue «no llegó» de «falló», y esa confusión era la que hacía que un
  /// error de red se mostrara como una acusación sobre la base.
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
  /// Controller propio del resumen: cuando el bloque no entra se desplaza
  /// adentro, y sin controller explícito quedaría colgado del
  /// PrimaryScrollController, que también reclaman la lista y el vacío.
  final _resumen = ScrollController();

  @override
  void dispose() {
    _resumen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    // «Solo lo excluido» se resuelve acá y no en el SP: es un where sobre un
    // campo que ya viene en cada fila. Con el filtro en la clave del provider,
    // tildar el chip destruía la entrada del cache —es autoDispose— y
    // destildarlo volvía a bajar el mes entero.
    final visibles =
        widget.soloExcluidos
            ? items.where((i) => i.excluido).toList(growable: false)
            : items;

    // Si la nota elegida ya no está entre las del período —el índice se
    // recargó— se cae a «todas» al dibujar. No se toca el estado acá:
    // cambiarlo durante el build es un bucle de rebuilds.
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

        // Alto minimo para que la lista tenga sentido: por debajo, en vez de
        // apretar todo hasta que algo desborde, el cuerpo entero se desplaza.
        //
        // El desborde vivia aca: _BarraFiltros es hijo rigido y el unico
        // Flexible era la lista, asi que en un telefono ACOSTADO -640x360,
        // 800x360, 568x320- el Flexible se encogia a cero y el Column
        // reventaba igual. Medido tambien con el resumen vacio, asi que no era
        // culpa de cuanto se lleva el resumen.
        //
        // Se scrollea en vez de esconder: decidir por el usuario que mitad de
        // la pantalla no merece verse es peor que pedirle que baje.
        const minimoUtil = 260.0;
        final apretado =
            limites.maxHeight.isFinite && limites.maxHeight < minimoUtil;

        final cuerpo = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // El resumen va ARRIBA de la lista: la pregunta que trae a alguien
            // acá es «¿cuánto quedó afuera y por qué?», y esa se responde con
            // el reparto por motivo, no leyendo doscientas líneas.
            _ZonaResumen(
              resumen: widget.resumen,
              esMovil: widget.esMovil,
              tope: tope,
              controlador: _resumen,
              alReintentar: widget.alReintentarResumen,
            ),
            // La barra depende de que HAYA líneas, y de nada más. Antes
            // dependía también de que el resumen hubiera llegado: si la rama
            // 'R' fallaba, la barra no se dibujaba y el vacío de abajo seguía
            // diciendo «Quite Solo lo excluido», o sea mandaba a apagar un
            // control que no estaba en pantalla.
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

        // Sin scroll cuando entra: un SingleChildScrollView permanente le saca
        // el alto acotado al Flexible de la lista y la lista deja de tener su
        // propio scroll.
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

// ── Resumen por motivo ───────────────────────────────────────────────────────

/// Los tres estados del resumen, que antes se veían todos igual: sin resumen.
///
/// Todavía no llegó, no llegó nunca, o el período no tiene nada que repartir.
/// El del medio es el que hay que decir: si no, la única señal de que la rama
/// 'R' falló es un bloque que falta.
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
      // Cargando, o período sin nada que repartir. En los dos casos el que
      // habla es lo de abajo —el esqueleto o la lectura del corte—, y un
      // bloque a medio llenar acá arriba solo agregaría ruido.
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

/// El reparto de lo pagado entre lo que descontó y lo que no.
///
/// Se dibuja con una barra proporcional además de los números porque «15 de
/// 19» y «79 %» se leen distinto: el ancho se entiende sin hacer la cuenta.
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
          // filas de tabla para saber cuánto quedó afuera.
          //
          // Cuando NO hay exclusiones el titular se da vuelta en vez de
          // anunciar «0 de 1 ítems no descontaron»: un cero al lado de un uno
          // se lee como un problema, y acá es exactamente lo contrario.
          Text(
            _titular(total, excluidos),
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          // Y la línea del monto solo cuando hay monto: «0.00 Bs quedaron
          // fuera del descuento» era el segundo cero pelado de la misma caja.
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
                    // Sin colores sueltos: lo que descontó lleva el acento del
                    // tema y lo excluido, tonos del canal de error, que es el
                    // único par que se distingue en las nueve semillas y en
                    // los dos modos.
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

/// Los motivos de exclusión se separan entre sí por opacidad sobre el mismo
/// canal, no por matices distintos: cuatro matices inventados dejarían de
/// funcionar en cuanto el usuario cambie el color de acento en ajustes.
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
            // Lo descontado por motivo lo trae la rama 'R' y hasta ahora se
            // parseaba y se tiraba. En las filas de exclusión es cero por
            // definición —por eso no se pinta— y en la de DESCONTO es el único
            // número que dice cuánto se descontó de verdad: el de arriba es la
            // base de la línea, no el descuento.
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

// ── Barra de filtros ─────────────────────────────────────────────────────────

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

  /// Tope del selector. Con `isExpanded` el rótulo se recorta acá adentro en
  /// vez de estirar el desplegable hasta sacarlo de un teléfono de 320.
  static const double _anchoSelector = 240;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // El origen solo se nombra cuando hace falta: si el mismo docNum aparece
    // con dos empresas hay que poder distinguirlas —pasa en 198 casos de un
    // mismo período— y si no, «Nota 262220421» ya alcanza y entra en el
    // teléfono.
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
      // Wrap para que en un teléfono el contador, el selector de nota y el
      // interruptor bajen de línea en vez de recortarse.
      child: Wrap(
        spacing: ComisionesTema.esp3,
        runSpacing: ComisionesTema.esp2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Sin contador en cero: cuando la lista está vacía el que habla es
          // el estado de abajo, que dice POR QUÉ. Un «0 líneas» acá arriba lo
          // contradiría con un número que no explica nada.
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

// ── Vacío: el corte, nunca un cero pelado ────────────────────────────────────

/// Qué se muestra cuando no hay ítems.
///
/// NUNCA un contador en cero. Un período sin ítems puede estar perfecto —el
/// congelado corrió y ninguna nota cayó dentro de la vigencia de la política—
/// o puede estar roto —el congelado no corrió—, y esas dos cosas se ven igual
/// mirando la tabla. El corte es el que las separa, y trae la explicación ya
/// redactada por el SP en `lectura`.
///
/// El orden de las ramas importa, y no es el de antes: primero se resuelve lo
/// que se puede resolver con lo que YA está en memoria, y recién después habla
/// el corte. Así un período que sí tiene líneas nunca termina acusando a la
/// base de no haber congelado nada solo porque el corte no se pudo leer.
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

  /// Vuelve al período completo desde el propio estado vacío.
  ///
  /// Hace falta porque con la lista vacía la barra de filtros no se dibuja, y
  /// el desplegable de notas era la única forma de volver: el diálogo quedaba
  /// sin salida.
  final VoidCallback? alVolverAlPeriodo;

  /// Cuántas líneas trajo la consulta ANTES del filtro de exclusión. Es lo que
  /// permite distinguir «el filtro vació la lista» de «el período está vacío»
  /// sin depender del corte.
  final int itemsDelPeriodo;

  final _NotaPagada? notaElegida;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) =>
      _Desplazable(child: _contenido(context));

  Widget _contenido(BuildContext context) {
    final c = corte.valueOrNull;

    // (1) La lista la vacía el FILTRO, no el período, y eso se sabe sin el
    //     corte: las líneas están en memoria. Antes esta rama exigía
    //     `corte.items > 0`, así que con el corte caído o inexistente un
    //     período CON líneas terminaba en «este período no tiene corte»
    //     mientras el resumen de arriba contaba sus ítems.
    if (soloExcluidos && itemsDelPeriodo > 0) {
      // Con una nota elegida el corte NO sirve: es del período entero. Usarlo
      // producía «Las 40 líneas congeladas de la nota 262211852 descontaron»
      // sobre una nota de dos líneas — un número correcto puesto en boca de
      // otro conjunto. `itemsDelPeriodo` ya viene filtrado por nota cuando hay
      // una elegida, así que ese es el número que corresponde.
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
      // El botón va acá y el texto ya no manda a tocar el desplegable: con la
      // lista vacía la barra de filtros no se dibuja, así que ese control NO
      // está en pantalla. Y era la única forma de volver: sin esto había que
      // cerrar el diálogo y abrirlo de nuevo.
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

    // (3) De acá en adelante la lista está vacía porque el período no trajo
    //     nada, y el único que puede explicarlo es el corte.

    // Un error de red NO es una respuesta de la base. Se dice, con reintento,
    // en vez de imprimir «no quedó registro de que el detalle se haya
    // congelado»: ese texto sobre una llamada fallida es el mismo fallo que
    // este diálogo corrige, dado vuelta.
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

    // El corte no existe: el período nunca se congeló. Es el caso (b), el que
    // sin esta tabla pasaba por «no había nada».
    if (c == null) {
      return EstadoVista.vacio(
        context,
        icono: Icons.report_problem_outlined,
        titulo: 'Este período no tiene corte',
        indicacion:
            'No quedó registro de que el detalle por ítem se haya congelado '
            'acá. Puede ser un período pagado antes de que existiera el '
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

    // `vacioExplicado` separa el cero honesto —el corte corrió y no había nada
    // que congelar— de la incoherencia: el corte dice haber congelado N ítems
    // y la consulta no trajo ninguno. Las dos se veían con el mismo título.
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
              // El número que hay que mirar: notas que se pagaron y de las que
              // no quedó detalle. Si es alto y no lo explica la vigencia, algo
              // se perdió entre la captura y el pago.
              _Dato(
                rotulo: 'Sin detalle',
                valor: '${c.notasSinItems}',
                alerta: c.notasSinItems > 0,
              ),
              // Solo cuando el corte dice haber congelado algo: en el cero
              // honesto estos dos serían dos ceros más al lado de la frase que
              // está tratando de explicar el cero.
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

/// Contenedor de los estados vacíos que no puede desbordar.
///
/// Los tres estados de EstadoVista miden 240 px de alto fijo, y el cuerpo del
/// diálogo en un teléfono acostado mide menos que eso. Con el contenido suelto,
/// el vacío que explica el cero desbordaba justo en la pantalla donde menos se
/// puede leer.
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

// ── Escritorio: tabla ────────────────────────────────────────────────────────

/// Una columna de la tabla de escritorio.
///
/// Las columnas se declaran UNA vez y de acá salen el encabezado, cada fila y
/// el ancho mínimo. Antes eran tres cosas separadas —los DataColumn, las
/// DataCell y un 1340 sumado a mano en un comentario— y el comentario contaba
/// ocho columnas donde la tabla declaraba nueve.
class _Columna {
  const _Columna(
    this.rotulo,
    this.ancho, {
    this.numerica = false,
    this.elastica = false,
  });

  final String rotulo;

  /// Ancho fijo, o el mínimo de la columna elástica.
  ///
  /// Los importes van en JetBrains Mono a 13 px —7.8 px por carácter— así que
  /// la cuenta es literal: «1,234,567.89» son doce caracteres, 94 px. Por eso
  /// Monto y Descuento miden 110 y no los 90 que tenían anotados.
  final double ancho;

  /// Alineada a la derecha, como los importes de todo el módulo.
  final bool numerica;

  /// La que se queda con el ancho sobrante cuando la pantalla da de más. Es la
  /// descripción porque es la única que gana algo: las demás muestran un dato
  /// de largo conocido.
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
  // La más ancha de las fijas: lleva un chip con texto e icono —«Familia sin
  // política»— que no se puede recortar sin perder justo el dato por el que
  // alguien abre este diálogo.
  //
  // 300 y no 200: con 200 el chip del motivo más largo desbordaba 89 px hacia
  // la derecha, en CUALQUIER ancho de pantalla, porque la celda es un SizedBox
  // fijo y el chip no se achica. Los tests no lo veían porque su fixture usa
  // motivos cortos; se reprodujo recién al armar uno con los cinco.
  _Columna('Motivo', 300),
];

/// El mismo `horizontalMargin` que el tema le da a las DataTable del módulo.
const double _margenTabla = ComisionesTema.esp4;

/// Ancho mínimo antes de que el scroll horizontal empiece a hacer falta.
///
/// Se calcula, no se escribe: sumado a mano se desincroniza de las columnas en
/// cuanto alguna cambia, y eso ya pasó una vez.
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

/// La tabla de escritorio, virtualizada.
///
/// Antes era un DataTable con `rows: [for (final i in items) ...]` dentro de un
/// SingleChildScrollView: los miles de DataRow de un mes grande —cada uno con
/// su ChipEstado— se construían enteros en el frame en que abría el diálogo,
/// aunque solo se vieran quince. Ahora el alto de fila es fijo
/// (`ComisionesTema.altoFila`), así que la lista sabe cuánto mide sin
/// construir nada y solo instancia lo que se ve.
class _TablaItems extends StatefulWidget {
  const _TablaItems({required this.items});

  final List<PagadoItemEntity> items;

  @override
  State<_TablaItems> createState() => _TablaItemsState();
}

class _TablaItemsState extends State<_TablaItems> {
  /// Controller propio para el scroll horizontal.
  ///
  /// Sin el, el Scrollbar y el SingleChildScrollView no comparten posicion: la
  /// barra se dibuja pero no se mueve con la tabla ni la mueve. Un adorno.
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

        // Con el alto de fila fijo, lo que mide el contenido se sabe sin
        // construir una sola fila. El tope es lo que deja que el diálogo siga
        // encogiendo con pocas líneas: sin él la lista se estira hasta el
        // borde y un período de tres líneas abriría un diálogo de pantalla
        // entera con el aire abajo.
        final altoContenido = widget.items.length * ComisionesTema.altoFila;

        // El encabezado es un hijo rígido: si el cuerpo mide menos que él, el
        // Column desborda. Pasa de verdad —600x480 con el resumen puesto deja
        // 28 px para la tabla— así que se encoge con lo que haya. Una tabla de
        // 28 px no sirve para nada, pero un desborde tampoco, y este además
        // tapa el resto con la reja amarilla.
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
          // Siempre visible, no solo al arrastrar: en web el scroll
          // horizontal no se descubre solo, y lo que queda afuera es
          // justamente la columna del motivo.
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
                  // El encabezado queda fijo y no se va con el scroll vertical
                  // como hacía el DataTable: en una lista larga se perdía de
                  // vista a la tercera pantalla.
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
    // la fila entera la que quedó afuera, no un dato suyo. Bajo el cursor gana
    // el resaltado, que es el que dice «estoy leyendo este renglón».
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

// ── Móvil: tarjetas ──────────────────────────────────────────────────────────

class _ListaTarjetas extends StatelessWidget {
  const _ListaTarjetas({required this.items});

  final List<PagadoItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Controller propio: el resumen de arriba puede estar desplazándose al
      // mismo tiempo, y dos scrollables colgados del PrimaryScrollController
      // es una asercion en tiempo de ejecucion.
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
        // La tarjeta excluida se distingue por el borde, no por el relleno: en
        // una lista donde la mayoría está excluida, rellenarlas todas deja la
        // pantalla teñida y ya no destaca nada.
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
          // El por qué va completo en la tarjeta y no solo en el chip: en un
          // teléfono no hay tooltip donde esconderlo, y «Fuera de vigencia» sin
          // la explicación no le dice nada a quien pregunta por su comisión.
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
