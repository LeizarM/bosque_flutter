/// Detalle de un evento: resumen, acciones según su estado y dos pestañas,
/// tipos de vale y participantes.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ttk_tickets_provider.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tablas_utils.dart';
import 'package:bosque_flutter/domain/entities/ttk_evento_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_participante_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_tipo_ticket_entity.dart';
import 'package:bosque_flutter/presentation/widgets/shared/permission_widget.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_eventos_dialogos.dart';

class DetalleEventoTtk extends ConsumerWidget {
  const DetalleEventoTtk({
    super.key,
    required this.codEvento,
    required this.alVolver,
  });

  final BigInt codEvento;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asincrono = ref.watch(ttkEventoProvider(codEvento));
    return LayoutBuilder(
      builder: (context, c) {
        final compacto = Aire.de(c.maxWidth).esChico;
        return asincrono.when(
          loading: () => const EsqueletoListaTtk(),
          error:
              (e, _) => MensajeError(
                error: e,
                onReintentar:
                    () => ref.invalidate(ttkEventoProvider(codEvento)),
              ),
          data:
              (e) =>
                  e == null
                      ? Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: alVolver,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Volver a los eventos'),
                            ),
                          ),
                          const Expanded(
                            child: MensajeVacio(
                              icono: Icons.event_busy,
                              titulo: 'El evento ya no existe',
                              detalle:
                                  'Vuelve a la lista para ver los eventos actuales.',
                            ),
                          ),
                        ],
                      )
                      : _Contenido(
                        evento: e,
                        compacto: compacto,
                        alVolver: alVolver,
                      ),
        );
      },
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({
    required this.evento,
    required this.compacto,
    required this.alVolver,
  });

  final TtkEventoEntity evento;
  final bool compacto;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = evento;
    final acciones = accionesPermitidasTtk(
      ref,
      accionesEventoTtk(context, ref, e, alEliminar: alVolver),
    );
    final detalle = [
      fechaCorta(e.fecha),
      if ((e.lugar ?? '').isNotEmpty) e.lugar!,
      if ((e.descripcion ?? '').isNotEmpty) e.descripcion!,
    ].join(' · ');
    final relleno = compacto ? Esp.m : Esp.xl;

    return Padding(
      padding: EdgeInsets.fromLTRB(relleno, relleno, relleno, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EncabezadoTtk(
            ceja: 'Evento',
            titulo: e.nombre,
            detalle: detalle,
            compacto: compacto,
            alVolver: alVolver,
            acciones: [
              if (compacto)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Etiqueta(
                      texto: e.estadoTexto,
                      tono: ttkTonoEstado(e.estado),
                    ),
                    if (acciones.isNotEmpty)
                      MenuAccionesTtk(acciones: acciones),
                  ],
                )
              else ...[
                Etiqueta(texto: e.estadoTexto, tono: ttkTonoEstado(e.estado)),
                for (final a in acciones)
                  a.destructiva
                      ? OutlinedButton.icon(
                        onPressed: a.alTocar,
                        icon: Icon(a.icono, size: 18),
                        label: Text(a.etiqueta),
                      )
                      : FilledButton.tonalIcon(
                        onPressed: a.alTocar,
                        icon: Icon(a.icono, size: 18),
                        label: Text(a.etiqueta),
                      ),
              ],
            ],
          ),
          const SizedBox(height: Esp.m),
          Wrap(
            spacing: compacto ? Esp.l : Esp.xl,
            runSpacing: Esp.s,
            children: [
              CifraTtk(valor: '${e.totalParticipantes}', rotulo: 'En la lista'),
              CifraTtk(valor: '${e.totalEmpleados}', rotulo: 'Empleados'),
              CifraTtk(valor: '${e.totalRecientes}', rotulo: 'Recientes'),
              CifraTtk(valor: '${e.totalInvitados}', rotulo: 'Invitados'),
              CifraTtk(valor: '${e.totalTickets}', rotulo: 'Vales'),
            ],
          ),
          if (!e.usaTickets)
            const NotaDelDato(
              texto:
                  'Este evento no reparte vales. Su bingo se arma en la pantalla de configuración del bingo.',
            )
          else
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Esp.s),
                    TabBar(
                      isScrollable: compacto,
                      tabAlignment: compacto ? TabAlignment.start : null,
                      tabs: [
                        Tab(text: 'Participantes (${e.totalParticipantes})'),
                        Tab(text: 'Tipos de vale (${e.totalTipos})'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _TabParticipantes(evento: e),
                          _TabTipos(evento: e),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIPOS DE VALE
// ═══════════════════════════════════════════════════════════════════════════

class _TabTipos extends ConsumerStatefulWidget {
  const _TabTipos({required this.evento});

  final TtkEventoEntity evento;

  @override
  ConsumerState<_TabTipos> createState() => _TabTiposState();
}

class _TabTiposState extends ConsumerState<_TabTipos> {
  final _buscador = TextEditingController();
  String _buscar = '';

  @override
  void dispose() {
    _buscador.dispose();
    super.dispose();
  }

  List<AccionTtk> _acciones(TtkTipoTicketEntity t) {
    final e = widget.evento;
    if (!t.puedeEditar) return const [];
    return [
      AccionTtk(
        'Editar',
        Icons.edit_outlined,
        () => editarTipoTtk(context, ref, codEvento: e.codEvento!, tipo: t),
        boton: BotonTtkEvento.editar,
      ),
      AccionTtk(
        'Eliminar',
        Icons.delete_outline,
        () async {
          final ok = await confirmar(
            context,
            titulo: 'Eliminar el tipo de vale',
            detalle:
                'Se quita «${t.nombre}» y los ${t.totalVales} vales repartidos de ese tipo.',
            textoConfirmar: 'Eliminar',
            destructiva: true,
          );
          if (!ok || !mounted) return;
          final hecho = await ejecutarTtk(
            context,
            () => ref
                .read(ttkTicketsRepositoryProvider)
                .eliminarTipo(t.codTipoTicket!),
          );
          if (hecho) refrescarEventoTtk(ref, e.codEvento);
        },
        boton: BotonTtkEvento.editar,
        destructiva: true,
      ),
    ];
  }

  Widget _muestra(TtkTipoTicketEntity t) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: ttkColorHex(t.colorHex) ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: cs.outlineVariant),
      ),
    );
  }

  Widget _numero(int n) => Text('$n', style: context.numero(fuerte: true));

  @override
  Widget build(BuildContext context) {
    final e = widget.evento;
    final asincrono = ref.watch(ttkTiposProvider(e.codEvento!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Esp.s),
          child: Wrap(
            spacing: Esp.s,
            runSpacing: Esp.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Cuántos vales de cada tipo recibe cada grupo.',
                style: context.apagado(),
              ),
              if (e.puedeEditar)
                PermissionWidget(
                  buttonName: BotonTtkEvento.editar,
                  child: FilledButton.tonalIcon(
                    onPressed:
                        () => editarTipoTtk(
                          context,
                          ref,
                          codEvento: e.codEvento!,
                        ),
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo tipo de vale'),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: asincrono.when(
            loading: () => const EsqueletoListaTtk(),
            error:
                (err, _) => MensajeError(
                  error: err,
                  onReintentar:
                      () => ref.invalidate(ttkTiposProvider(e.codEvento!)),
                ),
            data: (todos) {
              if (todos.isEmpty) {
                return const MensajeVacio(
                  icono: Icons.confirmation_number_outlined,
                  titulo: 'Aún no hay tipos de vale',
                  detalle:
                      'Crea el primero (por ejemplo, Almuerzo) para empezar a repartir.',
                );
              }
              final q = _buscar.toLowerCase();
              final tipos = [
                for (final t in todos)
                  if (q.isEmpty || t.nombre.toLowerCase().contains(q)) t,
              ];
              return ListadoTtk<TtkTipoTicketEntity>(
                filas: tipos,
                buscador: _buscador,
                alBuscar: (t) => setState(() => _buscar = t.trim()),
                pistaBuscar: 'Buscar tipo de vale',
                columnas: [
                  BosqueColumn(
                    label: 'Tipo',
                    flex: 4,
                    cellBuilder:
                        (t) => Row(
                          children: [
                            _muestra(t),
                            const SizedBox(width: Esp.s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.nombre,
                                    style: context.tituloSeccion(),
                                  ),
                                  if ((t.leyenda ?? '').isNotEmpty)
                                    Text(
                                      t.leyenda!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.apagado(),
                                    ),
                                  if (t.daCartonBingo)
                                    const Padding(
                                      padding: EdgeInsets.only(top: Esp.xs),
                                      child: _ChipBingo(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                  ),
                  BosqueColumn(
                    label: 'Empleado',
                    alignment: Alignment.center,
                    cellBuilder: (t) => _numero(t.cantEmpleado),
                  ),
                  BosqueColumn(
                    label: 'Reciente',
                    alignment: Alignment.center,
                    cellBuilder: (t) => _numero(t.cantReciente),
                  ),
                  BosqueColumn(
                    label: 'Invitado',
                    alignment: Alignment.center,
                    cellBuilder: (t) => _numero(t.cantInvitado),
                  ),
                  BosqueColumn(
                    label: 'Repartidos',
                    alignment: Alignment.center,
                    cellBuilder: (t) => _numero(t.totalVales),
                  ),
                  BosqueColumn(
                    label: 'Personas',
                    alignment: Alignment.center,
                    cellBuilder: (t) => _numero(t.totalParticipantes),
                  ),
                  BosqueColumn(
                    label: 'Acciones',
                    flex: 2,
                    alignment: Alignment.center,
                    cellBuilder:
                        (t) => AccionesEnLineaTtk(acciones: _acciones(t)),
                  ),
                ],
                tarjeta:
                    (t) => TarjetaTtk(
                      inicio: _muestra(t),
                      titulo: t.nombre,
                      subtitulo: t.leyenda,
                      etiquetas: [
                        Etiqueta(texto: 'Empleado ${t.cantEmpleado}'),
                        Etiqueta(texto: 'Reciente ${t.cantReciente}'),
                        Etiqueta(texto: 'Invitado ${t.cantInvitado}'),
                        if (t.daCartonBingo) const _ChipBingo(),
                      ],
                      pie: Text(
                        '${t.totalVales} vales repartidos a ${t.totalParticipantes} personas',
                        style: context.apagado(),
                      ),
                      acciones: _acciones(t),
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARTICIPANTES
// ═══════════════════════════════════════════════════════════════════════════

class _TabParticipantes extends ConsumerStatefulWidget {
  const _TabParticipantes({required this.evento});

  final TtkEventoEntity evento;

  @override
  ConsumerState<_TabParticipantes> createState() => _TabParticipantesState();
}

class _TabParticipantesState extends ConsumerState<_TabParticipantes> {
  final _buscador = TextEditingController();
  Timer? _espera;
  String _buscar = '';
  String? _categoria;

  /// Participantes marcados para los vales en lote (sus `codParticipante`).
  Set<Object> _sel = {};

  BigInt get _cod => widget.evento.codEvento!;

  @override
  void dispose() {
    _espera?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  void _alEscribir(String t) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _buscar = t.trim());
    });
  }

  Future<void> _valesEnLote() async {
    final aplicado = await valesEnLoteTtk(
      context,
      codEvento: _cod,
      seleccionados: {for (final k in _sel) k as BigInt},
    );
    if (aplicado && mounted) setState(() => _sel = {});
  }

  Future<void> _generar() async {
    final ok = await confirmar(
      context,
      titulo: 'Agregar a los empleados activos',
      detalle:
          'Se suman a la lista los empleados activos que todavía no están, con la categoría que les da la regla de recientes.',
      textoConfirmar: 'Agregar',
    );
    if (!ok || !mounted) return;
    final hecho = await ejecutarTtk(
      context,
      () => ref.read(ttkTicketsRepositoryProvider).generarParticipantes(_cod),
    );
    if (hecho) refrescarEventoTtk(ref, _cod);
  }

  List<AccionTtk> _acciones(
    TtkParticipanteEntity p,
    List<TtkParticipanteEntity> todos,
  ) {
    final e = widget.evento;
    final repo = ref.read(ttkTicketsRepositoryProvider);
    return [
      AccionTtk(
        'Ver vales',
        Icons.confirmation_number_outlined,
        () => editarValesTtk(context, ref, p),
      ),
      if (p.puedeEditar && !p.esInvitado)
        AccionTtk(
          'Cambiar categoría',
          Icons.swap_horiz,
          () => cambiarCategoriaTtk(context, ref, p),
          boton: BotonTtkEvento.editar,
        ),
      if (p.puedeEditar && !p.esInvitado && p.categoriaManual)
        AccionTtk('Restablecer categoría', Icons.restart_alt, () async {
          final hecho = await ejecutarTtk(
            context,
            () => repo.restablecerParticipante(p.codParticipante!),
          );
          if (hecho) refrescarEventoTtk(ref, _cod);
        }, boton: BotonTtkEvento.editar),
      if (p.puedeEditar && p.esInvitado)
        AccionTtk(
          'Editar invitado',
          Icons.edit_outlined,
          () => editarInvitadoTtk(
            context,
            ref,
            codEvento: _cod,
            anfitriones: todos,
            invitado: p,
          ),
          boton: BotonTtkEvento.editar,
        ),
      if (e.puedeImprimir)
        AccionTtk(
          'Imprimir sus vales',
          Icons.print_outlined,
          () => imprimirValesTtk(
            context,
            ref,
            codEvento: _cod,
            codParticipante: p.codParticipante,
            titulo: 'Vales · ${p.nombreCompleto}',
          ),
          boton: BotonTtkEvento.imprimir,
        ),
      if (p.puedeEditar)
        AccionTtk(
          'Quitar de la lista',
          Icons.person_remove_outlined,
          () async {
            final ok = await confirmar(
              context,
              titulo: 'Quitar de la lista',
              detalle:
                  '${p.nombreCompleto} deja de recibir los vales de este evento.',
              textoConfirmar: 'Quitar',
              destructiva: true,
            );
            if (!ok || !mounted) return;
            final hecho = await ejecutarTtk(
              context,
              () => repo.eliminarParticipante(p.codParticipante!),
            );
            if (hecho) refrescarEventoTtk(ref, _cod);
          },
          boton: BotonTtkEvento.editar,
          destructiva: true,
        ),
    ];
  }

  List<Widget> _etiquetas(TtkParticipanteEntity p) => [
    Etiqueta(
      texto: p.categoriaTexto,
      tono:
          p.categoria == 'R'
              ? TonoEtiqueta.aviso
              : (p.categoria == 'I' ? TonoEtiqueta.neutro : TonoEtiqueta.exito),
    ),
    if (p.categoriaManual) const Etiqueta(texto: 'Ajustada por RRHH'),
  ];

  String _apoyo(TtkParticipanteEntity p) =>
      p.esInvitado
          ? [
            if ((p.nombreAnfitrion ?? '').isNotEmpty)
              'Invita: ${p.nombreAnfitrion}',
            if ((p.documento ?? '').isNotEmpty) p.documento!,
          ].join(' · ')
          : ttkOGuion(p.cargo);

  @override
  Widget build(BuildContext context) {
    final e = widget.evento;
    final filtro = (codEvento: _cod, categoria: _categoria, buscar: _buscar);
    final asincrono = ref.watch(ttkParticipantesProvider(filtro));
    final todos = asincrono.valueOrNull ?? const <TtkParticipanteEntity>[];

    final filtroCategoria = DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: _categoria,
        hint: const Text('Todas las categorías'),
        borderRadius: BorderRadius.circular(Esquina.chica),
        items: const [
          DropdownMenuItem(value: null, child: Text('Todas las categorías')),
          DropdownMenuItem(value: 'E', child: Text('Empleados')),
          DropdownMenuItem(value: 'R', child: Text('Recientes')),
          DropdownMenuItem(value: 'I', child: Text('Invitados')),
        ],
        onChanged: (v) => setState(() => _categoria = v),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (e.puedeEditar)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Esp.s),
            child: PermissionWidget(
              buttonName: BotonTtkEvento.editar,
              child: LayoutBuilder(
                builder: (context, c) {
                  final opciones = <(String, IconData, VoidCallback)>[
                    (
                      'Agregar empleados activos',
                      Icons.groups_outlined,
                      _generar,
                    ),
                    (
                      'Agregar empleado',
                      Icons.person_add_alt,
                      () => agregarEmpleadoTtk(context, ref, _cod),
                    ),
                    (
                      'Agregar invitado',
                      Icons.person_add_outlined,
                      () => editarInvitadoTtk(
                        context,
                        ref,
                        codEvento: _cod,
                        anfitriones: todos,
                      ),
                    ),
                  ];
                  final n = _sel.length;
                  final lote = <Widget>[
                    FilledButton.tonalIcon(
                      key: const ValueKey('ttk-vales-lote'),
                      onPressed: _valesEnLote,
                      icon: const Icon(Icons.library_add_check_outlined),
                      label: Text(
                        n == 0 ? 'Vales en lote' : 'Vales en lote ($n)',
                      ),
                    ),
                    if (n > 0)
                      TextButton(
                        onPressed: () => setState(() => _sel = {}),
                        child: const Text('Quitar selección'),
                      ),
                  ];
                  // En el teléfono las tres altas van en un solo menú: la lista gana alto.
                  if (Aire.de(c.maxWidth).esChico) {
                    return Wrap(
                      spacing: Esp.s,
                      runSpacing: Esp.s,
                      children: [
                        MenuAnchor(
                          builder:
                              (context, menu, _) => FilledButton.tonalIcon(
                                onPressed:
                                    () =>
                                        menu.isOpen
                                            ? menu.close()
                                            : menu.open(),
                                icon: const Icon(Icons.person_add_alt),
                                label: const Text('Agregar a la lista'),
                              ),
                          menuChildren: [
                            for (final (texto, icono, accion) in opciones)
                              MenuItemButton(
                                leadingIcon: Icon(icono),
                                onPressed: accion,
                                child: Text(texto),
                              ),
                          ],
                        ),
                        ...lote,
                      ],
                    );
                  }
                  return Wrap(
                    spacing: Esp.s,
                    runSpacing: Esp.s,
                    children: [
                      for (var i = 0; i < opciones.length; i++)
                        i == 0
                            ? FilledButton.tonalIcon(
                              onPressed: opciones[i].$3,
                              icon: Icon(opciones[i].$2),
                              label: Text(opciones[i].$1),
                            )
                            : OutlinedButton.icon(
                              onPressed: opciones[i].$3,
                              icon: Icon(opciones[i].$2),
                              label: Text(opciones[i].$1),
                            ),
                      const SizedBox(width: Esp.l),
                      ...lote,
                    ],
                  );
                },
              ),
            ),
          )
        else
          const SizedBox(height: Esp.s),
        Expanded(
          child: asincrono.when(
            skipLoadingOnReload: true,
            loading: () => const EsqueletoListaTtk(),
            error:
                (err, _) => MensajeError(
                  error: err,
                  onReintentar:
                      () => ref.invalidate(ttkParticipantesProvider(filtro)),
                ),
            data:
                (lista) =>
                    lista.isEmpty && _buscar.isEmpty && _categoria == null
                        ? const MensajeVacio(
                          icono: Icons.groups_outlined,
                          titulo: 'La lista está vacía',
                          detalle:
                              'Agrega a los empleados activos de una vez o a cada persona por separado.',
                        )
                        : ListadoTtk<TtkParticipanteEntity>(
                          filas: lista,
                          buscador: _buscador,
                          alBuscar: _alEscribir,
                          pistaBuscar: 'Buscar por nombre',
                          filtros: [filtroCategoria],
                          seleccion:
                              e.puedeEditar &&
                                      tienePermisoDeBoton(
                                        ref,
                                        BotonTtkEvento.editar,
                                      )
                                  ? SeleccionTtk<TtkParticipanteEntity>(
                                    claves: _sel,
                                    clave: (p) => p.codParticipante!,
                                    alCambiar: (s) => setState(() => _sel = s),
                                  )
                                  : null,
                          columnas: [
                            BosqueColumn(
                              label: 'Nombre',
                              flex: 4,
                              cellBuilder:
                                  (p) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.nombreCompleto,
                                        style: context.tituloSeccion(),
                                      ),
                                      Text(
                                        _apoyo(p),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.apagado(),
                                      ),
                                    ],
                                  ),
                            ),
                            BosqueColumn(
                              label: 'Categoría',
                              flex: 2,
                              cellBuilder:
                                  (p) => Wrap(
                                    spacing: Esp.xs,
                                    runSpacing: Esp.xs,
                                    children: _etiquetas(p),
                                  ),
                            ),
                            BosqueColumn(
                              label: 'Ingreso',
                              flex: 2,
                              cellBuilder:
                                  (p) => Text(
                                    p.esInvitado
                                        ? '—'
                                        : fechaCorta(p.fechaIngreso),
                                    style: context.numero(),
                                  ),
                            ),
                            BosqueColumn(
                              label: 'Vales',
                              flex: 4,
                              cellBuilder:
                                  (p) => Text(
                                    p.resumenVales,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            ),
                            BosqueColumn(
                              label: 'Total',
                              alignment: Alignment.center,
                              cellBuilder:
                                  (p) => Text(
                                    '${p.totalVales}',
                                    style: context.numero(fuerte: true),
                                  ),
                            ),
                            BosqueColumn(
                              label: 'Acciones',
                              flex: 3,
                              alignment: Alignment.center,
                              cellBuilder:
                                  (p) => AccionesEnLineaTtk(
                                    acciones: _acciones(p, lista),
                                  ),
                            ),
                          ],
                          tarjeta:
                              (p) => TarjetaTtk(
                                titulo: p.nombreCompleto,
                                subtitulo: _apoyo(p),
                                etiquetas: _etiquetas(p),
                                pie: Text(
                                  '${p.totalVales} ${p.totalVales == 1 ? 'vale' : 'vales'} · ${p.resumenVales}',
                                  style: context.apagado(),
                                ),
                                acciones: _acciones(p, lista),
                                alTocar: () => editarValesTtk(context, ref, p),
                              ),
                        ),
          ),
        ),
      ],
    );
  }
}

/// Marca del tipo de vale enlazado al bingo: cada vale da un cartón.
class _ChipBingo extends StatelessWidget {
  const _ChipBingo();

  @override
  Widget build(BuildContext context) =>
      const Etiqueta(texto: 'Da cartón de bingo', tono: TonoEtiqueta.exito);
}
