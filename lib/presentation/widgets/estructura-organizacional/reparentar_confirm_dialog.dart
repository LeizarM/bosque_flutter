import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';

/// Diálogo de confirmación para reparentar un cargo
class ReparentarConfirmDialog extends StatelessWidget {
  final CargoEntity cargo;
  final CargoEntity nuevoPadre;
  final VoidCallback onConfirm;

  const ReparentarConfirmDialog({
    super.key,
    required this.cargo,
    required this.nuevoPadre,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final tieneDependencias =
        cargo.tieneEmpleadosActivos > 0 || cargo.numHijosActivos > 0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: tieneDependencias ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 8),
          const Expanded(child: Text('Confirmar Reparentar')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            fontSize: 14,
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
                    if (cargo.tieneEmpleadosActivos > 0)
                      Text(
                        '• ${cargo.tieneEmpleadosActivos} empleado(s) activo(s)',
                        style: const TextStyle(fontSize: 11),
                      ),
                    if (cargo.numHijosActivos > 0)
                      Text(
                        '• ${cargo.numHijosActivos} cargo(s) subordinado(s)',
                        style: const TextStyle(fontSize: 11),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Al reparentar, estos elementos también se verán afectados en la jerarquía.',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Info del cambio
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
                    'Cambio a realizar:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _buildChangeRow('Cargo:', cargo.descripcion),
                  const SizedBox(height: 8),
                  _buildChangeRow('Padre actual:', cargo.estadoPadre),
                  const Divider(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'NUEVO PADRE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildChangeRow('Nuevo padre:', nuevoPadre.descripcion),
                  _buildChangeRow(
                    'Nivel del nuevo padre:',
                    nuevoPadre.nivel.toString(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nota adicional
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta acción reorganizará la jerarquía. Verifica que sea correcto antes de confirmar.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
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
            Navigator.of(context).pop();
            onConfirm();
          },
          icon: const Icon(Icons.check),
          label: const Text('Confirmar Reparentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: tieneDependencias ? Colors.orange : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildChangeRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
