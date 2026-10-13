/// Los dos catálogos del archivo: archivos físicos (con su sucursal) y tipos
/// de documento. Uno en uso no se elimina (lo rechaza el SP): se ofrece
/// desactivarlo, que lo saca de las listas de alta sin tocar lo ya registrado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/archivo_fisico_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_documento_archivo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

class CatalogosArchivo extends ConsumerWidget {
  const CatalogosArchivo({super.key, required this.mostrarAsa});

  final bool mostrarAsa;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(archivoDocumentalProvider);
    final alto = MediaQuery.sizeOf(context).height * 0.8;
    final codigos = [for (final a in estado.archivos) a.codArchivo];

    return SizedBox(
      height: alto,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            CabezaFicha(
              titulo: 'Catálogos del archivo',
              mostrarAsa: mostrarAsa,
              ocupado: false,
              icono: Icons.category_outlined,
              semilla: TonosArchivo.archivos[1],
            ),
            const TabBar(tabs: [Tab(text: 'Archivos'), Tab(text: 'Tipos de documento')]),
            Expanded(
              child: TabBarView(
                children: [
                  _Lista<ArchivoFisicoEntity>(
                    items: [...estado.archivos]..sort((a, b) => a.nombre.compareTo(b.nombre)),
                    nombre: (a) => a.nombre,
                    detalle:
                        (a) =>
                            '${(a.nombreSucursal ?? '').isEmpty ? 'Sin sucursal' : a.nombreSucursal} · '
                            '${a.cajas} cajas · ${documentosLegible(a.lineas)}'
                            '${(a.responsable ?? '').isEmpty ? '' : ' · ${a.responsable}'}',
                    icono: (a) => IconoTono(Icons.warehouse_outlined, semillaDeArchivo(a.codArchivo, codigos)),
                    activo: (a) => a.esActivo,
                    nuevo: 'Nuevo archivo',
                    semilla: TonosArchivo.archivos[1],
                    onEditar: (a) => _editarArchivo(context, ref, a),
                    onEliminar: (a) => _eliminar(
                      context,
                      que: 'el archivo ${a.nombre}',
                      eliminar: () => ref.read(archivoDocumentalProvider.notifier).eliminarArchivo(a.codArchivo),
                      desactivar:
                          a.esActivo
                              ? () => ref
                                  .read(archivoDocumentalProvider.notifier)
                                  .guardarArchivo(a.copyWith(estado: ArchivoFisicoEntity.inactivo))
                              : null,
                    ),
                  ),
                  _Lista<TipoDocumentoArchivoEntity>(
                    items: [...estado.tipos]
                      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase())),
                    nombre: (t) => t.nombre,
                    detalle: (t) => t.usos == 1 ? 'Lo usa 1 documento' : 'Lo usan ${t.usos} documentos',
                    icono: (_) => const IconoTono(Icons.description_outlined, TonosArchivo.documentos),
                    activo: (t) => t.esActivo,
                    nuevo: 'Nuevo tipo',
                    semilla: TonosArchivo.documentos,
                    onEditar: (t) => _editarTipo(context, ref, t),
                    onEliminar: (t) => _eliminar(
                      context,
                      que: 'el tipo ${t.nombre}',
                      eliminar: () => ref.read(archivoDocumentalProvider.notifier).eliminarTipo(t.codTipoDocumento),
                      desactivar:
                          t.esActivo
                              ? () => ref
                                  .read(archivoDocumentalProvider.notifier)
                                  .guardarTipo(t.copyWith(estado: TipoDocumentoArchivoEntity.inactivo))
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarArchivo(BuildContext context, WidgetRef ref, ArchivoFisicoEntity? a) =>
      showDialog<void>(
        context: context,
        builder:
            (_) => _FichaCatalogo(
              titulo: a == null ? 'Nuevo archivo' : 'Editar ${a.nombre}',
              nombre: a?.nombre ?? '',
              responsable: a?.responsable ?? '',
              conResponsable: true,
              conSucursal: true,
              codSucursal: a?.codSucursal,
              activo: a?.esActivo ?? true,
              onGuardar:
                  (nombre, responsable, codSucursal, activo) => ref
                      .read(archivoDocumentalProvider.notifier)
                      .guardarArchivo(
                        ArchivoFisicoEntity(
                          codArchivo: a?.codArchivo ?? 0,
                          nombre: nombre,
                          responsable: responsable,
                          codSucursal: codSucursal,
                          estado: activo ? ArchivoFisicoEntity.activo : ArchivoFisicoEntity.inactivo,
                        ),
                      ),
            ),
      );

  Future<void> _editarTipo(BuildContext context, WidgetRef ref, TipoDocumentoArchivoEntity? t) =>
      showDialog<void>(
        context: context,
        builder:
            (_) => _FichaCatalogo(
              titulo: t == null ? 'Nuevo tipo de documento' : 'Editar ${t.nombre}',
              nombre: t?.nombre ?? '',
              activo: t?.esActivo ?? true,
              onGuardar:
                  (nombre, _, __, activo) => ref
                      .read(archivoDocumentalProvider.notifier)
                      .guardarTipo(
                        TipoDocumentoArchivoEntity(
                          codTipoDocumento: t?.codTipoDocumento ?? 0,
                          nombre: nombre,
                          estado: activo ? TipoDocumentoArchivoEntity.activo : TipoDocumentoArchivoEntity.inactivo,
                        ),
                      ),
            ),
      );

  Future<void> _eliminar(
    BuildContext context, {
    required String que,
    required Future<void> Function() eliminar,
    Future<void> Function()? desactivar,
  }) async {
    final ok = await confirmar(
      context,
      titulo: 'Eliminar $que',
      detalle: 'Solo se puede eliminar si nada lo usa. Si está en uso, puedes desactivarlo.',
      textoConfirmar: 'Eliminar',
      destructiva: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await eliminar();
      if (context.mounted) avisar(context, 'Se eliminó $que.');
    } catch (e) {
      if (!context.mounted) return;
      final m = humanizar(e);
      if (m.esFalloTecnico || desactivar == null) {
        mostrarAviso(context, m.texto, tono: TonoAviso.error);
        return;
      }
      final baja = await confirmar(
        context,
        titulo: 'No se pudo eliminar $que',
        detalle: '${m.texto}\n\n¿Quieres desactivarlo en su lugar?',
        textoConfirmar: 'Desactivar',
      );
      if (!baja || !context.mounted) return;
      try {
        await desactivar();
        if (context.mounted) avisar(context, 'Se desactivó $que.');
      } catch (e2) {
        if (context.mounted) mostrarAviso(context, textoParaUsuario(e2), tono: TonoAviso.error);
      }
    }
  }
}

class _Lista<T> extends StatelessWidget {
  const _Lista({
    required this.items,
    required this.nombre,
    required this.detalle,
    required this.icono,
    required this.activo,
    required this.nuevo,
    required this.semilla,
    required this.onEditar,
    required this.onEliminar,
  });

  final List<T> items;
  final String Function(T) nombre;
  final String Function(T) detalle;
  final Widget Function(T) icono;
  final bool Function(T) activo;
  final String nuevo;
  final Color semilla;

  /// Con null es un alta.
  final void Function(T? item) onEditar;
  final void Function(T item) onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, Esp.s),
          child: Row(
            children: [
              Expanded(child: Text('${items.length} registrados', style: context.apagado())),
              FilledButton.tonalIcon(
                style: estiloTonal(context, semilla),
                onPressed: () => onEditar(null),
                icon: const Icon(Icons.add, size: 18),
                label: Text(nuevo),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final it = items[i];
              return ListTile(
                leading: icono(it),
                title: Text(
                  nombre(it),
                  style: TextStyle(color: activo(it) ? null : cs.onSurfaceVariant),
                ),
                subtitle: Text(detalle(it)),
                onTap: () => onEditar(it),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!activo(it)) const Etiqueta(texto: 'Inactivo'),
                    const SizedBox(width: Esp.xs),
                    IconButton.filledTonal(
                      style: estiloIconoTonal(context, TonosArchivo.peligro),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Eliminar ${nombre(it)}',
                      onPressed: () => onEliminar(it),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Nombre, responsable y sucursal opcionales y activo. Guarda y cierra; si el
/// servidor rechaza, muestra el motivo y queda abierta.
class _FichaCatalogo extends ConsumerStatefulWidget {
  const _FichaCatalogo({
    required this.titulo,
    required this.nombre,
    this.responsable = '',
    this.conResponsable = false,
    this.conSucursal = false,
    this.codSucursal,
    required this.activo,
    required this.onGuardar,
  });

  final String titulo;
  final String nombre;
  final String responsable;
  final bool conResponsable;
  final bool conSucursal;
  final int? codSucursal;
  final bool activo;
  final Future<void> Function(String nombre, String? responsable, int? codSucursal, bool activo)
  onGuardar;

  @override
  ConsumerState<_FichaCatalogo> createState() => _FichaCatalogoState();
}

class _FichaCatalogoState extends ConsumerState<_FichaCatalogo> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.nombre);
  late final TextEditingController _responsable = TextEditingController(text: widget.responsable);
  late bool _activo = widget.activo;
  late int? _sucursal = widget.codSucursal;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _responsable.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final r = _responsable.text.trim();
      await widget.onGuardar(_nombre.text.trim(), r.isEmpty ? null : r, _sucursal, _activo);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = humanizar(e).texto;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_guardando,
    child: AlertDialog(
      title: Text(widget.titulo),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Esp.m),
                  child: NotaDelDato(texto: _error!, tono: TonoNota.error),
                ),
              TextFormField(
                controller: _nombre,
                enabled: !_guardando,
                maxLength: 60,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Escribe el nombre.' : null,
              ),
              if (widget.conResponsable)
                TextFormField(
                  controller: _responsable,
                  enabled: !_guardando,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Responsable', border: OutlineInputBorder()),
                ),
              if (widget.conSucursal) ...[
                _comboSucursal(),
                const SizedBox(height: Esp.s),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activo'),
                subtitle: const Text('Inactivo no aparece al registrar, pero conserva lo ya guardado.'),
                value: _activo,
                onChanged: _guardando ? null : (v) => setState(() => _activo = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando…' : 'Guardar'),
        ),
      ],
    ),
  );

  /// tb_sucursal se repite por empresa: el rótulo lleva empresa y ciudad.
  Widget _comboSucursal() {
    final sucursales = ref.watch(sucursalesArchivoProvider);
    return sucursales.when(
      loading:
          () => const InputDecorator(
            decoration: InputDecoration(labelText: 'Sucursal', border: OutlineInputBorder()),
            child: Text('Cargando sucursales…'),
          ),
      error:
          (e, _) => NotaDelDato(
            texto: 'No se pudieron traer las sucursales: ${textoParaUsuario(e)}',
            tono: TonoNota.error,
          ),
      data:
          (lista) => ComboBuscable<int?>(
            etiqueta: 'Sucursal',
            valor: _sucursal,
            ayuda: 'Dónde está el archivo. Los reportes agrupan por ella.',
            opciones: [
              const DropdownMenuEntry<int?>(value: null, label: 'Sin sucursal'),
              for (final s in [...lista]..sort((a, b) => a.rotulo.compareTo(b.rotulo)))
                DropdownMenuEntry<int?>(value: s.codSucursal, label: s.rotulo),
            ],
            onElegir: (v) => setState(() => _sucursal = v),
          ),
    );
  }
}

