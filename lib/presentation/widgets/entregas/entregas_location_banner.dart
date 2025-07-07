import 'package:flutter/material.dart';

class EntregasLocationBanner extends StatelessWidget {
  final bool isLocationEnabled;
  final VoidCallback onVerifyPermissions;

  const EntregasLocationBanner({
    super.key,
    required this.isLocationEnabled,
    required this.onVerifyPermissions,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocationEnabled) return const SizedBox.shrink();
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.errorContainer,
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            '⚠️ La ubicación está desactivada',
            style: TextStyle(
              color: colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Active la ubicación para utilizar esta funcionalidad',
            style: TextStyle(color: colorScheme.onErrorContainer),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onVerifyPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.surfaceBright,
            ),
            child: const Text('Verificar permisos'),
          ),
        ],
      ),
    );
  }
}