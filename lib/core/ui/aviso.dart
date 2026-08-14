/// El aviso de la app: el mensajito que cuenta cómo salió una acción.
///
/// **Por qué no es un `SnackBar`.** El SnackBar lo dibuja el `Scaffold` de la
/// ruta de la pantalla; un diálogo o una hoja modal son OTRA ruta, montada
/// encima en el Overlay del Navigator. Así que el aviso salía abajo, tapado por
/// el diálogo y detrás de su velo oscuro. Pasó de verdad: «Regenerar» sobre un
/// rol publicado se rechaza con un mensaje de tres renglones que explica que hay
/// que reabrirlo a BORRADOR, y ese mensaje —el único que dice qué hacer— quedó
/// abajo, a medias, atrás del diálogo que lo provocó. No es un problema de
/// z-index: es de en qué capa vive cada cosa. Este aviso se inserta en el
/// Overlay **raíz**, que está por encima de todas las rutas, diálogos y hojas
/// modales incluidos.
///
/// Nació en el módulo del Rol de Sábados, pasó por
/// `presentation/widgets/shared/` y vive acá desde que se vio que el problema
/// no era de ese módulo: era de la app. El archivo viejo quedó como re-export
/// —lo importan 29 pantallas— así que **el código no cambió, sólo la carpeta**.
///
/// Junto con el aviso se re-exporta [humanizar], que es lo que traduce el
/// mensaje del backend antes de mostrarlo: quien avisa necesita las dos cosas,
/// y con un solo import las tiene.
library;

import 'dart:async';

import 'package:flutter/material.dart';

export 'package:bosque_flutter/core/ui/mensajes_usuario.dart';

/// Qué clase de cosa se está contando.
///
/// Son tres y no dos porque en la app hay tres semánticas: salió bien, salió
/// mal, y salió a medias o con una advertencia («no se envió el correo», «hay
/// documentos por vencer»).
enum TonoAviso {
  /// Salió bien.
  exito,

  /// No se pudo.
  error,

  /// Se pudo, pero hay algo que mirar.
  aviso,
}

/// Muestra [mensaje] arriba de todo, por encima de diálogos y hojas modales.
///
/// El texto se muestra **tal cual**: acá no se traduce ni se limpia nada. Quien
/// tenga que reescribir lo que devuelve el backend lo hace antes de llamar (ver
/// `mensajes_usuario.dart` del módulo de sábados, que hace justamente eso).
///
/// Un aviso a la vez, y gana el último: ver [_quitarAviso].
void mostrarAviso(
  BuildContext context,
  String mensaje, {
  TonoAviso tono = TonoAviso.exito,
}) {
  if (!context.mounted) return;

  // Cualquier app con Navigator tiene Overlay raíz. Si faltara sería un árbol
  // sin `MaterialApp`, o sea un test de un widget suelto: mejor no avisar que
  // reventar.
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final tema = Theme.of(context);

  // **Un aviso a la vez, y gana el último.** Apilarlos empuja al nuevo a un
  // segundo renglón —donde el ojo ya no está mirando— y encolarlos, que es lo
  // que hace `ScaffoldMessenger`, deja el importante esperando su turno detrás
  // de un «Listo». El aviso cuenta cómo salió la ÚLTIMA acción; el anterior ya
  // no describe nada de lo que hay en pantalla.
  _quitarAviso(_avisoVisible);

  late final OverlayEntry entrada;
  entrada = OverlayEntry(
    builder:
        (_) => Theme(
          // El tema se toma de quien avisa, no del Overlay: el Overlay raíz está
          // por encima de cualquier `Theme` local y ahí el aviso se vería de
          // otra app.
          data: tema,
          child: _Aviso(
            texto: mensaje,
            tono: tono,
            duracion: _cuantoDura(mensaje, tono != TonoAviso.exito),
            alCerrar: () => _quitarAviso(entrada),
          ),
        ),
  );

  _avisoVisible = entrada;
  overlay.insert(entrada);
}

/// El atajo de dos estados, que es como avisa casi toda la app.
///
/// La firma es la de siempre a propósito: cambia cómo se dibuja, no cómo se
/// llama, así que sus llamadores no se enteran. Para el tercer tono —una
/// advertencia que no es un fracaso— está [mostrarAviso].
void avisar(BuildContext context, String mensaje, {bool esError = false}) =>
    mostrarAviso(
      context,
      mensaje,
      tono: esError ? TonoAviso.error : TonoAviso.exito,
    );

