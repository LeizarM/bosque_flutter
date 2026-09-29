/// Declarar un sábado como **puente a cuenta de vacación**.
///
/// La empresa decide que no se trabaja y se cobra a la vacación de cada uno (no
/// sirve la pantalla de solicitudes: rebota por cruces, firmas y saldo). Escribe
/// en `trh_permiso` y descuenta saldo a decenas de personas, por eso la hoja abre
/// en la simulación (`@ACCION='S'`, hace `RETURN` antes de toda transacción).
library;

import 'package:bosque_flutter/core/state/rol_sabados_provider.dart';
import 'package:bosque_flutter/domain/entities/puente_vacacion_entity.dart';
import 'package:bosque_flutter/domain/entities/sabado_entity.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/estilo_modulo.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/mensajes_usuario.dart';
import 'package:bosque_flutter/presentation/widgets/rol-sabados/rol_sabados_comunes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> mostrarPuenteSheet({
  required BuildContext context,
  required int idRol,
  required SabadoEntity sabado,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 720),
  builder: (_) => _PuenteSheet(idRol: idRol, sabado: sabado),
);

class _PuenteSheet extends ConsumerStatefulWidget {
  const _PuenteSheet({required this.idRol, required this.sabado});
  final int idRol;
  final SabadoEntity sabado;

  @override
  ConsumerState<_PuenteSheet> createState() => _PuenteSheetState();
}

class _PuenteSheetState extends ConsumerState<_PuenteSheet> {
  /// El turno real del sábado: cambia cuánto se descuenta, así que son editables
  /// y la lista se rehace con cada cambio.
  final _desde = TextEditingController(text: '08:30');
  final _hasta = TextEditingController(text: '12:30');
  final _motivo = TextEditingController();

  /// Lo que se le pregunta al servidor. Se actualiza al salir de los campos de
  /// hora, no en cada tecla: «0», «08», «08:» no son horas válidas.
  late PuenteAConsultar _clave = _claveActual();
  bool _guardando = false;

  PuenteAConsultar _claveActual() => (
    idSabado: widget.sabado.idSabado,
    horaDesde: _desde.text.trim(),
    horaHasta: _hasta.text.trim(),
  );

  void _revisarHoras() {
    final nueva = _claveActual();
    if (nueva != _clave) setState(() => _clave = nueva);
  }

  @override
  void dispose() {
    _desde.dispose();
    _hasta.dispose();
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previa = ref.watch(previaPuenteProvider(_clave));

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puente a cuenta de vacación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Sábado ${fechaCorta(widget.sabado.fecha)}. A todos los que ese día '
              'les tocaba venir se les carga un permiso de vacación y su celda '
              'pasa a V.',
              style: context.apagado(),
            ),

            const SizedBox(height: Esp.l),
            Row(
              children: [
                Expanded(
                  child: _Hora(
                    controlador: _desde,
                    etiqueta: 'Desde',
                    alSalir: _revisarHoras,
                  ),
                ),
                const SizedBox(width: Esp.m),
                Expanded(
                  child: _Hora(
                    controlador: _hasta,
                    etiqueta: 'Hasta',
                    alSalir: _revisarHoras,
                  ),
                ),
              ],
            ),
            // El detalle que decide cuánto se le descuenta a cada uno y no se adivina
            // mirando la pantalla.
            const _Nota(
              'El horario decide los días que se descuentan, y no de forma '
              'proporcional: se resta hasta media hora de almuerzo si la franja '
              'pisa el mediodía, y el sábado tope en 4 horas. Los puentes '
              'anteriores usaron 08:30–14:30, que da medio día exacto.',
            ),

            const SizedBox(height: Esp.l),
            TextField(
              controller: _motivo,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                helperText:
                    'Queda en el permiso de cada persona. Si se deja vacío: '
                    'PUENTE A CUENTA DE VACACIÓN.',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),

