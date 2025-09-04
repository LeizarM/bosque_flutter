/*import 'dart:async';
import 'package:billing/application/auth/local_storage_service.dart';
import 'package:billing/application/lista-ficha-trabajador/empleado_dependientes_service.dart';
import 'package:billing/domain/listar-ficha-trabajador/empleado.dart';
import 'package:billing/presentation/lista-ficha-trabajador/DependienteScreen.dart';
import 'package:billing/presentation/lista-ficha-trabajador/infoEmpleado.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billing/main.dart';



class EmpleadosDependientesView extends StatefulWidget {
  @override
  EmpleadosDependientesViewState createState() =>
      EmpleadosDependientesViewState();
}

class EmpleadosDependientesViewState extends State<EmpleadosDependientesView> {
  static final ValueNotifier<int> imageVersion = ValueNotifier(0);
  int _imageTimestamp = DateTime.now().millisecondsSinceEpoch;
  bool _notificacionesCumple = false;
  final ObtenerEmpDepService _service = ObtenerEmpDepService();
  late Future<List<Empleado>> _futureEmpleados;

  List<Map<String, dynamic>> _empleado = [];
  
  
  final LocalStorageService _localStorageService = LocalStorageService();
  //variables buscador
  String _searchTerm = ""; //_searchTerm como una cadena vacía.
  List<Empleado> _allEmployees = [];// Lista vacía para almacenar los empleados obtenidos del FutureBuilder.

  @override
  void initState() {
    super.initState();
    _futureEmpleados = _service.obtenerListaEmpleadoyDependientes();// Llama al backend
    
  }
 



  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        'Empleados y Dependientes',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      centerTitle: true,
    ),
    body: Column(
      children: [
    
        // Nuevo buscador: Se coloca en la parte superior y actualiza _searchTerm en tiempo real.
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar empleado por nombre o código',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Empleado>>(
            future: _futureEmpleados,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData) {
                // Almacenamos la lista completa solo una vez
                if (_allEmployees.isEmpty) {
                  _allEmployees = snapshot.data!;
                }
                // Si hay texto en el buscador, filtramos la lista
                List<Empleado> displayedEmployees = _searchTerm.isEmpty
                    ? _allEmployees
                    : _allEmployees.where((empleado) {
                        // Convertimos a minúsculas para una búsqueda case-insensitive
                        final nombre = empleado.persona?.datoPersona?.toLowerCase() ?? '';
                        final codigo = empleado.codEmpleado?.toString() ?? '';
                        return nombre.contains(_searchTerm.toLowerCase()) ||
                            codigo.contains(_searchTerm);
                      }).toList();
                if (displayedEmployees.isEmpty) {
                  return const Center(child: Text('No hay empleados para mostrar.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: displayedEmployees.length,
                  itemBuilder: (context, index) {
                    final empleado = displayedEmployees[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: _buildEmpleadoAvatar(empleado.codEmpleado!),
                        title: Text(
                          empleado.persona?.datoPersona ?? 'Nombre no disponible',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        // Subtitle reorganizado en dos filas: Cargo & Dependientes, Empresa & Sucursal.
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Primera fila: Cargo y Dependientes
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Cargo: ${empleado.empleadoCargo?.cargoSucursal?.cargo?.descripcion ?? "N/A"}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Dependientes: ${empleado.dependiente?.codEmpleado ?? ""}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Segunda fila: Empresa y Sucursal
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Empresa: ${empleado.empresa?.nombre ?? ""}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Sucursal: ${empleado.sucursal?.nombre ?? ""}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.group, color: Colors.teal, size: 20),
                              tooltip: 'Dependientes',
                              onPressed: () {
                                print('Navegando con codEmpleado: ${empleado.codEmpleado}');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DependienteScreen(
                                      codEmpleado: empleado.codEmpleado!,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.info, color: Colors.teal, size: 20),
                              tooltip: 'Información empleado',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InfoEmpleadoScreen(
                                      codEmpleado: empleado.codEmpleado!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: Text('No hay empleados para mostrar.'));
              }
            },
          ),
        ),
      ],
    ),
  );
}

 /* void _mostrarDetallesEmp(BuildContext context, Empleado empleadoSeleccionado) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InfoEmpleadoScreen(
          codEmpleado: empleadoSeleccionado.codEmpleado!
        ),
      ),
    );
  }*/
  // Primero, modifica el método _buildEmpleadoAvatar
Widget _buildEmpleadoAvatar(int codEmpleado) {
  return ValueListenableBuilder(
    valueListenable: imageVersion,
    builder: (context, _, __) {
      return Hero(
        tag: 'empleado-imagen-$codEmpleado',
        child: GestureDetector(
          onTap: () => _mostrarImagenCompleta(context, codEmpleado),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(
              getImageUrl(codEmpleado),
            ),
            onBackgroundImageError: (_, __) {},
          ),
        ),
      );
    },
  );
}

// Actualizar el método getImageUrl para usar una variable observable
String getImageUrl(int codEmpleado) {
  return "http://localhost:9223/fichaTrabajador/uploads/img/$codEmpleado.jpg?timestamp=${DateTime.now().millisecondsSinceEpoch}";
}
// Método para refrescar la imagen cuando se necesite
void refreshImage() {
  setState(() {
    _imageTimestamp = DateTime.now().millisecondsSinceEpoch;
    imageVersion.value++;
  });
}
// Agrega este nuevo método para mostrar la imagen completa
void _mostrarImagenCompleta(BuildContext context, int codEmpleado) {
  showDialog(
    context: context,
    barrierDismissible: true, // Permite cerrar tocando fuera de la imagen
    barrierColor: Colors.black87, // Fondo más oscuro y elegante
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Hero(
                tag: 'empleado-imagen-$codEmpleado',
                child: Image.network(
                  getImageUrl(codEmpleado),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'Error al cargar la imagen',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
}*/




