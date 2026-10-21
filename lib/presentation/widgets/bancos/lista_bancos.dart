/// El listado de bancos: tabla con codigo, nombre, uso y acciones en escritorio
/// y tarjetas en movil. No conoce el estado ni abre nada: las acciones de cada
/// fila llegan por [AlElegirAccionBanco].
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';

/// Ancho del area de resultados desde el cual se usa tabla. Se mide el ancho del
/// contenedor y no el de la ventana: dentro del dashboard el menu lateral se
/// come su parte.
const double anchoMinimoTablaBancos = 720;

/// Ancho minimo de una tarjeta; decide cuantas caben por fila.
const double anchoMinimoTarjetaBanco = 340;

const double _anchoCodigo = 72;
const double _anchoUso = 112;
const double _anchoIconoAccion = 40;

/// Lo que mide la columna de acciones: caben los dos iconos y el titulo.
const double _anchoColumnaAcciones = 88;

/// Lo que se puede hacer con un banco desde el listado.
enum AccionFilaBanco {
  editar('Editar', Icons.edit_outlined),
  eliminar('Eliminar', Icons.delete_outline);

  const AccionFilaBanco(this.etiqueta, this.icono);

  final String etiqueta;
  final IconData icono;
}

/// Las acciones que [permisos] deja ver, en el orden de los botones del legacy.
/// Las reglas (ACL del boton, administrador) las resuelve [PermisosBanco].
List<AccionFilaBanco> accionesDeBanco(PermisosBanco permisos) => [
  if (permisos.puedeEditar) AccionFilaBanco.editar,
  if (permisos.puedeEliminar) AccionFilaBanco.eliminar,
];

typedef AlElegirAccionBanco =
    void Function(AccionFilaBanco accion, BancoEntity banco);

String _textoCantidad(int n) => '$n ${n == 1 ? 'banco' : 'bancos'}';

String _plural(int n, String uno, String varios) =>
    '$n ${n == 1 ? uno : varios}';

/// La franja izquierda: color principal si el banco se usa, gris si no.
Color _colorFranja(ColorScheme cs, BancoEntity b) =>
    b.enUso ? cs.primary : cs.outlineVariant;

/// El ícono del banco en su mosaico, más presente si el banco se usa.
class _IconoBanco extends StatelessWidget {
  const _IconoBanco(this.banco);

  final BancoEntity banco;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color:
            banco.enUso ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Icon(
        Icons.account_balance_outlined,
        size: 18,
        color: banco.enUso ? cs.onPrimaryContainer : cs.onSurfaceVariant,
      ),
    );
  }
}

/// Una cantidad de uso en la tabla: pastilla de color si hay, raya si es 0.
Widget _celdaUso(
  BuildContext context,
  int n,
  IconData icono,
  TonoDato tono, {
  String? detalle,
}) {
  if (n == 0) return Text('—', style: context.apagado());
  final pildora = PildoraDato('$n', icono: icono, tono: tono);
  return detalle == null ? pildora : Tooltip(message: detalle, child: pildora);
}

/// Elige tabla o tarjetas segun el ancho que hay.
class ListaBancos extends StatelessWidget {
  const ListaBancos({
    super.key,
    required this.bancos,
    required this.permisos,
    required this.onAccion,
  });

  final List<BancoEntity> bancos;
  final PermisosBanco permisos;
  final AlElegirAccionBanco onAccion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= anchoMinimoTablaBancos) {
          return _TablaBancos(
            key: const ValueKey('lista-tabla'),
            bancos: bancos,
            permisos: permisos,
            onAccion: onAccion,
          );
        }
        return _TarjetasBancos(
          key: const ValueKey('lista-tarjetas'),
          ancho: constraints.maxWidth,
          bancos: bancos,
          permisos: permisos,
          onAccion: onAccion,
        );
      },
    );
  }
}

/// El total y, si los hay, cuántos no se usan.
class _PieBancos extends StatelessWidget {
  const _PieBancos(this.bancos);

  final List<BancoEntity> bancos;

