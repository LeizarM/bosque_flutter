/// Las fotos y PDF de una caja: opcionales, de 0 a 3 entre los dos, para
/// reconocerla en el estante o guardar su inventario. Tres lugares fijos; una
/// foto se abre a pantalla completa y un PDF en el visor de PDF. El permiso de
/// cámara lo pide el sistema recién al tocar «Tomar foto».
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bosque_flutter/core/state/archivo_documental_provider.dart';
import 'package:bosque_flutter/core/ui/aviso.dart';
import 'package:bosque_flutter/core/ui/confirmacion.dart';
import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/core/utils/tipo_imagen.dart';
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
  String get _caja => tituloCaja(widget.caja).toLowerCase();

  /// Siempre se pregunta qué agregar: una foto o un PDF. La cámara solo aparece
  /// donde existe (teléfono, o el navegador de un teléfono).
  Future<FotoElegida?> _elegir() async {
    final camara = ref.read(camaraDisponibleProvider);
    final origen = await showModalBottomSheet<OrigenFoto>(
      context: context,
      useSafeArea: true,
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.symmetric(vertical: Esp.s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (camara)
                  ListTile(
                    leading: const IconoTono(Icons.photo_camera_outlined, TonosArchivo.fotos),
                    title: const Text('Tomar foto'),
                    onTap: () => Navigator.pop(ctx, OrigenFoto.camara),
                  ),
                ListTile(
                  leading: const IconoTono(Icons.photo_library_outlined, TonosArchivo.documentos),
                  title: Text(camara ? 'Elegir de la galería' : 'Elegir una foto'),
                  subtitle: const Text('JPG, PNG o WEBP'),
                  onTap: () => Navigator.pop(ctx, OrigenFoto.galeria),
                ),
                ListTile(
                  leading: const IconoTono(Icons.picture_as_pdf_outlined, TonosArchivo.peligro),
                  title: const Text('Elegir un PDF'),
                  subtitle: const Text('Por ejemplo, el inventario de la caja. Hasta 10 MB.'),
                  onTap: () => Navigator.pop(ctx, OrigenFoto.pdf),
                ),
              ],
            ),
          ),
    );
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
    final elegido = await _elegir();
    if (elegido == null || !mounted) return;
    final repo = ref.read(archivoDocumentalRepositoryProvider);
    await _escribir(
      lugar,
      (progreso) => repo.subirFoto(_codCaja, elegido.bytes, elegido.nombre, alProgreso: progreso),
      esPdf(elegido.bytes) ? 'PDF agregado a la $_caja.' : 'Foto agregada a la $_caja.',
    );
  }

  Future<void> _reemplazar(FotoCajaEntity actual, int lugar) async {
    final elegido = await _elegir();
    if (elegido == null || !mounted) return;
    final repo = ref.read(archivoDocumentalRepositoryProvider);
    await _escribir(
      lugar,
      (progreso) => repo.reemplazarFoto(actual.codFoto, elegido.bytes, elegido.nombre, alProgreso: progreso),
      actual.esPdf ? 'PDF reemplazado.' : 'Foto reemplazada.',
    );
  }

  Future<void> _eliminar(FotoCajaEntity actual, int lugar) async {
    final que = actual.esPdf ? 'el PDF ${actual.orden}' : 'la foto ${actual.orden}';
    // Se confirma: el archivo se borra del servidor para todos los usuarios.
    final ok = await confirmar(
      context,
      titulo: 'Eliminar $que',
      detalle: 'Se quita de la caja para todos los usuarios. Puedes agregar otro cuando quieras.',
      textoConfirmar: actual.esPdf ? 'Eliminar PDF' : 'Eliminar foto',
      destructiva: true,
    );
    if (!ok || !mounted) return;
    final repo = ref.read(archivoDocumentalRepositoryProvider);
    await _escribir(lugar, (_) => repo.eliminarFoto(actual.codFoto), actual.esPdf ? 'PDF eliminado.' : 'Foto eliminada.');
  }

  /// Un PDF se baja y se abre en el visor de PDF de la app (imprimir o compartir).
  Future<void> _verPdf(FotoCajaEntity pdf, int lugar) async {
    final repo = ref.read(archivoDocumentalRepositoryProvider);
    final ver = ref.read(visorPdfArchivoProvider);
    setState(() {
      _lugarOcupado = lugar;
      _avance = null;
    });
    try {
      final bytes = await repo.verFoto(pdf.codFoto);
      if (!mounted) return;
      setState(() => _lugarOcupado = null);
      await ver(
        context,
        bytes: bytes,
        titulo: 'PDF ${pdf.orden} · ${tituloCaja(widget.caja)}',
        nombreArchivo: 'caja-${widget.caja.numero}-${oGuion(widget.caja.nombreArchivo).toLowerCase()}-${pdf.orden}.pdf',
      );
    } catch (e) {
      if (mounted) mostrarAviso(context, textoParaUsuario(e), tono: TonoAviso.error);
    } finally {
      if (mounted && _lugarOcupado == lugar) setState(() => _lugarOcupado = null);
    }
  }

  /// Las fotos se pasan una tras otra en el visor; un PDF va al suyo.
  Future<void> _ver(List<FotoCajaEntity> todas, int indice) async {
    final elegida = todas[indice];
    if (elegida.esPdf) return _verPdf(elegida, indice);
    final fotos = [
      for (final f in todas)
        if (!f.esPdf) f,
    ];
    final r = await verFotosDeCaja(context, caja: widget.caja, fotos: fotos, inicial: fotos.indexOf(elegida));
    if (r == null || !mounted) return;
    final (accion, foto) = r;
    final lugar = todas.indexOf(foto);
    if (accion == AccionFoto.reemplazar) await _reemplazar(foto, lugar);
    if (accion == AccionFoto.eliminar) await _eliminar(foto, lugar);
  }

  String _rotulo(FotoCajaEntity f) =>
      '${f.esPdf ? 'PDF' : 'Foto'} ${f.orden} de ${FotoCajaEntity.maximo}, $_caja, '
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
            // Tres lugares siempre: las fotos y PDF, un «agregar» y lugares vacíos.
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
                              rotulo: _rotulo(ordenadas[i]),
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

