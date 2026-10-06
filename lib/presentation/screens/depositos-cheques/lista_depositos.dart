import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:flutter/material.dart';

/// Widgets de presentación del listado de depósitos: tabla con una columna por
/// dato en anchos grandes y medios, y tarjetas en los chicos. No conocen el
/// estado ni el notifier; las acciones por fila llegan ya construidas.

/// Ancho del área de resultados desde el cual se usa tabla. Se mide el ancho
/// del contenedor y no el de la ventana: dentro del dashboard el menú lateral
/// se come su parte.
const double anchoMinimoTabla = 720;

/// Ancho mínimo de una tarjeta; decide cuántas caben por fila.
const double anchoMinimoTarjeta = 340;

/// Construye las acciones de una fila. `compacto` reduce el área táctil de los
/// botones (tabla con mouse); en tarjetas se dejan al tamaño táctil completo.
typedef ConstructorAcciones =
    Widget Function(DepositoChequeEntity deposito, {required bool compacto});

/// Fondo suave de una fila rechazada. En oscuro el contenedor de error es un
/// granate profundo: con la misma intensidad que en claro pesaría demasiado.
Color _tinteRechazado(ColorScheme cs) => Color.alphaBlend(
  cs.errorContainer.withValues(
    alpha: cs.brightness == Brightness.dark ? 0.12 : 0.25,
  ),
  cs.surface,
);

bool depositoRechazado(DepositoChequeEntity d) =>
    d.esPendiente.trim().toLowerCase() == 'rechazado';

/// Elige tabla o tarjetas según el ancho que hay. [pie] (la paginación) va
/// dentro de la tabla, y debajo de las tarjetas.
class ListaDepositos extends StatelessWidget {
  const ListaDepositos({
    super.key,
    required this.depositos,
    required this.acciones,
    required this.pie,
  });

