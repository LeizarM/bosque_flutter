import 'package:bosque_flutter/domain/entities/articulos_ciudad_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:go_router/go_router.dart';

class DisponibilidadDetalladaScreen extends ConsumerStatefulWidget {
  final ArticulosxCiudadEntity articulo;

  

  const DisponibilidadDetalladaScreen({super.key, required this.articulo});

  @override
  ConsumerState<DisponibilidadDetalladaScreen> createState() => _DisponibilidadDetalladaScreenState();
}

class _DisponibilidadDetalladaScreenState extends ConsumerState<DisponibilidadDetalladaScreen> {
  bool _isLoading = true;
  
  
  @override
  void initState() {
    super.initState();
    // Cargar los datos de disponibilidad detallada
    _cargarDatosDisponibilidad();
  }
  
  Future<void> _cargarDatosDisponibilidad() async {
    // Simulamos una carga de datos 
    await Future.delayed(const Duration(seconds: 1));
    
    // En una implementación real, aquí llamarías a un servicio o provider para obtener
    // la disponibilidad detallada del artículo, por ejemplo:
    // final result = await ref.read(disponibilidadProvider(widget.articulo.codArticulo)).future;
    
    // Por ahora, vamos a usar datos de ejemplo
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si estamos en pantalla pequeña o grande
    final isSmallScreen = ResponsiveBreakpoints.of(context).smallerThan(TABLET);
    
    final theme = Theme.of(context);

    return Scaffold(
      // No necesitamos AppBar aquí porque ya está dentro del DashboardScreen
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con información del artículo y botón de volver
          _buildHeader(context, isSmallScreen, theme),
          
          
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botón de volver
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    debugPrint('Volver a la pantalla anterior'); 
                    context.pop();
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Disponibilidad Detallada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Información del artículo
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.white.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Código del artículo
                    Row(
                      children: [
                        Text(
                          'Código: ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        Text(
                          widget.articulo.codArticulo,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Descripción
                    Text(
                      widget.articulo.datoArt,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Unidad de medida y disponibilidad
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Unidad: ${widget.articulo.unidadMedida ?? "N/D"}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        Text(
                          'Disponibilidad Total: ${widget.articulo.disponible}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
}