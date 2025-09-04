import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;

  const ConfirmDialog({
    Key? key,
    this.title = 'Confirmar',
    this.content = '¿Está seguro?',
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.confirmColor,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    String title = 'Confirmar',
    String content = '¿Está seguro?',
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmText,
            style: TextStyle(color: confirmColor ?? Colors.red),
          ),
        ),
      ],
    );
  }
  // Agregar este nuevo método estático
  static Future<void> showConfirmDelete({
    required BuildContext context,
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
    Color confirmColor = Colors.red,
  }) async {
    final confirmed = await show(
      context,
      title: title,
      content: content,
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmColor: confirmColor,
    );

    if (confirmed == true && context.mounted) {
    try {
      await onConfirm();
      if (context.mounted) {
        AppSnackbarCustom.showDelete(context, 'Registro eliminado correctamente');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.showError(context, 'Error al eliminar el registro');
      }
    }
  }
  }

}
class AppSnackbar {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
enum SnackBarType { success, error, warning, info, add, edit, delete }
enum SnackBarPosition { top, bottom }

class AppSnackbarCustom {
  static OverlayEntry? _currentOverlay;
  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarPosition position = SnackBarPosition.top,
    bool showCloseIcon = false,
    VoidCallback? onClose,
  }) {
    final snackBar = SnackBar(
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getIcon(type),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (showCloseIcon)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (onClose != null) onClose();
              },
            ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: _getBackgroundColor(type),
      duration: duration,
      elevation: 6,
      margin: position == SnackBarPosition.top
          ? const EdgeInsets.only(top: 24, left: 40, right: 40)
          : const EdgeInsets.only(bottom: 24, left: 40, right: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      dismissDirection: DismissDirection.none,
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }
  static void showTop({
  required BuildContext context,
  required String message,
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 3),
  bool showCloseIcon = false,
  VoidCallback? onClose,
}) {
  _currentOverlay?.remove();

  final overlay = OverlayEntry(
    builder: (context) => Positioned(
      top: 40,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(type),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getIcon(type),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (showCloseIcon)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _currentOverlay?.remove();
                      _currentOverlay = null;
                      if (onClose != null) onClose();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context, rootOverlay: true).insert(overlay);
  _currentOverlay = overlay;

  if (!showCloseIcon) {
    Future.delayed(duration, () {
      _currentOverlay?.remove();
      _currentOverlay = null;
      if (onClose != null) onClose();
    });
  }
}

  static void showAdd(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: SnackBarType.add,
    );
  }

  static void showEdit(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: SnackBarType.edit,
    );
  }

  static void showDelete(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: SnackBarType.delete,
    );
  }

  // MÉTODOS QUE FALTABAN:
  static void showSuccess(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: SnackBarType.success,
    );
  }

  static void showError(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: SnackBarType.error,
    );
  }
  static void showWarning(BuildContext context, String message) {
    show(
      context: context,
      message: message,
      type: SnackBarType.warning,
      position: SnackBarPosition.bottom,

    );
  }

  static Icon _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const Icon(Icons.check_circle, color: Colors.white, size: 28);
      case SnackBarType.error:
        return const Icon(Icons.error, color: Colors.white, size: 28);
      case SnackBarType.warning:
        return const Icon(Icons.warning, color: Colors.white, size: 28);
      case SnackBarType.info:
        return const Icon(Icons.info, color: Colors.white, size: 28);
      case SnackBarType.add:
        return const Icon(Icons.add_circle, color: Colors.white, size: 28);
      case SnackBarType.edit:
        return const Icon(Icons.edit, color: Colors.white, size: 28);
      case SnackBarType.delete:
        return const Icon(Icons.delete_forever, color: Colors.white, size: 28);
    }
  }

  static Color _getBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Colors.green.shade800;
      case SnackBarType.error:
        return Colors.red.shade800;
      case SnackBarType.warning:
        return Colors.orange.shade800;
      case SnackBarType.info:
        return Colors.blue.shade800;
      case SnackBarType.add:
        return const Color(0xFF2E7D32); // Verde oscuro personalizado
      case SnackBarType.edit:
        return const Color(0xFF2E7D32); // Azul oscuro personalizado
      case SnackBarType.delete:
        return const Color(0xFFC62828); // Rojo oscuro personalizado
    }
  }
}