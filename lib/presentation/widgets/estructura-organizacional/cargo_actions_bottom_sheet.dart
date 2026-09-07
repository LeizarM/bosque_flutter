import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';

/// Bottom sheet con las acciones disponibles para un cargo
class CargoActionsBottomSheet extends StatelessWidget {
  final CargoEntity cargo;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onAddChild; // 🆕 Agregar hijo
  final VoidCallback onTareasRutinarias;

  const CargoActionsBottomSheet({
    super.key,
    required this.cargo,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDuplicate,
    required this.onAddChild,
    required this.onTareasRutinarias,
  });

  @override
  Widget build(BuildContext context) {
    // Alto máximo explícito + SingleChildScrollView: con isScrollControlled
    // la hoja puede crecer hasta ocupar toda la pantalla, pero si el
    // contenido igual no entra (viewport bajo — browser achicado, celular
    // en horizontal, teclado abierto) necesita poder scrollear en vez de
    // desbordar. ClampingScrollPhysics: es una lista corta de acciones, no
    // hace falta el rebote de iOS acá.
    final altoDisponible = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: altoDisponible * 0.85),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cargo.descripcion,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      Theme.of(context).primaryColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
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

              // 🆕 Agregar cargo hijo
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.1),
                      Colors.green.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.add_circle,
                    color: Colors.green,
                    size: 28,
                  ),
                  title: const Text(
                    'Agregar Cargo Hijo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  subtitle: const Text(
                    'Crear nuevo cargo que dependerá de este',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward,
                    color: Colors.green,
                  ),
                  onTap: onAddChild,
                ),
              ),

              const Divider(height: 8),

              // Tareas rutinarias por cargo (reemplaza dlgTarFunXCargo del legacy)
              ListTile(
                leading: const Icon(
                  Icons.assignment_outlined,
                  color: Colors.deepPurple,
                ),
                title: const Text('Tareas rutinarias'),
                subtitle: const Text(
                  'Ver, agregar, copiar o editar las tareas asignadas a este cargo',
                  style: TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: onTareasRutinarias,
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
        ),
      ),
    );
  }
}
