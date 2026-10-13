/// Las fotos de una caja a pantalla completa: se pasan deslizando (o con las
/// flechas y el teclado en la web), se amplían con pellizco o doble toque y
/// desde aquí se reemplazan o eliminan. Sin `Hero` a propósito: dos miniaturas
/// de la misma foto en pantalla (lista y detalle) chocarían por la etiqueta.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bosque_flutter/core/ui/tokens_bosque.dart';
import 'package:bosque_flutter/domain/entities/caja_archivo_entity.dart';
import 'package:bosque_flutter/domain/entities/foto_caja_entity.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/comun_archivo.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/imagen_foto.dart';
import 'package:bosque_flutter/presentation/widgets/archivo-documental/paleta_archivo.dart';

enum AccionFoto { reemplazar, eliminar }

/// Devuelve lo que la persona eligió hacer con una foto; la subida o el
/// borrado los hace quien abrió el visor, que sabe mostrar el avance.
Future<(AccionFoto, FotoCajaEntity)?> verFotosDeCaja(
  BuildContext context, {
  required CajaArchivoEntity caja,
  required List<FotoCajaEntity> fotos,
  required int inicial,
}) {
  return showDialog<(AccionFoto, FotoCajaEntity)>(
    context: context,
    barrierColor: Colors.black,
    useSafeArea: false,
    builder: (_) => _VisorFotos(caja: caja, fotos: fotos, inicial: inicial),
  );
}

const Color _fondoVisor = Color(0xFF0E0E10);
const Color _velo = Color(0x99000000);

class _VisorFotos extends StatefulWidget {
  const _VisorFotos({required this.caja, required this.fotos, required this.inicial});

  final CajaArchivoEntity caja;
  final List<FotoCajaEntity> fotos;
  final int inicial;

  @override
  State<_VisorFotos> createState() => _VisorFotosState();
}

class _VisorFotosState extends State<_VisorFotos> {
  late final PageController _paginas;
  late int _actual;

  /// Con la foto ampliada el arrastre mueve la foto, no cambia de página.
  bool _ampliada = false;

  int get _total => widget.fotos.length;

  @override
  void initState() {
    super.initState();
    _actual = widget.inicial.clamp(0, _total - 1);
    _paginas = PageController(initialPage: _actual);
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  void _ir(int i) {
    if (i < 0 || i >= _total || !_paginas.hasClients) return;
    _paginas.animateToPage(
      i,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  String _rotulo(int i) =>
      'Foto ${widget.fotos[i].orden} de ${tituloCaja(widget.caja).toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final foto = widget.fotos[_actual];
    final t = tonoDe(context, TonosArchivo.fotos);
    final peligro = tonoDe(context, TonosArchivo.peligro);

    return Dialog.fullscreen(
      backgroundColor: _fondoVisor,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _ir(_actual - 1),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () => _ir(_actual + 1),
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: _paginas,
                  physics:
                      _ampliada ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                  itemCount: _total,
                  onPageChanged:
                      (i) => setState(() {
                        _actual = i;
                        _ampliada = false;
                      }),
                  itemBuilder:
                      (context, i) => _FotoAmpliable(
                        key: ValueKey(widget.fotos[i].codFoto),
                        foto: widget.fotos[i],
                        rotulo: _rotulo(i),
                        onAmpliada: (v) {
                          if (i == _actual && v != _ampliada) setState(() => _ampliada = v);
                        },
                      ),
                ),
              ),
              // Barra superior: cerrar y dónde estoy.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ColoredBox(
                  color: _velo,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(Esp.xs, Esp.xs, Esp.l, Esp.xs),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: 'Cerrar las fotos',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: Esp.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${tituloCaja(widget.caja)} · ${oGuion(widget.caja.nombreArchivo)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: Peso.titulo,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Foto ${_actual + 1} de $_total',
                                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_total > 1 && _actual > 0)
                _Flecha(
                  izquierda: true,
                  onPressed: () => _ir(_actual - 1),
                ),
              if (_total > 1 && _actual < _total - 1)
                _Flecha(
                  izquierda: false,
                  onPressed: () => _ir(_actual + 1),
                ),
              // Barra inferior: miniaturas para saltar y las acciones de la foto visible.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ColoredBox(
                  color: _velo,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(Esp.m),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: Esp.l,
                        runSpacing: Esp.m,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < _total; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: Esp.s),
                                  child: _MiniaturaVisor(
                                    foto: widget.fotos[i],
                                    elegida: i == _actual,
                                    borde: t.fuerte,
                                    rotulo: _rotulo(i),
                                    onTap: () => _ir(i),
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.icon(
                                style: estiloTonal(context, TonosArchivo.fotos),
                                onPressed:
                                    () => Navigator.of(context).pop((AccionFoto.reemplazar, foto)),
                                icon: const Icon(Icons.flip_camera_ios_outlined, size: 18),
                                label: const Text('Reemplazar'),
                              ),
                              const SizedBox(width: Esp.s),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: peligro.fondo,
                                  foregroundColor: peligro.texto,
                                ),
                                onPressed:
                                    () => Navigator.of(context).pop((AccionFoto.eliminar, foto)),
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

class _Flecha extends StatelessWidget {
  const _Flecha({required this.izquierda, required this.onPressed});

  final bool izquierda;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Positioned(
    left: izquierda ? Esp.s : null,
    right: izquierda ? null : Esp.s,
    top: 0,
    bottom: 0,
    child: Center(
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: const Color(0x33FFFFFF),
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
        ),
        icon: Icon(izquierda ? Icons.chevron_left : Icons.chevron_right),
        tooltip: izquierda ? 'Foto anterior' : 'Foto siguiente',
        onPressed: onPressed,
      ),
    ),
  );
}

