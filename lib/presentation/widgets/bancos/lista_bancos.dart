/// El listado de bancos: tabla con codigo, nombre y acciones en escritorio y
/// tarjetas en movil. No conoce el estado ni abre nada: las acciones de cada
/// fila llegan por [AlElegirAccionBanco].
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/utils/permisos_banco.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

/// Ancho del area de resultados desde el cual se usa tabla. Se mide el ancho del
/// contenedor y no el de la ventana: dentro del dashboard el menu lateral se
/// come su parte.
const double anchoMinimoTablaBancos = 720;

/// Ancho minimo de una tarjeta; decide cuantas caben por fila.
const double anchoMinimoTarjetaBanco = 340;

const double _anchoCodigo = 96;
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
      cs.surfaceContainerHighest.withValues(alpha: 0.6),
      fondoFila,
    );
    final estiloCabecera = t.labelLarge?.copyWith(
      fontWeight: Peso.titulo,
      color: cs.onSurfaceVariant,
    );
    final acciones = accionesDeBanco(permisos);

    Widget fila({
      required Widget codigo,
      required Widget nombre,
      required Widget accionesCelda,
    }) => Row(
      children: [
        SizedBox(width: _anchoCodigo, child: codigo),
        const SizedBox(width: Esp.s),
        Expanded(child: nombre),
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
            color: fondoCabecera,
            padding: const EdgeInsets.symmetric(
              horizontal: Esp.l,
              vertical: Esp.m,
            ),
            child: fila(
              codigo: Text(
                'Código',
                style: estiloCabecera,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              nombre: Text('Nombre', style: estiloCabecera),
              accionesCelda: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Acciones', style: estiloCabecera),
                ),
              ),
            ),
          ),
          for (final b in bancos) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Container(
              key: ValueKey('banco-${b.codBanco}'),
              constraints: const BoxConstraints(minHeight: 56),
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
                nombre: Text(
                  textoODash(b.nombre),
                  style: t.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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
            child: Text(
              _textoCantidad(bancos.length),
              key: const ValueKey('total-bancos'),
              style: context.apagado()?.copyWith(fontFeatures: cifrasTabulares),
            ),
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
          child: Text(
            _textoCantidad(bancos.length),
            key: const ValueKey('total-bancos'),
            style: context.apagado()?.copyWith(fontFeatures: cifrasTabulares),
          ),
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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: contornoSuperficie(cs),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          Esp.l,
          Esp.m,
          acciones.isEmpty ? Esp.l : Esp.xs,
          Esp.m,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textoODash(banco.nombre),
                    style: t.titleSmall?.copyWith(fontWeight: Peso.titulo),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Esp.xs),
                  Text(
                    'Código ${banco.codBanco}',
                    style: context.apagado()?.copyWith(
                      fontFeatures: cifrasTabulares,
                    ),
                  ),
                ],
              ),
            ),
            if (acciones.isNotEmpty)
              MenuAccionesCheque(
                opciones: [
                  for (final a in acciones)
                    OpcionMenuCheque(
                      a.etiqueta,
                      a.icono,
                      () => onAccion(a, banco),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
