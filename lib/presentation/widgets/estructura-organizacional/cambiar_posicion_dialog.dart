import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';

/// Diálogo para cambiar la posición de un cargo
class CambiarPosicionDialog extends StatefulWidget {
  final CargoEntity cargo;
  final Function(int nuevaPosicion) onConfirm;

  const CambiarPosicionDialog({
    super.key,
    required this.cargo,
    required this.onConfirm,
  });

  @override
  State<CambiarPosicionDialog> createState() => _CambiarPosicionDialogState();
}

class _CambiarPosicionDialogState extends State<CambiarPosicionDialog> {
  late TextEditingController posicionController;
  bool tieneDependencias = false;

  @override
  void initState() {
    super.initState();
    posicionController = TextEditingController(
      text: widget.cargo.posicion.toString(),
    );
    tieneDependencias =
        widget.cargo.tieneEmpleadosActivos > 0 ||
        widget.cargo.numHijosActivos > 0;
  }

  @override
  void dispose() {
    posicionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.format_list_numbered),
          const SizedBox(width: 8),
          const Expanded(child: Text('Cambiar Posición')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info del cargo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cargo:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.cargo.descripcion,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posición actual: ${widget.cargo.posicion}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Advertencia si tiene dependencias
            if (tieneDependencias) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '¡Atención!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este cargo tiene dependencias:',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (widget.cargo.tieneEmpleadosActivos > 0)
                      Text(
                        '• ${widget.cargo.tieneEmpleadosActivos} empleado(s) activo(s)',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (widget.cargo.numHijosActivos > 0)
                      Text(
                        '• ${widget.cargo.numHijosActivos} cargo(s) subordinado(s)',
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Campo de nueva posición
            TextField(
              controller: posicionController,
              decoration: InputDecoration(
                labelText: 'Nueva posición',
                hintText: 'Ej: 1, 2, 3...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.format_list_numbered),
                helperText: 'La posición determina el orden de visualización',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Los cargos se ordenan por posición en el mismo nivel',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            final nuevaPosicion = int.tryParse(posicionController.text);
            if (nuevaPosicion == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor ingresa un número válido'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (nuevaPosicion == widget.cargo.posicion) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La posición es la misma que la actual'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            Navigator.of(context).pop();
            widget.onConfirm(nuevaPosicion);
          },
          icon: const Icon(Icons.check),
          label: const Text('Cambiar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: tieneDependencias ? Colors.orange : Colors.blue,
          ),
        ),
      ],
    );
  }
}
