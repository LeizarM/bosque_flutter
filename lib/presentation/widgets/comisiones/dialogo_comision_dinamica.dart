import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';

import 'package:bosque_flutter/core/utils/formato_comision.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/validadores_comision.dart';
import 'package:bosque_flutter/domain/entities/comision_dinamica_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Alta y modificacion de una escala de comision por meta.
class DialogoComisionDinamica extends ConsumerStatefulWidget {
  const DialogoComisionDinamica({super.key, this.escala});

  final ComisionDinamicaEntity? escala;

  @override
  ConsumerState<DialogoComisionDinamica> createState() =>
      _DialogoComisionDinamicaState();
}

class _DialogoComisionDinamicaState
    extends ConsumerState<DialogoComisionDinamica> {
  final _formulario = GlobalKey<FormState>();
  final _fmt = FormatoComision.fecha;

  late final TextEditingController _metaUsd;
  late final TextEditingController _metaBs;
  late final TextEditingController _porcentaje;

  late int _esInterno;
  late DateTime _desde;
  DateTime? _hasta;
  String? _errorGeneral;

  bool get _esEdicion => widget.escala != null;

  @override
  void initState() {
    super.initState();
    final e = widget.escala;
    _metaUsd = TextEditingController(
      text: (e != null && e.metaUsd > 0) ? e.metaUsd.toStringAsFixed(2) : '',
    );
    _metaBs = TextEditingController(
      text: (e != null && e.metaBs > 0) ? e.metaBs.toStringAsFixed(2) : '',
    );
    _porcentaje = TextEditingController(
      text: e != null ? ValidadoresComision.aTextoPorcentaje(e.porcentaje) : '',
    );
    _esInterno = e?.esInterno ?? 1;
    _desde = e?.vigenteDesde ?? DateTime.now();
    _hasta = e?.vigenteHasta;
  }

  @override
  void dispose() {
    _metaUsd.dispose();
    _metaBs.dispose();
    _porcentaje.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(comisionesAccionesProvider);
    final ancho = MediaQuery.sizeOf(context).width;

    return AlertDialog(
      title: Text(_esEdicion ? 'Editar escala' : 'Nueva escala'),
      content: SizedBox(
        width: ancho < 600 ? ancho * 0.9 : 500,
        child: Form(
          key: _formulario,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Al alcanzar la meta, la comision pasa a este porcentaje.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _metaUsd,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: ValidadoresComision.decimal2,
                        decoration: const InputDecoration(
                          labelText: 'Meta USD',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) => ValidadoresComision.monto(
                              v,
                              obligatorio: false,
                              campo: 'la meta en USD',
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _metaBs,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: ValidadoresComision.decimal2,
                        decoration: const InputDecoration(
                          labelText: 'Meta BS',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) => ValidadoresComision.monto(
                              v,
                              obligatorio: false,
                              campo: 'la meta en BS',
                            ),
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
                    labelText: 'Porcentaje al alcanzar la meta',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidadoresComision.porcentaje,
                ),
                const SizedBox(height: 20),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Interna')),
                    ButtonSegment(value: 0, label: Text('Externa')),
                  ],
                  selected: {_esInterno},
                  showSelectedIcon: false,
                  onSelectionChanged:
                      (s) => setState(() => _esInterno = s.first),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _CampoFecha(
                        etiqueta: 'Vigente desde',
                        valor: _desde,
                        texto: _fmt.format(_desde),
                        alElegir: (f) => setState(() => _desde = f),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CampoFecha(
                        etiqueta: 'Vigente hasta',
                        valor: _hasta,
                        texto:
                            _hasta == null
                                ? 'Sin limite'
                                : _fmt.format(_hasta!),
                        alElegir: (f) => setState(() => _hasta = f),
                        alLimpiar: () => setState(() => _hasta = null),
                      ),
                    ),
                  ],
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
                  : Text(_esEdicion ? 'Guardar cambios' : 'Crear escala'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _errorGeneral = null);

    if (!_formulario.currentState!.validate()) return;

    final errorMeta = ValidadoresComision.algunaMeta(
      _metaUsd.text,
      _metaBs.text,
    );
    if (errorMeta != null) {
      setState(() => _errorGeneral = errorMeta);
      return;
    }

    final errorFechas = ValidadoresComision.rangoFechas(_desde, _hasta);
    if (errorFechas != null) {
      setState(() => _errorGeneral = errorFechas);
      return;
    }

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final entidad = ComisionDinamicaEntity(
      idDc: widget.escala?.idDc ?? BigInt.zero,
      esInterno: _esInterno,
      metaUsd: ValidadoresComision.aDouble(_metaUsd.text) ?? 0,
      metaBs: ValidadoresComision.aDouble(_metaBs.text) ?? 0,
      porcentaje: ValidadoresComision.aPuntosPorcentuales(_porcentaje.text),
      vigenteDesde: _desde,
      vigenteHasta: _hasta,
      audUsuario: BigInt.from(uid),
    );

    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .guardarComisionDinamica(entidad);

    if (!mounted || !ok) return;

    Navigator.pop(context);
    avisar(context, _esEdicion ? 'Escala actualizada.' : 'Escala creada.');
  }
}

class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.etiqueta,
    required this.valor,
    required this.texto,
    required this.alElegir,
    this.alLimpiar,
  });

  final String etiqueta;
  final DateTime? valor;
  final String texto;
  final ValueChanged<DateTime> alElegir;
  final VoidCallback? alLimpiar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final elegida = await showDatePicker(
          context: context,
          initialDate: valor ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (elegida != null) alElegir(elegida);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon:
              (alLimpiar != null && valor != null)
                  ? IconButton(
                    tooltip: 'Quitar limite',
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: alLimpiar,
                  )
                  : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(texto),
      ),
    );
  }
}
