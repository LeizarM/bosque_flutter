import 'package:flutter/material.dart';
import 'package:bosque_flutter/presentation/screens/control-combustible-maquina-montacarga/control_combustible_dashboard_screen.dart';
import 'package:bosque_flutter/presentation/screens/control-combustible-maquina-montacarga/control_combustible_maquina_montacarga_view_screen.dart';

class ControlCombustibleMainScreen extends StatefulWidget {
  const ControlCombustibleMainScreen({super.key});

  @override
  State<ControlCombustibleMainScreen> createState() => _ControlCombustibleMainScreenState();
}

class _ControlCombustibleMainScreenState extends State<ControlCombustibleMainScreen> {
  int _selectedIndex = 0;

  // Lista de pantallas: Dashboard (0) y Reportes (1)
  final List<Widget> _screens = const [
    ControlCombustibleDashboardScreen(),
    ControlCombustibleMaquinaMontaCargaViewScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: colorScheme.surface,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Reportes',
            ),
          ],
        ),
      ),
    );
  }
}
