/// Los cartones de papel para elegir: boca abajo sobre la mesa, se inclinan
/// en 3D hacia el puntero y, al elegir uno, gira y revela sus números. Nunca
/// muestran los números antes de elegirlos; todo el color sale del tema.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/ui/mensajes_usuario.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_celda_entity.dart';
import 'package:bosque_flutter/domain/repositories/ttk_bingo_repository.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';

String _nro(int n) => n.toString().padLeft(4, '0');

bool _sinMovimiento(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Proporción de la hoja (ancho / alto), como un cartón impreso.
const double ttkProporcionCarton = 0.78;

/// Lo que se dibuja de un cartón sin revelarlo: matriz, letras y comodín.
class FormaCartonTtk {
  const FormaCartonTtk({
    this.filas = 5,
    this.columnas = 5,
    this.letras,
    this.conComodin = true,
  });

  final int filas;
  final int columnas;
  final String? letras;
  final bool conComodin;
}

// ═══════════════════════════════════════════════════════════════════════════
// LA HOJA
// ═══════════════════════════════════════════════════════════════════════════

/// Un cartón boca abajo: franja de letras, rejilla en relieve y su número.
/// Con mouse se inclina hacia el puntero y lo sigue un brillo; al tocarlo se hunde.
class CartonPapelTtk extends StatefulWidget {
  const CartonPapelTtk({
    super.key,
    required this.nroCarton,
    required this.forma,
    this.alTocar,
  });

  final int nroCarton;
  final FormaCartonTtk forma;
  final VoidCallback? alTocar;

  @override
  State<CartonPapelTtk> createState() => _CartonPapelTtkState();
}

class _CartonPapelTtkState extends State<CartonPapelTtk> {
  Offset _giro = Offset.zero;
  Alignment _luz = const Alignment(-0.6, -0.8);
  bool _encima = false;
  bool _presionado = false;

  /// Una torcedura propia de cada hoja, como papeles sueltos sobre la mesa.
  double get _reposo => math.sin(widget.nroCarton * 12.9898) * 0.026;

  void _seguir(Offset p, Size tam) {
    if (tam.isEmpty) return;
    final x = (p.dx / tam.width).clamp(0.0, 1.0) * 2 - 1;
    final y = (p.dy / tam.height).clamp(0.0, 1.0) * 2 - 1;
    setState(() {
      _encima = true;
      _giro = Offset(x * 0.26, -y * 0.26);
      _luz = Alignment(x, y);
    });
  }

  void _soltar() => setState(() {
    _encima = false;
    _presionado = false;
    _giro = Offset.zero;
  });

  @override
  Widget build(BuildContext context) {
    final tocable = widget.alTocar != null;
    final quieto = _sinMovimiento(context) || !tocable;
    final alto = _presionado ? 0.35 : (_encima ? 1.0 : 0.0);
    return Semantics(
      button: tocable,
      label: 'Cartón ${_nro(widget.nroCarton)}',
      child: LayoutBuilder(
        builder: (context, c) {
          final tam = c.biggest;
          final hoja = TweenAnimationBuilder<double>(
            tween: Tween(end: quieto ? 0 : alto),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            builder:
                (context, e, _) => TweenAnimationBuilder<Offset>(
                  tween: Tween(end: quieto ? Offset.zero : _giro),
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  builder:
                      (context, g, _) => Transform.translate(
                        offset: Offset(0, -10 * e),
                        child: Transform(
                          alignment: Alignment.center,
                          transform:
                              Matrix4.identity()
                                ..setEntry(3, 2, 0.0014)
                                ..rotateX(g.dy)
                                ..rotateY(g.dx)
                                ..rotateZ(tocable ? _reposo * (1 - e) : 0),
                          child: Transform.scale(
                            scale: _presionado ? 0.97 : 1 + 0.03 * e,
                            child: PapelCartonTtk(
                              nroCarton: widget.nroCarton,
                              forma: widget.forma,
                              elevacion: e,
                              luz: _luz,
                            ),
                          ),
                        ),
                      ),
                ),
          );
          if (!tocable) return hoja;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (ev) => _seguir(ev.localPosition, tam),
            onExit: (_) => _soltar(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => setState(() => _presionado = true),
              onTapCancel: () => setState(() => _presionado = false),
              onTapUp: (_) => setState(() => _presionado = false),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.alTocar!();
              },
              child: hoja,
            ),
          );
        },
      ),
    );
  }
}

