import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Declara el evento de un sábado y arma su lista nominal.
///
/// El orden importa y por eso la pantalla lo impone: **primero se declara el
/// evento, y recién después se convoca**. Convocar a alguien para un sábado sin
/// evento rebota en el backend, porque las ausencias de un sábado normal van por
/// otro camino (las programa un jefe).
///
/// Los dos alcances resuelven casos distintos:
/// - `TOTAL` — vienen todos, sin importar la rotación. Cierre de mes.
/// - `SELECTIVA` — no viene nadie por rotación; sólo los que se convoquen. Es el
///   inventario: van cinco personas elegidas y el resto se queda en casa.
class EventoSheet extends ConsumerStatefulWidget {
  const EventoSheet({
    super.key,
    required this.idRol,
    required this.sabado,
    required this.participantes,
  });

  final int idRol;
  final SabadoEntity sabado;
  final List<ParticipanteTurnoEntity> participantes;

  @override
  ConsumerState<EventoSheet> createState() => _EventoSheetState();
}

class _EventoSheetState extends ConsumerState<EventoSheet> {
  late String? _alcance;
  late final TextEditingController _motivo;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _alcance = widget.sabado.alcanceEvento;
    _motivo = TextEditingController(text: widget.sabado.motivoEspecial);
  }

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sabado;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder:
          (_, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Sábado ${fechaCorta(s.fecha)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Por rotación viene el grupo ${s.grupoQueRota}'
                '${s.esFeriadoBool ? ' · marcado como FERIADO' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: Esp.l),

              Text(
                'Tipo de jornada',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: Esp.s),
              _SelectorAlcance(
                valor: _alcance,
                onChanged: (v) => setState(() => _alcance = v),
              ),
              const SizedBox(height: Esp.s),
              Text(
                _explicacion(),
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: Esp.l),
              TextField(
                controller: _motivo,
                maxLength: 150,
                enabled: _alcance != null,
                decoration: const InputDecoration(
                  labelText: 'Motivo del evento',
                  hintText: 'Inventario de almacén, cierre de mes…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardarEvento,
                  icon:
                      _guardando
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.event_available),
                  label: Text(
                    _alcance == null
                        ? 'Volver a sábado normal'
                        : 'Guardar y rehacer las celdas del día',
                  ),
                ),
              ),

              const SizedBox(height: Esp.s),
              Text(
                'Guardar rehace las celdas de este sábado. Las correcciones '
                'manuales y lo que programó un jefe no se pierden.',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              if (s.tieneEvento) ...[
                const Divider(height: 32),
                _Convocatoria(
                  idRol: widget.idRol,
                  sabado: s,
                  participantes: widget.participantes,
                ),
              ] else ...[
                const Divider(height: 32),
                Text(
                  'Para convocar gente hay que declarar el evento primero: sin '
                  'evento, las ausencias de un sábado las programa el jefe del '
                  'área, no la convocatoria.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
    );
  }

  String _explicacion() => switch (_alcance) {
    'TOTAL' =>
      'Vienen TODOS, sin importar la rotación. El asueto de cumpleaños queda '
          'anulado ese día.',
    'SELECTIVA' =>
      'No viene NADIE por rotación. Sólo los que se convoquen abajo, uno por uno '
          'o por área.',
    _ => 'Sábado normal: viene el grupo que le toca por rotación.',
  };

  Future<void> _guardarEvento() async {
    setState(() => _guardando = true);
    await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .marcarEvento(
            idRol: widget.idRol,
            idSabado: widget.sabado.idSabado,
            alcanceEvento: _alcance,
            motivoEspecial: _motivo.text.trim(),
          ),
      exito:
          _alcance == null
              ? 'El sábado volvió a la rotación normal.'
              : 'Evento declarado y celdas rehechas.',
      cerrar: true,
    );
    if (mounted) setState(() => _guardando = false);
  }
}

class _SelectorAlcance extends StatelessWidget {
  const _SelectorAlcance({required this.valor, required this.onChanged});

  final String? valor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      ChoiceChip(
        label: const Text('Normal'),
        selected: valor == null,
        onSelected: (_) => onChanged(null),
      ),
      ChoiceChip(
        label: const Text('TOTAL'),
        selected: valor == 'TOTAL',
        onSelected: (_) => onChanged('TOTAL'),
      ),
      ChoiceChip(
        label: const Text('SELECTIVA'),
        selected: valor == 'SELECTIVA',
        onSelected: (_) => onChanged('SELECTIVA'),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTA NOMINAL
// ═══════════════════════════════════════════════════════════════════════════

class _Convocatoria extends ConsumerStatefulWidget {
  const _Convocatoria({
    required this.idRol,
    required this.sabado,
    required this.participantes,
  });

  final int idRol;
  final SabadoEntity sabado;
  final List<ParticipanteTurnoEntity> participantes;

  @override
  ConsumerState<_Convocatoria> createState() => _ConvocatoriaState();
}

class _ConvocatoriaState extends ConsumerState<_Convocatoria> {
  int? _empleado;
  String _tipo = 'CONVOCADO';
  final _motivo = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detalle = ref.watch(detalleEventoProvider(widget.sabado.idSabado));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lista nominal', style: Theme.of(context).textTheme.titleSmall),
        Text(
          'CONVOCADO viene aunque no le toque. EXCUSADO no viene aunque le '
          'toque, y su celda queda en "E" para que se vea que fue decidido.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: Esp.l),

        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'CONVOCADO', label: Text('Convocar')),
            ButtonSegment(value: 'EXCUSADO', label: Text('Excusar')),
          ],
          selected: {_tipo},
          onSelectionChanged: (v) => setState(() => _tipo = v.first),
        ),
        const SizedBox(height: Esp.m),

