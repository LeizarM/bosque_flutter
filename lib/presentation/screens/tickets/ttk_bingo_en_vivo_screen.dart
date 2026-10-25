import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/ttk_bingo_provider.dart';
import 'package:bosque_flutter/core/ui/estados_vista.dart';
import 'package:bosque_flutter/core/ui/piezas_bosque.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_publico_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_sorteo_entity.dart';
import 'package:bosque_flutter/domain/entities/ttk_estado_publico_entity.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_bingo_piezas.dart';
import 'package:bosque_flutter/presentation/widgets/tickets/ttk_comun.dart';

/// `ttkBingo/EnVivo` (todo empleado, se proyecta): el tablero luminoso de la
/// sala. El número cantado manda; nunca muestra quién ganó ni el ranking.
class TtkBingoEnVivoScreen extends ConsumerStatefulWidget {
  const TtkBingoEnVivoScreen({super.key, this.codBingo});

  /// Llega desde «Mi cartón»; si no, se elige entre los bingos en juego.
  final BigInt? codBingo;

  @override
  ConsumerState<TtkBingoEnVivoScreen> createState() =>
      _TtkBingoEnVivoScreenState();
}

class _TtkBingoEnVivoScreenState extends ConsumerState<TtkBingoEnVivoScreen> {
  BigInt? _elegido;

  @override
  Widget build(BuildContext context) {
    final cod = widget.codBingo ?? _elegido;
    return Scaffold(body: cod != null ? _Sala(codBingo: cod) : _elegirBingo());
  }