  final List<DepositoChequeEntity> depositos;
  final ConstructorAcciones acciones;
  final Widget pie;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= anchoMinimoTabla) {
          return _TablaDepositos(
            key: const ValueKey('lista-tabla'),
            depositos: depositos,
            acciones: acciones,
            pie: pie,
          );
        }
        return _TarjetasDepositos(
          key: const ValueKey('lista-tarjetas'),
          ancho: constraints.maxWidth,
          depositos: depositos,
          acciones: acciones,
          pie: pie,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLA (una columna por dato)
// ═══════════════════════════════════════════════════════════════════════════

/// Ancho con el que la tabla se dibuja entera. Con menos espacio no se
/// aprietan las columnas: la tabla conserva este ancho y se desplaza en
/// horizontal. La barra va abajo, sobre la paginación; con 50 filas por página
/// queda al final de ellas.
const double _anchoCuerpoTabla = 1520;

class _Col {
  const _Col(this.titulo, {this.ancho, this.flex = 1, this.derecha = false});

  final String titulo;

  /// Ancho fijo; sin él la columna reparte el resto por [flex].
  final double? ancho;
  final int flex;
  final bool derecha;
}

// Una columna por dato, como en la tabla de siempre. Las de texto largo
// reparten el ancho sobrante por `flex` y pasan hasta a tres líneas.
const _columnas = [
  _Col('ID', ancho: 70),
  _Col('Cliente', flex: 3),
  _Col('Banco', flex: 4),
  _Col('Empresa', flex: 2),
  _Col('Vendedor', flex: 3),
  _Col('Importe', ancho: 100, derecha: true),
  _Col('Moneda', ancho: 56),
  _Col('Fecha Ingreso', ancho: 112),
  _Col('Nro. Transacción', flex: 3),
  _Col('Estado', ancho: 112),
  _Col('Registrado Por', flex: 3),
  _Col('Acciones', ancho: 164),
];

/// Una fila con las celdas alineadas a [_columnas]; sirve a cabecera y datos.
Widget _fila(List<Widget> celdas) {
  assert(celdas.length == _columnas.length);
  final hijos = <Widget>[];
  for (var i = 0; i < _columnas.length; i++) {
    if (i > 0) hijos.add(const SizedBox(width: Esp.s));
    final c = _columnas[i];
    final celda = Align(
      alignment: c.derecha ? Alignment.centerRight : Alignment.centerLeft,
      child: celdas[i],
    );
    hijos.add(
      c.ancho != null
          ? SizedBox(width: c.ancho, child: celda)
          : Expanded(flex: c.flex, child: celda),
    );
  }
  return Row(children: hijos);
}

class _TablaDepositos extends StatefulWidget {
  const _TablaDepositos({
    super.key,
    required this.depositos,
    required this.acciones,
    required this.pie,
  });

  final List<DepositoChequeEntity> depositos;
  final ConstructorAcciones acciones;
  final Widget pie;

  @override
  State<_TablaDepositos> createState() => _TablaDepositosState();
}

class _TablaDepositosState extends State<_TablaDepositos> {
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estiloCabecera = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onSurfaceVariant,
    );

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(
            horizontal: Esp.l,
            vertical: Esp.m,
          ),
          child: _fila([
            for (final c in _columnas)
              Text(
                c.titulo,
                style: estiloCabecera,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ]),
        ),
        for (final d in widget.depositos) ...[
          Divider(height: 1, color: cs.outlineVariant),
          _FilaDeposito(deposito: d, acciones: widget.acciones),
        ],
      ],
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= _anchoCuerpoTabla) return cuerpo;
              return ScrollbarTheme(
                data: ScrollbarThemeData(
                  thickness: const WidgetStatePropertyAll(10),
                  radius: const Radius.circular(5),
                  thumbColor: WidgetStatePropertyAll(
                    cs.primary.withValues(alpha: 0.6),
                  ),
                  trackColor: WidgetStatePropertyAll(
                    cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  trackVisibility: const WidgetStatePropertyAll(true),
                ),
                child: Scrollbar(
                  controller: _horizontal,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontal,
                    scrollDirection: Axis.horizontal,
                    // Un margen bajo la última fila: la barra queda en su propia
                    // franja y no se encima al texto.
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: Esp.l),
                      child: SizedBox(width: _anchoCuerpoTabla, child: cuerpo),
                    ),
                  ),
                ),
              );
            },
          ),
          // La paginación no se desplaza con las columnas.
          Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.xs,
            ),
            child: widget.pie,
          ),
        ],
      ),
    );
  }
}

class _FilaDeposito extends StatelessWidget {
  const _FilaDeposito({required this.deposito, required this.acciones});

  final DepositoChequeEntity deposito;
  final ConstructorAcciones acciones;

  @override
  Widget build(BuildContext context) {
    final d = deposito;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final rechazado = depositoRechazado(d);

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      color: rechazado ? _tinteRechazado(cs) : null,
      padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.s),
      child: _fila([
        _Insignia('#${d.idDeposito}'),
        _Texto(
          d.codCliente,
          estilo: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
          lineas: 3,
        ),
        _Texto(d.nombreBanco, lineas: 3),
        _Texto(d.nombreEmpresa, lineas: 3),
        d.nombreVendedor.isEmpty
            ? const _SinDato()
            : _Dato(
              Icons.person_outline,
              d.nombreVendedor,
              destacado: true,
              lineas: 3,
            ),
        _Importe(d, mostrarUnidad: false),
        _MonedaChip(d.moneda),
        _Fecha(d.fechaI),
        d.nroTransaccion.isEmpty
            ? const _SinDato()
            : _Texto(d.nroTransaccion, estilo: _estiloTransaccion(context)),
        EstadoDepositoChip(d.esPendiente),
        d.nombreCompleto.isEmpty
            ? const _SinDato()
            : _Dato(Icons.badge_outlined, d.nombreCompleto, lineas: 3),
        rechazado ? const _NoDisponible() : acciones(d, compacto: true),
      ]),
    );
  }
}

/// El dato no viene: un guion apagado.
class _SinDato extends StatelessWidget {
  const _SinDato();

