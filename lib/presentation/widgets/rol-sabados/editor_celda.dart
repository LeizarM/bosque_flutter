import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/participante_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre el editor de una celda.
///
/// Vive suelto y no dentro de la matriz porque las dos vistas —la matriz del
/// escritorio y la agenda del teléfono— editan exactamente lo mismo. Si cada una
/// tuviera su propio editor, tarde o temprano una arreglaría un caso que la otra
/// no.
Future<void> mostrarEditorDeCelda({
  required BuildContext context,
  required GrillaRol grilla,
  required ParticipanteTurnoEntity participante,
  required SabadoEntity sabado,
  required CeldaTurnoEntity? celda,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder:
      (_) => EditorDeCelda(
        grilla: grilla,
        idRol: grilla.rol.idRol,
        participante: participante,
        sabado: sabado,
        celda: celda,
      ),
);

class EditorDeCelda extends ConsumerStatefulWidget {
  const EditorDeCelda({
    super.key,
    required this.grilla,
    required this.idRol,
    required this.participante,
    required this.sabado,
    required this.celda,
  });

  final GrillaRol grilla;
  final int idRol;
  final ParticipanteTurnoEntity participante;
  final SabadoEntity sabado;
  final CeldaTurnoEntity? celda;

  @override
  ConsumerState<EditorDeCelda> createState() => EditorDeCeldaState();
}

class EditorDeCeldaState extends ConsumerState<EditorDeCelda> {
  final _observacion = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _observacion.text = widget.celda?.observacion ?? '';
  }

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = widget.sabado.fecha;
    final fecha =
        f == null
            ? ''
            : '${f.day.toString().padLeft(2, '0')}/'
                '${f.month.toString().padLeft(2, '0')}/${f.year}';

    // 'L' no es un estado: liberar BORRA la fila, y por eso va en su propio botón.
    final letras =
        widget.grilla.estados.values
            .where((e) => e.estado == 'A' && e.codigoExcel != 'L')
            .toList()
          ..sort((a, b) => a.codigoExcel.compareTo(b.codigoExcel));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.participante.nombreRol,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Sábado $fecha · grupo ${widget.participante.grupoRotacion}',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          // Va arriba, pegado al nombre, y no abajo con el origen: es la
          // respuesta a «¿por qué esta celda dice lo que dice?», así que se
          // lee ANTES de tocar los chips y no después. El motivo del cambio ya
          // está en el campo Motivo —`trs_sp_corregirCelda` lo copia—, así que
          // acá va sólo lo que faltaba: con quién.
          if (widget.celda?.hayCambio == true) ...[
            const SizedBox(height: Esp.s),
            Row(
              children: [
                Icon(Icons.swap_horiz, size: 18, color: cs.tertiary),
                const SizedBox(width: Esp.xs),
                Expanded(
                  child: Text(
                    widget.celda!.cambioTexto,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: Esp.l),

          Text(
            'Estado de la celda',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: Esp.s),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in letras)
                ChoiceChip(
                  label: Text('${e.codigoExcel} · ${e.nombre}'),
                  selected: widget.celda?.codigoExcel == e.codigoExcel,
                  onSelected:
                      _guardando ? null : (_) => _guardar(e.codigoExcel),
                ),
            ],
          ),

          const SizedBox(height: Esp.l),
          TextField(
            controller: _observacion,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              helperText:
                  'Queda registrado en la celda y en el control de '
                  'intervenciones.',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),

          const SizedBox(height: Esp.s),
          Text(
            widget.celda == null
                ? 'Hoy está LIBRE: no hay celda guardada para este cruce.'
                : 'Origen ${widget.celda!.origen}'
                    '${widget.celda!.esIntervencion ? ' — la escribió una persona y sobrevive a una regeneración.' : ' — la puso la rotación; una regeneración la rehace.'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: Esp.m),
          Row(
            children: [
              if (widget.celda != null)
                TextButton.icon(
                  onPressed: _guardando ? null : _liberar,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Dejar libre'),
                ),
              const Spacer(),
              if (_guardando)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _guardar(String codigoExcel) async {
    await _ejecutar(
      () => ref
          .read(rolSabadosAccionesProvider)
          .corregirCelda(
            idRol: widget.idRol,
            idParticipante: widget.participante.idParticipante,
            idSabado: widget.sabado.idSabado,
            codigoExcel: codigoExcel,
            observacion: _observacion.text.trim(),
          ),
      'Celda actualizada.',
    );
  }

  Future<void> _liberar() async {
    await _ejecutar(
      () => ref
          .read(rolSabadosAccionesProvider)
          .liberarCelda(
            idRol: widget.idRol,
            idParticipante: widget.participante.idParticipante,
            idSabado: widget.sabado.idSabado,
          ),
      'Quedó libre.',
    );
  }

  /// Guarda, cierra la hoja y avisa.
  ///
  /// **Antes esto tenía su propio `try/catch` con dos `ScaffoldMessenger`**, o
  /// sea que el módulo avisaba de dos maneras distintas: por acá y por
  /// [ejecutarAccion]. Cuando los avisos pasaron a dibujarse por encima de los
  /// diálogos, estos dos se habrían quedado abajo —justo los que salen desde una
  /// hoja modal, que es donde peor se ve—. Un solo camino para avisar es lo que
  /// hace que un arreglo así alcance a todo el módulo de una vez.
  ///
  /// Lo único que queda propio es el `_guardando`: se apaga sólo si la cosa
  /// falló, porque si salió bien la hoja ya se cerró.
  Future<void> _ejecutar(Future<void> Function() accion, String exito) async {
    setState(() => _guardando = true);
    final ok = await ejecutarAccion(
      context,
      accion,
      exito: exito,
      cerrar: true,
    );
    if (!ok && mounted) setState(() => _guardando = false);
  }
}
