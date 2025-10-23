import 'package:flutter/material.dart';

/// Leyenda que explica los íconos del organigrama
class OrganigramaLegend extends StatelessWidget {
  const OrganigramaLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildLegendItem(Icons.person, 'Con empleados', Colors.blue),
          _buildLegendItem(
            Icons.account_tree,
            'Con subordinados',
            Colors.green,
          ),
          _buildLegendItem(Icons.work_outline, 'Sin asignaciones', Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