  @override
  Widget build(BuildContext context) => Text(
    '—',
    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

/// La moneda en su propia columna: una etiqueta neutra, sin competir con los
/// colores de estado.
class _MonedaChip extends StatelessWidget {
  const _MonedaChip(this.moneda);

  final String moneda;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
          child: Text(
            FormatoMoneda.unidad(moneda),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: Peso.dato,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// El número de transacción es lo que se busca para verificar un depósito:
/// va en peso fuerte y con el color de acento del tema. Sin fuente monoespaciada
/// (en web no existe y cambiaba el aspecto entre plataformas): las cifras
/// tabulares ya las alinean.
TextStyle? _estiloTransaccion(BuildContext context, {bool vacia = false}) {
  final cs = Theme.of(context).colorScheme;
  final base = Theme.of(context).textTheme.bodyMedium;
  if (vacia) return base?.copyWith(color: cs.onSurfaceVariant);
  return base?.copyWith(
    fontWeight: Peso.dato,
    fontFeatures: cifrasTabulares,
    color: cs.primary,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

class _TarjetasDepositos extends StatelessWidget {
  const _TarjetasDepositos({
    super.key,
    required this.ancho,
    required this.depositos,
    required this.acciones,
    required this.pie,
  });

  final double ancho;
  final List<DepositoChequeEntity> depositos;
  final ConstructorAcciones acciones;
  final Widget pie;

  @override
  Widget build(BuildContext context) {
    final columnas =
        ((ancho + Esp.m) / (anchoMinimoTarjeta + Esp.m)).floor().clamp(1, 3);
    // Hacia abajo: la suma nunca pasa del ancho y la última tarjeta no salta
    // de línea por un error de redondeo.
    final anchoTarjeta =
        ((ancho - Esp.m * (columnas - 1)) / columnas).floorToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            for (final d in depositos)
              SizedBox(
                width: anchoTarjeta,
                child: _TarjetaDeposito(deposito: d, acciones: acciones),
              ),
          ],
        ),
        const SizedBox(height: Esp.m),
        pie,
      ],
    );
  }
}

class _TarjetaDeposito extends StatelessWidget {
  const _TarjetaDeposito({required this.deposito, required this.acciones});

  final DepositoChequeEntity deposito;
  final ConstructorAcciones acciones;

  @override
  Widget build(BuildContext context) {
    final d = deposito;
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final rechazado = depositoRechazado(d);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      color:
          rechazado
              ? _tinteRechazado(cs)
              : null,
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Esp.s,
              runSpacing: Esp.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Insignia('#${d.idDeposito}'),
                EstadoDepositoChip(d.esPendiente),
              ],
            ),
            const SizedBox(height: Esp.m),
            _Texto(
              d.codCliente,
              estilo: t.titleSmall?.copyWith(fontWeight: Peso.titulo),
              lineas: 2,
            ),
            const SizedBox(height: Esp.xs),
            _Dato(
                  Icons.account_balance_outlined,
                  d.nombreBanco,
                ),
            const SizedBox(height: Esp.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      FormatoMoneda.conUnidad(d.moneda, d.importe),
                      style: t.titleLarge?.copyWith(
                        fontWeight: Peso.dato,
                        fontFeatures: cifrasTabulares,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Esp.s),
                _Fecha(d.fechaI),
              ],
            ),
            const SizedBox(height: Esp.m),
            Divider(height: 1, color: cs.outlineVariant),
            const SizedBox(height: Esp.m),
            _Campo('Empresa', d.nombreEmpresa),
            if (d.nombreVendedor.isNotEmpty)
              _Campo('Vendedor', d.nombreVendedor, destacado: true),
            if (d.nroTransaccion.isNotEmpty)
              _Campo('Nro. transacción', d.nroTransaccion, resaltado: true),
            _Campo('Registrado por', d.nombreCompleto),
            const SizedBox(height: Esp.xs),
            Divider(height: 1, color: cs.outlineVariant),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: Esp.xs),
                child:
                    rechazado
                        ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: Esp.m),
                          child: _NoDisponible(),
                        )
                        : acciones(d, compacto: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS COMUNES
// ═══════════════════════════════════════════════════════════════════════════

/// Estado del depósito. Color por familia del tema (no colores fijos: en
/// oscuro o con otra semilla se rompían) y además ícono y texto, para que el
/// color no sea el único canal.
class EstadoDepositoChip extends StatelessWidget {
  const EstadoDepositoChip(this.estado, {super.key});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (fondo, texto, icono) = switch (estado.trim().toLowerCase()) {
      'verificado' => (
        cs.primaryContainer,
        cs.onPrimaryContainer,
        Icons.check_circle_outline,
      ),
      'rechazado' => (
        cs.errorContainer,
        cs.onErrorContainer,
        Icons.cancel_outlined,
      ),
      _ => (
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
        Icons.hourglass_empty,
      ),
    };

    final chip = DecoratedBox(
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.pastilla),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: Esp.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 14, color: texto),
            const SizedBox(width: Esp.xs),
            Text(
              estado.isEmpty ? 'Pendiente' : estado,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: Peso.titulo,
                color: texto,
              ),
            ),
          ],
        ),
      ),
    );
    // Se achica en vez de desbordar la columna de ancho fijo con texto ampliado.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: chip,
    );
  }
}

