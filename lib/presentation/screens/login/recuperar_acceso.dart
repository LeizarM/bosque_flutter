part of 'login_screen.dart';

/// Recuperación de acceso, en el lugar del formulario de entrada.
///
/// Dos pasos: pedir un código, que llega al correo corporativo, y escribirlo
/// junto con la contraseña nueva. Sirve para el olvido y para desbloquearse.
class _Recuperacion extends ConsumerStatefulWidget {
  final bool amplio;
  final String loginInicial;
  final void Function({String? aviso, String? login}) onCerrar;

  const _Recuperacion({
    super.key,
    required this.amplio,
    required this.loginInicial,
    required this.onCerrar,
  });

  @override
  ConsumerState<_Recuperacion> createState() => _RecuperacionState();
}

class _RecuperacionState extends ConsumerState<_Recuperacion> {
  late final TextEditingController _usuario = TextEditingController(
    text: widget.loginInicial,
  );
  final TextEditingController _codigo = TextEditingController();
  final TextEditingController _clave = TextEditingController();
  final TextEditingController _confirmacion = TextEditingController();
  final FocusNode _focoUsuario = FocusNode();
  final FocusNode _focoCodigo = FocusNode();
  final FocusNode _focoClave = FocusNode();
  final FocusNode _focoConfirmacion = FocusNode();

  /// Segundo paso: escribir el código y la clave nueva.
  bool _conCodigo = false;

  /// A dónde se envió el último código; null si la persona dijo que ya lo tenía.
  RecuperacionEnviadaEntity? _enviada;
  bool _cargando = false;
  bool _claveOculta = true;
  String? _mensaje;
  _Tono _tono = _Tono.error;
  int _segundosParaReenviar = 0;
  Timer? _reloj;

  @override
  void dispose() {
    _reloj?.cancel();
    _usuario.dispose();
    _codigo.dispose();
    _clave.dispose();
    _confirmacion.dispose();
    _focoUsuario.dispose();
    _focoCodigo.dispose();
    _focoClave.dispose();
    _focoConfirmacion.dispose();
    super.dispose();
  }

  void _avisar(String texto, {_Tono tono = _Tono.error}) {
    setState(() {
      _mensaje = texto;
      _tono = tono;
    });
  }

  /// Pide el código. También es el «Reenviar» del segundo paso.
  Future<void> _enviarCodigo() async {
    final login = _usuario.text.trim();
    if (login.isEmpty) {
      _avisar('Escribe tu usuario.');
      return;
    }
    final reenvio = _conCodigo;
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      final enviada = await ref
          .read(recuperacionAccesoRepositoryProvider)
          .solicitarCodigo(login);
      if (!mounted) return;
      setState(() {
        _enviada = enviada;
        _conCodigo = true;
        _codigo.clear();
      });
      if (reenvio) {
        _avisar('Te enviamos un código nuevo a ${enviada.correo}.', tono: _Tono.aviso);
      }
      _arrancarReloj(enviada.segundosParaReenviar);
      _enfocarCodigo();
    } catch (e) {
      if (mounted) _avisar(textoParaUsuario(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Para quien ya recibió un código y volvió atrás o cerró la app: pedir otro anularía ese.
  void _yaTengoCodigo() {
    if (_usuario.text.trim().isEmpty) {
      _avisar('Escribe tu usuario.');
      return;
    }
    setState(() {
      _conCodigo = true;
      _mensaje = null;
    });
    _enfocarCodigo();
  }

  /// Al primer paso con el usuario ya escrito, por si estaba mal: «Volver» descarta todo el flujo.
  void _cambiarUsuario() {
    _reloj?.cancel();
    setState(() {
      _conCodigo = false;
      _enviada = null;
      _segundosParaReenviar = 0;
      _mensaje = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focoUsuario.requestFocus();
    });
  }

  /// En el cuadro siguiente: el campo del código recién se arma con el cambio de paso.
  void _enfocarCodigo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focoCodigo.requestFocus();
    });
  }

