/// Piezas visuales compartidas del módulo de Precios (tpr): las usan el
/// asistente, las propuestas y las demás pantallas. Viven aparte para no repetir
/// ancho de celda, rayado y formato de moneda, y por el molde de tablas (cabecera
/// fija y scroll horizontal controlado para 7 y 12 columnas).
///
/// No usa `BosqueFlatTable`: reparte columnas por `flex` sin ancho mínimo ni
/// scroll lateral y decide escritorio con `ResponsiveUtilsBosque` (ancho de la
/// VENTANA: en un portátil de 1366 dice "escritorio" y el cajón mide 1106, pues
/// el sidebar se come 260 px). Aquí el corte lo decide [Aire] sobre el ancho que
/// entrega `LayoutBuilder`.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';

// Formato

/// Dinero y porcentajes con separador de miles y coma decimal (como se escribe
/// en Bolivia). El patrón va explícito para no depender del locale del
/// dispositivo: la misma propuesta se lee igual en navegador y en teléfono.
final NumberFormat fmtMonto = NumberFormat('#,##0.00', 'es');

/// Cuatro decimales para el precio unitario, que en articulos chicos se juega
/// en la tercera cifra: redondeado a dos, dos articulos distintos salen iguales.
final NumberFormat fmtMontoFino = NumberFormat('#,##0.0000', 'es');

/// Cantidades (UTM, stock): hasta dos decimales, sin ceros de relleno.
final NumberFormat fmtCantidad = NumberFormat('#,##0.##', 'es');

/// Un monto con su moneda adelante. La moneda va como texto y no como simbolo
/// porque el modulo mezcla USD por tonelada y Bs por unidad en la misma grilla.
String montoLegible(double valor, {String moneda = ''}) {
  final numero = fmtMonto.format(valor);
  return moneda.isEmpty ? numero : '$moneda $numero';
}

/// Idem con cuatro decimales, para precios unitarios.
String montoFinoLegible(double valor, {String moneda = ''}) {
  final numero = fmtMontoFino.format(valor);
  return moneda.isEmpty ? numero : '$moneda $numero';
}

/// Porcentaje listo para mostrar, sin ceros de relleno.
String porcentajeLegible(double valor) => '${fmtCantidad.format(valor)} %';

// Lectura de las respuestas crudas: varias lecturas del repositorio devuelven
// `Map<String, dynamic>` (DTO de despliegue, sin tabla detrás) y `as double`
// revienta cuando SQL Server manda un entero sin parte decimal. Estos lectores
// convierten en vez de castear y toleran mayúsculas distintas en la clave.

Object? _valorCrudo(Map<String, dynamic> fila, String clave) {
  if (fila.containsKey(clave)) return fila[clave];
  final buscada = clave.toLowerCase();
  for (final entrada in fila.entries) {
    if (entrada.key.toLowerCase() == buscada) return entrada.value;
  }
  return null;
}

/// Texto de la fila, ya recortado. [siFalta] es lo que se muestra cuando la
/// clave no vino o vino vacia.
String textoCrudo(
  Map<String, dynamic> fila,
  String clave, {
  String siFalta = '',
}) {
  final valor = _valorCrudo(fila, clave);
  if (valor == null) return siFalta;
  final texto = valor.toString().trim();
  return texto.isEmpty ? siFalta : texto;
}

/// Numero de la fila. Acepta int, double y texto: el backend manda cualquiera
/// de los tres segun el tipo de la columna y si el valor tiene decimales.
double numeroCrudo(Map<String, dynamic> fila, String clave) {
  final valor = _valorCrudo(fila, clave);
  if (valor is num) return valor.toDouble();
  if (valor is String) {
    final limpio = valor.trim().replaceAll(',', '.');
    return double.tryParse(limpio) ?? 0;
  }
  return 0;
}

/// Entero de la fila. No se resuelve con `numeroCrudo(...).toInt()` a secas
/// porque un codigo con ceros a la izquierda llega como texto.
int enteroCrudo(Map<String, dynamic> fila, String clave) {
  final valor = _valorCrudo(fila, clave);
  if (valor is int) return valor;
  if (valor is num) return valor.toInt();
  if (valor is String) {
    final directo = int.tryParse(valor.trim());
    if (directo != null) return directo;
  }
  return numeroCrudo(fila, clave).toInt();
}

/// Id de la fila. Las PK del modulo son bigint, por eso BigInt y no int.
BigInt idCrudo(Map<String, dynamic> fila, String clave) =>
    BigInt.from(enteroCrudo(fila, clave));

