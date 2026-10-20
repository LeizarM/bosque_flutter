/// Áreas y categorías del banco de preguntas (`tcpe_area`, `tcpe_clasificacion`)
/// por el CRUD genérico. Tocar una categoría filtra las preguntas.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/examenes_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/tcpe_area_entity.dart';
import 'package:bosque_flutter/domain/entities/tcpe_catalogo.dart';
import 'package:bosque_flutter/domain/entities/tcpe_clasificacion_entity.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';

class CatalogoCategorias extends ConsumerWidget {
  const CatalogoCategorias({
    super.key,
    required this.elegida,
    required this.onElegir,
  });

  final BigInt? elegida;
  final void Function(TcpeClasificacionEntity? categoria) onElegir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(tcpeAreasProvider);
    final categorias = ref.watch(tcpeCategoriasProvider);
    final cs = Theme.of(context).colorScheme;

    if (areas.hasError || categorias.hasError) {
      return MensajeError(
        error: areas.error ?? categorias.error,
        compacto: true,
        onReintentar: () {
          ref.invalidate(tcpeAreasProvider);
          ref.invalidate(tcpeCategoriasProvider);
        },
      );
    }
    if (!areas.hasValue || !categorias.hasValue) {
      return const SizedBox(height: 280, child: EsqueletoLista(filas: 5, altoFila: 40));
    }
    final listaAreas = [...areas.value!]..sort((a, b) => (a.nombreArea ?? '').compareTo(b.nombreArea ?? ''));
    final listaCat = categorias.value!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 20, color: cs.primary),
            const SizedBox(width: Esp.s),
            Expanded(child: Text('Áreas y categorías', style: context.tituloSeccion())),
            IconButton.filledTonal(
              tooltip: 'Nueva área',
              icon: const Icon(Icons.create_new_folder_outlined, size: 20),
              onPressed: () => _fichaArea(context, ref, null),
            ),
          ],
        ),
        const SizedBox(height: Esp.s),
        ListTile(
          dense: true,
          selected: elegida == null,
          selectedTileColor: cs.primaryContainer,
          selectedColor: cs.onPrimaryContainer,
          iconColor: cs.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Esquina.chica)),
          leading: const Icon(Icons.all_inclusive, size: 20),
          title: const Text('Todas las categorías'),
          onTap: () => onElegir(null),
        ),
        if (listaAreas.isEmpty)
          const NotaDelDato(texto: 'Todavía no hay áreas. Crea la primera con el botón de arriba.'),
        for (final a in listaAreas)
          _BloqueArea(
            area: a,
            categorias: [
              for (final c in listaCat)
                if (c.codArea == a.codArea) c,
            ]..sort((x, y) => (x.nombre ?? '').compareTo(y.nombre ?? '')),
            elegida: elegida,
            onElegir: onElegir,
            onEditarArea: () => _fichaArea(context, ref, a),
            onNuevaCategoria: () => _fichaCategoria(context, ref, null, codArea: a.codArea),
            onEditarCategoria: (c) => _fichaCategoria(context, ref, c),
            onAlternarCategoria: (c) => _guardarCategoria(context, ref, c.copyWith(activo: !c.activo)),
            onAlternarArea: () => _guardarArea(context, ref, a.copyWith(activo: !a.activo)),
            onEliminarCategoria: (c) => _eliminarCategoria(context, ref, c),
          ),
      ],
    );
  }

  Future<void> _fichaArea(BuildContext context, WidgetRef ref, TcpeAreaEntity? area) async {
    final r = await mostrarFormulario<TcpeAreaEntity>(
      context,
      (completa) => _FormArea(area: area, completa: completa),
    );
    if (r != null && context.mounted) await _guardarArea(context, ref, r);
  }

  Future<void> _guardarArea(BuildContext context, WidgetRef ref, TcpeAreaEntity a) async {
    try {
      await ref.read(examenesRepositoryProvider).guardarCatalogo(TcpeCatalogo.area, a);
      ref.invalidate(tcpeAreasProvider);
      if (context.mounted) avisar(context, 'Área guardada.');
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  Future<void> _fichaCategoria(
    BuildContext context,
    WidgetRef ref,
    TcpeClasificacionEntity? cat, {
    BigInt? codArea,
  }) async {
    final areas = ref.read(tcpeAreasProvider).valueOrNull ?? const [];
    final r = await mostrarFormulario<TcpeClasificacionEntity>(
      context,
      (completa) => _FormCategoria(categoria: cat, codArea: codArea, areas: areas, completa: completa),
    );
    if (r != null && context.mounted) await _guardarCategoria(context, ref, r);
  }

  Future<void> _guardarCategoria(BuildContext context, WidgetRef ref, TcpeClasificacionEntity c) async {
    try {
      await ref.read(examenesRepositoryProvider).guardarCatalogo(TcpeCatalogo.clasificacion, c);
      ref.invalidate(tcpeCategoriasProvider);
      if (context.mounted) avisar(context, 'Categoría guardada.');
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }

  Future<void> _eliminarCategoria(BuildContext context, WidgetRef ref, TcpeClasificacionEntity c) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar categoría',
      detalle: 'Se elimina «${c.nombre ?? ''}». Si ya tiene preguntas no se puede: desactívala.',
      textoConfirmar: 'Eliminar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(examenesRepositoryProvider).eliminarCatalogo(TcpeCatalogo.clasificacion, c.codClasificacion);
      ref.invalidate(tcpeCategoriasProvider);
      if (elegida == c.codClasificacion) onElegir(null);
      if (context.mounted) avisar(context, 'Categoría eliminada.');
    } catch (e) {
      if (context.mounted) avisar(context, textoParaUsuario(e), esError: true);
    }
  }
}

