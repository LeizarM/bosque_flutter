import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/celda_turno_entity.dart';
import 'package:bosque_flutter/domain/entities/programador_dependiente_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La decisión de un jefe sobre una persona en un sábado: **viene o no viene**.
///
/// Vive suelta (como `mostrarEditorDeCelda`): se abre desde la lista y desde el
/// panorama. **Sólo dos salidas:** 'V', 'B', 'X' y 'P' los carga RR.HH. y esas
/// celdas ya llegan bloqueadas. **No hay «Anular»:** `trs_sp_programar` anula
/// por (jefe, sábado) y borra TODAS las celdas de esa programación; corregir es
/// volver a decidir.
Future<void> mostrarDecisionDelJefe({
  required BuildContext context,
  required int idRol,
  required GrillaRol grilla,
  required ProgramadorDependienteEntity dependiente,
  required SabadoEntity sabado,
  required CeldaTurnoEntity? celda,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder:
      (_) => _DecisionDelJefe(
        idRol: idRol,
        grilla: grilla,
        dependiente: dependiente,
        sabado: sabado,
        celda: celda,
      ),
);

class _DecisionDelJefe extends ConsumerStatefulWidget {
  const _DecisionDelJefe({
    required this.idRol,
    required this.grilla,
    required this.dependiente,
    required this.sabado,
    required this.celda,
  });

  final int idRol;
  final GrillaRol grilla;
  final ProgramadorDependienteEntity dependiente;
  final SabadoEntity sabado;
  final CeldaTurnoEntity? celda;

  @override
  ConsumerState<_DecisionDelJefe> createState() => _DecisionDelJefeState();
}

class _DecisionDelJefeState extends ConsumerState<_DecisionDelJefe> {
  final _motivo = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Con decisión previa, su motivo es el punto de partida: casi siempre se
    // corrige la letra y el motivo sigue igual.
    _motivo.text = widget.celda?.observacion ?? '';
  }

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final actual = widget.celda?.codigoExcel;

    // Sin celda es LIBRE (ausencia de fila, no una letra): para el jefe equivale
    // a una 'L'.
    final vieneAhora = actual == '1';
    final libreAhora = actual == null || actual == 'L';

    final dias = _diasHasta(widget.sabado.fecha);
    final cobertura = widget.grilla.coberturaDe(widget.sabado.idSabado);
    final objetivo = widget.grilla.rol.coberturaObjetivo;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.dependiente.nombreDependiente,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Sábado ${fechaCorta(widget.sabado.fecha)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Esp.s),

            // Cobertura del día (en memoria): evita que treinta jefes vacíen el mismo
            // sábado. Dice «todo el rol» y no «X de Y» porque la barra de arriba muestra
            // «tu equipo: vienen 3 de 6»; aquí el denominador es «cuántos hacen falta».
            Text(
              objetivo > 0
                  ? 'Todo el rol ese sábado: vienen $cobertura · '
                      'objetivo $objetivo'
                      '${cobertura < objetivo ? (objetivo - cobertura == 1 ? ' · falta 1 persona' : ' · faltan ${objetivo - cobertura} personas') : ''}'
                  : 'Todo el rol ese sábado: vienen $cobertura.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color:
                    objetivo > 0 && cobertura < objetivo
                        ? cs.error
                        : Theme.of(context).hintColor,
              ),
            ),

            const SizedBox(height: Esp.l),
            // Botones apilados y a todo el ancho: en 360 px la fila deja 170 px por botón
            // y «Que no venga» con el icono no entra sin recortarse.
            _BotonGrande(
              icono: Icons.check_circle_outline,
              texto: 'Que venga',
              marcado: vieneAhora,
              onTap: _guardando ? null : () => _guardar('1'),
            ),
            const SizedBox(height: Esp.s),
            _BotonGrande(
              icono: Icons.remove_circle_outline,
              texto: 'Que no venga',
              marcado: libreAhora,
              onTap: _guardando ? null : () => _guardar('L'),
            ),

            const SizedBox(height: Esp.s),
            Text(
              vieneAhora
                  ? 'Ahora figura que viene.'
                  : libreAhora
                  ? 'Ahora está libre: ese día no le tocaba.'
                  : 'Ahora figura como '
                      '${widget.grilla.estados[actual]?.nombre ?? actual}.',
              style: context.apagado(),
            ),

            if (dias != null && dias < 7) ...[
              const SizedBox(height: Esp.m),
              _AvisoTardio(dias: dias),
            ],

            const SizedBox(height: Esp.l),
            TextField(
              controller: _motivo,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                helperText:
                    'Opcional. Queda guardado con la decisión y se ve en el '
                    'control de intervenciones.',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),

            if (_guardando)
              const Padding(
                padding: EdgeInsets.only(top: Esp.s),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Días entre hoy y el sábado, por fecha y no por horas: el viernes a las 23 y
  /// a las 8 es "un día" en ambos casos.
  int? _diasHasta(DateTime? fecha) {
    if (fecha == null) return null;
    final hoy = DateTime.now();
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
  }

  Future<void> _guardar(String codigoExcel) async {
    setState(() => _guardando = true);
    final quien = widget.dependiente.nombreDependiente;
    final ok = await ejecutarAccion(
      context,
      () => ref
          .read(rolSabadosAccionesProvider)
          .programar(
            idRol: widget.idRol,
            idSabado: widget.sabado.idSabado,
            codEmpleadoDependiente: widget.dependiente.codDependiente,
            codigoExcel: codigoExcel,
            motivo: _motivo.text.trim(),
          ),
      exito:
          codigoExcel == '1'
              ? '$quien viene el ${fechaCorta(widget.sabado.fecha)}.'
              : '$quien no viene el ${fechaCorta(widget.sabado.fecha)}.',
      cerrar: true,
    );
    if (mounted && !ok) setState(() => _guardando = false);
  }
}

/// Botón de 56 px de alto y del ancho de la hoja. Marcado = lo que dice la
/// grilla hoy; se deja habilitado porque reafirmar deja el motivo escrito.
class _BotonGrande extends StatelessWidget {
  const _BotonGrande({
    required this.icono,
    required this.texto,
    required this.marcado,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final bool marcado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child:
        marcado
            ? FilledButton.icon(
              onPressed: onTap,
              icon: Icon(icono),
              label: Text(texto),
            )
            : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icono),
              label: Text(texto),
            ),
  );
}

/// El aviso de que se está decidiendo sobre la hora.
///
/// Va etiquetado como estimación: `trs_Programacion.diasAntelacion` lo calcula
/// el servidor con su reloj; éste sale del teléfono (fecha o huso pueden estar
/// corridos). Sirve para pensarlo dos veces, no para discutir si fue tardío.
class _AvisoTardio extends StatelessWidget {
  const _AvisoTardio({required this.dias});
  final int dias;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cuanto = switch (dias) {
      <= 0 => 'Ese sábado es hoy o ya pasó',
      1 => 'Estás avisando con un día',
      _ => 'Estás avisando con $dias días',
    };

    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(Esp.s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: cs.onTertiaryContainer),
              const SizedBox(width: Esp.s),
              Expanded(
                child: Text(
                  '$cuanto (estimado).',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onTertiaryContainer,
                    fontWeight: Peso.titulo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Esp.xs),
          Text(
            'La cuenta la hace el teléfono. El número que queda registrado lo '
            'calcula el servidor con su propio reloj.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onTertiaryContainer),
          ),
        ],
      ),
    );
  }
}
