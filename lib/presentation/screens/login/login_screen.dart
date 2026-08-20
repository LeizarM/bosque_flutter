/// La pantalla de entrada a Bosque.
///
/// ## De dónde sale el color
///
/// De la semilla del tema y de ningún otro lado. La versión anterior tenía
/// trece colores escritos a mano —`0xFF111111`, `0xFFF4F4F5`, `0xFFDC2626` y
/// diez más— que son la escala zinc de Tailwind pegada adentro de una app
/// Material 3. Funcionaban con la semilla azul y se rompían con el resto: con
/// la semilla **roja**, el rojo fijo del recuadro de error quedaba igual que el
/// acento, así que un error se veía exactamente como todo lo demás.
///
/// Acá cada color sale de un rol del `ColorScheme`, así que las nueve semillas
/// por dos modos —dieciocho combinaciones— quedan resueltas por Material, que
/// además garantiza el contraste de cada par `X` / `onX`.
///
/// ## El acento tiene un lugar grande y uno solo
///
/// Antes el acento estaba repartido en tres orbes flotantes al 6% de opacidad,
/// un gradiente de fondo al 8% y la sombra del logo. Mucho lugar, ninguno
/// visible. Acá ocupa **una superficie entera** —el panel de marca en
/// escritorio, la banda de arriba en teléfono— y el resto de la pantalla es
/// superficie limpia. El color se ve porque tiene dónde verse.
///
/// ## Qué se mueve y por qué
///
/// La versión anterior tenía dos animaciones infinitas: tres orbes recorriendo
/// toda la pantalla cada 6 segundos y el logo latiendo cada 2,5. Las dos
/// repintaban para siempre en una pantalla que suele quedar abierta, y ninguna
/// comunicaba nada.
///
/// Acá el movimiento entra donde tiene un motivo:
/// * **La entrada** presenta la pantalla en orden —marca, encabezado, campos,
///   botón— para que el ojo sepa por dónde empezar. Dura 900 ms y termina.
/// * **El halo del logo** respira: es lo único perpetuo que queda, encerrado en
///   un `RepaintBoundary` de ~200 px en vez de repintar el viewport completo.
/// * **El foco, el aviso y el botón cargando** son respuesta a algo que hizo
///   quien está usando la pantalla.
///
/// Todo eso se apaga si el sistema pide menos animación.
library;

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/theme_mode_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/theme/app_theme.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/data/repositories/auth_repository_impl.dart';
import 'package:bosque_flutter/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

/// Mensaje mostrado cuando el dispositivo no puede persistir la sesión
/// (Keystore que no escribe en ciertos Android). Evita el bucle de login.
const String _msgErrorPersistencia =
    'No se pudo guardar tu sesión en este dispositivo. '
    'Cierra otras apps o reinicia el teléfono e inténtalo de nuevo.';

/// Qué tipo de cosa es lo que se está avisando.
///
/// No todos los mensajes son un error. «Tu versión está desactualizada» no lo
/// es: nadie se equivocó, y la solución está afuera de la app. Pintarlo del
/// mismo rojo que «usuario o contraseña incorrectos» le decía a la persona que
/// hizo algo mal cuando lo único que tiene que hacer es actualizar.
enum _Tono { error, aviso }

/// La única esquina redondeada de la pantalla.
///
/// Había seis radios sueltos —10, 12, 14, 16, 24 y 24 otra vez— sin ninguna
/// regla detrás: un recuadro de error de 12 al lado de un campo de 14 adentro
/// de una tarjeta de 24. Se lee inquieto y no se sabe por qué.
///
/// Quedó uno solo, y no por austeridad: al sacar las cajas de color se fueron
/// con ellas las superficies que pedían un radio propio. Lo que queda que tenga
/// esquinas son los campos, el botón, el aviso y las muestras de la paleta, y
/// las cuatro cosas son del mismo tamaño de gesto.
///
/// Las dos excepciones no son radios sueltos, son proporciones: el cuadrado del
/// logo usa `lado * 0.28` —la de un ícono de app, que tiene que aguantar que el
/// logo cambie de tamaño con la ventana— y el anillo de la muestra de color
/// deriva el suyo del de la muestra para quedar concéntrico.
const BorderRadius _esquina = BorderRadius.all(Radius.circular(14));

/// Nombres de las semillas de [colorList], en orden.
///
/// El color solo no alcanza para elegir: quien no distingue bien el violeta del
/// púrpura necesita leerlo. Si mañana agregan una semilla a `colorList`, la que
/// no tenga nombre acá se muestra por su posición en vez de romper.
const List<String> _nombresDeSemilla = [
  'Azul',
  'Turquesa',
  'Verde',
  'Rojo',
  'Violeta',
  'Amarillo',
  'Naranja',
  'Púrpura',
  'Rosa',
];

