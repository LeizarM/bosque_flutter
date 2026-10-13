/// Un vehículo visto desde un teléfono. Tarjeta y no tabla achicada: ocho
/// columnas no entran en 360 px y el scroll horizontal pelearía con el
/// vertical. Muestra placa, estado, descripción y los datos que ayudan a
/// reconocerlo; el resto queda a un toque, en la ficha. Las acciones van en un
/// menú contextual: tres iconos por tarjeta serían demasiados blancos de toque
/// compitiendo con el scroll.
library;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/coche_entity.dart';
import 'package:bosque_flutter/presentation/widgets/catalogo-coches/acciones_coche.dart';

class TarjetaCoche extends StatelessWidget {
  const TarjetaCoche({
    super.key,
    required this.coche,
    required this.onEditar,
    required this.onAccion,
    this.ocupado = false,
  });

  final CocheEntity coche;
  final VoidCallback onEditar;
  final ValueChanged<AccionCoche> onAccion;

  /// Hay una escritura de este vehículo en curso: el menú queda apagado.
  final bool ocupado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final apagado = !coche.esActivo;
    final placa = placaLegible(coche);

    return Card(
      margin: const EdgeInsets.only(bottom: Esp.s),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEditar,
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
                        // La placa es la llave con la que la gente nombra un
                        // vehículo: va primero y en cifras tabulares.
                        Flexible(
                          child: Text(
                            placa,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.numero(fuerte: true),
                          ),
                        ),
                        const SizedBox(width: Esp.s),
                        Etiqueta(
                          texto: coche.esActivo ? 'Activo' : 'Inactivo',
                          tono:
                              coche.esActivo
                                  ? TonoEtiqueta.exito
                                  : TonoEtiqueta.neutro,
                        ),
                      ],
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(
                      descripcionVehiculo(coche),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: Peso.titulo,
                        color: apagado ? cs.onSurfaceVariant : null,
                      ),
                    ),
                    const SizedBox(height: Esp.xs),
                    Wrap(
                      spacing: Esp.m,
                      runSpacing: Esp.xs,
                      children: [
                        _Dato(rotulo: 'Sucursal', valor: sucursalLegible(coche)),
                        _Dato(
                          rotulo: 'Año',
                          valor: coche.anio?.toString() ?? '--',
                          cifra: true,
                        ),
                        _Dato(rotulo: 'Color', valor: oGuion(coche.color)),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<AccionCoche>(
                enabled: !ocupado,
                icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
                tooltip: 'Acciones del vehículo $placa',
                onSelected: onAccion,
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: AccionCoche.editar,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: AccionCoche.cambiarEstado,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            coche.esActivo
                                ? Icons.block_outlined
                                : Icons.restore_outlined,
                          ),
                          title: Text(rotuloCambiarEstado(coche)),
                        ),
                      ),
                      PopupMenuItem(
                        value: AccionCoche.eliminar,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline, color: cs.error),
                          title: Text(
                            'Eliminar',
                            style: TextStyle(color: cs.error),
                          ),
                        ),
                      ),
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
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$rotulo: ', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        Flexible(
          child: Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: cifra ? context.numero() : tt.bodySmall,
          ),
        ),
      ],
    );
  }
}
