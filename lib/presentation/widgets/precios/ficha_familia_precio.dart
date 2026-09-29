/// La ficha de la familia consultada: que producto es, con que costo e
/// impuestos se armaron sus precios, cuantas listas tiene y entre que valores
/// se mueve su precio.
///
/// **Por que estos datos estan aca y no en columnas de la tabla.** Grupo SAP,
/// proveedor, gramaje, formato y color son de la FAMILIA: valen lo mismo en las
/// doce filas de la grilla. El IVA y el IT tambien, porque en el resultset son
/// subconsultas escalares sin correlacion. Repetirlos en cada fila cuesta la
/// mitad del ancho de la tabla para no decir nada nuevo; dichos una vez arriba,
/// la tabla queda para lo que si cambia de fila en fila: la sucursal, la lista,
/// el porcentaje y el precio.
///
/// Las cuatro cifras van en las mismas tarjetas con franja de color que el
/// resumen del asistente ([CifraResumen]): en escritorio en una fila, en el
/// telefono de a dos.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/cifra_resumen.dart';
import 'package:bosque_flutter/presentation/widgets/precios/precios_vigentes_datos.dart';

class FichaFamiliaPrecio extends StatelessWidget {
  const FichaFamiliaPrecio({
    super.key,
    required this.familia,
    required this.aire,
    required this.filas,
    this.iva,
    this.it,
  });

  final FamiliaPrecio familia;
  final Aire aire;

  /// Las listas activas de la familia, antes de los filtros de pantalla: es el
  /// universo, no lo que quedo visible.
  final List<FilaPrecioVigente> filas;

  /// Los impuestos vigentes, tomados de las propias filas. Null cuando la
  /// familia no trajo ninguna fila y por lo tanto no hay de donde leerlos.
  final double? iva;
  final double? it;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chico = aire.esChico;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(chico ? Esp.m : Esp.l),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Encabezado(familia: familia, conResumen: chico),
          SizedBox(height: Esp.s),
          // En un telefono los ocho atributos de la familia cuestan media
          // pantalla y quien consulta un precio ya sabe que familia eligio.
          // Quedan a un toque.
          if (chico)
            _AtributosPlegados(familia: familia)
          else
            _Atributos(familia: familia),
          SizedBox(height: chico ? Esp.s : Esp.m),
          _Cifras(familia: familia, filas: filas, iva: iva, it: it, aire: aire),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS
// ═══════════════════════════════════════════════════════════════════════════

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.familia, required this.conResumen});

  final FamiliaPrecio familia;

  /// La etiqueta de la familia en una linea. Solo cuando los atributos estan
  /// plegados: con los chips a la vista diria lo mismo dos veces.
  final bool conResumen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Esp.s,
        runSpacing: Esp.xs,
        children: [
          Text(
            'Familia ${familia.codigoFamilia}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
            ),
          ),
          // Una familia dada de baja sigue teniendo precios cargados y se
          // puede consultar; lo que no puede es parecer vigente.
          if (familia.activa)
            const Etiqueta(texto: 'Activa', tono: TonoEtiqueta.exito)
          else
            const Etiqueta(texto: 'Inactiva', tono: TonoEtiqueta.aviso),
        ],
      ),
      if (conResumen) ...[
        SizedBox(height: Esp.xs),
        Text(
          familia.etiqueta,
          style: context.apagado(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ],
  );
}

/// Costo, impuestos, listas y rango de precio: las cifras que explican como se
/// formo el precio que muestra la grilla.
class _Cifras extends StatelessWidget {
  const _Cifras({
    required this.familia,
    required this.filas,
    required this.iva,
    required this.it,
    required this.aire,
  });

  final FamiliaPrecio familia;
  final List<FilaPrecioVigente> filas;
  final double? iva;
  final double? it;
  final Aire aire;

