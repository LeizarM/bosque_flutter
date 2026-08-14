import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/vacacion_asignada_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cargar o corregir **los días que la empresa le debe** a alguien por un año
/// cumplido de antigüedad.
///
/// **Una sola hoja para el alta y para la edición**, al revés que el legacy, que
/// tiene el mismo formulario duplicado en dos modales (`formVAM` y `formVAMB`)
/// con distinto `update` y distinto callback. Cuál de las dos operaciones es lo
/// decide el id, igual que allá: `codVacacionAsignada == 0` es un aniversario
/// sin registro y por lo tanto un alta.
///
/// **La fecha no se tipea nunca.** Es el aniversario que armó
/// `p_list_vacacionAsignada 'B'` recorriendo la relación laboral año por año; en
/// el modal viejo el campo va `disabled="true"` y acá también. Un alta con otra
/// fecha sería una asignación que ningún tramo del desglose va a encontrar.
///
/// **Y el empleado y la relación laboral tampoco se tocan**: el `UPDATE` del SP
/// no los actualiza —`codEmpleado` ni siquiera está en el `SET` y
/// `codRelEmplEmpr` está comentado a propósito—, así que ofrecerlos sería
/// ofrecer un cambio que el servidor va a ignorar en silencio.
Future<void> mostrarVacacionAsignadaSheet({
  required BuildContext context,
  required VacacionAsignadaEntity vacacion,
  required String datoEmpleado,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder:
      (_) =>
          _VacacionAsignadaSheet(vacacion: vacacion, datoEmpleado: datoEmpleado),
);

class _VacacionAsignadaSheet extends ConsumerStatefulWidget {
  const _VacacionAsignadaSheet({
    required this.vacacion,
    required this.datoEmpleado,
  });

  final VacacionAsignadaEntity vacacion;
  final String datoEmpleado;

  @override
  ConsumerState<_VacacionAsignadaSheet> createState() =>
      _VacacionAsignadaSheetState();
}

class _VacacionAsignadaSheetState
    extends ConsumerState<_VacacionAsignadaSheet> {
  late final _dias = TextEditingController(
    // En el alta arranca vacío y no en «0»: cero es un valor válido —446 filas
    // lo tienen, significa «este año no le corresponde nada»— así que dejarlo
    // puesto invitaría a guardarlo sin querer.
    text:
        widget.vacacion.esSintetica
            ? ''
            : numeroDeDias(widget.vacacion.diasAsignados),
  );
  late final _motivo = TextEditingController(text: widget.vacacion.motivo);

  bool _guardando = false;

  bool get _esAlta => widget.vacacion.esSintetica;

  @override
  void dispose() {
    _dias.dispose();
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vacacion;
    final dias = diasDeTexto(_dias.text);

    return Padding(
      padding: EdgeInsets.only(
        left: Esp.xl,
        right: Esp.xl,
        top: Esp.s,
        // El teclado tapa el botón de guardar en cuanto se toca un campo.
        bottom: MediaQuery.of(context).viewInsets.bottom + Esp.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _esAlta ? 'Asignar vacación' : 'Editar vacación asignada',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              widget.datoEmpleado.isEmpty
                  ? 'Aniversario del ${fechaCorta(v.fecha)}'
                  : '${widget.datoEmpleado} · aniversario del '
                      '${fechaCorta(v.fecha)}',
              style: context.apagado(),
            ),

            const SizedBox(height: Esp.l),
            CampoElegido(
              etiqueta: 'Fecha',
              texto: fechaCorta(v.fecha),
              // Bloqueada siempre, en el alta y en la edición.
              onTap: null,
              ayuda:
                  'La pone el sistema: es el aniversario de la relación '
                  'laboral, no una fecha a elegir.',
            ),

            const SizedBox(height: Esp.m),
            TextField(
              controller: _dias,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              // Sólo dígitos y un separador decimal. El teclado de Android
              // ofrece punto y coma según el idioma del teléfono, así que se
              // aceptan los dos y `diasDeTexto` los normaliza.
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Días asignados',
                border: OutlineInputBorder(),
                isDense: true,
                helperText: 'Cero es válido: significa que ese año no le toca.',
              ),
              // Redibuja para que el aviso de días fuera de rango y el estado
              // del botón sigan a lo que se está tipeando.
              onChanged: (_) => setState(() {}),
            ),

            if (dias != null && dias > VacacionAsignadaEntity.diasSospechosos)
              ...[
                const SizedBox(height: Esp.s),
                AvisoDelDato(
                  icono: Icons.warning_amber_rounded,
                  texto:
                      'En diez años no hay ninguna asignación de más de '
                      '${numeroDeDias(VacacionAsignadaEntity.diasSospechosos)} '
                      'días. Se puede guardar igual, pero revise el número.',
                ),
              ],

            const SizedBox(height: Esp.m),
            TextField(
              controller: _motivo,
              maxLength: VacacionAsignadaEntity.motivoMaximo,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                border: OutlineInputBorder(),
                isDense: true,
                helperText: 'Queda en la fila y en la bitácora. Es obligatorio.',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: Esp.m),
            FilledButton.icon(
              // Se apaga mientras la llamada está en vuelo: es lo único que el
              // cliente puede aportar contra el doble toque, porque la base no
              // tiene ningún UNIQUE que lo frene.
              onPressed: _guardando ? null : _revisar,
              icon:
                  _guardando
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.save_outlined),
              // El botón de la hoja y el del diálogo dicen distinto a
              // propósito: uno abre la pregunta, el otro escribe.
              label: Text(_esAlta ? 'Asignar los días' : 'Guardar el cambio'),
            ),
          ],
        ),
      ),
    );
  }

  /// Valida, pregunta y recién entonces escribe.
  Future<void> _revisar() async {
    final dias = diasDeTexto(_dias.text);
    if (dias == null) {
      avisarError(context, 'Indique cuántos días se asignan.');
      return;
    }

    final propuesta = widget.vacacion.copyWith(
      diasAsignados: dias,
      motivo: _motivo.text,
    );
    // El mismo orden de reglas que el legacy, que corta en el primer fallo. No
    // autoriza nada: la validación que manda es la de Java, porque el SP no
    // valida absolutamente nada.
    final problema = propuesta.problema;
    if (problema != null) {
      avisarError(context, problema);
      return;
    }

    final ok = await confirmar(
      context,
      titulo: _esAlta ? '¿Asignar los días?' : '¿Guardar el cambio?',
      mensaje: _queVaAPasar(propuesta),
      accion: _esAlta ? 'Asignar' : 'Guardar',
    );
    if (!ok || !mounted) return;
    await _guardar(propuesta);
  }

  String _queVaAPasar(VacacionAsignadaEntity v) {
    final quien = widget.datoEmpleado.isEmpty ? 'este empleado' : widget.datoEmpleado;
    final cuantos = numeroDeDias(v.diasAsignados);
    final base =
        _esAlta
            ? 'Vas a asignar $cuantos días a $quien con fecha '
                '${fechaCorta(v.fecha)}.'
            : 'Vas a dejar la asignación del ${fechaCorta(v.fecha)} de $quien '
                'en $cuantos días '
                '(antes: ${numeroDeDias(widget.vacacion.diasAsignados)}).';
    return '$base\n\nMotivo: ${v.motivo.trim()}\n\n'
        'Suma al saldo de vacación de esa persona. Se puede corregir o borrar '
        'desde esta misma pantalla.';
  }

  /// Escribe. [confirmado] sólo en el reintento, después del 400 confirmable.
  Future<void> _guardar(
    VacacionAsignadaEntity v, {
    bool confirmado = false,
  }) async {
    setState(() => _guardando = true);
    try {
      // Lo que vuelve es **la fila releída**, no un id: el mensaje dice lo que
      // quedó en la base y no lo que se tipeó, que es lo único verificable
      // cuando en la misma tabla escribe además un proceso automático.
      final guardada = await ref
          .read(permisosRrhhAccionesProvider)
          .registrarVacacionAsignada(v, confirmado: confirmado);
      if (!mounted) return;
      Navigator.of(context).pop();
      final dias =
          guardada.diasAsignadosTxt.isEmpty
              ? '${numeroDeDias(guardada.diasAsignados)} días'
              : guardada.diasAsignadosTxt;
      avisar(
        context,
        _esAlta
            ? 'Quedaron $dias asignados con fecha ${fechaCorta(guardada.fecha)}.'
            : 'La asignación del ${fechaCorta(guardada.fecha)} quedó en $dias.',
      );
    } on RequiereConfirmacion catch (d) {
      // **No es un fracaso, es una pregunta** (400 con `confirmable`). En esta
      // tabla la repetición es sospechosa pero legítima: hay 215 grupos con la
      // misma (empleado, relación, fecha), casi todos del proceso automático
      // que escribe el día 1 de cada mes. Bloquear rechazaría datos que el ERP
      // ya da por buenos.
      //
      // **El 409 no llega acá y es a propósito**: aquél es un doble toque o una
      // carrera con otra persona, y reintentar manda exactamente el mismo
      // cuerpo —confirmación incluida— para que lo rechacen otra vez. Cae en el
      // `catch` de abajo, que avisa y relee.
      if (!mounted) return;
      setState(() => _guardando = false);
      final igual = await confirmar(
        context,
        titulo: 'Revise antes de guardar',
        // El texto del servidor va entero y primero: dice qué tiene de raro
        // —cuántos días tiene la fila que ya existe, o por qué el monto llama
        // la atención—, que es el dato con el que se decide.
        mensaje:
            '${d.mensaje}\n\nSi la carga igual, esa cantidad va a sumar al '
            'saldo de esa persona.',
        accion: 'Guardar igual',
        destructiva: true,
      );
      if (igual && mounted) await _guardar(v, confirmado: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      // Se relee la grilla: si esto fue un 409, alguien más escribió en el
      // medio y lo que la pantalla muestra ya no es lo que hay. No se ofrece
      // reintento —insistir manda el mismo cuerpo y lo vuelven a rechazar—.
      ref.read(permisosRrhhAccionesProvider).refrescar(v.codEmpleado);
      avisarError(context, e);
    }
  }
}
