import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/deposito_cheque_entity.dart';
import 'package:flutter/material.dart';

/// Widgets de presentación del listado de depósitos: tabla en anchos grandes,
/// filas compactas en los medios (media pantalla de escritorio) y tarjetas en
/// los chicos. No conocen el estado ni el notifier; las acciones por fila
/// llegan ya construidas.

/// Ancho del área de resultados desde el cual se usa tabla. Se mide el ancho
/// del contenedor y no el de la ventana: dentro del dashboard el menú lateral
/// se come su parte.
const double anchoMinimoTabla = 1040;

/// Desde este ancho se usan filas compactas de 3 líneas. Una tarjeta mide unos
/// 290 px de alto y una fila compacta unos 75: a media pantalla de escritorio
/// se ven cuatro veces más registros.
const double anchoMinimoCompacta = 720;

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

/// Elige tabla, filas compactas o tarjetas según el ancho que hay. [pie] (la
/// paginación) va dentro de la tabla o de la lista compacta, y debajo de las
/// tarjetas.
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
        if (constraints.maxWidth >= anchoMinimoCompacta) {
          return _ListaCompacta(
            key: const ValueKey('lista-compacta'),
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
// TABLA
// ═══════════════════════════════════════════════════════════════════════════

class _Col {
  const _Col(this.titulo, {this.ancho, this.flex = 1, this.derecha = false});

  final String titulo;

  /// Ancho fijo; sin él la columna reparte el resto por [flex].
  final double? ancho;
  final int flex;
  final bool derecha;
}

// Doce campos en ocho columnas: lo secundario va en una segunda línea de la
// misma celda, así la tabla cabe sin scroll horizontal.
const _columnas = [
  _Col('ID', ancho: 72),
  _Col('Cliente / Banco', flex: 4),
  _Col('Empresa / Vendedor', flex: 2),
  _Col('Importe', ancho: 128, derecha: true),
  _Col('Fecha', ancho: 100),
  _Col('Transacción / Registró', flex: 3),
  _Col('Estado', ancho: 120),
  _Col('Acciones', ancho: 168),
];

/// Una fila con las celdas alineadas a [_columnas]; sirve a cabecera y datos.
Widget _fila(List<Widget> celdas) {
  assert(celdas.length == _columnas.length);
  final hijos = <Widget>[];
  for (var i = 0; i < _columnas.length; i++) {
    if (i > 0) hijos.add(const SizedBox(width: Esp.m));
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

class _TablaDepositos extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final estiloCabecera = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onSurfaceVariant,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: Column(
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
          for (final d in depositos) ...[
            Divider(height: 1, color: cs.outlineVariant),
            _FilaDeposito(deposito: d, acciones: acciones),
          ],
          Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.xs,
            ),
            child: pie,
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
    final rechazado = depositoRechazado(d);

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      color: rechazado ? _tinteRechazado(cs) : null,
      padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.s),
      child: _fila([
        _Insignia('#${d.idDeposito}'),
        _DosLineas(
          principal: d.codCliente,
          estiloPrincipal: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
          icono: Icons.account_balance_outlined,
          secundaria: d.nombreBanco,
          acento: _Acento.primario,
        ),
        _DosLineas(
          principal: d.nombreEmpresa,
          icono: Icons.person_outline,
          secundaria: d.nombreVendedor,
          acento: _Acento.terciario,
        ),
        _Importe(d),
        _Fecha(d.fechaI),
        _DosLineas(
          principal: d.nroTransaccion.isEmpty ? '—' : d.nroTransaccion,
          estiloPrincipal: _estiloTransaccion(context, vacia: d.nroTransaccion.isEmpty),
          icono: Icons.badge_outlined,
          secundaria: d.nombreCompleto,
        ),
        EstadoDepositoChip(d.esPendiente),
        rechazado ? const _NoDisponible() : acciones(d, compacto: true),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FILAS COMPACTAS (media pantalla de escritorio)
// ═══════════════════════════════════════════════════════════════════════════

class _ListaCompacta extends StatelessWidget {
  const _ListaCompacta({
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < depositos.length; i++) ...[
            if (i > 0) Divider(height: 1, color: cs.outlineVariant),
            _FilaCompacta(deposito: depositos[i], acciones: acciones),
          ],
          Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.m,
              vertical: Esp.xs,
            ),
            child: pie,
          ),
        ],
      ),
    );
  }
}

/// Un depósito en tres líneas y cuatro zonas: quién y dónde (flexible),
/// cuánto y cuándo, estado y transacción, y las acciones. Los anchos fijos
/// dejan el resto al texto largo (cliente, banco).
class _FilaCompacta extends StatelessWidget {
  const _FilaCompacta({required this.deposito, required this.acciones});

  final DepositoChequeEntity deposito;
  final ConstructorAcciones acciones;

