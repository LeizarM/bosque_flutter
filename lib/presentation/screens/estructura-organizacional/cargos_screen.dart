import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/organigrama_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider para el modo de vista (lista o organigrama)
final viewModeProvider = StateProvider<bool>(
  (ref) => false,
); // false = lista, true = organigrama

class CargosScreen extends ConsumerStatefulWidget {
  final int codEmpresa;
  final String nombreEmpresa;

  const CargosScreen({
    super.key,
    required this.codEmpresa,
    required this.nombreEmpresa,
  });

  @override
  ConsumerState<CargosScreen> createState() => _CargosScreenState();
}

class _CargosScreenState extends ConsumerState<CargosScreen> {
  // Ya no necesitamos GraphView ni sus configuraciones
  // final Graph graph = Graph()..isTree = true;
  // BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  // SugiyamaConfiguration sugiyamaBuilder = SugiyamaConfiguration();
  // final TransformationController _transformationController = TransformationController();
  // Map<int, Node> nodeMap = {};
  // Map<int, CargoEntity> cargoMap = {};
  // bool useSugiyama = true;

  @override
  void initState() {
    super.initState();
    // _configureBuilders(); // Ya no necesario
  }

  // Ya no necesitamos los métodos de GraphView
  /*
  void _configureBuilders() {
    builder
      ..siblingSeparation = (150)
      ..levelSeparation = (180)
      ..subtreeSeparation = (150)
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);

    sugiyamaBuilder
      ..nodeSeparation = (150)
      ..levelSeparation = (180)
      ..orientation = (SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM)
      ..bendPointShape = CurvedBendPointShape(curveLength: 20);
  }

  void _buildGraph(List<CargoEntity> cargos) {
    graph.nodes.clear();
    graph.edges.clear();
    nodeMap.clear();
    cargoMap.clear();
    ...
  }
  */

