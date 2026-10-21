/// Los diálogos de Tipos de teléfono: alta y edición (un campo, el nombre) y
/// la baja con su confirmación. Las reglas y los textos los pone
/// `p_abm_TipoTelefono`; aquí solo se muestran.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/tipo_telefono_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/domain/entities/tipo_telefono_entity.dart';
import 'package:bosque_flutter/presentation/widgets/parametros/catalogo_parametros.dart';

/// Con [existente] null es un alta; con un tipo, su edición.
Future<void> abrirFormularioTipoTelefono(
  BuildContext context, {
  TipoTelefonoEntity? existente,
}) {
  ProviderScope.containerOf(
    context,
  ).read(operacionesTipoTelefonoProvider.notifier).limpiarError();
  return abrirFormularioParametro<void>(
    context,
    contenido: (_) => _FormularioTipoTelefono(existente: existente),
  );
}

class _FormularioTipoTelefono extends ConsumerStatefulWidget {
  const _FormularioTipoTelefono({required this.existente});

  final TipoTelefonoEntity? existente;

  @override
  ConsumerState<_FormularioTipoTelefono> createState() =>
      _FormularioTipoTelefonoState();
}

class _FormularioTipoTelefonoState
    extends ConsumerState<_FormularioTipoTelefono> {
  late final _tipo = TextEditingController(text: widget.existente?.tipo ?? '');

  bool get _esAlta => widget.existente == null;

  @override
  void dispose() {
    _tipo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final r = await ref
        .read(operacionesTipoTelefonoProvider.notifier)
        .ejecutar(
          () => ref
              .read(tipoTelefonoRepositoryProvider)
              .registrar(
                TipoTelefonoEntity(
                  codTipoTel: widget.existente?.codTipoTel ?? 0,
                  tipo: _tipo.text,
                  audUsuario: 0,
                ),
              ),
        );
    // El rechazo, si lo hubo, queda en el estado y se dibuja arriba del campo.
    if (r == null || !mounted) return;
    avisar(context, r.mensaje);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(operacionesTipoTelefonoProvider);
    final e = widget.existente;

    return PanelParametro(
      titulo: _esAlta ? 'Nuevo tipo de teléfono' : 'Editar tipo de teléfono',
      subtitulo:
          _esAlta
              ? 'Aparecerá al registrar el teléfono de un empleado.'
              : 'Código ${e!.codTipoTel} · lo usan ${e.usos} teléfonos.',
      ocupado: estado.ocupado,
      errorServidor: estado.error,
      etiquetaGuardar: _esAlta ? 'Registrar' : 'Guardar cambios',
      onGuardar: _guardar,
      campos: [
        TextField(
          key: const ValueKey('campo-tipo-telefono'),
          controller: _tipo,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [LengthLimitingTextInputFormatter(50)],
          textInputAction: TextInputAction.done,
          onSubmitted: estado.ocupado ? null : (_) => _guardar(),
          decoration: const InputDecoration(
            labelText: 'Nombre del tipo',
            hintText: 'Por ejemplo: CORPORATIVO',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// Confirma y da de baja el tipo. Si lo usan teléfonos, el servidor lo
/// rechaza y su texto se lee completo.
Future<void> eliminarTipoTelefono(
  BuildContext context,
  WidgetRef ref,
  TipoTelefonoEntity tipo,
) {
  final ops = ref.read(operacionesTipoTelefonoProvider.notifier);
  return eliminarDeCatalogo(
    context,
    titulo: '¿Eliminar el tipo ${tipo.tipo}?',
    detalle:
        'Se elimina «${tipo.tipo}» (código ${tipo.codTipoTel}). '
        'Si algún teléfono lo usa, no se podrá eliminar.',
    textoConfirmar: 'Eliminar tipo',
    operaciones: ops,
    errorActual: () => ref.read(operacionesTipoTelefonoProvider).error,
    eliminar:
        () => ref.read(tipoTelefonoRepositoryProvider).eliminar(tipo.codTipoTel),
  );
}
