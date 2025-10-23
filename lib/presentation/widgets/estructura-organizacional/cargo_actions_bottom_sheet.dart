import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';

/// Bottom sheet con las acciones disponibles para un cargo
class CargoActionsBottomSheet extends StatelessWidget {
  final CargoEntity cargo;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;

  const CargoActionsBottomSheet({
    super.key,
    required this.cargo,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.work_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cargo.descripcion,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 24),

          // Ver detalles
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Ver detalles'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onViewDetails,
          ),

          const Divider(height: 8),

          // Editar cargo (DESTACADO - Opción principal)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.edit,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              title: Text(
                'Editar Cargo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              subtitle: const Text(
                'Estado, posición y reparentar en un solo formulario',
                style: TextStyle(fontSize: 11),
              ),
              trailing: Icon(
                Icons.arrow_forward,
                color: Theme.of(context).primaryColor,
              ),
              onTap: onEdit,
            ),
          ),

          const Divider(height: 8),

          // Duplicar cargo
          ListTile(
            leading: const Icon(Icons.content_copy, color: Colors.blue),
            title: const Text('Duplicar cargo'),
            subtitle: const Text(
              'Crear nuevo cargo con las mismas configuraciones',
              style: TextStyle(fontSize: 11),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: onDuplicate,
          ),
        ],
      ),
    );
  }
}
