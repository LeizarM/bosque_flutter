import 'package:bosque_flutter/core/state/dias_no_laborables_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/data/repositories/dias_no_laborables_impl.dart';
import 'package:bosque_flutter/domain/entities/dia_no_laborable_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Modal de alta/edicion de un Dia No Laborable.
///
/// Si no se marca ninguna sucursal, el registro queda como feriado GLOBAL
/// (aplica a toda la empresa) — asi lo resuelve el SP p_abm_rrhh_DiaNoLaborable.
class DialogoDiaNoLaborable extends ConsumerStatefulWidget {
  final int gestion;
  final int audUsuario;
  final DiaNoLaborableEntity? editar;

  /// false cuando se muestra dentro de un [Dialog] centrado (tablet/desktop):
  /// ese contenedor no se arrastra, asi que el asa de bottom-sheet sobraria.
  final bool mostrarAsa;

  const DialogoDiaNoLaborable({
    super.key,
    required this.gestion,
    required this.audUsuario,
    this.editar,
    this.mostrarAsa = true,
  });

  @override
  ConsumerState<DialogoDiaNoLaborable> createState() =>
      _DialogoDiaNoLaborableState();
}

class _DialogoDiaNoLaborableState
    extends ConsumerState<DialogoDiaNoLaborable> {
  final _formKey = GlobalKey<FormState>();
  final _motivoCtrl = TextEditingController();
  late DateTime _fecha;
  bool _cargando = false;

  /// null hasta que llega la matriz de sucursales; luego se inicializa UNA
  /// sola vez con lo que devuelve el backend (todas en false si es alta nueva).
  Map<BigInt, bool>? _seleccion;

  BigInt get _idEditar => widget.editar?.idDiaNoLaborable ?? BigInt.zero;

  @override
  void initState() {
    super.initState();
    _fecha = widget.editar?.fecha ?? DateTime.now();
    _motivoCtrl.text = widget.editar?.motivo ?? '';
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() => _fecha = picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    final seleccionadas =
        _seleccion?.entries.where((e) => e.value).map((e) => e.key).toList() ??
        [];
    final sucursalesCsv = seleccionadas.isEmpty
        ? null
        : seleccionadas.map((id) => id.toInt()).join(',');

    final payload = <String, dynamic>{
      'idDiaNoLaborable': _idEditar.toInt(),
      'fecha':
          '${_fecha.year.toString().padLeft(4, '0')}-'
          '${_fecha.month.toString().padLeft(2, '0')}-'
          '${_fecha.day.toString().padLeft(2, '0')}',
      'motivo': _motivoCtrl.text.trim(),
      'sucursales': sucursalesCsv,
      'audUsuario': widget.audUsuario,
    };

    try {
      final repo = DiasNoLaborablesImpl();
      await repo.registrarDiaNoLaborable(payload);
      if (!mounted) return;
      ref.invalidate(diasNoLaborablesProvider(widget.gestion));
      Navigator.of(context).pop();
      mostrarAviso(context, 'Dia no laborable guardado exitosamente');
    } catch (e) {
      if (!mounted) return;
      mostrarAviso(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        tono: TonoAviso.error,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('dd/MM/yyyy');
    final asyncSucursales = ref.watch(
      sucursalesDiaNoLaborableProvider(_idEditar),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mostrarAsa)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Text(
              widget.editar != null
                  ? 'Editar dia no laborable'
                  : 'Nuevo dia no laborable',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            // Fecha
            InkWell(
              onTap: _elegirFecha,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                ),
                child: Text(df.format(_fecha)),
              ),
            ),
            const SizedBox(height: 10),

            // Motivo
            TextFormField(
              controller: _motivoCtrl,
              maxLength: 50,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                hintText: 'Ej: Navidad',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El motivo es requerido'
                  : null,
            ),
            const SizedBox(height: 6),

            // Sucursales afectadas
            Text(
              'Aplica a:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: cs.onSurface,
              ),
            ),
            Text(
              'Si no marcás ninguna sucursal, el feriado aplica a TODA la empresa.',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            asyncSucursales.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Text(
                'Error cargando sucursales: $e',
                style: TextStyle(color: cs.error, fontSize: 12),
              ),
              data: (sucursales) {
                _seleccion ??= {
                  for (final s in sucursales) s.codSucursal: s.seleccionado,
                };
                return Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _seleccion!.updateAll((_, __) => true);
                            }),
                            child: const Text('Marcar todas'),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _seleccion!.updateAll((_, __) => false);
                            }),
                            child: const Text('Ninguna (global)'),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: sucursales
                              .map(
                                (s) => CheckboxListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(
                                    s.nombreSucEmpresa,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  value: _seleccion![s.codSucursal] ?? false,
                                  onChanged: (v) => setState(() {
                                    _seleccion![s.codSucursal] = v ?? false;
                                  }),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cargando
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _cargando ? null : _guardar,
                    child: _cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
