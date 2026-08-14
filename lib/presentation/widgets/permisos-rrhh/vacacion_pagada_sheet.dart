import 'package:bosque_flutter/core/state/permisos_rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/ficha_saldo_entity.dart';
import 'package:bosque_flutter/domain/repositories/permisos_rrhh_repository.dart';
import 'package:bosque_flutter/presentation/widgets/permisos-rrhh/permisos_rrhh_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// **Paga días de vacación**: el modal «Pago de vacaciones» (`tipoPermiso =
/// 'pva'`).
Future<void> mostrarVacacionPagada({
  required BuildContext context,
  required int codEmpleado,
  required String datoEmpleado,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 560),
  builder:
      (_) => _VacacionPagadaSheet(
        codEmpleado: codEmpleado,
        datoEmpleado: datoEmpleado,
      ),
);

/// La única escritura del módulo donde los días **los tipea una persona** y no
/// los calcula nadie.
///
/// ## Por qué esta pantalla tiene más barreras que las otras
///
/// Son 32 filas en diez años —una por año— así que no se justifica por el
/// volumen sino por el impacto: hay una fila histórica de **247 días pagados** y
/// otra de 30. Y el sistema anterior no pone ninguna barrera: `savePagoDiasVacac`
/// acepta cualquier cantidad, no mira el saldo, no tiene tope, no confirma nada
/// y un doble clic mete dos filas.
///
/// Acá van, en orden: el saldo antes y después **a la vista mientras se tipea**,
/// un aviso si el número supera el saldo o la mayor PVA razonable, una
/// confirmación que repite los dos saldos, y el botón apagado mientras la
/// llamada está en vuelo. Del otro lado, el backend rechaza con 409 la fila
/// idéntica cargada hace menos de dos minutos, que es lo que pasa cuando alguien
/// toca dos veces en el teléfono.
///
/// **No calcula días hábiles y no es un olvido**: el servidor fuerza `hasta =
/// desde`, así que una PVA ocupa un solo día y `f_CalcularDiasHabilesPermiso`
/// no tiene nada que calcular. Los días son los que se pagan, no los que se
/// gozan.
class _VacacionPagadaSheet extends ConsumerStatefulWidget {
  const _VacacionPagadaSheet({
    required this.codEmpleado,
    required this.datoEmpleado,
  });

  final int codEmpleado;
  final String datoEmpleado;

  @override
  ConsumerState<_VacacionPagadaSheet> createState() =>
      _VacacionPagadaSheetState();
}

class _VacacionPagadaSheetState extends ConsumerState<_VacacionPagadaSheet> {
  final _dias = TextEditingController();
  final _motivo = TextEditingController();

  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  /// Arriba de esto se avisa. **No es un tope**: es la segunda PVA más grande de
  /// los últimos diez años, o sea el número a partir del cual conviene mirar dos
  /// veces. La más grande fue de 247 días y nadie la frenó.
  static const double _diasSospechosos = 30;

  /// El mismo piso que exige el backend y que ya tenía el campo del sistema
  /// anterior (`min=0.5 step=0.5`).
  static const double _diasMinimo = 0.5;

  @override
  void dispose() {
    _dias.dispose();
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El saldo con el que se compara. Sale de la ficha que la pantalla ya tiene
    // cargada: pedirlo de nuevo acá sería una consulta más para el mismo dato.
    final ficha = ref.watch(fichaSaldoProvider(widget.codEmpleado)).valueOrNull;
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
              'Pagar vacación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              widget.datoEmpleado.isEmpty
                  ? 'A nombre del empleado seleccionado'
                  : widget.datoEmpleado,
              style: context.apagado(),
            ),

            const SizedBox(height: Esp.m),
            const AvisoDelDato(
              icono: Icons.payments_outlined,
              texto:
                  'Esto registra días PAGADOS: le descuenta el saldo de '
                  'vacación y va a la planilla. No se deshace desde esta '
                  'pantalla.',
            ),

            const SizedBox(height: Esp.l),
            CampoElegido(
              etiqueta: 'Fecha del pago',
              texto: fechaCorta(_fecha),
              onTap: _guardando ? null : _elegirFecha,
              ayuda:
                  'Un solo día: el sistema anterior guarda la PVA con la misma '
                  'fecha de inicio y de fin.',
            ),

            const SizedBox(height: Esp.m),
            TextField(
              controller: _dias,
              autofocus: true,
              enabled: !_guardando,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Días a pagar',
                border: OutlineInputBorder(),
                isDense: true,
                helperText: 'Medio día como mínimo. Los ingresa usted: aquí no hay '
                    'nada que los calcule.',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: Esp.m),
            _impacto(ficha, dias),

            if (ficha != null && dias != null && dias > ficha.totalDias) ...[
              const SizedBox(height: Esp.s),
              AvisoDelDato(
                icono: Icons.warning_amber_rounded,
                texto:
                    'Le está pagando más días de los que tiene: su saldo es '
                    '${_saldoTexto(ficha)} y le quedaría en '
                    '${numeroDeDias(_redondear(ficha.totalDias - dias))}. Se '
                    'puede guardar igual, pero revise el número.',
              ),
            ] else if (dias != null && dias > _diasSospechosos) ...[
              const SizedBox(height: Esp.s),
              AvisoDelDato(
                icono: Icons.warning_amber_rounded,
                texto:
                    'En diez años no hubo ningún pago de más de '
                    '${numeroDeDias(_diasSospechosos)} días salvo uno. Se puede '
                    'guardar igual, pero revise el número.',
              ),
            ],

