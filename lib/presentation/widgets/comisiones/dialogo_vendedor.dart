import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/comisiones_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/validadores_comision.dart';
import 'package:bosque_flutter/domain/entities/vendedor_comision_entity.dart';
import 'package:bosque_flutter/presentation/widgets/comisiones/comisiones_tema.dart';

/// Alta y modificacion de un vendedor y de sus codigos en cada empresa SAP.
///
/// Los cinco codigos son opcionales por separado, pero al menos uno debe
/// cargarse: un vendedor sin codigo no aparece en ninguna venta.
class DialogoVendedor extends ConsumerStatefulWidget {
  const DialogoVendedor({super.key, this.vendedor});

  final VendedorComisionEntity? vendedor;

  @override
  ConsumerState<DialogoVendedor> createState() => _DialogoVendedorState();
}

class _DialogoVendedorState extends ConsumerState<DialogoVendedor> {
  final _formulario = GlobalKey<FormState>();

  late final TextEditingController _nombre;
  late final TextEditingController _comision;
  late final Map<String, TextEditingController> _codigos;

  late int _esInterno;
  String? _errorCodigos;

  bool get _esEdicion => widget.vendedor != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vendedor;
    _nombre = TextEditingController(text: v?.nomVenSap ?? '');
    _comision = TextEditingController(
      text: v != null ? ValidadoresComision.aTextoPorcentaje(v.comision) : '',
    );
    _esInterno = v?.esInterno ?? 1;
    _codigos = {
      'PAPIRUS': TextEditingController(text: _texto(v?.codVenPapirus)),
      'IMPEXPAP': TextEditingController(text: _texto(v?.codVenImpexpap)),
      'PAPELBOL': TextEditingController(text: _texto(v?.codVenPapelbol)),
      'ESPPAPEL': TextEditingController(text: _texto(v?.codVenEsppapel)),
      'PRODPAP': TextEditingController(text: _texto(v?.codVenProdpap)),
    };
  }

  static String _texto(int? valor) =>
      (valor == null || valor == 0) ? '' : valor.toString();

  @override
  void dispose() {
    _nombre.dispose();
    _comision.dispose();
    for (final c in _codigos.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(comisionesAccionesProvider);
    final ancho = MediaQuery.sizeOf(context).width;
    final anchoDialogo = ancho < 600 ? ancho * 0.9 : 520.0;

    return AlertDialog(
      title: Text(_esEdicion ? 'Editar vendedor' : 'Nuevo vendedor'),
      content: SizedBox(
        width: anchoDialogo,
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
                    labelText: 'Nombre del vendedor',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) => ValidadoresComision.nombre(v, campo: 'el nombre'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _comision,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: ValidadoresComision.decimal4,
                  decoration: const InputDecoration(
                    labelText: 'Comision base',
                    suffixText: '%',
                    helperText:
                        'Se usa cuando el grupo no define un porcentaje.',
                    border: OutlineInputBorder(),
                  ),
                  validator: ValidadoresComision.porcentaje,
                ),
                const SizedBox(height: 20),
                Text(
                  'Tipo de vendedor',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Interno')),
                    ButtonSegment(value: 0, label: Text('Externo')),
                  ],
                  selected: {_esInterno},
                  showSelectedIcon: false,
                  onSelectionChanged:
                      (s) => setState(() => _esInterno = s.first),
                ),
                const SizedBox(height: 24),
                _TituloSeccion(
                  titulo: 'Codigos en SAP',
                  detalle:
                      'Complete el codigo en cada empresa donde el vendedor factura.',
                ),
                const SizedBox(height: 12),
                for (final entrada in _codigos.entries) ...[
                  TextFormField(
                    controller: entrada.value,
                    keyboardType: TextInputType.number,
                    inputFormatters: ValidadoresComision.soloEnteros,
                    decoration: InputDecoration(
                      labelText: entrada.key,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => ValidadoresComision.codigoSap(v),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_errorCodigos != null) AvisoError(mensaje: _errorCodigos!),
                if (estado.huboError) ...[
                  const SizedBox(height: 12),
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
                  : Text(_esEdicion ? 'Guardar cambios' : 'Crear vendedor'),
        ),
      ],
    );
  }

  int? _leer(String sigla) {
    final texto = _codigos[sigla]!.text.trim();
    if (texto.isEmpty) return null;
    return int.tryParse(texto);
  }

  Future<void> _guardar() async {
    setState(() => _errorCodigos = null);

    if (!_formulario.currentState!.validate()) return;

    final cargados = _codigos.keys.where((k) => _leer(k) != null).toList();
    if (cargados.isEmpty) {
      setState(
        () =>
            _errorCodigos =
                'Cargue al menos un codigo SAP: sin el, el vendedor no aparece en ninguna venta.',
      );
      return;
    }

    final uid = ref.read(userProvider)?.codUsuario ?? 0;
    final entidad = VendedorComisionEntity(
      idVendedor: widget.vendedor?.idVendedor ?? BigInt.zero,
      nomVenSap: _nombre.text.trim(),
      comision: ValidadoresComision.aPuntosPorcentuales(_comision.text),
      esInterno: _esInterno,
      activo: 1,
      audUsuario: BigInt.from(uid),
      codVenPapirus: _leer('PAPIRUS'),
      codVenImpexpap: _leer('IMPEXPAP'),
      codVenPapelbol: _leer('PAPELBOL'),
      codVenEsppapel: _leer('ESPPAPEL'),
      codVenProdpap: _leer('PRODPAP'),
    );

    final ok = await ref
        .read(comisionesAccionesProvider.notifier)
        .guardarVendedor(entidad);

    if (!mounted || !ok) return;

    Navigator.pop(context);
    avisar(context, _esEdicion ? 'Vendedor actualizado.' : 'Vendedor creado.');
  }
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({required this.titulo, required this.detalle});

  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          detalle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
