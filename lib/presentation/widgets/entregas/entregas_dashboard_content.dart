import 'package:flutter/material.dart';

class EntregasDashboardContent extends StatelessWidget {
  const EntregasDashboardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard, size: 80),
          SizedBox(height: 20),
          Text('Dashboard de Entregas', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}