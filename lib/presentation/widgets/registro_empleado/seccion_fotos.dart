// lib/presentation/widgets/registro_empleado/seccion_fotos.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/console_log.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/data/repositories/ficha_trabajador_impl.dart';

class DetalleDocumentosEmpleado extends ConsumerStatefulWidget {
  final int codEmpleado;

  const DetalleDocumentosEmpleado({Key? key, required this.codEmpleado})
    : super(key: key);

  @override
  ConsumerState<DetalleDocumentosEmpleado> createState() =>
      _DetalleDocumentosEmpleadoState();
}

class _DetalleDocumentosEmpleadoState
    extends ConsumerState<DetalleDocumentosEmpleado> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.document_scanner),
      label: const Text('Ver Documentos'),
      onPressed: () => _mostrarDialogoDocumentos(context),
    );
  }

  void _mostrarDialogoDocumentos(BuildContext context) {
    console(
      '🔍 Abriendo diálogo de documentos para codEmpleado: ${widget.codEmpleado}',
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => _DocumentosDialog(
            codEmpleado: widget.codEmpleado,
            imagePicker: _imagePicker,
          ),
    );
  }
}

// ============================================================================
// WIDGET DEL DIALOG ÚNICO - UNA SOLA VISTA
// ============================================================================

class _DocumentosDialog extends ConsumerStatefulWidget {
  final int codEmpleado;
  final ImagePicker imagePicker;

  const _DocumentosDialog({
    required this.codEmpleado,
    required this.imagePicker,
  });

  @override
  ConsumerState<_DocumentosDialog> createState() => _DocumentosDialogState();
}

class _DocumentosDialogState extends ConsumerState<_DocumentosDialog> {
  late Map<String, List<XFile?>> _fotosEnEdicion;
  late Set<String> _tiposEnEdicion;
  bool _isUploading = false;
  bool _isDeleting = false;

  static const Map<String, (String, int)> tiposDocumentos = {
    'carnet': ('Carnet de Identidad', 2),
    'pasaporte': ('Pasaporte', 1),
    'licencia': ('Licencia de Conducir', 2),
  };

  @override
  void initState() {
    super.initState();
    _fotosEnEdicion = {};
    _tiposEnEdicion = {};
  }

  void _entrarModoEdicion(String tipoKey, int cantidadRequerida) {
    setState(() {
      if (!_tiposEnEdicion.contains(tipoKey)) {
        _fotosEnEdicion[tipoKey] = List<XFile?>.filled(cantidadRequerida, null);
        _tiposEnEdicion.add(tipoKey);
      }
    });
  }

  void _salirModoEdicion(String tipoKey) {
    setState(() {
      _tiposEnEdicion.remove(tipoKey);
      _fotosEnEdicion.remove(tipoKey);
    });
  }

  Future<void> _seleccionarFoto(String tipoKey, int index) async {
    final cantidadRequerida = tiposDocumentos[tipoKey]!.$2;
    final lado =
        cantidadRequerida == 2 ? (index == 0 ? 'Anverso' : 'Reverso') : 'Foto';

    try {
      console('📷 Seleccionando $lado (índice: $index)');

      final XFile? foto = await widget.imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (foto != null) {
        console('✅ $lado seleccionado');
        setState(() {
          _fotosEnEdicion[tipoKey]![index] = foto;
        });
      } else {
        console('⚠️  Usuario canceló selección de $lado');
      }
    } catch (e) {
      console('❌ Error al seleccionar $lado: $e');
    }
  }

  Future<void> _subirFoto(String tipoKey, XFile file, int index) async {
    final bytes = await file.readAsBytes();
    final tipoDocumentoBackend = tipoKey.toUpperCase();
    final cantidadRequerida = tiposDocumentos[tipoKey]!.$2;
    final lado =
        cantidadRequerida == 2 ? (index == 0 ? 'anverso' : 'reverso') : 'foto';

    console('📤 Subiendo ${index + 1}/$cantidadRequerida:');
    console('   - codEmpleado: ${widget.codEmpleado}');
    console('   - tipoDocumento: $tipoDocumentoBackend');
    console('   - lado: $lado');

    try {
      final result = await ref.read(
        subirFotoDocProvider((
          widget.codEmpleado,
          tipoDocumentoBackend,
          bytes,
          lado,
        )).future,
      );

      if (!result) {
        console('❌ Fallo subiendo foto $lado');
        throw Exception('La subida no fue exitosa');
      }

      console('✅ Foto $lado subida correctamente');

      try {
        final repo = FichaTrabajadorImpl();
        final nombreArchivo = '${widget.codEmpleado}_${tipoKey}_$lado.jpg';

        await repo.aprobarDocumentoPendiente({
          'codEmpleado': widget.codEmpleado,
          'tipoDocumento': tipoDocumentoBackend,
          'nombreArchivo': nombreArchivo,
        });

        console('✅ Foto $lado aprobada automáticamente');
      } catch (e) {
        console('⚠️  Foto subida pero no se pudo aprobar: $e');
      }
    } catch (e) {
      console('❌ Error en subida $lado: $e');
      rethrow;
    }
  }