// La tabla ancha (escritorio)

const double _altoBanda = 24;
const double _altoCabecera = 40;
const double _altoFila = 52;

/// Una columna de [TablaPropuesta].
class ColumnaPropuesta<T> {
  const ColumnaPropuesta(
    this.titulo,
    this.ancho,
    this.celda, {
    this.alinear = Alignment.centerRight,
    this.banda = '',
    this.ayuda,
  });

  final String titulo;

  /// Ancho fijo en píxeles, no `flex`: con doce columnas el reparto
  /// proporcional deja los importes en dos caracteres. Pedir de más es lo
  /// que dispara el scroll horizontal.
  final double ancho;

  final Widget Function(BuildContext contexto, T fila) celda;
  final Alignment alinear;

  /// El grupo al que pertenece, para la banda de arriba. Vacio = sin grupo.
  final String banda;

  /// Que significa la columna, cuando el rotulo no alcanza.
  final String? ayuda;
}

/// Planilla de ancho fijo con cabecera que no se va con el scroll (patrón de
/// `TablaLotes`). Si la suma de anchos no entra aparece el scroll horizontal,
/// arrastrable también con el mouse ([ArrastreLateral]); si sobra lugar, la
/// última columna se estira.
///
/// **Solo para escritorio.** En móvil se reemplaza por tarjetas: doce columnas
/// en un teléfono serían scroll horizontal infinito.
class TablaPropuesta<T> extends StatefulWidget {
  const TablaPropuesta({
    super.key,
    required this.filas,
    required this.columnas,
    this.alTocarFila,
  });

  final List<T> filas;
  final List<ColumnaPropuesta<T>> columnas;
  final void Function(T fila)? alTocarFila;

  @override
  State<TablaPropuesta<T>> createState() => _TablaPropuestaState<T>();
}

class _TablaPropuestaState<T> extends State<TablaPropuesta<T>> {
  final ScrollController _scrollH = ScrollController();

