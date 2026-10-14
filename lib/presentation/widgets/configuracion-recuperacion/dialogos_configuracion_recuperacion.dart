import 'package:bosque_flutter/core/state/configuracion_recuperacion_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/configuracion_recuperacion_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edita un parámetro; si se guarda, avisa y relee la lista.
Future<void> editarParametro(
  BuildContext context,
  WidgetRef ref,
  ConfiguracionRecuperacionEntity parametro,
) async {
  final mensaje = await showDialog<String>(
    context: context,
    builder: (_) => _DialogoParametro(parametro: parametro),
  );
  if (mensaje == null || !context.mounted) return;
  avisar(context, mensaje);
  ref.invalidate(configuracionRecuperacionProvider);
}

/// Manda un correo con la configuración vigente, para comprobarla sin esperar a un empleado.
Future<void> probarCorreo(BuildContext context, String? sugerido) async {
  final mensaje = await showDialog<String>(
    context: context,
    builder: (_) => _DialogoPrueba(sugerido: sugerido ?? ''),
  );
  if (mensaje != null && context.mounted) avisar(context, mensaje);
}

class _DialogoParametro extends ConsumerStatefulWidget {
  const _DialogoParametro({required this.parametro});

  final ConfiguracionRecuperacionEntity parametro;

  @override
  ConsumerState<_DialogoParametro> createState() => _DialogoParametroState();
}

class _DialogoParametroState extends ConsumerState<_DialogoParametro> {
  // La contraseña actual no viaja: el campo arranca vacío.
  late final TextEditingController _texto = TextEditingController(
    text: widget.parametro.esSecreto ? '' : (widget.parametro.valor ?? ''),
  );
  late String? _opcion =
      widget.parametro.opciones.contains(widget.parametro.valor)
          ? widget.parametro.valor
          : null;
  bool _oculto = true;
  bool _guardando = false;
  String? _error;

  ConfiguracionRecuperacionEntity get _p => widget.parametro;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  /// Lo obvio se avisa aquí; el resto lo valida el SP y su mensaje se muestra tal cual.
  String? _problema(String valor) {
    if (valor.isEmpty) return _p.tipo == 'opcion' ? 'Elige una opción.' : 'Escribe un valor.';
    if (_p.tipo == 'numero') {
      final n = int.tryParse(valor);
      if (n == null) return 'Escribe un número entero.';
      if ((_p.minimo != null && n < _p.minimo!) || (_p.maximo != null && n > _p.maximo!)) {
        return 'El valor tiene que estar entre ${_p.minimo} y ${_p.maximo}.';
      }
    }
    return null;
  }

  Future<void> _guardar() async {
    // Una contraseña puede tener espacios: es el único valor que no se recorta.
    final valor = _p.tipo == 'opcion' ? (_opcion ?? '') : (_p.esSecreto ? _texto.text : _texto.text.trim());
    final problema = _problema(valor);
    if (problema != null) {
      setState(() => _error = problema);
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final mensaje = await ref
          .read(configuracionRecuperacionRepositoryProvider)
          .guardar(clave: _p.clave, valor: valor);
      if (mounted) Navigator.of(context).pop(mensaje.isEmpty ? 'Guardado.' : mensaje);
    } catch (e) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = textoParaUsuario(e);
        });
      }
    }
  }

  String? get _ayuda => switch (_p.tipo) {
    'numero' when _p.minimo != null && _p.maximo != null => 'Entre ${_p.minimo} y ${_p.maximo}.',
    'dominios' => 'Separados por coma, por ejemplo esppapel.com,impexpap.com.',
    'secreto' => 'La contraseña actual no se muestra: escribe la nueva.',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final campo =
        _p.tipo == 'opcion'
            ? DropdownButtonFormField<String>(
              value: _opcion,
              isExpanded: true,
              decoration: InputDecoration(labelText: _p.nombre, errorText: _error),
              items: [
                for (final o in _p.opciones) DropdownMenuItem(value: o, child: Text(o)),
              ],
              onChanged: _guardando ? null : (o) => setState(() => _opcion = o),
            )
            : TextField(
              controller: _texto,
              autofocus: true,
              readOnly: _guardando,
              obscureText: _p.esSecreto && _oculto,
              keyboardType: switch (_p.tipo) {
                'numero' => TextInputType.number,
                'correo' => TextInputType.emailAddress,
                'secreto' => TextInputType.visiblePassword,
                _ => TextInputType.text,
              },
              inputFormatters:
                  _p.tipo == 'numero' ? [FilteringTextInputFormatter.digitsOnly] : null,
              // El rango se avisa mientras se escribe, no al guardar.
              onChanged:
                  _p.tipo == 'numero'
                      ? (v) => setState(() => _error = v.trim().isEmpty ? null : _problema(v.trim()))
                      : null,
              onSubmitted: (_) => _guardar(),
              decoration: InputDecoration(
                labelText: _p.nombre,
                helperText: _ayuda,
                helperMaxLines: 2,
                errorText: _error,
                errorMaxLines: 3,
                suffixIcon:
                    _p.esSecreto
                        ? IconButton(
                          tooltip: _oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          onPressed: () => setState(() => _oculto = !_oculto),
                          icon: Icon(_oculto ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        )
                        : null,
              ),
            );

    return AlertDialog(
      title: Text(_p.nombre),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_p.descripcion, style: context.apagado()),
            const SizedBox(height: Esp.l),
            campo,
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Guardar',
          etiquetaOcupado: 'Guardando',
          ocupado: _guardando,
          onPressed: _guardar,
        ),
      ],
    );
  }
}

class _DialogoPrueba extends ConsumerStatefulWidget {
  const _DialogoPrueba({required this.sugerido});

  final String sugerido;

  @override
  ConsumerState<_DialogoPrueba> createState() => _DialogoPruebaState();
}

class _DialogoPruebaState extends ConsumerState<_DialogoPrueba> {
  late final TextEditingController _correo = TextEditingController(text: widget.sugerido);
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final correo = _correo.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final mensaje = await ref.read(configuracionRecuperacionRepositoryProvider).probar(correo);
      if (mounted) Navigator.of(context).pop(mensaje);
    } catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          // El backend ya armó el texto para un administrador («No se pudo enviar: <causa>»): la causa
          // técnica es lo que le sirve para corregir, así que no pasa por humanizar, que la taparía.
          _error = e is String ? e : textoParaUsuario(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enviar correo de prueba'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Se envía con la configuración guardada. Si no llega, el error dice qué corregir.',
              style: context.apagado(),
            ),
            const SizedBox(height: Esp.l),
            TextField(
              controller: _correo,
              autofocus: true,
              readOnly: _enviando,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _enviar(),
              decoration: InputDecoration(
                labelText: 'Enviar a',
                errorText: _error,
                errorMaxLines: 4,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        BotonAccion(
          etiqueta: 'Enviar',
          etiquetaOcupado: 'Enviando',
          icono: Icons.send_outlined,
          ocupado: _enviando,
          onPressed: _enviar,
        ),
      ],
    );
  }
}
