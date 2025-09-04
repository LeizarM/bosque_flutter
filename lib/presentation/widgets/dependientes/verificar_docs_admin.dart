import 'package:flutter/material.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';

class VerificarDocsAdminWidget extends StatelessWidget {
  final List<Map<String, dynamic>> imagenesPendientes;
  final void Function(Map<String, dynamic> item)? onAprobar;
  final void Function(Map<String, dynamic> item)? onRechazar;

  const VerificarDocsAdminWidget({
    super.key,
    required this.imagenesPendientes,
    this.onAprobar,
    this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    if (isMobile) {
      // En móvil, solo muestra un botón que abre el dialog
      return IconButton(
        icon: const Icon(Icons.notifications),
        tooltip: 'Ver imágenes pendientes',
        onPressed: () => _showPendientesDialog(context),
      );
    } else {
      // En web/desktop, muestra un DropdownButton con las notificaciones
      return DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          icon: const Icon(Icons.notifications),
          hint: const Text('Pendientes'),
          items: imagenesPendientes.map((item) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: item,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: item['imagen'],
                  radius: 18,
                ),
                title: Text(item['nombreEmpleado'] ?? ''),
                subtitle: Text(item['documento'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Aprobar',
                      onPressed: onAprobar != null ? () => onAprobar!(item) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Rechazar',
                      onPressed: onRechazar != null ? () => onRechazar!(item) : null,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (_) {},
        ),
      );
    }
  }

  void _showPendientesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 350,
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Imágenes pendientes de aprobación',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: imagenesPendientes.isEmpty
                    ? const Center(child: Text('No hay imágenes pendientes.'))
                    : ListView.builder(
                        itemCount: imagenesPendientes.length,
                        itemBuilder: (context, index) {
                          final item = imagenesPendientes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: item['imagen'],
                                radius: 24,
                              ),
                              title: Text(item['nombreEmpleado'] ?? ''),
                              subtitle: Text(item['documento'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    tooltip: 'Aprobar',
                                    onPressed: onAprobar != null ? () => onAprobar!(item) : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    tooltip: 'Rechazar',
                                    onPressed: onRechazar != null ? () => onRechazar!(item) : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}