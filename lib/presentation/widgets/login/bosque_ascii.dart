/// «Bosque de papel»: el fondo animado del login, hecho de caracteres. Un bosque
/// de pinos en tres planos que se mece y una bandada de aves de papel que vuela
/// junta, se espanta con el puntero y deja estelas de viento.
///
/// La técnica viene de ascii-sharks: grilla de celdas más altas que anchas,
/// rampa de densidad según la luz, bandada tipo boids y un campo de energía que
/// se difunde y se apaga. Los colores salen del ColorScheme (semilla y modo del
/// usuario) y con «reducir movimiento» queda un cuadro quieto.
library;

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class BosqueAscii extends StatefulWidget {
  const BosqueAscii({
    super.key,
    this.altoBosque = 0.42,
    this.techoAves,
    this.densidadAves = 1,
    this.intensidad = 1,
    this.pausado = false,
  });

  /// Detiene la animación (p. ej. mientras se inicia sesión) sin borrar nada.
  final bool pausado;

  /// Fracción del alto que ocupa el bosque, contada desde abajo.
  final double altoBosque;

  /// Hasta qué fracción del alto bajan las aves; por defecto, hasta el bosque.
  final double? techoAves;

  /// Multiplica la cantidad de aves (menos en pantallas chicas).
  final double densidadAves;

  /// Multiplica la opacidad de todo: menos donde hay texto encima.
  final double intensidad;

  @override
  State<BosqueAscii> createState() => _BosqueAsciiState();
}