/// El `#id` del depósito.
class _Insignia extends StatelessWidget {
  const _Insignia(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            texto,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: Peso.titulo,
              color: cs.onSurfaceVariant,
              fontFeatures: cifrasTabulares,
            ),
          ),
        ),
      ),
    );
  }
}

/// Texto de una línea con puntos suspensivos; el tooltip deja leer lo cortado.
class _Texto extends StatelessWidget {
  const _Texto(this.texto, {this.estilo, this.lineas = 1});

  final String texto;
  final TextStyle? estilo;
  final int lineas;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      texto,
      style: estilo,
      maxLines: lineas,
      overflow: TextOverflow.ellipsis,
    );
    return texto.isEmpty ? t : Tooltip(message: texto, child: t);
  }
}

/// Línea de apoyo con ícono: quién registró y, en las tarjetas, el banco.
///
/// Son datos de apoyo pero se consultan: 13 px en tono pleno y el ícono en el
/// color de acento, no en gris. Con [destacado] (el vendedor) va además en
/// negrita dentro de una etiqueta con relleno tenue y borde del color
/// terciario del tema, que se ve aun en una lista densa sin competir con el
/// color de los estados (los de estado son de fondo pleno).
class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto, {this.destacado = false, this.lineas = 1});

  final IconData icono;
  final String texto;
  final bool destacado;

  /// Líneas máximas del texto; en la tabla, tres.
  final int lineas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: destacado ? Peso.dato : FontWeight.w500,
      color: cs.onSurface,
    );

    if (!destacado) {
      return Row(
        children: [
          Icon(icono, size: 15, color: cs.primary),
          const SizedBox(width: Esp.xs),
          Expanded(child: _Texto(texto, estilo: estilo, lineas: lineas)),
        ],
      );
    }
    if (texto.isEmpty) return const SizedBox.shrink();

    final color = cs.tertiary;
    final oscuro = cs.brightness == Brightness.dark;
    // La etiqueta mide lo que mide su texto (hasta el ancho disponible).
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: oscuro ? 0.16 : 0.09),
          border: Border.all(color: color.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(Esquina.chica - 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 15, color: color),
              const SizedBox(width: Esp.xs),
              Flexible(child: _Texto(texto, estilo: estilo, lineas: lineas)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila «etiqueta: valor» de la tarjeta.
class _Campo extends StatelessWidget {
  const _Campo(
    this.etiqueta,
    this.valor, {
    this.resaltado = false,
    this.destacado = false,
  });

  final String etiqueta;
  final String valor;

  /// El valor va con el estilo del número de transacción.
  final bool resaltado;

  /// El valor va como etiqueta de color (ver [_Dato]).
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text(etiqueta, style: context.apagado())),
          Expanded(
            child:
                destacado
                    ? _Dato(Icons.person_outline, valor, destacado: true)
                    : _Texto(
                      valor.isEmpty ? '—' : valor,
                      estilo:
                          resaltado
                              ? _estiloTransaccion(context)
                              : t.bodyMedium,
                      lineas: 2,
                    ),
          ),
        ],
      ),
    );
  }
}

