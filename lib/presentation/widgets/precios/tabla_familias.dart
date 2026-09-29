/// La planilla de familias de producto para web y escritorio. Sigue el patrón de
/// `TablaLotes` y no `BosqueFlatTable` (flex sin ancho mínimo: con nueve columnas
/// las aplasta): anchos fijos, cabecera fija y un único scroll horizontal
/// controlado, arrastrable con el mouse. Si sobra lugar, la columna de grupo de
/// familia se lleva el sobrante.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/acciones_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cifra_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';

const double _altoCabecera = 40;
const double _altoFila = 52;

/// Los tamanios de pagina que ofrece el pie. 15 entra sin scroll vertical en un
/// monitor comun; 100 es para quien esta comparando todo el catalogo.
const List<int> _tamaniosPagina = [15, 25, 50, 100];

class TablaFamilias extends StatefulWidget {
  const TablaFamilias({
    super.key,
    required this.filas,
    required this.onAbrir,
    required this.onNuevaDesde,
    required this.onAccion,
  });

  final List<FamiliaVista> filas;

  /// Abre la ficha de la familia. Es la misma ficha que edita y que muestra el
  /// detalle, por eso la accion no se llama "editar".
  final void Function(FamiliaVista familia) onAbrir;

  /// Alta de una familia nueva con los datos de esta, menos el codigo.
  final void Function(FamiliaVista familia) onNuevaDesde;

  /// Historial, grupo o proveedor SAP, baja o reactivacion y eliminacion.
  final void Function(FamiliaVista familia, AccionFamilia accion) onAccion;

  @override
  State<TablaFamilias> createState() => _TablaFamiliasState();
}

class _TablaFamiliasState extends State<TablaFamilias> {
  final _scrollH = ScrollController();
  final _scrollV = ScrollController();

  int _pagina = 1;
  int _porPagina = _tamaniosPagina.first;

  @override
  void didUpdateWidget(TablaFamilias anterior) {
    super.didUpdateWidget(anterior);
    // Al cambiar el filtro el listado es otro: quedarse en la página 7 de un resultado
    // de dos páginas muestra una tabla vacía y parece que la búsqueda no encontró nada.
    if (anterior.filas.length != widget.filas.length) {
      _pagina = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollV.hasClients) _scrollV.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollH.dispose();
    _scrollV.dispose();
    super.dispose();
  }

  // Formato y gramaje NO van: están 100 % vacías en producción (200 px de guiones).
  // Dos juegos: el completo pide ~1450 px; con el menú lateral una ventana de 1280
  // deja ~1000, así que el apretado junta de a dos los datos descriptivos (~990 px).

  List<_Col> _columnas({required bool apretada}) => [
    _Col(
      'CÓDIGO',
      apretada ? 80 : 92,
      (c, f) => _cifra(c, '#${f.codigoLegible}', fuerte: true),
    ),
    if (apretada) ...[
      _Col(
        'FAMILIA SAP / PROVEEDOR',
        220,
        (c, f) =>
            _dosLineas(c, f.grupoFamiliaSap, f.proveedorSap, fuerte: true),
      ),
      _Col(
        'TIPO / PRESENTACIÓN',
        160,
        (c, f) => _dosLineas(c, f.tipo, f.presentacion),
      ),
      _Col(
        'GRAMAJE / COLOR',
        150,
        (c, f) => _dosLineas(c, f.rangoGramaje, f.color),
      ),
    ] else ...[
      _Col('GRUPO FAMILIA SAP', 210, (c, f) => _texto(c, f.grupoFamiliaSap)),
      _Col('PROVEEDOR SAP', 190, (c, f) => _texto(c, f.proveedorSap)),
      _Col('PRESENTACIÓN', 150, (c, f) => _texto(c, f.presentacion)),
      _Col('TIPO', 150, (c, f) => _texto(c, f.tipo)),
      _Col('RANGO GRAMAJE', 150, (c, f) => _texto(c, f.rangoGramaje)),
      _Col('COLOR', 130, (c, f) => _texto(c, f.color)),
    ],
    _Col(
      'ESTADO',
      apretada ? 96 : 104,
      (c, f) => Etiqueta(
        texto: f.estadoLegible,
        tono: f.esActiva ? TonoEtiqueta.exito : TonoEtiqueta.neutro,
      ),
    ),
    _Col(
      'COSTO / TM',
      apretada ? 116 : 130,
      // Alineada a la derecha y con cifras tabulares: es la unica columna que
      // se compara renglon contra renglon.
      (c, f) => _cifra(
        c,
        f.sinCosto ? 'Sin costo' : f.costoTmLegible,
        fuerte: !f.sinCosto,
        apagada: f.sinCosto,
      ),
      alinear: Alignment.centerRight,
    ),
    // Cuatro botones de 34 con 3 de aire a cada lado, mas el padding de la
    // celda.
    _Col('ACCIONES', 176, _acciones, alinear: Alignment.center),
  ];