/// El papel del cartón, sin interacción: lo comparten la mesa y la escena.
class PapelCartonTtk extends StatelessWidget {
  const PapelCartonTtk({
    super.key,
    required this.nroCarton,
    required this.forma,
    this.elevacion = 0,
    this.luz = const Alignment(-0.6, -0.8),
  });

  final int nroCarton;
  final FormaCartonTtk forma;

  /// De 0 (apoyado) a 1 (levantado): agranda la sombra y enciende el brillo.
  final double elevacion;
  final Alignment luz;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final papel = Color.alphaBlend(
      cs.primary.withValues(alpha: 0.035),
      cs.surfaceContainerLowest,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final radio = BorderRadius.circular(math.max(6, w * 0.06));
        return DecoratedBox(
          decoration: BoxDecoration(
            color: papel,
            borderRadius: radio,
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.10 + 0.10 * elevacion),
                blurRadius: 4 + 22 * elevacion,
                spreadRadius: -2 * elevacion,
                offset: Offset(0, 2 + 8 * elevacion),
              ),
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.08),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: w * 0.17,
                      color: cs.primary,
                      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                      child: Row(
                        children: [
                          for (var col = 0; col < forma.columnas; col++)
                            Expanded(
                              child: Text(
                                ttkLetra(forma.letras, col),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: ttkFuenteNumeros,
                                  fontWeight: Peso.dato,
                                  color: cs.onPrimary,
                                  fontSize: w * 0.09,
                                  height: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(w * 0.06),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _RejillaPapel(
                                forma: forma,
                                linea: cs.outlineVariant,
                                punto: cs.onSurfaceVariant.withValues(
                                  alpha: 0.16,
                                ),
                                estrella: cs.tertiary.withValues(alpha: 0.35),
                              ),
                            ),
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.07,
                                    vertical: w * 0.03,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: cs.primary,
                                      width: math.max(1.2, w * 0.012),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: cs.shadow.withValues(
                                          alpha: 0.10,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _nro(nroCarton),
                                    style: TextStyle(
                                      fontFamily: ttkFuenteNumeros,
                                      fontWeight: Peso.dato,
                                      fontFeatures: cifrasTabulares,
                                      fontSize: math.max(12, w * 0.17),
                                      color: cs.onSurface,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: w * 0.07,
                      child: CustomPaint(
                        painter: _Perforado(color: cs.outlineVariant),
                      ),
                    ),
                  ],
                ),
                Positioned.fill(child: TexturaPapelTtk(semilla: nroCarton)),
                if (elevacion > 0)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: luz,
                          radius: 1.1,
                          colors: [
                            Colors.white.withValues(alpha: 0.30 * elevacion),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// La rejilla en relieve tenue: casillas con un punto (el número va oculto)
/// y la estrella del comodín.
class _RejillaPapel extends CustomPainter {
  _RejillaPapel({
    required this.forma,
    required this.linea,
    required this.punto,
    required this.estrella,
  });

  final FormaCartonTtk forma;
  final Color linea;
  final Color punto;
  final Color estrella;

  @override
  void paint(Canvas canvas, Size size) {
    final f = math.max(1, forma.filas);
    final c = math.max(1, forma.columnas);
    final cw = size.width / c;
    final ch = size.height / f;
    final trazo =
        Paint()
          ..color = linea.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(3)),
      trazo,
    );
    for (var i = 1; i < c; i++) {
      canvas.drawLine(Offset(i * cw, 0), Offset(i * cw, size.height), trazo);
    }
    for (var i = 1; i < f; i++) {
      canvas.drawLine(Offset(0, i * ch), Offset(size.width, i * ch), trazo);
    }
    final relleno = Paint()..color = punto;
    final lado = math.min(cw, ch);
    for (var fila = 0; fila < f; fila++) {
      for (var col = 0; col < c; col++) {
        final centro = Offset((col + 0.5) * cw, (fila + 0.5) * ch);
        if (ttkEsComodin(fila * c + col, f, c, forma.conComodin)) {
          canvas.drawPath(
            _estrella(centro, lado * 0.3),
            Paint()..color = estrella,
          );
        } else {
          canvas.drawCircle(centro, lado * 0.1, relleno);
        }
      }
    }
  }

  Path _estrella(Offset centro, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final radio = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final punto = centro + Offset(math.cos(a) * radio, math.sin(a) * radio);
      i == 0 ? p.moveTo(punto.dx, punto.dy) : p.lineTo(punto.dx, punto.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(covariant _RejillaPapel v) =>
      v.forma != forma ||
      v.linea != linea ||
      v.punto != punto ||
      v.estrella != estrella;
}

/// La línea de perforación del pie, como un talón para cortar.
class _Perforado extends CustomPainter {
  _Perforado({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p =
        Paint()
          ..color = color
          ..strokeWidth = 1.2;
    final y = size.height * 0.35;
    for (var x = 4.0; x < size.width - 4; x += 7) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 3.5, size.width), y),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Perforado v) => v.color != color;
}

/// Entrada escalonada de las primeras hojas, como si se repartieran.
class RepartirTtk extends StatelessWidget {
  const RepartirTtk({
    super.key,
    required this.indice,
    required this.activo,
    required this.child,
  });

  final int indice;
  final bool activo;
  final Widget child;

  static const _paso = 40;
  static const _cuantas = 30;
  static const _vuelo = 460;

  @override
  Widget build(BuildContext context) {
    if (!activo || indice >= _cuantas || _sinMovimiento(context)) return child;
    const total = _vuelo + _cuantas * _paso;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: total),
      curve: Interval(
        indice * _paso / total,
        (indice * _paso + _vuelo) / total,
        curve: Curves.easeOutBack,
      ),
      child: child,
      builder:
          (context, v, hijo) => Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 36 * (1 - v)),
              child: Transform.rotate(
                angle: (1 - v) * (indice.isEven ? 0.18 : -0.18),
                child: hijo,
              ),
            ),
          ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA ESCENA DE ELEGIR
// ═══════════════════════════════════════════════════════════════════════════

class _Resultado {
  bool elegido = false;
}

/// El cartón tocado salta al centro sobre la mesa desenfocada; al confirmarlo
/// gira, revela sus números y cae papel picado. Devuelve si quedó elegido.
Future<bool> elegirCartonEnMesaTtk(
  BuildContext context, {
  required int nroCarton,
  required FormaCartonTtk forma,
  required Future<TtkRespuesta> Function() elegir,
  required Future<List<TtkBingoCeldaEntity>> Function() celdas,
}) async {
  final resultado = _Resultado();
  final quieto = _sinMovimiento(context);
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration:
        quieto ? Duration.zero : const Duration(milliseconds: 380),
    // Material transparente: los textos toman el estilo del tema.
    pageBuilder:
        (_, __, ___) => Material(
          type: MaterialType.transparency,
          child: _Escena(
            nroCarton: nroCarton,
            forma: forma,
            elegir: elegir,
            celdas: celdas,
            resultado: resultado,
          ),
        ),
    transitionBuilder: (context, a, _, hijo) {
      final curva = CurvedAnimation(
        parent: a,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      );
      return BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 6 * a.value, sigmaY: 6 * a.value),
        child: FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1).animate(curva),
            child: hijo,
          ),
        ),
      );
    },
  );
  return resultado.elegido;
}