            const SizedBox(height: Esp.m),
            TextField(
              controller: _motivo,
              enabled: !_guardando,
              // 100 y no 300: el textarea del sistema anterior declara 300 pero
              // `trh_permiso.motivo` es VARCHAR(100), así que lo que sobra se
              // pierde en silencio del otro lado.
              maxLength: 100,
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
              // Apagado mientras la llamada está en vuelo: es lo único que el
              // cliente puede aportar contra el doble toque, y acá el doble
              // toque cuesta plata.
              onPressed: _puedeGuardar(dias) ? () => _revisar(ficha, dias!) : null,
              icon:
                  _guardando
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.payments_outlined),
              label: const Text('Pagar los días'),
            ),
          ],
        ),
      ),
    );
  }

  /// El saldo antes y después, **mientras se tipea**. Es el primero de los dos
  /// pasos de confirmación: el segundo es el diálogo, que repite los mismos dos
  /// números.
  Widget _impacto(FichaSaldoEntity? ficha, double? dias) {
    if (ficha == null) {
      return const AvisoDelDato(
        icono: Icons.help_outline,
        texto:
            'No se pudo leer el saldo de esta persona, así que no puedo '
            'decirte cómo le queda después de pagar. Revisalo en la pestaña '
            '«Saldo» antes de guardar.',
      );
    }
    final despues = dias == null ? null : _redondear(ficha.totalDias - dias);
    return Bloque(
      icono: Icons.account_balance_wallet_outlined,
      titulo: 'Cómo le queda el saldo',
      hijo: Wrap(
        spacing: Esp.xl,
        runSpacing: Esp.m,
        children: [
          Metrica(
            rotulo: 'Saldo hoy',
            texto: _saldoTexto(ficha),
            valor: ficha.totalDias,
          ),
          Metrica(
            rotulo: 'Después de pagar',
            texto: despues == null ? '…' : numeroDeDias(despues),
            valor: despues,
            destacada: true,
          ),
        ],
      ),
    );
  }

  String _saldoTexto(FichaSaldoEntity f) =>
      f.totalDiasTxt.isEmpty ? numeroDeDias(f.totalDias) : f.totalDiasTxt;

  /// Los días se muestran con la misma precisión con la que los guarda el
  /// backend: octavos. Sin esto, `12,5 - 3` puede salir `9,499999999999998`.
  static double _redondear(double v) => (v * 8).round() / 8;

  bool _puedeGuardar(double? dias) =>
      !_guardando &&
      dias != null &&
      dias >= _diasMinimo &&
      _motivo.text.trim().length >= 2;

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 1, 12, 31),
      helpText: 'Fecha del pago',
    );
    if (!mounted || elegida == null) return;
    setState(() => _fecha = elegida);
  }

  /// El segundo paso: dice la cantidad, a quién, con qué fecha y **cómo queda el
  /// saldo**, que es lo único con lo que se puede verificar que el número es el
  /// que se quiso poner.
  Future<void> _revisar(FichaSaldoEntity? ficha, double dias) async {
    final quien =
        widget.datoEmpleado.isEmpty ? 'este empleado' : widget.datoEmpleado;
    final saldo =
        ficha == null
            ? 'No se pudo leer su saldo actual, así que no puedo decirte cómo '
                'queda.'
            : 'Su saldo pasa de ${_saldoTexto(ficha)} a '
                '${numeroDeDias(_redondear(ficha.totalDias - dias))} días.';

    final ok = await confirmar(
      context,
      titulo: '¿Pagar ${numeroDeDias(dias)} días?',
      mensaje:
          'Vas a pagar ${numeroDeDias(dias)} días de vacación a $quien con '
          'fecha ${fechaCorta(_fecha)}.\n\n$saldo\n\n'
          'Motivo: ${_motivo.text.trim()}\n\n'
          'Son días PAGADOS: van a la planilla. Para deshacerlo hay que borrar '
          'la fila desde el sistema anterior.',
      accion: 'Pagar',
      // Rojo del tema, no por castigo: para que el toque de confirmar no sea el
      // mismo gesto automático que el de guardar cualquier otra cosa.
      destructiva: true,
    );
    if (!ok || !mounted) return;
    await _guardar(dias);
  }

  Future<void> _guardar(double dias, {bool confirmado = false}) async {
    setState(() => _guardando = true);
    try {
      final msg = await ref
          .read(permisosRrhhAccionesProvider)
          .registrarVacacionPagada(
            codEmpleado: widget.codEmpleado,
            fecha: _fecha,
            dias: dias,
            motivo: _motivo.text,
            confirmado: confirmado,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      avisar(
        context,
        msg.isEmpty
            ? 'Quedaron pagados ${numeroDeDias(dias)} días.'
            : msg,
      );
    } on RequiereConfirmacion catch (d) {
      // 400 confirmable: el servidor encontró algo raro —una PVA parecida, un
      // número grande— y pregunta. El 409 es lo contrario: es el doble toque, y
      // reintentar mandaría el mismo cuerpo para que lo rechacen otra vez. Cae
      // en el `catch` de abajo.
      if (!mounted) return;
      setState(() => _guardando = false);
      final igual = await confirmar(
        context,
        titulo: 'Revise antes de pagar',
        mensaje:
            '${d.mensaje}\n\nSi lo carga igual, esos días quedan pagados y le '
            'descuentan el saldo.',
        accion: 'Pagar igual',
        destructiva: true,
      );
      if (igual && mounted) await _guardar(dias, confirmado: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      // Se relee: si fue un 409, la fila ya existe y el saldo en pantalla es el
      // viejo. Lo peor que puede pasar acá es que alguien vuelva a intentarlo
      // creyendo que no se guardó.
      ref.read(permisosRrhhAccionesProvider).refrescar(widget.codEmpleado);
      avisarError(context, e);
    }
  }
}
