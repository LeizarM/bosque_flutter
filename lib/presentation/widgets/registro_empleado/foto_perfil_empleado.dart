import 'dart:typed_data';
import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/empleados_dependientes_provider.dart';
import 'package:bosque_flutter/core/state/registro_empleado_provider.dart';
import 'package:bosque_flutter/core/utils/abm_service.dart';
import 'package:bosque_flutter/data/repositories/ficha_trabajador_impl.dart';
import 'package:bosque_flutter/presentation/widgets/registro_empleado/responsive_utils_registro_empleado.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class SeccionFotoEmpleado extends ConsumerStatefulWidget {
  final int codEmpleado;
  final bool autoApprove;
  final VoidCallback? onUploadSuccess;
  final VoidCallback? onDeleteSuccess;

  const SeccionFotoEmpleado({
    Key? key,
    required this.codEmpleado,
    this.autoApprove = false,
    this.onUploadSuccess,
    this.onDeleteSuccess,
  }) : super(key: key);

  @override
  ConsumerState<SeccionFotoEmpleado> createState() =>
      _SeccionFotoEmpleadoState();
}

class _SeccionFotoEmpleadoState extends ConsumerState<SeccionFotoEmpleado> {
  Uint8List? _imageBytes;
  bool _isUploading = false;
  bool _isDeleting = false;

  String _buildImageUrl(int codEmpleado, int imageVersion) =>
      '${AppConstants.baseUrl}${AppConstants.getImageUrl}/$codEmpleado.jpg?v=$imageVersion';