  @override
  Widget build(BuildContext context) {
    final sinUso = bancos.where((b) => !b.enUso).length;
    return Wrap(
      spacing: Esp.m,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          _textoCantidad(bancos.length),
          key: const ValueKey('total-bancos'),
          style: context.apagado()?.copyWith(fontFeatures: cifrasTabulares),
        ),
        if (sinUso > 0 && sinUso < bancos.length)
          PildoraDato('$sinUso sin uso', icono: Icons.remove_circle_outline),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TABLA
// ═══════════════════════════════════════════════════════════════════════════

class _TablaBancos extends StatelessWidget {
  const _TablaBancos({
    super.key,
    required this.bancos,
    required this.permisos,
    required this.onAccion,
  });

  final List<BancoEntity> bancos;
  final PermisosBanco permisos;
  final AlElegirAccionBanco onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fondoFila = cs.surfaceContainerLow;
    final fondoCabecera = Color.alphaBlend(
      cs.primaryContainer.withValues(alpha: 0.55),
      fondoFila,
    );
    // Filas alternadas apenas distintas: guian el ojo sin pintar de mas.
    final fondoAlterno = Color.alphaBlend(
      cs.onSurface.withValues(alpha: 0.025),
      fondoFila,
    );
    final estiloCabecera = t.labelLarge?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onPrimaryContainer,
    );
    final acciones = accionesDeBanco(permisos);

    Widget titulo(String texto, {bool derecha = false}) => Align(
      alignment: derecha ? Alignment.centerRight : Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(texto, style: estiloCabecera, maxLines: 1),
      ),
    );

