import 'package:bosque_flutter/presentation/widgets/ventas/venta_articulos_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:bosque_flutter/core/state/user_provider.dart';
import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';


class VentasHomeScreen extends ConsumerStatefulWidget {
  const VentasHomeScreen({super.key});

  @override
  ConsumerState<VentasHomeScreen> createState() => _VentasHomeScreenState();
}

class _VentasHomeScreenState extends ConsumerState<VentasHomeScreen> {
  int _codCiudad = 0; // Inicializamos con un valor por defecto

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() async {
        _codCiudad = await ref.read(userProvider.notifier).getCodCiudad();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No usamos appBar aquí porque ya lo tiene el DashboardScreen como contenedor
      body: ResponsiveBreakpoints(
        breakpoints: ResponsiveUtilsBosque.breakpoints,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del módulo de ventas
            Padding(
              padding: EdgeInsets.all(ResponsiveUtilsBosque.getHorizontalPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lista de Artículos',
                    style: ResponsiveUtilsBosque.getTitleStyle(context),
                  ),
                  SizedBox(
                    height: ResponsiveUtilsBosque.getResponsiveValue<double>(
                      context: context, 
                      defaultValue: 8.0,
                      desktop: 12.0,
                    ),
                  ),
                  Text(
                    'Catálogo de productos disponibles',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      fontSize: ResponsiveUtilsBosque.getResponsiveValue<double>(
                        context: context,
                        defaultValue: 14.0,
                        desktop: 16.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal: Lista de artículos
            Expanded(child: VentasArticulosView(codCiudad: _codCiudad)),
          ],
        ),
      ),
    );
  }
}
