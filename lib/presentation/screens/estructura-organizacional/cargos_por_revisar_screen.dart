// Destino final: lib/presentation/screens/estructura-organizacional/cargos_por_revisar_screen.dart
import 'package:bosque_flutter/core/state/senales_cargo_provider.dart';
import 'package:bosque_flutter/core/ui/mensaje_error_tareas.dart';
import 'package:bosque_flutter/core/theme/tareas_colors.dart';
import 'package:bosque_flutter/core/theme/tareas_tema.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/cerrar_ruta.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formatear_fecha.dart';
import 'package:bosque_flutter/domain/entities/senal_cargo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tareas-rutinarias/pagina_tareas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cargos por revisar (archivo SQL 82): quién no hizo ninguna de sus últimas
/// ocurrencias de una tarea. Puede que le cambiaran las funciones y RRHH no
/// actualizara su cargo. Con [deMiEquipo], solo el equipo de quien mira.
class CargosPorRevisarScreen extends ConsumerStatefulWidget {
  final bool deMiEquipo;

  const CargosPorRevisarScreen({super.key, this.deMiEquipo = false});

  @override
  ConsumerState<CargosPorRevisarScreen> createState() =>
      _CargosPorRevisarScreenState();
}

class _CargosPorRevisarScreenState
    extends ConsumerState<CargosPorRevisarScreen> {
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = senalesCargoProvider(widget.deMiEquipo);
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

    final personas = s.porPersona;
    return TareasScope(
      child: Scaffold(
        appBar: AppBarTareas(
          titulo:
              widget.deMiEquipo
                  ? 'Tareas que tu equipo no hace'
                  : 'Cargos por revisar',
          subtitulo:
              s.senales.cargado && s.personas > 0
                  ? '${s.personas == 1 ? '1 persona' : '${s.personas} personas'}'
                      ' · ${s.tareas == 1 ? '1 tarea' : '${s.tareas} tareas'} sin hacer'
                  : null,
          insignia: InsigniaTarea.modulo(context, Icons.manage_search),
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
                children: [
                  Text(
                    'Aquí aparece quien no hizo ninguna de sus últimas '
                    '${s.ocurrencias ?? 'N'} ocurrencias de una tarea. Puede '
                    'que le hayan cambiado las funciones y su cargo no esté al '
                    'día. Si es correcto así, márcalo con "Está bien así".',
                    style: context.apagado(),
                  ),
                  const SizedBox(height: Esp.m),
                  Wrap(
                    spacing: Esp.m,
                    runSpacing: Esp.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: TextField(
                          controller: _busqueda,
                          onChanged: n.buscar,
                          decoration: InputDecoration(
                            isDense: true,
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Buscar persona, cargo o sucursal',
                            border: const OutlineInputBorder(),
                            suffixIcon:
                                s.busqueda.isEmpty
                                    ? null
                                    : IconButton(
                                      tooltip: 'Limpiar búsqueda',
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        _busqueda.clear();
                                        n.buscar('');
                                      },
                                    ),
                          ),
                        ),
                      ),
                      if (!widget.deMiEquipo)
                        FilterChip(
                          label: const Text('Ver también "Está bien así"'),
                          selected: s.verCalladas,
                          onSelected: n.cambiarVerCalladas,
                        ),
                    ],
                  ),
                  const SizedBox(height: Esp.l),
                  ..._cuerpo(context, s, n, personas),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Un solo estado: error, leyendo, vacío, sin coincidencias o la lista.
  List<Widget> _cuerpo(
    BuildContext context,
    SenalesCargoState s,
    SenalesCargoNotifier n,
    List<PersonaConSenales> personas,
  ) {
    if (s.senales.error != null) {
      return [
        EstadoTareas.error(
          titulo: 'No se pudo leer la lista',
          detalle: mensajeError(s.senales.error),
          onReintentar: n.cargar,
        ),
      ];
    }
    if (!s.senales.cargado) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: Esp.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (s.senales.filas.isEmpty) {
      return [
        EstadoTareas(
          icono: Icons.task_alt,
          titulo:
              widget.deMiEquipo
                  ? 'Tu equipo hace sus tareas'
                  : 'Nadie dejó de hacer sus tareas',
          detalle:
              'Si alguien deja de hacer todas las ocurrencias seguidas de una '
              'tarea, aparece aquí.',
          tono: TonoEstadoTareas.listo,
        ),
      ];
    }
    if (personas.isEmpty) {
      return [
        EstadoTareas(
          icono: Icons.search_off,
          titulo: 'Nada coincide con "${s.busqueda.trim()}"',
          accion: TextButton(
            onPressed: () {
              _busqueda.clear();
              n.buscar('');
            },
            child: const Text('Limpiar búsqueda'),
          ),
        ),
      ];
    }
    return [
      for (final p in personas)
        Padding(
          padding: const EdgeInsets.only(bottom: Esp.m),
          child: _TarjetaPersona(
            persona: p,
            guardando: (x) => s.guardando.contains(x.clave),
            onEstaBien: (x) => _estaBien(context, n, x),
            onVolverAMostrar: (x) => _volverAMostrar(n, x),
          ),
        ),
    ];
  }

  Future<void> _estaBien(
    BuildContext context,
    SenalesCargoNotifier n,
    SenalCargo senal,
  ) async {
    HapticFeedback.selectionClick();
    // Null = se cerró sin guardar: no pasa nada.
    await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoEstaBien(senal: senal, notifier: n),
    );
  }

  Future<void> _volverAMostrar(SenalesCargoNotifier n, SenalCargo senal) async {
    HapticFeedback.selectionClick();
    final motivo = await n.volverAMostrar(senal);
    if (motivo != null && mounted) {
      mostrarAviso(context, motivo, tono: TonoAviso.error);
    }
  }
}