  /// La columna que se come el espacio sobrante cuando la ventana es ancha:
  /// la del grupo SAP en los dos juegos.
  static const int _indiceElastico = 1;

  /// Acciones en linea, que es lo que se puede hacer cuando sobra ancho.
  Widget _acciones(BuildContext context, FamiliaVista f) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _BotonFila(
        matiz: matizAzul,
        icono: Icons.edit_note_outlined,
        ayuda: 'Abrir la ficha de la familia ${f.codigoLegible}',
        onTocar: () => widget.onAbrir(f),
      ),
      _BotonFila(
        matiz: matizVerde,
        icono: Icons.library_add_outlined,
        ayuda: 'Nueva familia a partir de la ${f.codigoLegible}',
        onTocar: () => widget.onNuevaDesde(f),
      ),
      _BotonFila(
        matiz: matizVioleta,
        icono: Icons.timeline_outlined,
        ayuda: 'Historial del costo de la familia ${f.codigoLegible}',
        onTocar: () => widget.onAccion(f, AccionFamilia.historial),
      ),
      _MasAcciones(
        familia: f,
        onAccion: (a) {
          if (a == AccionFamilia.copiar) {
            copiarCodigo(context, f);
          } else {
            widget.onAccion(f, a);
          }
        },
      ),
    ],
  );

  // Dibujo

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final total = widget.filas.length;
    final paginas = math.max(1, (total / _porPagina).ceil());
    final pagina = _pagina.clamp(1, paginas);
    final desde = (pagina - 1) * _porPagina;
    final hasta = math.min(desde + _porPagina, total);
    final visibles = widget.filas.sublist(desde, hasta);

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, restricciones) {
                double pide(List<_Col> lista) =>
                    lista.fold(0.0, (s, c) => s + c.ancho);
                final completas = _columnas(apretada: false);
                final cols =
                    pide(completas) <= restricciones.maxWidth
                        ? completas
                        : _columnas(apretada: true);
                final pedido = pide(cols);
                final ancho = math.max(pedido, restricciones.maxWidth);
                final estirar = ancho - pedido;
                final desborda = pedido > restricciones.maxWidth;

                return ScrollConfiguration(
                  // Sin esto, en web la tabla ancha queda inalcanzable: Flutter saca el mouse de los
                  // dispositivos de arrastre y la rueda va al eje vertical.
                  behavior: const ArrastreLateral(),
                  child: Scrollbar(
                    controller: _scrollH,
                    thumbVisibility: desborda,
                    child: SingleChildScrollView(
                      controller: _scrollH,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: ancho,
                        child: Column(
                          children: [
                            _cabecera(cols, estirar),
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollV,
                                padding: EdgeInsets.zero,
                                itemExtent: _altoFila,
                                itemCount: visibles.length,
                                itemBuilder:
                                    (context, i) =>
                                        _fila(visibles[i], i, cols, estirar),
                              ),
                            ),
                            // Deja pasar la barra horizontal sin que se apoye
                            // encima de la ultima fila.
                            SizedBox(height: desborda ? 10 : 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        _Paginador(
          pagina: pagina,
          paginas: paginas,
          primera: total == 0 ? 0 : desde + 1,
          ultima: hasta,
          total: total,
          porPagina: _porPagina,
          onPagina: (p) => setState(() => _pagina = p),
          onPorPagina:
              (n) => setState(() {
                _porPagina = n;
                _pagina = 1;
              }),
        ),
      ],
    );
  }

  Widget _cabecera(List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: _altoCabecera,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final (i, c) in cols.indexed)
            SizedBox(
              width: c.ancho + (i == _indiceElastico ? estirar : 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                child: Align(
                  alignment: c.alinear,
                  child: Text(
                    c.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: Peso.titulo,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fila(FamiliaVista f, int indice, List<_Col> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => widget.onAbrir(f),
      child: Container(
        decoration: BoxDecoration(
          // El rayado cebra se hace con la superficie del tema y no con un gris
          // fijo: el usuario elige entre nueve semillas y hay modo oscuro.
          color: indice.isEven ? Colors.transparent : cs.surfaceContainerLow,
          border: Border(bottom: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            for (final (i, c) in cols.indexed)
              SizedBox(
                width: c.ancho + (i == _indiceElastico ? estirar : 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                  child: Align(
                    alignment: c.alinear,
                    child: c.celda(context, f),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Celdas

/// Un boton de la fila, con su color como las acciones de las propuestas: se
/// reconoce sin leer el tooltip. 34x34: el `IconButton` de fabrica mide 48 y
/// tres no entran en el alto de renglon de la planilla.
class _BotonFila extends StatelessWidget {
  const _BotonFila({
    required this.matiz,
    required this.icono,
    required this.ayuda,
    required this.onTocar,
  });

  final Color matiz;
  final IconData icono;
  final String ayuda;
  final VoidCallback onTocar;

  @override
  Widget build(BuildContext context) {
    final t = tonosDeMatiz(matiz, Theme.of(context).colorScheme);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: IconButton(
        icon: Icon(icono, size: 18),
        tooltip: ayuda,
        onPressed: onTocar,
        style: IconButton.styleFrom(
          backgroundColor: t.fondo,
          foregroundColor: t.icono,
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Esquina.chica),
            side: BorderSide(color: t.icono.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }
}

/// El resto de las acciones, en un menu con el mismo aspecto que los botones
/// de la fila pero en el tono neutro del tema: grupo o proveedor SAP, baja o
/// reactivacion, copiar el codigo y eliminar.
class _MasAcciones extends StatelessWidget {
  const _MasAcciones({required this.familia, required this.onAccion});

  final FamiliaVista familia;
  final ValueChanged<AccionFamilia> onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: PopupMenuButton<AccionFamilia>(
        tooltip: 'Más acciones de la familia ${familia.codigoLegible}',
        onSelected: onAccion,
        itemBuilder: (_) => itemsAccionesFamilia(familia),
        style: IconButton.styleFrom(
          backgroundColor: cs.surfaceContainerHigh,
          foregroundColor: cs.onSurfaceVariant,
          minimumSize: const Size(34, 34),
          maximumSize: const Size(34, 34),
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Esquina.chica),
            side: BorderSide(color: cs.outlineVariant),
          ),
        ),
        icon: const Icon(Icons.more_horiz, size: 18),
      ),
    );
  }
}

/// Lo que hay en el listado de un vistazo: cuantas, cuantas activas, cuantas
/// inactivas y cuantas todavia sin costo. Cuenta lo que trajo el filtro, no el
/// catalogo entero; una cuenta en cero no se dibuja, salvo el total.
class ResumenFamilias extends StatelessWidget {
  const ResumenFamilias({super.key, required this.filas});

  final List<FamiliaVista> filas;

  @override
  Widget build(BuildContext context) {
    final activas = filas.where((f) => f.esActiva).length;
    final sinCosto = filas.where((f) => f.sinCosto).length;
    final cuentas = <(int, String, String, Color)>[
      (filas.length, 'familia', 'familias', matizAzul),
      (activas, 'activa', 'activas', matizVerde),
      (
        filas.length - activas,
        'inactiva',
        'inactivas',
        const Color(0xFF757575),
      ),
      (sinCosto, 'sin costo', 'sin costo', matizNaranja),
    ];
    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      children: [
        for (final (i, (n, uno, varios, matiz)) in cuentas.indexed)
          if (i == 0 || n > 0)
            _Cuenta(n: n, rotulo: n == 1 ? uno : varios, matiz: matiz),
      ],
    );
  }
}

class _Cuenta extends StatelessWidget {
  const _Cuenta({required this.n, required this.rotulo, required this.matiz});

  final int n;
  final String rotulo;
  final Color matiz;

  @override
  Widget build(BuildContext context) {
    final t = tonosDeMatiz(matiz, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
      decoration: BoxDecoration(
        color: t.fondo,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$n ',
              style: context.numero(fuerte: true, color: t.icono),
            ),
            TextSpan(text: rotulo),
          ],
        ),
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: t.icono),
      ),
    );
  }
}

class _Col {
  const _Col(
    this.rotulo,
    this.ancho,
    this.celda, {
    this.alinear = Alignment.centerLeft,
  });

  final String rotulo;
  final double ancho;
  final Alignment alinear;
  final Widget Function(BuildContext context, FamiliaVista familia) celda;
}

Widget _texto(BuildContext context, String valor) {
  final vacio = valor.trim().isEmpty;
  return Text(
    FamiliaVista.oGuion(valor),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: vacio ? context.cs.onSurfaceVariant : null,
    ),
  );
}

/// Dos datos en una celda: el principal arriba y el que lo acompana abajo, mas
/// chico y apagado. Es lo que deja entrar la tabla apretada en unos 1000 px.
Widget _dosLineas(
  BuildContext context,
  String arriba,
  String abajo, {
  bool fuerte = false,
}) {
  final tt = Theme.of(context).textTheme;
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        FamiliaVista.oGuion(arriba),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tt.bodySmall?.copyWith(fontWeight: fuerte ? Peso.titulo : null),
      ),
      Text(
        FamiliaVista.oGuion(abajo),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: tt.labelSmall?.copyWith(color: context.cs.onSurfaceVariant),
      ),
    ],
  );
}

Widget _cifra(
  BuildContext context,
  String valor, {
  bool fuerte = false,
  bool apagada = false,
}) => Text(
  valor,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: context.numero(
    fuerte: fuerte,
    color: apagada ? context.cs.onSurfaceVariant : null,
  ),
);

// Pie de paginación

/// No usa `BosquePaginator`: pinta su fondo con `Colors.white` y decide si es
/// móvil con `ResponsiveUtilsBosque.isMobile`, que devuelve falso entre 451 y
/// 800 px. Este sale del tema y se acomoda con `Wrap`.
class _Paginador extends StatelessWidget {
  const _Paginador({
    required this.pagina,
    required this.paginas,
    required this.primera,
    required this.ultima,
    required this.total,
    required this.porPagina,
    required this.onPagina,
    required this.onPorPagina,
  });

  final int pagina;
  final int paginas;
  final int primera;
  final int ultima;
  final int total;
  final int porPagina;
  final ValueChanged<int> onPagina;
  final ValueChanged<int> onPorPagina;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: Esp.s),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Esp.l,
        runSpacing: Esp.s,
        children: [
          Text(
            'Mostrando $primera-$ultima de $total familias',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filas',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: Esp.s),
              DropdownButton<int>(
                value: porPagina,
                isDense: true,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(Esquina.chica),
                items: [
                  for (final n in _tamaniosPagina)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (n) {
                  if (n != null) onPorPagina(n);
                },
              ),
              const SizedBox(width: Esp.l),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
                onPressed: pagina > 1 ? () => onPagina(pagina - 1) : null,
              ),
              Text('$pagina de $paginas', style: context.numero(fuerte: true)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Página siguiente',
                onPressed: pagina < paginas ? () => onPagina(pagina + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