/// El aviso que se está viendo, si hay alguno.
///
/// Es una variable global porque el aviso también lo es: vive en el Overlay
/// raíz, arriba de todas las pantallas, y no le pertenece a ninguna.
OverlayEntry? _avisoVisible;

/// Saca [entrada] del Overlay, **una sola vez**.
///
/// El «una sola vez» lo garantiza la identidad: toda entrada que se inserta
/// queda en [_avisoVisible] y sale de ahí justo cuando se la saca, así que el
/// segundo intento no encuentra nada. Hace falta porque hay tres caminos que
/// cierran un aviso —el reloj, el toque y el aviso siguiente que lo reemplaza—
/// y `OverlayEntry.remove()` revienta si se llama dos veces.
///
/// El otro guardia posible, `entrada.mounted`, sería un error: es `false`
/// durante todo el frame en que se insertó la entrada, así que dos avisos
/// seguidos dentro del mismo frame —pop del diálogo y aviso, el caso normal—
/// dejarían al primero pegado en pantalla para siempre.
void _quitarAviso(OverlayEntry? entrada) {
  if (entrada == null || !identical(_avisoVisible, entrada)) return;
  _avisoVisible = null;
  entrada.remove();
}

/// Cuánto se queda en pantalla: lo que tarda en leerse.
///
/// Un «Listo.» y un párrafo de tres renglones no pueden durar lo mismo; con los
/// 7 segundos fijos de antes, el mensaje del rol publicado se iba a la mitad.
/// ~18 caracteres por segundo es una lectura tranquila; el piso cubre el tiempo
/// de levantar la vista hasta el aviso y el techo evita que un texto largo se
/// quede clavado tapando la pantalla —igual se puede cerrar tocándolo—.
///
/// [urgente] es todo lo que no es un éxito: un error y una advertencia hay que
/// alcanzar a leerlos aunque sean cortos.
Duration _cuantoDura(String texto, bool urgente) {
  final piso = urgente ? 5.0 : 3.0;
  var segundos = 1.5 + texto.length / 18;
  if (segundos < piso) segundos = piso;
  if (segundos > 12) segundos = 12;
  return Duration(milliseconds: (segundos * 1000).round());
}

/// Ancho máximo del aviso.
///
/// Un aviso de ancho completo en un monitor de 1900 px es una franja de un
/// renglón larguísimo: el ojo pierde el principio de la línea siguiente. 560 px
/// deja unos 70 caracteres por renglón, que es el largo de línea con el que se
/// lee más cómodo. En una pantalla de 360 px el tope no se alcanza y manda el
/// ancho real menos los márgenes.
const double _anchoMaximoAviso = 560;

/// Margen contra el borde de la pantalla y aire vertical adentro de la tarjeta.
/// Los números son los de la escala de 4 de la app; van sueltos y no como
/// constante importada para que una pieza compartida no dependa de los tokens
/// de ningún módulo.
const double _aireChico = 12;

/// Aire horizontal adentro de la tarjeta.
const double _aireGrande = 16;

/// El aviso propiamente dicho: la tarjeta que se dibuja en el Overlay raíz.
///
/// **Va arriba y no abajo.** Abajo es lo conocido por el SnackBar, pero abajo a
/// la derecha están los botones del diálogo —«Cancelar», «Regenerar»— y abajo
/// también se abre el teclado. Arriba está siempre libre, no compite con nada
/// que se pueda tocar y encima es donde el sistema operativo pone sus propias
/// notificaciones, así que se lee como lo que es: algo que pasó por encima de la
/// pantalla.
class _Aviso extends StatefulWidget {
  const _Aviso({
    required this.texto,
    required this.tono,
    required this.duracion,
    required this.alCerrar,
  });

  final String texto;
  final TonoAviso tono;
  final Duration duracion;
  final VoidCallback alCerrar;

  @override
  State<_Aviso> createState() => _AvisoState();
}

class _AvisoState extends State<_Aviso> with SingleTickerProviderStateMixin {
  late final AnimationController _control = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  late final CurvedAnimation _curva = CurvedAnimation(
    parent: _control,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  Timer? _reloj;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    _control.forward();
    _reloj = Timer(widget.duracion, _cerrar);
  }

