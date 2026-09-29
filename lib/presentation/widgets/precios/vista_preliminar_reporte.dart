/// La vista preliminar de una propuesta con las filas de su PDF (rptPropuArt
/// por familia, RptArtPropuPorArticulo por articulo), sus rotulos, sus colores
/// y el formato de sus numeros (1,714.26).
///
/// Los datos salen de `/price/vistaPropuesta`, que el backend arma con los
/// mismos procedimientos que el reporte y que el Excel de la generacion: si la
/// pantalla, el papel y el archivo no coinciden, el error esta en un solo
/// lugar.
///
/// * **Por tonelada:** por familia, cada articulo con tres filas, como en el
///   PDF -el porcentaje de cada lista, el precio actual y el propuesto, verde
///   si sube y rojo si baja-. Una propuesta ya aprobada no trae precio actual:
///   quedan dos filas, sin colores. Por articulo, una fila con el precio que
///   toma de su familia.
/// * **Por unidad** (Bs, USD, Bs Productiva): una fila por articulo con el
///   precio por unidad de cada lista, y en la fila de la familia el precio por
///   tonelada del que sale. Bs y Bs Productiva son las dos columnas de precio
///   del Excel de la generacion.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/vista_propuesta_entity.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cifra_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/tabla_propuestas.dart';

/// Los numeros como en el PDF: coma para los miles y punto para los decimales.
final NumberFormat fmtComoPdf = NumberFormat('#,##0.00', 'en_US');
final NumberFormat fmtComoPdfFino = NumberFormat('#,##0.0000', 'en_US');

/// El tipo de cambio sin ceros de relleno: 12.22, 6.96.
final NumberFormat fmtTipoCambio = NumberFormat('#,##0.00##', 'en_US');

/// El rojo del "Menor al precio actual" (el verde es [matizVerde]).
const Color _matizRojo = Color(0xFFC62828);

/// Que precio se muestra.
enum MedidaVista {
  tonelada(
    'Por tonelada',
    'Como el PDF: porcentaje, precio actual y precio propuesto por tonelada '
        'en USD',
    'USD/t',
  ),
  bs('Bs', 'Precio por unidad en bolivianos (Impexpap)', 'Bs'),
  usd('USD', 'Precio por unidad en dólares (Impexpap)', 'USD'),
  bsProductiva(
    'Bs Productiva',
    'Precio por unidad en bolivianos de Productiva: el de Impexpap menos 7 %',
    'Bs Prod.',
  );

  const MedidaVista(this.etiqueta, this.ayuda, this.corto);

  final String etiqueta;
  final String ayuda;

  /// El rotulo de la fila en las tarjetas del telefono.
  final String corto;

  bool get porUnidad => this != MedidaVista.tonelada;

  /// Los precios por unidad de [f] en esta medida (vacia por tonelada).
  List<double?> valores(FilaVistaPropuestaEntity f) => switch (this) {
    MedidaVista.tonelada => const [],
    MedidaVista.bs => f.unidadBs,
    MedidaVista.usd => f.unidadUsd,
    MedidaVista.bsProductiva => f.unidadBsProductiva,
  };

  /// Como se llega al numero: es lo que hay que poder verificar.
  String explicacion(double? tipoCambio) {
    final tc = tipoCambio == null ? '' : ' ${fmtTipoCambio.format(tipoCambio)}';
    return switch (this) {
      MedidaVista.tonelada => 'Como el PDF: precios por tonelada en USD.',
      MedidaVista.usd =>
        'Precio por unidad en USD = precio por tonelada ÷ UTM.',
      MedidaVista.bs =>
        'Precio por unidad en Bs = precio por tonelada ÷ UTM × tipo de cambio'
            '$tc (el último de SAP). Es la columna «Precio Unit. IPX (BS)» '
            'del Excel de la generación.',
      MedidaVista.bsProductiva =>
        'Bs Productiva = el precio por unidad en Bs menos 7 %. Es la columna '
            '«Precio Unit. PRODUCTIVA (BS)» del Excel de la generación.',
    };
  }
}

