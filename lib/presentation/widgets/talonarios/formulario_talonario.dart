import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/talonarios_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/talonario_entity.dart';

/// Edita un talonario suelto.
///
/// **Solo tres campos son editables**, y no es una decisión de esta pantalla:
/// `p_abm_tmto_Talonario` con `ACCION='U'` ignora a propósito `costoBs`,
/// `numeracionInicial`, `numeracionFinal` y `codEmpresa`. Cambiar el rango de
/// folios de un talonario que ya circuló invalidaría su historial de eventos
/// —y el wizard viejo ya los tenía comentados, por lo mismo.
///
/// Esos datos se muestran igual, en solo lectura y con el motivo escrito:
/// esconderlos deja a quien mira preguntándose dónde están.
class FormularioTalonario extends ConsumerStatefulWidget {
  const FormularioTalonario({super.key, required this.talonario});

  final TalonarioEntity talonario;

  @override
  ConsumerState<FormularioTalonario> createState() =>
      _FormularioTalonarioState();
}

class _FormularioTalonarioState extends ConsumerState<FormularioTalonario> {
  final _formKey = GlobalKey<FormState>();
  late BigInt _codTipoRecibo = widget.talonario.codTipoRecibo;
  late final _nro = TextEditingController(text: widget.talonario.nroTalonario);
  late final _observacion = TextEditingController(
    text: widget.talonario.observacion,
  );

  bool _ocupado = false;
  Object? _error;

  @override
  void dispose() {
    _nro.dispose();
    _observacion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final t = widget.talonario;
      await ref
          .read(talonariosRepositoryProvider)
          .registrarTalonario(
            TalonarioEntity(
              codTalonario: t.codTalonario,
              codTipoRecibo: _codTipoRecibo,
              nroTalonario: _nro.text.trim(),
              // Van los valores actuales: el SP los ignora en el UPDATE, pero
              // mandar ceros sería mentirle al modelo.
              costoBs: t.costoBs,
              numeracionInicial: t.numeracionInicial,
              numeracionFinal: t.numeracionFinal,
              estado: t.estado,
              codEmpresa: t.codEmpresa,
              observacion: _observacion.text.trim(),
              audUsuario: BigInt.from(ref.read(userProvider)?.codUsuario ?? 0),
            ),
          );
      if (!mounted) return;
      refrescarTalonarios(ref);
      Navigator.pop(context);
      mostrarAviso(context, 'Talonario ${_nro.text} actualizado');
    } catch (e) {
      // Se queda abierto con todo intacto: el error más probable es un
      // nroTalonario repetido, y perder el formulario por eso sería absurdo.
      if (!mounted) return;
      setState(() {
        _error = e;
        _ocupado = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.talonario;
    final tipos = ref.watch(tiposReciboProvider);

    return AlertDialog(
      title: Text('Editar ${t.nroTalonario}'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  MensajeError(error: _error, compacto: true),
                  const SizedBox(height: Esp.m),
                ],

                tipos.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error:
                      (e, _) => MensajeError(
                        error: e,
                        compacto: true,
                        onReintentar: () => ref.invalidate(tiposReciboProvider),
                      ),
                  data:
                      (lista) => ComboBuscable<BigInt>(
                        etiqueta: 'Tipo de recibo',
                        valor: _codTipoRecibo,
                        opciones:
                            lista
                                .map(
                                  (x) => DropdownMenuEntry(
                                    value: x.codTipoRecibo,
                                    label: '${x.sigla} — ${x.nombre}',
                                  ),
                                )
                                .toList(),
                        onElegir:
                            (v) => setState(
                              () => _codTipoRecibo = v ?? _codTipoRecibo,
                            ),
                      ),
                ),
                const SizedBox(height: Esp.m),

                TextFormField(
                  controller: _nro,
                  enabled: !_ocupado,
                  maxLength: 20,
                  style: const TextStyle(fontFeatures: cifrasTabulares),
                  decoration: const InputDecoration(
                    labelText: 'Número de talonario *',
                    helperText: 'Es único en todo el sistema',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'El número es obligatorio'
                              : null,
                ),
                const SizedBox(height: Esp.m),

                TextFormField(
                  controller: _observacion,
                  enabled: !_ocupado,
                  maxLength: 250,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Observación',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: Esp.s),
                _soloLectura(t),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _ocupado ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Guardar',
          etiquetaOcupado: 'Guardando…',
          ocupado: _ocupado,
          onPressed: _guardar,
        ),
      ],
    );
  }

  /// Lo que no se puede tocar, y por qué.
  Widget _soloLectura(TalonarioEntity t) {
    final movimientos = t.entregas + t.devoluciones + t.cierres + 1;
    return Container(
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 15,
                color: context.cs.onSurfaceVariant,
              ),
              const SizedBox(width: Esp.s),
              Text('No editable', style: context.tituloSeccion()),
            ],
          ),
          const SizedBox(height: Esp.s),
          _dato('Folios', '${t.numeracionInicial} – ${t.numeracionFinal}'),
          _dato('Costo', 'Bs ${t.costoBs.toStringAsFixed(2)}'),
          _dato('Empresa', t.datoEmpresa.isEmpty ? '—' : t.datoEmpresa),
          _dato('Estado', t.estadoActual),
          const SizedBox(height: Esp.s),
          Text(
            'El rango de folios, el costo y la empresa no se modifican: este '
            'talonario ya tiene $movimientos movimientos registrados y '
            'cambiarlos invalidaría su historial.',
            style: context.apagado(),
          ),
        ],
      ),
    );
  }

  Widget _dato(String etiqueta, String valor) => Padding(
    padding: const EdgeInsets.only(bottom: Esp.xs),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(etiqueta, style: context.apagado())),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontFeatures: cifrasTabulares),
          ),
        ),
      ],
    ),
  );
}
