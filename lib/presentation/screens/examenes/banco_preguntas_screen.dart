/// Banco de preguntas (`tcpeExamenes/Banco`): áreas y categorías a la
/// izquierda, preguntas con filtros a la derecha. Reemplaza al ABM de
/// preguntas del sistema PHP, que armaba el SQL a mano.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_banco_pregunta_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/catalogo_categorias.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/editor_pregunta.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/identidad_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/importar_preguntas.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/tabla_examenes.dart';

// Estado local: los filtros arrancan limpios en cada visita.
final _filtroProvider = StateProvider.autoDispose<FiltroPreguntas>(
  (ref) => (codArea: null, codClasificacion: null, activo: true, texto: ''),
);

const double _anchoPanelLateral = 1080;

class BancoPreguntasScreen extends ConsumerWidget {
  const BancoPreguntasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, r) {
        final conPanel = r.maxWidth >= _anchoPanelLateral;
        final compacto = r.maxWidth < anchoTablaExamenes;
        final margen = compacto ? Esp.l : Esp.xl;
        final filtro = ref.watch(_filtroProvider);
        final categorias = ref.watch(tcpeCategoriasProvider).valueOrNull ?? const <TcpeClasificacionEntity>[];

        void elegirCategoria(TcpeClasificacionEntity? c) =>
            ref.read(_filtroProvider.notifier).state = (
              codArea: c?.codArea ?? filtro.codArea,
              codClasificacion: c?.codClasificacion,
              activo: filtro.activo,
              texto: filtro.texto,
            );

        final activas = categorias.where((c) => c.activo).toList();

        Future<void> nueva() async {
          final ok = await editarPregunta(context, codClasificacion: filtro.codClasificacion, categorias: activas);
          if (ok) ref.invalidate(tcpePreguntasProvider);
        }

        Future<void> importar() async {
          final ok = await abrirImportacionPreguntas(context, codClasificacion: filtro.codClasificacion, categorias: activas);
          if (ok) ref.invalidate(tcpePreguntasProvider);
        }

        void limpiar() =>
            ref.read(_filtroProvider.notifier).state = (codArea: null, codClasificacion: null, activo: true, texto: '');

        final lista = Padding(
          padding: EdgeInsets.fromLTRB(conPanel ? Esp.xl : margen, Esp.l, margen, compacto ? 0 : Esp.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EncabezadoExamenes(
                ceja: 'Exámenes · Banco',
                titulo: 'Banco de preguntas',
                icono: Icons.quiz_outlined,
                detalle: 'Cada examen sortea sus preguntas de aquí. Una pregunta ya usada se desactiva en vez de borrarse.',
                compacto: compacto,
                acciones: [
                  if (!conPanel)
                    OutlinedButton.icon(
                      onPressed: () => _abrirCategorias(context, ref),
                      icon: const Icon(Icons.account_tree_outlined, size: 18),
                      label: const Text('Áreas y categorías'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: importar,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: const Text('Importar preguntas'),
                  ),
                  if (!compacto)
                    FilledButton.icon(
                      onPressed: nueva,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nueva pregunta'),
                    ),
                ],
              ),
              const SizedBox(height: Esp.l),
              _Filtros(compacto: compacto, categorias: categorias),
              const SizedBox(height: Esp.m),
              Expanded(
                child: _ListaPreguntas(
                  filtro: filtro,
                  categorias: categorias,
                  onNueva: nueva,
                  onImportar: importar,
                  onLimpiar: limpiar,
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          floatingActionButton:
              compacto
                  ? FloatingActionButton.extended(
                    onPressed: nueva,
                    icon: const Icon(Icons.add),
                    label: const Text('Nueva pregunta'),
                  )
                  : null,
          body:
              conPanel
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 320,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(Esp.l),
                          child: CatalogoCategorias(
                            elegida: filtro.codClasificacion,
                            onElegir: elegirCategoria,
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: lista),
                    ],
                  )
                  : lista,
        );
      },
    );
  }

  void _abrirCategorias(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            builder:
                (ctx, scroll) => Consumer(
                  builder: (ctx, ref, _) {
                    final filtro = ref.watch(_filtroProvider);
                    return SingleChildScrollView(
                      controller: scroll,
                      padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.xl),
                      child: CatalogoCategorias(
                        elegida: filtro.codClasificacion,
                        onElegir: (c) {
                          ref.read(_filtroProvider.notifier).state = (
                            codArea: c?.codArea ?? filtro.codArea,
                            codClasificacion: c?.codClasificacion,
                            activo: filtro.activo,
                            texto: filtro.texto,
                          );
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                ),
          ),
    );
  }
}

class _Filtros extends ConsumerStatefulWidget {
  const _Filtros({required this.compacto, required this.categorias});

  final bool compacto;
  final List<TcpeClasificacionEntity> categorias;

  @override
  ConsumerState<_Filtros> createState() => _FiltrosState();
}

class _FiltrosState extends ConsumerState<_Filtros> {
  late final _texto = TextEditingController(text: ref.read(_filtroProvider).texto);
  Timer? _pausa;

  @override
  void dispose() {
    _pausa?.cancel();
    _texto.dispose();
    super.dispose();
  }