/// El ancho a partir del cual entran las dos columnas.
///
/// No es «es una tablet»: es cuánto necesita el formulario. Partido 6/5, a
/// 960 px la columna del formulario queda en 436 y, descontados los 40 de
/// respiro de cada lado, le sobran 356 para un campo que pide 400 y se
/// conforma con menos. Por debajo de eso el partido sí aprieta, así que la
/// marca pasa arriba y el formulario se queda con todo el ancho.
///
/// Se probó en 1040 y era demasiado alto: a 1000 px de ventana —un portátil
/// con la ventana a medias— la banda ocupaba el ancho completo con un logo en
/// el medio y el formulario quedaba flotando abajo. A ese ancho el partido usa
/// mejor el lugar.
const double _anchoParaPartir = 960;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  /// La entrada. Corre una vez y se apaga.
  late final AnimationController _entrada;

  /// El halo detrás del logo. Lo único perpetuo de la pantalla.
  late final AnimationController _halo;

  bool _isLoading = false;
  String? _message;
  _Tono _tono = _Tono.error;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // Ninguno de los dos arranca acá: si el sistema pide menos animación hay
    // que saltearlos, y eso recién se puede leer en didChangeDependencies.
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _halo = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _entrada.value = 1;
      _halo.stop();
      _halo.value = 0.5;
      return;
    }
    if (_entrada.status == AnimationStatus.dismissed) _entrada.forward();
    if (!_halo.isAnimating) _halo.repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrada.dispose();
    _halo.dispose();
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Login logic ──────────────────────────────────────────────────────────

  /// Pone el mensaje y con qué cara se muestra. Lo único que agrega sobre el
  /// `setState` de antes es el tono.
  void _mostrar(String texto, {_Tono tono = _Tono.error}) {
    setState(() {
      _message = texto;
      _tono = tono;
    });
  }

  void _login() async {
    if (_userController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrar('Completa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final (loginEntity, message) = await _authRepository.login(
        _userController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (loginEntity != null) {
        if (loginEntity.versionApp != AppConstants.APP_VERSION) {
          // Aviso, no error: no hay nada mal escrito, hay que actualizar.
          _mostrar(
            'Tu versión de la app (${AppConstants.APP_VERSION}) está desactualizada. '
            'Por favor actualiza a la versión ${loginEntity.versionApp} para continuar.',
            tono: _Tono.aviso,
          );
          return;
        } else if (_passwordController.text == '123456789') {
          // Contraseña por defecto, obligar cambio
          final ok = await ref.read(userProvider.notifier).setUser(loginEntity);
          if (!mounted) return;
          if (!ok) {
            _mostrar(_msgErrorPersistencia);
            return;
          }
          ref.invalidate(asyncUserProvider);
          context.go('/change-password', extra: loginEntity);
        } else {
          // await: la escritura de user_data/token debe completarse ANTES de
          // navegar, o el redirect del router puede leer storage vacío y rebotar.
          final ok = await ref.read(userProvider.notifier).setUser(loginEntity);
          if (!mounted) return;
          if (!ok) {
            // El dispositivo no pudo guardar la sesión (Keystore). Evita el
            // bucle de login silencioso mostrando un mensaje claro.
            _mostrar(_msgErrorPersistencia);
            return;
          }

          // `asyncUserProvider` es un FutureProvider SIN autoDispose: lee
          // `user_data` del storage una vez y se queda con ese valor. Si en esta
          // misma carga de la app alguien ya lo evaluó cuando no había sesión,
          // tiene cacheado un `null` que sobrevive al login — y el `AuthGate`,
          // que es quien lo mira, seguiría creyendo que no hay usuario.
          //
          // `setUser` acaba de escribir el storage, así que este es el momento
          // exacto en que ese caché quedó viejo. Invalidarlo acá lo obliga a
          // releer y a ver la sesión nueva.
          ref.invalidate(asyncUserProvider);
          context.go('/dashboard');
        }
      } else {
        _mostrar(message);
      }
    } catch (e) {
      if (mounted) _mostrar('Error de conexión');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tema = ref.watch(themeNotifierProvider);

    // El ancho del cajón y no el de la ventana: si algún día esto se monta
    // adentro de algo con márgenes, `MediaQuery` mentiría.
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, restricciones) {
          final amplio = restricciones.maxWidth >= _anchoParaPartir;

          return Stack(
            fit: StackFit.expand,
            children: [
              _CampoDeAcento(amplio: amplio),
              amplio
                  ? _partido(tema)
                  : _apilado(tema, restricciones.maxHeight),
            ],
          );
        },
      ),
    );
  }

  // ── Escritorio: dos columnas ─────────────────────────────────────────────

  /// La marca a la izquierda, el formulario a la derecha.
  ///
  /// Entre las dos mitades no hay ningún borde ni ninguna caja: lo único que
  /// las separa es dónde está el resplandor de [_CampoDeAcento], que se apaga
  /// antes de llegar al formulario.
  Widget _partido(AppTheme tema) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: LayoutBuilder(
              builder: (context, mitad) {
                // La marca crece con el lugar que tiene. Fija en 104 px se veia
                // como una estampilla pegada en una pared: en una ventana de
                // 1900 esta mitad pasa los 1000 px de ancho.
                final lado = (mitad.maxWidth / 8.2).clamp(96.0, 152.0);

                return Padding(
                  padding: const EdgeInsets.all(48),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: _bloqueDeMarca(amplio: true, ladoForzado: lado),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: _Entra(
                          control: _entrada,
                          desde: 0.45,
                          hasta: 1,
                          child: _pie(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                _columnaDeFormulario(amplio: true),
                // Van a la esquina y no arriba de la columna: la columna esta
                // centrada verticalmente, asi que ahi quedaban flotando a 300 px
                // de todo, sin pertenecer a nada.
                Positioned(
                  top: Esp.s,
                  right: Esp.l,
                  child: _Entra(
                    control: _entrada,
                    desde: 0.20,
                    hasta: 0.75,
                    child: _controles(tema),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Teléfono y tablet: banda arriba, formulario abajo ────────────────────

  /// Todo en una columna: marca, formulario y pie.
  ///
  /// Acá hubo una tarjeta, y después una banda de acento con las esquinas de
  /// abajo redondeadas. Las dos eran lo mismo: un bloque de color con un borde
  /// neto contra la hoja. El resplandor de [_CampoDeAcento] hace el trabajo que
  /// hacían —decir dónde está la marca— sin dibujar ese borde.
  Widget _apilado(AppTheme tema, double alto) {
    final bordes = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        SingleChildScrollView(
          child: ConstrainedBox(
            // El piso hace que la columna se centre en la pantalla en vez de
            // apoyarse arriba y dejar el resto vacio.
            constraints: BoxConstraints(minHeight: alto),
            // Apenas arriba del centro real: un bloque exactamente centrado se
            // percibe caido.
            child: Align(
              alignment: const Alignment(0, -0.12),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Esp.xl,
                  bordes.top + Esp.xxl,
                  Esp.xl,
                  bordes.bottom + Esp.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _bloqueDeMarca(amplio: false),
                    const SizedBox(height: Esp.xxl),
                    _columnaDeFormulario(amplio: false),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Clavados arriba a la derecha: no scrollean con el formulario.
        Positioned(
          top: bordes.top + Esp.xs,
          right: Esp.s,
          child: _Entra(
            control: _entrada,
            desde: 0.20,
            hasta: 0.75,
            child: _controles(tema),
          ),
        ),
      ],
    );
  }

  // ── Piezas compartidas por los dos armados ───────────────────────────────

  /// Logo, nombre y bajada. Es el mismo bloque en los dos armados: cambia el
  /// tamaño y de qué lado se alinea, no la estructura.
  Widget _bloqueDeMarca({required bool amplio, double? ladoForzado}) {
    final cs = context.cs;
    final lado = ladoForzado ?? (amplio ? 104.0 : 86.0);
    final tamNombre = amplio ? (lado * 0.52).clamp(46.0, 74.0) : 36.0;

    // Cuánto se abre el halo más allá del logo. Se abre bastante porque es lo
    // que le da cuerpo a la marca ahora que no hay ninguna caja atrás: es
    // superficie pintada, no un objeto que haya que inventar para llenar.
    final apertura = amplio ? 0.9 : 0.75;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Entra(
          control: _entrada,
          desde: 0,
          hasta: 0.55,
          escalaDesde: 0.84,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Desborda el cuadrado del logo por los cuatro lados. Va en
              // `Positioned` para que el Stack lo siga midiendo por el logo: si
              // midiera el halo, la columna entera se ensancharía a su tamaño y
              // el bloque dejaría de centrarse sobre el logo.
              Positioned(
                left: -lado * apertura,
                right: -lado * apertura,
                top: -lado * apertura,
                bottom: -lado * apertura,
                child: _Halo(latido: _halo, color: cs.primary),
              ),
              _Marca(lado: lado),
            ],
          ),
        ),
        SizedBox(height: amplio ? Esp.xxl : Esp.xl),
        _Entra(
          control: _entrada,
          desde: 0.12,
          hasta: 0.70,
          desplazamiento: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Bosque',
                style: TextStyle(
                  // `onSurface` y ya no `onPrimaryContainer`: abajo no hay
                  // contenedor, hay hoja con un tinte encima.
                  color: cs.onSurface,
                  fontSize: tamNombre,
                  fontWeight: FontWeight.w800,
                  // Proporcional al cuerpo: un tracking fijo de -1,5 que se ve
                  // bien a 52 px queda demasiado apretado a 34.
                  letterSpacing: tamNombre * -0.035,
                  height: 1,
                ),
              ),
              const SizedBox(height: Esp.s),
              Text(
                'powered by Esppapel',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: amplio ? 15 : 13,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Controles de tema, encabezado y formulario, en una columna que no pasa de
  /// 400 px. Un campo de texto más ancho que eso se vuelve incómodo de leer y
  /// de apuntar, por ancha que esté la ventana.
  Widget _columnaDeFormulario({required bool amplio}) {
    final cs = context.cs;
    final t = Theme.of(context).textTheme;

    final columna = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Entra(
            control: _entrada,
            desde: 0.26,
            hasta: 0.82,
            desplazamiento: 12,
            child: Column(
              // En escritorio el encabezado arranca contra el borde de los
              // campos. En telefono la marca esta justo arriba y centrada: un
              // titulo pegado a la izquierda debajo de un logo centrado se lee
              // como dos composiciones apiladas en vez de una columna.
              crossAxisAlignment: amplio
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Text(
                  'Bienvenido',
                  style: t.headlineMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: Esp.xs),
                Text(
                  'Inicia sesión para continuar',
                  style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: Esp.xl),
          _Entra(
            control: _entrada,
            desde: 0.34,
            hasta: 0.92,
            desplazamiento: 16,
            child: _formulario(),
          ),
          if (!amplio) ...[
            const SizedBox(height: Esp.xl),
            _Entra(
              control: _entrada,
              desde: 0.45,
              hasta: 1,
              child: Center(child: _pie()),
            ),
          ],
        ],
      ),
    );

    // En escritorio la columna se centra en su mitad y hace scroll si la
    // ventana es baja. En teléfono ya viene adentro del scroll de la pantalla.
    if (!amplio) return Center(child: columna);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        // El `Align` no es de adorno: `SingleChildScrollView` le pasa a su hijo
        // un ancho APRETADO, y contra un ancho apretado el `maxWidth: 400` del
        // `ConstrainedBox` se pierde —`enforce` lo recorta al ancho de
        // afuera— así que los campos se estiraban a los 540 px del panel.
        // `Align` afloja la restricción y recién ahí el tope de 400 manda.
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1,
          child: columna,
        ),
      ),
    );
  }

  Widget _formulario() {
    final habilitado = !_isLoading;

    return _GrupoDeAutocompletado(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Campo(
            controlador: _userController,
            foco: _userFocus,
            etiqueta: 'Usuario',
            icono: Icons.person_outline_rounded,
            pistas: const [AutofillHints.username],
            accion: TextInputAction.next,
            habilitado: habilitado,
            onEnviar: () => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: Esp.m),
          _Campo(
            controlador: _passwordController,
            foco: _passwordFocus,
            etiqueta: 'Contraseña',
            icono: Icons.lock_outline_rounded,
            pistas: const [AutofillHints.password],
            accion: TextInputAction.done,
            habilitado: habilitado,
            esClave: true,
            oculto: _obscurePassword,
            onAlternarOculto: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onEnviar: _login,
          ),

          // El aviso crece en lugar de aparecer de golpe: apareciendo empujaba
          // el botón hacia abajo justo cuando la persona iba a volver a
          // apretarlo.
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _message == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Esp.l),
                    child: _Aviso(texto: _message!, tono: _tono),
                  ),
          ),

          const SizedBox(height: Esp.xl),
          _BotonEntrar(cargando: _isLoading, onPresionar: _login),
        ],
      ),
    );
  }

  /// Los controles de tema. Caen siempre sobre la hoja —ya no hay banda de
  /// color debajo— así que la tinta es una sola.
  Widget _controles(AppTheme tema) {
    return _ControlesDeTema(
      acento: context.cs.primary,
      oscuro: tema.isDarkMode,
      onPaleta: () => _mostrarPaleta(context, tema.selectedColor),
      onModo: () => ref.read(themeNotifierProvider.notifier).toggleDarkMode(),
    );
  }

  Widget _pie() {
    return Text(
      'Esppapel  ·  v${AppConstants.APP_VERSION}',
      style: TextStyle(
        color: context.cs.onSurfaceVariant.withValues(alpha: 0.85),
        fontSize: 11.5,
        fontWeight: Peso.titulo,
        letterSpacing: 1,
      ),
    );
  }

  // ── La paleta ────────────────────────────────────────────────────────────

  /// Las nueve semillas, cada una con su nombre.
  ///
  /// Antes eran nueve cuadrados sin rótulo y con una sombra del propio color
  /// abajo: un resplandor de color sobre color, que es la decoración que se
  /// pone cuando no hay nada que mostrar. Acá el rótulo hace el trabajo y la
  /// elegida se marca con un anillo de `onSurface`, que contrasta con la hoja
  /// pase lo que pase con la semilla.
  void _mostrarPaleta(BuildContext context, int elegida) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final cs = context.cs;
        final t = Theme.of(context).textTheme;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Esp.xl, 0, Esp.xl, Esp.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: _esquina,
                      ),
                      child: Icon(
                        Icons.palette_outlined,
                        color: cs.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: Esp.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Color del tema',
                            style: t.titleMedium?.copyWith(
                              fontWeight: Peso.titulo,
                            ),
                          ),
                          Text(
                            'Elige tu color favorito',
                            style: t.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.xl),
                Wrap(
                  spacing: Esp.m,
                  runSpacing: Esp.l,
                  children: [
                    for (var i = 0; i < colorList.length; i++)
                      _MuestraDeColor(
                        color: colorList[i],
                        nombre: i < _nombresDeSemilla.length
                            ? _nombresDeSemilla[i]
                            : 'Color ${i + 1}',
                        elegida: elegida == i,
                        onTap: () {
                          ref
                              .read(themeNotifierProvider.notifier)
                              .changeColorIndex(i);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA SUPERFICIE DE ACENTO
// ═══════════════════════════════════════════════════════════════════════════

/// El resplandor de la marca. No tiene forma: se disuelve en la hoja.
///
/// ## Por qué dejó de ser un rectángulo
///
/// Era una superficie rellena de `primaryContainer` con las esquinas
/// redondeadas: una tarjeta gigante apoyada sobre el fondo. Ese borde se veía,
/// y partia la pantalla en **dos objetos** en vez de en dos zonas —«la caja de
/// color» y «lo de al lado»—, pegados con cinta.
///
/// Acá el acento no tiene contorno. Son tres degradados radiales que arrancan
/// teñidos y terminan **en transparente**, pintados encima de `surface`. Donde
/// el resplandor se apaga no hay un límite: hay hoja. Por eso se mezcla con el
/// blanco y con el negro sin decidir nada: lo que queda cuando el color se
/// termina es el fondo del tema, sea cual sea.
///
/// ## De dónde salen los centros
///
/// `RadialGradient` toma `center` en coordenadas de alineación y `radius` como
/// fracción del lado más corto, así que el dibujo escala solo con la ventana.
/// No hay un solo píxel escrito a mano, y de paso se fue el parámetro `medida`
/// que hacía falta cuando las manchas estaban en píxeles.
///
/// ## Y por qué el texto ya no se apoya en él
///
/// Encima de este campo el texto usa `onSurface`, no `onPrimaryContainer`: el
/// fondo real sigue siendo `surface` con un tinte, y `onSurface` es el par que
/// Material garantiza contra ella. El tinte mas cargado llega a 0,42, que sobre
/// blanco deja la hoja cerca de un gris claro: `onSurface` encima sigue por
/// arriba de 9:1, asi que no hay que correr la cuenta con cada semilla.
class _CampoDeAcento extends StatelessWidget {
  final bool amplio;

  const _CampoDeAcento({required this.amplio});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    // En escritorio el resplandor se junta en la mitad izquierda, que es donde
    // está la marca, y se apaga antes de llegar al formulario. En teléfono se
    // junta arriba, por el mismo motivo.
    return IgnorePointer(
      child: Stack(
        children: amplio
            ? [
                // La primera va DETRAS de la marca, no en la esquina. Estuvo
                // arriba a la izquierda y el resultado era que justo abajo del
                // logo la hoja quedaba mas limpia que alrededor: la marca se
                // apoyaba en el hueco del resplandor en vez de en su centro.
                _mancha(cs.primary, const Alignment(-0.55, -0.30), 0.85, 0.42),
                _mancha(cs.tertiary, const Alignment(-0.12, 0.78), 0.75, 0.30),
                _mancha(cs.primary, const Alignment(-0.95, 0.60), 0.55, 0.24),
              ]
            : [
                _mancha(cs.primary, const Alignment(0, -0.62), 1.00, 0.38),
                _mancha(cs.tertiary, const Alignment(0.82, -0.28), 0.70, 0.24),
                _mancha(cs.primary, const Alignment(-0.78, -0.05), 0.60, 0.18),
              ],
      ),
    );
  }

  Widget _mancha(Color color, Alignment centro, double radio, double fuerza) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: centro,
            radius: radio,
            // Tres paradas y no dos: con dos, el alfa cae en linea recta desde
            // el centro y la mancha queda chata. La del medio le deja un nucleo
            // y recien despues la abre.
            //
            // Y el final es el MISMO color en alfa 0, no `Colors.transparent`:
            // ese es negro transparente, y al interpolar hacia el se ensucia el
            // matiz en el camino.
            colors: [
              color.withValues(alpha: fuerza),
              color.withValues(alpha: fuerza * 0.38),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
      ),
    );
  }
}

/// El logo, en un cuadrado de esquinas redondeadas.
///
/// Era un círculo con una sombra del propio acento debajo. La sombra de color
/// se fue —es el resplandor que la pantalla no necesitaba— y el círculo pasó a
/// cuadrado redondeado con la proporción de un ícono de app: es la forma que
/// tiene el resto de la pantalla y la que el ojo ya asocia con «esta es la
/// aplicación».
class _Marca extends StatelessWidget {
  final double lado;

  const _Marca({required this.lado});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Container(
      width: lado,
      height: lado,
      padding: EdgeInsets.all(lado * 0.24),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(lado * 0.28),
      ),
      child: SvgPicture.asset(
        'assets/icon/bosque_logo.svg',
        fit: BoxFit.contain,
        // El par que Material garantiza legible sobre `primary`, con cualquier
        // semilla y en los dos modos. Un blanco fijo se perdía sobre el
        // amarillo claro del modo oscuro.
        color: cs.onPrimary,
      ),
    );
  }
}

