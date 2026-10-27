/// Los ganadores confirmados para la sala: nombre y foto de su ficha (el
/// invitado, con sus iniciales), el premio y, si hubo empate, cómo se resuelve.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/ttk_bingo_ganador_entity.dart';

/// Foto de la ficha del trabajador; si no tiene, el servidor devuelve un ícono.
String ttkFotoEmpleado(BigInt codEmpleado) =>
    '${AppConstants.baseUrl}${AppConstants.getImageUrl}/$codEmpleado.jpg';

/// Hasta dos iniciales del nombre, para el invitado o si la foto no carga.
String ttkIniciales(String? nombre) {
  final partes = [
    for (final p in (nombre ?? '').trim().split(RegExp(r'\s+')))
      if (p.isNotEmpty) p,
  ];
  if (partes.isEmpty) return '?';
  final primera = partes.first.substring(0, 1);
  final otra = partes.length > 1 ? partes[1].substring(0, 1) : '';
  return (primera + otra).toUpperCase();
}

/// La foto redonda del ganador con un aro claro, como en un podio.
class FotoGanadorTtk extends StatelessWidget {
  const FotoGanadorTtk({
    super.key,
    required this.ganador,
    required this.diametro,
  });

  final TtkBingoGanadorEntity ganador;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iniciales = Container(
      width: diametro,
      height: diametro,
      alignment: Alignment.center,
      color: cs.onTertiary,
      child: Text(
        ttkIniciales(ganador.nombreEmpleado),
        style: TextStyle(
          fontSize: diametro * 0.36,
          fontWeight: Peso.dato,
          color: cs.tertiary,
        ),
      ),
    );
    final cod = ganador.codEmpleado;
    // Una sola etiqueta: las iniciales de respaldo no se leen aparte.
    return Semantics(
      image: true,
      label: 'Foto de ${ganador.nombreEmpleado ?? 'el ganador'}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.all(math.max(2, diametro * 0.035)),
        decoration: BoxDecoration(color: cs.onTertiary, shape: BoxShape.circle),
        child: ClipOval(
          child:
              cod == null
                  ? iniciales
                  : Image.network(
                    ttkFotoEmpleado(cod),
                    width: diametro,
                    height: diametro,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => iniciales,
                  ),
        ),
      ),
    );
  }
}

/// El anuncio de ganador: mensaje del SP, premio, nombre y foto de cada uno y,
/// con más de un ganador, la regla o cómo se desempató (el que ganó, destacado).
/// [grande] es para el proyector.
class GanadoresTtk extends StatelessWidget {
  const GanadoresTtk({
    super.key,
    required this.ganadores,
    required this.mensaje,
    this.textoPremio,
    this.textoEmpate,
    this.grande = false,
  });

  final List<TtkBingoGanadorEntity> ganadores;
  final String mensaje;
  final String? textoPremio;
  final String? textoEmpate;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final tinta = cs.onTertiary;
    final empate = ganadores.length > 1 && (textoEmpate ?? '').isNotEmpty;
    final desempatado = ganadores.any((g) => g.ganoDesempate);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: cs.tertiary,
        borderRadius: BorderRadius.circular(Esquina.media),
        child: Padding(
          padding: EdgeInsets.all(grande ? Esp.xl : Esp.l),
          child: LayoutBuilder(
            builder: (context, c) {
              // La foto crece con el espacio y se achica si son varios.
              final foto =
                  grande
                      ? (c.maxWidth / (math.max(ganadores.length, 1) * 1.7))
                          .clamp(96.0, 220.0)
                          .toDouble()
                      : 64.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: grande ? 52 : 28,
                        color: tinta,
                      ),
                      SizedBox(width: grande ? Esp.l : Esp.s),
                      Flexible(
                        child: Text(
                          mensaje,
                          textAlign: TextAlign.center,
                          style: (grande ? t.displaySmall : t.titleMedium)
                              ?.copyWith(color: tinta, fontWeight: Peso.dato),
                        ),
                      ),
                    ],
                  ),
                  if ((textoPremio ?? '').isNotEmpty) ...[
                    SizedBox(height: grande ? Esp.s : Esp.xs),
                    Text(
                      textoPremio!,
                      textAlign: TextAlign.center,
                      style: (grande ? t.headlineSmall : t.bodyLarge)?.copyWith(
                        color: tinta,
                      ),
                    ),
                  ],
                  if (ganadores.isNotEmpty) ...[
                    SizedBox(height: grande ? Esp.xl : Esp.m),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: grande ? Esp.xl : Esp.l,
                      runSpacing: grande ? Esp.l : Esp.m,
                      children: [
                        for (final g in ganadores)
                          SizedBox(
                            width: foto * (grande ? 1.5 : 1.9),
                            child: Column(
                              children: [
                                FotoGanadorTtk(
                                  ganador: g,
                                  // Resuelto el desempate, los que empataron van más chicos.
                                  diametro:
                                      desempatado && !g.ganoDesempate
                                          ? foto * 0.6
                                          : foto,
                                ),
                                SizedBox(height: grande ? Esp.m : Esp.s),
                                Text(
                                  (g.nombreEmpleado ?? '').isEmpty
                                      ? 'Sin nombre'
                                      : g.nombreEmpleado!,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: (grande
                                          ? t.headlineSmall
                                          : t.titleSmall)
                                      ?.copyWith(
                                        color: tinta,
                                        fontWeight: Peso.dato,
                                      ),
                                ),
                                if (desempatado) ...[
                                  const SizedBox(height: Esp.xs),
                                  Text(
                                    g.ganoDesempate
                                        ? 'Ganó el desempate'
                                        : 'Empató',
                                    textAlign: TextAlign.center,
                                    style: (grande
                                            ? t.titleMedium
                                            : t.labelLarge)
                                        ?.copyWith(
                                          color: tinta.withValues(
                                            alpha: g.ganoDesempate ? 1 : 0.75,
                                          ),
                                          fontWeight:
                                              g.ganoDesempate
                                                  ? Peso.titulo
                                                  : Peso.normal,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (empate) ...[
                    SizedBox(height: grande ? Esp.xl : Esp.m),
                    Container(
                      padding: EdgeInsets.all(grande ? Esp.l : Esp.m),
                      decoration: BoxDecoration(
                        color: tinta.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(Esquina.chica),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.balance_outlined,
                            size: grande ? 36 : 22,
                            color: tinta,
                          ),
                          SizedBox(width: grande ? Esp.l : Esp.s),
                          Expanded(
                            child: Text(
                              textoEmpate!,
                              style: (grande ? t.titleLarge : t.bodyMedium)
                                  ?.copyWith(color: tinta),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
