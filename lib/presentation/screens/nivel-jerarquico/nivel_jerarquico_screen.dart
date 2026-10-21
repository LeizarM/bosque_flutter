/// Niveles jerárquicos (tb_nivelJerarquico): la escala de haber básico y bono
/// de producción por nivel. Reemplaza a `tbNivelJerarquico/nivelJerarquico.xhtml`
/// (tb_vista codVista 15) con la misma dirección y los botones btnNewNJ,
/// btnEditNJ y btnEliminarNJ. Como en el legacy, solo la escala vigente se
/// edita o elimina, salvo para el administrador.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/nivel_jerarquico_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/nivel-jerarquico/dialogos_nivel_jerarquico.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

class NivelJerarquicoScreen extends ConsumerWidget {
  const NivelJerarquicoScreen({super.key});

  static const btnNuevo = 'btnNewNJ';
  static const btnEditar = 'btnEditNJ';
  static const btnEliminar = 'btnEliminarNJ';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectura = ref.watch(listaEscalasProvider);
    final filtro = ref.watch(filtroVigenciaProvider);
    final ocupado = ref.watch(
      operacionesNivelJerarquicoProvider.select((s) => s.ocupado),
    );
    final esAdmin = ref.watch(userProvider)?.tipoUsuario == 'ROLE_ADM';
    final puedeCrear = tienePermisoDeBoton(ref, btnNuevo);
    final puedeEditar = tienePermisoDeBoton(ref, btnEditar);
    final puedeEliminar = tienePermisoDeBoton(ref, btnEliminar);
    bool tocable(NivelJerarquicoEntity e) => e.esVigente || esAdmin;

    final filtroChips = Wrap(
      spacing: Esp.s,
      runSpacing: Esp.s,
      children: [
        for (final (f, etiqueta) in [
          (FiltroVigencia.vigentes, 'Vigentes'),
          (FiltroVigencia.anteriores, 'Anteriores'),
          (FiltroVigencia.todas, 'Todas'),
        ])
          ChoiceChip(
            label: Text(etiqueta),
            selected: filtro == f,
            onSelected:
                (_) => ref.read(filtroVigenciaProvider.notifier).state = f,
          ),
      ],
    );

