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
    // Si esVisible == 0, hacer el nodo completamente transparente
    if (cargo.esVisible == 0) {
      return Container(width: 180, height: 95, color: Colors.transparent);
    }

    final isInactive = cargo.estado == 0;

    Color backgroundColor;
    Color borderColor;

    if (isInactive) {
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
          border: Border.all(color: borderColor, width: isInactive ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRect(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  cargo.descripcion,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isInactive ? Colors.red.shade900 : Colors.black87,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nivel: ${cargo.nivel} | Pos: ${cargo.posicion}',
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (cargo.tieneEmpleadosActivos > 0)
                Text(
                  '👤 ${cargo.tieneEmpleadosActivos}',
                  style: const TextStyle(fontSize: 9),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNodeColor(CargoEntity cargo) {
    // Paleta de colores variada para diferentes niveles jerárquicos
    final coloresPorNivel = [
      Colors.red.shade300, // Nivel 0
      Colors.orange.shade300, // Nivel 1
      Colors.amber.shade300, // Nivel 2
      Colors.yellow.shade300, // Nivel 3
      Colors.lime.shade300, // Nivel 4
      Colors.lightGreen.shade300, // Nivel 5
      Colors.green.shade300, // Nivel 6
      Colors.teal.shade300, // Nivel 7
      Colors.cyan.shade300, // Nivel 8
      Colors.lightBlue.shade300, // Nivel 9
      Colors.blue.shade300, // Nivel 10
      Colors.indigo.shade300, // Nivel 11
      Colors.purple.shade300, // Nivel 12
      Colors.deepPurple.shade300, // Nivel 13
      Colors.pink.shade300, // Nivel 14
      Colors.blueGrey.shade300, // Nivel 15
    ];

    // Usar el nivel para determinar el color (con ciclo para N niveles)
    return coloresPorNivel[cargo.nivel % coloresPorNivel.length];
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
