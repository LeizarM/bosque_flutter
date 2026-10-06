/// La linea de estado que va debajo de «Talonario manual» y «Recibo manual» del
/// formulario de cheque: avisa mientras se escribe si el par no corresponde a un
/// talonario de la empresa, en vez de esperar a «Registrar cheque».
///
/// Es solo un aviso temprano. **No bloquea nada**: el servidor vuelve a validar
/// al guardar y su respuesta manda. Por eso un fallo de la consulta (red, 400,
/// 403) no es un error en rojo sino un aviso neutro.
///
/// [ComprobadorTalonarioCheque] lleva el tiempo (espera de 600 ms desde la ultima
/// tecla) y descarta las respuestas viejas; [AvisoTalonarioCheque] solo dibuja.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/talonario_validacion_entity.dart';
import 'package:bosque_flutter/domain/utils/comprobar_talonario_cheque.dart';

/// En que punto esta la comprobacion.
enum FaseTalonarioCheque {
  /// Nada que decir: no hay par que comprobar, o es valido y sin detalle.
  ninguna,

  /// Espera de la ultima tecla y consulta en curso.
  comprobando,

  /// El servidor lo acepto y dio un dato util ([EstadoTalonarioCheque.texto]).
  valido,

  /// El servidor lo rechazo; [EstadoTalonarioCheque.texto] es el motivo completo.
  invalido,

  /// La consulta fallo: no se sabe nada, el servidor decidira al guardar.
  noComprobado,
}

/// Lo que muestra la linea: la fase y, segun ella, un texto.
class EstadoTalonarioCheque {
  const EstadoTalonarioCheque(this.fase, [this.texto]);

  final FaseTalonarioCheque fase;
  final String? texto;

  static const EstadoTalonarioCheque ninguno = EstadoTalonarioCheque(
    FaseTalonarioCheque.ninguna,
  );

  /// Si hay algo que dibujar.
  bool get visible => fase != FaseTalonarioCheque.ninguna;

  @override
  bool operator ==(Object other) =>
      other is EstadoTalonarioCheque &&
      other.fase == fase &&
      other.texto == texto;

  @override
  int get hashCode => Object.hash(fase, texto);
}

/// Pregunta al servidor por un par talonario / recibo. Devuelve lo que este
/// responde; cualquier excepcion se toma por «no se pudo comprobar».
typedef ConsultaTalonarioCheque =
    Future<TalonarioValidacionEntity> Function(
      int codEmpresa,
      String talonario,
      String recibo,
    );

/// El texto cuando el servidor rechaza el par sin dar el motivo.
const String textoTalonarioSinMotivo =
    'El servidor indica que este talonario o recibo no es válido.';

/// El texto cuando la consulta no pudo hacerse.
const String textoTalonarioNoComprobado =
    'No se pudo comprobar el talonario ahora; se validará al guardar.';

/// El texto mientras se espera.
const String textoTalonarioComprobando = 'Comprobando talonario…';

/// Decide cuando consultar y que mostrar. Vive en el `State` del formulario y se
/// libera en su `dispose`: cancela lo pendiente y no avisa a nadie despues.
///
/// Cada llamada a [programar] anula la anterior, tambien una consulta ya enviada:
/// su respuesta, si llega tarde, se ignora (contador de secuencia).
class ComprobadorTalonarioCheque extends ChangeNotifier {
  ComprobadorTalonarioCheque({
    required this.consultar,
    this.espera = esperaComprobarTalonario,
  });

  final ConsultaTalonarioCheque consultar;
  final Duration espera;

  Timer? _temporizador;
  int _secuencia = 0;
  bool _cerrado = false;
  EstadoTalonarioCheque _estado = EstadoTalonarioCheque.ninguno;

  EstadoTalonarioCheque get estado => _estado;

  /// Debe llamarse cada vez que cambia el talonario, el recibo o la empresa.
  ///
  /// Sin empresa, o si [debeComprobarTalonario] dice que no, limpia la linea y
  /// cancela lo pendiente. Si dice que si, muestra «Comprobando…» ya (el
  /// resultado anterior quedo viejo) y consulta cuando pasa [espera] sin
  /// novedades.
  void programar({
    required int? codEmpresa,
    required String talonario,
    required String recibo,
  }) {
    if (_cerrado) return;
    _secuencia++;
    _temporizador?.cancel();
    _temporizador = null;

    if (codEmpresa == null || !debeComprobarTalonario(talonario, recibo)) {
      _poner(EstadoTalonarioCheque.ninguno);
      return;
    }

    _poner(const EstadoTalonarioCheque(FaseTalonarioCheque.comprobando));
    final turno = _secuencia;
    final t = talonario.trim();
    final r = recibo.trim();
    _temporizador = Timer(espera, () => _consultar(turno, codEmpresa, t, r));
  }

  Future<void> _consultar(
    int turno,
    int codEmpresa,
    String talonario,
    String recibo,
  ) async {
    if (_cerrado) return;
    EstadoTalonarioCheque resultado;
    try {
      final r = await consultar(codEmpresa, talonario, recibo);
      resultado = _traducir(r);
    } catch (_) {
      // Red, 400 o 403: el servidor validara igual al guardar.
      resultado = const EstadoTalonarioCheque(
        FaseTalonarioCheque.noComprobado,
        textoTalonarioNoComprobado,
      );
    }
    // Llego tarde: el usuario ya cambio algo, o cerro el formulario.
    if (_cerrado || turno != _secuencia) return;
    _poner(resultado);
  }

