import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/rrhh_provider.dart';
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
/// **Tipo, número, observación y empresa son editables.** El rango de folios y
/// el costo no: `p_abm_tmto_Talonario` con `ACCION='U'` los ignora a propósito,
/// porque cambiarlos en un talonario que ya circuló invalidaría su historial
/// de eventos —y el wizard viejo ya los tenía comentados, por lo mismo.
///
/// Esos datos se muestran igual, en solo lectura y con el motivo escrito:
/// esconderlos deja a quien mira preguntándose dónde están.
///
/// La empresa va por `ACCION='E'`, aparte del `U`: mueve los recibos de SAP.
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
  late BigInt _codEmpresa = widget.talonario.codEmpresa;
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
    var datosGuardados = false;
    try {
      final t = widget.talonario;
      final repo = ref.read(talonariosRepositoryProvider);
      final aud = BigInt.from(ref.read(userProvider)?.codUsuario ?? 0);

      await repo.registrarTalonario(
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
          audUsuario: aud,
        ),
      );
      datosGuardados = true;

      // Después del UPDATE y no antes: su falla probable es un número repetido,
      // y así ese error no deja la empresa ya cambiada. Si falla esta, el
      // reintento es seguro: ambas llamadas repiten sin efecto.
      if (_codEmpresa != t.codEmpresa) {
        await repo.cambiarEmpresaLote(
          codTalonarios: [t.codTalonario],
          codEmpresa: _codEmpresa,
          audUsuario: aud,
        );
      }
      if (!mounted) return;
      refrescarTalonarios(ref);
      Navigator.pop(context);
      mostrarAviso(context, 'Talonario ${_nro.text} actualizado');
    } catch (e) {
      // Se queda abierto con todo intacto: el error más probable es un
      // nroTalonario repetido, y perder el formulario por eso sería absurdo.
      // Si el UPDATE ya entró, el listado se refresca igual: lo que muestra
      // detrás ya no es lo que hay.
      if (!mounted) return;
      if (datosGuardados) refrescarTalonarios(ref);
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
    final empresas = ref.watch(empresasProvider);
    // Sin entregas no hay recibos emitidos que mover en SAP.
    final avisaSap = _codEmpresa != t.codEmpresa && t.entregas > 0;

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

                empresas.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error:
                      (e, _) => MensajeError(
                        error: e,
                        compacto: true,
                        onReintentar:
                            () => ref.read(empresasProvider.notifier).refresh(),
                      ),
                  data:
                      (lista) => ComboBuscable<int>(
                        etiqueta: 'Empresa',
                        valor: _codEmpresa.toInt(),
                        opciones:
                            lista
                                .map(
                                  (e) => DropdownMenuEntry(
                                    value: e.codEmpresa,
                                    label: e.nombre,
                                  ),
                                )
                                .toList(),
                        ayuda:
                            avisaSap
                                ? 'Sus recibos emitidos pasan al reporte de '
                                    'SAP de la otra empresa.'
                                : null,
                        onElegir:
                            (v) => setState(
                              () =>
                                  _codEmpresa =
                                      v == null ? _codEmpresa : BigInt.from(v),
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
          _dato('Estado', t.estadoActual),
          const SizedBox(height: Esp.s),
          Text(
            'El rango de folios y el costo no se modifican: este talonario ya '
            'tiene $movimientos movimientos registrados y cambiarlos '
            'invalidaría su historial.',
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