/// Las filas de detalle de un articulo en la vista por tonelada, con el
/// rotulo de la columna DETALLE del PDF.
enum DetalleReporte {
  porcentaje('Porcentajes %'),
  actual('Precio Ton. Actual'),
  propuesto('Precio Ton. Propuesto'),
  precio('Precio Ton.');

  const DetalleReporte(this.etiqueta);

  final String etiqueta;

  double? valor(FilaVistaPropuestaEntity f, int vpp) => switch (this) {
    DetalleReporte.porcentaje => FilaVistaPropuestaEntity.de(
      f.porcentajes,
      vpp,
    ),
    DetalleReporte.actual => FilaVistaPropuestaEntity.de(f.actuales, vpp),
    DetalleReporte.propuesto ||
    DetalleReporte.precio => FilaVistaPropuestaEntity.de(f.propuestos, vpp),
  };

  /// Solo el propuesto se compara contra el actual.
  int? cambio(FilaVistaPropuestaEntity f, int vpp) =>
      this == DetalleReporte.propuesto
          ? FilaVistaPropuestaEntity.de(f.cambios, vpp)
          : null;
}

/// Las filas de detalle de [f], en el orden del PDF.
List<DetalleReporte> detallesDe(
  VistaPropuestaEntity v,
  FilaVistaPropuestaEntity f,
) =>
    v.porArticulo
        ? const [DetalleReporte.precio]
        : [
          DetalleReporte.porcentaje,
          if (f.conFilaActual) DetalleReporte.actual,
          DetalleReporte.propuesto,
        ];

/// El fondo y la tinta de una celda del propuesto que sube o baja.
({Color fondo, Color tinta})? tonoDeCambio(int? cambio, ColorScheme cs) {
  if (cambio == null || cambio == 0) return null;
  final t = tonosDeMatiz(cambio > 0 ? matizVerde : _matizRojo, cs);
  return (fondo: t.fondo, tinta: t.icono);
}

/// Los grupos de columnas: (sucursal, cuantas listas seguidas).
List<(String, int)> gruposDeSucursal(List<ListaVistaPropuestaEntity> listas) {
  final grupos = <(String, int)>[];
  for (final l in listas) {
    if (grupos.isNotEmpty && grupos.last.$1 == l.sucursal) {
      grupos[grupos.length - 1] = (l.sucursal, grupos.last.$2 + 1);
    } else {
      grupos.add((l.sucursal, 1));
    }
  }
  return grupos;
}

/// El titulo de la cabecera de una familia.
String tituloDeFamilia(VistaPropuestaEntity v, FilaVistaPropuestaEntity f) {
  final partes = <String>[
    'Familia ${f.codigoFamilia}',
    if (f.descripcionFamilia.trim().isNotEmpty) f.descripcionFamilia.trim(),
    if (v.porArticulo)
      f.ultimaPropuesta == null
          ? 'sin propuesta aprobada'
          : 'última propuesta aprobada N.º ${f.ultimaPropuesta}',
  ];
  return partes.join(' · ');
}

bool coincideEnVista(FilaVistaPropuestaEntity f, String texto) =>
    f.coincide(texto) || '${f.codigoFamilia}' == texto;

/// La leyenda de colores del PDF: solo si hay precio actual con que comparar.
class LeyendaComparacion extends StatelessWidget {
  const LeyendaComparacion({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget chip(int cambio, String texto) {
      final t = tonoDeCambio(cambio, cs)!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 2),
        decoration: BoxDecoration(
          color: t.fondo,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Text(
          texto,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: t.tinta,
            fontWeight: Peso.titulo,
          ),
        ),
      );
    }