class _BosqueAsciiState extends State<BosqueAscii>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _escena = _Escena();
  final _cuadro = ValueNotifier<int>(0);
  Duration _anterior = Duration.zero;
  double _acumulado = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizarTicker();
  }

  @override
  void didUpdateWidget(covariant BosqueAscii old) {
    super.didUpdateWidget(old);
    if (old.pausado != widget.pausado) _sincronizarTicker();
  }

  /// Para las pruebas de rendimiento: si el reloj corre y cuánta caché hay.
  @visibleForTesting
  bool get animando => _ticker.isActive;
  @visibleForTesting
  int get letrasEnCache => _escena.letrasEnCache;
  @visibleForTesting
  int get hojasEnElAire => _escena.hojasEnElAire;
  @visibleForTesting
  bool get hayHalcon => _escena.halcon != null;

  /// Anima solo si nadie pidió quietud: ni el sistema ni la pantalla.
  void _sincronizarTicker() {
    final quieto =
        widget.pausado ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (quieto && _ticker.isActive) _ticker.stop();
    if (!quieto && !_ticker.isActive) {
      _anterior = Duration.zero;
      _acumulado = 0;
      _ticker.start();
    }
  }

  void _tick(Duration t) {
    final dt =
        _anterior == Duration.zero
            ? 0.0
            : (t - _anterior).inMicroseconds / Duration.microsecondsPerSecond;
    _anterior = t;
    _acumulado += dt.clamp(0.0, 0.1);
    // 30 cuadros por segundo alcanzan para el estilo y cuestan la mitad.
    if (_acumulado < 1 / 30) return;
    _escena.avanzar(_acumulado);
    _acumulado = 0;
    _cuadro.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cuadro.dispose();
    _escena.liberar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        final tam = Size(
          c.maxWidth.isFinite ? c.maxWidth : 0,
          c.maxHeight.isFinite ? c.maxHeight : 0,
        );
        _escena.ajustar(
          tam,
          altoBosque: widget.altoBosque,
          techoAves: widget.techoAves,
          densidad: widget.densidadAves,
        );
        return MouseRegion(
          opaque: false,
          onHover: (e) => _escena.puntero = e.localPosition,
          onExit: (_) => _escena.puntero = null,
          child: RepaintBoundary(
            child: CustomPaint(
              size: tam,
              painter: _PintorBosque(_escena, cs, widget.intensidad, _cuadro),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LA ESCENA: SIMULACIÓN Y GRILLA
// ═══════════════════════════════════════════════════════════════════════════

/// Rampas de cada plano, de la cara iluminada (rala) a la sombra (densa).
const _rampas = ['.:;', ':;+=', ';+*%#@'];

const _cBarra = 0x2F, _cContra = 0x5C, _cPunta = 0x5E, _cTronco = 0x7C;

/// Ave cercana, 5×2 (columna y fila relativas al cuerpo `v`): alas arriba
/// `\   /` sobre ` \v/ `, planeo `--v--`, y alas abajo ` _v_ ` sobre `/   \`.
const _aveArriba = [
  (-2, -1, _cContra),
  (2, -1, _cBarra),
  (-1, 0, _cContra),
  (0, 0, 0x76),
  (1, 0, _cBarra),
];
const _avePlaneo = [
  (-2, 0, 0x2D),
  (-1, 0, 0x2D),
  (0, 0, 0x76),
  (1, 0, 0x2D),
  (2, 0, 0x2D),
];
const _aveAbajo = [
  (-1, 0, 0x5F),
  (0, 0, 0x76),
  (1, 0, 0x5F),
  (-2, 1, _cBarra),
  (2, 1, _cContra),
];

/// Halcón, 5×2 como el ave cercana pero con cuerpo `◆`: alas arriba, planeo
/// `◄=◆=►` (planea casi siempre) y alas abajo.
const _halconArriba = [
  (-2, -1, _cContra),
  (2, -1, _cBarra),
  (-1, 0, _cContra),
  (0, 0, 0x25C6),
  (1, 0, _cBarra),
];
const _halconPlaneo = [
  (-2, 0, 0x25C4),
  (-1, 0, 0x3D),
  (0, 0, 0x25C6),
  (1, 0, 0x3D),
  (2, 0, 0x25BA),
];
const _halconAbajo = [
  (-1, 0, 0x5F),
  (0, 0, 0x25C6),
  (1, 0, 0x5F),
  (-2, 1, _cBarra),
  (2, 1, _cContra),
];

/// Hojas que caen girando: llena, chica y hueca.
const _hojaLlena = 0x25C6, _hojaChica = 0x25AA, _hojaHueca = 0x25C7;
const _maxHojas = 36;

class _Arbol {
  _Arbol(
    this.cx,
    this.suelo,
    this.alto,
    this.medio,
    this.plano,
    this.desfase,
    this.frecuencia,
    this.fuerza,
  );

  final double cx;
  final int suelo;
  final int alto;

  /// Medio ancho de la copa en la base, en celdas.
  final double medio;
  final int plano;
  final double desfase;

  /// Cada pino se mece a su ritmo y con su propia flexibilidad.
  final double frecuencia;
  final double fuerza;
}

class _Hoja {
  double x = 0, y = 0, caida = 30, giro = 0, velGiro = 4;
  int tono = 0;
  bool activa = false;
}

class _Halcon {
  _Halcon(this.x, this.y, this.reloj);

  double x, y, vx = 60, vy = 0, fase = 0;

  /// Segundos dentro del ciclo de 12: caza los primeros 7, después patrulla.
  double reloj;
  _Ave? presa;
  bool get cazando => reloj % 12 < 7;
}

class _Ave {
  _Ave(this.x, this.y, this.vx, this.vy, this.fase, this.tamano, this.acento);

  double x, y, vx, vy, fase;
  double susto = 0;

  /// 0 lejana (una letra), 1 mediana (3 letras), 2 cercana (dibujo de 5×2).
  final int tamano;
  final bool acento;
}

class _Escena {
  Size tam = Size.zero;
  double cw = 10, ch = 14;
  int cols = 0, filas = 0, filaBosque = 0;
  double techoPx = 0;
  double tiempo = 0;
  Offset? puntero;

  final aves = <_Ave>[];
  final arboles = <_Arbol>[];

  /// Los pinos que sueltan hojas (medianos y cercanos), calculados al plantar.
  final _conHojas = <_Arbol>[];
  final hojas = List.generate(_maxHojas, (_) => _Hoja());
  _Halcon? halcon;

  // El bosque se planta con semilla fija (no cambia de lugar); el viento, las
  // hojas y el halcón usan azar de verdad: cada visita se ve distinta.
  final _azar = math.Random();
  double _rafaga = 0.2, _rafagaMeta = 0.2, _cambioRafaga = 0;
  double _hojasPendientes = 0;
  Float32List energia = Float32List(0);
  Float32List _aux = Float32List(0);
  Int8List planoCelda = Int8List(0);
  Uint16List glifoCelda = Uint16List(0);

  int versionBosque = 0;
  double _ultimoBosque = -1;

  // Cuadro grabado del bosque y caché de letras ya medidas.
  ui.Picture? _grabado;
  int _versionGrabada = -1;
  ColorScheme? _tintaGrabada;
  final Map<int, Map<int, TextPainter>> _letras = {};
  // Las aves cercanas usan letra más grande y negrita: caché aparte.
  final Map<int, Map<int, TextPainter>> _letrasGrandes = {};
  double _tamLetra = 10;
  Object? _parametros;

  void ajustar(
    Size nuevo, {
    required double altoBosque,
    required double? techoAves,
    required double densidad,
  }) {
    if (nuevo.width < 40 || nuevo.height < 40) return;
    final parametros = (altoBosque, techoAves, densidad);
    if (nuevo == tam && parametros == _parametros) return;
    tam = nuevo;
    _parametros = parametros;
    cw = (nuevo.width / 110).clamp(8.0, 13.0).roundToDouble();
    ch = (cw * 1.45).roundToDouble();
    cols = (nuevo.width / cw).ceil();
    filas = (nuevo.height / ch).ceil();
    final n = cols * filas;
    energia = Float32List(n);
    _aux = Float32List(n);
    planoCelda = Int8List(n);
    glifoCelda = Uint16List(n);
    filaBosque = (filas * (1 - altoBosque)).round().clamp(0, filas);
    techoPx =
        techoAves != null
            ? nuevo.height * techoAves
            : math.max(ch * 3, filaBosque * ch - ch * 2);
    _limpiarLetras();
    _tamLetra = ch * 0.72;
    _plantar();
    _soltarAves(densidad);
    for (final h in hojas) {
      h.activa = false;
    }
    // El halcón necesita cielo: en una franja angosta (teléfono) estorba.
    halcon =
        techoPx >= 260
            ? _Halcon(
              _azar.nextDouble() * nuevo.width,
              techoPx * 0.4,
              _azar.nextDouble() * 12,
            )
            : null;
    _rasterizarBosque();
  }

  void avanzar(double dt) {
    if (cols == 0) return;
    tiempo += dt;
    _soplar(dt);
    _moverHalcon(dt);
    _moverAves(dt);
    _moverHojas(dt);
    final p = puntero;
    if (p != null) _depositar(p.dx, p.dy, 3.0 * dt);
    _difundir(dt);
    // El vaivén es lento: rehacer el bosque 10 veces por segundo basta.
    if (tiempo - _ultimoBosque >= 0.1) {
      _rasterizarBosque();
      _ultimoBosque = tiempo;
    }
  }

  // ── Bosque ────────────────────────────────────────────────────────────────

  /// Planta los tres planos con una semilla fija: el bosque es siempre el
  /// mismo para un tamaño dado. Lejos, los árboles son chicos y nacen más alto.
  void _plantar() {
    arboles.clear();
    final zona = filas - filaBosque;
    if (zona < 3) return;
    final r = math.Random(11);
    const escalas = [0.5, 0.75, 1.0];
    // Separados y angostos: si las copas se pisan, el plano cercano se vuelve
    // un muro de caracteres y se pierde la silueta del pino.
    const pasos = [5.0, 9.0, 15.0];
    final elevacion = [(zona * 0.28).round(), (zona * 0.12).round(), 0];
    for (var p = 0; p < 3; p++) {
      var x = -r.nextDouble() * pasos[p];
      while (x < cols + pasos[p]) {
        final alto = (zona * escalas[p] * (0.55 + 0.45 * r.nextDouble()))
            .round()
            .clamp(3, zona);
        arboles.add(
          _Arbol(
            x,
            filas - 1 - elevacion[p],
            alto,
            alto * (0.30 + 0.10 * r.nextDouble()),
            p,
            r.nextDouble() * math.pi * 2,
            0.6 + 0.7 * r.nextDouble(),
            0.7 + 0.6 * r.nextDouble(),
          ),
        );
        x += pasos[p] * (0.55 + 0.9 * r.nextDouble());
      }
    }
    _conHojas
      ..clear()
      ..addAll(arboles.where((a) => a.plano > 0));
  }

  /// Pasa los árboles a la grilla: punta `^`, bordes `/` y `\`, copa con la
  /// rampa de su plano (izquierda iluminada) en pisos de ramas, y tronco `|`.
  void _rasterizarBosque() {
    if (cols == 0) return;
    planoCelda.fillRange(0, planoCelda.length, -1);
    for (final a in arboles) {
      final tronco = a.plano == 2 ? 2 : 1;
      final tope = a.suelo - a.alto + 1;
      final copaFin = a.suelo - tronco;
      final amplitud = const [0.5, 0.8, 1.2][a.plano];
      final rampa = _rampas[a.plano];
      final largo = math.max(1, copaFin - tope);
      for (var f = math.max(tope, 0); f <= a.suelo && f < filas; f++) {
        if (f > copaFin) {
          _marcar(a.cx.round(), f, a.plano, _cTronco);
          continue;
        }
        final k = (f - tope) / largo;
        // Su propio vaivén más el empuje de la ráfaga que pasa por su columna.
        final vaiven =
            amplitud *
            a.fuerza *
            (1 - k) *
            (math.sin(tiempo * a.frecuencia + a.desfase) * 0.55 +
                viento(a.cx) * 1.6);
        final piso = ((f - tope) % 3) / 3;
        final medio = math.max(0.0, a.medio * k * (0.72 + 0.28 * piso));
        final centro = a.cx + vaiven;
        final c0 = (centro - medio).round();
        final c1 = (centro + medio).round();
        for (var c = c0; c <= c1; c++) {
          final int codigo;
          if (f == tope || c0 == c1) {
            codigo = _cPunta;
          } else if (c == c0) {
            codigo = _cBarra;
          } else if (c == c1) {
            codigo = _cContra;
          } else {
            final luz = 0.5 + 0.5 * ((centro - c) / math.max(medio, 1));
            // Con ráfaga fuerte la copa susurra: el ruido cambia 6 veces por
            // segundo; en calma queda fijo.
            final agitada = viento(c.toDouble()) > 0.55;
            final ruido =
                agitada
                    ? (_hash(c, f + (tiempo * 6).floor() * 31) - 0.5) * 0.6
                    : (_hash(c, f) - 0.5) * 0.3;
            final i =
                ((1 - (luz + ruido).clamp(0.0, 1.0)) * (rampa.length - 0.01))
                    .floor();
            codigo = rampa.codeUnitAt(i);
          }
          _marcar(c, f, a.plano, codigo);
        }
      }
    }
    // El suelo: la última fila salpicada donde no hay árbol.
    final f = filas - 1;
    for (var c = 0; c < cols; c++) {
      final i = f * cols + c;
      if (planoCelda[i] < 0 && _hash(c, filas) > 0.45) {
        planoCelda[i] = 3;
        glifoCelda[i] = _hash(c, 7) > 0.5 ? 0x5F : 0x2E;
      }
    }
    versionBosque++;
  }

  void _marcar(int c, int f, int plano, int codigo) {
    if (c < 0 || c >= cols || f < 0 || f >= filas) return;
    final i = f * cols + c;
    planoCelda[i] = plano;
    glifoCelda[i] = codigo;
  }

  /// Ruido fijo por celda, entre 0 y 1.
  static double _hash(int a, int b) {
    var h = a * 374761393 + b * 668265263;
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h ^ (h >> 16)) & 0xFFFF) / 0xFFFF;
  }

  // ── Ráfagas, hojas y halcón ───────────────────────────────────────────────

  /// Fuerza del viento en la columna [x] (0 a ~1): la ráfaga actual viaja de
  /// izquierda a derecha como una onda.
  double viento(double x) =>
      _rafaga * (0.55 + 0.45 * math.sin(x * 0.11 - tiempo * 1.7));

  /// El viento va y viene solo: cada 2 a 6 s elige calma (70 %) o ráfaga
  /// (30 %) y se acerca suave a esa fuerza.
  void _soplar(double dt) {
    if (tiempo >= _cambioRafaga) {
      _rafagaMeta =
          _azar.nextDouble() < 0.3
              ? 0.6 + 0.4 * _azar.nextDouble()
              : 0.1 + 0.25 * _azar.nextDouble();
      _cambioRafaga = tiempo + 2 + _azar.nextDouble() * 4;
    }
    _rafaga += (_rafagaMeta - _rafaga) * math.min(1.0, dt * 0.8);
  }

  /// Caza 7 de cada 12 s: persigue a la presa apuntando adonde va a estar; el
  /// resto del ciclo patrulla ondulando. Más rápido que la bandada al cazar.
  void _moverHalcon(double dt) {
    final h = halcon;
    if (h == null) return;
    h.reloj += dt;
    final arriba = tam.height * 0.06;
    final abajo = math.max(arriba + 20, techoPx);
    var fx = 0.0, fy = 0.0;
    if (h.cazando) {
      var presa = h.presa;
      if (presa == null || !aves.contains(presa)) {
        // La más cercana entre las que se ven (medianas y cercanas).
        var mejor = double.infinity;
        for (final a in aves) {
          if (a.tamano == 0) continue;
          final d = (a.x - h.x) * (a.x - h.x) + (a.y - h.y) * (a.y - h.y);
          if (d < mejor) {
            mejor = d;
            presa = a;
          }
        }
        h.presa = presa;
      }
      if (presa != null) {
        fx = (presa.x + presa.vx * 0.4 - h.x) * 2.2 - h.vx * 0.9;
        fy = (presa.y + presa.vy * 0.4 - h.y) * 2.2 - h.vy * 0.9;
      }
    } else {
      h.presa = null;
      fx = (70 - h.vx) * 0.6;
      fy = math.sin(tiempo * 0.5 + h.reloj) * 30 - h.vy * 0.5;
    }
    if (h.y < arriba) fy += (arriba - h.y) * 5;
    if (h.y > abajo) fy -= (h.y - abajo) * 5;
    h.vx += fx * dt;
    h.vy += fy * dt;
    final v = math.sqrt(h.vx * h.vx + h.vy * h.vy);
    final tope = h.cazando ? 135.0 : 75.0;
    if (v > tope) {
      h.vx *= tope / v;
      h.vy *= tope / v;
    }
    h.x += h.vx * dt;
    h.y += h.vy * dt;
    if (h.x > tam.width + 50) {
      h.x = -50;
    } else if (h.x < -60) {
      h.x = tam.width + 50;
    }
    h.fase += dt * (h.cazando ? 7 : 3);
    _depositar(h.x - h.vx * 0.12, h.y, 2.5 * dt);
  }

  /// Las copas sueltan hojas: pocas en calma, muchas con ráfaga. Caen girando,
  /// el viento las arrastra y el puntero las aparta. Se reciclan del pozo.
  void _moverHojas(double dt) {
    _hojasPendientes += dt * (0.8 + 9 * _rafaga * _rafaga);
    while (_hojasPendientes >= 1) {
      _hojasPendientes -= 1;
      _soltarHoja();
    }
    final p = puntero;
    for (final h in hojas) {
      if (!h.activa) continue;
      var vx = viento(h.x / cw) * 80 + math.sin(tiempo * 1.4 + h.giro) * 14;
      if (p != null) {
        final dx = h.x - p.dx, dy = h.y - p.dy;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < 100 && d > 0.01) {
          vx += dx / d * 160 * (1 - d / 100);
          h.y += dy / d * 60 * (1 - d / 100) * dt;
        }
      }
      h.x += vx * dt;
      // La ráfaga las sostiene: flotan un rato antes de seguir cayendo.
      h.y += (h.caida - viento(h.x / cw) * 34) * dt;
      h.giro += h.velGiro * dt;
      if (h.y > tam.height + 10 ||
          h.y < -30 ||
          h.x > tam.width + 20 ||
          h.x < -40) {
        h.activa = false;
      }
    }
  }

  void _soltarHoja() {
    final libre = hojas.where((h) => !h.activa).firstOrNull;
    if (libre == null || _conHojas.isEmpty) return;
    if (_rafaga > 0.5 && _azar.nextDouble() < 0.45) {
      // Con ráfaga, el viento las trae volando por el cielo desde la izquierda.
      final arriba = tam.height * 0.06;
      libre
        ..x = -10
        ..y = arriba + _azar.nextDouble() * math.max(1, techoPx - arriba);
    } else {
      // Si no, se desprenden de la copa de un pino mediano o cercano.
      final a = _conHojas[_azar.nextInt(_conHojas.length)];
      final tope = a.suelo - a.alto + 1;
      libre
        ..x = (a.cx + (_azar.nextDouble() - 0.5) * a.medio) * cw
        ..y = (tope + _azar.nextDouble() * a.alto * 0.4) * ch;
    }
    libre
      ..activa = true
      ..caida = 20 + _azar.nextDouble() * 22
      ..giro = _azar.nextDouble() * math.pi * 2
      ..velGiro = 3 + _azar.nextDouble() * 4
      ..tono = _azar.nextInt(2);
  }

  /// Cuántas hojas están en el aire (para las pruebas: nunca más que el pozo).
  int get hojasEnElAire => hojas.where((h) => h.activa).length;

  // ── Aves de papel ─────────────────────────────────────────────────────────

  void _soltarAves(double densidad) {
    aves.clear();
    final r = math.Random(5);
    // Menos aves que antes: las cercanas ahora son grandes y se amontonaban.
    final n = (tam.width * techoPx / 24000 * densidad).round().clamp(5, 20);
    for (var i = 0; i < n; i++) {
      final ang = (r.nextDouble() - 0.5) * 0.8;
      final v = 40 + r.nextDouble() * 25;
      final dado = r.nextDouble();
      aves.add(
        _Ave(
          r.nextDouble() * tam.width,
          techoPx * (0.15 + 0.8 * r.nextDouble()),
          math.cos(ang) * v,
          math.sin(ang) * v,
          r.nextDouble() * math.pi * 2,
          dado < 0.25 ? 0 : (dado < 0.55 ? 1 : 2),
          // (25 % lejanas, 30 % medianas, 45 % cercanas.)
          i % 6 == 0,
        ),
      );
    }
  }

  /// Bandada: separación, alineación y cohesión con las vecinas, una brisa
  /// hacia la derecha, un techo y un piso suaves, y huida del puntero.
  void _moverAves(double dt) {
    const percepcion = 110.0, radioPuntero = 130.0;
    final arriba = tam.height * 0.05;
    final abajo = math.max(arriba + 20, techoPx);
    for (final a in aves) {
      var sx = 0.0, sy = 0.0, ax = 0.0, ay = 0.0, cx = 0.0, cy = 0.0;
      var n = 0;
      // Cuanto más grande el ave, más lugar pide para no taparse con otra.
      final espacio = const [22.0, 32.0, 54.0][a.tamano];
      for (final b in aves) {
        if (identical(a, b) || a.tamano != b.tamano) continue;
        final dx = b.x - a.x, dy = b.y - a.y;
        final d2 = dx * dx + dy * dy;
        if (d2 > percepcion * percepcion) continue;
        n++;
        ax += b.vx;
        ay += b.vy;
        cx += b.x;
        cy += b.y;
        if (d2 < espacio * espacio && d2 > 0.01) {
          sx -= dx / d2;
          sy -= dy / d2;
        }
      }
      var fx = sx * 900, fy = sy * 900;
      if (n > 0) {
        fx += (ax / n - a.vx) * 0.6 + (cx / n - a.x) * 0.35;
        fy += (ay / n - a.vy) * 0.6 + (cy / n - a.y) * 0.35;
      }
      fx += (55 - a.vx) * 0.4;
      fy += math.sin(tiempo * 0.7 + a.fase) * 6;
      if (a.y < arriba) fy += (arriba - a.y) * 4;
      if (a.y > abajo) fy -= (a.y - abajo) * 4;

      // El halcón espanta más que el mouse y desde más lejos.
      final h = halcon;
      if (h != null) {
        final dx = a.x - h.x, dy = a.y - h.y;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < 150 && d > 0.01) {
          final w = math.pow(1 - d / 150, 2).toDouble();
          fx += dx / d * 1700 * w;
          fy += dy / d * 1700 * w;
          a.susto = math.max(a.susto, w);
        }
      }

      final p = puntero;
      if (p != null) {
        final dx = a.x - p.dx, dy = a.y - p.dy;
        final d = math.sqrt(dx * dx + dy * dy);
        if (d < radioPuntero && d > 0.01) {
          final w = math.pow(1 - d / radioPuntero, 2).toDouble();
          fx += dx / d * 1400 * w;
          fy += dy / d * 1400 * w;
          a.susto = math.max(a.susto, w);
        }
      }

      a.vx += fx * dt;
      a.vy += fy * dt;
      final v = math.sqrt(a.vx * a.vx + a.vy * a.vy);
      final tope = 120 * (1 + a.susto);
      if (v > tope) {
        a.vx *= tope / v;
        a.vy *= tope / v;
      }
      a.x += a.vx * dt;
      a.y += a.vy * dt;
      // Salen por un lado y entran por el otro: la bandada no se amontona.
      if (a.x > tam.width + 30) {
        a.x = -30;
        a.y = arriba + (abajo - arriba) * _hash(a.fase.round(), 3);
      } else if (a.x < -40) {
        a.x = tam.width + 30;
      }
      a.fase += dt * (6 + v * 0.05);
      a.susto *= math.exp(-dt * 1.2);
      if (a.tamano > 0) {
        final fuerza = a.tamano == 2 ? 1.8 : 1.0;
        _depositar(a.x - a.vx * 0.1, a.y, (fuerza + 2 * a.susto) * dt);
      }
    }
  }

  // ── Viento ────────────────────────────────────────────────────────────────

  void _depositar(double x, double y, double cantidad) {
    final c = (x / cw).floor(), f = (y / ch).floor();
    if (c < 0 || c >= cols || f < 0 || f >= filas) return;
    final i = f * cols + c;
    energia[i] = math.min(1.5, energia[i] + cantidad);
  }

  /// Cada celda se promedia con sus cuatro vecinas y se apaga de a poco.
  void _difundir(double dt) {
    final apagado = math.exp(-dt * 1.6);
    for (var f = 0; f < filas; f++) {
      for (var c = 0; c < cols; c++) {
        final i = f * cols + c;
        final l = c > 0 ? energia[i - 1] : energia[i];
        final r = c < cols - 1 ? energia[i + 1] : energia[i];
        final u = f > 0 ? energia[i - cols] : energia[i];
        final d = f < filas - 1 ? energia[i + cols] : energia[i];
        _aux[i] = (4 * energia[i] + l + r + u + d) / 8 * apagado;
      }
    }
    final t = energia;
    energia = _aux;
    _aux = t;
  }

  // ── Dibujo ────────────────────────────────────────────────────────────────

  TextPainter _letra(int codigo, Color color, bool grande) {
    final cache = grande ? _letrasGrandes : _letras;
    final porColor = cache.putIfAbsent(color.toARGB32(), () => {});
    return porColor.putIfAbsent(
      codigo,
      () => TextPainter(
        text: TextSpan(
          text: String.fromCharCode(codigo),
          style: TextStyle(
            // Monoespaciada: el dibujo de caracteres pide letras parejas.
            fontFamily: 'JetBrainsMono',
            fontSize: grande ? _tamLetra * 1.7 : _tamLetra,
            height: 1,
            fontWeight: grande ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
  }

  void pintarCelda(
    Canvas canvas,
    int codigo,
    Color color,
    int c,
    int f, {
    bool grande = false,
  }) {
    if (c < 0 || c >= cols || f < 0 || f >= filas || color.a <= 0) return;
    final tp = _letra(codigo, color, grande);
    tp.paint(
      canvas,
      Offset(c * cw + (cw - tp.width) / 2, f * ch + (ch - tp.height) / 2),
    );
  }

  /// Una letra grande (la de las aves cercanas) centrada en [centro], en
  /// píxeles: no se ata a la grilla del bosque.
  void pintarEn(Canvas canvas, int codigo, Color color, Offset centro) {
    if (color.a <= 0 ||
        centro.dx < -cw * 4 ||
        centro.dx > tam.width + cw * 4 ||
        centro.dy < -ch * 2 ||
        centro.dy > tam.height + ch * 2) {
      return;
    }
    final tp = _letra(codigo, color, true);
    tp.paint(canvas, centro - Offset(tp.width / 2, tp.height / 2));
  }

  /// El bosque grabado en un cuadro: se rehace solo cuando el bosque se movió
  /// o cambió el tema. Con otro tema, las letras medidas ya no sirven y se van.
  ui.Picture grabadoDelBosque(
    ColorScheme tinta,
    Color Function(int plano, int codigo) color,
  ) {
    final g = _grabado;
    final mismaTinta = _tintaGrabada == tinta;
    if (g != null && _versionGrabada == versionBosque && mismaTinta) {
      return g;
    }
    if (!mismaTinta && _tintaGrabada != null) _limpiarLetras();
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    for (var i = 0; i < planoCelda.length; i++) {
      final p = planoCelda[i];
      if (p < 0) continue;
      final codigo = glifoCelda[i];
      pintarCelda(canvas, codigo, color(p, codigo), i % cols, i ~/ cols);
    }
    _grabado?.dispose();
    final nuevo = rec.endRecording();
    _grabado = nuevo;
    _versionGrabada = versionBosque;
    _tintaGrabada = tinta;
    return nuevo;
  }

  void _limpiarLetras() {
    for (final cache in [_letras, _letrasGrandes]) {
      for (final m in cache.values) {
        for (final tp in m.values) {
          tp.dispose();
        }
      }
      cache.clear();
    }
    _grabado?.dispose();
    _grabado = null;
  }

  /// Cuántas letras medidas hay en caché (para vigilar que no crezca).
  int get letrasEnCache => [
    _letras,
    _letrasGrandes,
  ].fold(0, (s, m) => s + m.values.fold(0, (t, x) => t + x.length));

  void liberar() => _limpiarLetras();
}

// ═══════════════════════════════════════════════════════════════════════════
// EL PINTOR
// ═══════════════════════════════════════════════════════════════════════════

class _PintorBosque extends CustomPainter {
  _PintorBosque(this.e, this.cs, this.intensidad, Listenable cuadro)
    : super(repaint: cuadro);

  final _Escena e;
  final ColorScheme cs;
  final double intensidad;

  /// Opacidad en 20 escalones: así la caché de letras no crece sin límite.
  Color _alfa(Color c, double a) =>
      c.withValues(alpha: ((a * intensidad).clamp(0.0, 1.0) * 20).round() / 20);

  Color _colorBosque(int plano, int codigo) {
    if (plano == 3) return _alfa(cs.onSurfaceVariant, 0.22);
    const base = [0.16, 0.27, 0.42];
    final borde =
        codigo == _cBarra ||
        codigo == _cContra ||
        codigo == _cPunta ||
        codigo == _cTronco;
    return _alfa(cs.primary, base[plano] + (borde ? 0.10 : 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (e.cols == 0) return;

    // 1. Estelas de viento, por debajo del bosque y sin taparlo.
    for (var i = 0; i < e.energia.length; i++) {
      final v = e.energia[i];
      if (v < 0.05 || e.planoCelda[i] >= 0) continue;
      e.pintarCelda(
        canvas,
        v > 0.45 ? 0x2022 : 0x00B7,
        _alfa(cs.tertiary, math.min(0.6, v * 1.4)),
        i % e.cols,
        i ~/ e.cols,
      );
    }

    // 2. El bosque, del cuadro grabado.
    canvas.drawPicture(e.grabadoDelBosque(cs, _colorBosque));

    // 3. Hojas que caen, delante del bosque, con letra grande para que se
    // noten; ajustadas a la grilla para conservar el aire de caracteres.
    for (final h in e.hojas) {
      if (!h.activa) continue;
      final s = math.sin(h.giro);
      final c = (h.x / e.cw).floor(), f = (h.y / e.ch).floor();
      e.pintarEn(
        canvas,
        s > 0.3
            ? _hojaLlena
            : s > -0.3
            ? _hojaChica
            : _hojaHueca,
        h.tono == 0 ? _alfa(cs.primary, 0.75) : _alfa(cs.tertiary, 0.8),
        Offset(c * e.cw + e.cw / 2, f * e.ch + e.ch / 2),
      );
    }

    // 4. Las aves, de la más lejana a la más cercana: las grandes van encima.
    for (var tamano = 0; tamano < 3; tamano++) {
      for (final a in e.aves) {
        if (a.tamano == tamano) _pintarAve(canvas, a);
      }
    }

    // 5. El halcón, arriba de todo y en el color terciario.
    final h = e.halcon;
    if (h != null) {
      final s = math.sin(h.fase);
      // Planea casi siempre; aletea solo en los extremos del ciclo.
      final dibujo =
          s > 0.6
              ? _halconArriba
              : s < -0.6
              ? _halconAbajo
              : _halconPlaneo;
      final c = (h.x / e.cw).floor(), f = (h.y / e.ch).floor();
      final cx = c * e.cw + e.cw / 2, cy = f * e.ch + e.ch / 2;
      final color = _alfa(cs.tertiary, 0.95);
      for (final (dc, df, codigo) in dibujo) {
        e.pintarEn(
          canvas,
          codigo,
          color,
          // Alas más abiertas que las de un ave: se distingue de lejos.
          Offset(cx + dc * e.cw * 2.0, cy + df * e.ch * 1.4),
        );
      }
    }
  }

  void _pintarAve(Canvas canvas, _Ave a) {
    final c = (a.x / e.cw).floor(), f = (a.y / e.ch).floor();
    final s = math.sin(a.fase);
    // Las cercanas casi opacas: son lo que se tiene que ver.
    final color =
        a.acento
            // Acento en el principal: el terciario es del halcón.
            ? _alfa(cs.primary, const [0.5, 0.8, 0.95][a.tamano])
            : _alfa(cs.onSurface, const [0.42, 0.72, 0.92][a.tamano]);
    switch (a.tamano) {
      case 0:
        e.pintarCelda(canvas, s > 0 ? 0x76 : 0x2D, color, c, f);
      case 1:
        final (izq, der) =
            s > 0.35
                ? (_cContra, _cBarra)
                : s < -0.35
                ? (_cBarra, _cContra)
                : (0x2D, 0x2D);
        e.pintarCelda(canvas, izq, color, c - 1, f);
        e.pintarCelda(canvas, 0x76, color, c, f);
        e.pintarCelda(canvas, der, color, c + 1, f);
      default:
        final dibujo =
            s > 0.35
                ? _aveArriba
                : s < -0.35
                ? _aveAbajo
                : _avePlaneo;
        // Sobre una grilla más ancha que la del bosque: el ave cercana mide
        // unas 7,5 × 2,6 celdas y se lee de lejos.
        final cx = c * e.cw + e.cw / 2, cy = f * e.ch + e.ch / 2;
        for (final (dc, df, codigo) in dibujo) {
          e.pintarEn(
            canvas,
            codigo,
            color,
            Offset(cx + dc * e.cw * 1.5, cy + df * e.ch * 1.3),
          );
        }
    }
  }

  @override
  bool shouldRepaint(_PintorBosque old) =>
      old.cs != cs || old.intensidad != intensidad;
}