  Widget _elegirBingo() {
    final bingos = ref.watch(ttkMisBingosProvider);
    return bingos.when(
      loading: () => const EsqueletoListaTtk(),
      error:
          (e, _) => MensajeError(
            error: e,
            onReintentar: () => ref.invalidate(ttkMisBingosProvider),
          ),
      data: (lista) {
        final enJuego = [
          for (final b in lista)
            if (b.puedeVerEnVivo) b,
        ];
        if (enJuego.length == 1) {
          return _Sala(codBingo: enJuego.first.codBingo!);
        }
        if (enJuego.isEmpty) {
          return Column(
            children: [
              const Expanded(
                child: MensajeVacio(
                  icono: Icons.live_tv_outlined,
                  titulo: 'No hay un bingo en juego',
                  detalle: 'Cuando empiece, el tablero aparece aquí.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: Esp.xl),
                child: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(ttkMisBingosProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Volver a consultar'),
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(Esp.xl),
          children: [
            Text(
              '¿Qué bingo quieres ver?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Esp.l),
            for (final b in enJuego)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.casino_outlined),
                  title: Text(b.nombreEvento),
                  subtitle: Text(fechaCorta(b.fechaEvento)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _elegido = b.codBingo),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Lo que la sala necesita leer de un vistazo, sacado del estado público.
class _Lectura {
  _Lectura(TtkEstadoPublicoEntity e)
    : publico = e.publico,
      tablero = e.tablero,
      cantados = [
        for (final b in e.tablero)
          if (b.marcado && b.orden != null) b,
      ]..sort((a, b) => b.orden!.compareTo(a.orden!));

  final TtkBingoPublicoEntity? publico;
  final List<TtkBingoSorteoEntity> tablero;

  /// Bolillos que salieron, del más reciente al más antiguo.
  final List<TtkBingoSorteoEntity> cantados;

  TtkBingoSorteoEntity? get ultimo {
    final n = publico?.ultimoBolillo;
    if (n == null) return null;
    return tablero.where((b) => b.nroBolillo == n).firstOrNull ??
        TtkBingoSorteoEntity(nroBolillo: n);
  }

  /// Los anteriores al último, para la historia de lo cantado.
  List<TtkBingoSorteoEntity> antes(int cuantos) =>
      [
        for (final b in cantados)
          if (b.nroBolillo != publico?.ultimoBolillo) b,
      ].take(cuantos).toList();

  bool get hayGanador => publico?.hayGanador ?? false;
  bool get enCurso => publico?.estadoJuego == 'EN_CURSO';

  /// Con juego en curso, su nombre; si no, el mensaje del SP (fin, pausa).
  String get titulo =>
      enCurso || hayGanador
          ? ttkOGuion(publico?.nombreJuego)
          : ttkOGuion(publico?.mensaje);
}

class _Sala extends ConsumerWidget {
  const _Sala({required this.codBingo});

  final BigInt codBingo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vivo = ref.watch(ttkVivoPublicoProvider(codBingo));
    final dato = vivo.dato;
    if (dato == null) {
      if (vivo.cargando) {
        return const Center(child: CircularProgressIndicator());
      }
      if (vivo.error != null) {
        return MensajeError(
          error: vivo.error,
          onReintentar:
              () =>
                  ref
                      .read(ttkVivoPublicoProvider(codBingo).notifier)
                      .refrescar(),
        );
      }
      return const MensajeVacio(
        icono: Icons.live_tv_outlined,
        titulo: 'El bingo aún no empieza',
        detalle:
            'El tablero se enciende solo en cuanto salga el primer bolillo.',
      );
    }
    final l = _Lectura(dato);
    return LayoutBuilder(
      builder:
          (context, c) =>
              c.maxWidth >= 1000
                  ? _VistaSala(
                    lectura: l,
                    conectado: vivo.conectado,
                    tam: c.biggest,
                  )
                  : _VistaCelular(
                    lectura: l,
                    conectado: vivo.conectado,
                    tam: c.biggest,
                  ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROYECTOR Y PANTALLA ANCHA
// ═══════════════════════════════════════════════════════════════════════════

/// Panel del número cantado a la izquierda (el color fuerte del tema) y el
/// tablero luminoso con el juego a la derecha.
class _VistaSala extends StatelessWidget {
  const _VistaSala({
    required this.lectura,
    required this.conectado,
    required this.tam,
  });

  final _Lectura lectura;
  final bool conectado;
  final Size tam;

  @override
  Widget build(BuildContext context) {
    final panel = (tam.width * 0.3).clamp(320.0, 600.0).toDouble();
    final aire = tam.width >= 1600 ? Esp.xxl : Esp.xl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: panel,
          child: _PanelCantado(
            lectura: lectura,
            conectado: conectado,
            historial: 6,
            relleno: aire,
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(aire),
            child: LayoutBuilder(
              builder: (context, c) {
                // El tablero toma el alto que necesita a todo el ancho y el
                // sobrante agranda el juego y su figura.
                final grupos = <int, int>{};
                for (final b in lectura.tablero) {
                  grupos[b.columna] = (grupos[b.columna] ?? 0) + 1;
                }
                const hueco = 6.0;
                final minimo = (c.maxHeight * 0.16).clamp(96.0, 180.0);
                final m = ttkMedidaTablero(
                  ancho: c.maxWidth,
                  alto: c.maxHeight - minimo - aire,
                  grupos: math.max(grupos.length, 1),
                  porGrupo: grupos.values.fold(1, math.max),
                  minimo: 36,
                  maximo: 220,
                );
                final lineas =
                    math.max(grupos.length, 1) *
                    (grupos.values.fold(1, math.max) / m.porLinea).ceil();
                final tablero =
                    lineas * m.diametro +
                    (lineas - 1) * hueco +
                    (math.max(grupos.length, 1) - 1) * hueco;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder:
                                  (context, k) => _CabeceraJuego(
                                    lectura: lectura,
                                    alto: k.maxHeight,
                                  ),
                            ),
                          ),
                          _AvisoGanador(lectura: lectura, grande: true),
                        ],
                      ),
                    ),
                    SizedBox(height: aire),
                    SizedBox(
                      height: math.min(
                        tablero + 2,
                        c.maxHeight - minimo - aire,
                      ),
                      child: TableroBolillosTtk(
                        tablero: lectura.tablero,
                        ultimo: lectura.publico?.ultimoBolillo,
                        llenar: true,
                        lampara: true,
                        minCelda: 36,
                        maxCelda: 220,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CELULAR
// ═══════════════════════════════════════════════════════════════════════════

/// En el teléfono el panel del cantado va arriba, el juego debajo y el
/// tablero se queda con el resto del alto.
class _VistaCelular extends StatelessWidget {
  const _VistaCelular({
    required this.lectura,
    required this.conectado,
    required this.tam,
  });

  final _Lectura lectura;
  final bool conectado;
  final Size tam;

  @override
  Widget build(BuildContext context) {
    final alto = (tam.height * 0.24).clamp(150.0, 210.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: alto,
          child: _PanelCantado(
            lectura: lectura,
            conectado: conectado,
            historial: 4,
            relleno: Esp.l,
            horizontal: true,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Esp.l, Esp.m, Esp.l, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 64,
                child: _CabeceraJuego(lectura: lectura, alto: 64),
              ),
              _AvisoGanador(lectura: lectura, grande: false),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(Esp.m),
            child: TableroBolillosTtk(
              tablero: lectura.tablero,
              ultimo: lectura.publico?.ultimoBolillo,
              llenar: true,
              lampara: true,
              minCelda: 24,
              maxCelda: 96,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PIEZAS
// ═══════════════════════════════════════════════════════════════════════════

/// El panel del cantado: evento, conexión, el número con su letra a escala
/// de marcador, lo cantado antes y cuántos van.
class _PanelCantado extends StatelessWidget {
  const _PanelCantado({
    required this.lectura,
    required this.conectado,
    required this.historial,
    required this.relleno,
    this.horizontal = false,
  });

  final _Lectura lectura;
  final bool conectado;
  final int historial;
  final double relleno;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final p = lectura.publico;
    final tinta = cs.onPrimary;
    Widget evento([double? tam]) => Text(
      ttkOGuion(p?.nombreEvento),
      maxLines: horizontal ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: (horizontal ? t.titleSmall : t.titleLarge)?.copyWith(
        color: tinta,
        fontWeight: Peso.dato,
        fontSize: tam,
      ),
    );
    Widget cuenta([double? tam]) => Text(
      '${p?.totalMarcados ?? 0} de ${p?.nroBolillos ?? 0} bolillos',
      style: (horizontal ? t.bodyMedium : t.titleMedium)?.copyWith(
        color: tinta,
        fontFeatures: cifrasTabulares,
        fontSize: tam,
      ),
    );

    return Material(
      color: cs.primary,
      child: Padding(
        padding: EdgeInsets.all(relleno),
        child: LayoutBuilder(
          builder: (context, c) {
            if (horizontal) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: math.min(c.maxWidth * 0.42, c.maxHeight * 1.1),
                    child: _Cantado(ultimo: lectura.ultimo, tinta: tinta),
                  ),
                  SizedBox(width: relleno),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: evento()),
                            Flexible(
                              child: _Conexion(
                                conectado: conectado,
                                tinta: tinta,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _Historial(
                          bolillos: lectura.antes(historial),
                          tinta: tinta,
                          base: 22,
                        ),
                        const SizedBox(height: Esp.s),
                        cuenta(),
                      ],
                    ),
                  ),
                ],
              );
            }
            final h = c.maxHeight;
            final texto = (h * 0.026).clamp(15.0, 30.0).toDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                evento(texto * 1.15),
                const SizedBox(height: Esp.s),
                _Conexion(conectado: conectado, tinta: tinta, tamano: texto),
                SizedBox(height: h * 0.04),
                Expanded(child: _Cantado(ultimo: lectura.ultimo, tinta: tinta)),
                SizedBox(height: h * 0.03),
                Divider(color: tinta.withValues(alpha: 0.4), height: 1),
                const SizedBox(height: Esp.m),
                Text(
                  'Antes',
                  style: TextStyle(
                    fontSize: texto,
                    color: tinta,
                    fontWeight: Peso.dato,
                  ),
                ),
                const SizedBox(height: Esp.s),
                _Historial(
                  bolillos: lectura.antes(historial),
                  tinta: tinta,
                  base: (h * 0.052).clamp(22.0, 56.0).toDouble(),
                ),
                SizedBox(height: h * 0.04),
                cuenta(texto),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// La letra y el número del último bolillo, tan grandes como el espacio deje.
/// El nuevo entra subiendo y el anterior se va: es el único movimiento.
class _Cantado extends StatelessWidget {
  const _Cantado({required this.ultimo, required this.tinta});

  final TtkBingoSorteoEntity? ultimo;
  final Color tinta;

  @override
  Widget build(BuildContext context) {
    final sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final u = ultimo;
    final letra = u?.letra ?? '';
    return Semantics(
      liveRegion: true,
      label:
          u == null
              ? 'Aún no salió ningún bolillo'
              : 'Último bolillo: ${letra.isEmpty ? '' : '$letra '}${u.nroBolillo}',
      child: ExcludeSemantics(
        child: AnimatedSwitcher(
          duration:
              sinMovimiento ? Duration.zero : const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder:
              (hijo, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(a),
                  child: hijo,
                ),
              ),
          child: LayoutBuilder(
            key: ValueKey(u?.nroBolillo),
            builder: (context, c) {
              final alto = c.maxHeight.isFinite ? c.maxHeight : 300.0;
              final conLetra = letra.isNotEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (conLetra)
                    SizedBox(
                      height: alto * 0.26,
                      child: FittedBox(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          letra,
                          style: TextStyle(
                            fontFamily: ttkFuenteNumeros,
                            fontWeight: Peso.normal,
                            color: tinta,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: alto * (conLetra ? 0.74 : 1),
                    width: c.maxWidth,
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        u == null ? '–' : '${u.nroBolillo}',
                        style: TextStyle(
                          fontFamily: ttkFuenteNumeros,
                          fontWeight: Peso.dato,
                          fontFeatures: cifrasTabulares,
                          color: tinta,
                          height: 0.95,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Lo cantado antes del último: el más reciente más grande, luego bajan.
class _Historial extends StatelessWidget {
  const _Historial({
    required this.bolillos,
    required this.tinta,
    required this.base,
  });

  final List<TtkBingoSorteoEntity> bolillos;
  final Color tinta;
  final double base;

  @override
  Widget build(BuildContext context) {
    if (bolillos.isEmpty) {
      return Text(
        'Todavía nada',
        style: TextStyle(color: tinta, fontSize: base * 0.7),
      );
    }
    return Wrap(
      spacing: base * 0.7,
      runSpacing: base * 0.25,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (var i = 0; i < bolillos.length; i++)
          Text.rich(
            TextSpan(
              children: [
                if (bolillos[i].letra.isNotEmpty)
                  TextSpan(
                    text: '${bolillos[i].letra} ',
                    style: TextStyle(
                      fontSize: base * math.pow(0.86, i) * 0.6,
                      fontWeight: Peso.normal,
                    ),
                  ),
                TextSpan(text: '${bolillos[i].nroBolillo}'),
              ],
            ),
            style: TextStyle(
              fontFamily: ttkFuenteNumeros,
              fontWeight: Peso.dato,
              fontFeatures: cifrasTabulares,
              fontSize: base * math.pow(0.86, i),
              color: tinta,
              height: 1,
            ),
          ),
      ],
    );
  }
}

/// «En vivo» o «Reconectando»: texto con su icono, sin pastillas.
class _Conexion extends StatelessWidget {
  const _Conexion({
    required this.conectado,
    required this.tinta,
    this.tamano = 14,
  });

  final bool conectado;
  final Color tinta;
  final double tamano;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          conectado ? Icons.sensors : Icons.sensors_off,
          size: tamano * 1.25,
          color: tinta,
        ),
        const SizedBox(width: Esp.xs),
        // Con la letra del sistema agrandada se recorta en vez de desbordarse.
        Flexible(
          child: Text(
            conectado ? 'En vivo' : 'Reconectando',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: tamano, color: tinta),
          ),
        ),
      ],
    ),
  );
}

/// El juego en curso a escala de cartel y su figura, legible desde el fondo.
class _CabeceraJuego extends StatelessWidget {
  const _CabeceraJuego({required this.lectura, required this.alto});

  final _Lectura lectura;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = lectura.publico;
    final tieneFigura = p != null && (p.figura ?? '').isNotEmpty;
    final filas = math.max(p?.filas ?? 5, 1);
    // FiguraTtk deja un hueco del 12 % de la celda entre filas: se descuenta
    // para que la figura entre entera en la franja y no se corte abajo.
    // Un 3 % de margen absorbe el redondeo de píxeles al dibujar.
    final celda = (alto * 0.97 / (filas + 0.12 * (filas - 1))).clamp(6.0, 52.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (p?.nroJuego != null)
                Text(
                  'Juego ${p!.nroJuego} de ${p.nroJuegos}',
                  style: TextStyle(
                    fontSize: (alto * 0.16).clamp(12.0, 36.0),
                    color: cs.onSurfaceVariant,
                    fontWeight: Peso.normal,
                  ),
                ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    lectura.titulo,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: (alto * 0.5).clamp(18.0, 132.0),
                      fontWeight: Peso.dato,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (tieneFigura) ...[
          const SizedBox(width: Esp.l),
          FiguraTtk(
            figura: p.figura!,
            filas: p.filas,
            columnas: p.columnas,
            conComodin: p.conComodin,
            celda: celda.toDouble(),
          ),
        ],
      ],
    );
  }
}

/// Franja de ganador: genérica (el texto es del SP) y entra desplegándose.
class _AvisoGanador extends StatelessWidget {
  const _AvisoGanador({required this.lectura, required this.grande});

  final _Lectura lectura;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final sinMovimiento = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration:
          sinMovimiento ? Duration.zero : const Duration(milliseconds: 420),
      transitionBuilder:
          (hijo, a) => SizeTransition(
            sizeFactor: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
            axisAlignment: -1,
            child: FadeTransition(opacity: a, child: hijo),
          ),
      child:
          lectura.hayGanador
              ? Padding(
                key: const ValueKey('ttk-aviso-ganador'),
                padding: EdgeInsets.only(top: grande ? Esp.l : Esp.s),
                child: Semantics(
                  liveRegion: true,
                  container: true,
                  child: Material(
                    color: cs.tertiary,
                    borderRadius: BorderRadius.circular(Esquina.chica),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: grande ? Esp.xl : Esp.l,
                        vertical: grande ? Esp.l : Esp.m,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: grande ? 44 : 26,
                            color: cs.onTertiary,
                          ),
                          SizedBox(width: grande ? Esp.l : Esp.m),
                          Expanded(
                            child: Text(
                              ttkOGuion(lectura.publico?.mensaje),
                              style: (grande ? t.headlineLarge : t.titleMedium)
                                  ?.copyWith(
                                    color: cs.onTertiary,
                                    fontWeight: Peso.dato,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              : const SizedBox(width: double.infinity),
    );
  }
}
