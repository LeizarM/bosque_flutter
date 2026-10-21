/// Tipos de teléfono (trh_tipoTelefono). Reemplaza a
/// `trhtipoTelefono/tipoTelefono.xhtml` (tb_vista codVista 28) con la misma
/// dirección y los mismos botones del ACL (btnNewTF, btnEditTF, btnEliminarTF).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/tipo_telefono_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tipo-telefono/dialogos_tipo_telefono.dart';

class TipoTelefonoScreen extends ConsumerWidget {
  const TipoTelefonoScreen({super.key});

  static const btnNuevo = 'btnNewTF';
  static const btnEditar = 'btnEditTF';
  static const btnEliminar = 'btnEliminarTF';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaTiposTelefonoProvider);
    final ocupado = ref.watch(
      operacionesTipoTelefonoProvider.select((s) => s.ocupado),
    );
    final puedeEditar = tienePermisoDeBoton(ref, btnEditar);
    final puedeEliminar = tienePermisoDeBoton(ref, btnEliminar);

    return PantallaCatalogo<TipoTelefonoEntity>(
      titulo: 'Tipos de teléfono',
      subtitulo: 'Los que se eligen al registrar el teléfono de un empleado',
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () => ref.invalidate(listaTiposTelefonoProvider),
      botonNuevo: btnNuevo,
      etiquetaNuevo: 'Nuevo tipo',
      onNuevo: () => abrirFormularioTipoTelefono(context),
      icono: Icons.contact_phone_outlined,
      resumen:
          (items) => [
            DatoResumen(
              'tipos de teléfono',
              '${items.length}',
              icono: Icons.category_outlined,
            ),
            DatoResumen(
              'teléfonos registrados',
              '${items.fold<int>(0, (s, t) => s + t.usos)}',
              icono: Icons.phone_in_talk_outlined,
              tono: TonoDato.terciario,
            ),
            DatoResumen(
              'tipos sin uso',
              '${items.where((t) => t.usos == 0).length}',
              icono: Icons.do_not_disturb_on_outlined,
              tono: TonoDato.neutro,
            ),
          ],
      tituloRanking: 'Teléfonos por tipo',
      ranking:
          (items) => [for (final t in items) BarraResumen(t.tipo, t.usos)],
      vacio: const MensajeVacio(
        icono: Icons.phone_outlined,
        titulo: 'Todavía no hay tipos de teléfono',
        detalle: 'Cuando se registre el primero aparecerá aquí.',
      ),
      contenido:
          (items) => ListaCatalogo<TipoTelefonoEntity>(
            items: items,
            unidad: ('tipo', 'tipos'),
            pistaBusqueda: 'Buscar tipo de teléfono',
            clave: (t) => '${t.codTipoTel}',
            textoBusqueda: (t) => '${t.codTipoTel} ${t.tipo}',
            tituloTarjeta: (t) => t.tipo,
            detalleTarjeta: (t) => 'Código ${t.codTipoTel}',
            pieTarjeta: (_, t) => _EnUso(t.usos),
            acento: (t) => t.usos > 0 ? TonoDato.principal : TonoDato.neutro,
            columnas: [
              ColumnaCatalogo(
                titulo: 'Código',
                ancho: 88,
                celda:
                    (c, t) => Text(
                      '${t.codTipoTel}',
                      style: c.apagado()?.copyWith(
                        fontFeatures: cifrasTabulares,
                      ),
                    ),
              ),
              ColumnaCatalogo(
                titulo: 'Tipo',
                flex: 3,
                celda:
                    (c, t) => Text(
                      t.tipo,
                      style: Theme.of(
                        c,
                      ).textTheme.bodyMedium?.copyWith(fontWeight: Peso.titulo),
                    ),
              ),
              ColumnaCatalogo(
                titulo: 'En uso',
                ancho: 170,
                celda: (_, t) => _EnUso(t.usos),
              ),
            ],
            acciones: [
              if (puedeEditar)
                AccionCatalogo(
                  etiqueta: 'Editar',
                  icono: Icons.edit_outlined,
                  alElegir:
                      (t) => abrirFormularioTipoTelefono(context, existente: t),
                ),
              if (puedeEliminar)
                AccionCatalogo(
                  etiqueta: 'Eliminar',
                  icono: Icons.delete_outline,
                  alElegir: (t) => eliminarTipoTelefono(context, ref, t),
                ),
            ],
          ),
    );
  }
}

/// Cuántos teléfonos usan el tipo: un tipo sin uso se puede eliminar.
class _EnUso extends StatelessWidget {
  const _EnUso(this.usos);

  final int usos;

  @override
  Widget build(BuildContext context) => PildoraDato(
    usos == 0 ? 'Sin uso' : '$usos ${usos == 1 ? 'teléfono' : 'teléfonos'}',
    icono: usos == 0 ? Icons.remove_circle_outline : Icons.phone_outlined,
    tono: usos == 0 ? TonoDato.neutro : TonoDato.principal,
  );
}