  @override
  Widget build(BuildContext context) {
    final chico = aire.esChico;
    final sinPrecio = filas.where((f) => f.sinPrecio).length;
    final rango = rangoDePrecios(filas);
    final ivaVigente = iva;
    final itVigente = it;
    final propuesta = familia.idPropuestaAprobada;

    final cifras = <Widget>[
      CifraResumen(
        compacto: chico,
        matiz: matizAzul,
        icono: Icons.payments_outlined,
        rotulo: 'Costo USD/TM',
        // Un costo en cero no es un costo barato: es una familia que todavia no
        // paso por una propuesta aprobada.
        valor: familia.tieneCosto ? fmtImporte(familia.costoTM) : '—',
        detalle:
            !familia.tieneCosto
                ? 'Sin costo aprobado'
                : propuesta == null
                ? 'Costo vigente'
                : 'Propuesta N.º $propuesta',
      ),
      // El IVA en grande y el IT abajo: los dos juntos no entran en la cifra
      // de un telefono, y la cifra no achica la letra, la corta.
      CifraResumen(
        compacto: chico,
        matiz: matizVioleta,
        icono: Icons.percent,
        rotulo: 'IVA',
        valor: ivaVigente == null ? '—' : fmtPorcentaje(ivaVigente),
        detalle: itVigente == null ? 'IT —' : 'IT ${fmtPorcentaje(itVigente)}',
      ),
      CifraResumen(
        compacto: chico,
        matiz: matizVerde,
        icono: Icons.format_list_numbered,
        rotulo: 'Listas activas',
        valor: '${filas.length}',
        detalle:
            sinPrecio == 0
                ? 'Todas con precio'
                : sinPrecio == 1
                ? '1 sin precio'
                : '$sinPrecio sin precio',
      ),
      CifraResumen(
        compacto: chico,
        matiz: matizNaranja,
        icono: Icons.price_change_outlined,
        rotulo: 'Precio USD/TM',
        valor: rango == null ? '—' : fmtImporte(rango.menor),
        detalle:
            rango == null
                ? 'Sin precios cargados'
                : rango.menor == rango.mayor
                ? 'Igual en todas'
                : 'hasta ${fmtImporte(rango.mayor)}',
      ),
    ];

    // Escritorio: las cuatro en una fila. Telefono y medio: de a dos, sin
    // scroll de costado.
    if (aire == Aire.amplio) {
      return Row(
        children: [
          for (final (i, c) in cifras.indexed) ...[
            if (i > 0) SizedBox(width: Esp.m),
            Expanded(child: c),
          ],
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, r) {
        final ancho = (r.maxWidth - Esp.s) / 2;
        return Wrap(
          spacing: Esp.s,
          runSpacing: Esp.s,
          children: [for (final c in cifras) SizedBox(width: ancho, child: c)],
        );
      },
    );
  }
}

class _Atributos extends StatelessWidget {
  const _Atributos({required this.familia});

  final FamiliaPrecio familia;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Esp.s,
    runSpacing: Esp.s,
    children: [
      for (final (rotulo, valor) in familia.atributos)
        _Atributo(rotulo: rotulo, valor: valor),
    ],
  );
}

class _Atributo extends StatelessWidget {
  const _Atributo({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Esp.s, vertical: Esp.xs),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$rotulo  ',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            TextSpan(
              text: valor,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: Peso.titulo),
            ),
          ],
        ),
      ),
    );
  }
}

/// Los mismos atributos, plegados. Es el caso del telefono.
class _AtributosPlegados extends StatelessWidget {
  const _AtributosPlegados({required this.familia});

  final FamiliaPrecio familia;

  @override
  Widget build(BuildContext context) => Theme(
    // El ExpansionTile pinta una linea divisoria arriba y abajo que aca corta
    // la ficha en dos por la mitad.
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      title: Text(
        'Detalle de la familia',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: Peso.titulo),
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.only(bottom: Esp.s),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [_Atributos(familia: familia)],
    ),
  );
}