/// El resplandor que respira detrás del logo.
///
/// Es lo único perpetuo que quedó de las tres animaciones infinitas que había.
/// Sobrevivió porque es el más barato —repinta un cuadrado de ~200 px adentro
/// de un `RepaintBoundary`, no la pantalla entera— y porque está en el único
/// lugar donde un movimiento ambiental se justifica: la marca.
///
/// No escala nada: mueve la opacidad y el centro del degradado, que no obliga a
/// rehacer el layout.
class _Halo extends StatelessWidget {
  final Animation<double> latido;
  final Color color;

  const _Halo({required this.latido, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: latido,
          builder: (context, _) {
            final v = Curves.easeInOut.transform(latido.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.30 + 0.13 * v),
                    color.withValues(alpha: 0),
                  ],
                  stops: [0.16 + 0.10 * v, 1],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA ENTRADA
// ═══════════════════════════════════════════════════════════════════════════

/// Aparece un pedazo de la pantalla dentro de un tramo de la entrada.
///
/// Presentar la pantalla en orden —marca, encabezado, campos, botón— le dice al
/// ojo por dónde empezar. Todo junto de golpe no dice nada.
///
/// No usa `CurvedAnimation`: cada instancia crearía por build un objeto que hay
/// que dar de baja. La cuenta del intervalo es una resta y una división.
class _Entra extends StatelessWidget {
  final Animation<double> control;

  /// Tramo de [control] en el que ocurre, de 0 a 1.
  final double desde;
  final double hasta;

  /// Cuántos píxeles sube mientras aparece.
  final double desplazamiento;

  /// De qué escala parte. 1 = no escala.
  final double escalaDesde;

  final Widget child;

  const _Entra({
    required this.control,
    required this.desde,
    required this.hasta,
    this.desplazamiento = 0,
    this.escalaDesde = 1,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: control,
      builder: (context, hijo) {
        final crudo = ((control.value - desde) / (hasta - desde)).clamp(
          0.0,
          1.0,
        );
        final v = Curves.easeOutCubic.transform(crudo);

        Widget resultado = Opacity(opacity: v, child: hijo);
        if (desplazamiento != 0) {
          resultado = Transform.translate(
            offset: Offset(0, desplazamiento * (1 - v)),
            child: resultado,
          );
        }
        if (escalaDesde != 1) {
          resultado = Transform.scale(
            scale: escalaDesde + (1 - escalaDesde) * v,
            child: resultado,
          );
        }
        return resultado;
      },
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTROLES
// ═══════════════════════════════════════════════════════════════════════════

/// Los dos controles de tema.
///
/// Eran dos `GestureDetector` de 36 px sin tinta, sin foco y sin rótulo: dos
/// íconos que había que adivinar y apuntar. Ahora son `IconButton`, que trae el
/// área de 48 px, el efecto de tinta, el estado de hover y el tooltip que dice
/// qué hace cada uno.
class _ControlesDeTema extends StatelessWidget {
  final Color acento;
  final bool oscuro;
  final VoidCallback onPaleta;
  final VoidCallback onModo;

  const _ControlesDeTema({
    required this.acento,
    required this.oscuro,
    required this.onPaleta,
    required this.onModo,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Color del tema',
          onPressed: onPaleta,
          // El punto no es decoración: es el color que está puesto ahora. El
          // borde lo hace visible cuando el acento se parece a la hoja, que es
          // lo que pasa con la semilla amarilla en modo claro.
          icon: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: acento,
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant),
            ),
          ),
        ),
        IconButton(
          tooltip: oscuro ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
          onPressed: onModo,
          color: cs.onSurfaceVariant,
          // El ícono gira al cambiar: confirma que el toque llegó, en el mismo
          // gesto en que la pantalla entera cambia de modo.
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (hijo, anim) => RotationTransition(
              turns: Tween<double>(begin: 0.65, end: 1).animate(anim),
              child: FadeTransition(opacity: anim, child: hijo),
            ),
            child: Icon(
              oscuro ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey<bool>(oscuro),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

/// El `AutofillGroup` del formulario, salvo en la web.
///
/// En la web el grupo **rompe el foco**, y no de a poco: adentro de un grupo,
/// cuando un campo suelta su conexión de texto el motor de Flutter enfoca su
/// `<input>` del DOM y acto seguido le hace `blur`. Si el foco lo acababa de
/// tomar el otro campo del mismo grupo, ese `blur` se lo lleva puesto y la
/// pantalla queda sin nada enfocado.
///
/// Medido en Chrome: tanto Tab como Enter —que llama a
/// `_passwordFocus.requestFocus()`— dejaban los dos campos apagados, y lo que
/// se escribía después no aparecía en ninguno. Sin el grupo, la travesía de
/// foco de Flutter hace lo suyo y Tab, Mayús+Tab y Enter caminan los dos campos
/// y el botón como corresponde.
///
/// Lo que se pierde es el `<form>` que envolvía a los dos `<input>`. Las pistas
/// siguen puestas —el motor igual escribe `autocomplete="username"` y
/// `autocomplete="current-password"`—, así que el navegador sigue reconociendo
/// el par. En Android y iOS el grupo no molesta y queda como estaba, que es
/// donde el autocompletado del sistema realmente se usa.
class _GrupoDeAutocompletado extends StatelessWidget {
  final Widget child;

  const _GrupoDeAutocompletado({required this.child});

  @override
  Widget build(BuildContext context) =>
      kIsWeb ? child : AutofillGroup(child: child);
}

/// Un campo del formulario.
///
/// ## El rótulo no es el placeholder
///
/// Antes el nombre del campo vivía en `hintText`, así que se borraba en cuanto
/// alguien escribía la primera letra. Con dos campos apilados y el navegador
/// autocompletando los dos de una, no quedaba nada diciendo cuál era cuál.
/// `labelText` sube al borde en vez de irse.
///
/// ## Y el foco se ve
///
/// El borde pasa a 2 px del color principal y el ícono de la izquierda se pinta
/// del mismo color. Antes el borde era el mismo siempre: quien navega con
/// teclado no tenía forma de saber dónde estaba parado.
class _Campo extends StatelessWidget {
  final TextEditingController controlador;
  final FocusNode foco;
  final String etiqueta;
  final IconData icono;
  final List<String> pistas;
  final TextInputAction accion;
  final bool habilitado;
  final bool esClave;
  final bool oculto;
  final VoidCallback? onAlternarOculto;
  final VoidCallback onEnviar;

  const _Campo({
    required this.controlador,
    required this.foco,
    required this.etiqueta,
    required this.icono,
    required this.pistas,
    required this.accion,
    required this.habilitado,
    required this.onEnviar,
    this.esClave = false,
    this.oculto = true,
    this.onAlternarOculto,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    OutlineInputBorder borde(Color color, double grosor) => OutlineInputBorder(
      borderRadius: _esquina,
      borderSide: BorderSide(color: color, width: grosor),
    );

    return TextField(
      controller: controlador,
      focusNode: foco,
      // `readOnly` y no `enabled: false`: bloquea escribir mientras viaja la
      // consulta sin apagar el campo. Apagarlo lo pintaba de gris por medio
      // segundo, y quién está trabajando ya lo dice el botón.
      readOnly: !habilitado,
      obscureText: esClave && oculto,
      autofillHints: pistas,
      textInputAction: accion,
      onSubmitted: (_) => onEnviar(),
      style: TextStyle(color: cs.onSurface),
      cursorColor: cs.primary,
      decoration: InputDecoration(
        labelText: etiqueta,
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        prefixIcon: Icon(icono, size: 20),
        prefixIconColor: WidgetStateColor.resolveWith(
          (estados) => estados.contains(WidgetState.focused)
              ? cs.primary
              : cs.onSurfaceVariant,
        ),
        suffixIcon: esClave
            // `ExcludeFocus`: sin esto, tocar el ojo le saca el foco al campo y
            // en el teléfono se cierra el teclado en medio de escribir la
            // contraseña.
            ? ExcludeFocus(
                child: IconButton(
                  tooltip: oculto ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  onPressed: onAlternarOculto,
                  color: cs.onSurfaceVariant,
                  icon: Icon(
                    oculto
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                ),
              )
            : null,
        border: borde(cs.outlineVariant, 1),
        enabledBorder: borde(cs.outlineVariant, 1),
        focusedBorder: borde(cs.primary, 2),
      ),
    );
  }
}

/// El botón de entrar.
///
/// Mientras la consulta viaja **no se apaga**: se queda encendido, un poco más
/// tenue, con el indicador y la palabra que dice qué está pasando. Apagado con
/// los colores de deshabilitado parecía que se había roto justo al apretarlo.
class _BotonEntrar extends StatefulWidget {
  final bool cargando;
  final VoidCallback onPresionar;

  const _BotonEntrar({required this.cargando, required this.onPresionar});

  @override
  State<_BotonEntrar> createState() => _BotonEntrarState();
}

class _BotonEntrarState extends State<_BotonEntrar> {
  final WidgetStatesController _estados = WidgetStatesController();

  @override
  void dispose() {
    _estados.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    return ListenableBuilder(
      listenable: _estados,
      // El hundido de 1,5% al apretar. La tinta de Material dice «te escuché»;
      // el hundido dice «esto es un botón físico». Cuesta un `Transform`.
      builder: (context, hijo) => AnimatedScale(
        scale: _estados.value.contains(WidgetState.pressed) ? 0.985 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: hijo,
      ),
      child: FilledButton(
        statesController: _estados,
        onPressed: widget.cargando ? null : widget.onPresionar,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(borderRadius: _esquina),
          disabledBackgroundColor: cs.primary.withValues(alpha: 0.72),
          disabledForegroundColor: cs.onPrimary,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: Peso.titulo,
            letterSpacing: 0.2,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: widget.cargando
              ? Row(
                  key: const ValueKey('cargando'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: cs.onPrimary,
                      ),
                    ),
                    const SizedBox(width: Esp.m),
                    const Text('Verificando'),
                  ],
                )
              : const Row(
                  key: ValueKey('listo'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Iniciar sesión'),
                    SizedBox(width: Esp.s),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Lo que salió mal, o lo que hay que saber.
///
/// Los colores salen de `errorContainer` / `onErrorContainer`, el par que
/// Material garantiza legible. El rojo fijo de antes (`0xFFDC2626`) quedaba
/// idéntico al acento con la semilla roja: el error se veía como cualquier otra
/// cosa de la pantalla.
///
/// `liveRegion` hace que un lector de pantalla lo anuncie cuando aparece. Sin
/// eso, quien no ve la pantalla apretaba Entrar y no pasaba nada.
class _Aviso extends StatelessWidget {
  final String texto;
  final _Tono tono;

  const _Aviso({required this.texto, required this.tono});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final esError = tono == _Tono.error;

    final fondo = esError ? cs.errorContainer : cs.primaryContainer;
    final tinta = esError ? cs.onErrorContainer : cs.onPrimaryContainer;
    final borde = (esError ? cs.error : cs.primary).withValues(alpha: 0.35);

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Esp.m),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: _esquina,
          border: Border.all(color: borde),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              esError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: tinta,
              size: 19,
            ),
            const SizedBox(width: Esp.s),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tinta,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una semilla de la paleta, con su nombre debajo.
class _MuestraDeColor extends StatelessWidget {
  final Color color;
  final String nombre;
  final bool elegida;
  final VoidCallback onTap;

  const _MuestraDeColor({
    required this.color,
    required this.nombre,
    required this.elegida,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;

    // Negro o blanco encima del color, el que contraste más. Es la misma cuenta
    // que hacía la versión anterior y es honesta: no hay forma de saber de
    // antemano qué letra se lee sobre un amarillo y sobre un violeta.
    final tinta =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
        ? Colors.black87
        : Colors.white;

    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // El anillo se dibuja siempre, transparente cuando no está elegida,
          // para que las nueve muestras midan lo mismo y la grilla no salte al
          // cambiar de color.
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: elegida ? cs.onSurface : Colors.transparent,
                width: 2,
              ),
            ),
            child: Material(
              color: color,
              borderRadius: _esquina,
              child: InkWell(
                onTap: onTap,
                borderRadius: _esquina,
                child: SizedBox(
                  height: 58,
                  child: Center(
                    child: AnimatedScale(
                      scale: elegida ? 1 : 0,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutBack,
                      child: Icon(Icons.check_rounded, color: tinta, size: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Esp.xs),
          Text(
            nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: elegida ? cs.onSurface : cs.onSurfaceVariant,
              fontWeight: elegida ? Peso.dato : Peso.normal,
            ),
          ),
        ],
      ),
    );
  }
}
