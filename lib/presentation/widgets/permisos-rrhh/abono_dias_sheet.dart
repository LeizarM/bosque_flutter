import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/abono_dias_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Acreditar días libres que se cobran igual: una compensación, una
/// regularización. Es el abono **individual**.
///
/// **No es una vacación asignada, aunque las dos sumen al saldo.** Los umbrales
/// son distintos y confundirlos es el error fácil de este módulo: acá los días
/// tienen que ser **mayores a cero** (allá el cero es válido y se usa) y el
/// motivo entra en `varchar(50)`, no en 300 — «Compensación por inventario del
/// 21 de septiembre» ya son 54 caracteres y el SP lo cortaría, o reventaría con
/// «String or binary data would be truncated».
///
/// **La fecha sólo se elige en el alta.** En la edición el modal legacy la deja
/// `disabled` y acá también: mover la fecha de un abono ya cargado lo cambia de
/// año laboral y con eso cambia de tramo en el desglose.
///
/// En diez años hay 184 filas —9 en 2025, ninguna en 2026—: cada alta acá es un
/// hecho raro, y por eso se confirma.
Future<void> mostrarAbonoDiasSheet({
  required BuildContext context,
  required AbonoDiasEntity abono,
  required String datoEmpleado,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => _AbonoDiasSheet(abono: abono, datoEmpleado: datoEmpleado),
);

class _AbonoDiasSheet extends ConsumerStatefulWidget {
  const _AbonoDiasSheet({required this.abono, required this.datoEmpleado});

  final AbonoDiasEntity abono;
  final String datoEmpleado;

  @override
  ConsumerState<_AbonoDiasSheet> createState() => _AbonoDiasSheetState();
}

class _AbonoDiasSheetState extends ConsumerState<_AbonoDiasSheet> {
  late final _dias = TextEditingController(
    text:
        widget.abono.esAlta ? '' : numeroDeDias(widget.abono.diasAbonados),
  );
  late final _motivo = TextEditingController(text: widget.abono.motivo);
  late DateTime? _fecha = widget.abono.fecha;

  bool _guardando = false;

  bool get _esAlta => widget.abono.esAlta;

  @override
  void dispose() {
    _dias.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? hoy,
      // Dos años atrás cubre las regularizaciones que se cargan tarde; un año
      // adelante, lo que se deja programado. Fuera de eso es un error de tipeo.
      firstDate: DateTime(hoy.year - 2),
      lastDate: DateTime(hoy.year + 1, 12, 31),
      helpText: 'Fecha del abono',
    );
    // `use_build_context_synchronously` está apagado en `analysis_options.yaml`:
    // el guardia va a mano.
    if (!mounted || elegida == null) return;
    setState(() => _fecha = elegida);
  }

  @override
  Widget build(BuildContext context) {
    final dias = diasDeTexto(_dias.text);

    return Padding(
      padding: EdgeInsets.only(
        left: Esp.xl,
        right: Esp.xl,
        top: Esp.s,
        bottom: MediaQuery.of(context).viewInsets.bottom + Esp.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _esAlta ? 'Abonar días' : 'Editar el abono',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.datoEmpleado.isNotEmpty)
              Text(widget.datoEmpleado, style: context.apagado()),

            const SizedBox(height: Esp.l),
            CampoElegido(
              etiqueta: 'Fecha del abono',
              texto: _fecha == null ? null : fechaCorta(_fecha),
              onTap: _esAlta ? _elegirFecha : null,
              ayuda:
                  _esAlta
                      ? null
                      : 'No se cambia: movería el abono de año laboral y con '
                          'eso de tramo en el desglose.',
            ),

            const SizedBox(height: Esp.m),
            TextField(
              controller: _dias,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Días abonados',
                border: OutlineInputBorder(),
                isDense: true,
                // El umbral del legacy es estricto, y acá el cero de verdad no
                // existe: el mínimo medido en diez años es medio día.
                helperText: 'Tiene que ser mayor a cero. Se admite medio día.',
              ),
              onChanged: (_) => setState(() {}),
            ),

            if (dias != null && dias > AbonoDiasEntity.diasSospechosos) ...[
              const SizedBox(height: Esp.s),
              AvisoDelDato(
                icono: Icons.warning_amber_rounded,
                texto:
                    'El abono más grande de los últimos diez años es de '
                    '${numeroDeDias(AbonoDiasEntity.diasSospechosos)} días y el '
                    'promedio es 2,6. Se puede guardar igual, pero revise el '
                    'número.',
              ),
            ],

            const SizedBox(height: Esp.m),
            TextField(
              controller: _motivo,
              // El límite de la columna, contado acá: pasarse no da un error de
              // negocio, revienta el SP con un mensaje de motor.
              maxLength: AbonoDiasEntity.motivoMaximo,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
                isDense: true,
                helperText: 'Entran 50 caracteres: el largo de la columna.',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: Esp.m),
            FilledButton.icon(
              onPressed: _guardando ? null : _revisar,
              icon:
                  _guardando
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              // Distinto del botón del diálogo, igual que en la hoja de
              // vacación asignada: uno pregunta, el otro escribe.
              label: Text(_esAlta ? 'Abonar los días' : 'Guardar el cambio'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revisar() async {
    final dias = diasDeTexto(_dias.text);
    if (dias == null) {
      avisarError(context, 'Indique cuántos días se abonan.');
      return;
    }

    final propuesta = widget.abono.copyWith(
      diasAbonados: dias,
      motivo: _motivo.text,
      fecha: _fecha,
    );
    final problema = propuesta.problema;
    if (problema != null) {
      avisarError(context, problema);
      return;
    }

    final quien =
        widget.datoEmpleado.isEmpty ? 'este empleado' : widget.datoEmpleado;
    final cuantos = numeroDeDias(dias);
    final queCambia =
        _esAlta
            ? 'Vas a abonar $cuantos días a $quien con fecha '
                '${fechaCorta(_fecha)}.'
            : 'Vas a dejar el abono del ${fechaCorta(_fecha)} de $quien en '
                '$cuantos días '
                '(antes: ${numeroDeDias(widget.abono.diasAbonados)}).';
    final ok = await confirmar(
      context,
      titulo: _esAlta ? '¿Abonar los días?' : '¿Guardar el cambio?',
      mensaje:
          '$queCambia\n\nMotivo: ${propuesta.motivo.trim()}\n\n'
          'Son días libres que se cobran igual: suman al saldo de esa persona.',
      accion: _esAlta ? 'Abonar' : 'Guardar',
    );
    if (!ok || !mounted) return;
    await _guardar(propuesta);
  }

  /// Escribe. [confirmado] sólo en el reintento, después del 400 confirmable.
  Future<void> _guardar(AbonoDiasEntity a, {bool confirmado = false}) async {
    setState(() => _guardando = true);
    try {
      // La fila releída, igual que en la vacación asignada: lo que se avisa es
      // lo que quedó guardado.
      final guardado = await ref
          .read(permisosRrhhAccionesProvider)
          .registrarAbonoDias(a, confirmado: confirmado);
      if (!mounted) return;
      Navigator.of(context).pop();
      final dias =
          guardado.diasAbonadosTxt.isEmpty
              ? '${numeroDeDias(guardado.diasAbonados)} días'
              : guardado.diasAbonadosTxt;
      avisar(
        context,
        _esAlta
            ? 'Quedaron $dias abonados con fecha ${fechaCorta(guardado.fecha)}.'
            : 'El abono del ${fechaCorta(guardado.fecha)} quedó en $dias.',
      );
    } on RequiereConfirmacion catch (d) {
      // **Lo inusual se pregunta; el doble toque no.** Acá el backend contesta
      // 400 con `confirmable` por un monto fuera del rango histórico o por otro
      // abono del mismo día con distinto monto —los dos son legítimos y pasan—,
      // y 409 seco por una fila idéntica cargada hace segundos, que es un doble
      // toque. Sin esta rama, «Confirme si es correcto» era un callejón: el
      // mensaje pedía confirmar y no había con qué.
      if (!mounted) return;
      setState(() => _guardando = false);
      final igual = await confirmar(
        context,
        titulo: 'Revise antes de guardar',
        mensaje:
            '${d.mensaje}\n\nSi lo carga igual, esos días suman al saldo de '
            'esa persona.',
        accion: 'Guardar igual',
        destructiva: true,
      );
      if (igual && mounted) await _guardar(a, confirmado: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      // Un 409 significa que alguien más escribió: la lista que se está viendo
      // puede estar vieja, así que se relee y no se ofrece reintento.
      ref.read(permisosRrhhAccionesProvider).refrescar(a.codEmpleado);
      avisarError(context, e);
    }
  }
}