    return Wrap(
      spacing: Esp.s,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Precio propuesto:', style: context.apagado()),
        chip(1, 'Mayor al precio actual'),
        chip(-1, 'Menor al precio actual'),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ESCRITORIO
// ═══════════════════════════════════════════════════════════════════════════

const double _anchoArticulo = 280;
const double _anchoUtm = 100;
const double _anchoCosto = 92;
const double _anchoDetalle = 164;
const double _anchoLista = 88;
const double _altoBanda = 28;
const double _altoTitulo = 32;

enum _Clase { familia, detalle, unidad }

/// Un renglon: la cabecera de una familia, una fila de detalle (por
/// tonelada) o la fila de un articulo (por unidad).
@immutable
class _Renglon {
  const _Renglon.familia(this.fila)
    : clase = _Clase.familia,
      detalle = null,
      numero = 0,
      primero = false,
      ultimo = true;
  const _Renglon.detalle(
    this.fila,
    DetalleReporte this.detalle, {
    required this.numero,
    required this.primero,
    required this.ultimo,
  }) : clase = _Clase.detalle;
  const _Renglon.unidad(this.fila, {required this.numero})
    : clase = _Clase.unidad,
      detalle = null,
      primero = true,
      ultimo = true;

  final _Clase clase;
  final FilaVistaPropuestaEntity fila;
  final DetalleReporte? detalle;

  /// El orden del articulo, para alternar el fondo por articulo y no por fila.
  final int numero;
  final bool primero;
  final bool ultimo;

  bool get esFamilia => clase == _Clase.familia;
}

List<_Renglon> _renglones(
  VistaPropuestaEntity v,
  MedidaVista medida,
  String texto,
) {
  final r = <_Renglon>[];
  int? familia;
  var numero = 0;
  for (final f in v.filas) {
    if (!coincideEnVista(f, texto)) continue;
    if (f.codigoFamilia != familia) {
      familia = f.codigoFamilia;
      r.add(_Renglon.familia(f));
    }
    if (medida.porUnidad) {
      r.add(_Renglon.unidad(f, numero: numero));
    } else {
      final detalles = detallesDe(v, f);
      for (final (i, d) in detalles.indexed) {
        r.add(
          _Renglon.detalle(
            f,
            d,
            numero: numero,
            primero: i == 0,
            ultimo: i == detalles.length - 1,
          ),
        );
      }
    }
    numero++;
  }
  return r;
}

/// La tabla con el articulo fijo a la izquierda: dos paneles con su propia
/// lista vertical que se mueven juntos. Doce listas no entran en un portatil,
/// y si el articulo se fuera con el desplazamiento quedaria una grilla de
/// numeros sin nombre.
class TablaReportePropuesta extends StatefulWidget {
  const TablaReportePropuesta({
    super.key,
    required this.vista,
    required this.medida,
    required this.texto,
  });

  final VistaPropuestaEntity vista;
  final MedidaVista medida;
  final String texto;

  @override
  State<TablaReportePropuesta> createState() => _TablaReportePropuestaState();
}

class _TablaReportePropuestaState extends State<TablaReportePropuesta> {
  final _horizontal = ScrollController();
  final _fijo = ScrollController();
  final _listas = ScrollController();
  bool _siguiendo = false;

  @override
  void initState() {
    super.initState();
    _fijo.addListener(() => _seguir(_fijo, _listas));
    _listas.addListener(() => _seguir(_listas, _fijo));
  }

  void _seguir(ScrollController desde, ScrollController hacia) {
    if (_siguiendo || !hacia.hasClients || !desde.hasClients) return;
    if (hacia.offset == desde.offset) return;
    _siguiendo = true;
    hacia.jumpTo(desde.offset);
    _siguiendo = false;
  }

  @override
  void dispose() {
    _horizontal.dispose();
    _fijo.dispose();
    _listas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = widget.vista;
    final medida = widget.medida;
    final renglones = _renglones(v, medida, widget.texto);
    // Por familia y por tonelada son tres filas cortas por articulo, con el
    // codigo en la primera y la descripcion en la segunda, como las celdas
    // combinadas del PDF. Lo demas es una fila por articulo, de dos renglones.
    final conDetalle = !medida.porUnidad && !v.porArticulo;
    final alto = conDetalle ? 30.0 : 44.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.m),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(Esquina.media),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, r) {
            final fijo =
                _anchoArticulo +
                _anchoUtm +
                _anchoCosto +
                (conDetalle ? _anchoDetalle : 0);
            final precios = v.listas.length * _anchoLista;
            final desborda = fijo + precios > r.maxWidth;
            final extra = desborda ? 0.0 : r.maxWidth - fijo - precios;
            final pie = SizedBox(height: desborda ? 12 : 0);

            Widget lista(ScrollController c, Widget Function(int) fila) =>
                ListView.builder(
                  controller: c,
                  padding: EdgeInsets.zero,
                  itemExtent: alto,
                  itemCount: renglones.length,
                  itemBuilder: (_, i) => fila(i),
                );

            final panelFijo = Container(
              width: fijo + extra,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: desborda ? cs.outline : cs.outlineVariant,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _TitulosFijos(
                    porArticulo: v.porArticulo,
                    conDetalle: conDetalle,
                  ),
                  Expanded(
                    child: lista(
                      _fijo,
                      (i) => _FilaFija(
                        vista: v,
                        medida: medida,
                        renglon: renglones[i],
                        conDetalle: conDetalle,
                      ),
                    ),
                  ),
                  pie,
                ],
              ),
            );

