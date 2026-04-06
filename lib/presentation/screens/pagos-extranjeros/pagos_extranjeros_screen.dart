import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/screens/pagos-extranjeros/pagos_extranjeros_list_screen.dart';
import 'package:bosque_flutter/presentation/screens/pagos-extranjeros/pagos_extranjeros_register_screen.dart';
import 'package:flutter/material.dart';

class PagosExtranjerosScreen extends StatelessWidget {
  const PagosExtranjerosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = ResponsiveUtilsBosque.isDesktop(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLow,
        appBar: AppBar(
          title: const Text(
            'Pagos al Extranjero',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor:
              isDesktop ? colorScheme.primaryContainer : colorScheme.surface,
          foregroundColor:
              isDesktop
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: colorScheme.primary,
            labelColor:
                isDesktop
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.primary,
            unselectedLabelColor:
                isDesktop
                    ? colorScheme.onPrimaryContainer.withValues(alpha: 0.6)
                    : colorScheme.onSurfaceVariant,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(
                icon: Icon(Icons.add_circle_outline_rounded, size: 20),
                text: 'Registro',
              ),
              Tab(
                icon: Icon(Icons.list_alt_rounded, size: 20),
                text: 'Consulta',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PagosExtranjerosRegisterScreen(),
            PagosExtranjerosListScreen(),
          ],
        ),
      ),
    );
  }
}