  @override
  void dispose() {
    // **El reloj lo tiene el aviso, no la pantalla que avisó.** El aviso
    // sobrevive a esa pantalla a propósito —`ejecutarAccion` hace `pop()` del
    // diálogo y avisa casi al mismo tiempo—, así que el temporizador tiene que
    // morir con el aviso y no con quien lo pidió. Sin este `cancel`, un aviso
    // reemplazado por otro seguiría contando y cerraría al que no era.
    _reloj?.cancel();
    _curva.dispose();
    _control.dispose();
    super.dispose();
  }

  /// Se va: porque se cumplió el tiempo o porque lo tocaron.
  ///
  /// Lo segundo tiene que funcionar siempre: un aviso pegado tapando la pantalla
  /// es peor que el problema que vino a resolver.
  Future<void> _cerrar() async {
    if (_cerrando) return;
    _cerrando = true;
    _reloj?.cancel();
    // Si otro aviso lo reemplaza durante la salida, este widget se desmonta y
    // el futuro del ticker nunca resuelve: no hay excepción, y `alCerrar` no
    // corre sobre una entrada que ya sacó el otro camino.
    await _control.reverse();
    if (mounted) widget.alCerrar();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // El error toma el rol de error del tema; el éxito, el mismo tono que el
    // tema le da a sus SnackBar, para que el aviso no parezca de otra app.
    //
    // La advertencia va en **terciario**, y no en un naranja escrito a mano,
    // porque el tema de esta app se arma con `colorSchemeSeed` sobre nueve
    // semillas a elección más modo claro y oscuro: un `Colors.orange` fijo
    // queda de otra paleta con ocho de las nueve, y en oscuro además pide
    // letra negra que nadie le pone. Material 3 no define un rol `warning`, y
    // de los que sí define el terciario es el único que se separa de `primary`
    // y de `error` con TODAS las semillas —el mismo motivo por el que el módulo
    // de sábados ya lo usa para su etiqueta de aviso—. Y `onTertiary` viene
    // garantizado legible sobre él, que es lo que un color a mano no garantiza.
    final (Color fondo, Color letra, IconData icono) = switch (widget.tono) {
      TonoAviso.error => (cs.error, cs.onError, Icons.error_outline),
      TonoAviso.aviso => (
        cs.tertiary,
        cs.onTertiary,
        Icons.warning_amber_rounded,
      ),
      TonoAviso.exito => (
        cs.inverseSurface,
        cs.onInverseSurface,
        Icons.check_circle_outline,
      ),
    };

    return Positioned(
      // Debajo de la muesca y la barra de estado: el Overlay raíz no las
      // descuenta, es la pantalla entera.
      top: MediaQuery.paddingOf(context).top + _aireChico,
      left: _aireChico,
      right: _aireChico,
      child: Semantics(
        container: true,
        // Que el lector de pantalla lo cante al aparecer, como haría con un
        // SnackBar: si no, el aviso se va antes de que nadie lo enfoque.
        liveRegion: true,
        child: FadeTransition(
          opacity: _curva,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.4),
              end: Offset.zero,
            ).animate(_curva),
            // La Row centra la tarjeta y la deja encoger: un «Listo.» es una
            // pastilla corta y un mensaje largo llega hasta el tope y ahí
            // envuelve. `Positioned` da alto libre, así que un `Center` acá
            // pediría alto infinito.
            //
            // El `Flexible` no es decorativo: una Row le ofrece ancho INFINITO
            // a los hijos que no lo son, así que en una pantalla de 360 px la
            // tarjeta se iba a los 560 del tope y se desbordaba. Con él, el tope
            // es el menor entre los 560 y el ancho que de verdad hay.
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _anchoMaximoAviso,
                    ),
                    child: Material(
                      color: fondo,
                      elevation: 6,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: _cerrar,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _aireGrande,
                            vertical: _aireChico,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icono, size: 20, color: letra),
                              const SizedBox(width: _aireChico),
                              Flexible(
                                child: Text(
                                  widget.texto,
                                  // Sin `maxLines`: el mensaje que explica cómo
                                  // reabrir el rol tiene tres renglones y cortarlo
                                  // lo dejaría sin la parte que dice qué hacer.
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: letra, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
