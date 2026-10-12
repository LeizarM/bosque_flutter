// Destino final: lib/presentation/screens/estructura-organizacional/responsables_cierre_screen.dart
import 'package:bosque_flutter/core/state/responsables_cierre_provider.dart';
import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/responsable_cierre_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/paneles_cierre.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/tabla_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Responsables del cierre (archivo SQL 81): la matriz de Verificar Cierre.
/// Quién revisa cada sección y de qué sucursal lo deciden RRHH o un
/// administrador desde el organigrama. Las secciones salen del catálogo
/// (archivo SQL 86): se crean, se quitan y se vuelven a pedir desde aquí.
class ResponsablesCierreScreen extends ConsumerWidget {
  final int idTarRuti;
  final String nombreTarea;

  const ResponsablesCierreScreen({
    super.key,
    this.idTarRuti = 39,
    this.nombreTarea = 'Verificar Cierre de Operaciones',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prov = responsablesCierreProvider(idTarRuti);
    final s = ref.watch(prov);
    final n = ref.read(prov.notifier);

    ref.listen(prov, (previo, actual) {
      if (actual.aviso != null && actual.aviso != previo?.aviso) {
        mostrarAviso(context, actual.aviso!);
      }
      if (actual.mensajeError != null &&
          actual.mensajeError != previo?.mensajeError) {
        mostrarAviso(context, actual.mensajeError!, tono: TonoAviso.error);
      }
    });

    final responsables = s.responsables;
    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo: 'Responsables del cierre',
          subtitulo:
              s.filas.cargado
                  ? '$nombreTarea · ${responsables.length == 1 ? '1 responsable' : '${responsables.length} responsables'}'
                  : nombreTarea,
          insignia: InsigniaTarea.deTipo(
            context,
            5,
            icono: Icons.how_to_reg_outlined,
          ),
          acciones: [
            IconButton(
              tooltip: 'Volver a leer',
              icon: const Icon(Icons.refresh),
              onPressed: n.cargar,
            ),
          ],
        ),
        body: SafeArea(
          child: MargenPaginaTareas(
            child: RefreshIndicator(
              onRefresh: n.cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: Esp.xl),
                children: [
                  Wrap(
                    spacing: Esp.l,
                    runSpacing: Esp.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Text(
                          'Quién revisa cada sección del cierre y de qué '
                          'sucursal. Lo que no está asignado no lo revisa '
                          'nadie, y quien tiene la tarea sin ninguna sección '
                          'la recibe en "No aplica".',
                          style: context.apagado(),
                        ),
                      ),
                      Wrap(
                        spacing: Esp.s,
                        runSpacing: Esp.s,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _abrirSecciones(context),
                            icon: const Icon(Icons.view_column_outlined),
                            label: const Text('Secciones'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed:
                                s.vigentes.isEmpty
                                    ? null
                                    : () => _agregar(context, n, s),
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text('Agregar responsable'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: Esp.l),
                  if (s.sinSecciones.isNotEmpty) ...[
                    _AvisoSinSecciones(
                      cargos: s.sinSecciones,
                      onAgregar: (c) => _agregar(context, n, s, candidato: c),
                    ),
                    const SizedBox(height: Esp.l),
                  ],
                  ..._cuerpo(context, s, n, responsables),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _cuerpo(
    BuildContext context,
    ResponsablesCierreState s,
    ResponsablesCierreNotifier n,
    List<ResponsableConSecciones> responsables,
  ) {
    final error = s.filas.error ?? s.secciones.error;
    if (error != null) {
      return [
        EstadoTareas.error(
          titulo: 'No se pudo leer la matriz',
          detalle: mensajeError(error),
          onReintentar: n.cargar,
        ),
      ];
    }
    if (!s.filas.cargado || !s.secciones.cargado) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: Esp.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    final secciones = s.vigentes;
    if (secciones.isEmpty) {
      return [
        EstadoTareas(
          icono: Icons.view_column_outlined,
          titulo: 'No hay secciones que pedir',
          detalle:
              'Crea una o vuelve a pedir una que se quitó. Si el sistema se '
              'acaba de actualizar, falta correr el script 86 en la base.',
          accion: FilledButton.tonalIcon(
            onPressed: () => _abrirSecciones(context),
            icon: const Icon(Icons.view_column_outlined),
            label: const Text('Secciones'),
          ),
        ),
      ];
    }
    if (responsables.isEmpty) {
      return [
        EstadoTareas(
          icono: Icons.how_to_reg_outlined,
          titulo: 'Nadie revisa el cierre todavía',
          detalle: 'Agrega a quien revisa cada sección.',
          accion: FilledButton.tonalIcon(
            onPressed: () => _agregar(context, n, s),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Agregar responsable'),
          ),
        ),
      ];
    }

    Widget celda(ResponsableConSecciones r, SeccionCierre p) => _CeldaMatriz(
      filas: r.filasDe(p.codigo),
      seccion: p,
      guardando: (f) => s.guardando.contains(f.idRC),
      onAgregar: () => _agregar(context, n, s, responsable: r, seccion: p),
      onAutorrevision: (f, v) {
        HapticFeedback.selectionClick();
        n.cambiarAutorrevision(f, v);
      },
      onQuitar: (f) => _quitar(context, n, r, f),
    );

    return [
      LayoutBuilder(
        builder: (context, cajon) {
          if (cajon.maxWidth < 900) {
            return Column(
              children: [
                for (final r in responsables)
                  _TarjetaResponsable(
                    responsable: r,
                    secciones: secciones,
                    celda: (p) => celda(r, p),
                  ),
              ],
            );
          }
          final anchos = <AnchoCol>[
            const AnchoCol.flexible(3),
            for (final _ in secciones) const AnchoCol.flexible(2),
          ];
          return TablaCierre(
            anchos: anchos,
            titulos: ['Responsable', for (final p in secciones) p.nombre],
            filas: [
              for (final r in responsables)
                FilaTabla(
                  anchos: anchos,
                  alineacion: CrossAxisAlignment.start,
                  celdas: [
                    _NombreResponsable(responsable: r),
                    for (final p in secciones) celda(r, p),
                  ],
                ),
            ],
          );
        },
      ),
    ];
  }

  Future<void> _agregar(
    BuildContext context,
    ResponsablesCierreNotifier n,
    ResponsablesCierreState s, {
    CandidatoCierre? candidato,
    ResponsableConSecciones? responsable,
    SeccionCierre? seccion,
  }) async {
    HapticFeedback.selectionClick();
    await showDialog<bool>(
      context: context,
      builder:
          (_) => _DialogoResponsable(
            notifier: n,
            secciones: s.vigentes,
            candidatos: s.candidatos.filas,
            sucursales: s.sucursales,
            candidato: candidato,
            responsable: responsable,
            seccion: seccion,
          ),
    );
  }

  Future<void> _abrirSecciones(BuildContext context) async {
    HapticFeedback.selectionClick();
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogoSecciones(idTarRuti: idTarRuti),
    );
  }

  Future<void> _quitar(
    BuildContext context,
    ResponsablesCierreNotifier n,
    ResponsableConSecciones r,
    ResponsableCierre f,
  ) async {
    final si = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              '¿Quitar ${f.nombreSeccion.toLowerCase()} · ${f.nombreSucursal}?',
            ),
            content: Text(
              'Desde la próxima generación, ${r.titulo} ya no revisa esa '
              'sección. Si nadie más la tiene, esa parte del cierre queda sin '
              'revisar.',
            ),
            actions: [
              TextButton(
                onPressed: () => cerrarRuta(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => cerrarRuta(ctx, true),
                child: const Text('Quitar'),
              ),
            ],
          ),
    );
    // Null = se cerró sin elegir: no se quita nada.
    if (si == true) await n.quitar(f);
  }
}

class _AvisoSinSecciones extends StatelessWidget {
  final List<CandidatoCierre> cargos;
  final void Function(CandidatoCierre) onAgregar;

  const _AvisoSinSecciones({required this.cargos, required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    final tono = TareasColors.pendienteTexto(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TareasColors.pendiente(context),
        borderRadius: BorderRadius.circular(Esquina.media),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: tono, size: 20),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Text(
                    'Tienen la tarea pero ninguna sección: cada día la reciben '
                    'en "No aplica".',
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: tono),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.s),
            for (final c in cargos)
              Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(
                    child: Text(
                      '${c.cargo} · ${c.sucursal}'
                      '${c.personas == null ? '' : ' (${c.personas})'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onAgregar(c),
                    child: const Text('Agregar secciones'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NombreResponsable extends StatelessWidget {
  final ResponsableConSecciones responsable;

  const _NombreResponsable({required this.responsable});

  @override
  Widget build(BuildContext context) {
    final r = responsable;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: r.esCargo ? 'Un cargo: quien lo ocupe' : 'Una persona',
          child: Icon(
            r.esCargo ? Icons.badge_outlined : Icons.person_outline,
            size: 20,
            color: context.cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: Esp.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.titulo, style: Theme.of(context).textTheme.titleSmall),
              if (r.detalle != null) Text(r.detalle!, style: context.apagado()),
            ],
          ),
        ),
      ],
    );
  }
}

class _TarjetaResponsable extends StatelessWidget {
  final ResponsableConSecciones responsable;
  final List<SeccionCierre> secciones;
  final Widget Function(SeccionCierre) celda;

  const _TarjetaResponsable({
    required this.responsable,
    required this.secciones,
    required this.celda,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.m),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(
          color: context.cs.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Esp.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NombreResponsable(responsable: responsable),
            const SizedBox(height: Esp.s),
            for (final p in secciones)
              Padding(
                padding: const EdgeInsets.only(top: Esp.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(p.nombre, style: context.apagado()),
                      ),
                    ),
                    Expanded(child: celda(p)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Las sucursales que un responsable revisa en una sección, y el "+" para
/// agregar otra. Cada píldora tiene su menú: revisar lo propio y quitar.
class _CeldaMatriz extends StatelessWidget {
  final List<ResponsableCierre> filas;
  final SeccionCierre seccion;
  final bool Function(ResponsableCierre) guardando;
  final VoidCallback onAgregar;
  final void Function(ResponsableCierre, bool) onAutorrevision;
  final void Function(ResponsableCierre) onQuitar;

  const _CeldaMatriz({
    required this.filas,
    required this.seccion,
    required this.guardando,
    required this.onAgregar,
    required this.onAutorrevision,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    // Todas, o la sección de toda la empresa ya asignada: no hay más que agregar.
    final completa =
        filas.any((f) => f.codSucursal == null) ||
        (!seccion.porSucursal && filas.isNotEmpty);
    return Wrap(
      spacing: Esp.xs,
      runSpacing: Esp.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final f in filas)
          _PildoraFila(
            fila: f,
            porSucursal: seccion.porSucursal,
            guardando: guardando(f),
            onAutorrevision: (v) => onAutorrevision(f, v),
            onQuitar: () => onQuitar(f),
          ),
        if (!completa)
          IconButton(
            tooltip: filas.isEmpty ? 'Asignar' : 'Agregar otra sucursal',
            // Del alto de la píldora, para que la fila no se descuadre.
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            iconSize: 18,
            onPressed: onAgregar,
            icon: Icon(
              filas.isEmpty ? Icons.add_circle_outline : Icons.add,
              color: context.cs.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _PildoraFila extends StatelessWidget {
  final ResponsableCierre fila;
  final bool porSucursal;
  final bool guardando;
  final void Function(bool) onAutorrevision;
  final VoidCallback onQuitar;

  const _PildoraFila({
    required this.fila,
    required this.porSucursal,
    required this.guardando,
    required this.onAutorrevision,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final f = fila;
    final fondo = TareasColors.realizado(context);
    final color = TareasColors.realizadoTexto(context);
    final texto = porSucursal ? f.nombreSucursal : 'Asignada';
    return PopupMenuButton<String>(
      tooltip:
          f.puedeAutorrevisar
              ? '$texto · puede revisar su propio trabajo'
              : texto,
      enabled: !guardando,
      onSelected:
          (o) =>
              o == 'quitar'
                  ? onQuitar()
                  : onAutorrevision(!f.puedeAutorrevisar),
      itemBuilder:
          (_) => [
            CheckedPopupMenuItem(
              value: 'propio',
              checked: f.puedeAutorrevisar,
              child: const Text('Puede revisar su propio trabajo'),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'quitar',
              child: ListTile(
                leading: Icon(Icons.remove_circle_outline),
                title: Text('Quitar'),
              ),
            ),
          ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (guardando)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else if (f.puedeAutorrevisar)
              Icon(Icons.how_to_reg, size: 14, color: color),
            if (guardando || f.puedeAutorrevisar) const SizedBox(width: 4),
            Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Agregar una sección a un responsable. Si viene de una celda o del aviso, el
/// responsable (y la sección) ya están elegidos. Las reglas son del servidor:
/// si no acepta, su mensaje sale aquí mismo.
class _DialogoResponsable extends StatefulWidget {
  final ResponsablesCierreNotifier notifier;

  /// Las que se piden hoy; nunca vacía (sin secciones no se abre).
  final List<SeccionCierre> secciones;
  final List<CandidatoCierre> candidatos;
  final List<SucursalCaja> sucursales;
  final CandidatoCierre? candidato;
  final ResponsableConSecciones? responsable;
  final SeccionCierre? seccion;

  const _DialogoResponsable({
    required this.notifier,
    required this.secciones,
    required this.candidatos,
    required this.sucursales,
    this.candidato,
    this.responsable,
    this.seccion,
  });

  @override
  State<_DialogoResponsable> createState() => _DialogoResponsableState();
}

class _DialogoResponsableState extends State<_DialogoResponsable> {
  final _busqueda = TextEditingController();
  bool _porCargo = true;
  CandidatoCierre? _elegido;
  late SeccionCierre _seccion;
  int? _codSucursal;
  bool _propio = false;
  bool _enviando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _elegido = widget.candidato;
    _seccion = widget.seccion ?? widget.secciones.first;
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  bool get _fijo => widget.candidato != null || widget.responsable != null;

  String get _nombreFijo {
    final r = widget.responsable;
    if (r != null) return r.titulo;
    final c = widget.candidato!;
    return '${c.cargo} · ${c.sucursal}';
  }

  Future<void> _guardar() async {
    final r = widget.responsable;
    final c = _elegido;
    if (r == null && c == null) {
      setState(() => _error = 'Elige a quién se le asigna.');
      return;
    }
    // Un responsable que ya está en la matriz es un cargo o una persona: el
    // otro dato va nulo, sin mirar el candidato (que aquí no hay).
    final (cs, emp) =
        r != null
            ? (r.codCargoSucursal, r.codEmpleado)
            : c!.esCargo
            ? (c.codCargoSucursal, null)
            : (null, c.codEmpleado);
    setState(() {
      _enviando = true;
      _error = null;
    });
    final motivo = await widget.notifier.agregar(
      seccion: _seccion.codigo,
      codSucursal: _seccion.porSucursal ? _codSucursal : null,
      codCargoSucursal: cs,
      codEmpleado: emp,
      puedeAutorrevisar: _propio,
    );
    if (!mounted) return;
    if (motivo == null) {
      cerrarRuta(context, true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _enviando = false;
      _error = motivo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _busqueda.text.trim().toLowerCase();
    final opciones =
        widget.candidatos
            .where((c) => c.esCargo == _porCargo)
            .where(
              (c) =>
                  q.isEmpty ||
                  '${c.cargo} ${c.sucursal} ${c.personas ?? ''}'
                      .toLowerCase()
                      .contains(q),
            )
            .take(60)
            .toList();

    return AlertDialog(
      title: Text(
        widget.seccion != null
            ? 'Asignar ${widget.seccion!.nombre.toLowerCase()}'
            : _fijo
            ? 'Asignar una sección'
            : 'Agregar responsable',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_fijo)
                Text(_nombreFijo, style: Theme.of(context).textTheme.titleSmall)
              else ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Un cargo'),
                      icon: Icon(Icons.badge_outlined),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Una persona'),
                      icon: Icon(Icons.person_outline),
                    ),
                  ],
                  selected: {_porCargo},
                  onSelectionChanged:
                      (v) => setState(() {
                        _porCargo = v.first;
                        _elegido = null;
                      }),
                ),
                const SizedBox(height: Esp.xs),
                Text(
                  _porCargo
                      ? 'Lo revisa quien ocupe el cargo, aunque cambie la persona.'
                      : 'Lo revisa esta persona, aunque cambie de cargo.',
                  style: context.apagado(),
                ),
                const SizedBox(height: Esp.s),
                TextField(
                  controller: _busqueda,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar cargo, sucursal o persona',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Esp.xs),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: [
                      for (final c in opciones)
                        RadioListTile<CandidatoCierre>(
                          dense: true,
                          value: c,
                          groupValue: _elegido,
                          onChanged: (v) => setState(() => _elegido = v),
                          title: Text(
                            _porCargo
                                ? '${c.cargo} · ${c.sucursal}'
                                : (c.personas ?? '—'),
                          ),
                          subtitle: Text(
                            _porCargo
                                ? (c.personas ?? 'Vacante')
                                : '${c.cargo} · ${c.sucursal}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Esp.m),
              if (widget.seccion == null) ...[
                Text('Sección', style: context.apagado()),
                const SizedBox(height: Esp.xs),
                Wrap(
                  spacing: Esp.xs,
                  runSpacing: Esp.xs,
                  children: [
                    for (final p in widget.secciones)
                      ChoiceChip(
                        label: Text(p.nombre),
                        selected: _seccion.codigo == p.codigo,
                        onSelected: (_) => setState(() => _seccion = p),
                      ),
                  ],
                ),
                const SizedBox(height: Esp.m),
              ],
              if (_seccion.porSucursal)
                DropdownButtonFormField<int?>(
                  value: _codSucursal,
                  decoration: const InputDecoration(
                    labelText: 'Sucursal',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todas las sucursales'),
                    ),
                    for (final s in widget.sucursales)
                      DropdownMenuItem<int?>(
                        value: s.codSucursal,
                        child: Text(s.nombre),
                      ),
                  ],
                  onChanged: (v) => setState(() => _codSucursal = v),
                )
              else
                Text(
                  'Esta sección es de toda la empresa.',
                  style: context.apagado(),
                ),
              const SizedBox(height: Esp.s),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _propio,
                onChanged: (v) => setState(() => _propio = v),
                title: const Text('Puede revisar su propio trabajo'),
                subtitle: const Text(
                  'Por ejemplo, donde no hay otra persona que lo revise.',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: Esp.xs),
                  child: Text(
                    _error!,
                    style: TextStyle(color: context.cs.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => cerrarRuta(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _guardar,
          child: Text(_enviando ? 'Guardando…' : 'Asignar'),
        ),
      ],
    );
  }
}

/// Las secciones del catálogo (archivo SQL 86): crear una, cambiarla, quitarla
/// desde hoy o volver a pedirla. Lo que se acepta lo decide el servidor.
class _DialogoSecciones extends ConsumerWidget {
  final int idTarRuti;

  const _DialogoSecciones({required this.idTarRuti});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(responsablesCierreProvider(idTarRuti));
    final n = ref.read(responsablesCierreProvider(idTarRuti).notifier);
    final lista = s.secciones.filas;

    return AlertDialog(
      title: const Text('Secciones del cierre'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lo que se revisa en Verificar Cierre. Quitar una deja de '
              'pedirla desde hoy; su historial y sus responsables quedan.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.m),
            if (lista.isEmpty)
              Text(
                'El catálogo está vacío: falta correr el script 86 en la base.',
                style: TextStyle(color: context.cs.error),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder:
                      (_, i) => _FilaSeccionCatalogo(
                        seccion: lista[i],
                        onEditar: () => _formulario(context, n, s, lista[i]),
                        onQuitarOVolver:
                            () => _quitarOVolver(context, n, lista[i]),
                      ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: lista.isEmpty ? null : () => _fuentes(context),
          icon: const Icon(Icons.storage_outlined),
          label: const Text('Fuentes'),
        ),
        TextButton(
          onPressed: () => cerrarRuta(context),
          child: const Text('Cerrar'),
        ),
        FilledButton.tonalIcon(
          onPressed:
              lista.isEmpty ? null : () => _formulario(context, n, s, null),
          icon: const Icon(Icons.add),
          label: const Text('Nueva sección'),
        ),
      ],
    );
  }

  Future<void> _formulario(
    BuildContext context,
    ResponsablesCierreNotifier n,
    ResponsablesCierreState s,
    SeccionCierre? actual,
  ) async {
    HapticFeedback.selectionClick();
    await showDialog<bool>(
      context: context,
      builder:
          (_) => _FormularioSeccion(
            notifier: n,
            actual: actual,
            fuentes: s.fuentes,
          ),
    );
  }

  Future<void> _fuentes(BuildContext context) async {
    HapticFeedback.selectionClick();
    await showDialog<void>(
      context: context,
      builder: (_) => _DialogoFuentes(idTarRuti: idTarRuti),
    );
  }

  Future<void> _quitarOVolver(
    BuildContext context,
    ResponsablesCierreNotifier n,
    SeccionCierre x,
  ) async {
    final quitar = x.vigente;
    final si = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              quitar
                  ? '¿Dejar de pedir ${x.nombre}?'
                  : '¿Volver a pedir ${x.nombre}?',
            ),
            content: Text(
              quitar
                  ? 'Desde hoy nadie la revisa ni la firma. Lo ya firmado y sus '
                      '${x.responsables} responsable(s) quedan guardados por si vuelve.'
                  : 'Desde hoy se vuelve a pedir, con los responsables que tenía.',
            ),
            actions: [
              TextButton(
                onPressed: () => cerrarRuta(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => cerrarRuta(ctx, true),
                child: Text(quitar ? 'Dejar de pedirla' : 'Volver a pedirla'),
              ),
            ],
          ),
    );
    // Null = se cerró sin elegir: no se cambia nada.
    if (si != true) return;
    final motivo = await n.quitarSeccion(x, quitar: quitar);
    if (motivo != null && context.mounted) {
      mostrarAviso(context, motivo, tono: TonoAviso.error);
    }
  }
}

class _FilaSeccionCatalogo extends StatelessWidget {
  final SeccionCierre seccion;
  final VoidCallback onEditar;
  final VoidCallback onQuitarOVolver;

  const _FilaSeccionCatalogo({
    required this.seccion,
    required this.onEditar,
    required this.onQuitarOVolver,
  });

  @override
  Widget build(BuildContext context) {
    final x = seccion;
    final apagada = !x.vigente;
    final datos = [
      x.porSucursal ? 'Por sucursal' : 'Toda la empresa',
      x.propia ? 'Pantalla propia' : 'De: ${x.nombreFuente ?? x.fuente ?? '—'}',
      x.responsables == 1 ? '1 responsable' : '${x.responsables} responsables',
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        x.nombre,
        style: TextStyle(
          color: apagada ? context.cs.onSurfaceVariant : null,
          decoration: apagada ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(apagada ? 'Ya no se pide · $datos' : datos),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Cambiar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEditar,
          ),
          IconButton(
            tooltip: apagada ? 'Volver a pedirla' : 'Dejar de pedirla',
            icon: Icon(apagada ? Icons.undo : Icons.visibility_off_outlined),
            onPressed: onQuitarOVolver,
          ),
        ],
      ),
    );
  }
}

/// Alta o cambio de una sección. En una de pantalla propia solo cambian el
/// nombre, qué revisar y el orden: su lógica está programada.
class _FormularioSeccion extends StatefulWidget {
  final ResponsablesCierreNotifier notifier;
  final SeccionCierre? actual;
  final List<FuenteCierre> fuentes;

  const _FormularioSeccion({
    required this.notifier,
    required this.actual,
    required this.fuentes,
  });

  @override
  State<_FormularioSeccion> createState() => _FormularioSeccionState();
}

class _FormularioSeccionState extends State<_FormularioSeccion> {
  late final _nombre = TextEditingController(text: widget.actual?.nombre ?? '');
  late final _queRevisar = TextEditingController(
    text: widget.actual?.queRevisar ?? '',
  );
  late final _obsDesde = TextEditingController(
    text: '${widget.actual?.obsDesde ?? 1}',
  );
  late final _orden = TextEditingController(
    text: widget.actual == null ? '' : '${widget.actual!.orden}',
  );
  late String? _fuente = widget.actual?.fuente;
  late bool _porSucursal = widget.actual?.porSucursal ?? false;
  late bool _marcaPorFila = widget.actual?.marcaPorFila ?? true;
  late bool _firmaSola = widget.actual?.firmaSola ?? true;
  late String _dia = widget.actual?.diaRevisado ?? 'H';
  bool _enviando = false;
  String? _error;

  bool get _propia => widget.actual?.propia ?? false;

  /// Las fuentes registradas y, si la sección usa una que ya no está, esa.
  List<FuenteCierre> get _opcionesFuente => [
    ...widget.fuentes,
    if (_fuente != null && !widget.fuentes.any((f) => f.fuente == _fuente))
      FuenteCierre(
        fuente: _fuente!,
        nombre: widget.actual?.nombreFuente ?? _fuente!,
        descripcion: 'Ya no está registrada.',
      ),
  ];

  @override
  void dispose() {
    _nombre.dispose();
    _queRevisar.dispose();
    _obsDesde.dispose();
    _orden.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    String? motivo;
    try {
      // Un número vacío viaja nulo: el servidor pone el suyo.
      motivo = await widget.notifier.guardarSeccion(
        codigo: widget.actual?.codigo,
        nombre: _nombre.text.trim(),
        queRevisar: _queRevisar.text.trim(),
        orden: int.tryParse(_orden.text.trim()),
        porSucursal: _propia ? null : _porSucursal,
        fuente: _propia ? null : _fuente,
        marcaPorFila: _propia ? null : _marcaPorFila,
        firmaSola: _propia ? null : _firmaSola,
        obsDesde: _propia ? null : int.tryParse(_obsDesde.text.trim()),
        diaRevisado: _propia ? null : _dia,
      );
    } catch (e) {
      motivo = mensajeError(e);
    }
    if (!mounted) return;
    if (motivo == null) {
      cerrarRuta(context, true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _enviando = false;
      _error = motivo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nueva = widget.actual == null;
    final sinFuentes = !_propia && widget.fuentes.isEmpty && _fuente == null;
    return AlertDialog(
      title: Text(nueva ? 'Nueva sección' : 'Cambiar ${widget.actual!.nombre}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nombre,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.s),
              TextField(
                controller: _queRevisar,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Qué revisar',
                  hintText: 'Lo que lee quien revisa, arriba de la sección.',
                  border: OutlineInputBorder(),
                ),
              ),
              if (!_propia) ...[
                const SizedBox(height: Esp.s),
                if (sinFuentes)
                  Text(
                    'Todavía no hay consultas de otros módulos para usar. '
                    'Regístralas en Secciones > Fuentes.',
                    style: TextStyle(color: context.cs.error),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _fuente,
                    isExpanded: true,
                    // Alto libre: cada opción lleva su descripción debajo.
                    itemHeight: null,
                    decoration: const InputDecoration(
                      labelText: 'De dónde salen las filas',
                      helperText:
                          'Consultas de otros módulos. Se registran en '
                          'Secciones > Fuentes.',
                      helperMaxLines: 2,
                      border: OutlineInputBorder(),
                    ),
                    // Ya elegida, solo el nombre.
                    selectedItemBuilder:
                        (_) => [
                          for (final f in _opcionesFuente)
                            Text(f.nombre, overflow: TextOverflow.ellipsis),
                        ],
                    items: [
                      for (final f in _opcionesFuente)
                        DropdownMenuItem(
                          value: f.fuente,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(f.nombre, overflow: TextOverflow.ellipsis),
                                if (f.descripcion != null)
                                  Text(
                                    f.descripcion!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.apagado(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _fuente = v),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _porSucursal,
                  onChanged: (v) => setState(() => _porSucursal = v),
                  title: const Text('Se revisa por sucursal'),
                  subtitle: const Text(
                    'Si no, una sola vez para toda la empresa.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _marcaPorFila,
                  onChanged: (v) => setState(() => _marcaPorFila = v),
                  title: const Text('Cada fila se marca como revisada'),
                  subtitle: const Text(
                    'Si no, solo se miran y se firma la sección.',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _firmaSola,
                  onChanged: (v) => setState(() => _firmaSola = v),
                  title: const Text('Se firma sola'),
                  subtitle: const Text(
                    'Con la última marca y sin hallazgos, o si no hubo nada '
                    'que revisar.',
                  ),
                ),
                const SizedBox(height: Esp.xs),
                Text('Qué día revisa', style: context.apagado()),
                const SizedBox(height: Esp.xs),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'H', label: Text('El hábil anterior')),
                    ButtonSegment(value: 'M', label: Text('El mismo día')),
                  ],
                  selected: {_dia},
                  onSelectionChanged: (v) => setState(() => _dia = v.first),
                ),
                const SizedBox(height: Esp.m),
                TextField(
                  controller: _obsDesde,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Pide observación desde cuántos hallazgos',
                    helperText: '0 = nunca la pide.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: Esp.m),
              TextField(
                controller: _orden,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Orden',
                  helperText: nueva ? 'Vacío = al final.' : 'Menor va antes.',
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: Esp.s),
                  child: Text(
                    _error!,
                    style: TextStyle(color: context.cs.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => cerrarRuta(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando || sinFuentes ? null : _guardar,
          child: Text(_enviando ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}

/// El registro de fuentes (archivo SQL 87): las consultas de otros módulos que
/// se pueden elegir en una sección. La consulta la escribe sistemas en SQL;
/// aquí se registra, se cambia su nombre, se activa o se borra.
class _DialogoFuentes extends ConsumerStatefulWidget {
  final int idTarRuti;

  const _DialogoFuentes({required this.idTarRuti});

  @override
  ConsumerState<_DialogoFuentes> createState() => _DialogoFuentesState();
}

class _DialogoFuentesState extends ConsumerState<_DialogoFuentes> {
  ResponsablesCierreNotifier get _n =>
      ref.read(responsablesCierreProvider(widget.idTarRuti).notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _n.cargarFuentes());
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(responsablesCierreProvider(widget.idTarRuti));
    final datos = s.fuentesTodas;

    Widget cuerpo;
    if (datos.error != null) {
      cuerpo = Text(
        mensajeError(datos.error),
        style: TextStyle(color: context.cs.error),
      );
    } else if (!datos.cargado) {
      cuerpo = const Padding(
        padding: EdgeInsets.all(Esp.l),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (datos.filas.isEmpty) {
      cuerpo = Text(
        'Todavía no hay fuentes registradas.',
        style: context.apagado(),
      );
    } else {
      cuerpo = Flexible(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: datos.filas.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder:
              (_, i) => _FilaFuente(
                fuente: datos.filas[i],
                onEditar: () => _formulario(context, s, datos.filas[i]),
                onActivar: () => _activar(context, datos.filas[i]),
                onBorrar: () => _borrar(context, datos.filas[i]),
              ),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Fuentes de las secciones'),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Las consultas de otros módulos que se pueden elegir en "De dónde '
              'salen las filas". Sistemas escribe cada consulta en la base '
              '(fn_tac_cierre_...); aquí se registra y se le pone nombre.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.m),
            cuerpo,
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => cerrarRuta(context),
          child: const Text('Cerrar'),
        ),
        FilledButton.tonalIcon(
          onPressed: datos.cargado ? () => _formulario(context, s, null) : null,
          icon: const Icon(Icons.add),
          label: const Text('Registrar fuente'),
        ),
      ],
    );
  }

  Future<void> _formulario(
    BuildContext context,
    ResponsablesCierreState s,
    FuenteCierre? actual,
  ) async {
    HapticFeedback.selectionClick();
    await showDialog<bool>(
      context: context,
      builder:
          (_) => _FormularioFuente(
            notifier: _n,
            actual: actual,
            candidatas: s.candidatasFuente,
          ),
    );
  }

  Future<void> _activar(BuildContext context, FuenteCierre f) async {
    HapticFeedback.selectionClick();
    final motivo = await _n.activarFuente(f, activa: !f.activa);
    if (motivo != null && context.mounted) {
      mostrarAviso(context, motivo, tono: TonoAviso.error);
    }
  }

  Future<void> _borrar(BuildContext context, FuenteCierre f) async {
    final si = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('¿Borrar ${f.nombre} del registro?'),
            content: const Text(
              'Deja de aparecer en la lista. La consulta sigue en la base y se '
              'puede volver a registrar.',
            ),
            actions: [
              TextButton(
                onPressed: () => cerrarRuta(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => cerrarRuta(ctx, true),
                child: const Text('Borrar'),
              ),
            ],
          ),
    );
    // Null = se cerró sin elegir: no se borra.
    if (si != true) return;
    final motivo = await _n.borrarFuente(f);
    if (motivo != null && context.mounted) {
      mostrarAviso(context, motivo, tono: TonoAviso.error);
    }
  }
}

class _FilaFuente extends StatelessWidget {
  final FuenteCierre fuente;
  final VoidCallback onEditar;
  final VoidCallback onActivar;
  final VoidCallback onBorrar;

  const _FilaFuente({
    required this.fuente,
    required this.onEditar,
    required this.onActivar,
    required this.onBorrar,
  });

  @override
  Widget build(BuildContext context) {
    final f = fuente;
    final problema =
        !f.existe
            ? 'Su consulta ya no está en la base'
            : !f.columnasOk
            ? 'Su consulta no devuelve clave y titulo'
            : null;
    final datos = [
      '${f.fuente} (${f.tipo == 'P' ? 'procedimiento' : 'función'})',
      f.usadaPor == null ? 'Sin secciones' : 'La usa: ${f.usadaPor}',
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Flexible(
            child: Text(
              f.nombre,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: f.activa ? null : context.cs.onSurfaceVariant,
              ),
            ),
          ),
          if (!f.activa) ...[
            const SizedBox(width: Esp.s),
            PildoraTareas(
              texto: 'Inactiva',
              fondo: TareasColors.noAplica(context),
              color: TareasColors.noAplicaTexto(context),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (f.descripcion != null) Text(f.descripcion!),
          Text(datos, style: context.apagado()),
          if (problema != null)
            Text(problema, style: TextStyle(color: context.cs.error)),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Cambiar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEditar,
          ),
          IconButton(
            tooltip: f.activa ? 'Desactivar' : 'Activar',
            icon: Icon(
              f.activa ? Icons.toggle_on_outlined : Icons.toggle_off_outlined,
            ),
            onPressed: onActivar,
          ),
          IconButton(
            tooltip:
                f.enUso
                    ? 'La usa una sección: desactívala'
                    : 'Borrar del registro',
            icon: const Icon(Icons.delete_outline),
            onPressed: f.enUso ? null : onBorrar,
          ),
        ],
      ),
    );
  }
}

/// Registrar una fuente (elegir la consulta de la base) o cambiar su nombre,
/// descripción y SP de marca. Las reglas son del servidor.
class _FormularioFuente extends StatefulWidget {
  final ResponsablesCierreNotifier notifier;
  final FuenteCierre? actual;
  final List<CandidatoFuente> candidatas;

  const _FormularioFuente({
    required this.notifier,
    required this.actual,
    required this.candidatas,
  });

  @override
  State<_FormularioFuente> createState() => _FormularioFuenteState();
}

class _FormularioFuenteState extends State<_FormularioFuente> {
  late final _nombre = TextEditingController(text: widget.actual?.nombre ?? '');
  late final _descripcion = TextEditingController(
    text: widget.actual?.descripcion ?? '',
  );
  late final _spMarcar = TextEditingController(
    text: widget.actual?.spMarcar ?? '',
  );
  late String? _fuente = widget.actual?.fuente;
  bool _enviando = false;
  String? _error;

  bool get _alta => widget.actual == null;

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _spMarcar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final fuente = _fuente;
    if (fuente == null) {
      setState(() => _error = 'Elige la consulta de la base.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    String? motivo;
    try {
      motivo = await widget.notifier.guardarFuente(
        fuente: fuente,
        nombre: _nombre.text.trim(),
        descripcion: _descripcion.text.trim(),
        spMarcar: _spMarcar.text.trim(),
        alta: _alta,
      );
    } catch (e) {
      motivo = mensajeError(e);
    }
    if (!mounted) return;
    if (motivo == null) {
      cerrarRuta(context, true);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _enviando = false;
      _error = motivo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sinCandidatas = _alta && widget.candidatas.isEmpty;
    return AlertDialog(
      title: Text(
        _alta ? 'Registrar fuente' : 'Cambiar ${widget.actual!.nombre}',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_alta)
                Text(
                  'Consulta: ${widget.actual!.fuente}',
                  style: Theme.of(context).textTheme.titleSmall,
                )
              else if (sinCandidatas)
                Text(
                  'No hay consultas nuevas en la base. Sistemas tiene que '
                  'crear la función fn_tac_cierre_... del requerimiento '
                  '(plantilla en sql/snippets/plantilla_fuente_cierre.sql).',
                  style: TextStyle(color: context.cs.error),
                )
              else
                DropdownButtonFormField<String>(
                  value: _fuente,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Consulta de la base',
                    helperText:
                        'Las funciones fn_tac_cierre_... que todavía no se '
                        'registraron.',
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final c in widget.candidatas)
                      DropdownMenuItem(
                        value: c.fuente,
                        child: Text(
                          c.columnasOk
                              ? c.fuente
                              : '${c.fuente} (no devuelve clave y titulo)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _fuente = v),
                ),
              const SizedBox(height: Esp.m),
              TextField(
                controller: _nombre,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText:
                      'Como se ve al elegirla, p. ej. "Caja chica sin factura".',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.s),
              TextField(
                controller: _descripcion,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Qué trae',
                  hintText: 'Se ve debajo del nombre en la lista.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Esp.s),
              TextField(
                controller: _spMarcar,
                decoration: const InputDecoration(
                  labelText: 'SP que guarda la marca (opcional)',
                  helperText:
                      'Un p_tac_cierre_... del módulo. Vacío: la marca queda '
                      'en el cierre.',
                  helperMaxLines: 2,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: Esp.s),
                  child: Text(
                    _error!,
                    style: TextStyle(color: context.cs.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => cerrarRuta(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando || sinCandidatas ? null : _guardar,
          child: Text(
            _enviando ? 'Guardando…' : (_alta ? 'Registrar' : 'Guardar'),
          ),
        ),
      ],
    );
  }
}