  void _cambiar(FiltroPreguntas f) => ref.read(_filtroProvider.notifier).state = f;

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(_filtroProvider);
    final areas = ref.watch(tcpeAreasProvider).valueOrNull ?? const [];
    final activos =
        (f.codArea != null ? 1 : 0) + (f.codClasificacion != null ? 1 : 0) + (f.activo != true ? 1 : 0);
    final categoriasDelArea = [
      for (final c in widget.categorias)
        if (f.codArea == null || c.codArea == f.codArea) c,
    ];
    final busqueda = SizedBox(
      width: widget.compacto ? double.infinity : 320,
      child: TextField(
        controller: _texto,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: 'Buscar en el texto de la pregunta',
          border: const OutlineInputBorder(),
          suffixIcon:
              _texto.text.isEmpty
                  ? null
                  : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _texto.clear();
                      _cambiar((codArea: f.codArea, codClasificacion: f.codClasificacion, activo: f.activo, texto: ''));
                    },
                  ),
        ),
        onChanged: (t) {
          setState(() {});
          _pausa?.cancel();
          _pausa = Timer(const Duration(milliseconds: 400), () {
            final ahora = ref.read(_filtroProvider);
            _cambiar((codArea: ahora.codArea, codClasificacion: ahora.codClasificacion, activo: ahora.activo, texto: t.trim()));
          });
        },
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.compacto) ...[busqueda, const SizedBox(height: Esp.s)],
        FiltrosExamenes(
          compacto: widget.compacto,
          activos: activos,
          onLimpiar: () => _cambiar((codArea: null, codClasificacion: null, activo: true, texto: f.texto)),
          campos: [
            if (!widget.compacto) busqueda,
            ComboFiltro<BigInt>(
              etiqueta: 'Área',
              valor: f.codArea,
              textoTodos: 'Todas',
              opciones: [for (final a in areas) (a.codArea, a.nombreArea ?? '')],
              onCambio: (v) => _cambiar((codArea: v, codClasificacion: null, activo: f.activo, texto: f.texto)),
            ),
            ComboFiltro<BigInt>(
              etiqueta: 'Categoría',
              valor: f.codClasificacion,
              textoTodos: 'Todas',
              ancho: 260,
              opciones: [for (final c in categoriasDelArea) (c.codClasificacion, c.nombre ?? '')],
              onCambio: (v) => _cambiar((codArea: f.codArea, codClasificacion: v, activo: f.activo, texto: f.texto)),
            ),
            ComboFiltro<bool>(
              etiqueta: 'Estado',
              valor: f.activo,
              textoTodos: 'Activas e inactivas',
              ancho: 200,
              opciones: const [(true, 'Activas'), (false, 'Inactivas')],
              onCambio: (v) => _cambiar((codArea: f.codArea, codClasificacion: f.codClasificacion, activo: v, texto: f.texto)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ListaPreguntas extends ConsumerWidget {
  const _ListaPreguntas({
    required this.filtro,
    required this.categorias,
    required this.onNueva,
    required this.onImportar,
    required this.onLimpiar,
  });

  final FiltroPreguntas filtro;
  final List<TcpeClasificacionEntity> categorias;
  final VoidCallback onNueva;
  final VoidCallback onImportar;
  final VoidCallback onLimpiar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(tcpePreguntasProvider(filtro));
    final categoriaVacia = filtro.texto.isEmpty && filtro.codClasificacion != null && filtro.activo == true;
    final sinFiltros = filtro.texto.isEmpty && filtro.codClasificacion == null && filtro.codArea == null;
    return datos.when(
      skipLoadingOnReload: true,
      loading: () => const EsqueletoLista(),
      error: (e, _) => MensajeError(error: e, onReintentar: () => ref.invalidate(tcpePreguntasProvider)),
      data:
          (preguntas) => TablaExamenes<TcpeBancoPreguntaEntity>(
            filas: preguntas,
            claveFila: (p) => p.codPregunta,
            hayBotonFlotante: true,
            vacio:
                categoriaVacia || sinFiltros
                    ? VacioExamenes(
                      icono: Icons.quiz_outlined,
                      titulo: categoriaVacia ? 'Esta categoría todavía no tiene preguntas' : 'El banco está vacío',
                      detalle:
                          'Escribe la primera con «Nueva pregunta» o trae muchas de una vez desde Excel con la plantilla.',
                      accion: 'Importar preguntas',
                      iconoAccion: Icons.upload_file_outlined,
                      onAccion: onImportar,
                    )
                    : VacioExamenes(
                      icono: Icons.filter_alt_off_outlined,
                      titulo: 'Ninguna pregunta coincide',
                      detalle: 'Prueba con otra palabra o quita algún filtro para ver más.',
                      accion: 'Quitar filtros',
                      iconoAccion: Icons.filter_alt_off_outlined,
                      onAccion: onLimpiar,
                    ),
            alTocarFila: (p) => _editar(context, ref, p),
            // La franja dice el tipo: cerrada en principal, abierta en terciario; inactiva, gris.
            tonoFila: (p) => !p.activo ? TonoExamen.neutro : (p.esCerrada ? TonoExamen.principal : TonoExamen.terciario),
            columnas: [
              ColumnaExamen('Pregunta', (p) => CeldaTexto(p.pregunta, lineas: 2), flex: 7),
              ColumnaExamen(
                'Categoría',
                (p) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [CeldaTexto(p.nombreClasificacion), CeldaTexto(p.nombreArea, apagado: true)],
                ),
                flex: 3,
              ),
              ColumnaExamen('Tipo', (p) => _TipoPregunta(p), flex: 3),
              ColumnaExamen('Usos', (p) => _Usos(p.usadaEnExamenes), flex: 1, alinear: Alignment.center),
              ColumnaExamen('Estado', (p) => _estado(p), flex: 2),
            ],
            acciones: [
              AccionExamen('Editar', Icons.edit_outlined, (p) => _editar(context, ref, p)),
              AccionExamen(
                'Desactivar',
                Icons.visibility_off_outlined,
                (p) => _activar(context, ref, p, false),
                visible: (p) => p.activo,
                tono: TonoExamen.terciario,
              ),
              AccionExamen(
                'Activar',
                Icons.visibility_outlined,
                (p) => _activar(context, ref, p, true),
                visible: (p) => !p.activo,
              ),
              AccionExamen(
                'Eliminar',
                Icons.delete_outline,
                (p) => _eliminar(context, ref, p),
                destructiva: true,
                visible: (p) => !p.usada,
              ),
            ],
            tarjeta:
                (p) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.pregunta ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: Esp.xs),
                    Text(
                      oGuion(p.nombreClasificacion),
                      style: context.apagado(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: Esp.s),
                    Wrap(spacing: Esp.s, runSpacing: Esp.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      _estado(p),
                      _TipoPregunta(p, enLinea: true),
                      if (p.usada)
                        PastillaExamen(
                          texto: 'En ${p.usadaEnExamenes} exámenes',
                          tono: TonoExamen.secundario,
                          icono: Icons.history_edu_outlined,
                        ),
                    ]),
                  ],
                ),
          ),
    );
  }

  static Widget _estado(TcpeBancoPreguntaEntity p) =>
      p.activo
          ? const PastillaExamen(texto: 'Activa', tono: TonoExamen.principal, icono: Icons.check_circle_outline)
          : const PastillaExamen(texto: 'Inactiva', icono: Icons.visibility_off_outlined);

  Future<void> _editar(BuildContext context, WidgetRef ref, TcpeBancoPreguntaEntity p) async {
    final ok = await editarPregunta(context, pregunta: p, categorias: categorias);
    if (ok) ref.invalidate(tcpePreguntasProvider);
  }

  Future<void> _activar(BuildContext context, WidgetRef ref, TcpeBancoPreguntaEntity p, bool activo) async {
    try {
      await ref.read(examenesRepositoryProvider).activarPregunta(p.codPregunta, activo);
      ref.invalidate(tcpePreguntasProvider);
      if (context.mounted) avisar(context, activo ? 'Pregunta activada.' : 'Pregunta desactivada.');
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref, TcpeBancoPreguntaEntity p) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar pregunta',
      detalle: 'Se borran la pregunta, su respuesta y sus opciones. No se puede deshacer.',
      textoConfirmar: 'Eliminar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(examenesRepositoryProvider).eliminarPregunta(p.codPregunta);
      ref.invalidate(tcpePreguntasProvider);
      if (context.mounted) avisar(context, 'Pregunta eliminada.');
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }
}

