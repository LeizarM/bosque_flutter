import 'package:flutter/material.dart';
import 'package:bosque_flutter/presentation/widgets/consumo_tigo/resumen_detallado.dart';

class TigoAnalisisScreen extends StatelessWidget {
  final String periodoCobrado;
  const TigoAnalisisScreen({super.key, required this.periodoCobrado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Facturas Tigo'),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        elevation: 2,
      ),
      body: ResumenDetalladoScreen(periodoCobrado: periodoCobrado),
    );
  }
}