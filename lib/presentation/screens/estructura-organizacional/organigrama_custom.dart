import 'dart:typed_data';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graphview/GraphView.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;

// Importar de forma condicional para web y móvil
import 'web_export_stub.dart'
    if (dart.library.html) 'web_export.dart'
    as web_export;

class OrganigramaCustom extends StatefulWidget {
  final List<CargoEntity> cargos;
  final Function(CargoEntity) onNodeTap;
  final Function(CargoEntity)? onEmpleadosTap;

  const OrganigramaCustom({
    super.key,
    required this.cargos,
    required this.onNodeTap,
    this.onEmpleadosTap,
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
    // Layout ultra compacto para carta horizontal
    builder
      ..siblingSeparation = 12
      ..levelSeparation = 30
      ..subtreeSeparation = 12
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  @override
  void didUpdateWidget(OrganigramaCustom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cargos != widget.cargos) {
      _buildGraph();
    }
  }

  final List<CargoEntity> _nodosHuerfanos = [];

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

    // Primero, identificar qué cargos REALES ACTIVOS existen
    final cargosRealesActivos = <int>{};
    for (var cargo in todosLosCargos) {
      final esFicticio =
          cargo.descripcion.contains('[Ficticio') ||
          cargo.descripcion.toLowerCase().contains('ficticio');
      if (!esFicticio && cargo.estado == 1) {
        cargosRealesActivos.add(cargo.codCargo);
      }
    }

    // Construir mapa de padres para rastrear cadenas ficticias
    final mapaPadres = <int, int>{};
    for (var cargo in todosLosCargos) {
      mapaPadres[cargo.codCargo] = cargo.codCargoPadre;
    }

    // Función para verificar si un nodo ficticio lleva a un cargo real activo
    bool ficticioPadreDeCargoActivo(int codCargo) {
      for (var cargo in todosLosCargos) {
        if (cargo.codCargoPadre == codCargo) {
          final esFicticioHijo =
              cargo.descripcion.contains('[Ficticio') ||
              cargo.descripcion.toLowerCase().contains('ficticio');
          if (!esFicticioHijo && cargo.estado == 1) {
            // El hijo es un cargo real activo
            return true;
          } else if (esFicticioHijo) {
            // Seguir la cadena ficticia
            if (ficticioPadreDeCargoActivo(cargo.codCargo)) {
              return true;
            }
          }
        }
      }
      return false;
    }

    // Crear nodos: OCULTAR cargos REALES inactivos Y ficticios que no llevan a activos
    for (var cargo in todosLosCargos) {
      final esFicticio =
          cargo.descripcion.contains('[Ficticio') ||
          cargo.descripcion.toLowerCase().contains('ficticio');
      final esRealInactivo = !esFicticio && cargo.estado == 0;

      // Si es REAL Y está INACTIVO -> NO MOSTRAR
      if (esRealInactivo) continue;

      // Si es FICTICIO, verificar que su cadena lleve a un cargo real activo
      if (esFicticio) {
        if (!ficticioPadreDeCargoActivo(cargo.codCargo)) {
          // Este ficticio no lleva a ningún cargo real activo, no mostrarlo
          continue;
        }
      }

      final node = Node.Id(cargo.codCargo);
      nodeMap[cargo.codCargo] = node;
      cargoMap[cargo.codCargo] = cargo;
      graph.addNode(node);
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
      // Verificar que el contexto del organigrama esté disponible ANTES de mostrar el diálogo
      final currentContext = _organigramaKey.currentContext;
      if (currentContext == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error: El organigrama no está listo para exportar. Intente de nuevo.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final renderObject = currentContext.findRenderObject();
      if (renderObject == null || renderObject is! RenderRepaintBoundary) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error: No se pudo acceder al renderizado del organigrama.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Mostrar loading con indicador que no depende del hilo principal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx;
          return const _ExportLoadingDialog();
        },
      );

      // Esperar a que el diálogo se renderice completamente
      await Future.delayed(const Duration(milliseconds: 150));

      // Usar el RenderRepaintBoundary ya validado
      RenderRepaintBoundary boundary = renderObject;

      // Capturar la imagen (en web usamos menor resolución para evitar problemas)
      final double pixelRatio = kIsWeb ? 2.0 : 3.0;
      ui.Image originalImage = await boundary.toImage(pixelRatio: pixelRatio);

      // Convertir directamente a PNG
      ByteData? byteData = await originalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Verificar que byteData no sea null
      if (byteData == null) {
        originalImage.dispose();
        throw Exception('No se pudo convertir la imagen a bytes');
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

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
        await _exportarWeb(pngBytes, ancho, alto, context);
      } else {
        // Para plataformas móviles/desktop
        await _exportarMovilDesktop(pngBytes, ancho, alto, context);
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
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Exportar para plataforma Web
  Future<void> _exportarWeb(
    Uint8List pngBytes,
    int ancho,
    int alto,
    BuildContext context,
  ) async {
    if (!kIsWeb) return;

    try {
      // Usar el ExportManager para descargar
      final exportManager = web_export.createExportManager();
      final nombreArchivo =
          'organigrama_${DateTime.now().millisecondsSinceEpoch}.png';
      await exportManager.descargarPNG(pngBytes, nombreArchivo);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Organigrama descargado exitosamente\nResolución: ${ancho}x$alto pixels',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Exportar para plataformas móviles/desktop
  Future<void> _exportarMovilDesktop(
    Uint8List pngBytes,
    int ancho,
    int alto,
    BuildContext context,
  ) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Organigrama generado exitosamente\nResolución: ${ancho}x$alto pixels\n(Imagen lista para compartir)',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    // Aquí se puede implementar la exportación nativa usando:
    // - share_plus para compartir
    // - path_provider para guardar archivos
    // - file_saver para descargar
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
                child: RepaintBoundary(
                  key: _organigramaKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
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
            color: Colors.black.withValues(alpha: 0.1),
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
                  color: Colors.black.withValues(alpha: 0.1),
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
      return Container(width: 75, height: 48, color: Colors.transparent);
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
        width: 75,
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: borderColor, width: isInactive ? 1 : 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                cargo.descripcion,
                style: TextStyle(
                  fontSize: 5,
                  fontWeight: FontWeight.bold,
                  color: isInactive ? Colors.red.shade900 : Colors.black87,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'N${cargo.nivel}|P${cargo.posicion}',
              style: TextStyle(fontSize: 4.5, color: Colors.grey.shade800),
            ),
            if (cargo.tieneEmpleadosActivos > 0)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      widget.onEmpleadosTap != null
                          ? () => widget.onEmpleadosTap!(cargo)
                          : null,
                  borderRadius: BorderRadius.circular(2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '👤${cargo.tieneEmpleadosActivos}',
                      style: TextStyle(
                        fontSize: 4.5,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
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

/// Widget de loading con animación propia que no se bloquea
/// durante operaciones pesadas en el hilo principal
class _ExportLoadingDialog extends StatefulWidget {
  const _ExportLoadingDialog();

  @override
  State<_ExportLoadingDialog> createState() => _ExportLoadingDialogState();
}

class _ExportLoadingDialogState extends State<_ExportLoadingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Animar los puntos suspensivos
    _startDotAnimation();
  }

  void _startDotAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    final spaces = ' ' * (3 - _dotCount);

    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de carga rotatorio personalizado
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 4,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _ArcPainter(
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 4,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Generando imagen$dots$spaces',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor espere',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter para dibujar un arco (parte del círculo de carga)
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Dibujar solo una porción del círculo (90 grados)
    canvas.drawArc(rect, -0.5, 1.5, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