  @override
  void didUpdateWidget(TablaPropuesta<T> anterior) {
    super.didUpdateWidget(anterior);
    // Al cambiar el juego de columnas la tabla se angosta o se ensancha: sin
    // esto queda mirando un hueco a la derecha hasta que alguien la arrastre.
    if (anterior.columnas.length != widget.columnas.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollH.hasClients) _scrollH.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollH.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cols = widget.columnas;
    final hayBandas = cols.any((c) => c.banda.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, restricciones) {
          final pedido = cols.fold(0.0, (suma, c) => suma + c.ancho);
          final ancho = math.max(pedido, restricciones.maxWidth);
          final estirar = ancho - pedido;
          final desborda = pedido > restricciones.maxWidth;

          return ScrollConfiguration(
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
                      if (hayBandas) _banda(cols, estirar),
                      _cabecera(cols, estirar),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemExtent: _altoFila,
                          itemCount: widget.filas.length,
                          itemBuilder: (context, i) => _fila(i, cols, estirar),
                        ),
                      ),
                      // Deja pasar la barra del scroll horizontal sin que se
                      // apoye encima de la ultima fila.
                      SizedBox(height: desborda ? 10 : 0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// La banda que agrupa las columnas por lo que responden.
  Widget _banda(List<ColumnaPropuesta<T>> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;
    final grupos = _agrupar(cols);

    return SizedBox(
      height: _altoBanda,
      child: Row(
        children: [
          for (final (i, g) in grupos.indexed)
            Container(
              width: g.ancho + (i == grupos.length - 1 ? estirar : 0),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: Esp.s),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                border: Border(
                  bottom: BorderSide(
                    color:
                        g.nombre.isEmpty
                            ? Colors.transparent
                            : colorDeCatalogo(cs, i).fondo,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                g.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: Peso.titulo,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cabecera(List<ColumnaPropuesta<T>> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: _altoCabecera,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          for (final (i, col) in cols.indexed)
            _celda(
              col,
              estirar: i == cols.length - 1 ? estirar : 0,
              hijo:
                  col.ayuda == null
                      ? _rotulo(col.titulo)
                      : Tooltip(
                        message: col.ayuda!,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: _rotulo(col.titulo)),
                            const SizedBox(width: Esp.xs),
                            Icon(
                              Icons.info_outline,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
            ),
        ],
      ),
    );
  }

  Widget _rotulo(String texto) => Text(
    texto,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: Peso.titulo,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      letterSpacing: 0.3,
    ),
  );

  /// Una fila por registro. El rayado alterno es lo que deja seguir un renglon
  /// a lo ancho de doce columnas sin perderlo de vista.
  Widget _fila(int i, List<ColumnaPropuesta<T>> cols, double estirar) {
    final cs = Theme.of(context).colorScheme;
    final fila = widget.filas[i];

    final contenido = Row(
      children: [
        for (final (j, col) in cols.indexed)
          _celda(
            col,
            estirar: j == cols.length - 1 ? estirar : 0,
            hijo: col.celda(context, fila),
          ),
      ],
    );

    return Material(
      color: i.isOdd ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
      child:
          widget.alTocarFila == null
              ? contenido
              : InkWell(
                onTap: () => widget.alTocarFila!(fila),
                child: contenido,
              ),
    );
  }

  Widget _celda(
    ColumnaPropuesta<T> col, {
    required Widget hijo,
    double estirar = 0,
  }) => Container(
    width: col.ancho + estirar,
    alignment: col.alinear,
    padding: const EdgeInsets.symmetric(horizontal: Esp.s),
    child: hijo,
  );
}

typedef _Grupo = ({String nombre, double ancho});

/// Junta las columnas contiguas que comparten banda.
List<_Grupo> _agrupar<T>(List<ColumnaPropuesta<T>> cols) {
  final grupos = <_Grupo>[];
  for (final col in cols) {
    if (grupos.isNotEmpty && grupos.last.nombre == col.banda) {
      grupos[grupos.length - 1] = (
        nombre: col.banda,
        ancho: grupos.last.ancho + col.ancho,
      );
    } else {
      grupos.add((nombre: col.banda, ancho: col.ancho));
    }
  }
  return grupos;
}

/// Celda de texto de la planilla.
Widget celdaTexto(
  BuildContext context,
  String texto, {
  bool fuerte = false,
  Color? color,
  int maxLineas = 1,
}) => Text(
  texto.isEmpty ? '--' : texto,
  maxLines: maxLineas,
  overflow: TextOverflow.ellipsis,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    fontWeight: fuerte ? Peso.dato : Peso.normal,
    color: color,
  ),
);

/// Celda numérica: cifras tabulares para que los dígitos no bailen de fila en
/// fila (sin esto una columna de importes es imposible de recorrer).
Widget celdaNumero(
  BuildContext context,
  String texto, {
  bool fuerte = false,
  Color? color,
}) => Text(
  texto,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: context.numero(fuerte: fuerte, color: color),
);

// Las piezas del móvil y de los paneles

/// Un dato con su rotulo, en una linea. Es la unidad de las tarjetas del movil
/// y de la ficha de la propuesta.
class FilaDeDato extends StatelessWidget {
  const FilaDeDato({
    super.key,
    required this.rotulo,
    required this.valor,
    this.color,
    this.fuerte = false,
    this.esNumero = true,
  });

  final String rotulo;
  final String valor;
  final Color? color;
  final bool fuerte;

  /// Los importes van con cifras tabulares; los textos, no.
  final bool esNumero;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Esp.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              rotulo,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: Esp.s),
          Expanded(
            flex: 5,
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  esNumero
                      ? Text(
                        valor,
                        textAlign: TextAlign.right,
                        style: context.numero(fuerte: fuerte, color: color),
                      )
                      : Text(
                        valor,
                        textAlign: TextAlign.right,
                        style: tt.bodySmall?.copyWith(
                          fontWeight: fuerte ? Peso.dato : Peso.normal,
                          color: color,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La tarjeta que reemplaza a la fila de la tabla cuando el cajón es angosto. No
/// es la tabla escalada: el título y lo que se compara suben, el resto baja a
/// pares rótulo/valor y las acciones van en un menú contextual.
class TarjetaPropuesta extends StatelessWidget {
  const TarjetaPropuesta({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.etiqueta,
    this.destacado,
    this.datos = const <Widget>[],
    this.acciones = const <PopupMenuEntry<String>>[],
    this.alElegirAccion,
    this.alTocar,
  });

  final String titulo;
  final String? subtitulo;

  /// Chip de estado, a la derecha del titulo.
  final Widget? etiqueta;

  /// El bloque que la tarjeta pone por encima de los pares rotulo/valor: es lo
  /// que se mira primero, tipicamente la comparacion de precios.
  final Widget? destacado;

  final List<Widget> datos;

  /// Las acciones van en un menú y no en botones sueltos: en cincuenta tarjetas,
  /// dos botones por tarjeta son cien blancos de toque compitiendo con el scroll.
  final List<PopupMenuEntry<String>> acciones;
  final void Function(String opcion)? alElegirAccion;

  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: Esp.s),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(Esp.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: Peso.titulo,
                          ),
                        ),
                        if (subtitulo != null && subtitulo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitulo!,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (etiqueta != null) ...[
                    const SizedBox(width: Esp.s),
                    etiqueta!,
                  ],
                  if (acciones.isNotEmpty)
                    PopupMenuButton<String>(
                      tooltip: 'Acciones',
                      icon: const Icon(Icons.more_vert, size: 20),
                      itemBuilder: (_) => acciones,
                      onSelected: alElegirAccion,
                    ),
                ],
              ),
              if (destacado != null) ...[
                const SizedBox(height: Esp.s),
                destacado!,
              ],
              if (datos.isNotEmpty) ...[
                const SizedBox(height: Esp.xs),
                const Divider(height: Esp.m),
                ...datos,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Una seccion con titulo, para los paneles de la pestania de datos.
class BloquePanel extends StatelessWidget {
  const BloquePanel({
    super.key,
    required this.titulo,
    required this.hijo,
    this.subtitulo,
    this.acciones = const <Widget>[],
    this.icono,
  });

  final String titulo;
  final String? subtitulo;
  final IconData? icono;
  final List<Widget> acciones;
  final Widget hijo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Esquina.media),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap y no Row: con el titulo, la bajada y dos botones, en un
            // telefono de 360 px la fila se desborda.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: Esp.m,
              runSpacing: Esp.s,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icono != null) ...[
                      Icon(icono, size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: Esp.s),
                    ],
                    Text(
                      titulo,
                      style: tt.titleSmall?.copyWith(fontWeight: Peso.titulo),
                    ),
                  ],
                ),
                if (acciones.isNotEmpty)
                  Wrap(spacing: Esp.s, children: acciones),
              ],
            ),
            if (subtitulo != null && subtitulo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: Esp.xs),
                child: Text(
                  subtitulo!,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: Esp.m),
            hijo,
          ],
        ),
      ),
    );
  }
}