class _MiniaturaVisor extends StatelessWidget {
  const _MiniaturaVisor({
    required this.foto,
    required this.elegida,
    required this.borde,
    required this.rotulo,
    required this.onTap,
  });

  final FotoCajaEntity foto;
  final bool elegida;
  final Color borde;
  final String rotulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: elegida,
    label: rotulo,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Esquina.chica),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Esquina.chica),
          border: Border.all(color: elegida ? borde : const Color(0x55FFFFFF), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Esquina.chica - 2),
          child: ImagenDeFoto(codFoto: foto.codFoto, ruta: foto.ruta, anchoLogico: 48),
        ),
      ),
    ),
  );
}

/// Una foto que se amplía con pellizco o doble toque. Avisa cuando está
/// ampliada para que el visor no cambie de página al arrastrarla.
class _FotoAmpliable extends StatefulWidget {
  const _FotoAmpliable({
    super.key,
    required this.foto,
    required this.rotulo,
    required this.onAmpliada,
  });

  final FotoCajaEntity foto;
  final String rotulo;
  final ValueChanged<bool> onAmpliada;

  @override
  State<_FotoAmpliable> createState() => _FotoAmpliableState();
}

class _FotoAmpliableState extends State<_FotoAmpliable> {
  final _control = TransformationController();
  Offset? _toque;
  bool _ampliada = false;

  @override
  void initState() {
    super.initState();
    _control.addListener(_alCambiar);
  }

  @override
  void dispose() {
    _control
      ..removeListener(_alCambiar)
      ..dispose();
    super.dispose();
  }

  void _alCambiar() {
    final ampliada = _control.value.getMaxScaleOnAxis() > 1.01;
    if (ampliada != _ampliada) {
      _ampliada = ampliada;
      widget.onAmpliada(ampliada);
    }
  }

  void _dobleToque() {
    if (_ampliada) {
      _control.value = Matrix4.identity();
      return;
    }
    // Amplía 2,5 veces dejando quieto el punto tocado.
    const escala = 2.5;
    final p = _toque ?? Offset.zero;
    _control.value =
        Matrix4.diagonal3Values(escala, escala, 1)
          ..setTranslationRaw(-p.dx * (escala - 1), -p.dy * (escala - 1), 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder:
          (context, r) => GestureDetector(
            onDoubleTapDown: (d) => _toque = d.localPosition,
            onDoubleTap: _dobleToque,
            child: InteractiveViewer(
              transformationController: _control,
              minScale: 1,
              maxScale: 5,
              child: SizedBox(
                width: r.maxWidth,
                height: r.maxHeight,
                child: ImagenDeFoto(
                  codFoto: widget.foto.codFoto,
                  ruta: widget.foto.ruta,
                  anchoLogico: r.maxWidth,
                  fit: BoxFit.contain,
                  rotulo: widget.rotulo,
                  mientras: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}
