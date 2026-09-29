import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/presentation/widgets/precios/ancho_dialogo.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/costo_iva_it_entity.dart';

/// Lo que devuelve [DialogoImpuestosPrecio] cuando la persona confirma.
///
/// El dialogo NO escribe: solo junta los dos porcentajes y los valida. La
/// escritura la hace la pantalla, que es la que tiene el repositorio y sabe
/// que lecturas invalidar.
@immutable
class ResultadoImpuestos {
  const ResultadoImpuestos({required this.iva, required this.it});

  /// Porcentaje de IVA en puntos porcentuales: 15,476 % viaja como 15.476.
  final double iva;

  /// Porcentaje de IT en puntos porcentuales.
  final double it;
}

/// Formulario del IVA y el IT que entran en la formula de precio.
///
/// Es una ficha de configuracion, no un alta: tpr_costoIvaIt es un singleton y
/// el procedimiento rechaza una segunda fila. Por eso el dialogo siempre edita
/// [actual], y solo cuando la tabla esta vacia se comporta como carga inicial.
///
/// Los dos valores los lee TODO el calculo de precios del sistema, asi que
/// antes de devolver el resultado se pide una confirmacion explicita que
/// muestra el valor anterior y el nuevo.
class DialogoImpuestosPrecio extends StatefulWidget {
  const DialogoImpuestosPrecio({super.key, this.actual});

  /// La fila vigente. Null cuando todavia no hay impuestos configurados.
  final CostoIvaItEntity? actual;

  @override
  State<DialogoImpuestosPrecio> createState() => _DialogoImpuestosPrecioState();
}

class _DialogoImpuestosPrecioState extends State<DialogoImpuestosPrecio> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _iva;
  late final TextEditingController _it;

  @override
  void initState() {
    super.initState();
    _iva = TextEditingController(text: _texto(widget.actual?.iva));
    _it = TextEditingController(text: _texto(widget.actual?.it));
  }

  @override
  void dispose() {
    _iva.dispose();
    _it.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final anterior = widget.actual;

    // El total se recalcula mientras se escribe: es la cifra que el usuario
    // reconoce -hoy 19,046 %- y equivocarse en un decimal se ve mejor en la
    // suma que en cada campo por separado.
    final ivaNuevo = _aNumero(_iva.text);
    final itNuevo = _aNumero(_it.text);
    final total =
        (ivaNuevo != null && itNuevo != null) ? ivaNuevo + itNuevo : null;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: cs.error),
      title: const Text('Editar IVA e IT'),
      insetPadding: const EdgeInsets.all(Esp.l),
      content: SingleChildScrollView(
        child: SizedBox(
          width: anchoDialogo(context, 420),
          child: Form(
            key: _formulario,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const NotaDelDato(
                  tono: TonoNota.error,
                  texto:
                      'Estos dos porcentajes entran en el cálculo de TODOS los '
                      'precios del sistema. Al guardarlos, cada precio que se '
                      'calcule desde ahora usa los valores nuevos.',
                ),
                const SizedBox(height: Esp.l),
                _campo(
                  controlador: _iva,
                  etiqueta: 'IVA (%)',
                  anterior: anterior?.ivaLegible,
                ),
                const SizedBox(height: Esp.m),
                _campo(
                  controlador: _it,
                  etiqueta: 'IT (%)',
                  anterior: anterior?.itLegible,
                ),
                const SizedBox(height: Esp.l),
                Container(
                  padding: const EdgeInsets.all(Esp.m),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(Esquina.chica),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Total IVA + IT', style: context.apagado()),
                      ),
                      Text(
                        total == null ? '-' : _porcentaje(total),
                        style: tt.titleMedium?.copyWith(
                          fontWeight: Peso.dato,
                          fontFeatures: cifrasTabulares,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _confirmarYDevolver,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _campo({
    required TextEditingController controlador,
    required String etiqueta,
    String? anterior,
  }) => TextFormField(
    controller: controlador,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    // Se admite coma y punto: el teclado numerico de Android manda coma en
    // es-BO y el de escritorio manda punto. La conversion la hace [_aNumero].
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
    decoration: InputDecoration(
      labelText: etiqueta,
      prefixIcon: const Icon(Icons.percent),
      helperText: anterior == null ? 'Sin valor previo' : 'Actual: $anterior',
      border: const OutlineInputBorder(),
    ),
    onChanged: (_) => setState(() {}),
    validator: _validarPorcentaje,
  );

  /// Valida contra el dominio del dato y no contra el widget: es un porcentaje
  /// y fuera de 0 a 100 no significa nada.
  String? _validarPorcentaje(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Ingrese el porcentaje';
    final numero = _aNumero(texto);
    if (numero == null) return 'Use solo números, con coma o punto';
    if (numero < 0) return 'No puede ser negativo';
    if (numero > 100) return 'No puede superar 100';
    return null;
  }

  Future<void> _confirmarYDevolver() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;

    final iva = _aNumero(_iva.text)!;
    final it = _aNumero(_it.text)!;
    final anterior = widget.actual;

    // Nada que guardar: se evita una escritura que no cambia nada, y de paso
    // la confirmacion en vano.
    if (anterior != null && anterior.iva == iva && anterior.it == it) {
      Navigator.pop(context);
      return;
    }

    final detalle =
        StringBuffer()
          ..writeln(
            'IVA: ${anterior?.ivaLegible ?? 'sin valor'} a ${_porcentaje(iva)}',
          )
          ..writeln(
            'IT: ${anterior?.itLegible ?? 'sin valor'} a ${_porcentaje(it)}',
          )
          ..writeln(
            'Total: ${anterior?.totalIvaItLegible ?? 'sin valor'} '
            'a ${_porcentaje(iva + it)}',
          )
          ..writeln()
          ..write(
            'El IVA y el IT se usan para calcular todos los precios del '
            'sistema. El cambio afecta a cada precio que se calcule a partir '
            'de ahora.',
          );

    final aceptado = await confirmar(
      context,
      titulo: '¿Cambiar el IVA y el IT?',
      detalle: detalle.toString(),
      textoConfirmar: 'Sí, cambiar',
      destructiva: true,
    );
    if (!aceptado || !mounted) return;

    Navigator.pop(context, ResultadoImpuestos(iva: iva, it: it));
  }
}

/// Convierte lo escrito a numero aceptando coma o punto como separador.
/// Devuelve null cuando el texto no es un numero.
double? _aNumero(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) return null;
  return double.tryParse(limpio);
}

/// El valor guardado, listo para editar: con coma y sin ceros de relleno.
String _texto(double? valor) {
  if (valor == null) return '';
  return _sinCerosSobrantes(valor).replaceAll('.', ',');
}

/// Porcentaje legible, con el mismo formato que usan las entities.
String _porcentaje(double valor) =>
    '${_sinCerosSobrantes(valor).replaceAll('.', ',')} %';

String _sinCerosSobrantes(double valor) {
  var texto = valor.toStringAsFixed(3);
  if (texto.contains('.')) {
    texto = texto.replaceAll(RegExp(r'0+$'), '');
    texto = texto.replaceAll(RegExp(r'\.$'), '');
  }
  return texto;
}