class _Importe extends StatelessWidget {
  const _Importe(this.deposito, {this.mostrarUnidad = true});

  final DepositoChequeEntity deposito;

  /// Con la unidad («Bs 570.00») o solo la cifra, cuando la moneda va en su
  /// propia columna.
  final bool mostrarUnidad;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        mostrarUnidad
            ? FormatoMoneda.conUnidad(deposito.moneda, deposito.importe)
            : FormatoMoneda.monto.format(deposito.importe),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: Peso.dato,
          fontFeatures: cifrasTabulares,
        ),
      ),
    );
  }
}

class _Fecha extends StatelessWidget {
  const _Fecha(this.fecha);

  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (fecha == null) {
      return Text('—', style: TextStyle(color: cs.onSurfaceVariant));
    }
    // FittedBox: en las columnas de ancho fijo, con texto ampliado, se achica
    // en vez de desbordar.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 13,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: Esp.xs),
          Text(
            FormatearFecha.formatearFecha(fecha!),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFeatures: cifrasTabulares,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDisponible extends StatelessWidget {
  const _NoDisponible();

  @override
  Widget build(BuildContext context) {
    return Text(
      'No disponible',
      style: context.apagado()?.copyWith(fontStyle: FontStyle.italic),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PAGINACIÓN
// ═══════════════════════════════════════════════════════════════════════════

/// «Mostrando X a Y de N» y los controles de página. En anchos chicos los
/// controles bajan a una segunda línea en vez de desbordar.
class PaginacionDepositos extends StatelessWidget {
  const PaginacionDepositos({
    super.key,
    required this.pagina,
    required this.filasPorPagina,
    required this.total,
    required this.onPagina,
    required this.onFilasPorPagina,
  });

  final int pagina;
  final int filasPorPagina;
  final int total;
  final ValueChanged<int> onPagina;
  final ValueChanged<int?> onFilasPorPagina;

  static const opciones = [10, 20, 50];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inicio = total == 0 ? 0 : pagina * filasPorPagina + 1;
    final fin = ((pagina + 1) * filasPorPagina).clamp(0, total).toInt();
    final paginas = total == 0 ? 1 : (total / filasPorPagina).ceil();
    final hayAnterior = pagina > 0;
    final haySiguiente = fin < total;
    // Un valor fuera de la lista haría fallar al desplegable.
    final filas = {...opciones, filasPorPagina}.toList()..sort();

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Esp.l,
      runSpacing: Esp.xs,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s),
          child: Text(
            'Mostrando $inicio a $fin de $total depósitos',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        // Wrap y no Row: con texto ampliado los controles bajan de línea.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.first_page),
              tooltip: 'Primera página',
              onPressed: hayAnterior ? () => onPagina(0) : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Página anterior',
              onPressed: hayAnterior ? () => onPagina(pagina - 1) : null,
            ),
            Text(
              '${pagina + 1} / $paginas',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFeatures: cifrasTabulares),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Página siguiente',
              onPressed: haySiguiente ? () => onPagina(pagina + 1) : null,
            ),
            IconButton(
              icon: const Icon(Icons.last_page),
              tooltip: 'Última página',
              onPressed: haySiguiente ? () => onPagina(paginas - 1) : null,
            ),
            const SizedBox(width: Esp.m),
            Text('Filas:', style: context.apagado()),
            const SizedBox(width: Esp.s),
            DropdownButton<int>(
              value: filasPorPagina,
              isDense: true,
              items: [
                for (final e in filas)
                  DropdownMenuItem(value: e, child: Text('$e')),
              ],
              onChanged: onFilasPorPagina,
            ),
            const SizedBox(width: Esp.s),
          ],
        ),
      ],
    );
  }
}
