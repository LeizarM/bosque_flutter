import 'package:flutter/material.dart';

class ObservacionesDialog extends StatefulWidget {
  final String direccion;

  const ObservacionesDialog({
    super.key,
    required this.direccion,
  });

  @override
  State<ObservacionesDialog> createState() => _ObservacionesDialogState();
}

class _ObservacionesDialogState extends State<ObservacionesDialog> {
  late TextEditingController _observacionesController;

  @override
  void initState() {
    super.initState();
    _observacionesController = TextEditingController();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      title: Text(
        'Confirmar entrega',
        style: TextStyle(color: colorScheme.primary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mensaje informativo sobre la ubicación automática
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Información de ubicación',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La ubicación se obtendrá automáticamente de su dispositivo para registrar la entrega.',
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              'Observaciones (opcional):',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _observacionesController,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                hintText: 'Detalles adicionales sobre la entrega',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colorScheme.primary),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            // Devolver solo las observaciones, la dirección se obtendrá automáticamente
            Navigator.of(context).pop({
              'observaciones': _observacionesController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Confirmar entrega'),
        ),
      ],
    );
  }
}