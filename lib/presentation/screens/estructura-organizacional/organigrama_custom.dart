import 'dart:typed_data';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphview/GraphView.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

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
  final GlobalKey _organigramaKey = GlobalKey();
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

  List<CargoEntity> _nodosHuerfanos = [];

  void _buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();
    nodeMap.clear();
    cargoMap.clear();
    _nodosHuerfanos.clear();

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

    // Crear nodos: OCULTAR solo cargos REALES inactivos
    // MOSTRAR: cargos activos + cargos ficticios (aunque estén inactivos)
    for (var cargo in todosLosCargos) {
      final esFicticio =
          cargo.descripcion.contains('[Ficticio') ||
          cargo.descripcion.toLowerCase().contains('ficticio');
      final esRealInactivo = !esFicticio && cargo.estado == 0;

      // Si es REAL Y está INACTIVO -> NO MOSTRAR
      if (!esRealInactivo) {
        final node = Node.Id(cargo.codCargo);
        nodeMap[cargo.codCargo] = node;
        cargoMap[cargo.codCargo] = cargo;
        graph.addNode(node);
      }
    }

    // Detectar TODAS las RAÍCES (codCargoPadre = 0) visibles en el grafo
    // Incluye: Reales activos Y Ficticios (aunque estén inactivos)
    final todasLasRaices =
        todosLosCargos.where((cargo) {
          return cargo.codCargoPadre == 0 &&
              nodeMap.containsKey(cargo.codCargo);
        }).toList();

    //  Si hay múltiples raíces, crear un NODO VIRTUAL como raíz común
    Node? nodoRaizVirtual;
    if (todasLasRaices.length > 1) {
      nodoRaizVirtual = Node.Id(-1); // ID virtual
      graph.addNode(nodoRaizVirtual);

      // Conectar TODAS las raíces al nodo virtual (reales y ficticias)
      for (var raiz in todasLasRaices) {
        final nodeRaiz = nodeMap[raiz.codCargo];
        if (nodeRaiz != null) {
          graph.addEdge(nodoRaizVirtual, nodeRaiz);
        }
      }
    }

    //  Crear edges: Los hijos de cargos inactivos quedan "huérfanos"
    for (var cargo in todosLosCargos) {
      // Si el cargo hijo no se muestra, saltarlo
      if (!nodeMap.containsKey(cargo.codCargo)) continue;

      // Si es una raíz real (codCargoPadre = 0), ya se manejó arriba
      if (cargo.codCargoPadre == 0) continue;

      final nodeChild = nodeMap[cargo.codCargo];
      final nodeParent = nodeMap[cargo.codCargoPadre];

      // Si el padre existe Y está visible, crear la conexión
      if (nodeChild != null && nodeParent != null) {
        graph.addEdge(nodeParent, nodeChild);
      } else if (nodeChild != null && nodeParent == null) {
        //  NODO HUÉRFANO: El padre no existe o está inactivo
        _nodosHuerfanos.add(cargo);
      }
    }
  }

  // Método para capturar el organigrama completo en alta calidad
  Future<void> exportarOrganigrama(BuildContext context) async {
    // Usar un contexto del diálogo directamente
    BuildContext? dialogContext;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx;
          return const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Generando imagen ...'),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Esperar un frame
      await Future.delayed(const Duration(milliseconds: 200));

      // Encontrar el RenderRepaintBoundary
      RenderRepaintBoundary boundary =
          _organigramaKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Capturar la imagen COMPLETA con ALTA CALIDAD (pixelRatio: 3.0 para mejor resolución)
      // Esto capturará TODO el contenido del RepaintBoundary, no solo lo visible
      ui.Image originalImage = await boundary.toImage(pixelRatio: 3.0);

      // Convertir directamente a PNG sin redimensionar (mantener calidad original)
      ByteData? byteData = await originalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Información del tamaño para el usuario
      final int ancho = originalImage.width;
      final int alto = originalImage.height;

      // Liberar recursos
      originalImage.dispose();

      // Cerrar loading
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      // Descargar el archivo (funciona en Web)
      if (kIsWeb) {
        final blob = html.Blob([pngBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.document.createElement('a') as html.AnchorElement
              ..href = url
              ..style.display = 'none'
              ..download =
                  'organigrama_${DateTime.now().millisecondsSinceEpoch}.png';
        html.document.body?.children.add(anchor);

        // Click para descargar
        anchor.click();

        // Limpiar después de un momento
        Future.delayed(const Duration(milliseconds: 500), () {
          html.document.body?.children.remove(anchor);
          html.Url.revokeObjectUrl(url);
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Organigrama exportado en alta calidad\nResolución: ${ancho}x${alto} pixels',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Para plataformas móviles/desktop (no implementado aún)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exportación solo disponible en versión Web'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cargos.isEmpty) {
      return const Center(child: Text('No hay cargos para mostrar'));
    }

    _buildGraph();

    return Row(
      children: [
        // Panel principal del organigrama
        Expanded(
          child: Stack(
            children: [
              // Organigrama visible con InteractiveViewer
              InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(200),
                minScale: 0.1,
                maxScale: 5.0,
                transformationController: _transformationController,
                child: Container(
                  color: Colors.white,
                  child: GraphView(
                    graph: graph,
                    algorithm: BuchheimWalkerAlgorithm(
                      builder,
                      TreeEdgeRenderer(builder),
                    ),
                    paint:
                        Paint()
                          ..color = Colors.grey.shade400
                          ..strokeWidth = 2
                          ..style = PaintingStyle.stroke,
                    builder: (Node node) {
                      final codCargo = node.key!.value as int;
                      // Si es el nodo virtual raíz, no mostrarlo
                      if (codCargo == -1) {
                        return Container(
                          width: 1,
                          height: 1,
                          color: Colors.transparent,
                        );
                      }
                      final cargo = cargoMap[codCargo];
                      if (cargo == null) return const SizedBox.shrink();
                      return _buildNodeWidget(cargo);
                    },
                  ),
                ),
              ),
              // Organigrama invisible pero completo para captura (fuera de pantalla)
              Positioned(
                left: -50000, // Fuera de la vista
                top: -50000,
                child: RepaintBoundary(
                  key: _organigramaKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(
                      50,
                    ), // Padding para que no se corten los bordes
                    child: GraphView(
                      graph: graph,
                      algorithm: BuchheimWalkerAlgorithm(
                        builder,
                        TreeEdgeRenderer(builder),
                      ),
                      paint:
                          Paint()
                            ..color = Colors.grey.shade400
                            ..strokeWidth = 2
                            ..style = PaintingStyle.stroke,
                      builder: (Node node) {
                        final codCargo = node.key!.value as int;
                        if (codCargo == -1) {
                          return Container(
                            width: 1,
                            height: 1,
                            color: Colors.transparent,
                          );
                        }
                        final cargo = cargoMap[codCargo];
                        if (cargo == null) return const SizedBox.shrink();
                        return _buildNodeWidget(cargo);
                      },
                    ),
                  ),
                ),
              ),
              // Botón flotante para exportar
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => exportarOrganigrama(context),
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar'),
                  backgroundColor: Colors.blue,
                  tooltip: 'Exportar organigrama en alta calidad',
                ),
              ),
            ],
          ),
        ),
        // Panel lateral de nodos huérfanos
        if (_nodosHuerfanos.isNotEmpty) _buildPanelHuerfanos(),
      ],
    );
  }

  Widget _buildPanelHuerfanos() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border(left: BorderSide(color: Colors.orange, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nodos Huérfanos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_nodosHuerfanos.length} cargo(s) sin padre',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lista de nodos huérfanos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _nodosHuerfanos.length,
              itemBuilder: (context, index) {
                final cargo = _nodosHuerfanos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 2,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.orange.shade300, width: 2),
                  ),
                  child: InkWell(
                    onTap: () => widget.onNodeTap(cargo),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.link_off,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  cargo.descripcion,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Código: ${cargo.codCargo}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            'Nivel: ${cargo.nivel} | Pos: ${cargo.posicion}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
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
                              'Padre inactivo: ${cargo.codCargoPadre}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (cargo.tieneEmpleadosActivos > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '👤 ${cargo.tieneEmpleadosActivos} empleado(s)',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