    Widget fila({
      required Widget codigo,
      required Widget nombre,
      required Widget cheques,
      required Widget cuentas,
      required Widget movimientos,
      required Widget accionesCelda,
    }) => Row(
      children: [
        SizedBox(width: _anchoCodigo, child: codigo),
        const SizedBox(width: Esp.s),
        Expanded(child: nombre),
        for (final uso in [cheques, cuentas, movimientos]) ...[
          const SizedBox(width: Esp.s),
          SizedBox(
            width: _anchoUso,
            child: Align(alignment: Alignment.centerRight, child: uso),
          ),
        ],
        if (acciones.isNotEmpty) ...[
          const SizedBox(width: Esp.s),
          SizedBox(width: _anchoColumnaAcciones, child: accionesCelda),
        ],
      ],
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: fondoFila,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: fondoCabecera,
              // Misma franja que las filas, invisible: las columnas alinean.
              border: const Border(
                left: BorderSide(width: 4, color: Colors.transparent),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.l,
              vertical: Esp.m,
            ),
            child: fila(
              codigo: titulo('Código'),
              nombre: Text('Nombre', style: estiloCabecera),
              cheques: titulo('Cheques', derecha: true),
              cuentas: titulo('Cuentas', derecha: true),
              movimientos: titulo('Movimientos', derecha: true),
              accionesCelda: titulo('Acciones', derecha: true),
            ),
          ),
          for (final (i, b) in bancos.indexed) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Container(
              key: ValueKey('banco-${b.codBanco}'),
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                color: i.isOdd ? fondoAlterno : null,
                border: Border(
                  left: BorderSide(width: 4, color: _colorFranja(cs, b)),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: Esp.l,
                vertical: Esp.s,
              ),
              child: fila(
                codigo: Text(
                  '${b.codBanco}',
                  style: t.bodyMedium?.copyWith(
                    fontFeatures: cifrasTabulares,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                nombre: Row(
                  children: [
                    _IconoBanco(b),
                    const SizedBox(width: Esp.m),
                    Expanded(
                      child: Text(
                        textoODash(b.nombre),
                        style: t.bodyMedium?.copyWith(
                          fontWeight: Peso.titulo,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                cheques: _celdaUso(
                  context,
                  b.cheques,
                  Icons.request_quote_outlined,
                  TonoDato.principal,
                ),
                cuentas: _celdaUso(
                  context,
                  b.cuentas,
                  Icons.credit_card_outlined,
                  TonoDato.terciario,
                  detalle:
                      '${b.cuentasEmpresa} de la empresa · '
                      '${b.cuentasEmpleados} de sueldo',
                ),
                movimientos: _celdaUso(
                  context,
                  b.movimientos + b.pagosExterior,
                  Icons.swap_horiz,
                  TonoDato.principal,
                  detalle:
                      '${b.movimientos} bancarios · '
                      '${b.pagosExterior} pagos al exterior',
                ),
                accionesCelda: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final a in acciones)
                      IconButton(
                        tooltip: a.etiqueta,
                        onPressed: () => onAccion(a, b),
                        icon: Icon(a.icono, size: 20),
                        // El tamano de un IconButton de Material 3 (40) no se
                        // acota con `constraints`: se fija en su estilo.
                        style: IconButton.styleFrom(
                          minimumSize: const Size.square(_anchoIconoAccion),
                          maximumSize: const Size.square(_anchoIconoAccion),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          Divider(height: 1, color: cs.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.l,
              vertical: Esp.m,
            ),
            child: _PieBancos(bancos),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TARJETAS
// ═══════════════════════════════════════════════════════════════════════════

class _TarjetasBancos extends StatelessWidget {
  const _TarjetasBancos({
    super.key,
    required this.ancho,
    required this.bancos,
    required this.permisos,
    required this.onAccion,
  });

  final double ancho;
  final List<BancoEntity> bancos;
  final PermisosBanco permisos;
  final AlElegirAccionBanco onAccion;

  @override
  Widget build(BuildContext context) {
    final columnas = ((ancho + Esp.m) / (anchoMinimoTarjetaBanco + Esp.m))
        .floor()
        .clamp(1, 3);
    // Hacia abajo: la suma nunca pasa del ancho y la ultima tarjeta no salta de
    // linea por un error de redondeo.
    final anchoTarjeta =
        ((ancho - Esp.m * (columnas - 1)) / columnas).floorToDouble();
    final acciones = accionesDeBanco(permisos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: Esp.m,
          runSpacing: Esp.m,
          children: [
            for (final b in bancos)
              SizedBox(
                key: ValueKey('banco-${b.codBanco}'),
                width: anchoTarjeta,
                child: _TarjetaBanco(
                  banco: b,
                  acciones: acciones,
                  onAccion: onAccion,
                ),
              ),
          ],
        ),
        const SizedBox(height: Esp.m),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Esp.s),
          child: _PieBancos(bancos),
        ),
      ],
    );
  }
}

class _TarjetaBanco extends StatelessWidget {
  const _TarjetaBanco({
    required this.banco,
    required this.acciones,
    required this.onAccion,
  });

  final BancoEntity banco;
  final List<AccionFilaBanco> acciones;
  final AlElegirAccionBanco onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final b = banco;
    final movimientos = b.movimientos + b.pagosExterior;

    // Sin encabezados de columna, cada cantidad lleva su nombre.
    final usos = <Widget>[
      if (b.cheques > 0)
        PildoraDato(
          _plural(b.cheques, 'cheque', 'cheques'),
          icono: Icons.request_quote_outlined,
          tono: TonoDato.principal,
        ),
      if (b.cuentas > 0)
        PildoraDato(
          _plural(b.cuentas, 'cuenta', 'cuentas'),
          icono: Icons.credit_card_outlined,
          tono: TonoDato.terciario,
        ),
      if (movimientos > 0)
        PildoraDato(
          _plural(movimientos, 'movimiento', 'movimientos'),
          icono: Icons.swap_horiz,
          tono: TonoDato.principal,
        ),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: contornoSuperficie(cs),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(width: 4, color: _colorFranja(cs, b))),
        ),
        padding: EdgeInsets.fromLTRB(
          Esp.l,
          Esp.m,
          acciones.isEmpty ? Esp.l : Esp.xs,
          Esp.m,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconoBanco(b),
            const SizedBox(width: Esp.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textoODash(b.nombre),
                    style: t.titleSmall?.copyWith(fontWeight: Peso.titulo),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Esp.xs),
                  Text(
                    'Código ${b.codBanco}',
                    style: context.apagado()?.copyWith(
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
                  const SizedBox(height: Esp.s),
                  Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.xs,
                    children:
                        usos.isEmpty
                            ? const [
                              PildoraDato(
                                'Sin uso',
                                icono: Icons.remove_circle_outline,
                              ),
                            ]
                            : usos,
                  ),
                ],
              ),
            ),
            if (acciones.isNotEmpty)
              MenuAccionesCheque(
                opciones: [
                  for (final a in acciones)
                    OpcionMenuCheque(a.etiqueta, a.icono, () => onAccion(a, b)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
