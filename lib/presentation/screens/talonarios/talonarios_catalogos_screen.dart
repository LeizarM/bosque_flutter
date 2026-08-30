import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/constants/talonarios_botones.dart';
import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/talonario_grupo_entity.dart';
import 'package:bosque_flutter/domain/entities/talonario_por_grupo_entity.dart';
import 'package:bosque_flutter/domain/entities/tipo_recibo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';

/// Los dos catálogos del módulo: **tipos de recibo** y **grupos**.
///
/// Son chicos —7 tipos y 3 grupos— y casi no cambian, pero tienen que poder
/// editarse: la sigla arma el prefijo del `nroTalonario` y está atada a la
/// empresa (IR1/IR3/NPI son de Impexpap, ER1/EC2 de Esppapel), así que
/// renombrar o dar de alta una sigla nueva es una operación real del negocio.
///
/// Van juntos en una pantalla con pestañas porque se administran en el mismo
/// momento: un tipo nuevo casi siempre entra a un grupo.
class TalonariosCatalogosScreen extends ConsumerWidget {
  const TalonariosCatalogosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Catálogos'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sell_outlined), text: 'Tipos de recibo'),
              Tab(icon: Icon(Icons.folder_outlined), text: 'Grupos'),
            ],
          ),
        ),
        body: const TabBarView(children: [_PanelTipos(), _PanelGrupos()]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIPOS DE RECIBO
// ═══════════════════════════════════════════════════════════════════════════

class _PanelTipos extends ConsumerWidget {
  const _PanelTipos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tiposReciboProvider);

    return Scaffold(
      floatingActionButton: PermissionWidget(
        buttonName: TalonariosBotones.nuevo,
        child: FloatingActionButton.extended(
          onPressed: () => _editarTipo(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo tipo'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);
          return async.when(
            loading: () => const EsqueletoLista(filas: 4),
            error:
                (e, _) => MensajeError(
                  error: e,
                  onReintentar: () => ref.invalidate(tiposReciboProvider),
                ),
            data: (lista) {
              if (lista.isEmpty) {
                return const MensajeVacio(
                  icono: Icons.sell_outlined,
                  titulo: 'No hay tipos de recibo',
                  detalle:
                      'Un tipo define la sigla que arma el número de talonario. '
                      'Creá el primero con «Nuevo tipo».',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => refrescarTalonarios(ref),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    aire.esChico ? Esp.m : Esp.xl,
                    Esp.m,
                    aire.esChico ? Esp.m : Esp.xl,
                    88,
                  ),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Esp.s),
                  itemBuilder: (_, i) => _FilaTipo(tipo: lista[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FilaTipo extends ConsumerWidget {
  const _FilaTipo({required this.tipo});

  final TipoReciboEntity tipo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _editarTipo(context, ref, tipo),
        child: Padding(
          padding: const EdgeInsets.all(Esp.l),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tipo.sigla,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: Peso.dato),
                          ),
                        ),
                        const SizedBox(width: Esp.s),
                        Etiqueta(
                          texto: tipo.activo ? 'Activo' : 'Inactivo',
                          tono:
                              tipo.activo
                                  ? TonoEtiqueta.exito
                                  : TonoEtiqueta.neutro,
                        ),
                      ],
                    ),
                    const SizedBox(height: Esp.xs),
                    Text(
                      tipo.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tipo.detalle.isNotEmpty)
                      Text(
                        tipo.detalle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.apagado(),
                      ),
                    const SizedBox(height: Esp.xs),
                    Wrap(
                      spacing: Esp.m,
                      children: [
                        _Dato(
                          icono: Icons.receipt_long_outlined,
                          texto: '${tipo.cantTalonarios} talonarios',
                        ),
                        _Dato(
                          icono: Icons.folder_outlined,
                          texto: '${tipo.cantGrupos} grupos',
                        ),
                        if (tipo.ultimoFolio > 0)
                          _Dato(
                            icono: Icons.tag,
                            texto: 'último folio ${tipo.ultimoFolio}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PermissionWidget(
                buttonName: TalonariosBotones.eliminar,
                child:
                    tipo.sePuedeEliminar
                        ? IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _eliminarTipo(context, ref, tipo),
                        )
                        // No se esconde: se explica por qué no se puede.
                        : Tooltip(
                          message:
                              'No se puede eliminar: tiene '
                              '${tipo.cantTalonarios} talonarios y está en '
                              '${tipo.cantGrupos} grupos. Marcalo Inactivo.',
                          child: Padding(
                            padding: const EdgeInsets.all(Esp.m),
                            child: Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _editarTipo(
  BuildContext context,
  WidgetRef ref,
  TipoReciboEntity? tipo,
) async {
  final esNuevo = tipo == null;
  final permiso =
      esNuevo ? TalonariosBotones.nuevo : TalonariosBotones.editar;
  if (!tienePermisoDeBoton(ref, permiso)) {
    mostrarAviso(
      context,
      esNuevo
          ? 'No tenés permiso para crear tipos de recibo.'
          : 'No tenés permiso para editar tipos de recibo.',
      tono: TonoAviso.aviso,
    );
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormularioTipo(tipo: tipo),
  );
}

Future<void> _eliminarTipo(
  BuildContext context,
  WidgetRef ref,
  TipoReciboEntity tipo,
) async {
  final sigue = await confirmar(
    context,
    titulo: '¿Eliminar el tipo ${tipo.sigla}?',
    detalle:
        'No tiene talonarios ni grupos asociados, así que se puede borrar. '
        'Si más adelante lo vas a volver a usar, conviene marcarlo Inactivo '
        'en vez de eliminarlo.',
    textoConfirmar: 'Eliminar',
    destructiva: true,
  );
  if (!sigue || !context.mounted) return;

  try {
    await ref
        .read(talonariosRepositoryProvider)
        .eliminarTipo(
          tipo.codTipoRecibo,
          BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
        );
    if (!context.mounted) return;
    refrescarTalonarios(ref);
    mostrarAviso(context, 'Tipo ${tipo.sigla} eliminado');
  } catch (e) {
    if (!context.mounted) return;
    mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
  }
}

class _FormularioTipo extends ConsumerStatefulWidget {
  const _FormularioTipo({this.tipo});

  final TipoReciboEntity? tipo;

  @override
  ConsumerState<_FormularioTipo> createState() => _FormularioTipoState();
}

class _FormularioTipoState extends ConsumerState<_FormularioTipo> {
  final _formKey = GlobalKey<FormState>();
  late final _sigla = TextEditingController(text: widget.tipo?.sigla ?? '');
  late final _nombre = TextEditingController(text: widget.tipo?.nombre ?? '');
  late final _detalle = TextEditingController(text: widget.tipo?.detalle ?? '');
  late bool _activo = widget.tipo?.activo ?? true;

  bool _ocupado = false;
  Object? _error;

  bool get _esNuevo => widget.tipo == null;

  @override
  void dispose() {
    _sigla.dispose();
    _nombre.dispose();
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await ref
          .read(talonariosRepositoryProvider)
          .registrarTipo(
            TipoReciboEntity(
              codTipoRecibo: widget.tipo?.codTipoRecibo ?? BigInt.zero,
              nombre: _nombre.text.trim(),
              detalle: _detalle.text.trim(),
              estado: _activo ? '1' : '0',
              sigla: _sigla.text.trim().toUpperCase(),
              audUsuario: BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
            ),
          );
      if (!mounted) return;
      refrescarTalonarios(ref);
      Navigator.pop(context);
      mostrarAviso(
        context,
        _esNuevo ? 'Tipo creado' : 'Tipo ${_sigla.text} actualizado',
      );
    } catch (e) {
      // Se queda abierto con todo intacto: el error más probable es una sigla
      // repetida, y perder el formulario por eso sería absurdo.
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_esNuevo ? 'Nuevo tipo de recibo' : 'Editar ${widget.tipo!.sigla}'),
    content: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                MensajeError(error: _error, compacto: true),
                const SizedBox(height: Esp.m),
              ],
              TextFormField(
                controller: _sigla,
                enabled: !_ocupado,
                maxLength: 5,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Sigla *',
                  helperText: 'Arma el prefijo del número de talonario (IR1001)',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'La sigla es obligatoria'
                            : null,
              ),
              const SizedBox(height: Esp.m),
              TextFormField(
                controller: _nombre,
                enabled: !_ocupado,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'El nombre es obligatorio'
                            : null,
              ),
              const SizedBox(height: Esp.m),
              TextFormField(
                controller: _detalle,
                enabled: !_ocupado,
                maxLength: 250,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Detalle',
                  helperText: 'Para qué empresa o uso es. Se muestra en el alta.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _activo,
                title: const Text('Activo'),
                subtitle: const Text('Los inactivos no aparecen en el alta'),
                onChanged:
                    _ocupado ? null : (v) => setState(() => _activo = v),
              ),
              if (!_esNuevo && widget.tipo!.cantTalonarios > 0)
                NotaDelDato(
                  texto:
                      'Este tipo ya tiene ${widget.tipo!.cantTalonarios} '
                      'talonarios. Cambiar la sigla NO renombra los que ya '
                      'existen: solo afecta a los que se creen de ahora en más.',
                  tono: TonoNota.aviso,
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _ocupado ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      BotonAccion(
        etiqueta: _esNuevo ? 'Crear' : 'Guardar',
        etiquetaOcupado: 'Guardando…',
        ocupado: _ocupado,
        onPressed: _guardar,
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// GRUPOS
// ═══════════════════════════════════════════════════════════════════════════

class _PanelGrupos extends ConsumerWidget {
  const _PanelGrupos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(talonarioGruposProvider);

    return Scaffold(
      floatingActionButton: PermissionWidget(
        buttonName: TalonariosBotones.nuevo,
        child: FloatingActionButton.extended(
          onPressed: () => _editarGrupo(context, ref, null),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo grupo'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, cajon) {
          final aire = Aire.de(cajon.maxWidth);
          return async.when(
            loading: () => const EsqueletoLista(filas: 3),
            error:
                (e, _) => MensajeError(
                  error: e,
                  onReintentar: () => ref.invalidate(talonarioGruposProvider),
                ),
            data: (lista) {
              if (lista.isEmpty) {
                return const MensajeVacio(
                  icono: Icons.folder_outlined,
                  titulo: 'No hay grupos',
                  detalle:
                      'Los grupos juntan tipos de recibo para filtrar listados '
                      'y reportes.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => refrescarTalonarios(ref),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    aire.esChico ? Esp.m : Esp.xl,
                    Esp.m,
                    aire.esChico ? Esp.m : Esp.xl,
                    88,
                  ),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Esp.s),
                  itemBuilder: (_, i) => _FilaGrupo(grupo: lista[i]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FilaGrupo extends ConsumerWidget {
  const _FilaGrupo({required this.grupo});

  final TalonarioGrupoEntity grupo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipos = ref.watch(tiposPorGrupoProvider(grupo.codGrupo));

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          grupo.nombre,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: Peso.titulo),
        ),
        subtitle: Text(
          '${grupo.cantTipos} tipos  ·  ${grupo.cantTalonarios} talonarios',
          style: context.apagado(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PermissionWidget(
              buttonName: TalonariosBotones.editar,
              child: IconButton(
                tooltip: 'Editar grupo',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editarGrupo(context, ref, grupo),
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (grupo.detalle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.s),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(grupo.detalle, style: context.apagado()),
              ),
            ),
          tipos.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.all(Esp.l),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            error:
                (e, _) => Padding(
                  padding: const EdgeInsets.all(Esp.m),
                  child: MensajeError(
                    error: e,
                    compacto: true,
                    onReintentar:
                        () => ref.invalidate(
                          tiposPorGrupoProvider(grupo.codGrupo),
                        ),
                  ),
                ),
            data:
                (asignados) => Column(
                  children: [
                    if (asignados.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Esp.l,
                          0,
                          Esp.l,
                          Esp.m,
                        ),
                        child: NotaDelDato(
                          texto:
                              'Este grupo no tiene ningún tipo asignado, así '
                              'que no filtra nada.',
                          tono: TonoNota.aviso,
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Esp.l,
                          0,
                          Esp.l,
                          Esp.s,
                        ),
                        child: Wrap(
                          spacing: Esp.s,
                          runSpacing: Esp.s,
                          children:
                              asignados
                                  .map(
                                    (a) => InputChip(
                                      label: Text(a.datoTipo),
                                      onDeleted:
                                          tienePermisoDeBoton(
                                                ref,
                                                TalonariosBotones.editar,
                                              )
                                              ? () => _quitarTipo(
                                                context,
                                                ref,
                                                grupo,
                                                a.codTipoRecibo,
                                                a.datoTipo,
                                              )
                                              : null,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Esp.l, 0, Esp.l, Esp.m),
                      child: Row(
                        children: [
                          PermissionWidget(
                            buttonName: TalonariosBotones.editar,
                            child: TextButton.icon(
                              onPressed:
                                  () => _asignarTipo(context, ref, grupo),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Agregar tipo'),
                            ),
                          ),
                          const Spacer(),
                          PermissionWidget(
                            buttonName: TalonariosBotones.eliminar,
                            child:
                                grupo.sePuedeEliminar
                                    ? TextButton.icon(
                                      onPressed:
                                          () => _eliminarGrupo(
                                            context,
                                            ref,
                                            grupo,
                                          ),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      label: const Text('Eliminar grupo'),
                                    )
                                    : Tooltip(
                                      message:
                                          'Quitá primero los '
                                          '${grupo.cantTipos} tipos',
                                      child: Text(
                                        'No se puede eliminar',
                                        style: context.apagado(),
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

Future<void> _editarGrupo(
  BuildContext context,
  WidgetRef ref,
  TalonarioGrupoEntity? grupo,
) async {
  final permiso =
      grupo == null ? TalonariosBotones.nuevo : TalonariosBotones.editar;
  if (!tienePermisoDeBoton(ref, permiso)) {
    mostrarAviso(
      context,
      'No tenés permiso para esta acción.',
      tono: TonoAviso.aviso,
    );
    return;
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormularioGrupo(grupo: grupo),
  );
}

Future<void> _eliminarGrupo(
  BuildContext context,
  WidgetRef ref,
  TalonarioGrupoEntity grupo,
) async {
  final sigue = await confirmar(
    context,
    titulo: '¿Eliminar el grupo ${grupo.nombre}?',
    detalle:
        'No tiene tipos asignados. Los talonarios no se tocan: el grupo solo '
        'sirve para filtrar.',
    textoConfirmar: 'Eliminar',
    destructiva: true,
  );
  if (!sigue || !context.mounted) return;

  try {
    await ref
        .read(talonariosRepositoryProvider)
        .eliminarGrupo(
          grupo.codGrupo,
          BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
        );
    if (!context.mounted) return;
    refrescarTalonarios(ref);
    mostrarAviso(context, 'Grupo eliminado');
  } catch (e) {
    if (!context.mounted) return;
    mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
  }
}

Future<void> _quitarTipo(
  BuildContext context,
  WidgetRef ref,
  TalonarioGrupoEntity grupo,
  BigInt codTipoRecibo,
  String datoTipo,
) async {
  final sigue = await confirmar(
    context,
    titulo: '¿Quitar $datoTipo del grupo?',
    detalle:
        'El tipo sigue existiendo y sus talonarios no se tocan: solo deja de '
        'estar en «${grupo.nombre}».',
    textoConfirmar: 'Quitar',
  );
  if (!sigue || !context.mounted) return;

  try {
    await ref
        .read(talonariosRepositoryProvider)
        .quitarTipoDeGrupo(
          TalonarioPorGrupoEntity(
            codGrupo: grupo.codGrupo,
            codTipoRecibo: codTipoRecibo,
            audUsuario: BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
          ),
        );
    if (!context.mounted) return;
    refrescarTalonarios(ref);
    mostrarAviso(context, 'Tipo quitado del grupo');
  } catch (e) {
    if (!context.mounted) return;
    mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
  }
}

/// Elige entre los tipos que **todavía no están** en el grupo.
Future<void> _asignarTipo(
  BuildContext context,
  WidgetRef ref,
  TalonarioGrupoEntity grupo,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder:
        (ctx) => Consumer(
          builder: (ctx, ref, __) {
            final async = ref.watch(
              tiposDisponiblesParaGrupoProvider(grupo.codGrupo),
            );
            return async.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.all(Esp.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error:
                  (e, _) => Padding(
                    padding: const EdgeInsets.all(Esp.l),
                    child: MensajeError(
                      error: e,
                      compacto: true,
                      onReintentar:
                          () => ref.invalidate(
                            tiposDisponiblesParaGrupoProvider(grupo.codGrupo),
                          ),
                    ),
                  ),
              data:
                  (libres) =>
                      libres.isEmpty
                          ? const SizedBox(
                            height: 240,
                            child: MensajeVacio(
                              icono: Icons.check_circle_outline,
                              titulo: 'Ya están todos',
                              detalle:
                                  'Todos los tipos de recibo existentes ya '
                                  'pertenecen a este grupo.',
                            ),
                          )
                          : ListView(
                            shrinkWrap: true,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(Esp.l),
                                child: Text(
                                  'Agregar a ${grupo.nombre}',
                                  style: ctx.tituloSeccion(),
                                ),
                              ),
                              ...libres.map(
                                (t) => ListTile(
                                  leading: const Icon(Icons.sell_outlined),
                                  title: Text(t.datoTipo),
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await ref
                                          .read(talonariosRepositoryProvider)
                                          .asignarTipoAGrupo(
                                            TalonarioPorGrupoEntity(
                                              codGrupo: grupo.codGrupo,
                                              codTipoRecibo: t.codTipoRecibo,
                                              audUsuario: BigInt.from(
                                                ref
                                                        .read(userProvider)
                                                        ?.codUsuario ??
                                                    0,
                                              ),
                                            ),
                                          );
                                      if (!context.mounted) return;
                                      refrescarTalonarios(ref);
                                      mostrarAviso(
                                        context,
                                        '${t.datoTipo} agregado',
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      mostrarAviso(
                                        context,
                                        textoParaUsuario(e),
                                        tono: TonoAviso.error,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: Esp.l),
                            ],
                          ),
            );
          },
        ),
  );
}

class _FormularioGrupo extends ConsumerStatefulWidget {
  const _FormularioGrupo({this.grupo});

  final TalonarioGrupoEntity? grupo;

  @override
  ConsumerState<_FormularioGrupo> createState() => _FormularioGrupoState();
}

class _FormularioGrupoState extends ConsumerState<_FormularioGrupo> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.grupo?.nombre ?? '');
  late final _detalle = TextEditingController(text: widget.grupo?.detalle ?? '');

  bool _ocupado = false;
  Object? _error;

  bool get _esNuevo => widget.grupo == null;

  @override
  void dispose() {
    _nombre.dispose();
    _detalle.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await ref
          .read(talonariosRepositoryProvider)
          .registrarGrupo(
            TalonarioGrupoEntity(
              codGrupo: widget.grupo?.codGrupo ?? BigInt.zero,
              nombre: _nombre.text.trim(),
              detalle: _detalle.text.trim(),
              audUsuario: BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
            ),
          );
      if (!mounted) return;
      refrescarTalonarios(ref);
      Navigator.pop(context);
      mostrarAviso(context, _esNuevo ? 'Grupo creado' : 'Grupo actualizado');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_esNuevo ? 'Nuevo grupo' : 'Editar grupo'),
    content: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                MensajeError(error: _error, compacto: true),
                const SizedBox(height: Esp.m),
              ],
              TextFormField(
                controller: _nombre,
                enabled: !_ocupado,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'El nombre es obligatorio'
                            : null,
              ),
              const SizedBox(height: Esp.m),
              TextFormField(
                controller: _detalle,
                enabled: !_ocupado,
                maxLength: 250,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Detalle',
                  helperText: 'Para qué se usa este grupo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _ocupado ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      BotonAccion(
        etiqueta: _esNuevo ? 'Crear' : 'Guardar',
        etiquetaOcupado: 'Guardando…',
        ocupado: _ocupado,
        onPressed: _guardar,
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, size: 13, color: Theme.of(context).hintColor),
      const SizedBox(width: Esp.xs),
      Text(texto, style: context.apagado()),
    ],
  );
}