class _BloqueArea extends StatelessWidget {
  const _BloqueArea({
    required this.area,
    required this.categorias,
    required this.elegida,
    required this.onElegir,
    required this.onEditarArea,
    required this.onNuevaCategoria,
    required this.onEditarCategoria,
    required this.onAlternarCategoria,
    required this.onAlternarArea,
    required this.onEliminarCategoria,
  });

  final TcpeAreaEntity area;
  final List<TcpeClasificacionEntity> categorias;
  final BigInt? elegida;
  final void Function(TcpeClasificacionEntity?) onElegir;
  final VoidCallback onEditarArea;
  final VoidCallback onNuevaCategoria;
  final void Function(TcpeClasificacionEntity) onEditarCategoria;
  final void Function(TcpeClasificacionEntity) onAlternarCategoria;
  final VoidCallback onAlternarArea;
  final void Function(TcpeClasificacionEntity) onEliminarCategoria;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: Esp.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // El área va en terciario: se separa de un vistazo de sus categorías.
              Icon(Icons.folder_outlined, size: 18, color: area.activo ? cs.tertiary : cs.outline),
              const SizedBox(width: Esp.s),
              Expanded(
                child: Text(
                  (area.nombreArea ?? 'Sin nombre').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    letterSpacing: 0.6,
                    fontWeight: Peso.titulo,
                    color: area.activo ? cs.tertiary : cs.outline,
                    decoration: area.activo ? null : TextDecoration.lineThrough,
                  ),
                ),
              ),
              if (categorias.isNotEmpty)
                PastillaExamen(texto: '${categorias.length}', tono: TonoExamen.terciario),
              PopupMenuButton<int>(
                tooltip: 'Acciones del área',
                icon: const Icon(Icons.more_horiz, size: 20),
                onSelected:
                    (i) => switch (i) {
                      0 => onNuevaCategoria(),
                      1 => onEditarArea(),
                      _ => onAlternarArea(),
                    },
                itemBuilder:
                    (_) => [
                      _itemMenu(cs, 0, Icons.new_label_outlined, 'Nueva categoría', TonoExamen.principal),
                      _itemMenu(cs, 1, Icons.edit_outlined, 'Editar área', TonoExamen.principal),
                      _itemMenu(
                        cs,
                        2,
                        area.activo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        area.activo ? 'Desactivar área' : 'Activar área',
                        area.activo ? TonoExamen.terciario : TonoExamen.principal,
                      ),
                    ],
              ),
            ],
          ),
          if (categorias.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: Esp.s, bottom: Esp.xs),
              child: Text('Sin categorías', style: context.apagado()),
            ),
          for (final c in categorias)
            ListTile(
              dense: true,
              selected: elegida == c.codClasificacion,
              selectedTileColor: cs.primaryContainer,
              selectedColor: cs.onPrimaryContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Esquina.chica)),
              contentPadding: const EdgeInsets.only(left: Esp.s),
              horizontalTitleGap: Esp.s,
              minLeadingWidth: 18,
              leading: Icon(
                elegida == c.codClasificacion ? Icons.label : Icons.label_outline,
                size: 18,
                color: c.activo ? cs.primary : cs.outline,
              ),
              title: Text(
                c.nombre ?? 'Sin nombre',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.activo ? null : cs.outline,
                  decoration: c.activo ? null : TextDecoration.lineThrough,
                ),
              ),
              onTap: () => onElegir(c),
              trailing: PopupMenuButton<int>(
                tooltip: 'Acciones de la categoría',
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected:
                    (i) => switch (i) {
                      0 => onEditarCategoria(c),
                      1 => onAlternarCategoria(c),
                      _ => onEliminarCategoria(c),
                    },
                itemBuilder:
                    (_) => [
                      _itemMenu(cs, 0, Icons.edit_outlined, 'Editar', TonoExamen.principal),
                      _itemMenu(
                        cs,
                        1,
                        c.activo ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        c.activo ? 'Desactivar' : 'Activar',
                        c.activo ? TonoExamen.terciario : TonoExamen.principal,
                      ),
                      _itemMenu(cs, 2, Icons.delete_outline, 'Eliminar', TonoExamen.alerta),
                    ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Una opción de menú con su icono en el color de lo que hace.
PopupMenuItem<int> _itemMenu(ColorScheme cs, int valor, IconData icono, String texto, TonoExamen tono) => PopupMenuItem(
  value: valor,
  child: Row(
    children: [
      Icon(icono, size: 20, color: coloresDeTono(cs, tono).acento),
      const SizedBox(width: Esp.m),
      Text(texto),
    ],
  ),
);

class _FormArea extends StatefulWidget {
  const _FormArea({required this.area, required this.completa});

  final TcpeAreaEntity? area;
  final bool completa;

  @override
  State<_FormArea> createState() => _FormAreaState();
}

class _FormAreaState extends State<_FormArea> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.area?.nombreArea ?? '');
  late final _descripcion = TextEditingController(text: widget.area?.descripArea ?? '');
  late bool _activo = widget.area?.activo ?? true;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MarcoFormulario(
    titulo: widget.area == null ? 'Nueva área' : 'Editar área',
    icono: Icons.folder_outlined,
    completa: widget.completa,
    cuerpo: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nombre,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe el nombre del área' : null,
          ),
          const SizedBox(height: Esp.m),
          TextFormField(
            controller: _descripcion,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
            inputFormatters: [LengthLimitingTextInputFormatter(150)],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activa'),
            value: _activo,
            onChanged: (v) => setState(() => _activo = v),
          ),
        ],
      ),
    ),
    acciones: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          final base = widget.area ?? TcpeAreaEntity(codArea: BigInt.zero);
          Navigator.pop(
            context,
            base.copyWith(
              nombreArea: _nombre.text.trim(),
              descripArea: _descripcion.text.trim(),
              activo: _activo,
            ),
          );
        },
        child: const Text('Guardar área'),
      ),
    ],
  );
}

