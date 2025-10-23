import 'package:bosque_flutter/core/state/rrhh_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/domain/entities/empresa_entity.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/cargos_screen.dart';
import 'package:bosque_flutter/presentation/screens/estructura-organizacional/sucursales_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EstructuraOrganizacionalEmpresaScreen extends ConsumerWidget {
  const EstructuraOrganizacionalEmpresaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empresasAsync = ref.watch(empresasProvider);
    final selectedEmpresa = ref.watch(selectedEmpresaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empresas'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'nueva':
                  _showNuevaEmpresaDialog(context);
                  break;
                case 'editar':
                  if (selectedEmpresa != null) {
                    _showEditarEmpresaDialog(context, selectedEmpresa);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecciona una empresa primero'),
                      ),
                    );
                  }
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
                        Text('Nueva Empresa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Editar Empresa'),
                      ],
                    ),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(empresasProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtilsBosque.getHorizontalPadding(context),
          vertical: ResponsiveUtilsBosque.getVerticalPadding(context),
        ),
        child: Column(
          children: [
            Expanded(
              child: empresasAsync.when(
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
                            onPressed: () {
                              ref.read(empresasProvider.notifier).refresh();
                            },
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                data: (empresas) => _buildEmpresasList(context, empresas, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpresasList(
    BuildContext context,
    List<EmpresaEntity> empresas,
    WidgetRef ref,
  ) {
    if (ResponsiveUtilsBosque.isMobile(context)) {
      return ListView.builder(
        itemCount: empresas.length,
        itemBuilder: (context, index) {
          final empresa = empresas[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(child: Text(empresa.nombre[0])),
              title: Text(empresa.nombre),
              subtitle:
                  empresa.sigla.isNotEmpty
                      ? Text('Sigla: ${empresa.sigla}')
                      : null,
              onTap: () {
                ref
                    .read(selectedEmpresaProvider.notifier)
                    .selectEmpresa(empresa);
                _showEmpresaActionsBottomSheet(context, empresa);
              },
            ),
          );
        },
      );
    } else {
      // Desktop/Web: GridView mejorado
      final gridDimensions = ResponsiveUtilsBosque.getGridDimensions(context);
      return GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridDimensions.crossAxisCount,
          childAspectRatio: 1.8, // Más ancho para mejor presentación
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
        ),
        itemCount: empresas.length,
        itemBuilder: (context, index) {
          final empresa = empresas[index];
          return Card(
            elevation: 2,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                ref
                    .read(selectedEmpresaProvider.notifier)
                    .selectEmpresa(empresa);
                _showEmpresaActionsBottomSheet(context, empresa);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.white],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                empresa.nombre[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  empresa.nombre,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (empresa.sigla.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      empresa.sigla,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ver detalles',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  void _showEmpresaActionsBottomSheet(
    BuildContext context,
    EmpresaEntity empresa,
  ) {
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
              // Header simple
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.business, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        empresa.nombre,
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

              // Botones de acción simples
              ListTile(
                leading: const Icon(Icons.work_outline),
                title: const Text('Ver Cargos y Organigrama'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => CargosScreen(
                            codEmpresa: empresa.codEmpresa,
                            nombreEmpresa: empresa.nombre,
                          ),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: const Text('Sucursales'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pop();
                  // Navigate to sucursales
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => SucursalesScreen(
                            codEmpresa: empresa.codEmpresa,
                            nombreEmpresa: empresa.nombre,
                          ),
                    ),
                  );
                },
              ),

              const Divider(height: 8),

              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar empresa'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).pop();
                  _showEditarEmpresaDialog(context, empresa);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNuevaEmpresaDialog(BuildContext context) {
    // TODO: Implementar diálogo para nueva empresa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función Nueva Empresa - próximamente')),
    );
  }

  void _showEditarEmpresaDialog(BuildContext context, EmpresaEntity empresa) {
    // TODO: Implementar diálogo para editar empresa
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Función Editar Empresa para ${empresa.nombre} - próximamente',
        ),
      ),
    );
  }
}
