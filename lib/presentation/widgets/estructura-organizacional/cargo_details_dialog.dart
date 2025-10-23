import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';

/// Diálogo que muestra los detalles de un cargo
class CargoDetailsDialog extends StatelessWidget {
  final CargoEntity cargo;

  const CargoDetailsDialog({super.key, required this.cargo});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.work, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(cargo.descripcion)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Código', cargo.codCargo.toString()),
            _buildDetailRow('Código Cargo', cargo.codCargo.toString()),
            _buildDetailRow('Nivel', cargo.nivel.toString()),
            _buildDetailRow('Posición', cargo.posicion.toString()),
            _buildDetailRow('Código Nivel', cargo.codNivel.toString()),
            _buildDetailRow(
              'Código Padre',
              cargo.codCargoPadre == 0
                  ? 'Ninguno (Raíz)'
                  : cargo.codCargoPadre.toString(),
            ),
            _buildDetailRow(
              'Código Padre Original',
              cargo.codCargoPadreOriginal == 0
                  ? 'Ninguno (Raíz)'
                  : cargo.codCargoPadreOriginal.toString(),
            ),
            _buildDetailRow(
              'Estado',
              cargo.estado == 1 ? 'Activo' : 'Inactivo',
            ),
            _buildDetailRow(
              'Empleados Activos',
              cargo.tieneEmpleadosActivos.toString(),
            ),
            _buildDetailRow(
              'Subordinados Activos',
              cargo.numHijosActivos.toString(),
            ),
            _buildDetailRow(
              'Puede Desactivar',
              cargo.canDeactivate == 1 ? 'Sí' : 'No',
            ),
            _buildDetailRow(
              'Visible',
              cargo.esVisible == 1 ? 'Sí' : 'No (Ficticio)',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
