import 'dart:io';
//import 'dart:typed_data';
import 'package:bosque_flutter/core/utils/banner_personalizado.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/widgets/dependientes/confirm_dialogs.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';

class SeccionFotoDocsDropdown extends ConsumerStatefulWidget {
  final bool habilitarEdicion;
  final int codEmpleado;
  const SeccionFotoDocsDropdown({
    super.key,
    required this.habilitarEdicion,
    required this.codEmpleado,
  });

  @override
  ConsumerState<SeccionFotoDocsDropdown> createState() => _SeccionFotoDocsDropdownState();
}

class _SeccionFotoDocsDropdownState extends ConsumerState<SeccionFotoDocsDropdown> {
  final ImagePicker _picker = ImagePicker();
  String? _bannerMessage;
Color _bannerColor = Colors.red;

  String? _documentoSeleccionado;
  final Map<String, int> _documentos = {
    'Carnet de Identidad': 2,
    'Pasaporte': 1,
    'Licencia de Conducir': 2,
  };

  final Map<String, List<XFile>> _imagenes = {
    'Carnet de Identidad': [],
    'Pasaporte': [],
    'Licencia de Conducir': [],
  };
   bool get _isMobile {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  Future<void> _pickImages(String doc, int cantidad, {bool fromCamera = false}) async {
  List<XFile> images = [];
  final picker = ImagePicker();

  if (fromCamera) {
    // Permitir tomar varias fotos si el documento lo requiere
    for (int i = 0; i < cantidad; i++) {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        images.add(image);
      } else {
        // Si el usuario cancela, salimos del ciclo
        break;
      }
    }
  } else if (cantidad == 1) {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) images = [image];
  } else {
    images = await picker.pickMultiImage();
    if (images.length > 2) images = images.take(2).toList();
  }

