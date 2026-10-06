/// Los dialogos de la pantalla de Bancos: el formulario de alta y edicion (un
/// solo campo, el nombre) y la baja con su confirmacion.
///
/// El nombre se valida aqui como el servidor (`ReglasCheque.errorNombreBanco`,
/// el regex del legacy) solo para ayudar; el servidor repite la regla y si
/// rechaza, su mensaje se muestra **tal cual**. Lo mismo con la baja: un banco
/// con depositos o pagos al exterior no se elimina y el 400 explica por que.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/bancos_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/banco_entity.dart';
import 'package:bosque_flutter/domain/entities/banco_registro_entity.dart';
import 'package:bosque_flutter/domain/utils/reglas_cheque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart';

// ═══════════════════════════════════════════════════════════════════════════
// FORMULARIO
// ═══════════════════════════════════════════════════════════════════════════

/// Abre el formulario. Con [existente] null es un alta; con un banco, su
/// edicion. Devuelve el codBanco guardado o null si se cancelo.
Future<BigInt?> abrirFormularioBanco(
  BuildContext context, {
  BancoEntity? existente,
}) {
  // El error de una escritura anterior no debe aparecer en un formulario nuevo.
  ProviderScope.containerOf(
    context,
  ).read(operacionesBancosProvider.notifier).limpiarError();
  return abrirPanelCheque<BigInt>(
    context,
    anchoMaximo: 520,
    // La pantalla de Bancos no lleva el tema de Cheques: su dialogo tampoco.
    temaDelModulo: false,
    contenido: (_) => _FormularioBanco(existente: existente),
  );
}

class _FormularioBanco extends ConsumerStatefulWidget {
  const _FormularioBanco({required this.existente});

  final BancoEntity? existente;

  @override
  ConsumerState<_FormularioBanco> createState() => _FormularioBancoState();
}

class _FormularioBancoState extends ConsumerState<_FormularioBanco> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(
    text: widget.existente?.nombre ?? '',
  );

  /// Ya se intento guardar: desde ahi el error se actualiza al escribir.
  bool _intentado = false;

  bool get _esAlta => widget.existente == null;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _intentado = true);
    if (!(_form.currentState?.validate() ?? false)) {
      avisar(context, 'Revisa el campo marcado en rojo.', esError: true);
      return;
    }
    final nombre = _nombre.text.trim();
    final id = await ref
        .read(operacionesBancosProvider.notifier)
        .registrar(
          BancoRegistroEntity(
            codBanco: widget.existente?.codBanco ?? 0,
            nombre: nombre,
          ),
        );
    // El error, si lo hubo, queda en el estado y se dibuja junto al campo.
    if (id == null || !mounted) return;
    avisar(
      context,
      _esAlta ? 'Banco $nombre registrado.' : 'Banco actualizado.',
    );
    Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final ocupado = ref.watch(
      operacionesBancosProvider.select((s) => s.ocupado),
    );
    final errorServidor = ref.watch(
      operacionesBancosProvider.select((s) => s.error),
    );
    final e = widget.existente;

    return Form(
      key: _form,
      autovalidateMode:
          _intentado ? AutovalidateMode.always : AutovalidateMode.disabled,
      child: MarcoPanelCheque(
        titulo: _esAlta ? 'Nuevo banco' : 'Editar banco',
        subtitulo:
            _esAlta
                ? 'Lo usan Cheques, Depósitos y Pagos al exterior.'
                : 'Código ${e!.codBanco} · el cambio se ve en Cheques, '
                    'Depósitos y Pagos al exterior.',
        onCerrar: ocupado ? () {} : () => Navigator.of(context).pop(),
        cuerpo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorServidor != null) ...[
              ErrorServidorCheque(errorServidor),
              const SizedBox(height: Esp.l),
            ],
            TextFormField(
              key: const ValueKey('campo-nombre-banco'),
              controller: _nombre,
              autofocus: true,
              // Sin contador (`maxLength`): le quitaria ancho al mensaje de
              // error, que es largo.
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: ocupado ? null : (_) => _guardar(),
              decoration: const InputDecoration(
                labelText: 'Nombre del banco',
                helperText:
                    'De 3 a 50 caracteres. Letras sin acento, números, '
                    'espacios, apóstrofe y barra (/).',
                helperMaxLines: 3,
                errorMaxLines: 3,
                border: OutlineInputBorder(),
              ),
              validator: (t) {
                final v = (t ?? '').trim();
                if (v.isEmpty) return 'Ingresa el nombre del banco.';
                return ReglasCheque.errorNombreBanco(v);
              },
            ),
          ],
        ),
        acciones: [
          TextButton(
            onPressed: ocupado ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          BotonGuardarCheque(
            etiqueta: _esAlta ? 'Registrar banco' : 'Guardar cambios',
            ocupado: ocupado,
            onPressed: ocupado ? null : _guardar,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BAJA
// ═══════════════════════════════════════════════════════════════════════════

/// Pide confirmacion y da de baja el banco. Si el servidor lo rechaza (por
/// ejemplo, el banco tiene depositos o pagos al exterior) su texto se muestra
/// completo en un dialogo que se queda hasta que se lee, no en un aviso que se
/// va solo: explica por que no se pudo y que hacer.
Future<void> eliminarBanco(
  BuildContext context,
  WidgetRef ref,
  BancoEntity banco,
) async {
  final seguro = await confirmar(
    context,
    titulo: '¿Eliminar el banco ${banco.nombre}?',
    detalle:
        'Se elimina «${banco.nombre}» (código ${banco.codBanco}).\n\n'
        'Atención: si el banco solo tiene cheques registrados, el sistema lo '
        'elimina igual y esos cheques dejan de aparecer en el listado de '
        'Cheques. Si tiene depósitos o pagos al exterior, no se puede '
        'eliminar.',
    textoConfirmar: 'Eliminar banco',
    destructiva: true,
  );
  if (!seguro || !context.mounted) return;

  final ops = ref.read(operacionesBancosProvider.notifier);
  final r = await ops.eliminar(banco.codBanco);
  if (!context.mounted) return;
  if (r == null) {
    final texto =
        ref.read(operacionesBancosProvider).error ??
        'No se pudo eliminar el banco.';
    ops.limpiarError();
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: Icon(
              Icons.error_outline,
              color: Theme.of(ctx).colorScheme.error,
            ),
            title: const Text('No se pudo eliminar el banco'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in lineasDeError(texto))
                      Padding(
                        padding: const EdgeInsets.only(bottom: Esp.xs),
                        child: Text(l),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
    );
    return;
  }
  avisar(context, 'Banco eliminado.');
}
