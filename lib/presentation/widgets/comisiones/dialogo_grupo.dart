import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/validadores_comision.dart';
import 'package:bosque_flutter/domain/entities/grupo_comision_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Alta y modificacion de un grupo de comision.
///
/// El porcentaje se pide y se guarda en puntos porcentuales, igual que la
/// tabla: escribir 0,7 significa 0,7%. No hay conversion de por medio.
class DialogoGrupo extends ConsumerStatefulWidget {
  const DialogoGrupo({super.key, this.grupo});

  final GrupoComisionEntity? grupo;

  @override
  ConsumerState<DialogoGrupo> createState() => _DialogoGrupoState();
}

class _DialogoGrupoState extends ConsumerState<DialogoGrupo> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _porcentaje;

  late int _esInterno;
  late int _esParaVenta;

  bool get _esEdicion => widget.grupo != null;

  @override
  void initState() {
    super.initState();
    final g = widget.grupo;
    _nombre = TextEditingController(text: g?.grupo ?? '');
    _porcentaje = TextEditingController(
      text: g != null ? ValidadoresComision.aTextoPorcentaje(g.porcentaje) : '',
    );
    _esInterno = g?.esInterno ?? 1;
    _esParaVenta = g?.esParaVenta ?? 1;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _porcentaje.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(comisionesAccionesProvider);
    final anchoMaximo = MediaQuery.sizeOf(context).width < 560 ? 420.0 : 480.0;

    return AlertDialog(
      title: Text(_esEdicion ? 'Editar grupo' : 'Nuevo grupo'),
      content: SizedBox(
        width: anchoMaximo,
        child: Form(
          key: _formulario,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: ValidadoresComision.textoNombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del grupo',
                    hintText: 'Por ejemplo: PAPELERIA MAYORISTA',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => ValidadoresComision.nombre(v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _porcentaje,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: ValidadoresComision.decimal4,
                  decoration: const InputDecoration(
                    labelText: 'Porcentaje de comision',
                    suffixText: '%',
                    helperText: 'Puntos porcentuales. Escriba 0,7 para 0,7%.',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidadoresComision.porcentaje,
                ),
                const SizedBox(height: 20),
                _Selector(
                  etiqueta: 'Tipo de vendedor',
                  valor: _esInterno,
                  opciones: const {1: 'Interno', 0: 'Externo'},
                  alCambiar: (v) => setState(() => _esInterno = v),
                ),
                const SizedBox(height: 14),
                _Selector(
                  etiqueta: 'Se aplica sobre',
                  valor: _esParaVenta,
                  opciones: const {1: 'Venta', 0: 'Cobranza'},
                  alCambiar: (v) => setState(() => _esParaVenta = v),
                ),
                if (estado.huboError) ...[
                  const SizedBox(height: 16),
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
                  : Text(_esEdicion ? 'Guardar cambios' : 'Crear grupo'),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final entidad = GrupoComisionEntity(
      idGrupo: widget.grupo?.idGrupo ?? BigInt.zero,
      grupo: _nombre.text.trim(),
      porcentaje: ValidadoresComision.aPuntosPorcentuales(_porcentaje.text),
      esParaVenta: _esParaVenta,
      esInterno: _esInterno,
      bd: widget.grupo?.bd,
      siglaEmpresa: widget.grupo?.siglaEmpresa ?? '',
      activo: 1,
      audUsuario: BigInt.from(uid),
    );

    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .guardarGrupo(entidad);

    if (!mounted || !ok) return;

    Navigator.pop(context);
    avisar(context, _esEdicion ? 'Grupo actualizado.' : 'Grupo creado.');
  }
}

/// Selector binario en forma de segmentos. Mas legible que un switch cuando las
/// dos opciones tienen nombre propio.
class _Selector extends StatelessWidget {
  const _Selector({
    required this.etiqueta,
    required this.valor,
    required this.opciones,
    required this.alCambiar,
  });

  final String etiqueta;
  final int valor;
  final Map<int, String> opciones;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (final e in opciones.entries)
              ButtonSegment(value: e.key, label: Text(e.value)),
          ],
          selected: {valor},
          showSelectedIcon: false,
          onSelectionChanged: (s) => alCambiar(s.first),
        ),
      ],
    );
  }
}