  // ============================================================================
  // IMAGE PICKER
  // ============================================================================

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (e) {
      showErrorMessage(context, 'Error al seleccionar imagen: $e');
    }
  }

  // ============================================================================
  // UPLOAD & DELETE
  // ============================================================================

  Future<void> _uploadImage() async {
    if (_imageBytes == null) {
      showErrorMessage(context, 'Seleccione una imagen primero');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final success = await ref.read(
          subirFotoProvider((widget.codEmpleado, _imageBytes!)).future);

      if (!success) {
        showErrorMessage(context, 'Error al subir la imagen');
        return;
      }

      try {
        final repo = FichaTrabajadorImpl();
        await repo.aprobarDocumentoPendiente({
          'codEmpleado': widget.codEmpleado,
          'tipoDocumento': 'foto_perfil',
          'nombreArchivo': '${widget.codEmpleado}.jpg',
        });

        ref.read(imageVersionProvider.notifier).state++;
        showSuccessMessage(context, 'Foto de perfil subida correctamente');
        widget.onUploadSuccess?.call();
        if (mounted) setState(() => _imageBytes = null);
      } catch (e) {
        showErrorMessage(context, 'Subida OK, fallo al aprobar: $e');
        widget.onUploadSuccess?.call();
      }
    } catch (e) {
      showErrorMessage(context, 'Error al subir imagen: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage() async {
    if (!mounted) return;

    await executeABM(
      ref: ref,
      context: context,
      requireConfirmation: true,
      confirmationTitle: 'Eliminar foto de perfil',
      confirmationMessage:
          '¿Deseas eliminar la foto de perfil? Esta acción no se puede deshacer.',
      confirmButtonText: 'Eliminar',
      confirmButtonColor: Colors.red,
      operation: () async {
        setState(() => _isDeleting = true);
        try {
          final resultado = await ref.read(
            eliminarFotoProvider((
              widget.codEmpleado,
              'foto_perfil',
              '${widget.codEmpleado}.jpg',
            )).future,
          );

          if (!resultado) {
            throw CustomError('No se pudo eliminar la imagen');
          }

          ref.read(imageVersionProvider.notifier).state++;
          widget.onDeleteSuccess?.call();
        } finally {
          if (mounted) setState(() => _isDeleting = false);
        }
      },
      providersToInvalidate: [],
      successMessage: 'Foto de perfil eliminada correctamente',
    );
  }

  void _cancelPreview() => setState(() => _imageBytes = null);

  void _showFullImage(String url, Uint8List? bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: Hero(
            tag: 'empleado-imagen-${widget.codEmpleado}',
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.contain)
                : Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageVersion = ref.watch(imageVersionProvider);
    final imageUrl = _buildImageUrl(widget.codEmpleado, imageVersion);

    return Column(
      children: [
        // Header con título y menú
        _buildHeader(context),
        SizedBox(height: context.spacing),
        // Imagen o preview
        _imageBytes != null
            ? _buildImagePreview(context, imageUrl)
            : _buildImageDisplay(context, imageUrl),
        SizedBox(height: context.spacing),
        // Acciones
        _imageBytes != null
            ? _buildPreviewActions(context)
            : _buildDefaultActions(context),
      ],
    );
  }

  // ============================================================================
  // HEADER CON MENÚ DROPDOWN
  // ============================================================================

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Foto de Perfil',
          style: context.subtitleStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: context.smallIconSize,
          ),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'gallery',
              child: Row(
                children: [
                  Icon(Icons.photo_library, size: context.smallIconSize),
                  SizedBox(width: context.smallSpacing),
                  const Text('Seleccionar'),
                ],
              ),
            ),
            if (context.isMobile)
              PopupMenuItem<String>(
                value: 'camera',
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, size: context.smallIconSize),
                    SizedBox(width: context.smallSpacing),
                    const Text('Tomar foto'),
                  ],
                ),
              ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline,
                      size: context.smallIconSize, color: Colors.red),
                  SizedBox(width: context.smallSpacing),
                  const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (String value) {
            switch (value) {
              case 'gallery':
                _pick(ImageSource.gallery);
                break;
              case 'camera':
                _pick(ImageSource.camera);
                break;
              case 'delete':
                _deleteImage();
                break;
            }
          },
        ),
      ],
    );
  }

  // ============================================================================
  // IMAGEN DISPLAY (SIN PREVIEW)
  // ============================================================================

  Widget _buildImageDisplay(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullImage(imageUrl, null),
      child: Hero(
        tag: 'empleado-imagen-${widget.codEmpleado}',
        child: Container(
          constraints: BoxConstraints(
            maxHeight: context.isMobile ? 200 : 280,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: context.spacing * 2,
                offset: Offset(0, context.smallSpacing),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: context.isMobile ? 100 : 140,
            backgroundImage: NetworkImage(imageUrl),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // IMAGEN PREVIEW (CON PREVIEW)
  // ============================================================================

  Widget _buildImagePreview(BuildContext context, String imageUrl) {
    return GestureDetector(
      onTap: () => _showFullImage(imageUrl, _imageBytes),
      child: Hero(
        tag: 'empleado-imagen-${widget.codEmpleado}',
        child: Container(
          constraints: BoxConstraints(
            maxHeight: context.isMobile ? 200 : 280,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.2),
                blurRadius: context.spacing * 2,
                offset: Offset(0, context.smallSpacing),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              width: context.isMobile ? 200 : 280,
              height: context.isMobile ? 200 : 280,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // ACCIONES - PREVIEW (GUARDAR/CANCELAR)
  // ============================================================================

  Widget _buildPreviewActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _uploadImage,
          icon: _isUploading
              ? SizedBox(
                  width: context.smallIconSize,
                  height: context.smallIconSize,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.check, size: context.smallIconSize),
          label: const Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
          ),
        ),
        SizedBox(width: context.spacing),
        OutlinedButton.icon(
          onPressed: _isUploading ? null : _cancelPreview,
          icon: Icon(Icons.close, size: context.smallIconSize),
          label: const Text('Cancelar'),
        ),
      ],
    );
  }

  // ============================================================================
  // ACCIONES - DEFAULT (MENÚ EN HEADER)
  // ============================================================================

  Widget _buildDefaultActions(BuildContext context) {
    // Las acciones están en el menú dropdown del header
    return SizedBox.shrink();
  }
}