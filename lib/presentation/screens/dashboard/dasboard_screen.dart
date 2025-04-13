import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/secure_storage.dart';
import 'package:bosque_flutter/presentation/widgets/shared/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override  
  Widget build(BuildContext context, WidgetRef ref) {  
    final user = ref.watch(userProvider);  
    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET);  
  
    return Scaffold(  
      appBar: AppBar(  
        title: const Text('Dashboard'),  
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(userProvider.notifier).clearUser();  
              context.go('/login');
            },
          ),
        ],
      ),
        
      drawer: isSmallScreen ? const AppSidebar() : null,  
      body: Row(  
        children: [  
          if (!isSmallScreen) const AppSidebar(),  
          Expanded(  
            child: Center(  
              child: user != null  
                  ? Column(  
                      mainAxisAlignment: MainAxisAlignment.center,  
                      children: [  
                        Text(  
                          'Bienvenido, ${user.nombreCompleto}',  
                          style: Theme.of(context).textTheme.headlineMedium,  
                        ),  
                        const SizedBox(height: 16),  
                        Text(  
                          'Cargo: ${user.cargo}',  
                          style: Theme.of(context).textTheme.bodyLarge,  
                        ),  
                        Text(  
                          'Tipo de Usuario: ${user.tipoUsuario}',  
                          style: Theme.of(context).textTheme.bodyLarge,  
                        ),  
                      ],  
                    )  
                  : const Text('No hay datos de usuario disponibles'),  
            ),  
          ),  
        ],  
      ),  
    );
  }
}
