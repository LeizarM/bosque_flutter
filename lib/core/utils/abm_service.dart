// lib/core/utils/abm_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =============================================================================
// NUEVO: Clase CustomError
// Se agrega aquí para que los repositorios puedan usarla importando este archivo.
// Esto permite que el mensaje llegue "limpio" desde el origen.
// =============================================================================
class CustomError implements Exception {
  final String message;
  CustomError(this.message);

  @override
  String toString() => message;
}

/// Servicio unificado para operaciones CRUD (ABM: Alta, Baja, Modificación)
Future<bool> executeABM({
  required WidgetRef ref,
  required BuildContext context,
  required Future<void> Function() operation,
  required List<ProviderOrFamily> providersToInvalidate,
  required String successMessage,
  bool requireConfirmation = false,
  String confirmationTitle = 'Confirmar Operación',
  String confirmationMessage =
      '¿Está seguro de realizar esta operación? Esta acción no se puede deshacer.',
  String cancelButtonText = 'Cancelar',
  String confirmButtonText = 'Aceptar',
  Color confirmButtonColor = Colors.red,
}) async {
  if (!context.mounted) return false;

  // PASO 1: Mostrar confirmación (SIN CAMBIOS)
  if (requireConfirmation) {
    final confirmed = await _showConfirmationDialog(
      context: context,
      title: confirmationTitle,
      message: confirmationMessage,
      cancelButtonText: cancelButtonText,
      confirmButtonText: confirmButtonText,
      confirmButtonColor: confirmButtonColor,
    );

    if (!confirmed) return false;
  }


  try {
    await operation();


    for (final provider in providersToInvalidate) {
      ref.invalidate(provider);
    }


    if (!context.mounted) return true;
    showSuccessMessage(context, successMessage);
    return true;
  } catch (e) {

    if (!context.mounted) return false;
    showErrorMessage(context, e);
    return false;
  }
}


Future<bool> _showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelButtonText,
  required String confirmButtonText,
  required Color confirmButtonColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelButtonText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: confirmButtonColor),
          child: Text(
            confirmButtonText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );

  return result ?? false;
}


void showSuccessMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// =============================================================================
// CAMBIO IMPORTANTE: _showErrorMessage
// Ahora es más inteligente. No solo "limpia" texto, sino que reconoce tipos.
// =============================================================================
void showErrorMessage(BuildContext context, dynamic error) {
  if (!context.mounted) return;

  String errorMessage = 'Error inesperado. Intente de nuevo.';

  if (error is CustomError) {
    // Si el error es de nuestra nueva clase, el mensaje ya está limpio.
    errorMessage = error.message;
  } else if (error is Exception) {
    // Si es una Exception genérica, limpiamos el prefijo.
    // Usamos replaceFirst en lugar de split para evitar romper mensajes complejos.
    errorMessage = error.toString().replaceFirst('Exception: ', '');
  } else if (error is String) {
    errorMessage = error;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(errorMessage)),
        ],
      ),
      backgroundColor: Colors.red.shade800,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4), // Un poco más de tiempo para leer errores largos
    ),
  );
}