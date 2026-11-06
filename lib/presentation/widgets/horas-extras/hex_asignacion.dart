/// Piezas de la asignación de horas extra (D37): el aviso que no bloquea
/// (vacación, baja, permiso o sábado sin turno), el resultado y las faltas
/// (adenda D37) y el diálogo de quitar. Quién puede y los textos, del SP.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/hex_asignacion_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/hex_asignacion_falta_entity.dart';
import 'package:bosque_flutter/domain/repositories/hex_errores.dart';
import 'package:bosque_flutter/presentation/widgets/horas-extras/hex_comun.dart';

/// El ícono de cada tipo de aviso de `asignacion/asignables`.
IconData iconoAvisoAsignacionHex(String? tipo) => switch (tipo) {
  'VACACION' => Icons.beach_access_outlined,
  'BAJA' => Icons.healing_outlined,
  'PERMISO' => Icons.event_busy_outlined,
  'SABADO' => Icons.weekend_outlined,
  _ => Icons.info_outline,
};

/// D41: el motivo que escribió quien asignó, con su etiqueta; [lineas] lo
/// corta en la tabla. Solo lectura, igual para el encargado y el operario.
class MotivoAsignacionHex extends StatelessWidget {
  const MotivoAsignacionHex(this.motivo, {super.key, this.lineas});

  final String motivo;
  final int? lineas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme.bodySmall;
    return Semantics(
      label: 'Motivo: ${motivo.trim()}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.notes, size: 16, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: Esp.xs),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Motivo: ',
                    style: TextStyle(
                      fontWeight: Peso.titulo,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(text: motivo.trim()),
                ],
              ),
              maxLines: lineas,
              overflow: lineas == null ? null : TextOverflow.ellipsis,
              style: t?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// El aviso del SP antes de asignar; no impide asignar: al hacerlo, el SP
/// pide confirmarlo. Nada si no hay aviso.
class AvisoAsignacionHex extends StatelessWidget {
  const AvisoAsignacionHex({
    super.key,
    required this.tipo,
    required this.aviso,
  });

  final String? tipo;
  final String? aviso;

  @override
  Widget build(BuildContext context) {
    final texto = aviso?.trim() ?? '';
    if (texto.isEmpty) return const SizedBox.shrink();
    return ChipHex(
      texto: texto,
      icono: iconoAvisoAsignacionHex(tipo),
      tono: TonoHex.pendiente,
      ayuda: 'Se puede asignar igual: al hacerlo se pide confirmarlo.',
    );
  }
}

/// D42: «Asignada el …, con fecha atrasada (regularización)», como lo manda
/// el SP; sin ficha para que quepa en una celda angosta. Nada si no vino.
class AtrasadaAsignacionHex extends StatelessWidget {
  const AtrasadaAsignacionHex(this.texto, {super.key});

  final String? texto;

  @override
  Widget build(BuildContext context) {
    final t = texto?.trim() ?? '';
    if (t.isEmpty) return const SizedBox.shrink();
    return IconoTextoHex(
      texto: t,
      icono: Icons.history,
      tono: TonoHex.pendiente,
    );
  }
}

/// Adenda D37: qué pasó con una asignación activa (con reporte, pendiente,
/// falta o sin reporte) y el texto del SP. Nada si el SP no manda resultado.
/// [compacto] para la celda de una tabla: el texto en tres renglones.
class ResultadoAsignacionHex extends StatelessWidget {
  const ResultadoAsignacionHex({
    super.key,
    required this.resultado,
    required this.aviso,
    this.compacto = false,
  });

