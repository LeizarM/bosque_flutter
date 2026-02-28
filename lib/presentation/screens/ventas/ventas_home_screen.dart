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
  int _codCiudad = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarPantalla();
    });
  }

  void _inicializarPantalla() async {
    _codCiudad = await ref.read(userProvider.notifier).getCodCiudad();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBreakpoints(
        breakpoints: ResponsiveUtilsBosque.breakpoints,
        child: VentasArticulosView(codCiudad: _codCiudad),
      ),
    );
  }
}
