import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/sucursal_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SucursalesScreen extends ConsumerWidget {
  final int codEmpresa;
  final String nombreEmpresa;

  const SucursalesScreen({
    super.key,
    required this.codEmpresa,
    required this.nombreEmpresa,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sucursalesAsync = ref.watch(sucursalesProvider(codEmpresa));

    return Scaffold(
      appBar: AppBar(
        title: Text('Sucursales - $nombreEmpresa'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'nueva':
                  _showNuevaSucursalDialog(context);
                  break;
                case 'editar':
                  // TODO: Implementar edición de sucursal
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Función no implementada')),
                  );
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'nueva',
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('Nueva Sucursal'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar Sucursal'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: sucursalesAsync.when(
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
                        () => ref.invalidate(sucursalesProvider(codEmpresa)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
        data: (sucursales) => _buildSucursalesList(context, sucursales),
      ),
    );
  }

  Widget _buildSucursalesList(
    BuildContext context,
    List<SucursalEntity> sucursales,
  ) {
    if (sucursales.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay sucursales registradas'),
          ],
        ),
      );
    }

    return ResponsiveUtilsBosque.isMobile(context)
        ? _buildMobileLayout(sucursales)
        : _buildDesktopLayout(sucursales);
  }

  Widget _buildMobileLayout(List<SucursalEntity> sucursales) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sucursales.length,
      itemBuilder: (context, index) {
        final sucursal = sucursales[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.store, color: Colors.blue),
            title: Text(
              sucursal.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ciudad: ${sucursal.nombreCiudad}'),
                Text('Código: ${sucursal.codSucursal}'),
              ],
            ),
            onTap: () => _showSucursalDetails(context, sucursal),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(List<SucursalEntity> sucursales) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 2.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: sucursales.length,
      itemBuilder: (context, index) {
        final sucursal = sucursales[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sucursal.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Ciudad: ${sucursal.nombreCiudad}'),
                const SizedBox(height: 4),
                Text('Código: ${sucursal.codSucursal}'),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => _showSucursalDetails(context, sucursal),
                    child: const Text('Ver detalles'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNuevaSucursalDialog(BuildContext context) {
    // TODO: Implementar diálogo para nueva sucursal
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Función no implementada')));
  }

  void _showSucursalDetails(BuildContext context, SucursalEntity sucursal) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.store, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text(sucursal.nombre)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código: ${sucursal.codSucursal}'),
                Text('Empresa: ${sucursal.empresa.nombre}'),
                Text('Ciudad: ${sucursal.nombreCiudad}'),
                Text('Código Ciudad: ${sucursal.codCiudad}'),
                Text('Usuario Auditoría: ${sucursal.audUsuarioI}'),
              ],
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
}