  static EstadoTalonarioCheque _traducir(TalonarioValidacionEntity r) {
    if (!r.valido) {
      final motivo = (r.mensaje ?? '').trim();
      return EstadoTalonarioCheque(
        FaseTalonarioCheque.invalido,
        motivo.isEmpty ? textoTalonarioSinMotivo : motivo,
      );
    }
    // Valido sin dato util: no hay nada que decir.
    final detalle = (r.detalle ?? '').trim();
    if (detalle.isEmpty) return EstadoTalonarioCheque.ninguno;
    return EstadoTalonarioCheque(FaseTalonarioCheque.valido, detalle);
  }

  void _poner(EstadoTalonarioCheque nuevo) {
    if (_cerrado || nuevo == _estado) return;
    _estado = nuevo;
    notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    _temporizador?.cancel();
    _temporizador = null;
    super.dispose();
  }
}

/// Claves de cada fase, para las pruebas.
const claveAvisoTalonarioComprobando = ValueKey<String>(
  'aviso-talonario-comprobando',
);
const claveAvisoTalonarioValido = ValueKey<String>('aviso-talonario-valido');
const claveAvisoTalonarioInvalido = ValueKey<String>(
  'aviso-talonario-invalido',
);
const claveAvisoTalonarioNoComprobado = ValueKey<String>(
  'aviso-talonario-no-comprobado',
);

/// Dibuja el [estado]. Con `ninguna` no ocupa nada.
///
/// Los colores salen del `ColorScheme` (el usuario elige 1 de 9 semillas mas
/// claro u oscuro). El mensaje del servidor se muestra **completo**, sin recortar,
/// y a lo ancho disponible: a 390 px y con texto grande crece hacia abajo.
class AvisoTalonarioCheque extends StatelessWidget {
  const AvisoTalonarioCheque({super.key, required this.estado});

  final EstadoTalonarioCheque estado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final texto = (estado.texto ?? '').trim();

    final Widget cuerpo = switch (estado.fase) {
      FaseTalonarioCheque.ninguna => const SizedBox.shrink(),
      FaseTalonarioCheque.comprobando => _LineaDiscreta(
        key: claveAvisoTalonarioComprobando,
        icono: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        texto: textoTalonarioComprobando,
      ),
      FaseTalonarioCheque.noComprobado => _LineaDiscreta(
        key: claveAvisoTalonarioNoComprobado,
        icono: Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
        texto: texto.isEmpty ? textoTalonarioNoComprobado : texto,
      ),
      FaseTalonarioCheque.valido => _Recuadro(
        key: claveAvisoTalonarioValido,
        fondo: cs.primaryContainer,
        letra: cs.onPrimaryContainer,
        icono: Icons.check_circle_outline,
        texto: texto,
        estilo: t.bodyMedium,
      ),
      FaseTalonarioCheque.invalido => _Recuadro(
        key: claveAvisoTalonarioInvalido,
        fondo: cs.errorContainer,
        letra: cs.onErrorContainer,
        icono: Icons.error_outline,
        texto: texto.isEmpty ? textoTalonarioSinMotivo : texto,
        estilo: t.bodyMedium,
      ),
    };

    // Un cambio de estado se anuncia solo a quien usa lector de pantalla.
    return Semantics(container: true, liveRegion: true, child: cuerpo);
  }
}

/// «Comprobando…» y «no se pudo comprobar»: sin recuadro, no compiten con el
/// formulario.
class _LineaDiscreta extends StatelessWidget {
  const _LineaDiscreta({super.key, required this.icono, required this.texto});

  final Widget icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final estilo = context.apagado();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El icono se centra en la primera linea del texto, tambien con la
        // letra agrandada.
        SizedBox(
          width: 16,
          height: _altoDeLinea(context, estilo),
          child: Center(child: icono),
        ),
        const SizedBox(width: Esp.s),
        Expanded(child: Text(texto, style: estilo)),
      ],
    );
  }
}

/// Lo que mide una linea de texto con [estilo] y la escala de letra del usuario.
double _altoDeLinea(BuildContext context, TextStyle? estilo) =>
    MediaQuery.textScalerOf(context).scale(estilo?.fontSize ?? 14) *
    (estilo?.height ?? 1.3);

/// El resultado del servidor, en un recuadro. Texto completo, tal cual: los
/// saltos de linea del mensaje se conservan.
class _Recuadro extends StatelessWidget {
  const _Recuadro({
    super.key,
    required this.fondo,
    required this.letra,
    required this.icono,
    required this.texto,
    required this.estilo,
  });

  final Color fondo;
  final Color letra;
  final IconData icono;
  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Esp.m),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Esquina.chica),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: _altoDeLinea(context, estilo),
            child: Center(child: Icon(icono, size: 20, color: letra)),
          ),
          const SizedBox(width: Esp.s),
          Expanded(child: Text(texto, style: estilo?.copyWith(color: letra))),
        ],
      ),
    );
  }
}
