/// Las fotos de las cajas en pantalla: siempre desde bytes (`Image.memory`),
/// que funciona igual en la web y en el teléfono, decodificadas al tamaño en
/// que se muestran y con un hueco digno si la imagen no se puede leer.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

/// Una foto del servidor. [anchoLogico] decide a qué tamaño se decodifica:
/// una miniatura de 48 px no tiene por qué ocupar la memoria de 1600 px.
class ImagenDeFoto extends ConsumerWidget {
  const ImagenDeFoto({
    super.key,
    required this.codFoto,
    required this.ruta,
    required this.anchoLogico,
    this.fit = BoxFit.cover,
    this.mientras,
    this.rotulo,
  });

  final int codFoto;
  final String? ruta;
  final double anchoLogico;
  final BoxFit fit;

  /// Lo que se ve mientras llegan los bytes (por defecto, un fondo liso).
  final Widget? mientras;

  /// Para el lector de pantalla; null la deja fuera (la rotula quien la contiene).
  final String? rotulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final bytes = ref.watch(bytesFotoProvider((codFoto: codFoto, ruta: ruta)));
    final espera = mientras ?? ColoredBox(color: cs.surfaceContainerHigh);

    return bytes.when(
      loading: () => espera,
      error: (_, __) => _Rota(rotulo: rotulo),
      data: (b) {
        final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
        final ancho = anchoLogico.isFinite ? anchoLogico : 1600.0;
        // cacheWidth tiene que ser un entero positivo: nunca 0 ni infinito.
        final cache = math.max(1, math.min(1600, (ancho * dpr).round()));
        return Image.memory(
          b,
          fit: fit,
          cacheWidth: cache,
          gaplessPlayback: true,
          semanticLabel: rotulo,
          excludeFromSemantics: rotulo == null,
          errorBuilder: (_, __, ___) => _Rota(rotulo: rotulo),
          frameBuilder: (context, hijo, cuadro, sincronica) {
            if (sincronica) return hijo;
            return AnimatedOpacity(
              opacity: cuadro == null ? 0 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: hijo,
            );
          },
        );
      },
    );
  }
}

class _Rota extends StatelessWidget {
  const _Rota({this.rotulo});

  final String? rotulo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: cs.onSurfaceVariant,
          semanticLabel: rotulo == null ? null : '$rotulo: no se pudo cargar',
        ),
      ),
    );
  }
}

/// La etiqueta de una caja: su número grande sobre el color de su archivo, como
/// el rótulo pegado al cartón. Si la caja tiene foto, la foto ocupa la etiqueta
/// y el número queda en una placa en la esquina.
class EtiquetaCaja extends StatelessWidget {
  const EtiquetaCaja({
    super.key,
    required this.caja,
    required this.semilla,
    this.lado = 48,
  });

  final CajaArchivoEntity caja;
  final Color semilla;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, semilla);
    final radio = BorderRadius.circular(lado >= 80 ? Esquina.media : Esquina.chica);
    final liso = _Numero(numero: caja.numero, tono: t, lado: lado);
    final portada = caja.codFotoPortada;

    return Semantics(
      label: 'Caja ${caja.numero}${portada == null ? '' : ', con foto'}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: lado,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radio,
            border: Border.all(color: t.fuerte.withValues(alpha: 0.45)),
          ),
          child: ClipRRect(
            borderRadius: radio,
            child:
                portada == null
                    ? liso
                    : Stack(
                      fit: StackFit.expand,
                      children: [
                        ImagenDeFoto(
                          codFoto: portada,
                          ruta: caja.rutaPortada,
                          anchoLogico: lado,
                          mientras: liso,
                        ),
                        Positioned(
                          left: 3,
                          bottom: 3,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: lado >= 80 ? Esp.s : 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: t.fuerte,
                              borderRadius: BorderRadius.circular(Esquina.pastilla),
                            ),
                            child: Text(
                              '${caja.numero}',
                              style: TextStyle(
                                color: t.sobreFuerte,
                                fontSize: lado >= 80 ? 15 : 11,
                                fontWeight: Peso.dato,
                                fontFeatures: cifrasTabulares,
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

class _Numero extends StatelessWidget {
  const _Numero({required this.numero, required this.tono, required this.lado});

  final int numero;
  final Tono tono;
  final double lado;

  @override
  Widget build(BuildContext context) {
    // FittedBox: con el texto del sistema al 200 % la etiqueta se achica en vez
    // de desbordar su cuadrado. Color pleno con su letra: contrasta en claro y oscuro.
    return ColoredBox(
      color: tono.fuerte,
      child: Padding(
        padding: EdgeInsets.all(lado * 0.08),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CAJA',
                style: TextStyle(
                  color: tono.sobreFuerte.withValues(alpha: 0.85),
                  fontSize: math.max(8, lado * 0.16),
                  fontWeight: Peso.titulo,
                  letterSpacing: 0.8,
                  height: 1,
                ),
              ),
              Text(
                '$numero',
                style: TextStyle(
                  color: tono.sobreFuerte,
                  fontSize: lado * 0.42,
                  fontWeight: Peso.dato,
                  fontFeatures: cifrasTabulares,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
