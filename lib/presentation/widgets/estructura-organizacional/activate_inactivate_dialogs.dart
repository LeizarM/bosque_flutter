import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';

/// Diálogo de confirmación para activar un cargo
class ActivateCargoDialog extends StatelessWidget {
  final CargoEntity cargo;
  final VoidCallback onConfirm;

  const ActivateCargoDialog({
    super.key,
    required this.cargo,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          const Expanded(child: Text('Activar Cargo')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cargo a activar:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  cargo.descripcion,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Código: ${cargo.codCargo} | Nivel: ${cargo.nivel}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Al activar este cargo, estará disponible nuevamente en el organigrama y podrás asignarle empleados.',
            style: TextStyle(fontSize: 13),
          ),
        ],
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
          icon: const Icon(Icons.check_circle),
          label: const Text('Activar'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }
}

/// Diálogo de confirmación para desactivar un cargo
class InactivateCargoDialog extends StatelessWidget {
  final CargoEntity cargo;
  final VoidCallback onConfirm;

  const InactivateCargoDialog({
    super.key,
    required this.cargo,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final tieneEmpleados = cargo.tieneEmpleadosActivos > 0;
    final tieneSubordinados = cargo.numHijosActivos > 0;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: tieneSubordinados ? Colors.deepOrange : Colors.red,
          ),
          const SizedBox(width: 8),
          const Expanded(child: Text('Desactivar Cargo')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cargo a desactivar:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cargo.descripcion,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Código: ${cargo.codCargo} | Nivel: ${cargo.nivel}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Advertencia CRÍTICA si tiene subordinados
            if (tieneSubordinados) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.deepOrange.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error,
                          color: Colors.deepOrange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '¡ADVERTENCIA CRÍTICA!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Este cargo tiene ${cargo.numHijosActivos} cargo(s) subordinado(s) activos',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.deepOrange.shade200),
                      ),
                      child: const Text(
                        '⚠️ Los cargos subordinados quedarán HUÉRFANOS y deberán ser reasignados manualmente a un nuevo cargo padre.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Se recomienda reasignar primero los cargos subordinados antes de desactivar este cargo.',
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

            // Advertencia si tiene empleados
            if (tieneEmpleados) ...[
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
                          Icons.people,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Empleados asignados',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ${cargo.tieneEmpleadosActivos} empleado(s) activo(s) asignado(s) a este cargo',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Los empleados deberán ser reasignados a otro cargo.',
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

            // Mensaje general
            Text(
              'Al desactivar este cargo, ya no aparecerá en el organigrama activo pero se mantendrá en el historial.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
          icon: const Icon(Icons.block),
          label: Text(
            tieneSubordinados ? 'Desactivar de todas formas' : 'Desactivar',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: tieneSubordinados ? Colors.deepOrange : Colors.red,
          ),
        ),
      ],
    );
  }
}