enum _Fase { eligiendo, enviando, revelado, error }

class _Escena extends StatefulWidget {
  const _Escena({
    required this.nroCarton,
    required this.forma,
    required this.elegir,
    required this.celdas,
    required this.resultado,
  });

  final int nroCarton;
  final FormaCartonTtk forma;
  final Future<TtkRespuesta> Function() elegir;
  final Future<List<TtkBingoCeldaEntity>> Function() celdas;
  final _Resultado resultado;

  @override
  State<_Escena> createState() => _EscenaState();
}

class _EscenaState extends State<_Escena> with TickerProviderStateMixin {
  late final AnimationController _giro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );
  late final AnimationController _confeti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );
  _Fase _fase = _Fase.eligiendo;
  String _mensaje = '';
  List<TtkBingoCeldaEntity> _celdas = const [];

  @override
  void dispose() {
    _giro.dispose();
    _confeti.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() => _fase = _Fase.enviando);
    final TtkRespuesta r;
    try {
      r = await widget.elegir();
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _fase = _Fase.error;
        _mensaje = textoParaUsuario(e);
      });
      return;
    }
    widget.resultado.elegido = true;
    var celdas = const <TtkBingoCeldaEntity>[];
    try {
      celdas = await widget.celdas();
    } catch (_) {
      // Ya es suyo: si las casillas no llegan, las ve después en «Mi cartón».
    }
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _fase = _Fase.revelado;
      _mensaje = r.mensaje;
      _celdas = celdas;
    });
    if (_sinMovimiento(context)) {
      _giro.value = 1;
      return;
    }
    await _giro.forward();
    if (mounted) _confeti.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tam = MediaQuery.sizeOf(context);
    var ancho = math.min(tam.width - 2 * Esp.l, 380.0);
    var alto = ancho / ttkProporcionCarton;
    if (alto > tam.height * 0.56) {
      alto = tam.height * 0.56;
      ancho = alto * ttkProporcionCarton;
    }
    final hoja = AnimatedBuilder(
      animation: _giro,
      builder: (context, _) {
        final angulo = Curves.easeInOutCubic.transform(_giro.value) * math.pi;
        final reverso = angulo > math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform:
              Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angulo),
          child:
              reverso
                  ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: _Reverso(
                      nroCarton: widget.nroCarton,
                      letras: widget.forma.letras,
                      celdas: _celdas,
                    ),
                  )
                  : PapelCartonTtk(
                    nroCarton: widget.nroCarton,
                    forma: widget.forma,
                    elevacion: 1,
                  ),
        );
      },
    );
    return PopScope(
      canPop: _fase != _Fase.enviando,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Esp.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(width: ancho, height: alto, child: hoja),
                    Positioned(
                      left: -ancho * 0.35,
                      right: -ancho * 0.35,
                      top: -alto * 0.15,
                      bottom: -alto * 0.1,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _PapelPicado(
                            avance: _confeti,
                            colores: [
                              cs.primary,
                              cs.tertiary,
                              cs.secondary,
                              cs.primaryContainer,
                              cs.tertiaryContainer,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Esp.l),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: math.max(ancho, math.min(tam.width, 360)),
                  ),
                  child: _Pie(
                    nroCarton: widget.nroCarton,
                    fase: _fase,
                    mensaje: _mensaje,
                    alConfirmar: _confirmar,
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

/// La cara de los números, ya elegida: todos sus juegos en el mismo papel.
class _Reverso extends StatelessWidget {
  const _Reverso({
    required this.nroCarton,
    required this.letras,
    required this.celdas,
  });

  final int nroCarton;
  final String? letras;
  final List<TtkBingoCeldaEntity> celdas;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return _ConTextura(
      radio: BorderRadius.circular(Esquina.media),
      semilla: nroCarton,
      hijo: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            cs.primary.withValues(alpha: 0.035),
            cs.surfaceContainerLowest,
          ),
          borderRadius: BorderRadius.circular(Esquina.media),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(Esp.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cartón N° ${_nro(nroCarton)}',
                style: t.titleLarge?.copyWith(
                  fontFamily: ttkFuenteNumeros,
                  fontWeight: Peso.dato,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: Esp.s),
              Expanded(
                child:
                    celdas.isEmpty
                        ? Center(
                          child: Text(
                            'Ya es tuyo. Sus números están en «Mi cartón».',
                            textAlign: TextAlign.center,
                            style: t.bodyLarge,
                          ),
                        )
                        : SingleChildScrollView(
                          child: CartonCompletoTtk(
                            celdas: celdas,
                            letras: letras,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto y botones bajo la hoja, según la fase de la escena.
class _Pie extends StatelessWidget {
  const _Pie({
    required this.nroCarton,
    required this.fase,
    required this.mensaje,
    required this.alConfirmar,
  });

  final int nroCarton;
  final _Fase fase;
  final String mensaje;
  final VoidCallback alConfirmar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final enviando = fase == _Fase.enviando;
    final (titulo, detalle) = switch (fase) {
      _Fase.revelado => (
        mensaje.isEmpty ? '¡Es tuyo!' : mensaje,
        'Estos son tus números. Puedes verlo e imprimirlo desde «Mi cartón».',
      ),
      _Fase.error => (mensaje, 'Elige otro de la mesa.'),
      _ => (
        'Elegir el cartón N° ${_nro(nroCarton)}',
        'Una vez elegido no se puede cambiar.',
      ),
    };
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(Esquina.media),
      child: Padding(
        padding: const EdgeInsets.all(Esp.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                titulo,
                style: t.titleLarge?.copyWith(
                  fontWeight: Peso.titulo,
                  color: fase == _Fase.error ? cs.error : cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: Esp.xs),
            Text(
              detalle,
              style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: Esp.l),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: Esp.s,
              runSpacing: Esp.s,
              children: [
                if (fase == _Fase.revelado)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check),
                    label: const Text('Listo'),
                  )
                else ...[
                  TextButton(
                    onPressed:
                        enviando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Elegir otro'),
                  ),
                  if (fase != _Fase.error)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                      onPressed: enviando ? null : alConfirmar,
                      icon:
                          enviando
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.auto_awesome),
                      label: const Text('Elegir este cartón'),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Papel picado que estalla desde la hoja y cae; se repinta con [avance].
class _PapelPicado extends CustomPainter {
  _PapelPicado({required this.avance, required this.colores})
    : super(repaint: avance);

  final Animation<double> avance;
  final List<Color> colores;

  static final _piezas = List.generate(46, (i) {
    final r = math.Random(i * 7 + 3);
    return (
      angulo: -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 1.3,
      velocidad: 0.5 + r.nextDouble() * 0.6,
      giro: (r.nextDouble() - 0.5) * 14,
      lado: 5 + r.nextDouble() * 6,
      redonda: i % 3 == 0,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = avance.value;
    if (t <= 0 || t >= 1) return;
    final centro = Offset(size.width / 2, size.height * 0.42);
    for (var i = 0; i < _piezas.length; i++) {
      final p = _piezas[i];
      final d = p.velocidad * size.shortestSide * 0.8 * t;
      final pos =
          centro +
          Offset(
            math.cos(p.angulo) * d,
            math.sin(p.angulo) * d + 0.8 * size.height * t * t,
          );
      final pintura =
          Paint()
            ..color = colores[i % colores.length].withValues(
              alpha: (1 - t * t).clamp(0.0, 1.0),
            );
      canvas
        ..save()
        ..translate(pos.dx, pos.dy)
        ..rotate(p.giro * t);
      if (p.redonda) {
        canvas.drawCircle(Offset.zero, p.lado / 2, pintura);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.lado,
            height: p.lado * 0.45,
          ),
          pintura,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PapelPicado v) => v.colores != colores;
}

// ═══════════════════════════════════════════════════════════════════════════
// LA MESA Y LA HOJA DE JUEGO
// ═══════════════════════════════════════════════════════════════════════════

/// La mesa donde se apoyan las hojas: un foco de luz al centro.
class MesaTtk extends StatelessWidget {
  const MesaTtk({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Esquina.media),
        gradient: RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.3,
          colors: [cs.surfaceContainerHigh, cs.surface],
        ),
      ),
      child: child,
    );
  }
}

/// El juego en curso del cartón como hoja de papel apoyada en la mesa. Se
/// marca a mano con un sello de tinta; nunca señala lo que salió.
class HojaJuegoTtk extends StatefulWidget {
  const HojaJuegoTtk({
    super.key,
    required this.celdas,
    required this.filas,
    required this.columnas,
    required this.nroCarton,
    required this.marcas,
    this.letras,
    this.alTocar,
    this.maxCelda = 88,
  });

  final List<TtkBingoCeldaEntity> celdas;
  final int filas;
  final int columnas;
  final int nroCarton;
  final String? letras;
  final Set<int> marcas;

  /// Con [alTocar], cada casilla con número se sella o se borra al tocarla.
  final ValueChanged<int>? alTocar;
  final double maxCelda;

  @override
  State<HojaJuegoTtk> createState() => _HojaJuegoTtkState();
}

class _HojaJuegoTtkState extends State<HojaJuegoTtk> {
  Offset _giro = Offset.zero;

  void _seguir(Offset p, Size tam) {
    if (tam.isEmpty) return;
    final x = (p.dx / tam.width).clamp(0.0, 1.0) * 2 - 1;
    final y = (p.dy / tam.height).clamp(0.0, 1.0) * 2 - 1;
    setState(() => _giro = Offset(x * 0.05, -y * 0.05));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final quieto = _sinMovimiento(context);
    final porPosicion = {for (final c in widget.celdas) c.posicion: c};
    return LayoutBuilder(
      builder: (context, c) {
        const borde = Esp.m;
        final celda =
            ((c.maxWidth - 2 * borde) / widget.columnas)
                .clamp(36.0, widget.maxCelda)
                .toDouble();
        final ancho = celda * widget.columnas + 2 * borde;
        final hoja = _ConTextura(
          radio: BorderRadius.circular(Esquina.media),
          semilla: widget.nroCarton,
          hijo: DecoratedBox(
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                cs.primary.withValues(alpha: 0.035),
                cs.surfaceContainerLowest,
              ),
              borderRadius: BorderRadius.circular(Esquina.media),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.7),
              ),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.16),
                  blurRadius: 26,
                  spreadRadius: -4,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.08),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(borde, borde, borde, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: celda * 0.5,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(Esquina.chica),
                    ),
                    child: Row(
                      children: [
                        for (var col = 0; col < widget.columnas; col++)
                          Expanded(
                            child: Text(
                              ttkLetra(widget.letras, col),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: ttkFuenteNumeros,
                                fontWeight: Peso.dato,
                                color: cs.onPrimary,
                                fontSize: celda * 0.3,
                                height: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Esp.s),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(Esquina.chica / 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var f = 0; f < widget.filas; f++)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var col = 0; col < widget.columnas; col++)
                                _CasillaJuego(
                                  dato: porPosicion[f * widget.columnas + col],
                                  lado: celda - 2 / widget.columnas,
                                  letra: ttkLetra(widget.letras, col),
                                  sellada: widget.marcas.contains(
                                    f * widget.columnas + col,
                                  ),
                                  lineaDerecha: col < widget.columnas - 1,
                                  lineaAbajo: f < widget.filas - 1,
                                  semilla: widget.nroCarton * 97 + f * 13 + col,
                                  alTocar: widget.alTocar,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: Esp.l,
                    child: CustomPaint(
                      size: Size(ancho, Esp.l),
                      painter: _Perforado(color: cs.outlineVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        // Apoyada en la mesa y apenas inclinada; con mouse se mece hacia el puntero.
        return Center(
          child: SizedBox(
            width: ancho,
            child: MouseRegion(
              onHover:
                  quieto
                      ? null
                      : (e) => _seguir(e.localPosition, Size(ancho, ancho)),
              onExit: (_) => setState(() => _giro = Offset.zero),
              child: TweenAnimationBuilder<Offset>(
                tween: Tween(end: quieto ? Offset.zero : _giro),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: hoja,
                builder:
                    (context, g, hijo) => Transform(
                      alignment: Alignment.center,
                      transform:
                          Matrix4.identity()
                            ..setEntry(3, 2, 0.0008)
                            ..rotateX((quieto ? 0 : 0.05) + g.dy)
                            ..rotateY(g.dx),
                      child: hijo,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Una casilla de la hoja: número a mano alzada, la figura tenue y el sello
/// de tinta cuando el participante la marca.
class _CasillaJuego extends StatelessWidget {
  const _CasillaJuego({
    required this.dato,
    required this.lado,
    required this.letra,
    required this.sellada,
    required this.lineaDerecha,
    required this.lineaAbajo,
    required this.semilla,
    required this.alTocar,
  });

  final TtkBingoCeldaEntity? dato;
  final double lado;
  final String letra;
  final bool sellada;
  final bool lineaDerecha;
  final bool lineaAbajo;
  final int semilla;
  final ValueChanged<int>? alTocar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = dato;
    final linea = BorderSide(color: cs.outlineVariant.withValues(alpha: 0.8));
    final quieto = _sinMovimiento(context);
    final casilla = Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color:
            (d?.enFigura ?? false)
                ? cs.primaryContainer.withValues(alpha: 0.55)
                : null,
        border: Border(
          right: lineaDerecha ? linea : BorderSide.none,
          bottom: lineaAbajo ? linea : BorderSide.none,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedSwitcher(
            duration:
                quieto ? Duration.zero : const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder:
                (hijo, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.45, end: 1).animate(a),
                    child: hijo,
                  ),
                ),
            child:
                sellada && d != null && !d.esComodin
                    ? CustomPaint(
                      key: const ValueKey('tinta'),
                      size: Size.square(lado),
                      painter: _Tinta(
                        semilla: semilla,
                        color: cs.tertiary.withValues(alpha: 0.42),
                      ),
                    )
                    : SizedBox.square(
                      key: const ValueKey('limpia'),
                      dimension: lado,
                    ),
          ),
          if (d != null && d.esComodin)
            Icon(Icons.star_rounded, size: lado * 0.55, color: cs.tertiary)
          else if (d != null)
            Text(
              '${d.numero}',
              style: TextStyle(
                fontFamily: ttkFuenteNumeros,
                fontWeight: sellada ? FontWeight.w800 : Peso.dato,
                fontFeatures: cifrasTabulares,
                fontSize: lado * 0.4,
                color: cs.onSurface,
              ),
            ),
        ],
      ),
    );
    final tocar = alTocar;
    if (tocar == null || d == null || d.esComodin) return casilla;
    return Semantics(
      button: true,
      toggled: sellada,
      label: '${letra.isEmpty ? '' : '$letra '}${d.numero}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          tocar(d.posicion);
        },
        child: MouseRegion(cursor: SystemMouseCursors.click, child: casilla),
      ),
    );
  }
}

/// El sello de tinta del marcador: mancha irregular, borde más cargado y
/// gotitas alrededor. La forma es fija por casilla para que no «baile».
class _Tinta extends CustomPainter {
  _Tinta({required this.semilla, required this.color});

  final int semilla;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(semilla);
    final centro =
        size.center(Offset.zero) +
        Offset(
          (r.nextDouble() - 0.5) * size.width * 0.06,
          (r.nextDouble() - 0.5) * size.height * 0.06,
        );
    final radio = size.shortestSide * 0.4;
    const n = 14;
    final puntos = [
      for (var i = 0; i < n; i++)
        centro +
            Offset.fromDirection(
              i * 2 * math.pi / n,
              radio * (0.88 + r.nextDouble() * 0.18),
            ),
    ];
    Offset medio(Offset a, Offset b) =>
        Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final inicio = medio(puntos.last, puntos.first);
    final mancha = Path()..moveTo(inicio.dx, inicio.dy);
    for (var i = 0; i < n; i++) {
      final m = medio(puntos[i], puntos[(i + 1) % n]);
      mancha.quadraticBezierTo(puntos[i].dx, puntos[i].dy, m.dx, m.dy);
    }
    mancha.close();
    canvas.drawPath(mancha, Paint()..color = color);
    canvas.drawPath(
      mancha,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radio * 0.12,
    );
    for (var i = 0; i < 3; i++) {
      final gota =
          centro +
          Offset.fromDirection(
            r.nextDouble() * 2 * math.pi,
            radio * (1.08 + r.nextDouble() * 0.22),
          );
      canvas.drawCircle(
        gota,
        radio * (0.04 + r.nextDouble() * 0.06),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Tinta v) =>
      v.semilla != semilla || v.color != color;
}

// ═══════════════════════════════════════════════════════════════════════════
// TEXTURA DEL PAPEL
// ═══════════════════════════════════════════════════════════════════════════

/// El mosaico de la textura (grano, fibras y nubes), dibujado una sola vez por
/// brillo del tema y repetido en todas las hojas: cientos de cartones no pesan.
abstract final class _Grano {
  static const double _lado = 256;
  static final Map<bool, ui.Image> _cache = {};

  static ui.Image mosaico(bool oscuro) => _cache[oscuro] ??= _dibujar(oscuro);

  static ui.Image _dibujar(bool oscuro) {
    final grabadora = ui.PictureRecorder();
    // Al doble de resolución: el grano se ve nítido en pantallas densas.
    final c = Canvas(grabadora)..scale(2);
    final r = math.Random(7);
    final tinta = oscuro ? Colors.white : Colors.black;
    final luz = oscuro ? Colors.black : Colors.white;
    Offset azar() => Offset(r.nextDouble() * _lado, r.nextDouble() * _lado);

    // Copias desplazadas cerca de los bordes: el mosaico se repite sin costuras.
    void enMosaico(Offset p, double margen, void Function(Offset q) dibujar) {
      for (final dx in const [-_lado, 0.0, _lado]) {
        for (final dy in const [-_lado, 0.0, _lado]) {
          final q = p + Offset(dx, dy);
          if (q.dx > -margen &&
              q.dx < _lado + margen &&
              q.dy > -margen &&
              q.dy < _lado + margen) {
            dibujar(q);
          }
        }
      }
    }

    for (var i = 0; i < 14; i++) {
      final radio = 18 + r.nextDouble() * 40;
      final nube =
          Paint()
            ..color = tinta.withValues(alpha: 0.02)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radio * 0.6);
      enMosaico(azar(), radio * 2, (q) => c.drawCircle(q, radio, nube));
    }
    for (var i = 0; i < 110; i++) {
      final angulo = r.nextDouble() * math.pi;
      final largo = 5 + r.nextDouble() * 15;
      final curva = (r.nextDouble() - 0.5) * 6;
      final fibra =
          Paint()
            ..color = tinta.withValues(alpha: 0.035 + r.nextDouble() * 0.04)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 0.35 + r.nextDouble() * 0.45;
      enMosaico(azar(), largo, (q) {
        final fin = q + Offset.fromDirection(angulo, largo);
        final medio =
            Offset((q.dx + fin.dx) / 2, (q.dy + fin.dy) / 2) +
            Offset.fromDirection(angulo + math.pi / 2, curva);
        c.drawPath(
          Path()
            ..moveTo(q.dx, q.dy)
            ..quadraticBezierTo(medio.dx, medio.dy, fin.dx, fin.dy),
          fibra,
        );
      });
    }
    for (var i = 0; i < 2600; i++) {
      c.drawCircle(
        azar(),
        0.3 + r.nextDouble() * 0.5,
        Paint()..color = tinta.withValues(alpha: 0.03 + r.nextDouble() * 0.05),
      );
    }
    for (var i = 0; i < 900; i++) {
      c.drawCircle(
        azar(),
        0.3 + r.nextDouble() * 0.6,
        Paint()..color = luz.withValues(alpha: 0.06 + r.nextDouble() * 0.08),
      );
    }
    return grabadora.endRecording().toImageSync(
      (_lado * 2).toInt(),
      (_lado * 2).toInt(),
    );
  }
}

/// Grano, fibras y bordes gastados del papel, encima de lo impreso con poca
/// opacidad (la tinta también queda «sobre el papel»). No capta toques.
class TexturaPapelTtk extends StatelessWidget {
  const TexturaPapelTtk({super.key, this.semilla = 0});

  /// Desplaza el mosaico: dos hojas vecinas no muestran el mismo grano.
  final int semilla;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _TexturaPapel(
          oscuro: tema.brightness == Brightness.dark,
          sombra: tema.colorScheme.shadow,
          semilla: semilla,
        ),
      ),
    );
  }
}

/// Pone la textura encima de una hoja ya decorada, recortada a su esquina.
class _ConTextura extends StatelessWidget {
  const _ConTextura({
    required this.radio,
    required this.semilla,
    required this.hijo,
  });

  final BorderRadius radio;
  final int semilla;
  final Widget hijo;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      hijo,
      Positioned.fill(
        child: ClipRRect(
          borderRadius: radio,
          child: TexturaPapelTtk(semilla: semilla),
        ),
      ),
    ],
  );
}

class _TexturaPapel extends CustomPainter {
  _TexturaPapel({
    required this.oscuro,
    required this.sombra,
    required this.semilla,
  });

  final bool oscuro;
  final Color sombra;
  final int semilla;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final matriz = Matrix4.diagonal3Values(0.5, 0.5, 1)..setTranslationRaw(
      -((semilla * 37) % _Grano._lado),
      -((semilla * 91) % _Grano._lado),
      0,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ImageShader(
          _Grano.mosaico(oscuro),
          TileMode.repeated,
          TileMode.repeated,
          matriz.storage,
        ),
    );
    // Bordes apenas más gastados que el centro, donde da la luz.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 1.15,
          colors: [sombra.withValues(alpha: 0), sombra.withValues(alpha: 0.07)],
          stops: const [0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _TexturaPapel v) =>
      v.oscuro != oscuro || v.sombra != sombra || v.semilla != semilla;
}
