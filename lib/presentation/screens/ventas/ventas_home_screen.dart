import 'package:flutter/material.dart';

class VentasHomeScreen extends StatefulWidget {
  const VentasHomeScreen({super.key});

  @override
  State<VentasHomeScreen> createState() => _VentasHomeScreenState();
}

class _VentasHomeScreenState extends State<VentasHomeScreen> {
  int _selectedIndex = 0;

  // Lista de widgets para las diferentes secciones del módulo de ventas
  final List<Widget> _ventasScreens = [
    const VentasDashboardView(),
    const VentasNuevaView(),
    const VentasHistorialView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No usamos appBar aquí porque ya lo tiene el DashboardScreen como contenedor
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del módulo de ventas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Módulo de Ventas',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión de ventas, facturas y clientes',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Pestañas de navegación dentro del módulo
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildTabButton('Panel', 0, Icons.dashboard),
                  _buildTabButton('Nueva venta', 1, Icons.add_shopping_cart),
                  _buildTabButton('Historial', 2, Icons.history),
                ],
              ),
            ),
          ),
          
          // Área de contenido principal
          Expanded(
            child: _ventasScreens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.0,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Vistas internas del módulo de ventas
class VentasDashboardView extends StatelessWidget {
  const VentasDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjetas de resumen
          Row(
            children: [
              _buildSummaryCard(
                context,
                'Ventas del día',
                '15',
                Colors.blue.shade100,
                Icons.payments,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                context,
                'Total (S/.)',
                'S/. 1,250.00',
                Colors.green.shade100,
                Icons.attach_money,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                context,
                'Clientes',
                '8',
                Colors.orange.shade100,
                Icons.people,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Gráfico o tabla de ventas recientes
          Expanded(
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ventas recientes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildRecentSaleItem(
                            'FAC-0001',
                            'Juan Pérez',
                            'S/. 120.00',
                            DateTime.now().subtract(const Duration(hours: 1)),
                          ),
                          _buildRecentSaleItem(
                            'FAC-0002',
                            'María García',
                            'S/. 350.00',
                            DateTime.now().subtract(const Duration(hours: 2)),
                          ),
                          _buildRecentSaleItem(
                            'FAC-0003',
                            'Carlos López',
                            'S/. 75.50',
                            DateTime.now().subtract(const Duration(hours: 3)),
                          ),
                          _buildRecentSaleItem(
                            'FAC-0004',
                            'Ana Martínez',
                            'S/. 200.00',
                            DateTime.now().subtract(const Duration(hours: 4)),
                          ),
                          _buildRecentSaleItem(
                            'FAC-0005',
                            'Roberto Sánchez',
                            'S/. 180.00',
                            DateTime.now().subtract(const Duration(hours: 5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSaleItem(String invoice, String customer, String amount, DateTime date) {
    return ListTile(
      title: Text(invoice),
      subtitle: Text(customer),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
      leading: const CircleAvatar(
        child: Icon(Icons.receipt_long),
      ),
    );
  }
}

class VentasNuevaView extends StatelessWidget {
  const VentasNuevaView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Formulario de nueva venta (en construcción)'),
    );
  }
}

class VentasHistorialView extends StatelessWidget {
  const VentasHistorialView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Historial de ventas (en construcción)'),
    );
  }
}