  Color _getNodeColor(CargoEntity cargo) {
    if (cargo.estado == 0) {
      return Colors.red.shade100; // Inactivo
    }
    // Colores basados en el nivel jerárquico
    switch (cargo.codNivel) {
      case 1:
        return Colors.red.shade100;
      case 2:
        return Colors.orange.shade100;
      case 3:
        return Colors.yellow.shade100;
      case 4:
        return Colors.green.shade100;
      case 5:
        return Colors.blue.shade100;
      case 6:
        return Colors.indigo.shade100;
      case 7:
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
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

  @override
  Widget build(BuildContext context) {
    final isOrganigramaMode = ref.watch(viewModeProvider);
    final cargosAsync = ref.watch(cargosXEmpresaProvider(widget.codEmpresa));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cargos - ${widget.nombreEmpresa}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(isOrganigramaMode ? Icons.list : Icons.account_tree),
            tooltip: isOrganigramaMode ? 'Ver Lista' : 'Ver Organigrama',
            onPressed: () {
              ref.read(viewModeProvider.notifier).state = !isOrganigramaMode;
            },
          ),
          // Ya no necesitamos controles de zoom de GraphView
          /*
          if (isOrganigramaMode) ...[
            IconButton(
              icon: Icon(useSugiyama ? Icons.account_tree : Icons.device_hub),
              tooltip: useSugiyama ? 'Cambiar a layout de árbol' : 'Cambiar a layout por niveles',
              onPressed: () {
                setState(() {
                  useSugiyama = !useSugiyama;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () {
                _transformationController.value = Matrix4.identity()..scale(
                  _transformationController.value.getMaxScaleOnAxis() * 1.2,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () {
                _transformationController.value = Matrix4.identity()..scale(
                  _transformationController.value.getMaxScaleOnAxis() * 0.8,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: () {
                _transformationController.value = Matrix4.identity();
              },
            ),
          ],
          */
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(cargosXEmpresaProvider(widget.codEmpresa));
            },
          ),
        ],
      ),
      body: cargosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () => ref.invalidate(
                          cargosXEmpresaProvider(widget.codEmpresa),
                        ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
        data:
            (cargos) =>
                isOrganigramaMode
                    ? _buildOrganigramaView(cargos)
                    : _buildListView(cargos),
      ),
    );
  }

  // Vista de organigrama
  Widget _buildOrganigramaView(List<CargoEntity> cargos) {
    if (cargos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay cargos registrados'),
          ],
        ),
      );
    }

    // Ya no necesitamos _buildGraph porque usamos posicionamiento manual
    // _buildGraph(cargos);

    return Column(
      children: [
        // Leyenda
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade200,
          child: Column(
            children: [
              // Leyenda de estados
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(
                      Icons.person,
                      'Con empleados',
                      Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      Icons.account_tree,
                      'Con dependencias',
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(
                      Icons.work_outline,
                      'Sin asignar',
                      Colors.grey,
                    ),
                    const SizedBox(width: 16),
                    _buildLegendItem(Icons.block, 'Inactivo', Colors.red),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Info sobre el organigrama
              Text(
                'Organigrama con posicionamiento manual por nivel y posición',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        // Organigrama Custom Optimizado
        Expanded(
          child: OrganigramaCustom(
            cargos: cargos,
            onNodeTap: (cargo) => _showCargoActions(cargo),
          ),
        ),
      ],
    );
  }

  // Vista de lista
  Widget _buildListView(List<CargoEntity> cargos) {
    if (cargos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay cargos registrados'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cargos.length,
      itemBuilder: (context, index) {
        final cargo = cargos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getNodeColor(cargo),
              child: Icon(_getStatusIcon(cargo), size: 20),
            ),
            title: Text(
              cargo.descripcion,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cargo.estado == 0 ? Colors.grey : null,
                decoration:
                    cargo.estado == 0 ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nivel: ${cargo.codNivel}'),
                if (cargo.tieneEmpleadosActivos > 0)
                  Text(
                    '${cargo.tieneEmpleadosActivos} empleado(s) activo(s)',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                if (cargo.numHijosActivos > 0)
                  Text(
                    '${cargo.numHijosActivos} hijo(s) activo(s)',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
              ],
            ),
            trailing:
                cargo.estado == 1
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.cancel, color: Colors.red),
            onTap: () => _showCargoActions(cargo),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Ya no necesitamos este método porque el widget personalizado tiene su propia implementación
  /*
  Widget _buildNodeWidget(CargoEntity cargo) {
    final nodeColor = _getNodeColor(cargo);

    return InkWell(
      onTap: () => _showCargoActions(cargo),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 140,
          maxWidth: 180,
          minHeight: 80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: nodeColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: cargo.estado == 0
                ? Colors.red.shade700
                : cargo.tieneEmpleadosActivos > 0
                ? Colors.green.shade700
                : cargo.numHijosActivos > 0
                ? Colors.blue.shade700
                : Colors.grey.shade600,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Nombre del cargo (principal)
            Text(
              cargo.descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.2,
                decoration: cargo.estado == 0 ? TextDecoration.lineThrough : null,
                color: cargo.estado == 0 ? Colors.grey.shade600 : Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            // ... resto del código comentado
          ],
        ),
      ),
    );
  }
  */

  // Mostrar acciones del cargo
  void _showCargoActions(CargoEntity cargo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
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
                    Icon(
                      _getStatusIcon(cargo),
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
                onTap: () {
                  Navigator.of(context).pop();
                  _showCargoDetails(cargo);
                },
              ),

              // Reparentar (cambiar padre)
              if (cargo.canDeactivate == 1 && cargo.estado == 1) ...[
                ListTile(
                  leading: const Icon(Icons.switch_access_shortcut),
                  title: const Text('Reparentar (Cambiar padre)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showReparentarDialog(cargo);
                  },
                ),
              ],

              // Inactivar cargo
              if (cargo.canDeactivate == 1 && cargo.estado == 1) ...[
                const Divider(height: 8),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Inactivar cargo',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showInactivateConfirmation(cargo);
                  },
                ),
              ],

              // Mensaje si no se puede inactivar
              if (cargo.canDeactivate == 0) ...[
                const Divider(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Este cargo no puede ser inactivado o modificado debido a sus dependencias.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Mostrar detalles del cargo
  void _showCargoDetails(CargoEntity cargo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _getStatusIcon(cargo),
                  color:
                      cargo.tieneEmpleadosActivos > 0
                          ? Colors.green
                          : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cargo.descripcion,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Código:', '${cargo.codCargo}'),
                  _buildDetailRow('Nivel:', '${cargo.codNivel}'),
                  _buildDetailRow('Posición:', '${cargo.posicion}'),
                  _buildDetailRow(
                    'Estado:',
                    cargo.estado == 1 ? 'Activo' : 'Inactivo',
                  ),
                  _buildDetailRow(
                    'Puede desactivarse:',
                    cargo.canDeactivate == 1 ? 'Sí' : 'No',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Empleados activos:',
                    '${cargo.tieneEmpleadosActivos}',
                  ),
                  _buildDetailRow(
                    'Empleados totales:',
                    '${cargo.tieneEmpleadosTotales}',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Hijos activos:',
                    '${cargo.numHijosActivos} de ${cargo.numHijosTotal}',
                  ),
                  _buildDetailRow('Dependencias:', '${cargo.numDependientes}'),
                  _buildDetailRow(
                    'Dependencias totales:',
                    '${cargo.numDependenciasTotales}',
                  ),
                  const Divider(),
                  _buildDetailRow('Estado padre:', cargo.estadoPadre),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cargo.resumenCompleto,
                      style: const TextStyle(fontSize: 12),
                    ),
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
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // Diálogo para reparentar
  void _showReparentarDialog(CargoEntity cargo) {
    final cargosAsync = ref.read(cargosXEmpresaProvider(widget.codEmpresa));
    final cargos = cargosAsync.value ?? [];

    // Filtrar posibles padres (excluir el mismo cargo y sus descendientes)
    final posiblesPadres =
        cargos.where((c) {
          return c.codCargo != cargo.codCargo &&
              c.estado == 1 &&
              c.codCargo != cargo.codCargoPadre;
        }).toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reparentar Cargo'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cargo: ${cargo.descripcion}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Padre actual: ${cargo.estadoPadre}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Selecciona el nuevo cargo padre:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: posiblesPadres.length,
                      itemBuilder: (context, index) {
                        final padre = posiblesPadres[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getNodeColor(padre),
                            radius: 20,
                            child: Text(
                              '${padre.codNivel}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          title: Text(padre.descripcion),
                          subtitle: Text('Nivel: ${padre.codNivel}'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _confirmReparentar(cargo, padre);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  // Confirmar reparentar
  void _confirmReparentar(CargoEntity cargo, CargoEntity nuevoPadre) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Reparentar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Estás seguro de cambiar el padre?'),
                const SizedBox(height: 16),
                Text('Cargo: ${cargo.descripcion}'),
                const SizedBox(height: 8),
                Text('Nuevo padre: ${nuevoPadre.descripcion}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Esta acción modificará la estructura organizacional.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _executeReparentar(cargo, nuevoPadre);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );
  }

  // Ejecutar reparentar
  void _executeReparentar(CargoEntity cargo, CargoEntity nuevoPadre) {
    // TODO: Implementar la llamada al backend para reparentar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reparentando ${cargo.descripcion} a ${nuevoPadre.descripcion}...',
        ),
        backgroundColor: Colors.orange,
      ),
    );

    // Aquí deberías hacer la llamada al backend
    // Por ahora, solo mostramos un mensaje
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Función no implementada en el backend'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  // Confirmar inactivación
  void _showInactivateConfirmation(CargoEntity cargo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Confirmar Inactivación'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Estás seguro de inactivar este cargo?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Cargo: ${cargo.descripcion}'),
                Text('Código: ${cargo.codCargo}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Esta acción desactivará el cargo en el sistema.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _executeInactivate(cargo);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Inactivar'),
              ),
            ],
          ),
    );
  }

  // Ejecutar inactivación
  void _executeInactivate(CargoEntity cargo) {
    // TODO: Implementar la llamada al backend para inactivar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inactivando ${cargo.descripcion}...'),
        backgroundColor: Colors.red,
      ),
    );

    // Aquí deberías hacer la llamada al backend
    // Por ahora, solo mostramos un mensaje
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Función no implementada en el backend'),
          backgroundColor: Colors.orange,
        ),
      );
    });
  }

  @override
  void dispose() {
    // Ya no necesitamos dispose del _transformationController
    // _transformationController.dispose();
    super.dispose();
  }
}
