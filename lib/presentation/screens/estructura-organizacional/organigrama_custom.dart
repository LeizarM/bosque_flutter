import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class OrganigramaCustom extends StatefulWidget {
  final List<CargoEntity> cargos;
  final Function(CargoEntity) onNodeTap;

  const OrganigramaCustom({
    super.key,
    required this.cargos,
    required this.onNodeTap,
  });

  @override
  State<OrganigramaCustom> createState() => _OrganigramaCustomState();
}

class _OrganigramaCustomState extends State<OrganigramaCustom> {
  final Graph graph = Graph()..isTree = true;
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  final TransformationController _transformationController =
      TransformationController();
  Map<int, Node> nodeMap = {};
  Map<int, CargoEntity> cargoMap = {};

  @override
  void initState() {
    super.initState();
    builder
      ..siblingSeparation = 80
      ..levelSeparation = 120
      ..subtreeSeparation = 80
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  @override
  void didUpdateWidget(OrganigramaCustom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cargos != widget.cargos) {
      _buildGraph();
    }
  }

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();
    nodeMap.clear();
    cargoMap.clear();

    final todosLosCargos = <CargoEntity>[];
    void aplanarCargos(List<CargoEntity> cargos) {
      for (var cargo in cargos) {
        todosLosCargos.add(cargo);
        if (cargo.items.isNotEmpty) {
          aplanarCargos(cargo.items);
        }
      }
    }

    aplanarCargos(widget.cargos);

    for (var cargo in todosLosCargos) {
      final node = Node.Id(cargo.codCargo);
      nodeMap[cargo.codCargo] = node;
      cargoMap[cargo.codCargo] = cargo;
      graph.addNode(node);
    }

    for (var cargo in todosLosCargos) {
      if (cargo.codCargoPadre == 0) continue;

      final nodeChild = nodeMap[cargo.codCargo];
      final nodeParent = nodeMap[cargo.codCargoPadre];

      if (nodeChild != null && nodeParent != null) {
        graph.addEdge(nodeParent, nodeChild);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cargos.isEmpty) {
      return const Center(child: Text('No hay cargos para mostrar'));
    }

    _buildGraph();

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.1,
      maxScale: 5.0,
      transformationController: _transformationController,
      child: GraphView(
        graph: graph,
        algorithm: BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
        paint:
            Paint()
              ..color = Colors.grey.shade400
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final codCargo = node.key!.value as int;
          final cargo = cargoMap[codCargo];
          if (cargo == null) return const SizedBox.shrink();
          return _buildNodeWidget(cargo);
        },
      ),
    );
  }

  Widget _buildNodeWidget(CargoEntity cargo) {
    final isInactive = cargo.estado == 0;
    final isFicticio = cargo.codCargo < 0;

    Color backgroundColor;
    Color borderColor;

    if (isFicticio) {
      backgroundColor = Colors.grey.shade300;
      borderColor = Colors.orange.shade700;
    } else if (isInactive) {
      backgroundColor = Colors.red.shade100;
      borderColor = Colors.red;
    } else {
      backgroundColor = _getNodeColor(cargo);
      borderColor = Colors.grey.shade300;
    }

    return InkWell(
      onTap: () => widget.onNodeTap(cargo),
      child: Container(
        width: 180,
        height: 95,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isFicticio ? 3 : (isInactive ? 2 : 1),
            style: isFicticio ? BorderStyle.solid : BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isFicticio ? 0.2 : 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isFicticio)
              Icon(
                Icons.report_problem_outlined,
                color: Colors.orange.shade700,
                size: 16,
              ),
            Text(
              cargo.descripcion,
              style: TextStyle(
                fontSize: isFicticio ? 10 : 11,
                fontWeight: isFicticio ? FontWeight.normal : FontWeight.bold,
                color:
                    isFicticio
                        ? Colors.orange.shade900
                        : (isInactive ? Colors.red.shade900 : Colors.black87),
                fontStyle: isFicticio ? FontStyle.italic : FontStyle.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Nivel: ${cargo.nivel} | Pos: ${cargo.posicion}',
              style: TextStyle(
                fontSize: 9,
                color:
                    isFicticio ? Colors.orange.shade700 : Colors.grey.shade600,
                fontWeight: isFicticio ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (cargo.tieneEmpleadosActivos > 0)
              Text(
                '👤 ${cargo.tieneEmpleadosActivos}',
                style: const TextStyle(fontSize: 9),
              ),
            if (isFicticio)
              Text(
                'FICTICIO',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNodeColor(CargoEntity cargo) {
    if (cargo.codCargo >= 130 && cargo.codCargo <= 175) {
      final Map<int, Color> coloresPrincipales = {
        130: Colors.red.shade700,
        131: Colors.blue.shade700,
        132: Colors.green.shade700,
        133: Colors.purple.shade700,
        134: Colors.orange.shade700,
      };
      if (coloresPrincipales.containsKey(cargo.codCargo)) {
        return coloresPrincipales[cargo.codCargo]!;
      }
    }

    final colores = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
    ];
    return colores[cargo.codCargo % colores.length];
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
