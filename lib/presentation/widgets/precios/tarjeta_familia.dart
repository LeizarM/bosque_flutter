/// La familia de producto vista desde un telefono.
///
/// **Por que una tarjeta y no la tabla achicada.** Las nueve columnas de la
/// planilla no entran en 360 px: meterlas igual obliga a un scroll horizontal
/// que en un telefono pelea con el scroll vertical de la lista y termina con el
/// dedo arrastrando la pagina entera de costado. Aca se muestran las tres cosas
/// por las que se reconoce una familia —el codigo, la descripcion compuesta y el
/// estado— y el resto queda a un toque, en el formulario.
///
/// Las acciones van en un menu contextual y no como botones sueltos: dos
/// iconos por tarjeta multiplicados por veinte tarjetas son cuarenta blancos de
/// toque compitiendo con el gesto de scroll.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/precios/acciones_familia.dart';
import 'package:bosque_flutter/presentation/widgets/precios/familia_vista.dart';

class TarjetaFamilia extends StatelessWidget {
  const TarjetaFamilia({
    super.key,
    required this.familia,
    required this.onAbrir,
    required this.onNuevaDesde,
    required this.onAccion,
  });

  final FamiliaVista familia;

  /// Abre la ficha: la misma que edita y que muestra el detalle completo.
  final VoidCallback onAbrir;

  /// Alta de una familia nueva con los datos de esta, menos el codigo.
  final VoidCallback onNuevaDesde;

  /// Historial, grupo o proveedor SAP, baja o reactivacion y eliminacion.
  final ValueChanged<AccionFamilia> onAccion;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAbrir,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.xs, Esp.m),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // El codigo es la llave con la que la gente habla de una
                        // familia ("la 1204"), asi que va primero y en cifras
                        // tabulares.
                        Text(
                          '#${familia.codigoLegible}',
                          style: context.numero(fuerte: true),
                        ),
                        const SizedBox(width: Esp.s),
                        Etiqueta(
                          texto: familia.estadoLegible,
                          tono:
                              familia.esActiva
                                  ? TonoEtiqueta.exito
                                  : TonoEtiqueta.neutro,
                        ),
                      ],
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(
                      familia.descripcion,
                      style: tt.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                    ),
                    const SizedBox(height: Esp.xs),
                    Wrap(
                      spacing: Esp.m,
                      runSpacing: Esp.xs,
                      children: [
                        _Dato(
                          rotulo: 'Proveedor',
                          valor: FamiliaVista.oGuion(familia.proveedorSap),
                        ),
                        _Dato(
                          rotulo: 'Costo/TM',
                          valor:
                              familia.sinCosto
                                  ? 'Sin costo'
                                  : familia.costoTmLegible,
                          cifra: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<AccionFamilia>(
                icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                tooltip: 'Acciones de la familia ${familia.codigoLegible}',
                onSelected: (a) {
                  switch (a) {
                    case AccionFamilia.abrir:
                      onAbrir();
                    case AccionFamilia.nuevaDesde:
                      onNuevaDesde();
                    case AccionFamilia.copiar:
                      copiarCodigo(context, familia);
                    default:
                      onAccion(a);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: AccionFamilia.abrir,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_note_outlined),
                          title: Text('Abrir ficha'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: AccionFamilia.nuevaDesde,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.library_add_outlined),
                          title: Text('Nueva a partir de esta'),
                        ),
                      ),
                      ...itemsAccionesFamilia(familia, conHistorial: true),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.rotulo, required this.valor, this.cifra = false});

  final String rotulo;
  final String valor;
  final bool cifra;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$rotulo: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        cifra
            ? Text(valor, style: context.numero())
            : Text(valor, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
