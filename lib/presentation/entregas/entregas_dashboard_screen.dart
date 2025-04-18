import 'package:bosque_flutter/presentation/widgets/entregas/entregas_dashboard_content.dart';
import 'package:bosque_flutter/presentation/widgets/entregas/entregas_por_chofer_content.dart';
import 'package:flutter/material.dart';


class EntregasDashboardScreen extends StatefulWidget {
  const EntregasDashboardScreen({super.key});

  @override
  State<EntregasDashboardScreen> createState() => _EntregasDashboardScreenState();
}

class _EntregasDashboardScreenState extends State<EntregasDashboardScreen> {
  int _selectedIndex = 0;
  
  static final List<Widget> _widgetOptions = <Widget>[
    const EntregasDashboardContent(),
    const EntregasPorChoferContent(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entregas'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Por Chofer',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}