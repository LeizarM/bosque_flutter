/// Los diálogos de Niveles jerárquicos: alta, nueva vigencia de un nivel,
/// edición y baja. Las reglas (montos, duplicados, cargos que la usan) y los
/// textos los pone `p_abm_NivelJerarquico`; aquí solo se muestran.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/nivel_jerarquico_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/formato_moneda.dart';
import 'package:bosque_flutter/domain/entities/nivel_jerarquico_entity.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';

/// Qué se está haciendo con el formulario.
enum ModoEscala { alta, nuevaVigencia, edicion }

/// Con [base] null es un alta. Con una escala: su edición o, con
/// [ModoEscala.nuevaVigencia], una escala nueva del mismo nivel desde hoy.
Future<void> abrirFormularioEscala(
  BuildContext context, {
  NivelJerarquicoEntity? base,
  ModoEscala modo = ModoEscala.alta,
}) {
  ProviderScope.containerOf(
    context,
  ).read(operacionesNivelJerarquicoProvider.notifier).limpiarError();
  return abrirFormularioParametro<void>(
    context,
    contenido: (_) => _FormularioEscala(base: base, modo: modo),
  );
}

class _FormularioEscala extends ConsumerStatefulWidget {
  const _FormularioEscala({required this.base, required this.modo});

  final NivelJerarquicoEntity? base;
  final ModoEscala modo;

  @override
  ConsumerState<_FormularioEscala> createState() => _FormularioEscalaState();
}

class _FormularioEscalaState extends ConsumerState<_FormularioEscala> {
  late final _nivel = TextEditingController(
    text: widget.base == null ? '' : '${widget.base!.nivel}',
  );
  late final _haber = TextEditingController(
    text: widget.base == null ? '' : _texto(widget.base!.haberBasico),
  );
  late final _bono = TextEditingController(
    text: widget.base == null ? '' : _texto(widget.base!.bonoProduccion),
  );
  late DateTime _fecha =
      widget.modo == ModoEscala.edicion ? widget.base!.fecha : _hoy();

  static DateTime _hoy() {
    final h = DateTime.now();
    return DateTime(h.year, h.month, h.day);
  }

  static String _texto(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Un monto escrito con coma o punto; vacío o inválido llega como 0 y el SP
  /// explica qué falta.
  static double _monto(String t) =>
      double.tryParse(t.trim().replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _nivel.dispose();
    _haber.dispose();
    _bono.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final edicion = widget.modo == ModoEscala.edicion;
    final escala = NivelJerarquicoEntity(
      codNivel: edicion ? widget.base!.codNivel : 0,
      nivel: int.tryParse(_nivel.text.trim()) ?? 0,
      haberBasico: _monto(_haber.text),
      bonoProduccion: _monto(_bono.text),
      fecha: _fecha,
      audUsuario: 0,
      activo: 0,
    );
    final r = await ref
        .read(operacionesNivelJerarquicoProvider.notifier)
        .ejecutar(
          () => ref.read(nivelJerarquicoRepoProvider).registrar(escala),
        );
    if (r == null || !mounted) return;
    avisar(context, r.mensaje);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(operacionesNivelJerarquicoProvider);
    final b = widget.base;
    final (titulo, subtitulo) = switch (widget.modo) {
      ModoEscala.alta => (
        'Nueva escala',
        'Un nivel con su haber básico y el bono de producción.',
      ),
      ModoEscala.nuevaVigencia => (
        'Nueva vigencia del nivel ${b!.nivel}',
        'La escala actual (${FormatoMoneda.bs(b.haberBasico)}) queda como '
            'anterior desde la fecha que elijas.',
      ),
      ModoEscala.edicion => (
        'Editar escala del nivel ${b!.nivel}',
        'La usan ${b.cargos} cargos: el cambio se ve en todos.',
      ),
    };

    final montos = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      LengthLimitingTextInputFormatter(9),
    ];

    return PanelParametro(
      titulo: titulo,
      subtitulo: subtitulo,
      ocupado: estado.ocupado,
      errorServidor: estado.error,
      etiquetaGuardar:
          widget.modo == ModoEscala.edicion ? 'Guardar cambios' : 'Registrar',
      onGuardar: _guardar,
      campos: [
        TextField(
          key: const ValueKey('campo-nivel'),
          controller: _nivel,
          autofocus: widget.modo == ModoEscala.alta,
          // En una nueva vigencia el nivel es el mismo: no se cambia.
          readOnly: widget.modo == ModoEscala.nuevaVigencia,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: const InputDecoration(
            labelText: 'Nivel',
            border: OutlineInputBorder(),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            Widget campo(String clave, String etiqueta, TextEditingController t) =>
                TextField(
                  key: ValueKey(clave),
                  controller: t,
                  autofocus:
                      clave == 'campo-haber' && widget.modo != ModoEscala.alta,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: montos,
                  decoration: InputDecoration(
                    labelText: etiqueta,
                    border: const OutlineInputBorder(),
                  ),
                );
            final haber = campo('campo-haber', 'Haber básico (Bs)', _haber);
            final bono = campo('campo-bono', 'Bono de producción (Bs)', _bono);
            // Dos columnas solo si cada campo tiene al menos 200 px.
            if (c.maxWidth >= 412) {
              return Row(
                children: [
                  Expanded(child: haber),
                  const SizedBox(width: Esp.m),
                  Expanded(child: bono),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [haber, const SizedBox(height: Esp.l), bono],
            );
          },
        ),
        CampoFechaCheque(
          etiqueta: 'Rige desde',
          valor: _fecha,
          onCambio: (f) {
            if (f != null) setState(() => _fecha = f);
          },
        ),
      ],
    );
  }
}

/// Confirma y da de baja la escala. Si la usan cargos, el servidor lo rechaza
/// y su texto se lee completo.
Future<void> eliminarEscala(
  BuildContext context,
  WidgetRef ref,
  NivelJerarquicoEntity escala,
) {
  final ops = ref.read(operacionesNivelJerarquicoProvider.notifier);
  return eliminarDeCatalogo(
    context,
    titulo: '¿Eliminar la escala del nivel ${escala.nivel}?',
    detalle:
        'Se elimina la escala que rige desde el ${textoFecha(escala.fecha)} '
        '(${FormatoMoneda.bs(escala.haberBasico)}). Si algún cargo la usa, '
        'no se podrá eliminar.',
    textoConfirmar: 'Eliminar escala',
    operaciones: ops,
    errorActual: () => ref.read(operacionesNivelJerarquicoProvider).error,
    eliminar:
        () => ref.read(nivelJerarquicoRepoProvider).eliminar(escala.codNivel),
  );
}
