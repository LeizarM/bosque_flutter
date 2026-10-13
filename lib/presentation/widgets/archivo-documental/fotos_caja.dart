/// Las fotos de una caja: opcionales, de 0 a 3, para reconocerla en el
/// estante. Tres lugares fijos; tocar una foto la abre a pantalla completa. El
/// permiso de cámara lo pide el sistema recién al tocar «Tomar foto».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/imagen_foto.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/visor_fotos.dart';

class FotosCaja extends ConsumerStatefulWidget {
  const FotosCaja({super.key, required this.caja});

  final CajaArchivoEntity caja;

  @override
  ConsumerState<FotosCaja> createState() => _FotosCajaState();
}

class _FotosCajaState extends ConsumerState<FotosCaja> {
  /// Lugar con una subida o un reemplazo viajando, y su avance (0 a 1).
  int? _lugarOcupado;
  double? _avance;

  int get _codCaja => widget.caja.codCaja;

  Future<FotoElegida?> _elegir() async {
    final camara = ref.read(camaraDisponibleProvider);
    OrigenFoto? origen = OrigenFoto.galeria;
    if (camara) {
      origen = await showModalBottomSheet<OrigenFoto>(
        context: context,
        useSafeArea: true,
        builder:
            (ctx) => Padding(
              padding: const EdgeInsets.symmetric(vertical: Esp.s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const IconoTono(Icons.photo_camera_outlined, TonosArchivo.fotos),
                    title: const Text('Tomar foto'),
                    onTap: () => Navigator.pop(ctx, OrigenFoto.camara),
                  ),
                  ListTile(
                    leading: const IconoTono(Icons.photo_library_outlined, TonosArchivo.documentos),
                    title: const Text('Elegir de la galería'),
                    onTap: () => Navigator.pop(ctx, OrigenFoto.galeria),
                  ),
                ],
              ),
            ),
      );
    }
    if (origen == null || !mounted) return null;
    try {
      return await ref.read(elegirFotoProvider)(origen);
    } catch (e) {
      if (mounted) mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
      return null;
    }
  }

  Future<void> _escribir(
    int lugar,
    Future<void> Function(void Function(int, int)) op,
    String hecho,
  ) async {
    // El contenedor se toma antes de esperar: si la persona sale de la caja a
    // mitad de la subida, `ref` ya no se puede usar pero la lista igual se
    // tiene que poner al día.
    final contenedor = ProviderScope.containerOf(context, listen: false);
    setState(() {
      _lugarOcupado = lugar;
      _avance = null;
    });
    try {
      await op((enviados, total) {
        if (mounted && total > 0) setState(() => _avance = enviados / total);
      });
      contenedor.invalidate(fotosCajaProvider(_codCaja));
      if (contenedor.exists(archivoDocumentalProvider)) {
        await contenedor.read(archivoDocumentalProvider.notifier).fotosCambiaron();
      }
      if (mounted) avisar(context, hecho);
    } catch (e) {
      if (mounted) mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    } finally {
      if (mounted) {
        setState(() {
          _lugarOcupado = null;
          _avance = null;
        });
      }
    }
  }

  Future<void> _agregar(int lugar) async {
    final foto = await _elegir();
    if (foto == null || !mounted) return;
    final repo = ref.read(archivoDocumentalRepositoryProvider);
    await _escribir(
      lugar,
      (progreso) => repo.subirFoto(_codCaja, foto.bytes, foto.nombre, alProgreso: progreso),
      'Foto agregada a la ${tituloCaja(widget.caja).toLowerCase()}.',
    );
  }

  Future<void> _reemplazar(FotoCajaEntity actual, int lugar) async {
    final foto = await _elegir();
    if (foto == null || !mounted) return;
    final repo = ref.read(archivoDocumentalRepositoryProvider);
    await _escribir(
      lugar,
      (progreso) => repo.reemplazarFoto(actual.codFoto, foto.bytes, foto.nombre, alProgreso: progreso),
      'Foto reemplazada.',
    );
  }

  Future<void> _eliminar(FotoCajaEntity actual, int lugar) async {
    // Se confirma: la foto se borra del servidor para todos los usuarios.
    final ok = await confirmar(
      context,
      titulo: 'Eliminar la foto ${actual.orden}',
      detalle: 'La foto se quita de la caja para todos los usuarios. Puedes agregar otra cuando quieras.',
      textoConfirmar: 'Eliminar foto',
      destructiva: true,
    );
    if (!ok || !mounted) return;
    final repo = ref.read(archivoDocumentalRepositoryProvider);
    await _escribir(lugar, (_) => repo.eliminarFoto(actual.codFoto), 'Foto eliminada.');
  }

  Future<void> _ver(List<FotoCajaEntity> fotos, int indice) async {
    final r = await verFotosDeCaja(context, caja: widget.caja, fotos: fotos, inicial: indice);
    if (r == null || !mounted) return;
    final (accion, foto) = r;
    final lugar = fotos.indexOf(foto);
    if (accion == AccionFoto.reemplazar) await _reemplazar(foto, lugar);
    if (accion == AccionFoto.eliminar) await _eliminar(foto, lugar);
  }

  String _rotulo(int orden) =>
      'Foto $orden de ${FotoCajaEntity.maximo}, ${tituloCaja(widget.caja).toLowerCase()}, '
      '${oGuion(widget.caja.nombreArchivo)}';

  @override
  Widget build(BuildContext context) {
    final fotos = ref.watch(fotosCajaProvider(_codCaja));
    final cs = Theme.of(context).colorScheme;

    return fotos.when(
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error:
          (e, _) => Row(
            children: [
              Icon(Icons.error_outline, color: cs.error),
              const SizedBox(width: Esp.s),
              Expanded(child: Text(textoParaUsuario(e))),
              TextButton(
                onPressed: () => ref.invalidate(fotosCajaProvider(_codCaja)),
                child: const Text('Reintentar'),
              ),
            ],
          ),
      data: (lista) {
        final ordenadas = [...lista]..sort((a, b) => a.orden.compareTo(b.orden));
        return LayoutBuilder(
          builder: (context, r) {
            // Tres lugares siempre: las fotos, un «agregar» y lugares vacíos.
            final lado = ((r.maxWidth - 2 * Esp.m) / 3).clamp(80.0, 220.0);
            return Wrap(
              spacing: Esp.m,
              runSpacing: Esp.m,
              children: [
                for (var i = 0; i < FotoCajaEntity.maximo; i++)
                  SizedBox(
                    width: lado,
                    height: lado,
                    child:
                        i < ordenadas.length
                            ? _Miniatura(
                              foto: ordenadas[i],
                              lado: lado,
                              rotulo: _rotulo(ordenadas[i].orden),
                              ocupado: _lugarOcupado == i,
                              bloqueado: _lugarOcupado != null,
                              avance: _avance,
                              onVer: () => _ver(ordenadas, i),
                              onReemplazar: () => _reemplazar(ordenadas[i], i),
                              onEliminar: () => _eliminar(ordenadas[i], i),
                            )
                            : _LugarVacio(
                              agregar: i == ordenadas.length,
                              ocupado: _lugarOcupado == i,
                              bloqueado: _lugarOcupado != null,
                              avance: _avance,
                              onAgregar: () => _agregar(i),
                            ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// La espera de una subida: el avance en porcentaje sobre la foto o el lugar.
class _Avance extends StatelessWidget {
  const _Avance({required this.avance});

  final double? avance;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, TonosArchivo.fotos);
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(value: avance, color: t.fuerte),
            if (avance != null) ...[
              const SizedBox(height: Esp.s),
              Text(
                '${(avance! * 100).round()} %',
                style: context.numero(fuerte: true, color: t.fuerte),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    required this.foto,
    required this.lado,
    required this.rotulo,
    required this.ocupado,
    required this.bloqueado,
    required this.avance,
    required this.onVer,
    required this.onReemplazar,
    required this.onEliminar,
  });

  final FotoCajaEntity foto;
  final double lado;
  final String rotulo;
  final bool ocupado;
  final bool bloqueado;
  final double? avance;
  final VoidCallback onVer;
  final VoidCallback onReemplazar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = tonoDe(context, TonosArchivo.fotos);

    return Semantics(
      label: rotulo,
      button: true,
      child: Material(
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Esquina.media),
          side: BorderSide(color: t.fuerte.withValues(alpha: 0.35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InkWell(
              onTap: bloqueado ? null : onVer,
              child: ImagenDeFoto(codFoto: foto.codFoto, ruta: foto.ruta, anchoLogico: lado),
            ),
            Positioned(
              left: Esp.xs,
              bottom: Esp.xs,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Esp.s, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.fuerte,
                    borderRadius: BorderRadius.circular(Esquina.pastilla),
                  ),
                  child: Text(
                    '${foto.orden}',
                    style: context.numero(fuerte: true, color: t.sobreFuerte),
                  ),
                ),
              ),
            ),
            if (ocupado) _Avance(avance: avance),
            Positioned(
              top: Esp.xs,
              right: Esp.xs,
              child: PopupMenuButton<int>(
                enabled: !bloqueado,
                tooltip: 'Acciones de la ${rotulo.split(',').first.toLowerCase()}',
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.surface.withValues(alpha: 0.88),
                  child: Icon(Icons.more_vert, size: 18, color: cs.onSurface),
                ),
                onSelected: (v) {
                  if (v == 0) onVer();
                  if (v == 1) onReemplazar();
                  if (v == 2) onEliminar();
                },
                itemBuilder:
                    (_) => [
                      const PopupMenuItem(
                        value: 0,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: IconoTono(Icons.zoom_out_map, TonosArchivo.fotos, lado: 28),
                          title: Text('Ver en grande'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 1,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: IconoTono(Icons.flip_camera_ios_outlined, TonosArchivo.documentos, lado: 28),
                          title: Text('Reemplazar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const IconoTono(Icons.delete_outline, TonosArchivo.peligro, lado: 28),
                          title: Text('Eliminar', style: TextStyle(color: cs.error)),
                        ),
                      ),
                    ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LugarVacio extends StatelessWidget {
  const _LugarVacio({
    required this.agregar,
    required this.ocupado,
    required this.bloqueado,
    required this.avance,
    required this.onAgregar,
  });

  /// Solo el primer lugar libre ofrece agregar; los demás quedan de muestra.
  final bool agregar;
  final bool ocupado;
  final bool bloqueado;
  final double? avance;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = tonoDe(context, TonosArchivo.fotos);
    final borde = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Esquina.media),
      side: BorderSide(color: agregar ? t.fuerte.withValues(alpha: 0.5) : cs.outlineVariant),
    );
    if (ocupado) {
      return Material(shape: borde, clipBehavior: Clip.antiAlias, child: _Avance(avance: avance));
    }
    if (!agregar) {
      return Material(
        shape: borde,
        color: cs.surfaceContainerLowest,
        child: Center(
          child: Icon(Icons.image_outlined, color: cs.outlineVariant, semanticLabel: 'Lugar libre'),
        ),
      );
    }
    return Material(
      shape: borde,
      color: t.fondo,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: bloqueado ? null : onAgregar,
        child: Padding(
          padding: const EdgeInsets.all(Esp.s),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IconoTono(Icons.add_a_photo_outlined, TonosArchivo.fotos, lado: 40),
                const SizedBox(height: Esp.s),
                Text(
                  'Agregar foto',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: t.texto,
                    fontWeight: Peso.titulo,
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
