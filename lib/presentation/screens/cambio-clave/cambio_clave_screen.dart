/// Cambio de la propia contraseña dentro del Dashboard. Reemplaza a
/// `tbUsuario/cpassword.xhtml` (tb_vista codVista 29) con la misma dirección.
///
/// Pide la actual, la nueva y su repetición; las reglas y los textos los pone
/// el servidor (`/auth/cambiarClave`). Distinta de `ChangePasswordScreen`, que
/// es la del primer ingreso con la clave por defecto.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/cuenta_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/cheques/piezas_cheques.dart'
    show ErrorServidorCheque;

class CambioClaveScreen extends ConsumerStatefulWidget {
  const CambioClaveScreen({super.key});

  @override
  ConsumerState<CambioClaveScreen> createState() => _CambioClaveScreenState();
}

class _CambioClaveScreenState extends ConsumerState<CambioClaveScreen> {
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _repetida = TextEditingController();
  final _visibles = <String>{};

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _repetida.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final r = await ref
        .read(operacionCambioClaveProvider.notifier)
        .ejecutar(
          () => ref
              .read(cuentaRepositoryProvider)
              .cambiarClave(
                actual: _actual.text,
                nueva: _nueva.text,
                confirmacion: _repetida.text,
              ),
        );
    if (r == null || !mounted) return;
    _actual.clear();
    _nueva.clear();
    _repetida.clear();
    avisar(context, r.mensaje);
  }

  Widget _campo(String clave, String etiqueta, TextEditingController c) {
    final visible = _visibles.contains(clave);
    return TextField(
      key: ValueKey(clave),
      controller: c,
      obscureText: !visible,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [LengthLimitingTextInputFormatter(15)],
      // Redibuja las comprobaciones en vivo de abajo del formulario.
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          tooltip: visible ? 'Ocultar' : 'Mostrar',
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed:
              () => setState(
                () => visible ? _visibles.remove(clave) : _visibles.add(clave),
              ),
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(operacionCambioClaveProvider);
    final usuario = ref.watch(userProvider);
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // Panel de identidad: quién cambia la clave y qué pasa al guardar.
    Widget identidad({required bool ancho}) => Container(
      padding: EdgeInsets.all(ancho ? Esp.xl : Esp.l),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ancho ? 56 : 44,
            height: ancho ? 56 : 44,
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(Esquina.media),
            ),
            child: Icon(
              Icons.key_outlined,
              color: cs.primary,
              size: ancho ? 30 : 24,
            ),
          ),
          SizedBox(height: ancho ? Esp.l : Esp.m),
          Text(
            'Cambiar contraseña',
            style: (ancho ? t.headlineSmall : t.titleLarge)?.copyWith(
              fontWeight: Peso.titulo,
              color: cs.onPrimaryContainer,
            ),
          ),
          if (usuario != null) ...[
            const SizedBox(height: Esp.xs),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: cs.onPrimaryContainer,
                ),
                const SizedBox(width: Esp.xs),
                Flexible(
                  child: Text(
                    usuario.login,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: Peso.titulo,
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: ancho ? Esp.xl : Esp.l),
          _Aviso(
            icono: Icons.devices_other_outlined,
            texto: 'Al guardar se cierran tus otras sesiones abiertas.',
          ),
          const SizedBox(height: Esp.m),
          _Aviso(
            icono: Icons.lock_clock_outlined,
            texto:
                'Tres intentos con la contraseña actual errada en una hora '
                'bloquean el usuario.',
          ),
        ],
      ),
    );

    final formulario = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (estado.error != null) ...[
          ErrorServidorCheque(estado.error!),
          const SizedBox(height: Esp.l),
        ],
        _campo('clave-actual', 'Contraseña actual', _actual),
        const SizedBox(height: Esp.l),
        _campo('clave-nueva', 'Nueva contraseña', _nueva),
        const SizedBox(height: Esp.l),
        _campo('clave-repetida', 'Repite la nueva contraseña', _repetida),
        const SizedBox(height: Esp.l),
        // Solo comparaciones entre campos; las reglas de la clave las
        // valida el servidor.
        _Chequeo(
          texto: 'La repetición coincide',
          ok:
              _nueva.text.isEmpty || _repetida.text.isEmpty
                  ? null
                  : _nueva.text == _repetida.text,
        ),
        const SizedBox(height: Esp.xs),
        _Chequeo(
          texto: 'Es distinta de la actual',
          ok:
              _nueva.text.isEmpty || _actual.text.isEmpty
                  ? null
                  : _nueva.text != _actual.text,
        ),
        const SizedBox(height: Esp.xl),
        Align(
          alignment: Alignment.centerRight,
          child: BotonAccion(
            etiqueta: 'Guardar contraseña',
            etiquetaOcupado: 'Guardando…',
            icono: Icons.save_outlined,
            ocupado: estado.ocupado,
            onPressed: _guardar,
          ),
        ),
      ],
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final chico = Aire.de(c.maxWidth).esChico;
          final ancho = c.maxWidth >= 840;
          final tarjeta = Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            shape: contornoSuperficie(cs),
            child:
                ancho
                    ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 360, child: identidad(ancho: true)),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(Esp.xxl),
                              child: Center(child: formulario),
                            ),
                          ),
                        ],
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        identidad(ancho: false),
                        Padding(
                          padding: EdgeInsets.all(chico ? Esp.l : Esp.xl),
                          child: formulario,
                        ),
                      ],
                    ),
          );
          return SingleChildScrollView(
            padding: EdgeInsets.all(chico ? Esp.m : Esp.xxl),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: ancho ? 960 : 560),
                child: tarjeta,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Una consecuencia de guardar, con su ícono, sobre el panel de color.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 20, color: cs.onPrimaryContainer),
        const SizedBox(width: Esp.s),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onPrimaryContainer),
          ),
        ),
      ],
    );
  }
}

/// Comprobación en vivo: gris sin datos, color principal si se cumple y de
/// error si no.
class _Chequeo extends StatelessWidget {
  const _Chequeo({required this.texto, required this.ok});

  final String texto;
  final bool? ok;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icono, color) = switch (ok) {
      null => (Icons.radio_button_unchecked, cs.outline),
      true => (Icons.check_circle, cs.primary),
      false => (Icons.cancel, cs.error),
    };
    return Row(
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: Esp.s),
        Expanded(
          child: Text(
            texto,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ok == null ? cs.onSurfaceVariant : color,
            ),
          ),
        ),
      ],
    );
  }
}