  /// Valida aquí lo que no necesita al servidor, para no gastar intentos del código.
  Future<void> _cambiarClave() async {
    final codigo = _codigo.text.trim();
    final clave = _clave.text.trim();
    final String? problema = switch (true) {
      _ when codigo.length != 6 => 'Escribe los 6 dígitos del código.',
      _ when clave.length < 6 =>
        'La nueva contraseña debe tener al menos 6 caracteres.',
      _ when clave == '123456789' =>
        'La nueva contraseña no puede ser 123456789.',
      _ when clave != _confirmacion.text.trim() =>
        'Las dos contraseñas no coinciden.',
      _ => null,
    };
    if (problema != null) {
      _avisar(problema);
      return;
    }

    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      final listo = await ref
          .read(recuperacionAccesoRepositoryProvider)
          .restablecer(
            login: _usuario.text.trim(),
            codigo: codigo,
            nuevaContrasena: clave,
          );
      if (!mounted) return;
      widget.onCerrar(
        aviso:
            listo.isNotEmpty
                ? listo
                : 'Listo: cambiamos tu contraseña. Ya puedes iniciar sesión.',
        login: _usuario.text.trim(),
      );
    } catch (e) {
      if (mounted) _avisar(textoParaUsuario(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// La espera la manda el backend: es la misma que exige el SP entre dos pedidos.
  void _arrancarReloj(int segundos) {
    _reloj?.cancel();
    setState(() => _segundosParaReenviar = segundos);
    _reloj = Timer.periodic(const Duration(seconds: 1), (reloj) {
      if (!mounted || _segundosParaReenviar <= 1) {
        reloj.cancel();
        if (mounted) setState(() => _segundosParaReenviar = 0);
        return;
      }
      setState(() => _segundosParaReenviar--);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final t = Theme.of(context).textTheme;
    final enviada = _enviada;
    final paso2 = _conCodigo;
    final habilitado = !_cargando;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          // Misma alineación que el encabezado de entrada (ver _entrar).
          crossAxisAlignment:
              widget.amplio
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
          children: [
            Text(
              paso2 ? 'Revisa tu correo' : 'Recupera tu acceso',
              style: t.headlineMedium?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: Esp.xs),
            Text(
              !paso2
                  ? 'Te enviaremos un código a tu correo corporativo. Sirve si '
                      'olvidaste tu contraseña o si tu usuario se bloqueó.'
                  : enviada == null
                  ? 'Escribe el código que te enviamos por correo y elige tu '
                      'nueva contraseña.'
                  : 'Escribe el código que enviamos a ${enviada.correo} y elige '
                      'tu nueva contraseña. Vence en ${enviada.minutosVigencia} minutos.',
              textAlign: widget.amplio ? TextAlign.start : TextAlign.center,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (paso2)
              Wrap(
                alignment:
                    widget.amplio ? WrapAlignment.start : WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Usuario: ${_usuario.text.trim()}',
                    style: t.bodyMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: habilitado ? _cambiarUsuario : null,
                    child: const Text('Cambiar usuario'),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: Esp.xl),
        _GrupoDeAutocompletado(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children:
                !paso2
                    ? [
                      _Campo(
                        controlador: _usuario,
                        foco: _focoUsuario,
                        etiqueta: 'Usuario',
                        icono: Icons.person_outline_rounded,
                        pistas: const [AutofillHints.username],
                        accion: TextInputAction.done,
                        habilitado: habilitado,
                        onEnviar: _enviarCodigo,
                      ),
                    ]
                    : [
                      _Campo(
                        controlador: _codigo,
                        foco: _focoCodigo,
                        etiqueta: 'Código de 6 dígitos',
                        icono: Icons.pin_outlined,
                        pistas: const [AutofillHints.oneTimeCode],
                        accion: TextInputAction.next,
                        habilitado: habilitado,
                        teclado: TextInputType.number,
                        formatos: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onEnviar: () => _focoClave.requestFocus(),
                      ),
                      const SizedBox(height: Esp.m),
                      _Campo(
                        controlador: _clave,
                        foco: _focoClave,
                        etiqueta: 'Nueva contraseña',
                        icono: Icons.lock_outline_rounded,
                        pistas: const [AutofillHints.newPassword],
                        accion: TextInputAction.next,
                        habilitado: habilitado,
                        esClave: true,
                        oculto: _claveOculta,
                        onAlternarOculto:
                            () => setState(() => _claveOculta = !_claveOculta),
                        ayuda: 'Mínimo 6 caracteres.',
                        onCambio: (_) => setState(() {}),
                        onEnviar: () => _focoConfirmacion.requestFocus(),
                      ),
                      const SizedBox(height: Esp.m),
                      _Campo(
                        controlador: _confirmacion,
                        foco: _focoConfirmacion,
                        etiqueta: 'Repite la nueva contraseña',
                        icono: Icons.lock_outline_rounded,
                        pistas: const [AutofillHints.newPassword],
                        accion: TextInputAction.done,
                        habilitado: habilitado,
                        esClave: true,
                        oculto: _claveOculta,
                        onAlternarOculto:
                            () => setState(() => _claveOculta = !_claveOculta),
                        // En vivo, no al enviar: el error se corrige donde se cometió.
                        error:
                            _confirmacion.text.isNotEmpty &&
                                    _confirmacion.text.trim() !=
                                        _clave.text.trim()
                                ? 'No coincide con la nueva contraseña.'
                                : null,
                        onCambio: (_) => setState(() {}),
                        onEnviar: _cambiarClave,
                      ),
                    ],
          ),
        ),
        AnimatedSize(
          duration:
              MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child:
              _mensaje == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                    padding: const EdgeInsets.only(top: Esp.l),
                    child: _Aviso(texto: _mensaje!, tono: _tono),
                  ),
        ),
        const SizedBox(height: Esp.xl),
        _BotonEntrar(
          cargando: _cargando,
          onPresionar: paso2 ? _cambiarClave : _enviarCodigo,
          texto: paso2 ? 'Cambiar contraseña' : 'Enviar código',
          textoCargando: paso2 ? 'Cambiando' : 'Enviando',
          icono: paso2 ? Icons.check_rounded : Icons.mail_outline_rounded,
        ),
        const SizedBox(height: Esp.s),
        // Wrap y no Row: con letra grande en un teléfono los dos no entran en una línea.
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: habilitado ? () => widget.onCerrar() : null,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Volver a iniciar sesión'),
            ),
            if (paso2)
              TextButton(
                onPressed:
                    habilitado && _segundosParaReenviar == 0
                        ? _enviarCodigo
                        : null,
                child: Text(
                  _segundosParaReenviar > 0
                      ? 'Reenviar en $_segundosParaReenviar s'
                      : 'Reenviar código',
                ),
              )
            else
              TextButton(
                onPressed: habilitado ? _yaTengoCodigo : null,
                child: const Text('Ya tengo un código'),
              ),
          ],
        ),
      ],
    );
  }
}