  @override
  Widget build(BuildContext context) {
    final d = deposito;
    final cs = Theme.of(context).colorScheme;
    final rechazado = depositoRechazado(d);

    return Container(
      color: rechazado ? _tinteRechazado(cs) : null,
      padding: const EdgeInsets.symmetric(horizontal: Esp.l, vertical: Esp.s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Insignia('#${d.idDeposito}'),
                    const SizedBox(width: Esp.s),
                    Expanded(
                      child: _Texto(
                        d.codCliente,
                        estilo: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: Peso.titulo),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _Dato(
                  Icons.account_balance_outlined,
                  d.nombreBanco,
                  acento: _Acento.primario,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: _Dato(Icons.business_outlined, d.nombreEmpresa),
                    ),
                    if (d.nombreVendedor.isNotEmpty) ...[
                      const SizedBox(width: Esp.s),
                      Expanded(
                        child: _Dato(
                          Icons.person_outline,
                          d.nombreVendedor,
                          acento: _Acento.terciario,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Esp.m),
          SizedBox(
            width: 124,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Importe(d),
                const SizedBox(height: Esp.xs),
                _Fecha(d.fechaI),
              ],
            ),
          ),
          const SizedBox(width: Esp.m),
          SizedBox(
            width: 132,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EstadoDepositoChip(d.esPendiente),
                const SizedBox(height: Esp.xs),
                _Texto(
                  d.nroTransaccion.isEmpty ? '—' : d.nroTransaccion,
                  estilo: _estiloTransaccion(
                    context,
                    vacia: d.nroTransaccion.isEmpty,
                  ),
                ),
                if (d.nombreCompleto.isNotEmpty)
                  _Dato(Icons.badge_outlined, d.nombreCompleto),
              ],
            ),
          ),
          const SizedBox(width: Esp.s),
          SizedBox(
            width: 164,
            child: Align(
              alignment: Alignment.centerRight,
              child: rechazado ? const _NoDisponible() : acciones(d, compacto: true),
            ),
          ),
        ],
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
                  acento: _Acento.primario,
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
              _Campo('Vendedor', d.nombreVendedor, acento: _Acento.terciario),
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
        child: Text(
          texto,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: Peso.titulo,
            color: cs.onSurfaceVariant,
            fontFeatures: cifrasTabulares,
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

/// Color de acento de una etiqueta: familias del tema que se separan con las
/// nueve semillas, y distintas de las de estado (que son de fondo pleno).
enum _Acento { primario, terciario }

/// Línea de apoyo con ícono: banco, vendedor, quién registró.
///
/// Son datos de apoyo pero los que más se consultan: 13 px en tono pleno y el
/// ícono en el color de acento, no en gris. Con [acento] (banco: primario,
/// vendedor: terciario) van además en negrita dentro de una etiqueta con
/// relleno tenue y borde del mismo color, que se ve aun en una lista densa sin
/// competir con el color de los estados.
class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.texto, {this.acento});

  final IconData icono;
  final String texto;
  final _Acento? acento;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = acento;
    final estilo = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: a != null ? Peso.dato : FontWeight.w500,
      color: cs.onSurface,
    );

    if (a == null) {
      return Row(
        children: [
          Icon(icono, size: 15, color: cs.primary),
          const SizedBox(width: Esp.xs),
          Expanded(child: _Texto(texto, estilo: estilo)),
        ],
      );
    }
    if (texto.isEmpty) return const SizedBox.shrink();

    final color = a == _Acento.primario ? cs.primary : cs.tertiary;
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
              Flexible(child: _Texto(texto, estilo: estilo)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Celda de dos líneas: dato principal y, debajo, uno de apoyo con ícono (si
/// viene vacío, la celda queda de una sola línea).
class _DosLineas extends StatelessWidget {
  const _DosLineas({
    required this.principal,
    required this.icono,
    required this.secundaria,
    this.estiloPrincipal,
    this.acento,
  });

  final String principal;
  final TextStyle? estiloPrincipal;
  final IconData icono;
  final String secundaria;

  /// Si viene, la línea de apoyo va como etiqueta con ese acento (ver [_Dato]).
  final _Acento? acento;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Texto(principal, estilo: estiloPrincipal),
        if (secundaria.isNotEmpty) ...[
          const SizedBox(height: 2),
          _Dato(icono, secundaria, acento: acento),
        ],
      ],
    );
  }
}

/// Fila «etiqueta: valor» de la tarjeta.
class _Campo extends StatelessWidget {
  const _Campo(
    this.etiqueta,
    this.valor, {
    this.resaltado = false,
    this.acento,
  });

  final String etiqueta;
  final String valor;

  /// El valor va con el estilo del número de transacción.
  final bool resaltado;

  /// Si viene, el valor va como etiqueta con ese acento (ver [_Dato]).
  final _Acento? acento;

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
                acento != null
                    ? _Dato(Icons.person_outline, valor, acento: acento)
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
  const _Importe(this.deposito);

  final DepositoChequeEntity deposito;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        FormatoMoneda.conUnidad(deposito.moneda, deposito.importe),
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