            final panelListas = Scrollbar(
              controller: _horizontal,
              thumbVisibility: desborda,
              child: SingleChildScrollView(
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: precios,
                  child: Column(
                    children: [
                      _Bandas(listas: v.listas),
                      _Titulos(listas: v.listas),
                      Expanded(
                        child: lista(
                          _listas,
                          (i) => _FilaDeListas(
                            renglon: renglones[i],
                            listas: v.listas,
                            medida: medida,
                          ),
                        ),
                      ),
                      pie,
                    ],
                  ),
                ),
              ),
            );

            return ScrollConfiguration(
              behavior: const ArrastreLateral().copyWith(scrollbars: false),
              child: Scrollbar(
                controller: _listas,
                notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [panelFijo, Expanded(child: panelListas)],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

TextStyle? _estiloTitulo(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

/// El fondo de un renglon: alterna por articulo, no por fila, y cierra el
/// articulo con una linea como la grilla del PDF.
BoxDecoration _fondoDe(ColorScheme cs, _Renglon r) {
  if (r.esFamilia) {
    return BoxDecoration(
      color: cs.secondaryContainer.withValues(alpha: 0.55),
      border: Border(
        top: BorderSide(color: cs.outlineVariant),
        bottom: BorderSide(color: cs.outlineVariant),
      ),
    );
  }
  return BoxDecoration(
    color: r.numero.isEven ? cs.surfaceContainerLowest : cs.surfaceContainerLow,
    border:
        r.ultimo
            ? Border(
              bottom: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
            )
            : null,
  );
}

class _TitulosFijos extends StatelessWidget {
  const _TitulosFijos({required this.porArticulo, required this.conDetalle});

  final bool porArticulo;
  final bool conDetalle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = _estiloTitulo(context);
    Widget titulo(String texto, double ancho, String ayuda) => SizedBox(
      width: ancho,
      child: Padding(
        padding: const EdgeInsets.only(right: Esp.s),
        child: Tooltip(
          message: ayuda,
          child: Text(texto, textAlign: TextAlign.right, style: estilo),
        ),
      ),
    );

    return Container(
      height: _altoBanda + _altoTitulo,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      alignment: Alignment.bottomLeft,
      child: SizedBox(
        height: _altoTitulo,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Esp.m),
                child: Text('Artículo', style: estilo),
              ),
            ),
            titulo(
              'UTM',
              _anchoUtm,
              'Unidades por tonelada con que se divide el precio',
            ),
            titulo(
              porArticulo ? 'Costo actual' : 'Costo',
              _anchoCosto,
              'Costo por tonelada en USD',
            ),
            if (conDetalle)
              SizedBox(
                width: _anchoDetalle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                  child: Text('Detalle', style: estilo),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bandas extends StatelessWidget {
  const _Bandas({required this.listas});

  final List<ListaVistaPropuestaEntity> listas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHigh,
      height: _altoBanda,
      child: Row(
        children: [
          for (final (i, (nombre, n)) in gruposDeSucursal(listas).indexed)
            SizedBox(
              width: n * _anchoLista,
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorDeCatalogo(cs, i).fondo,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _estiloTitulo(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Los numeros de lista, como el encabezado del PDF.
class _Titulos extends StatelessWidget {
  const _Titulos({required this.listas});

  final List<ListaVistaPropuestaEntity> listas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onSurfaceVariant,
    );
    return Container(
      height: _altoTitulo,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final l in listas)
            SizedBox(
              width: _anchoLista,
              child: Padding(
                padding: const EdgeInsets.only(right: Esp.s),
                child: Text(
                  '${l.vpp}',
                  textAlign: TextAlign.right,
                  style: estilo,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaFija extends StatelessWidget {
  const _FilaFija({
    required this.vista,
    required this.medida,
    required this.renglon,
    required this.conDetalle,
  });

  final VistaPropuestaEntity vista;
  final MedidaVista medida;
  final _Renglon renglon;
  final bool conDetalle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final f = renglon.fila;

    if (renglon.esFamilia) {
      // Por unidad, las celdas de la familia llevan el precio por tonelada
      // del que sale cada precio por unidad: se dice debajo del titulo.
      final bajada =
          medida.porUnidad
              ? 'Precio por tonelada en USD, lista por lista'
              : null;
      return Container(
        decoration: _fondoDe(cs, renglon),
        padding: const EdgeInsets.symmetric(horizontal: Esp.m),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tituloDeFamilia(vista, f),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelLarge?.copyWith(
                fontWeight: Peso.dato,
                color: cs.onSecondaryContainer,
              ),
            ),
            if (bajada != null)
              Text(
                bajada,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSecondaryContainer),
              ),
          ],
        ),
      );
    }

    final codigo = Text(
      f.codArticulo,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.numero(fuerte: true),
    );
    final descripcion = Tooltip(
      message: f.descripcion,
      child: Text(
        f.descripcion,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.apagado(),
      ),
    );

    // Por familia y por tonelada el articulo ocupa sus tres filas: codigo en
    // la primera, descripcion en la segunda. Lo demas va en su unica fila.
    final Widget articulo;
    if (!conDetalle) {
      articulo = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [codigo, descripcion],
      );
    } else if (renglon.primero) {
      articulo = codigo;
    } else if (renglon.detalle == detallesDe(vista, f)[1]) {
      articulo = descripcion;
    } else {
      articulo = const SizedBox();
    }

    Widget cifra(String texto, double ancho, {bool fuerte = false}) => SizedBox(
      width: ancho,
      child: Padding(
        padding: const EdgeInsets.only(right: Esp.s),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            renglon.primero ? texto : '',
            maxLines: 1,
            style: context.numero(fuerte: fuerte),
          ),
        ),
      ),
    );

    return Container(
      decoration: _fondoDe(cs, renglon),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Esp.xl, 0, Esp.m, 0),
              child: Align(alignment: Alignment.centerLeft, child: articulo),
            ),
          ),
          cifra(fmtComoPdf.format(f.utm), _anchoUtm),
          cifra(fmtComoPdf.format(f.costoTM), _anchoCosto, fuerte: true),
          if (conDetalle)
            SizedBox(
              width: _anchoDetalle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Esp.s),
                child: Text(
                  renglon.detalle!.etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.apagado(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaDeListas extends StatelessWidget {
  const _FilaDeListas({
    required this.renglon,
    required this.listas,
    required this.medida,
  });

  final _Renglon renglon;
  final List<ListaVistaPropuestaEntity> listas;
  final MedidaVista medida;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = renglon.fila;
    final List<Widget> celdas;
    switch (renglon.clase) {
      case _Clase.familia:
        // Por tonelada la familia es solo un titulo: sus precios estan en las
        // filas de cada articulo, como en el PDF.
        celdas = [
          if (medida.porUnidad)
            for (final l in listas)
              _Celda(
                texto: _texto(
                  FilaVistaPropuestaEntity.de(f.propuestos, l.vpp),
                  fmtComoPdf,
                ),
                fuerte: true,
                tinta: cs.onSecondaryContainer,
              ),
        ];
      case _Clase.detalle:
        final d = renglon.detalle!;
        celdas = [
          for (final l in listas)
            Builder(
              builder: (context) {
                final tono = tonoDeCambio(d.cambio(f, l.vpp), cs);
                return _Celda(
                  texto: _texto(d.valor(f, l.vpp), fmtComoPdf),
                  fondo: tono?.fondo,
                  tinta: tono?.tinta,
                  fuerte:
                      tono != null ||
                      d == DetalleReporte.propuesto ||
                      d == DetalleReporte.precio,
                );
              },
            ),
        ];
      case _Clase.unidad:
        final valores = medida.valores(f);
        celdas = [
          for (final l in listas)
            _Celda(
              texto: _texto(
                FilaVistaPropuestaEntity.de(valores, l.vpp),
                fmtComoPdfFino,
              ),
            ),
        ];
    }
    return Container(
      decoration: _fondoDe(cs, renglon),
      child: Row(children: celdas),
    );
  }
}

String _texto(double? v, NumberFormat f) => v == null ? '--' : f.format(v);

class _Celda extends StatelessWidget {
  const _Celda({
    required this.texto,
    this.fondo,
    this.tinta,
    this.fuerte = false,
  });

  final String texto;
  final Color? fondo;
  final Color? tinta;
  final bool fuerte;

  @override
  Widget build(BuildContext context) => Container(
    width: _anchoLista,
    color: fondo,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: Esp.s),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        texto,
        maxLines: 1,
        style: context.numero(fuerte: fuerte, color: tinta),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TELEFONO: una sucursal por vez, un articulo por tarjeta
// ═══════════════════════════════════════════════════════════════════════════

/// La vista angosta: cada articulo en una tarjeta con las cuatro listas de
/// la sucursal elegida, sin scroll lateral.
class ReportePropuestaSucursal extends StatelessWidget {
  const ReportePropuestaSucursal({
    super.key,
    required this.vista,
    required this.medida,
    required this.texto,
    required this.sucursal,
  });

  final VistaPropuestaEntity vista;
  final MedidaVista medida;
  final String texto;
  final String sucursal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final listas = [
      for (final l in vista.listas)
        if (l.sucursal == sucursal) l,
    ];

    final hijos = <Widget>[];
    int? familia;
    for (final f in vista.filas) {
      if (!coincideEnVista(f, texto)) continue;
      if (f.codigoFamilia != familia) {
        familia = f.codigoFamilia;
        hijos.add(
          Container(
            margin: const EdgeInsets.only(bottom: Esp.s),
            padding: const EdgeInsets.all(Esp.m),
            decoration: BoxDecoration(
              color: cs.secondaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloDeFamilia(vista, f),
                  style: tt.titleSmall?.copyWith(
                    fontWeight: Peso.dato,
                    color: cs.onSecondaryContainer,
                  ),
                ),
                // Por unidad, el precio por tonelada del que sale cada uno.
                if (medida.porUnidad) ...[
                  const SizedBox(height: Esp.s),
                  _TablaListas(
                    listas: listas,
                    filas: [
                      (
                        MedidaVista.tonelada.corto,
                        (vpp) => FilaVistaPropuestaEntity.de(f.propuestos, vpp),
                        (int vpp) => null,
                        fmtComoPdf,
                      ),
                    ],
                    tinta: cs.onSecondaryContainer,
                  ),
                ],
              ],
            ),
          ),
        );
      }
      hijos.add(
        _TarjetaArticulo(vista: vista, medida: medida, fila: f, listas: listas),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Esp.m, 0, Esp.m, Esp.m),
      children: hijos,
    );
  }
}

/// Una fila de la tabla de una tarjeta: rotulo, valor por VPP, cambio por
/// VPP (para el color) y formato.
typedef _FilaTarjeta =
    (String, double? Function(int vpp), int? Function(int vpp), NumberFormat);

class _TarjetaArticulo extends StatelessWidget {
  const _TarjetaArticulo({
    required this.vista,
    required this.medida,
    required this.fila,
    required this.listas,
  });

  final VistaPropuestaEntity vista;
  final MedidaVista medida;
  final FilaVistaPropuestaEntity fila;
  final List<ListaVistaPropuestaEntity> listas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = fila;

    // Los rotulos cortos: en un telefono "Precio Ton. Propuesto" se come la
    // mitad del ancho.
    String corto(DetalleReporte d) => switch (d) {
      DetalleReporte.porcentaje => '%',
      DetalleReporte.actual => 'Actual',
      DetalleReporte.propuesto => 'Propuesto',
      DetalleReporte.precio => 'Precio',
    };

    final List<_FilaTarjeta> filas =
        medida.porUnidad
            ? [
              (
                medida.corto,
                (vpp) => FilaVistaPropuestaEntity.de(medida.valores(f), vpp),
                (int vpp) => null,
                fmtComoPdfFino,
              ),
            ]
            : [
              for (final d in detallesDe(vista, f))
                (
                  corto(d),
                  (vpp) => d.valor(f, vpp),
                  (vpp) => d.cambio(f, vpp),
                  fmtComoPdf,
                ),
            ];

    return Container(
      margin: const EdgeInsets.only(bottom: Esp.s),
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.codArticulo, style: context.numero(fuerte: true)),
          Text(f.descripcion, style: context.apagado()),
          const SizedBox(height: Esp.xs),
          Text(
            'UTM ${fmtComoPdf.format(f.utm)} · '
            '${vista.porArticulo ? 'Costo actual' : 'Costo'} '
            '${fmtComoPdf.format(f.costoTM)} USD/t',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.s),
          _TablaListas(listas: listas, filas: filas),
        ],
      ),
    );
  }
}

/// Las listas de una sucursal en columnas y las filas pedidas, con el color
/// del propuesto donde corresponde.
class _TablaListas extends StatelessWidget {
  const _TablaListas({required this.listas, required this.filas, this.tinta});

  final List<ListaVistaPropuestaEntity> listas;
  final List<_FilaTarjeta> filas;
  final Color? tinta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Table(
      columnWidths: const {0: FixedColumnWidth(72)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox(),
            for (final l in listas)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.xs),
                child: Text(
                  '${l.vpp}',
                  textAlign: TextAlign.right,
                  style: _estiloTitulo(context)?.copyWith(color: tinta),
                ),
              ),
          ],
        ),
        for (final (rotulo, valor, cambio, formato) in filas)
          TableRow(
            children: [
              Text(rotulo, style: context.apagado()?.copyWith(color: tinta)),
              for (final l in listas)
                Builder(
                  builder: (context) {
                    final tono = tonoDeCambio(cambio(l.vpp), cs);
                    final v = valor(l.vpp);
                    return Container(
                      color: tono?.fondo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 3,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          v == null ? '--' : formato.format(v),
                          style: context.numero(
                            fuerte: true,
                            color: tono?.tinta ?? tinta,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }
}