class _TarjetaPersona extends StatelessWidget {
  final PersonaConSenales persona;
  final bool Function(SenalCargo) guardando;
  final void Function(SenalCargo) onEstaBien;
  final void Function(SenalCargo) onVolverAMostrar;

  const _TarjetaPersona({
    required this.persona,
    required this.guardando,
    required this.onEstaBien,
    required this.onVolverAMostrar,
  });

  @override
  Widget build(BuildContext context) {
    final p = persona.primera;
    final todas = persona.ninguna;
    final fondo =
        todas ? TareasColors.vencido(context) : TareasColors.pendiente(context);
    final tono =
        todas
            ? TareasColors.vencidoTexto(context)
            : TareasColors.pendienteTexto(context);
    final datos = [
      if (p.cargo != null) p.cargo!,
      if (p.cargoDesde != null)
        'desde el ${FormatearFecha.formatearFecha(p.cargoDesde!)}',
      if (p.nombreSucursal != null) p.nombreSucursal!,
    ].join(' · ');
    final linea = context.cs.outlineVariant.withValues(alpha: 0.6);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Esquina.media),
        border: Border.all(color: linea),
      ),
      child: Theme(
        // Sin las líneas que ExpansionTile dibuja al abrirse.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(),
          collapsedShape: const RoundedRectangleBorder(),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: Esp.m,
            vertical: Esp.xs,
          ),
          childrenPadding: EdgeInsets.zero,
          leading: Icon(
            todas ? Icons.person_off_outlined : Icons.person_outline,
            color: tono,
          ),
          title: Text(
            persona.persona,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (datos.isNotEmpty) Text(datos, style: context.apagado()),
              const SizedBox(height: Esp.xs),
              PildoraTareas(
                texto:
                    todas
                        ? 'No hace ninguna de sus ${persona.deSusTareas} tareas'
                        : 'No hace ${persona.sinHacer} de sus ${persona.deSusTareas} tareas',
                fondo: fondo,
                color: tono,
              ),
            ],
          ),
          children: [
            for (final s in persona.senales) ...[
              Divider(height: 1, color: linea),
              _FilaSenal(
                senal: s,
                guardando: guardando(s),
                onEstaBien: () => onEstaBien(s),
                onVolverAMostrar: () => onVolverAMostrar(s),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaSenal extends StatelessWidget {
  final SenalCargo senal;
  final bool guardando;
  final VoidCallback onEstaBien;
  final VoidCallback onVolverAMostrar;

  const _FilaSenal({
    required this.senal,
    required this.guardando,
    required this.onEstaBien,
    required this.onVolverAMostrar,
  });

  @override
  Widget build(BuildContext context) {
    final s = senal;
    final desde =
        s.desde == null
            ? ''
            : ' desde el ${FormatearFecha.formatearFecha(s.desde!)}';
    final textos = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: s.tarea,
          waitDuration: const Duration(milliseconds: 500),
          child: Text(
            s.tarea,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          s.motivo,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: TareasColors.pendienteTexto(context),
          ),
        ),
        Text(
          'Las últimas ${s.ocurrencias}, sin hacer$desde.',
          style: context.apagado(),
        ),
        if (s.callada)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Marcada "Está bien así"'
              '${s.calladaPor == null || s.calladaPor!.isEmpty ? '' : ' por ${s.calladaPor}'}'
              '${s.calladaHasta == null ? '' : ' hasta el ${FormatearFecha.formatearFecha(s.calladaHasta!)}'}'
              '${s.obsCallada == null ? '' : ': ${s.obsCallada}'}',
              style: context.apagado()?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );

    final Widget boton =
        guardando
            ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : s.callada
            ? TextButton(
              onPressed: onVolverAMostrar,
              child: const Text('Volver a mostrar'),
            )
            : OutlinedButton.icon(
              onPressed: onEstaBien,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Está bien así'),
            );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.m, Esp.m),
      child: LayoutBuilder(
        builder:
            (context, cajon) =>
                cajon.maxWidth < 520
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textos,
                        const SizedBox(height: Esp.s),
                        Align(alignment: Alignment.centerRight, child: boton),
                      ],
                    )
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: textos),
                        const SizedBox(width: Esp.m),
                        boton,
                      ],
                    ),
      ),
    );
  }
}

/// "Está bien así": la explicación es opcional; el servidor dice hasta cuándo
/// deja de mostrarse y, si no acepta, su mensaje sale aquí mismo.
class _DialogoEstaBien extends StatefulWidget {
  final SenalCargo senal;
  final SenalesCargoNotifier notifier;

  const _DialogoEstaBien({required this.senal, required this.notifier});

  @override
  State<_DialogoEstaBien> createState() => _DialogoEstaBienState();
}

class _DialogoEstaBienState extends State<_DialogoEstaBien> {
  final _obs = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() {
      _enviando = true;
      _error = null;
    });
    final motivo = await widget.notifier.estaBien(widget.senal, obs: _obs.text);
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
    final s = widget.senal;
    return AlertDialog(
      title: const Text('¿Está bien así?'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.persona} no hace "${s.tarea}". Si es correcto (por '
              'ejemplo, otra persona la cubre), deja de mostrarse por unos '
              'días.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.m),
            TextField(
              controller: _obs,
              autofocus: true,
              enabled: !_enviando,
              minLines: 2,
              maxLines: 3,
              // 300 es el largo de la columna; las reglas son del servidor.
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Por qué (opcional)',
                border: const OutlineInputBorder(),
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => cerrarRuta(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _guardar,
          child: Text(_enviando ? 'Guardando…' : 'Está bien así'),
        ),
      ],
    );
  }
}
