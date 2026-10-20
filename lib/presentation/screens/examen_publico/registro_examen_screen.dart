/// `/examen/registro`: antes de rendir, el postulante completa CI, nombres y
/// apellidos (solo la primera vez, si `datosCompletos` vino en falso).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/postulante_examen_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/comun_examenes.dart';
import 'package:bosque_flutter/presentation/widgets/examenes/marco_publico.dart';

class RegistroExamenScreen extends ConsumerStatefulWidget {
  const RegistroExamenScreen({super.key});

  @override
  ConsumerState<RegistroExamenScreen> createState() => _RegistroExamenScreenState();
}

class _RegistroExamenScreenState extends ConsumerState<RegistroExamenScreen> {
  final _form = GlobalKey<FormState>();
  final _ci = TextEditingController();
  final _nombres = TextEditingController();
  final _paterno = TextEditingController();
  final _materno = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_ci, _nombres, _paterno, _materno]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(postulanteExamenRepositoryProvider).registrarDatos(
        ci: _ci.text,
        nombres: _nombres.text,
        apellidoPaterno: _paterno.text,
        apellidoMaterno: _materno.text,
      );
      if (!mounted) return;
      ref.invalidate(sesionPostulanteProvider);
      // Reemplaza la entrada del historial: Atrás no vuelve al formulario (la ruta igual lo rechaza).
      Router.neglect(context, () => context.go(AppConstants.rutaTcpeIngreso));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = textoParaUsuario(e);
      });
    }
  }

  // Basta un apellido, paterno o materno (p_abm_tcpe_Acceso 'R' exige al menos uno).
  bool get _sinApellidos => _paterno.text.trim().isEmpty && _materno.text.trim().isEmpty;

  TextFormField _campo(
    TextEditingController c,
    String etiqueta, {
    int largo = 50,
    String? Function(String valor)? validar,
    String? ayuda,
    bool ultimo = false,
  }) => TextFormField(
    controller: c,
    textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
    onFieldSubmitted: ultimo ? (_) => _guardar() : null,
    textCapitalization: TextCapitalization.words,
    inputFormatters: [LengthLimitingTextInputFormatter(largo)],
    decoration: InputDecoration(labelText: etiqueta, helperText: ayuda, border: const OutlineInputBorder()),
    validator: validar == null ? null : (v) => validar((v ?? '').trim()),
  );

  @override
  Widget build(BuildContext context) => MarcoPublicoExamen(
    child: Form(
      key: _form,
      child: TarjetaPublica(
        icono: Icons.badge_outlined,
        children: [
          Text(
            'PASO PREVIO · UNA SOLA VEZ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontFamily: fuenteFija,
              letterSpacing: 1.4,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: Esp.xs),
          Text(
            'Tus datos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: Peso.titulo),
          ),
          const SizedBox(height: Esp.s),
          Text(
            'Antes de empezar, completa tus datos tal como figuran en tu carnet. Se piden una sola vez.',
            style: context.apagado(),
          ),
          const SizedBox(height: Esp.xl),
          _campo(_ci, 'Carnet de identidad', largo: 20, validar: (v) => v.isEmpty ? 'Escribe tu número de carnet' : null),
          const SizedBox(height: Esp.m),
          _campo(_nombres, 'Nombres', validar: (v) => v.isEmpty ? 'Escribe tus nombres' : null),
          const SizedBox(height: Esp.m),
          _campo(
            _paterno,
            'Apellido paterno',
            ayuda: 'Si tienes un solo apellido, deja vacío el otro.',
            validar: (_) => _sinApellidos ? 'Escribe al menos un apellido: paterno o materno' : null,
          ),
          const SizedBox(height: Esp.m),
          _campo(_materno, 'Apellido materno', ultimo: true),
          if (_error != null) NotaDelDato(texto: _error!, tono: TonoNota.error),
          const SizedBox(height: Esp.xl),
          SizedBox(
            height: 48,
            child: BotonAccion(
              etiqueta: 'Guardar y continuar',
              etiquetaOcupado: 'Guardando…',
              icono: Icons.arrow_forward,
              ocupado: _guardando,
              onPressed: _guardar,
            ),
          ),
        ],
      ),
    ),
  );
}
