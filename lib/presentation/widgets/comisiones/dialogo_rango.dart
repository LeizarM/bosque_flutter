import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/validadores_comision.dart';
import 'package:bosque_flutter/domain/entities/comision_por_rango_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Alta y modificación de un tramo de comisión por días de cobro.
///
/// El porcentaje se pide en puntos porcentuales, que es como lo piensa el
/// usuario, y se convierte a base 1 al guardar, que es como lo almacena esta
/// tabla en particular. Es la única pantalla del módulo que hace esa conversión:
/// los grupos guardan directamente puntos porcentuales.
class DialogoRango extends ConsumerStatefulWidget {
  const DialogoRango({super.key, this.rango});

  final ComisionPorRangoEntity? rango;

  @override
  ConsumerState<DialogoRango> createState() => _DialogoRangoState();
}

class _DialogoRangoState extends ConsumerState<DialogoRango> {
  final _formulario = GlobalKey<FormState>();

  late final TextEditingController _porcentaje;
  late final TextEditingController _min;
  late final TextEditingController _max;

  late String _tipo;
  late int _esInterno;
  String? _errorGeneral;

  bool get _esEdicion => widget.rango != null;

  static const _tipos = ['Contado', 'Credito'];

  @override
  void initState() {
    super.initState();
    final r = widget.rango;
    _porcentaje = TextEditingController(
      text: r != null ? r.comisionVisual.toStringAsFixed(4) : '',
    );
    _min = TextEditingController(text: r?.min.toString() ?? '');
    _max = TextEditingController(text: r?.max.toString() ?? '');
    _tipo = r?.tipo ?? _tipos.first;
    _esInterno = r?.esInterno ?? 1;
  }

  @override
  void dispose() {
    _porcentaje.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(comisionesAccionesProvider);
    final ancho = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      title: Text(_esEdicion ? 'Editar tramo' : 'Nuevo tramo'),
      content: SizedBox(
        width: ancho < 600 ? ancho * 0.9 : 480,
        child: Form(
          key: _formulario,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Si el cobro cae dentro de este rango de días, se paga este '
                  'porcentaje.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de venta',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final t in _tipos)
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(() => _tipo = v ?? _tipo),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _min,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Desde (días)',
                          helperText: 'Negativo = anticipado',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => _entero(v, 'el día inicial'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _max,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hasta (días)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => _entero(v, 'el día final'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _porcentaje,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: ValidadoresComision.decimal4,
                  decoration: const InputDecoration(
                    labelText: 'Comisión',
                    suffixText: '%',
                    helperText: 'Escriba 0,8 para 0,8%',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidadoresComision.porcentaje,
                ),
                const SizedBox(height: 20),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Internos')),
                    ButtonSegment(value: 0, label: Text('Externos')),
                  ],
                  selected: {_esInterno},
                  showSelectedIcon: false,
                  onSelectionChanged:
                      (s) => setState(() => _esInterno = s.first),
                ),
                if (_errorGeneral != null) ...[
                  const SizedBox(height: 14),
                  AvisoError(mensaje: _errorGeneral!),
                ],
                if (estado.huboError) ...[
                  const SizedBox(height: 14),
                  AvisoError(mensaje: estado.error!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: estado.enProceso ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: estado.enProceso ? null : _guardar,
          child:
              estado.enProceso
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(_esEdicion ? 'Guardar cambios' : 'Crear tramo'),
        ),
      ],
    );
  }

  static String? _entero(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) return 'Ingrese $campo.';
    if (int.tryParse(valor.trim()) == null) {
      return 'Ingrese $campo como número entero.';
    }
    return null;
  }

  Future<void> _guardar() async {
    setState(() => _errorGeneral = null);

    if (!_formulario.currentState!.validate()) return;

    final min = int.parse(_min.text.trim());
    final max = int.parse(_max.text.trim());
    if (min > max) {
      setState(
        () => _errorGeneral = 'El día inicial no puede ser mayor que el final.',
      );
      return;
    }

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final visual = ValidadoresComision.aDouble(_porcentaje.text) ?? 0;

    final entidad = ComisionPorRangoEntity(
      idCfr: widget.rango?.idCfr ?? BigInt.zero,
      // Esta tabla guarda base 1, de ahí la división.
      comision: visual / 100,
      comisionVisual: visual,
      min: min,
      max: max,
      tipo: _tipo,
      esInterno: _esInterno,
      audUsuario: BigInt.from(uid),
    );

    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .guardarRango(entidad);

    if (!mounted || !ok) return;

    Navigator.pop(context);
    avisar(context, _esEdicion ? 'Tramo actualizado.' : 'Tramo creado.');
  }
}