  Future<void> _subirFotosDelTipo(String tipoKey) async {
    final fotos = _fotosEnEdicion[tipoKey] ?? [];

    if (fotos.any((img) => img == null)) {
      console('❌ No todas las imágenes están seleccionadas');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se requieren ${fotos.length} foto(s)'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      bool huboError = false;
      int fotosSubidas = 0;

      for (int i = 0; i < fotos.length; i++) {
        final imagen = fotos[i];
        if (imagen != null) {
          try {
            await _subirFoto(tipoKey, imagen, i);
            fotosSubidas++;
          } catch (e) {
            console('❌ Error subiendo foto $i: $e');
            huboError = true;
          }
        }
      }

      if (!mounted) return;

      if (huboError && fotosSubidas == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al subir documentos. Intente nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        console('✅ Todas las fotos subidas correctamente');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documentos subidos correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(todosLosDocumentosProvider(widget.codEmpleado));
        _salirModoEdicion(tipoKey);
      }
    } catch (e) {
      console('❌ Error general: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _eliminarFoto(String tipoKey, int index) {
    setState(() {
      if (_fotosEnEdicion[tipoKey] != null) {
        _fotosEnEdicion[tipoKey]![index] = null;
      }
    });
  }

  void _mostrarConfirmacionEliminar(String tipoKey, String nombreArchivo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar documento'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar este documento?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _eliminarDocumento(tipoKey, nombreArchivo);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  Future<void> _eliminarDocumento(String tipoKey, String nombreArchivo) async {
    if (!mounted) return;

    await executeABM(
      ref: ref,
      context: context,
      requireConfirmation: false,
      operation: () async {
        setState(() => _isDeleting = true);
        try {
          console('🗑️  Eliminando documento:');
          console('   - codEmpleado: ${widget.codEmpleado}');
          console('   - tipoDocumento: $tipoKey');
          console('   - nombreArchivo: $nombreArchivo');

          final resultado = await ref.read(
            eliminarFotoProvider((
              widget.codEmpleado,
              tipoKey,
              nombreArchivo,
            )).future,
          );

          if (!resultado) {
            throw CustomError('No se pudo eliminar el documento');
          }

          console('✅ Documento eliminado correctamente');
        } finally {
          if (mounted) setState(() => _isDeleting = false);
        }
      },
      providersToInvalidate: [todosLosDocumentosProvider(widget.codEmpleado)],
      successMessage: 'Documento eliminado correctamente',
    );
  }

  @override
  Widget build(BuildContext context) {
    console(
      '📋 Observando provider: todosLosDocumentosProvider(${widget.codEmpleado})',
    );
    final docsAsync = ref.watch(todosLosDocumentosProvider(widget.codEmpleado));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.document_scanner,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Documentos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed:
                        (_isUploading || _isDeleting)
                            ? null
                            : () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Contenido
            Expanded(
              child: docsAsync.when(
                loading: () {
                  console('⏳ Cargando documentos...');
                  return const Center(child: CircularProgressIndicator());
                },
                error: (err, stack) {
                  console('❌ Error cargando documentos: $err');
                  return Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
                data: (documentos) {
                  console('✅ Documentos cargados: ${documentos.keys.toList()}');
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...tiposDocumentos.entries.map((entry) {
                          final tipoKey = entry.key;
                          final (tipoDisplay, cantidad) = entry.value;
                          final archivos = documentos[tipoKey] ?? [];
                          final enEdicion = _tiposEnEdicion.contains(tipoKey);

                          return _buildTipoDocumentoCard(
                            tipoKey,
                            tipoDisplay,
                            cantidad,
                            archivos,
                            enEdicion,
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoDocumentoCard(
    String tipoKey,
    String tipoDisplay,
    int cantidadRequerida,
    List<String> archivos,
    bool enEdicion,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: enEdicion ? Colors.blue.shade300 : Colors.grey.shade300,
          width: enEdicion ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _getIconForDocType(tipoKey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tipoDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${archivos.length}/$cantidadRequerida',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Galería de archivos existentes
            if (archivos.isNotEmpty && !enEdicion)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: archivos.length,
                itemBuilder: (context, index) {
                  final nombreArchivo = archivos[index];
                  final url =
                      '${AppConstants.baseUrl}${AppConstants.getDocImageUrl}${widget.codEmpleado}/$tipoKey/$nombreArchivo?ts=${DateTime.now().millisecondsSinceEpoch}';
                  final lado =
                      cantidadRequerida == 2
                          ? (index == 0 ? 'Anverso' : 'Reverso')
                          : 'Documento';

                  return _buildThumbnail(url, lado, tipoKey, nombreArchivo);
                },
              )
            else if (archivos.isEmpty && !enEdicion)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin documentos',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            // Slots de edición
            if (enEdicion) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cantidadRequerida == 2
                            ? 'Toma 2 fotos: Anverso y Reverso'
                            : 'Toma 1 foto del documento',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cantidadRequerida,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final imagen = _fotosEnEdicion[tipoKey]?[index];
                  final lado =
                      cantidadRequerida == 2
                          ? (index == 0 ? 'Anverso' : 'Reverso')
                          : 'Foto';

                  return _buildFotoSlot(tipoKey, index, lado, imagen);
                },
              ),
            ],
            const SizedBox(height: 12),
            // Botones
            if (!enEdicion)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Agregar'),
                  onPressed:
                      () => _entrarModoEdicion(tipoKey, cantidadRequerida),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        archivos.isNotEmpty ? Colors.green : Colors.blue,
                  ),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final fotosSeleccionadas =
                      _fotosEnEdicion[tipoKey]
                          ?.where((img) => img != null)
                          .length ??
                      0;
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon:
                              _isUploading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Icon(Icons.cloud_upload),
                          label: Text(_isUploading ? 'Subiendo...' : 'Subir'),
                          onPressed:
                              _isUploading ||
                                      fotosSeleccionadas < cantidadRequerida
                                  ? null
                                  : () => _subirFotosDelTipo(tipoKey),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                          onPressed:
                              _isUploading
                                  ? null
                                  : () => _salirModoEdicion(tipoKey),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    String url,
    String lado,
    String tipoKey,
    String nombreArchivo,
  ) {
    return GestureDetector(
      onTap: () => _mostrarImagenCompleta(url),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
            // Label en la parte inferior
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(7),
                    bottomRight: Radius.circular(7),
                  ),
                ),
                child: Text(
                  lado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Botón eliminar en la esquina superior derecha
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap:
                    _isDeleting
                        ? null
                        : () => _mostrarConfirmacionEliminar(
                          tipoKey,
                          nombreArchivo,
                        ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarImagenCompleta(String url) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: 450,
              height: 550,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey.shade400,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
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

  Widget _buildFotoSlot(String tipoKey, int index, String lado, XFile? imagen) {
    return Column(
      children: [
        if (imagen != null)
          FutureBuilder<Uint8List>(
            future: imagen.readAsBytes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return GestureDetector(
                  onTap: () => _mostrarImagenPreview(snapshot.data!),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.shade300,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.9),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(7),
                              bottomRight: Radius.circular(7),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lado,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap:
                                    _isUploading
                                        ? null
                                        : () => _eliminarFoto(tipoKey, index),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
            },
          )
        else
          GestureDetector(
            onTap: _isUploading ? null : () => _seleccionarFoto(tipoKey, index),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'Tomar $lado',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap para capturar',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _mostrarImagenPreview(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: 450,
              height: 550,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.memory(imageBytes, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
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

  Icon _getIconForDocType(String tipoKey) {
    switch (tipoKey) {
      case 'carnet':
        return Icon(Icons.badge, size: 20, color: Colors.blue.shade700);
      case 'licencia':
        return Icon(Icons.card_giftcard, size: 20, color: Colors.blue.shade700);
      case 'pasaporte':
        return Icon(
          Icons.travel_explore,
          size: 20,
          color: Colors.blue.shade700,
        );
      default:
        return Icon(
          Icons.document_scanner,
          size: 20,
          color: Colors.blue.shade700,
        );
    }
  }
}