  if (images.isNotEmpty) {
    setState(() {
      _imagenes[doc] = images;
    });
  }
}

 Future<bool> _subirImagen(XFile file, String doc, int index, {bool showSnackbar = true}) async {
  final bytes = await file.readAsBytes();
  String tipoDocumento;
  if (doc == 'Carnet de Identidad') {
    tipoDocumento = 'CARNET';
  } else if (doc == 'Pasaporte') {
    tipoDocumento = 'PASAPORTE';
  } else if (doc == 'Licencia de Conducir') {
    tipoDocumento = 'LICENCIA';
  } else {
    tipoDocumento = doc.toUpperCase();
  }
  String lado = (doc == 'Pasaporte') ? 'foto' : (index == 0 ? 'anverso' : 'reverso');
  try {
    final result = await ref.read(subirFotoDocProvider(
      (widget.codEmpleado, tipoDocumento, bytes, lado)
    ).future);
    print ('codEmpleado: ${widget.codEmpleado}, tipoDocumento: $tipoDocumento, lado: $lado, result: $result');
    if (!mounted) return false;
    if (result) {
      ref.invalidate(todosLosDocumentosProvider(widget.codEmpleado));
      if (showSnackbar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagen de $tipoDocumento ($lado) subida correctamente.Espere confirmación')),
        );
      }
      return true;
    }
  } catch (e) {
    if (!mounted) return false;
    if (showSnackbar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir imagen: $e')),
      );
    }
  }
  return false;
}


 Widget _imagePreview(XFile file, String label, String doc, int index) {
  final isMobile = ResponsiveUtilsBosque.isMobile(context);
  final double imageHeight = isMobile ? 110 : 140;

  return FutureBuilder<Uint8List>(
    future: file.readAsBytes(),
    builder: (context, snapshot) {
      Widget imageWidget;
      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            snapshot.data!,
            width: double.infinity,
            height: imageHeight,
            fit: BoxFit.cover,
          ),
        );
      } else {
        imageWidget = Container(
          width: double.infinity,
          height: imageHeight,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: imageHeight * 2.5,
                  height: imageHeight * 2.5,
                  child: snapshot.hasData
                      ? Image.memory(snapshot.data!, fit: BoxFit.contain)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          );
        },
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    imageWidget,
                    const SizedBox(height: 4),
                    Text(label, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                  tooltip: 'Eliminar',
                  onPressed: () {
                    setState(() {
                      final imagenes = _imagenes[doc]!;
                      imagenes.remove(file);
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
Widget build(BuildContext context) {
  final doc = _documentoSeleccionado;
  final cantidad = doc != null ? _documentos[doc]! : 0;
  final imagenes = doc != null ? _imagenes[doc]! : [];
  final isMobile = ResponsiveUtilsBosque.isMobile(context);

  return SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 24,
        vertical: isMobile ? 8 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_bannerMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: BannerCustom(
                message: _bannerMessage!,
                color: _bannerColor,
                icon: Icons.warning,
                onClose: () {
                  setState(() {
                    _bannerMessage = null;
                  });
                },
                 // Nuevo parámetro para personalizar el texto
      messageTextStyle: TextStyle(
        fontSize: isMobile ? 13 : 16,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      maxLines: isMobile ? 6 : null, // Limita a 3 líneas en móvil
              ),
            ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 10 : 16)),
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 10 : 16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Tipo de documento',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 10 : 16,
                        horizontal: isMobile ? 10 : 16,
                      ),
                    ),
                    value: _documentoSeleccionado,
                    items: _documentos.keys.map((tipo) =>
                      DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      )
                    ).toList(),
                    onChanged: widget.habilitarEdicion
                        ? (tipo) => setState(() => _documentoSeleccionado = tipo)
                        : null,
                  ),
                  if (doc != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            cantidad == 2
                              ? 'Puedes seleccionar hasta 2 imágenes (anverso y reverso) para este documento.'
                              : 'Selecciona la imagen del documento.',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: Text('Subir ${cantidad == 2 ? "documento" : "foto"}'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size.fromHeight(isMobile ? 40 : 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                              ),
                            ),
                            onPressed: widget.habilitarEdicion
                                ? () => _pickImages(doc, cantidad)
                                : null,
                          ),
                        ),
                        if (_isMobile) ...[
                          const SizedBox(width: 8),
                          Tooltip(
                            message: cantidad == 2
                                ? 'Puedes seleccionar hasta 2 imágenes (anverso y reverso) para este documento.'
                                : 'Selecciona la imagen del documento.',
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: widget.habilitarEdicion
                                  ? () => _pickImages(doc, cantidad, fromCamera: true)
                                  : null,
                              tooltip: 'Tomar foto',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (doc != null) ...[
            const SizedBox(height: 14),
            if (imagenes.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: imagenes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final label = (cantidad == 2)
                      ? (i == 0 ? 'Anverso' : 'Reverso')
                      : 'Foto';
                  return _imagePreview(imagenes[i], label, doc, i);
                },
              ),
            if (imagenes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Subir imágenes'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(isMobile ? 40 : 48),
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                    ),
                  ),
                  onPressed: () async {
                    if (cantidad > 1 && imagenes.length < cantidad) {
                      setState(() {
                        _bannerMessage = 'Seleccione $cantidad imágenes para este documento';
                        _bannerColor = Colors.red;
                      });
                      return;
                    }
                    bool huboError = false;
                    for (int i = 0; i < imagenes.length; i++) {
                      final result = await _subirImagen(imagenes[i], doc, i, showSnackbar: false);
                      if (!result) huboError = true;
                    }
                    if (!mounted) return;
                    if (huboError) {
                      AppSnackbarCustom.showError(
                        context,
                        'Hubo un error al subir alguna imagen de $doc.',
                      );
                    } else {
                      AppSnackbarCustom.showWarning(
                        context,
                        'Imágenes de $doc subidas correctamente.Espere aprobacion.',
                      );
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ],
      ),
    ),
  );
}
}