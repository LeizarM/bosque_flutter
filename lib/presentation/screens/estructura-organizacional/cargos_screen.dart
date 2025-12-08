import 'package:bosque_flutter/core/constants/app_constants.dart';
import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/cargo_entity.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/organigrama_custom.dart';
import 'package:bosque_flutter/presentation/widgets/estructura-organizacional/cargo_actions_bottom_sheet.dart';
import 'package:bosque_flutter/presentation/widgets/estructura-organizacional/editar_cargo_form.dart';
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
  // Campo de búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // _configureBuilders(); // Ya no necesario
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // Método para filtrar cargos por búsqueda
  List<CargoEntity> _filtrarCargos(List<CargoEntity> cargos) {
    if (_searchQuery.isEmpty) {
      return cargos;
    }

    List<CargoEntity> resultado = [];

    void filtrarRecursivo(List<CargoEntity> lista) {
      for (var cargo in lista) {
        // Verificar si el cargo coincide con la búsqueda
        final coincide =
            cargo.descripcion.toLowerCase().contains(_searchQuery) ||
            cargo.codCargo.toString().contains(_searchQuery);

        // Filtrar hijos recursivamente
        List<CargoEntity> hijosFiltrados = [];
        if (cargo.items.isNotEmpty) {
          for (var hijo in cargo.items) {
            final hijoCoincide =
                hijo.descripcion.toLowerCase().contains(_searchQuery) ||
                hijo.codCargo.toString().contains(_searchQuery);

            if (hijoCoincide) {
              hijosFiltrados.add(hijo);
            } else {
              // Revisar si algún descendiente coincide
              var hijoConDescendientes = _filtrarCargoConDescendientes(hijo);
              if (hijoConDescendientes != null) {
                hijosFiltrados.add(hijoConDescendientes);
              }
            }
          }
        }

        // Agregar el cargo si coincide o tiene hijos que coinciden
        if (coincide || hijosFiltrados.isNotEmpty) {
          resultado.add(
            CargoEntity(
              codCargo: cargo.codCargo,
              codCargoPadre: cargo.codCargoPadre,
              descripcion: cargo.descripcion,
              codEmpresa: cargo.codEmpresa,
              codNivel: cargo.codNivel,
              posicion: cargo.posicion,
              estado: cargo.estado,
              audUsuario: cargo.audUsuario,
              sucursal: cargo.sucursal,
              sucursalPlanilla: cargo.sucursalPlanilla,
              nombreEmpresa: cargo.nombreEmpresa,
              nombreEmpresaPlanilla: cargo.nombreEmpresaPlanilla,
              codEmpresaPlanilla: cargo.codEmpresaPlanilla,
              codCargoPlanilla: cargo.codCargoPlanilla,
              descripcionPlanilla: cargo.descripcionPlanilla,
              nivel: cargo.nivel,
              tieneEmpleadosActivos: cargo.tieneEmpleadosActivos,
              tieneEmpleadosTotales: cargo.tieneEmpleadosTotales,
              estaAsignadoSucursal: cargo.estaAsignadoSucursal,
              canDeactivate: cargo.canDeactivate,
              numDependientes: cargo.numDependientes,
              numDependenciasTotales: cargo.numDependenciasTotales,
              numDependenciasCompletas: cargo.numDependenciasCompletas,
              numDeDependencias: cargo.numDeDependencias,
              numHijosActivos: cargo.numHijosActivos,
              numHijosTotal: cargo.numHijosTotal,
              resumenCompleto: cargo.resumenCompleto,
              estadoPadre: cargo.estadoPadre,
              esVisible: cargo.esVisible,
              items: hijosFiltrados,
              codCargoPadreOriginal: cargo.codCargoPadreOriginal,
              codEmpleado: cargo.codEmpleado,
              nombreCompleto: cargo.nombreCompleto,
            ),
          );
        }
      }
    }

    filtrarRecursivo(cargos);
    return resultado;
  }

  // Método auxiliar para filtrar cargo con sus descendientes
  CargoEntity? _filtrarCargoConDescendientes(CargoEntity cargo) {
    List<CargoEntity> hijosFiltrados = [];

    for (var hijo in cargo.items) {
      final coincide =
          hijo.descripcion.toLowerCase().contains(_searchQuery) ||
          hijo.codCargo.toString().contains(_searchQuery);

      if (coincide) {
        hijosFiltrados.add(hijo);
      } else {
        var hijoConDescendientes = _filtrarCargoConDescendientes(hijo);
        if (hijoConDescendientes != null) {
          hijosFiltrados.add(hijoConDescendientes);
        }
      }
    }

    if (hijosFiltrados.isEmpty) {
      return null;
    }

    return CargoEntity(
      codCargo: cargo.codCargo,
      codCargoPadre: cargo.codCargoPadre,
      descripcion: cargo.descripcion,
      codEmpresa: cargo.codEmpresa,
      codNivel: cargo.codNivel,
      posicion: cargo.posicion,
      estado: cargo.estado,
      audUsuario: cargo.audUsuario,
      sucursal: cargo.sucursal,
      sucursalPlanilla: cargo.sucursalPlanilla,
      nombreEmpresa: cargo.nombreEmpresa,
      nombreEmpresaPlanilla: cargo.nombreEmpresaPlanilla,
      codEmpresaPlanilla: cargo.codEmpresaPlanilla,
      codCargoPlanilla: cargo.codCargoPlanilla,
      descripcionPlanilla: cargo.descripcionPlanilla,
      nivel: cargo.nivel,
      tieneEmpleadosActivos: cargo.tieneEmpleadosActivos,
      tieneEmpleadosTotales: cargo.tieneEmpleadosTotales,
      estaAsignadoSucursal: cargo.estaAsignadoSucursal,
      canDeactivate: cargo.canDeactivate,
      numDependientes: cargo.numDependientes,
      numDependenciasTotales: cargo.numDependenciasTotales,
      numDependenciasCompletas: cargo.numDependenciasCompletas,
      numDeDependencias: cargo.numDeDependencias,
      numHijosActivos: cargo.numHijosActivos,
      numHijosTotal: cargo.numHijosTotal,
      resumenCompleto: cargo.resumenCompleto,
      estadoPadre: cargo.estadoPadre,
      esVisible: cargo.esVisible,
      items: hijosFiltrados,
      codCargoPadreOriginal: cargo.codCargoPadreOriginal,
      codEmpleado: cargo.codEmpleado,
      nombreCompleto: cargo.nombreCompleto,
    );
  }

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
          // Botón para crear nuevo cargo
          IconButton(
            icon: const Icon(Icons.add_circle),
            tooltip: 'Nuevo Cargo',
            onPressed: () => _showCrearCargoDialog(),
          ),

          IconButton(
            icon: Icon(isOrganigramaMode ? Icons.list : Icons.account_tree),
            tooltip: isOrganigramaMode ? 'Ver Lista' : 'Ver Organigrama',
            onPressed: () {
              ref.read(viewModeProvider.notifier).state = !isOrganigramaMode;
            },
          ),

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
        data: (cargos) {
          return Column(
            children: [
              // Barra de búsqueda - SOLO en modo lista
              if (!isOrganigramaMode)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar cargo...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              // Vista según el modo
              Expanded(
                child:
                    isOrganigramaMode
                        ? _buildOrganigramaView(
                          cargos,
                        ) // Organigrama sin filtro
                        : _buildListView(
                          _filtrarCargos(cargos),
                        ), // Lista con filtro
              ),
            ],
          );
        },
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
            onEmpleadosTap: (cargo) => _showEmpleadosDialog(cargo),
          ),
        ),
      ],
    );
  }

  // Vista de lista en forma de árbol
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _buildTreeNodes(cargos, 0),
    );
  }

  // Construir nodos del árbol recursivamente
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

      // Agregar el nodo actual (visible)
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: nivel * 20.0),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _showCargoActions(cargo),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Leading: Línea indicadora + Ícono clickeable
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Línea indicadora de nivel
                        if (nivel > 0)
                          Container(
                            width: 3,
                            height: 40,
                            color: _getNodeColor(cargo),
                            margin: const EdgeInsets.only(right: 8),
                          ),
                        // Icono del cargo - clickeable si tiene empleados
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                cargo.tieneEmpleadosActivos > 0
                                    ? () => _showEmpleadosDialog(cargo)
                                    : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getNodeColor(cargo),
                                  radius: 18,
                                  child: Icon(_getStatusIcon(cargo), size: 18),
                                ),
                                // Badge de empleados si tiene
                                if (cargo.tieneEmpleadosActivos > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        '${cargo.tieneEmpleadosActivos}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Title y Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cargo.descripcion,
                            style: TextStyle(
                              fontWeight:
                                  nivel == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: nivel == 0 ? 15 : 14,
                              color: cargo.estado == 0 ? Colors.grey : null,
                              decoration:
                                  cargo.estado == 0
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nivel: ${cargo.nivel} | Pos: ${cargo.posicion}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (cargo.tieneEmpleadosActivos > 0)
                            Text(
                              '👤 ${cargo.tieneEmpleadosActivos} empleado${cargo.tieneEmpleadosActivos > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                              ),
                            ),
                          if (cargo.numHijosActivos > 0)
                            Text(
                              '📊 ${cargo.numHijosActivos} cargo${cargo.numHijosActivos > 1 ? 's' : ''} subordinado${cargo.numHijosActivos > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Trailing
                    cargo.estado == 1
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.cancel, color: Colors.red),
                  ],
                ),
              ),
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

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Mostrar diálogo de empleados asignados a un cargo
  void _showEmpleadosDialog(CargoEntity cargo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => _EmpleadosBottomSheet(
            cargo: cargo,
            codEmpresa: widget.codEmpresa,
          ),
    );
  }

  // Mostrar acciones del cargo
  void _showCargoActions(CargoEntity cargo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => CargoActionsBottomSheet(
            cargo: cargo,
            onViewDetails: () {
              Navigator.of(context).pop();
              _showCargoDetails(cargo);
            },
            onEdit: () {
              Navigator.of(context).pop();
              _showEditarCargoForm(cargo);
            },
            onAddChild: () {
              Navigator.of(context).pop();
              _showCrearCargoHijoDialog(cargo);
            },
            onDuplicate: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función no implementada aún'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
    );
  }

  // Old bottom sheet code removed - using CargoActionsBottomSheet widget instead

  // Mostrar detalles del cargo con tabs
  void _showCargoDetails(CargoEntity cargo) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    showDialog(
      context: context,
      builder:
          (context) => _CargoDetailsDialog(
            cargo: cargo,
            isMobile: isMobile,
            getStatusIcon: _getStatusIcon,
          ),
    );
  }

  // Método auxiliar para aplanar la estructura jerárquica de cargos
  List<CargoEntity> _aplanarCargos(List<CargoEntity> cargosJerarquicos) {
    List<CargoEntity> listaPlana = [];

    void agregarRecursivo(List<CargoEntity> cargos) {
      for (var cargo in cargos) {
        listaPlana.add(cargo);
        if (cargo.items.isNotEmpty) {
          agregarRecursivo(cargo.items);
        }
      }
    }

    agregarRecursivo(cargosJerarquicos);
    return listaPlana;
  }

  // Diálogo para reparentar - Muestra TODOS los cargos disponibles
  void _showReparentarDialog(CargoEntity cargo) {
    final cargosAsync = ref.read(cargosXEmpresaProvider(widget.codEmpresa));
    final cargos = cargosAsync.value ?? [];

    // SIMPLIFICADO: Mostrar TODOS los cargos excepto el mismo cargo
    // El usuario puede elegir cualquier cargo como padre, incluso si crea ciclos
    // (el backend debería validar esto)
    final posiblesPadres =
        cargos.where((c) {
          return c.codCargo !=
                  cargo.codCargo && // No puede ser padre de sí mismo
              c.estado == 1 && // Solo cargos activos
              c.esVisible == 1; // Solo cargos visibles (no ficticios)
        }).toList();

    // Ordenar por nivel y luego por posición para mejor visualización
    posiblesPadres.sort((a, b) {
      if (a.nivel != b.nivel) return a.nivel.compareTo(b.nivel);
      return a.posicion.compareTo(b.posicion);
    });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.account_tree),
                const SizedBox(width: 8),
                const Expanded(child: Text('Reparentar Cargo')),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info del cargo a reparentar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cargo a mover:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cargo.descripcion,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Padre actual: ${cargo.estadoPadre}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona el nuevo cargo padre (todas las ramas):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  // Lista de todos los posibles padres
                  Expanded(
                    child:
                        posiblesPadres.isEmpty
                            ? Center(
                              child: Text(
                                'No hay otros cargos disponibles',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              itemCount: posiblesPadres.length,
                              itemBuilder: (context, index) {
                                final padre = posiblesPadres[index];
                                final esPadreActual =
                                    padre.codCargo == cargo.codCargoPadre;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  elevation: esPadreActual ? 2 : 0,
                                  color:
                                      esPadreActual
                                          ? Colors.blue.shade50
                                          : null,
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _getNodeColor(padre),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'N${padre.nivel}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      padre.descripcion,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            esPadreActual
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Nivel: ${padre.nivel} | Posición: ${padre.posicion} | Código: ${padre.codCargo}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing:
                                        esPadreActual
                                            ? Chip(
                                              label: const Text(
                                                'Actual',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              padding: EdgeInsets.zero,
                                            )
                                            : const Icon(
                                              Icons.arrow_forward,
                                              size: 18,
                                            ),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _confirmReparentar(cargo, padre);
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                  const SizedBox(height: 8),
                  // Leyenda
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Mostrando ${posiblesPadres.length} cargo(s) disponible(s). Puedes mover a cualquier cargo activo.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
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

  // Diálogo para reasignar a otra rama
  void _showReasignarRamaDialog(CargoEntity cargo) {
    final cargosAsync = ref.read(cargosXEmpresaProvider(widget.codEmpresa));
    final cargosJerarquicos = cargosAsync.value ?? [];

    // IMPORTANTE: Aplanar la lista jerárquica a una lista plana
    final todosCargos = _aplanarCargos(cargosJerarquicos);

    // Obtener las ramas principales (solo nivel 0 y 1) - INCLUYE INACTIVOS
    final ramasPrincipales =
        todosCargos
            .where(
              (c) => c.nivel <= 1 && c.esVisible == 1,
            ) // Sin filtrar por estado
            .toList()
          ..sort((a, b) {
            if (a.nivel != b.nivel) return a.nivel.compareTo(b.nivel);
            return a.posicion.compareTo(b.posicion);
          });

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.call_split, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Expanded(child: Text('Reasignar a Otra Rama')),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info del cargo a reasignar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.move_up,
                              color: Colors.purple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Cargo a reasignar:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cargo.descripcion,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rama actual: ${cargo.estadoPadre}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nivel: ${cargo.nivel} | Posición: ${cargo.posicion}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Advertencia sobre el movimiento
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.amber.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El cargo y toda su sub-jerarquía se moverán a la rama seleccionada.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Selecciona la rama destino:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),

                  // Lista de ramas disponibles
                  Expanded(
                    child:
                        ramasPrincipales.isEmpty
                            ? Center(
                              child: Text(
                                'No hay otras ramas disponibles',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              itemCount: ramasPrincipales.length,
                              itemBuilder: (context, index) {
                                final rama = ramasPrincipales[index];
                                final esInactivo = rama.estado == 0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  elevation: 0,
                                  color:
                                      esInactivo ? Colors.grey.shade100 : null,
                                  child: ExpansionTile(
                                    leading: Stack(
                                      children: [
                                        Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(
                                            color:
                                                esInactivo
                                                    ? Colors.grey.shade400
                                                    : _getNodeColor(rama),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  esInactivo
                                                      ? Colors.red
                                                      : Colors.grey.shade400,
                                              width: esInactivo ? 2 : 1,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.account_tree,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        if (esInactivo)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.block,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            rama.descripcion,
                                            style: TextStyle(
                                              fontSize: 13,
                                              decoration:
                                                  esInactivo
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                              color:
                                                  esInactivo
                                                      ? Colors.grey.shade600
                                                      : null,
                                            ),
                                          ),
                                        ),
                                        if (esInactivo)
                                          Chip(
                                            label: const Text(
                                              'INACTIVO',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.red.shade400,
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      'Nivel: ${rama.nivel} | Expande para ver cargos${esInactivo ? " | Desactivado" : ""}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            esInactivo
                                                ? Colors.grey.shade500
                                                : null,
                                      ),
                                    ),
                                    // Los children se construyen solo cuando se expande
                                    children: _buildCargosDeRamaLazy(
                                      rama,
                                      todosCargos,
                                      cargo,
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                  const SizedBox(height: 8),

                  // Leyenda
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Expande una rama y selecciona el cargo que será el nuevo padre.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.block,
                              size: 12,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Los cargos inactivos están disponibles (aparecen tachados con fondo gris)',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // Obtener cargos disponibles de una rama como posibles padres
  List<CargoEntity> _obtenerCargosDeRama(
    CargoEntity raiz,
    List<CargoEntity> todosCargos,
    CargoEntity cargoAMover,
  ) {
    List<CargoEntity> cargosRama = [raiz];
    Set<int> visitados = {raiz.codCargo}; // Prevenir ciclos

    void agregarDescendientes(int codPadre) {
      for (var c in todosCargos) {
        if (c.codCargoPadre == codPadre &&
            c.esVisible == 1 &&
            // MODIFICADO: Incluir cargos inactivos (estado == 0)
            c.codCargo != cargoAMover.codCargo &&
            !visitados.contains(c.codCargo)) {
          visitados.add(c.codCargo);
          cargosRama.add(c);
          agregarDescendientes(c.codCargo);
        }
      }
    }

    agregarDescendientes(raiz.codCargo);
    return cargosRama;
  }

  // Construir lista de cargos de una rama de forma lazy (solo cuando se expande)
  List<Widget> _buildCargosDeRamaLazy(
    CargoEntity rama,
    List<CargoEntity> todosCargos,
    CargoEntity cargoAMover,
  ) {
    // Obtener cargos de la rama de forma más eficiente
    final cargosRama = _obtenerCargosDeRama(rama, todosCargos, cargoAMover);

    // Limitar la cantidad si es muy grande
    final cargosAMostrar = cargosRama.take(50).toList();

    return cargosAMostrar.map((cargoDestino) {
      final esInactivo = cargoDestino.estado == 0;

      return ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 60, right: 16),
        // Fondo gris para cargos inactivos
        tileColor: esInactivo ? Colors.grey.shade100 : null,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color:
                    esInactivo
                        ? Colors.grey.shade400
                        : _getNodeColor(cargoDestino),
                shape: BoxShape.circle,
                border:
                    esInactivo ? Border.all(color: Colors.red, width: 2) : null,
              ),
              child: Center(
                child: Text(
                  'N${cargoDestino.nivel}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (esInactivo) ...[
              const SizedBox(width: 4),
              Icon(Icons.block, size: 14, color: Colors.red.shade700),
            ],
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cargoDestino.descripcion,
                style: TextStyle(
                  fontSize: 12,
                  decoration: esInactivo ? TextDecoration.lineThrough : null,
                  color: esInactivo ? Colors.grey.shade600 : null,
                ),
              ),
            ),
            if (esInactivo)
              Chip(
                label: const Text(
                  'INACTIVO',
                  style: TextStyle(fontSize: 9, color: Colors.white),
                ),
                backgroundColor: Colors.red.shade400,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        subtitle: Text(
          'Nivel: ${cargoDestino.nivel} | Pos: ${cargoDestino.posicion}${esInactivo ? " | Desactivado" : ""}',
          style: TextStyle(
            fontSize: 10,
            color: esInactivo ? Colors.grey.shade500 : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para activar/desactivar
            IconButton(
              icon: Icon(
                esInactivo ? Icons.check_circle : Icons.block,
                color: esInactivo ? Colors.green : Colors.red,
                size: 20,
              ),
              tooltip: esInactivo ? 'Activar cargo' : 'Desactivar cargo',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.of(context).pop();
                if (esInactivo) {
                  _showActivateConfirmation(cargoDestino);
                } else {
                  if (cargoDestino.canDeactivate == 1) {
                    _showInactivateConfirmation(cargoDestino);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'No se puede desactivar "${cargoDestino.descripcion}" porque tiene dependencias activas',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(width: 8),
            // Botón para reasignar
            IconButton(
              icon: Icon(
                Icons.arrow_forward,
                size: 20,
                color: esInactivo ? Colors.grey : Colors.blue,
              ),
              tooltip: 'Seleccionar como nuevo padre',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.of(context).pop();
                _confirmReasignarRama(cargoAMover, cargoDestino, rama);
              },
            ),
          ],
        ),
        onTap: () {
          // Al hacer tap, mostrar menú de opciones
          _showCargoQuickActions(context, cargoDestino, cargoAMover, rama);
        },
      );
    }).toList();
  }

  // Mostrar menú de acciones rápidas para un cargo en el diálogo de reasignar
  void _showCargoQuickActions(
    BuildContext context,
    CargoEntity cargo,
    CargoEntity cargoAMover,
    CargoEntity rama,
  ) {
    final esInactivo = cargo.estado == 0;

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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            esInactivo
                                ? Colors.grey.shade400
                                : _getNodeColor(cargo),
                        shape: BoxShape.circle,
                        border:
                            esInactivo
                                ? Border.all(color: Colors.red, width: 2)
                                : null,
                      ),
                      child: Center(
                        child: Text(
                          'N${cargo.nivel}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cargo.descripcion,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration:
                                  esInactivo
                                      ? TextDecoration.lineThrough
                                      : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Nivel ${cargo.nivel} | Pos ${cargo.posicion}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (esInactivo)
                      Chip(
                        label: const Text(
                          'INACTIVO',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                        backgroundColor: Colors.red.shade400,
                        padding: EdgeInsets.zero,
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

              // Seleccionar como nuevo padre
              ListTile(
                leading: const Icon(Icons.call_split, color: Colors.deepPurple),
                title: const Text('Seleccionar como nuevo padre'),
                subtitle: Text(
                  'Mover "${cargoAMover.descripcion}" a esta rama',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pop(); // Cerrar el diálogo de reasignar también
                  _confirmReasignarRama(cargoAMover, cargo, rama);
                },
              ),

              const Divider(height: 8),

              // Activar/Desactivar
              if (esInactivo)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text(
                    'Activar cargo',
                    style: TextStyle(color: Colors.green),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pop(); // Cerrar el diálogo de reasignar también
                    _showActivateConfirmation(cargo);
                  },
                )
              else if (cargo.canDeactivate == 1)
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text(
                    'Desactivar cargo',
                    style: TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(
                      context,
                    ).pop(); // Cerrar el diálogo de reasignar también
                    _showInactivateConfirmation(cargo);
                  },
                )
              else
                ListTile(
                  leading: Icon(Icons.block, color: Colors.grey.shade400),
                  title: Text(
                    'No se puede desactivar',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  subtitle: const Text(
                    'Tiene empleados o cargos subordinados activos',
                    style: TextStyle(fontSize: 11),
                  ),
                  enabled: false,
                ),

              // Ver detalles completos
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Ver detalles completos'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pop(); // Cerrar el diálogo de reasignar también
                  _showCargoDetails(cargo);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Confirmar reasignación a otra rama
  void _confirmReparentar(CargoEntity cargo, CargoEntity nuevoPadre) {
    final tieneDependencias =
        cargo.tieneEmpleadosActivos > 0 || cargo.numHijosActivos > 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  tieneDependencias
                      ? Icons.warning
                      : Icons.switch_access_shortcut,
                  color: tieneDependencias ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Confirmar Reparentar')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Estás seguro de cambiar el padre de este cargo?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Cargo: ${cargo.descripcion}'),
                  Text('Código: ${cargo.codCargo}'),
                  const SizedBox(height: 8),
                  Text('Nuevo padre: ${nuevoPadre.descripcion}'),
                  Text('Nivel nuevo: ${nuevoPadre.nivel + 1}'),
                  const SizedBox(height: 16),

                  // Advertencia si tiene dependencias
                  if (tieneDependencias) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.orange.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '⚠️ ADVERTENCIA IMPORTANTE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Este cargo tiene dependencias:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (cargo.tieneEmpleadosActivos > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '• ${cargo.tieneEmpleadosActivos} empleado(s) asignado(s)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          if (cargo.numHijosActivos > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '• ${cargo.numHijosActivos} cargo(s) subordinado(s)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Reparentar este cargo podría afectar:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Text(
                              '• Reportes jerárquicos\n'
                              '• Permisos de acceso\n'
                              '• Flujos de aprobación\n'
                              '• Estructura de costos\n'
                              '• Otros módulos del sistema',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
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
                    const SizedBox(height: 8),
                  ],
                ],
              ),
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

  // Confirmar reasignación a otra rama
  void _confirmReasignarRama(
    CargoEntity cargo,
    CargoEntity nuevoParaEnRama,
    CargoEntity ramaDestino,
  ) {
    final tieneDependencias =
        cargo.tieneEmpleadosActivos > 0 || cargo.numHijosActivos > 0;
    final tieneSubordinados = cargo.numHijosActivos > 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  tieneDependencias ? Icons.warning : Icons.call_split,
                  color: tieneDependencias ? Colors.orange : Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Confirmar Reasignación')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Estás seguro de reasignar este cargo a otra rama?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // Información del cargo
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.work,
                              size: 16,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Cargo a mover:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cargo.descripcion,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Código: ${cargo.codCargo} | Nivel actual: ${cargo.nivel}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Información del destino
                  Row(
                    children: [
                      Icon(
                        Icons.arrow_downward,
                        color: Colors.deepPurple.shade300,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Se moverá a:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_tree,
                              size: 16,
                              color: Colors.purple.shade700,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Rama destino:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ramaDestino.descripcion,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.supervisor_account,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Nuevo padre:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nuevoParaEnRama.descripcion,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Nuevo nivel: ${nuevoParaEnRama.nivel + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Advertencia sobre subordinados
                  if (tieneSubordinados) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este cargo tiene ${cargo.numHijosActivos} cargo(s) subordinado(s). Toda la sub-jerarquía se moverá junto con él.',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Advertencia si tiene dependencias
                  if (tieneDependencias) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '⚠️ ADVERTENCIA IMPORTANTE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este cargo tiene:',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ${cargo.tieneEmpleadosActivos} empleado(s) asignado(s)',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  '• ${cargo.numHijosActivos} cargo(s) subordinado(s)',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cambiar de rama podría afectar:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '• Reportes jerárquicos',
                                  style: TextStyle(fontSize: 11),
                                ),
                                Text(
                                  '• Permisos de acceso',
                                  style: TextStyle(fontSize: 11),
                                ),
                                Text(
                                  '• Flujos de aprobación',
                                  style: TextStyle(fontSize: 11),
                                ),
                                Text(
                                  '• Estructura de costos',
                                  style: TextStyle(fontSize: 11),
                                ),
                                Text(
                                  '• Otros módulos del sistema',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Este cargo no tiene empleados ni subordinados.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _executeReasignarRama(cargo, nuevoParaEnRama);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      tieneDependencias ? Colors.orange : Colors.deepPurple,
                ),
                child: const Text('Confirmar Reasignación'),
              ),
            ],
          ),
    );
  }

  // Ejecutar reasignación a otra rama
  void _executeReasignarRama(CargoEntity cargo, CargoEntity nuevoParaEnRama) {
    // TODO: Implementar la llamada al backend para reasignar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reasignando ${cargo.descripcion} a rama de ${nuevoParaEnRama.descripcion}...',
        ),
        backgroundColor: Colors.deepPurple,
      ),
    );

    // Aquí deberías hacer la llamada al backend
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Función no implementada en el backend'),
          backgroundColor: Colors.orange,
        ),
      );
    });
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

  // Confirmar activación
  void _showActivateConfirmation(CargoEntity cargo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Confirmar Activación'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Estás seguro de activar este cargo?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Cargo: ${cargo.descripcion}'),
                Text('Código: ${cargo.codCargo}'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Esta acción reactivará el cargo en el sistema.',
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
                  _executeActivate(cargo);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Activar'),
              ),
            ],
          ),
    );
  }

  // Ejecutar activación
  void _executeActivate(CargoEntity cargo) {
    // TODO: Implementar la llamada al backend para activar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Activando ${cargo.descripcion}...'),
        backgroundColor: Colors.green,
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

  // ============================================================================
  // MÉTODOS DEL FORMULARIO UNIFICADO DE EDICIÓN
  // ============================================================================

  // 🆕 Mostrar diálogo para crear nuevo cargo (RAÍZ)
  void _showCrearCargoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CrearCargoDialog(
          codEmpresa: widget.codEmpresa,
          cargoPadre: null, // Sin padre = raíz
          onGuardar: (data) {
            _procesarNuevoCargo(data);
          },
        );
      },
    );
  }

  // 🆕 Mostrar diálogo para crear cargo HIJO de un cargo específico
  void _showCrearCargoHijoDialog(CargoEntity cargoPadre) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CrearCargoDialog(
          codEmpresa: widget.codEmpresa,
          cargoPadre: cargoPadre, // Padre predefinido
          onGuardar: (data) {
            _procesarNuevoCargo(data);
          },
        );
      },
    );
  }

  // Procesar nuevo cargo
  Future<void> _procesarNuevoCargo(CargoEditData data) async {
    if (data.nuevoNombre == null || data.nuevoNombre!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ El nombre del cargo es obligatorio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (data.nuevoNivelJerarquico == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ El nivel jerárquico es obligatorio'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final datosParaBackend = {
      'codEmpresa': widget.codEmpresa,
      'nombre': data.nuevoNombre,
      'estado': data.nuevoEstado,
      'posicion': data.nuevaPosicion,
      'codCargoPadre': data.nuevoCargoPadre ?? 0, // 0 = raíz
      'codNivel': data.nuevoNivelJerarquico,
    };

    // Mostrar indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Creando cargo...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      // Obtener el código del usuario logueado
      final codUsuario = await ref.read(userProvider.notifier).getCodUsuario();

      // Crear entidad de cargo para enviar al backend
      final nuevoCargo = CargoEntity(
        codCargo: 0, // 0 = nuevo cargo
        codCargoPadre: data.nuevoCargoPadre ?? 0,
        descripcion: data.nuevoNombre!,
        codEmpresa: widget.codEmpresa,
        codNivel: data.nuevoNivelJerarquico!,
        posicion: data.nuevaPosicion,
        estado: data.nuevoEstado,
        audUsuario: codUsuario,
        sucursal: '',
        sucursalPlanilla: '',
        nombreEmpresa: widget.nombreEmpresa,
        nombreEmpresaPlanilla: '',
        codEmpresaPlanilla: 0,
        codCargoPlanilla: 0,
        descripcionPlanilla: '',
        nivel: 0,
        tieneEmpleadosActivos: 0,
        tieneEmpleadosTotales: 0,
        estaAsignadoSucursal: 0,
        canDeactivate: 1,
        numDependientes: 0,
        numDependenciasTotales: 0,
        numDependenciasCompletas: 0,
        numDeDependencias: 0,
        numHijosActivos: 0,
        numHijosTotal: 0,
        resumenCompleto: '',
        estadoPadre: '1',
        esVisible: 1,
        items: [],
        codCargoPadreOriginal: data.nuevoCargoPadre ?? 0,
        codEmpleado: 0,
        nombreCompleto: '',
      );

      // Llamar al repositorio
      final repository = ref.read(rrhhRepositoryProvider);
      final success = await repository.registrarCargo(nuevoCargo);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Cargo "${data.nuevoNombre}" creado exitosamente',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Refrescar la lista de cargos
          ref.invalidate(cargosXEmpresaProvider(widget.codEmpresa));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al crear el cargo'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Mostrar formulario unificado de edición
  void _showEditarCargoForm(CargoEntity cargo) {
    final cargosAsync = ref.read(cargosXEmpresaProvider(widget.codEmpresa));
    final cargos = cargosAsync.value ?? [];
    final todosCargos = _aplanarCargos(cargos);

    showDialog(
      context: context,
      builder:
          (context) => EditarCargoForm(
            cargo: cargo,
            todosCargos: todosCargos,
            codEmpresa: widget.codEmpresa,
            onGuardar: (data) {
              _procesarCambiosCargo(data, cargo);
            },
          ),
    );
  }

  // Procesar cambios del formulario de edición - CON CONFIRMACIÓN DETALLADA
  Future<void> _procesarCambiosCargo(
    CargoEditData data,
    CargoEntity cargoOriginal,
  ) async {
    // Validar que el codCargo sea diferente de cero (es un cargo existente)
    if (data.codCargo == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Error: El cargo no tiene un código válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Preparar datos que se enviarán al backend
    final datosParaBackend = {
      'codCargo': data.codCargo,
      'nombre':
          data.nuevoNombre ??
          cargoOriginal.descripcion, // Siempre incluir nombre
      'estado': data.nuevoEstado,
      'posicion': data.nuevaPosicion,
      'codCargoPadre':
          data.nuevoCargoPadre ?? cargoOriginal.codCargoPadreOriginal,
      'codNivel': data.nuevoNivelJerarquico ?? cargoOriginal.codNivel,
    };

    // Mostrar indicador de carga
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Actualizando cargo...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
    }

    try {
      // Obtener el código del usuario logueado
      final codUsuario = await ref.read(userProvider.notifier).getCodUsuario();

      // Crear entidad de cargo actualizada
      final cargoActualizado = CargoEntity(
        codCargo: data.codCargo,
        codCargoPadre:
            data.nuevoCargoPadre ?? cargoOriginal.codCargoPadreOriginal,
        descripcion: data.nuevoNombre ?? cargoOriginal.descripcion,
        codEmpresa: cargoOriginal.codEmpresa,
        codNivel: data.nuevoNivelJerarquico ?? cargoOriginal.codNivel,
        posicion: data.nuevaPosicion,
        estado: data.nuevoEstado,
        audUsuario: codUsuario,
        sucursal: cargoOriginal.sucursal,
        sucursalPlanilla: cargoOriginal.sucursalPlanilla,
        nombreEmpresa: cargoOriginal.nombreEmpresa,
        nombreEmpresaPlanilla: cargoOriginal.nombreEmpresaPlanilla,
        codEmpresaPlanilla: cargoOriginal.codEmpresaPlanilla,
        codCargoPlanilla: cargoOriginal.codCargoPlanilla,
        descripcionPlanilla: cargoOriginal.descripcionPlanilla,
        nivel: cargoOriginal.nivel,
        tieneEmpleadosActivos: cargoOriginal.tieneEmpleadosActivos,
        tieneEmpleadosTotales: cargoOriginal.tieneEmpleadosTotales,
        estaAsignadoSucursal: cargoOriginal.estaAsignadoSucursal,
        canDeactivate: cargoOriginal.canDeactivate,
        numDependientes: cargoOriginal.numDependientes,
        numDependenciasTotales: cargoOriginal.numDependenciasTotales,
        numDependenciasCompletas: cargoOriginal.numDependenciasCompletas,
        numDeDependencias: cargoOriginal.numDeDependencias,
        numHijosActivos: cargoOriginal.numHijosActivos,
        numHijosTotal: cargoOriginal.numHijosTotal,
        resumenCompleto: cargoOriginal.resumenCompleto,
        estadoPadre: cargoOriginal.estadoPadre,
        esVisible: cargoOriginal.esVisible,
        items: cargoOriginal.items,
        codCargoPadreOriginal:
            data.nuevoCargoPadre ?? cargoOriginal.codCargoPadreOriginal,
        codEmpleado: cargoOriginal.codEmpleado,
        nombreCompleto: cargoOriginal.nombreCompleto,
      );

      // Llamar al repositorio
      final repository = ref.read(rrhhRepositoryProvider);
      final success = await repository.registrarCargo(cargoActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cargo actualizado exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Refrescar la lista de cargos
          ref.invalidate(cargosXEmpresaProvider(widget.codEmpresa));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Error al actualizar el cargo'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Widget helper para mostrar filas de datos
  Widget _buildDataRow(String key, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9),
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(':', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enviar cambios al backend (aquí irá la llamada real al API)
  // ============================================================================
  // FIN DE MÉTODOS DEL FORMULARIO UNIFICADO
  // ============================================================================

  // Diálogo para cambiar posición
  void _showCambiarPosicionDialog(CargoEntity cargo) {
    final TextEditingController posicionController = TextEditingController(
      text: cargo.posicion.toString(),
    );
    final tieneDependencias =
        cargo.tieneEmpleadosActivos > 0 || cargo.numHijosActivos > 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  tieneDependencias
                      ? Icons.warning
                      : Icons.format_list_numbered,
                  color: tieneDependencias ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Cambiar Posición')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cargo: ${cargo.descripcion}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Nivel actual: ${cargo.nivel}'),
                  Text('Posición actual: ${cargo.posicion}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: posicionController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nueva posición',
                      hintText: 'Ingrese la nueva posición',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.format_list_numbered),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Advertencia si tiene dependencias
                  if (tieneDependencias) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade300,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '⚠️ ADVERTENCIA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este cargo tiene ${cargo.tieneEmpleadosActivos} empleado(s) y ${cargo.numHijosActivos} cargo(s) subordinado(s).',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Cambiar la posición podría afectar reportes y visualizaciones en otros módulos.',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'La posición determina el orden horizontal en el organigrama.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final nuevaPosicion = int.tryParse(posicionController.text);
                  if (nuevaPosicion != null &&
                      nuevaPosicion != cargo.posicion) {
                    Navigator.of(context).pop();
                    _executeCambiarPosicion(cargo, nuevaPosicion);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingrese una posición válida'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Cambiar'),
              ),
            ],
          ),
    );
  }

  // Ejecutar cambio de posición
  void _executeCambiarPosicion(CargoEntity cargo, int nuevaPosicion) {
    // TODO: Implementar la llamada al backend para cambiar posición
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cambiando posición de ${cargo.descripcion} a $nuevaPosicion...',
        ),
        backgroundColor: Colors.blue,
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
  @override
  void dispose() {
    // Ya no necesitamos dispose del _transformationController
    // _transformationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// ============================================================================
// DIÁLOGO SIMPLE PARA CREAR NUEVO CARGO
// ============================================================================
class _CrearCargoDialog extends ConsumerStatefulWidget {
  final int codEmpresa;
  final CargoEntity? cargoPadre; // Padre predefinido (null = raíz)
  final Function(CargoEditData) onGuardar;

  const _CrearCargoDialog({
    required this.codEmpresa,
    this.cargoPadre,
    required this.onGuardar,
  });

  @override
  ConsumerState<_CrearCargoDialog> createState() => _CrearCargoDialogState();
}

class _CrearCargoDialogState extends ConsumerState<_CrearCargoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  late final TextEditingController _posicionController;
  late bool _esRaiz; // Determinado por si hay padre predefinido
  int? _nivelJerarquicoSeleccionado; // Nivel jerárquico seleccionado

  // 🔄 Sugerencias de cargos REALES inactivos similares
  List<CargoEntity> _cargosInactivosSimilares = [];

  @override
  void initState() {
    super.initState();
    // Si hay padre predefinido, NO es raíz
    _esRaiz = widget.cargoPadre == null;

    // Inicializar posición con la del padre si existe, sino con 1
    final posicionInicial = widget.cargoPadre?.posicion.toString() ?? '1';
    _posicionController = TextEditingController(text: posicionInicial);

    // 🔄 Listener para buscar cargos similares mientras el usuario escribe
    _nombreController.addListener(_buscarCargosSimilares);
  }

  // 🔄 Buscar cargos REALES inactivos con nombres similares
  void _buscarCargosSimilares() {
    final query = _nombreController.text.trim().toLowerCase();

    // Solo buscar si hay al menos 3 caracteres
    if (query.length < 3) {
      setState(() {
        _cargosInactivosSimilares = [];
      });
      return;
    }

    // Obtener todos los cargos de la empresa
    final cargosAsync = ref.read(cargosXEmpresaProvider(widget.codEmpresa));
    final cargosJerarquicos = cargosAsync.value ?? [];

    // Aplanar la jerarquía
    List<CargoEntity> todosLosCargos = [];
    void aplanar(List<CargoEntity> lista) {
      for (var cargo in lista) {
        todosLosCargos.add(cargo);
        if (cargo.items.isNotEmpty) {
          aplanar(cargo.items);
        }
      }
    }

    aplanar(cargosJerarquicos);

    // Filtrar: Solo cargos REALES (no ficticios) Y INACTIVOS (estado==0)
    final similares =
        todosLosCargos
            .where((cargo) {
              final esFicticio =
                  cargo.descripcion.contains('[Ficticio') ||
                  cargo.descripcion.toLowerCase().contains('ficticio');
              final esRealInactivo = !esFicticio && cargo.estado == 0;
              final nombreCoincide = cargo.descripcion.toLowerCase().contains(
                query,
              );
              return esRealInactivo && nombreCoincide;
            })
            .take(5)
            .toList(); // Máximo 5 sugerencias

    setState(() {
      _cargosInactivosSimilares = similares;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _posicionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color:
                        widget.cargoPadre != null
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cargoPadre != null
                              ? 'Crear Cargo Hijo'
                              : 'Crear Nuevo Cargo',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (widget.cargoPadre != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Padre: ${widget.cargoPadre!.descripcion}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cargo *',
                  hintText: 'Ej: Gerente de Ventas',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (value.trim().length < 3) {
                    return 'Mínimo 3 caracteres';
                  }
                  return null;
                },
                maxLength: 100,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),

              // 🔄 Sugerencias de cargos REALES inactivos similares
              if (_cargosInactivosSimilares.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cargos inactivos similares encontrados:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...(_cargosInactivosSimilares.map((cargo) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          elevation: 0,
                          color: Colors.white,
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.warning_amber,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            title: Text(
                              cargo.descripcion,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              'Cód: ${cargo.codCargo} | Nivel: ${cargo.nivel} | Pos: ${cargo.posicion}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Activar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onPressed: () {
                                _confirmarActivarCargo(cargo);
                              },
                            ),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 4),
                      Text(
                        'Sugerencia: Si existe un cargo similar, actívalo en lugar de crear uno nuevo.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Posición
              TextFormField(
                controller: _posicionController,
                decoration: InputDecoration(
                  labelText: 'Posición *',
                  hintText:
                      widget.cargoPadre != null
                          ? 'Mínimo: ${widget.cargoPadre!.posicion}'
                          : '1',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.format_list_numbered),
                  helperText:
                      widget.cargoPadre != null
                          ? 'Debe ser >= ${widget.cargoPadre!.posicion} (posición del padre)'
                          : null,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La posición es obligatoria';
                  }
                  final pos = int.tryParse(value);
                  if (pos == null || pos < 1) {
                    return 'Debe ser un número mayor a 0';
                  }

                  // Validar que la posición sea >= a la del padre
                  if (widget.cargoPadre != null &&
                      pos < widget.cargoPadre!.posicion) {
                    return 'Debe ser >= ${widget.cargoPadre!.posicion} (posición del padre)';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 🆕 Dropdown de Nivel Jerárquico
              Consumer(
                builder: (context, ref, _) {
                  final nivelesAsync = ref.watch(nivelesJerarquicosProvider);

                  return nivelesAsync.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, _) => Text(
                          'Error: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                    data: (niveles) {
                      if (niveles.isEmpty) {
                        return const Text(
                          'No hay niveles jerárquicos disponibles',
                        );
                      }

                      return DropdownButtonFormField<int>(
                        value: _nivelJerarquicoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Nivel Jerárquico *',
                          hintText: 'Selecciona el nivel',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.stairs),
                        ),
                        items:
                            niveles.where((n) => n.activo == 1).map((nivel) {
                              return DropdownMenuItem<int>(
                                value: nivel.codNivel,
                                child: Text(
                                  'Nivel ${nivel.nivel} - Bs. ${nivel.haberBasico.toStringAsFixed(0)}',
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _nivelJerarquicoSeleccionado = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Debes seleccionar un nivel jerárquico';
                          }
                          return null;
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Tipo de cargo (solo si NO hay padre predefinido)
              if (widget.cargoPadre == null) ...[
                CheckboxListTile(
                  value: _esRaiz,
                  onChanged: (value) {
                    setState(() {
                      _esRaiz = value ?? true;
                    });
                  },
                  title: const Text('Cargo Raíz'),
                  subtitle: const Text(
                    'El cargo no tendrá padre (cargo de nivel superior)',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                if (!_esRaiz) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Para asignar un padre, usa "Reparentar" después de crear el cargo',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              // Info cuando hay padre predefinido
              if (widget.cargoPadre != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_tree,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este cargo será hijo de: ${widget.cargoPadre!.descripcion}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.save),
                    label: const Text('Crear Cargo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      // Determinar el padre:
      // 1. Si hay padre predefinido -> usar el codCargo del padre (que será el padre de este nuevo cargo)
      // 2. Si es raíz -> 0
      final codPadre =
          widget.cargoPadre != null ? widget.cargoPadre!.codCargo : 0;

      final data = CargoEditData(
        codCargo: 0, // 0 = nuevo
        nuevoNombre: _nombreController.text.trim(),
        nuevoEstado: 1, // Activo por defecto
        nuevaPosicion: int.parse(_posicionController.text),
        nuevoCargoPadre: codPadre,
        nuevoNivelJerarquico: _nivelJerarquicoSeleccionado,
        esNuevo: true,
      );

      widget.onGuardar(data);
      Navigator.of(context).pop();
    }
  }

  // 🔄 Confirmar y activar un cargo REAL inactivo
  void _confirmarActivarCargo(CargoEntity cargo) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Expanded(child: Text('Activar Cargo Existente')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Se encontró un cargo inactivo con este nombre:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nombre: ${cargo.descripcion}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Código: ${cargo.codCargo}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Nivel: ${cargo.nivel}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Posición: ${cargo.posicion}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      Text(
                        'Padre: ${cargo.codCargoPadre}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '¿Deseas activar este cargo en lugar de crear uno nuevo?',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Activar Cargo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.of(context).pop(); // Cerrar confirmación
                  Navigator.of(context).pop(); // Cerrar diálogo de crear

                  // Activar el cargo (cambiar estado a 1)
                  try {
                    final codUsuario =
                        await ref.read(userProvider.notifier).getCodUsuario();

                    // Crear objeto CargoEntity actualizado con estado = 1
                    final cargoActivado = CargoEntity(
                      codCargo: cargo.codCargo,
                      codCargoPadre: cargo.codCargoPadre,
                      descripcion: cargo.descripcion,
                      nivel: cargo.nivel,
                      posicion: cargo.posicion,
                      codEmpresa: cargo.codEmpresa,
                      estado: 1, // ✅ Activar
                      sucursal: cargo.sucursal,
                      sucursalPlanilla: cargo.sucursalPlanilla,
                      nombreEmpresa: cargo.nombreEmpresa,
                      nombreEmpresaPlanilla: cargo.nombreEmpresaPlanilla,
                      codEmpresaPlanilla: cargo.codEmpresaPlanilla,
                      codCargoPlanilla: cargo.codCargoPlanilla,
                      descripcionPlanilla: cargo.descripcionPlanilla,
                      codNivel: cargo.codNivel,
                      audUsuario: codUsuario,
                      tieneEmpleadosActivos: cargo.tieneEmpleadosActivos,
                      tieneEmpleadosTotales: cargo.tieneEmpleadosTotales,
                      estaAsignadoSucursal: cargo.estaAsignadoSucursal,
                      canDeactivate: cargo.canDeactivate,
                      numDependientes: cargo.numDependientes,
                      numDependenciasTotales: cargo.numDependenciasTotales,
                      numDependenciasCompletas: cargo.numDependenciasCompletas,
                      numDeDependencias: cargo.numDeDependencias,
                      numHijosActivos: cargo.numHijosActivos,
                      numHijosTotal: cargo.numHijosTotal,
                      resumenCompleto: cargo.resumenCompleto,
                      estadoPadre: cargo.estadoPadre,
                      esVisible: cargo.esVisible,
                      items: cargo.items,
                      codCargoPadreOriginal: cargo.codCargoPadreOriginal,
                      codEmpleado: cargo.codEmpleado,
                      nombreCompleto: cargo.nombreCompleto,
                    );

                    final repository = ref.read(rrhhRepositoryProvider);
                    final success = await repository.registrarCargo(
                      cargoActivado,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();

                      if (success) {
                        // Refrescar lista
                        ref.invalidate(
                          cargosXEmpresaProvider(widget.codEmpresa),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Cargo "${cargo.descripcion}" activado exitosamente',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Error al activar el cargo'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error al activar cargo: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }
}

// =============================================================================
// DIALOG DE DETALLES DEL CARGO CON TABS
// =============================================================================
class _CargoDetailsDialog extends StatelessWidget {
  final CargoEntity cargo;
  final bool isMobile;
  final IconData Function(CargoEntity) getStatusIcon;

  const _CargoDetailsDialog({
    required this.cargo,
    required this.isMobile,
    required this.getStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    cargo.estado == 1
                        ? Colors.blue.shade50
                        : Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          cargo.tieneEmpleadosActivos > 0
                              ? Colors.green.shade100
                              : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      getStatusIcon(cargo),
                      color:
                          cargo.tieneEmpleadosActivos > 0
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cargo.descripcion,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    cargo.estado == 1
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                cargo.estado == 1 ? 'ACTIVO' : 'INACTIVO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      cargo.estado == 1
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Código: ${cargo.codCargo}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Contenido
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: Información básica
                    _buildSectionCard(
                      'Información Básica',
                      Icons.info,
                      Colors.blue,
                      [
                        _buildInfoRow('Código', '${cargo.codCargo}'),
                        _buildInfoRow('Nivel Jerárquico', '${cargo.codNivel}'),
                        _buildInfoRow('Posición', '${cargo.posicion}'),
                        _buildInfoRow(
                          'Estado',
                          cargo.estado == 1 ? 'Activo' : 'Inactivo',
                        ),
                        _buildInfoRow(
                          'Puede desactivarse',
                          cargo.canDeactivate == 1 ? 'Sí' : 'No',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sección: Empleados
                    _buildSectionCard('Empleados', Icons.people, Colors.green, [
                      _buildInfoRow(
                        'Empleados activos',
                        '${cargo.tieneEmpleadosActivos}',
                      ),
                      _buildInfoRow(
                        'Empleados totales',
                        '${cargo.tieneEmpleadosTotales}',
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Sección: Jerarquía
                    _buildSectionCard(
                      'Jerarquía',
                      Icons.account_tree,
                      Colors.purple,
                      [
                        _buildInfoRow(
                          'Cargos hijos activos',
                          '${cargo.numHijosActivos} de ${cargo.numHijosTotal}',
                        ),
                        _buildInfoRow(
                          'Dependencias',
                          '${cargo.numDependientes}',
                        ),
                        _buildInfoRow(
                          'Dependencias totales',
                          '${cargo.numDependenciasTotales}',
                        ),
                        _buildInfoRow('Estado padre', cargo.estadoPadre),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Resumen
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.summarize,
                                size: 18,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Resumen',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cargo.resumenCompleto,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BOTTOM SHEET DE EMPLEADOS POR CARGO
// =============================================================================
class _EmpleadosBottomSheet extends ConsumerStatefulWidget {
  final CargoEntity cargo;
  final int codEmpresa;

  const _EmpleadosBottomSheet({required this.cargo, required this.codEmpresa});

  @override
  ConsumerState<_EmpleadosBottomSheet> createState() =>
      _EmpleadosBottomSheetState();
}

class _EmpleadosBottomSheetState extends ConsumerState<_EmpleadosBottomSheet> {
  @override
  void initState() {
    super.initState();
    // Forzar recarga de datos al abrir el bottom sheet
    Future.microtask(() {
      ref.invalidate(empleadosXCargoProvider(widget.cargo.codCargo));
    });
  }

  @override
  Widget build(BuildContext context) {
    final empleadosAsync = ref.watch(
      empleadosXCargoProvider(widget.cargo.codCargo),
    );
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.7,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          // Handle del bottom sheet
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.people,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Empleados Activos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.cargo.descripcion,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Contador
                empleadosAsync.when(
                  loading:
                      () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  error:
                      (_, __) => Icon(Icons.error, color: Colors.red.shade400),
                  data: (empleados) {
                    // Filtrar solo empleados activos
                    final activos =
                        empleados.where((e) => e.estado == 1).toList();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${activos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.green.shade700),
                  onPressed: () {
                    ref
                        .read(
                          empleadosXCargoProvider(
                            widget.cargo.codCargo,
                          ).notifier,
                        )
                        .refresh();
                  },
                  tooltip: 'Refrescar',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Lista de empleados
          Expanded(
            child: empleadosAsync.when(
              loading:
                  () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Cargando empleados...'),
                      ],
                    ),
                  ),
              error:
                  (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Error al cargar empleados',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref
                                  .read(
                                    empleadosXCargoProvider(
                                      widget.cargo.codCargo,
                                    ).notifier,
                                  )
                                  .refresh();
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
              data: (empleados) {
                // Filtrar solo empleados activos
                final empleadosActivos =
                    empleados.where((e) => e.estado == 1).toList();

                if (empleadosActivos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_off,
                              size: 48,
                              color: Colors.orange.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin Empleados Activos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Este cargo no tiene empleados activos actualmente.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: empleadosActivos.length,
                  itemBuilder: (context, index) {
                    final empleado = empleadosActivos[index];
                    return _buildEmpleadoItem(empleado);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpleadoItem(CargoEntity empleado) {
    final iniciales = _getInicialesEmpleado(empleado.nombreCompleto);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade100),
      ),
      child: InkWell(
        onTap: () => _showEmpleadoDetalle(empleado),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar con foto
              GestureDetector(
                onTap:
                    () => _mostrarFotoCompleta(
                      context,
                      empleado.codEmpleado,
                      empleado.nombreCompleto,
                    ),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _getImageUrl(empleado.codEmpleado),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              iniciales,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empleado.nombreCompleto,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Sucursal
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            empleado.sucursal.isNotEmpty
                                ? empleado.sucursal
                                : 'Sin sucursal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Empresa
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            empleado.nombreEmpresa.isNotEmpty
                                ? empleado.nombreEmpresa
                                : 'Sin empresa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Indicador activo
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInicialesEmpleado(String nombreCompleto) {
    if (nombreCompleto.isEmpty) return '?';
    final partes =
        nombreCompleto.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) {
      final parte = partes[0];
      if (parte.isEmpty) return '?';
      return parte.substring(0, parte.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
  }

  void _showEmpleadoDetalle(CargoEntity empleado) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: Colors.green.shade700),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Detalle del Empleado',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar grande con foto
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _mostrarFotoCompleta(
                        context,
                        empleado.codEmpleado,
                        empleado.nombreCompleto,
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          _getImageUrl(empleado.codEmpleado),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade700,
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade700,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getInicialesEmpleado(
                                    empleado.nombreCompleto,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    empleado.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ACTIVO',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildDetalleRow(
                    Icons.badge,
                    'Código',
                    '${empleado.codEmpleado}',
                  ),
                  _buildDetalleRow(Icons.work, 'Cargo', empleado.descripcion),
                  _buildDetalleRow(
                    Icons.location_city,
                    'Sucursal',
                    empleado.sucursal.isNotEmpty
                        ? empleado.sucursal
                        : 'No asignada',
                  ),
                  _buildDetalleRow(
                    Icons.business,
                    'Empresa',
                    empleado.nombreEmpresa.isNotEmpty
                        ? empleado.nombreEmpresa
                        : 'No asignada',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetalleRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Obtener URL de imagen del empleado
  String _getImageUrl(int codEmpleado) {
    return '${AppConstants.baseUrl}${AppConstants.getImageUrl}/$codEmpleado.jpg';
  }

  // Mostrar foto completa del empleado
  void _mostrarFotoCompleta(
    BuildContext context,
    int codEmpleado,
    String nombreCompleto,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con nombre
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nombreCompleto,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Imagen
                  Flexible(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        _getImageUrl(codEmpleado),
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 300,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.green.shade600,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            color: Colors.grey.shade100,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Imagen no disponible',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
