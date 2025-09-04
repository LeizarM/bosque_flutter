import 'dart:typed_data';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/banner_personalizado.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class SeccionFoto extends ConsumerStatefulWidget {
  final int codEmpleado;
  final bool habilitarEdicion;
  final Map<String, bool> estadoExpandido;
  final Function(String) onToggleSeccion;
  
  const SeccionFoto({
    Key? key,
    required this.codEmpleado,
    required this.habilitarEdicion,
    required this.estadoExpandido,
    required this.onToggleSeccion,
  }) : super(key: key);

  @override
  _SeccionFotoState createState() => _SeccionFotoState();
}

class _SeccionFotoState extends ConsumerState<SeccionFoto> {
  Uint8List? _imageBytes;
  int _imageTimestamp = DateTime.now().millisecondsSinceEpoch;
  XFile? imagenSeleccionada;
  Uint8List? _webImageBytes;
   bool _alertaMostrada = false;
   // BannerCustom
  String? _bannerMensaje;
  Color? _bannerColor;
  IconData? _bannerIcon;

  String _getImageUrl() {
  final imageVersion = ref.watch(imageVersionProvider); // ✅ Aquí sí
  return AppConstants.baseUrl +
      AppConstants.getImageUrl +
      '/${widget.codEmpleado}.jpg?v=$imageVersion';
}
 @override
void didChangeDependencies() {
  super.didChangeDependencies();
}

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _revisarFotoYAdvertir();
  });
}
Future<void> _revisarFotoYAdvertir() async {
  // Obtén el codEmpleado actual usando el mismo patrón que permisos_edicion.dart
  final codEmpleadoActual = await ref.read(userProvider.notifier).getCodEmpleado();

  // Solo muestra la alerta si el codEmpleado coincide
  if (widget.codEmpleado != codEmpleadoActual) return;

  try {
    final url = Uri.parse(_getImageUrl());
    final response = await http.get(url);

    final contentDisposition = response.headers['content-disposition'];
    if (contentDisposition != null && contentDisposition.contains('icon.png')) {
  if (mounted && !_alertaMostrada) {
    setState(() {
      _alertaMostrada = true;
      _bannerMensaje = 'Por favor, actualice su foto de perfil.';
      _bannerColor = Colors.red;
      _bannerIcon = Icons.warning;
    });
  }
}else {
      // Si la foto ya se actualizo, cierra el banner
      if (_alertaMostrada || _bannerMensaje != null) {
        setState(() {
          _alertaMostrada = false;
          _bannerMensaje = null;
          _bannerColor = null;
          _bannerIcon = null;
        });
      }
    }
  } catch (e) {
    print('Error revisando foto: $e');
  }
}
 //checkpoint
  Future<void> _seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imagen = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (imagen != null) {
        final bytes = await imagen.readAsBytes();
        setState(() {
          imagenSeleccionada = imagen;
          _imageBytes = bytes;
          _webImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbarCustom.showError(context, 'Error al seleccionar imagen: $e');
      }
    }
  }

  Future<void> _tomarFoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? imagen = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (imagen != null) {
        final bytes = await imagen.readAsBytes();
        setState(() {
          imagenSeleccionada = imagen;
          _imageBytes = bytes;
          _webImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        AppSnackbarCustom.showError(context, 'Error al tomar foto: $e');
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageBytes == null) {
      _showMessage('Seleccione una imagen primero');
      return;
    }

    try {
      await ref.read(subirFotoProvider((widget.codEmpleado, _imageBytes!)).future);

      setState(() {
        _imageTimestamp = DateTime.now().millisecondsSinceEpoch;
        _imageBytes = null;
      });
      ref.read(imageVersionProvider.notifier).state++;

      if (!mounted) return;
      _showMessage('Imagen subida exitosamente', isError: false);
    } catch (e) {
      _showMessage('Error al subir la imagen: $e');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    if (isError) {
      AppSnackbarCustom.showError(context, message);
    } else {
      AppSnackbarCustom.showSuccess(context, message);
    }
  }

  bool get _isMobile {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(imageVersionProvider, (previous, next) {
    if (previous != next) {
      _revisarFotoYAdvertir();
    }
  });
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDark ? colorScheme.surface : Colors.white;
    final Color borderColor = isDark ? colorScheme.primary : Colors.teal.shade700;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 8,
        vertical: isDesktop ? 16 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //header
          if (_bannerMensaje != null)
        BannerCustom(
          message: _bannerMensaje!,
          color: _bannerColor ?? Colors.red,
          icon: _bannerIcon ?? Icons.warning,
        ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOTO DE PERFIL',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.grey.shade900,
                  fontFamily: 'Montserrat',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Divider(height: 20, color: Colors.grey.withOpacity(0.18)),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double photoSize = constraints.maxWidth.clamp(120.0, 260.0);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Foto circular
                    Hero(
  tag: 'empleado-imagen-${widget.codEmpleado}',
  child: GestureDetector(
    onTap: () => _mostrarImagenCompleta(context, photoSize),
    child: _imageBytes != null
        ? ClipOval(
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              width: photoSize,
              height: photoSize,
            ),
          )
        : CircleAvatar(
            radius: photoSize / 2,
            backgroundImage: NetworkImage(_getImageUrl()),
            onBackgroundImageError: (_, __) {
              setState(() => _imageBytes = null);
            },
          ),
  ),
),

                    // Botón para seleccionar imagen (galería)
                    if (widget.habilitarEdicion)
                      Positioned(
                        right: _isMobile ? 48 : 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: borderColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.photo_library),
                            color: Colors.white,
                            onPressed: _seleccionarImagen,
                            tooltip: 'Seleccionar de galería',
                          ),
                        ),
                      ),

                    // Botón para tomar foto (solo móvil)
                    if (widget.habilitarEdicion && _isMobile)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            color: Colors.white,
                            onPressed: _tomarFoto,
                            tooltip: 'Tomar foto',
                          ),
                        ),
                      ),

                    // Botones de guardar/cancelar cuando hay imagen seleccionada
                    if (_imageBytes != null && widget.habilitarEdicion)
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.check),
                                color: Colors.white,
                                onPressed: _uploadImage,
                                tooltip: 'Guardar',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                color: Colors.white,
                                onPressed: () => setState(() {
                                  _imageBytes = null;
                                  _webImageBytes = null;
                                  imagenSeleccionada = null;
                                }),
                                tooltip: 'Cancelar',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void _mostrarImagenCompleta(BuildContext context, double photoSize) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black87,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Hero(
              tag: 'empleado-imagen-${widget.codEmpleado}',
              child: _imageBytes != null
                  ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                  : Image.network(_getImageUrl(), fit: BoxFit.contain),
            ),
          ),
        ),
      );
    },
  );
}

  

 
}