/// El buscador de una grilla.
class BuscadorPropuesta extends StatelessWidget {
  const BuscadorPropuesta({
    super.key,
    required this.texto,
    required this.alCambiar,
    this.pista = 'Buscar...',
    this.ancho,
  });

  final String texto;
  final ValueChanged<String> alCambiar;
  final String pista;

  /// Ancho fijo en escritorio. Null = ocupa lo que haya, que es lo que se usa
  /// en movil.
  final double? ancho;

  @override
  Widget build(BuildContext context) {
    final campo = TextFormField(
      initialValue: texto,
      onChanged: alCambiar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: pista,
        prefixIcon: const Icon(Icons.search, size: 20),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
      ),
    );
    return ancho == null ? campo : SizedBox(width: ancho, child: campo);
  }
}

/// Los filtros de una grilla: a la vista en escritorio, plegados en móvil (en un
/// teléfono se comen la mitad del alto útil y quien entra a mirar una propuesta
/// viene a ver precios, no a filtrar).
class FiltrosPropuesta extends StatelessWidget {
  const FiltrosPropuesta({
    super.key,
    required this.compacto,
    required this.hijos,
    this.resumen,
  });

  /// Viene del ancho del cajon, no de `MediaQuery`.
  final bool compacto;

  final List<Widget> hijos;

  /// Que filtros hay puestos, para poder saberlo con el panel cerrado.
  final String? resumen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!compacto) {
      return Wrap(
        spacing: Esp.m,
        runSpacing: Esp.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: hijos,
      );
    }

    return Theme(
      // El ExpansionTile de Material 3 dibuja una linea arriba y otra abajo que
      // aquí se suman al borde de la tarjeta y quedan tres rayas juntas.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: const Icon(Icons.filter_list, size: 20),
          title: Text(
            'Filtros',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: Peso.titulo),
          ),
          subtitle:
              (resumen == null || resumen!.isEmpty)
                  ? null
                  : Text(
                    resumen!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
          childrenPadding: const EdgeInsets.fromLTRB(Esp.m, 0, Esp.m, Esp.m),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final hijo in hijos)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.s),
                child: hijo,
              ),
          ],
        ),
      ),
    );
  }
}
