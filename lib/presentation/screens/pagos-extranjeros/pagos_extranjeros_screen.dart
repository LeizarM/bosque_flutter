import 'package:bosque_flutter/core/utils/responsive_utils_bosque.dart';
import 'package:bosque_flutter/presentation/screens/pagos-extranjeros/pagos_extranjeros_list_screen.dart';
import 'package:bosque_flutter/presentation/screens/pagos-extranjeros/pagos_extranjeros_register_screen.dart';
import 'package:flutter/material.dart';

class PagosExtranjerosScreen extends StatefulWidget {
  const PagosExtranjerosScreen({super.key});

  @override
  State<PagosExtranjerosScreen> createState() => _PagosExtranjerosScreenState();
}

class _PagosExtranjerosScreenState extends State<PagosExtranjerosScreen> {
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    PagosExtranjerosRegisterScreen(),
    PagosExtranjerosListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = ResponsiveUtilsBosque.isMobile(context);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined, size: 22, color: cs.primary),
            const SizedBox(width: 10),
            const Text(
              'Pagos al Extranjero',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 8,
            ),
            child: SizedBox(
              width: isMobile ? double.infinity : 360,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Nueva solicitud'),
                    icon: Icon(Icons.add_circle_outline_rounded, size: 18),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Mis solicitudes'),
                    icon: Icon(Icons.list_alt_rounded, size: 18),
                  ),
                ],
                selected: {_selectedIndex},
                onSelectionChanged:
                    (v) => setState(() => _selectedIndex = v.first),
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
    );
  }
}
