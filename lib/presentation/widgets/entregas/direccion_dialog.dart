import 'package:flutter/material.dart';

class DireccionDialog extends StatefulWidget {
  final String direccionInicial;

  const DireccionDialog({
    Key? key,
    required this.direccionInicial,
  }) : super(key: key);

  @override
  State<DireccionDialog> createState() => _DireccionDialogState();
}

class _DireccionDialogState extends State<DireccionDialog> {
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
            Text(
              'Dirección de entrega: ${widget.direccionInicial}',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface, fontWeight: FontWeight.bold),
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
            // Devolver un mapa con la dirección original y las observaciones
            Navigator.of(context).pop({
              'direccion': widget.direccionInicial,
              'observaciones': _observacionesController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}