        ComboBuscable<int>(
          etiqueta: 'Persona',
          valor: _empleado,
          ayuda: '${widget.participantes.length} en el rol',
          opciones: entradasDePersonas(widget.participantes),
          onElegir: (v) => setState(() => _empleado = v),
        ),
        const SizedBox(height: Esp.m),

        TextField(
          controller: _motivo,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (_empleado == null || _enviando) ? null : _enviar,
            icon:
                _enviando
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.person_add_alt),
            label: Text(
              _tipo == 'CONVOCADO' ? 'Agregar a la lista' : 'Excusar',
            ),
          ),
        ),

        const SizedBox(height: Esp.l),
        detalle.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
          error:
              (e, _) => Text(
                textoParaUsuario(e),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          data: (lista) {
            if (lista.isEmpty) {
              return Text(
                widget.sabado.alcanceEvento == 'SELECTIVA'
                    ? 'Todavía no hay nadie convocado: con SELECTIVA y la lista '
                        'vacía, ese sábado no viene nadie.'
                    : 'Sin excepciones cargadas: viene todo el personal.',
                style: Theme.of(context).textTheme.bodySmall,
              );
            }
            return Column(
              children: [
                for (final c in lista)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      c.tipo == 'CONVOCADO'
                          ? Icons.person_add_alt
                          : Icons.person_off_outlined,
                      size: 18,
                    ),
                    title: Text(c.nombreRol),
                    subtitle: Text(
                      c.situacion.isEmpty
                          ? '${c.tipo} · queda en "${c.celdaFinal}"'
                          : c.situacion,
                    ),
                    // Un CONVOCADO que ya venía por rotación no agrega a nadie:
                    // vale marcarlo para que no parezca que hizo algo.
                    trailing:
                        c.redundante
                            ? const Etiqueta(
                              texto: 'ya venía',
                              tono: TonoEtiqueta.neutro,
                            )
                            : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final ok = await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .convocar(
            idRol: widget.idRol,
            idSabado: widget.sabado.idSabado,
            tipo: _tipo,
            codEmpleado: _empleado!,
            motivo: _motivo.text.trim(),
          ),
      exito: _tipo == 'CONVOCADO' ? 'Convocado.' : 'Excusado.',
    );
    if (!mounted) return;
    setState(() {
      _enviando = false;
      if (ok) {
        _empleado = null;
        _motivo.clear();
      }
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GENERAR / REGENERAR
// ═══════════════════════════════════════════════════════════════════════════

/// Genera un rol nuevo o reconcilia uno existente.
///
/// La diferencia entre los dos modos es la que más confunde, así que está
/// escrita en la pantalla: `REGENERAR` **no borra el trabajo de nadie** —
/// rehace sólo las celdas que puso la rotación.
class GenerarRolDialog extends ConsumerStatefulWidget {
  const GenerarRolDialog({super.key, this.idRolExistente, this.anioExistente});

  final int? idRolExistente;
  final int? anioExistente;

  @override
  ConsumerState<GenerarRolDialog> createState() => _GenerarRolDialogState();
}

class _GenerarRolDialogState extends ConsumerState<GenerarRolDialog> {
  late final TextEditingController _anio;
  late String _modo;
  bool _trabajando = false;

  @override
  void initState() {
    super.initState();
    _modo = widget.idRolExistente != null ? 'REGENERAR' : 'CREAR';
    _anio = TextEditingController(
      text: (widget.anioExistente ?? DateTime.now().year).toString(),
    );
  }

  @override
  void dispose() {
    _anio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Generar rol'),
    // Scrollable: en un teléfono de 740 px de alto, con el teclado abierto para
    // escribir el año, la explicación de los dos modos no entra. Un AlertDialog
    // no scrollea solo.
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'CREAR', label: Text('Crear')),
              ButtonSegment(value: 'REGENERAR', label: Text('Regenerar')),
            ],
            selected: {_modo},
            onSelectionChanged: (v) => setState(() => _modo = v.first),
          ),
          const SizedBox(height: Esp.m),
          Text(
            _modo == 'CREAR'
                ? 'Arma el rol desde cero: la cabecera, los ~52 sábados y todos '
                    'los participantes con su grupo A/B. Falla si el año ya existe.'
                : 'Reconcilia contra el organigrama de hoy: agrega a los que '
                    'entraron, da de baja a los que salieron y rehace SÓLO las '
                    'celdas que puso la rotación. Las correcciones manuales y lo '
                    'que programó un jefe se conservan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Esp.l),
          TextField(
            controller: _anio,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Año',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: Esp.s),
          Text(
            'Se genera para toda la empresa. El feriado departamental igual '
            'sale bien: se resuelve por persona, según su sucursal.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _trabajando ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _trabajando ? null : _generar,
        child:
            _trabajando
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Text(_modo == 'CREAR' ? 'Crear' : 'Regenerar'),
      ),
    ],
  );

  Future<void> _generar() async {
    final anio = int.tryParse(_anio.text.trim()) ?? 0;
    if (anio < 2000 || anio > 2100) {
      avisar(context, 'Año fuera de rango: $anio.', esError: true);
      return;
    }

    setState(() => _trabajando = true);
    try {
      final id = await ref
          .read(rolSabadosAccionesProvider)
          .generarRol(anio: anio, modo: _modo);
      if (!mounted) return;
      // Dejar seleccionado el rol recién generado ahorra un paso: es lo que la
      // persona quiere mirar justo después.
      if (id > 0) ref.read(rolSeleccionadoProvider.notifier).state = id;
      Navigator.pop(context);
      avisar(context, _modo == 'CREAR' ? 'Rol generado.' : 'Rol regenerado.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _trabajando = false);
      avisar(context, '$e', esError: true);
    }
  }
}
