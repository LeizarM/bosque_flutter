import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';

/// Vista de lista que muestra los cargos en forma de árbol jerárquico
class CargosTreeListView extends StatelessWidget {
  final List<CargoEntity> cargos;
  final Function(CargoEntity) onCargoTap;

  const CargosTreeListView({
    super.key,
    required this.cargos,
    required this.onCargoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cargos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay cargos para mostrar'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _buildTreeNodes(cargos, 0),
    );
  }

  /// Construir nodos del árbol recursivamente
  List<Widget> _buildTreeNodes(List<CargoEntity> cargos, int nivel) {
    List<Widget> widgets = [];

    for (var cargo in cargos) {
      // Saltar nodos ficticios (esVisible == 0)
      if (cargo.esVisible == 0) {
        // Pero procesamos sus hijos
        if (cargo.items.isNotEmpty) {
          widgets.addAll(_buildTreeNodes(cargo.items, nivel));
        }
        continue;
      }

      final isInactive = cargo.estado == 0;

      // Agregar el nodo actual (visible)
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: nivel * 20.0),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: isInactive ? Colors.grey.shade100 : null,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isInactive
                        ? Colors.grey.shade400
                        : _getColorByLevel(cargo.nivel),
                child: Icon(
                  _getStatusIcon(cargo),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                cargo.descripcion,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isInactive ? TextDecoration.lineThrough : null,
                  color: isInactive ? Colors.grey.shade600 : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel: ${cargo.nivel} | Pos: ${cargo.posicion}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isInactive ? Colors.grey.shade500 : null,
                    ),
                  ),
                  if (cargo.tieneEmpleadosActivos > 0)
                    Text(
                      '👤 ${cargo.tieneEmpleadosActivos} empleado(s)',
                      style: const TextStyle(fontSize: 10),
                    ),
                  if (isInactive)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        'INACTIVO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Icon(
                cargo.items.isNotEmpty
                    ? Icons.arrow_forward_ios
                    : Icons.more_vert,
                size: 16,
              ),
              onTap: () => onCargoTap(cargo),
            ),
          ),
        ),
      );

      // Agregar hijos recursivamente
      if (cargo.items.isNotEmpty) {
        widgets.addAll(_buildTreeNodes(cargo.items, nivel + 1));
      }
    }

    return widgets;
  }

  IconData _getStatusIcon(CargoEntity cargo) {
    if (cargo.tieneEmpleadosActivos > 0) {
      return Icons.person;
    } else if (cargo.numHijosActivos > 0) {
      return Icons.account_tree;
    } else {
      return Icons.work_outline;
    }
  }

  Color _getColorByLevel(int nivel) {
    final coloresPorNivel = [
      Colors.red.shade300,
      Colors.orange.shade300,
      Colors.amber.shade300,
      Colors.yellow.shade300,
      Colors.lime.shade300,
      Colors.lightGreen.shade300,
      Colors.green.shade300,
      Colors.teal.shade300,
      Colors.cyan.shade300,
      Colors.lightBlue.shade300,
      Colors.blue.shade300,
      Colors.indigo.shade300,
      Colors.purple.shade300,
      Colors.deepPurple.shade300,
      Colors.pink.shade300,
      Colors.blueGrey.shade300,
    ];

    return coloresPorNivel[nivel % coloresPorNivel.length];
  }
}