  final String? resultado;
  final String? aviso;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final r = resultado?.trim() ?? '';
    if (r.isEmpty) return const SizedBox.shrink();
    final falta = r == 'FALTA';
    final (rotulo, icono, tono) = switch (r) {
      'FALTA' => ('Falta', Icons.person_off_outlined, TonoHex.error),
      'PENDIENTE' => ('Pendiente', Icons.hourglass_empty, TonoHex.pendiente),
      'CON_REPORTE' => (
        'Con reporte',
        Icons.assignment_turned_in_outlined,
        TonoHex.exito,
      ),
      'SIN_REPORTE' => (
        'Sin reporte',
        Icons.assignment_outlined,
        TonoHex.neutro,
      ),
      _ => (r, Icons.info_outline, TonoHex.neutro),
    };
    final texto = aviso?.trim() ?? '';
    final ficha = ChipHex(texto: rotulo, icono: icono, tono: tono);
    if (texto.isEmpty) return ficha;
    if (!compacto) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ficha,
          NotaDelDato(
            texto: texto,
            tono: falta ? TonoNota.error : TonoNota.info,
          ),
        ],
      );
    }
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: texto,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ficha,
          const SizedBox(height: Esp.xs),
          Text(
            texto,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: falta ? cs.error : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Adenda D37: las faltas de lo que asignó quien revisa, con el texto del
/// SP. Muestra las primeras [visibles]; el resto se abre a pedido.
class AvisoFaltasHex extends StatefulWidget {
  const AvisoFaltasHex(this.faltas, {super.key, this.visibles = 3});

  final List<HexAsignacionFaltaEntity> faltas;
  final int visibles;

  @override
  State<AvisoFaltasHex> createState() => _AvisoFaltasHexState();
}

class _AvisoFaltasHexState extends State<AvisoFaltasHex> {
  bool _todas = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final faltas = widget.faltas;
    final sobran = faltas.length - widget.visibles;
    final vistas =
        _todas || sobran <= 0 ? faltas : faltas.take(widget.visibles);
    return Semantics(
      container: true,
      label: 'Faltas en lo que asignaste',
      child: Container(
        padding: const EdgeInsets.fromLTRB(Esp.m, Esp.m, Esp.m, Esp.s),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(Esquina.chica),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_off_outlined, color: cs.onErrorContainer),
                const SizedBox(width: Esp.s),
                Expanded(
                  child: Text(
                    cuentaHex(
                      faltas.length,
                      'asignación terminó en falta',
                      'asignaciones terminaron en falta',
                    ),
                    style: t.titleSmall?.copyWith(color: cs.onErrorContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Esp.s),
            for (final f in vistas)
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.s),
                child: Text(
                  f.avisoResultado.trim().isEmpty
                      ? '${oGuionHex(f.nombreEmpleado)} · '
                          '${fechaHex(f.fechaJornada)}'
                      : f.avisoResultado.trim(),
                  style: t.bodyMedium?.copyWith(color: cs.onErrorContainer),
                ),
              ),
            if (sobran > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _todas = !_todas),
                  style: TextButton.styleFrom(
                    foregroundColor: cs.onErrorContainer,
                  ),
                  icon: Icon(
                    _todas ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(
                    _todas ? 'Ver menos' : 'Ver las $sobran restantes',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Abre la confirmación de quitar [idAsignacion] con una observación
/// opcional. [refrescar] corre si se quitó o si ya había cambiado (409).
Future<void> quitarAsignacionHex(
  BuildContext context,
  WidgetRef ref, {
  required BigInt idAsignacion,
  required String nombreEmpleado,
  required DateTime? fechaJornada,
  required VoidCallback refrescar,
}) {
  final repo = ref.read(hexAsignacionRepositoryProvider);
  return abrirDialogoHex(
    context,
    refrescar: refrescar,
    dialogo:
        (recargar) => _DialogoQuitarHex(
          detalle:
              'Se quita la asignación de ${oGuionHex(nombreEmpleado)} para la '
              'jornada del ${fechaHex(fechaJornada)}. Sin asignación no puede '
              'marcar ni reportar horas extra ese día.',
          refrescar: recargar,
          quitar:
              (observacion) => repo.quitar(
                idAsignacion: idAsignacion,
                observacion: observacion,
              ),
        ),
  );
}

class _DialogoQuitarHex extends StatefulWidget {
  const _DialogoQuitarHex({
    required this.detalle,
    required this.refrescar,
    required this.quitar,
  });

  final String detalle;
  final VoidCallback refrescar;
  final Future<HexRespuesta> Function(String? observacion) quitar;

  @override
  State<_DialogoQuitarHex> createState() => _DialogoQuitarHexState();
}

class _DialogoQuitarHexState extends State<_DialogoQuitarHex>
    with EscrituraEnDialogoHex {
  final TextEditingController _observacion = TextEditingController();

  @override
  VoidCallback get refrescarLista => widget.refrescar;

  @override
  void dispose() {
    _observacion.dispose();
    super.dispose();
  }

  void _quitar() {
    FocusManager.instance.primaryFocus?.unfocus();
    final texto = _observacion.text.trim();
    escribir((_) => widget.quitar(texto.isEmpty ? null : texto));
  }

  @override
  Widget build(BuildContext context) => DialogoHex(
    titulo: 'Quitar asignación',
    icono: Icons.person_remove_outlined,
    destructiva: true,
    ocupado: ocupado,
    accion: 'Quitar',
    alAceptar: _quitar,
    contenido:
        (enCurso) => [
          Text(widget.detalle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Esp.l),
          TextoLargoHex(
            control: _observacion,
            etiqueta: 'Observación',
            ayuda: 'Opcional.',
            habilitado: !enCurso,
          ),
        ],
  );
}