class _FormCategoria extends StatefulWidget {
  const _FormCategoria({
    required this.categoria,
    required this.codArea,
    required this.areas,
    required this.completa,
  });

  final TcpeClasificacionEntity? categoria;
  final BigInt? codArea;
  final List<TcpeAreaEntity> areas;
  final bool completa;

  @override
  State<_FormCategoria> createState() => _FormCategoriaState();
}

class _FormCategoriaState extends State<_FormCategoria> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.categoria?.nombre ?? '');
  late BigInt? _codArea = widget.categoria?.codArea ?? widget.codArea;
  late String? _modalidad = widget.categoria?.modalidad;
  late bool _activo = widget.categoria?.activo ?? true;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MarcoFormulario(
    titulo: widget.categoria == null ? 'Nueva categoría' : 'Editar categoría',
    icono: Icons.label_outline,
    completa: widget.completa,
    cuerpo: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<BigInt>(
            value: widget.areas.any((a) => a.codArea == _codArea) ? _codArea : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Área', border: OutlineInputBorder()),
            items: [
              for (final a in widget.areas)
                DropdownMenuItem(value: a.codArea, child: Text(a.nombreArea ?? '', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _codArea = v),
            validator: (v) => v == null ? 'Elige el área' : null,
          ),
          const SizedBox(height: Esp.m),
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
            inputFormatters: [LengthLimitingTextInputFormatter(150)],
            validator: (v) => (v ?? '').trim().isEmpty ? 'Escribe el nombre de la categoría' : null,
          ),
          const SizedBox(height: Esp.m),
          DropdownButtonFormField<String?>(
            value: _modalidad,
            decoration: const InputDecoration(labelText: 'Modalidad habitual', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: null, child: Text('Sin definir')),
              DropdownMenuItem(value: 'O', child: Text('En línea')),
              DropdownMenuItem(value: 'E', child: Text('Escrito')),
            ],
            onChanged: (v) => setState(() => _modalidad = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activa'),
            subtitle: const Text('Solo las activas sirven para generar lotes.'),
            value: _activo,
            onChanged: (v) => setState(() => _activo = v),
          ),
        ],
      ),
    ),
    acciones: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          final base = widget.categoria ?? TcpeClasificacionEntity(codClasificacion: BigInt.zero);
          Navigator.pop(
            context,
            TcpeClasificacionEntity(
              codClasificacion: base.codClasificacion,
              codArea: _codArea,
              codCurso: base.codCurso,
              nombre: _nombre.text.trim(),
              modalidad: _modalidad,
              activo: _activo,
            ),
          );
        },
        child: const Text('Guardar categoría'),
      ),
    ],
  );
}