    return PantallaCatalogo<NivelJerarquicoEntity>(
      titulo: 'Niveles jerárquicos',
      subtitulo: 'Haber básico y bono de producción de cada nivel',
      lectura: lectura,
      ocupado: ocupado,
      onRecargar: () => ref.invalidate(listaEscalasProvider),
      botonNuevo: btnNuevo,
      etiquetaNuevo: 'Nueva escala',
      onNuevo: () => abrirFormularioEscala(context),
      icono: Icons.stairs_outlined,
      resumen: (todas) {
        final vigentes = todas.where((e) => e.esVigente).toList();
        final promedio =
            vigentes.isEmpty
                ? 0.0
                : vigentes.fold<double>(0, (s, e) => s + e.haberBasico) /
                    vigentes.length;
        return [
          DatoResumen(
            'niveles con escala vigente',
            '${vigentes.length}',
            icono: Icons.verified_outlined,
          ),
          DatoResumen(
            'cargos en esas escalas',
            '${vigentes.fold<int>(0, (s, e) => s + e.cargos)}',
            icono: Icons.work_outline,
            tono: TonoDato.terciario,
          ),
          DatoResumen(
            'haber básico promedio',
            FormatoMoneda.bs(promedio),
            icono: Icons.payments_outlined,
            tono: TonoDato.neutro,
          ),
        ];
      },
      tituloRanking: 'Cargos por nivel (vigentes)',
      ranking:
          (todas) => [
            for (final e in todas)
              if (e.esVigente) BarraResumen('Nivel ${e.nivel}', e.cargos),
          ],
      vacio: const MensajeVacio(
        icono: Icons.stairs_outlined,
        titulo: 'Todavía no hay escalas',
        detalle: 'Cuando se registre la primera aparecerá aquí.',
      ),
      contenido: (todas) {
        final items = switch (filtro) {
          FiltroVigencia.vigentes => todas.where((e) => e.esVigente).toList(),
          FiltroVigencia.anteriores =>
            todas.where((e) => !e.esVigente).toList(),
          FiltroVigencia.todas => todas,
        };
        return ListaCatalogo<NivelJerarquicoEntity>(
          key: ValueKey(filtro),
          items: items,
          unidad: ('escala', 'escalas'),
          pistaBusqueda: 'Buscar por nivel o monto',
          filtros: [filtroChips],
          clave: (e) => '${e.codNivel}',
          acento: (e) => e.esVigente ? TonoDato.principal : TonoDato.neutro,
          textoBusqueda:
              (e) =>
                  'nivel ${e.nivel} ${e.haberBasico} ${e.bonoProduccion} '
                  '${textoFecha(e.fecha)}',
          tituloTarjeta: (e) => 'Nivel ${e.nivel}',
          detalleTarjeta:
              (e) =>
                  'Haber ${FormatoMoneda.bs(e.haberBasico)} · '
                  'Bono ${FormatoMoneda.bs(e.bonoProduccion)}',
          pieTarjeta:
              (c, e) => Wrap(
                spacing: Esp.s,
                runSpacing: Esp.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _EtiquetaVigencia(e.esVigente),
                  Text(
                    'Rige desde ${textoFecha(e.fecha)} · ${_cargos(e.cargos)}',
                    style: c.apagado(),
                  ),
                ],
              ),
          columnas: [
            ColumnaCatalogo(
              titulo: 'Nivel',
              ancho: 64,
              celda:
                  (c, e) => Text(
                    '${e.nivel}',
                    style: c.numero(fuerte: true),
                  ),
            ),
            ColumnaCatalogo(
              titulo: 'Haber básico',
              flex: 2,
              alineacion: Alignment.centerRight,
              celda:
                  (c, e) => Text(
                    FormatoMoneda.bs(e.haberBasico),
                    style: c.numero(fuerte: true),
                  ),
            ),
            ColumnaCatalogo(
              titulo: 'Bono producción',
              flex: 2,
              alineacion: Alignment.centerRight,
              celda:
                  (c, e) => Text(
                    FormatoMoneda.bs(e.bonoProduccion),
                    style: c.numero(),
                  ),
            ),
            ColumnaCatalogo(
              titulo: 'Rige desde',
              ancho: 104,
              celda: (c, e) => Text(textoFecha(e.fecha), style: c.numero()),
            ),
            ColumnaCatalogo(
              titulo: 'Estado',
              ancho: 104,
              celda: (_, e) => _EtiquetaVigencia(e.esVigente),
            ),
            ColumnaCatalogo(
              titulo: 'Cargos',
              ancho: 88,
              alineacion: Alignment.centerRight,
              celda: (c, e) => Text('${e.cargos}', style: c.numero()),
            ),
          ],
          acciones: [
            if (puedeCrear)
              AccionCatalogo(
                etiqueta: 'Nueva vigencia',
                icono: Icons.update,
                visible: (e) => e.esVigente,
                alElegir:
                    (e) => abrirFormularioEscala(
                      context,
                      base: e,
                      modo: ModoEscala.nuevaVigencia,
                    ),
              ),
            if (puedeEditar)
              AccionCatalogo(
                etiqueta: 'Editar',
                icono: Icons.edit_outlined,
                visible: tocable,
                alElegir:
                    (e) => abrirFormularioEscala(
                      context,
                      base: e,
                      modo: ModoEscala.edicion,
                    ),
              ),
            if (puedeEliminar)
              AccionCatalogo(
                etiqueta: 'Eliminar',
                icono: Icons.delete_outline,
                visible: tocable,
                alElegir: (e) => eliminarEscala(context, ref, e),
              ),
          ],
        );
      },
    );
  }

  static String _cargos(int n) =>
      n == 0 ? 'sin cargos' : '$n ${n == 1 ? 'cargo' : 'cargos'}';
}

class _EtiquetaVigencia extends StatelessWidget {
  const _EtiquetaVigencia(this.vigente);

  final bool vigente;

  @override
  Widget build(BuildContext context) => PildoraDato(
    vigente ? 'Vigente' : 'Anterior',
    icono: vigente ? Icons.check_circle_outline : Icons.history,
    tono: vigente ? TonoDato.principal : TonoDato.neutro,
  );
}