/// Cerrada (principal) o abierta (terciario), con cuántas opciones y válidas.
class _TipoPregunta extends StatelessWidget {
  const _TipoPregunta(this.p, {this.enLinea = false});

  final TcpeBancoPreguntaEntity p;

  /// En la tarjeta: solo la pastilla con el detalle adentro.
  final bool enLinea;

  @override
  Widget build(BuildContext context) {
    final detalle = '${p.cantOpciones} opc. · ${p.cantValidas} ${p.cantValidas == 1 ? 'válida' : 'válidas'}';
    final pastilla =
        p.esCerrada
            ? PastillaExamen(
              texto: enLinea ? 'Cerrada · $detalle' : 'Cerrada',
              tono: TonoExamen.principal,
              icono: Icons.checklist,
            )
            : const PastillaExamen(texto: 'Abierta', tono: TonoExamen.terciario, icono: Icons.notes);
    if (enLinea || !p.esCerrada) return pastilla;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        pastilla,
        const SizedBox(height: 2),
        Text(detalle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.apagado()),
      ],
    );
  }
}

/// En cuántos exámenes salió: burbuja rellena si ya salió (no se borra), vacía si nunca.
class _Usos extends StatelessWidget {
  const _Usos(this.usos);

  final int usos;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: usos == 0 ? 'Todavía no salió en exámenes' : 'Salió en $usos ${usos == 1 ? 'examen' : 'exámenes'}',
    child: BurbujaHoja(
      texto: '$usos',
      tamanio: 28,
      marca: usos == 0 ? MarcaBurbuja.vacia : MarcaBurbuja.marcada,
    ),
  );
}