/// Un PDF en su lugar: no hay miniatura que dibujar, así que se muestra como
/// una hoja con su sello, en el rojo de los PDF.
class _HojaPdf extends StatelessWidget {
  const _HojaPdf({required this.lado});

  final double lado;

  @override
  Widget build(BuildContext context) {
    final t = tonoDe(context, TonosArchivo.peligro);
    return ColoredBox(
      color: t.fondo,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(Esp.s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.picture_as_pdf_outlined, size: lado * 0.34, color: t.fuerte),
                const SizedBox(height: Esp.xs),
                Text(
                  'PDF',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: t.texto, fontWeight: Peso.dato),
                ),
                Text('Tócalo para abrirlo', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: t.texto)),
              ],
            ),
          ),
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
    final t = tonoDe(context, foto.esPdf ? TonosArchivo.peligro : TonosArchivo.fotos);

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
              child:
                  foto.esPdf
                      ? _HojaPdf(lado: lado)
                      : ImagenDeFoto(codFoto: foto.codFoto, ruta: foto.ruta, anchoLogico: lado),
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
                tooltip: 'Acciones de${foto.esPdf ? 'l PDF' : ' la foto'} ${foto.orden}',
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
                      PopupMenuItem(
                        value: 0,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: IconoTono(
                            foto.esPdf ? Icons.picture_as_pdf_outlined : Icons.zoom_out_map,
                            foto.esPdf ? TonosArchivo.peligro : TonosArchivo.fotos,
                            lado: 28,
                          ),
                          title: Text(foto.esPdf ? 'Abrir PDF' : 'Ver en grande'),
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
                  'Agregar foto o PDF',
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