            const SizedBox(height: Esp.m),
            previa.when(
              loading:
                  () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: Esp.m),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: Esp.s),
                        Text('Calculando a quiénes alcanza…'),
                      ],
                    ),
                  ),
              error:
                  (e, _) => _Aviso(
                    'No se pudo calcular el puente. ${textoParaUsuario(e)}',
                  ),
              data: (lista) => _Resumen(lista: lista),
            ),

            const SizedBox(height: Esp.m),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                // Se apaga si no hay nadie a quien dar de alta: el servidor devolvería error.
                onPressed:
                    (_guardando ||
                            (previa.valueOrNull
                                    ?.where((d) => d.entra)
                                    .isEmpty ??
                                true))
                        ? null
                        : _confirmar,
                icon:
                    _guardando
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.beach_access_outlined),
                label: const Text('Declarar el puente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmar() async {
    final lista =
        ref.read(previaPuenteProvider(_clave)).valueOrNull ?? const [];
    final entran = lista.where((d) => d.entra).toList();
    final dias = entran.fold<double>(0, (a, d) => a + d.dias);

    // Segundo paso deliberado: confirmar descuenta vacación de verdad y no se
    // deshace desde ninguna pantalla (hay que borrar los permisos en RR.HH.).
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('¿Declarar el puente?'),
            content: Text(
              'Se van a crear ${entran.length} permisos de vacación del '
              '${_desde.text.trim()} al ${_hasta.text.trim()} del sábado '
              '${fechaCorta(widget.sabado.fecha)}, por '
              '${_dias(dias)} días en total.\n\n'
              'A cada persona se le descuenta de su saldo. Esto no se deshace '
              'desde aquí: para revertirlo hay que borrar los permisos en RR.HH.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Declarar'),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;

    setState(() => _guardando = true);
    try {
      final msg = await ref
          .read(rolSabadosAccionesProvider)
          .aplicarPuente(
            idRol: widget.idRol,
            idSabado: widget.sabado.idSabado,
            horaDesde: _desde.text.trim(),
            horaHasta: _hasta.text.trim(),
            motivo: _motivo.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      // El mensaje del servidor va tal cual: dice cuántos entraron y cuántos se
      // omitieron, más que un «Listo».
      avisar(context, msg);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        avisar(context, '$e', esError: true);
      }
    }
  }
}

/// Días con hasta cuatro decimales, sin ceros de relleno: un permiso de sábado
/// puede valer 0.4375 y redondearlo a 0.44 no coincidiría con lo guardado.
String _dias(double d) => d
    .toStringAsFixed(4)
    .replaceFirst(RegExp(r'0+$'), '')
    .replaceFirst(RegExp(r'\.$'), '');

class _Hora extends StatelessWidget {
  const _Hora({
    required this.controlador,
    required this.etiqueta,
    required this.alSalir,
  });

  final TextEditingController controlador;
  final String etiqueta;
  final VoidCallback alSalir;

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (tiene) {
      if (!tiene) alSalir();
    },
    child: TextField(
      controller: controlador,
      decoration: InputDecoration(
        labelText: etiqueta,
        hintText: 'HH:MM',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onSubmitted: (_) => alSalir(),
    ),
  );
}

/// Cuántos entran, cuántos días suman y quiénes quedan afuera.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.lista});
  final List<PuenteVacacionEntity> lista;

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) {
      return const _Aviso(
        'Ese sábado no tiene a nadie que tenga que venir, así que no hay puente '
        'que declarar.',
      );
    }

    // El servidor manda el motivo como una fila, no como excepción: así sale
    // «falta tal dato» y no un error de driver. Ver `PuenteVacacionEntity.esError`.
    if (lista.first.esError) return _Aviso(lista.first.detalle);

    final entran = lista.where((d) => d.entra).toList();
    final fuera = lista.where((d) => !d.entra).toList();
    final dias = entran.fold<double>(0, (a, d) => a + d.dias);

    if (entran.isEmpty) {
      return _Aviso(
        'Las ${fuera.length} personas de ese sábado ya tienen un permiso '
        'cargado ese día, así que no hay nada que dar de alta.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${entran.length} personas · ${_dias(dias)} días de vacación en total',
          style: context.tituloSeccion(),
        ),
        Text(
          '${_dias(entran.first.dias)} días a cada una.',
          style: context.apagado(),
        ),
        if (fuera.isNotEmpty)
          _Nota(
            fuera.length == 1
                ? 'Se saltea 1: ${fuera.single.nombreRol} — ${fuera.single.detalle}.'
                : 'Se saltean ${fuera.length}: ya tienen un permiso ese día o no '
                    'tienen relación laboral activa. Están al final de la lista.',
          ),
        const SizedBox(height: Esp.s),
        Container(
          constraints: const BoxConstraints(maxHeight: 168),
          decoration: BoxDecoration(
            border: Border.all(color: context.cs.outlineVariant),
            borderRadius: BorderRadius.circular(Esp.xs),
          ),
          child: Scrollbar(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: Esp.xs),
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final d = lista[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Esp.s,
                    vertical: 3,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          d.nombreRol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              d.entra
                                  ? null
                                  : TextStyle(color: context.cs.error),
                        ),
                      ),
                      Text(
                        d.entra ? _dias(d.dias) : d.detalle,
                        style: context.apagado(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Esp.xs, left: 2),
    child: Text(texto, style: context.apagado()),
  );
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Esp.xs, left: 2),
    child: Text(
      texto,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: context.cs.error),
    ),
  );
}
